using Microsoft.Extensions.Options;
using ResortGuestbook.Data.Maintenance;
using ResortGuestbook.Data.Providers;
using ResortGuestbook.Web.Infrastructure.Options;

namespace ResortGuestbook.Web.Infrastructure.Cli;

public sealed class DbBackupCommand(DatabaseSettings settings, IOptions<StorageOptions> storage, IOptions<BackupOptions> backup, TimeProvider time) : ICliCommand
{
    public string Name => "db:backup";

    public string Usage => "db:backup   (SQLite VACUUM INTO storage/backups, keeps BACKUP_KEEP files)";

    public async Task<int> RunAsync(CliArguments arguments, TextWriter output, TextWriter error, CancellationToken cancellationToken)
    {
        var path = await SqliteBackup.CreateAsync(settings.SqliteConnectionString, storage.Value.BackupsPath, backup.Value.Keep, time, cancellationToken);
        await output.WriteLineAsync(path);
        return 0;
    }
}
