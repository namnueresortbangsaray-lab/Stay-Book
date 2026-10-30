namespace ResortGuestbook.Web.Infrastructure.Options;

/// <summary><c>Storage:*</c> settings. Relative paths resolve against the working directory (<c>/app</c> in Docker).</summary>
public sealed class StorageOptions
{
    public string Provider { get; set; } = "Local";
    public string UploadsPath { get; set; } = "storage/uploads";
    public string BackupsPath { get; set; } = "storage/backups";
    public string LogsPath { get; set; } = "storage/logs";
    public string KeysPath { get; set; } = "storage/keys";
}
