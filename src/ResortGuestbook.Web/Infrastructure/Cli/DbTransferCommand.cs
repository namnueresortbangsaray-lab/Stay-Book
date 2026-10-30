using Microsoft.EntityFrameworkCore;
using ResortGuestbook.Data;
using ResortGuestbook.Data.Providers;
using ResortGuestbook.Data.Transfer;

namespace ResortGuestbook.Web.Infrastructure.Cli;

/// <summary>Copies every table between SQLite and PostgreSQL (migrating the target first), preserving ids and timestamps.</summary>
public sealed class DbTransferCommand(DatabaseSettings settings) : ICliCommand
{
    public string Name => "db:transfer";

    public string Usage => "db:transfer --from=sqlite --to=postgres [--truncate] [--dry-run]";

    public async Task<int> RunAsync(CliArguments arguments, TextWriter output, TextWriter error, CancellationToken cancellationToken)
    {
        var from = DatabaseSettings.ParseProvider(arguments.Option("from") ?? "sqlite");
        var to = DatabaseSettings.ParseProvider(arguments.Option("to") ?? "postgres");
        if (from == to)
        {
            await error.WriteLineAsync("Providers must be different (sqlite/postgres).");
            return 1;
        }

        await using var source = new AppDbContext(AppDbContextOptions.Create(from, settings.ConnectionString(from), clock: null));
        await using var target = new AppDbContext(AppDbContextOptions.Create(to, settings.ConnectionString(to), clock: null));
        await target.Database.MigrateAsync(cancellationToken);
        var data = await DataSet.ReadAsync(source, cancellationToken);
        var counts = await DataSetWriter.WriteAsync(target, data, arguments.Flag("truncate"), arguments.Flag("dry-run"), cancellationToken);
        await TransferReport.WriteAsync(output, counts);
        return 0;
    }
}
