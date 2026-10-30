namespace ResortGuestbook.Web.Infrastructure.Options;

/// <summary>Number of SQLite backups to keep (<c>BACKUP_KEEP</c>).</summary>
public sealed class BackupOptions
{
    public int Keep { get; set; } = 7;
}
