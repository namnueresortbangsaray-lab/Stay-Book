using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Options;
using ResortGuestbook.Data;
using ResortGuestbook.Data.Legacy;
using ResortGuestbook.Data.Providers;
using ResortGuestbook.Data.Seed;
using ResortGuestbook.Data.Transfer;
using ResortGuestbook.Web.Infrastructure.Options;

namespace ResortGuestbook.Web.Infrastructure.Cli;

/// <summary>
/// Imports a v1 installation: every row of <c>stay_book.sqlite</c> (ids, bcrypt hashes and timestamps preserved) plus the
/// uploaded files, into the configured database. Idempotent; use <c>--truncate</c> on a freshly seeded database.
/// </summary>
public sealed class ImportPhpCommand(DatabaseSettings settings, IOptions<StorageOptions> storage) : ICliCommand
{
    public string Name => "import:php";

    public string Usage => "import:php --sqlite=<stay_book.sqlite> [--uploads=<uploads dir>] [--truncate] [--dry-run]";

    public async Task<int> RunAsync(CliArguments arguments, TextWriter output, TextWriter error, CancellationToken cancellationToken)
    {
        var sqlite = arguments.Option("sqlite");
        if (string.IsNullOrEmpty(sqlite))
        {
            await error.WriteLineAsync("Missing --sqlite");
            return 1;
        }

        var data = await LegacyDatabaseReader.ReadAsync(sqlite, cancellationToken);
        var dryRun = arguments.Flag("dry-run");
        await using var target = new AppDbContext(AppDbContextOptions.Create(settings.Provider, settings.ConnectionString(settings.Provider), clock: null));
        if (!dryRun)
        {
            await target.Database.MigrateAsync(cancellationToken);
        }

        IReadOnlyList<TableCount> counts;
        try
        {
            counts = await DataSetWriter.WriteAsync(target, data, arguments.Flag("truncate"), dryRun, cancellationToken);
        }
        catch (DbUpdateException exception) when (DbErrors.IsDuplicate(exception))
        {
            await error.WriteLineAsync("Import conflicts with existing rows (for example the seeded admin or rooms). Re-run with --truncate to replace them.");
            return 1;
        }

        if (!dryRun)
        {
            // v1 has no zone or room-type tables: build the lists from the imported rooms.
            await RoomCategorySync.AddMissingAsync(target, cancellationToken);
        }

        await TransferReport.WriteAsync(output, counts);
        await CopyUploadsAsync(arguments.Option("uploads"), data, dryRun, output);
        return 0;
    }

    private async Task CopyUploadsAsync(string? sourceDirectory, DataSet data, bool dryRun, TextWriter output)
    {
        if (string.IsNullOrEmpty(sourceDirectory))
        {
            return;
        }

        var source = Path.GetFullPath(sourceDirectory);
        var destination = Path.GetFullPath(storage.Value.UploadsPath);
        int copied = 0, present = 0, missing = 0;
        Directory.CreateDirectory(destination);
        foreach (var attachment in data.Attachments)
        {
            var from = Path.Combine(source, Path.GetFileName(attachment.StoredName));
            var to = Path.Combine(destination, Path.GetFileName(attachment.StoredName));
            if (File.Exists(to))
            {
                present++;
            }
            else if (!File.Exists(from))
            {
                missing++;
            }
            else
            {
                if (!dryRun)
                {
                    File.Copy(from, to);
                }

                copied++;
            }
        }

        await output.WriteLineAsync($"{"files",-24} copied {copied}, already present {present}, missing {missing}");
    }
}
