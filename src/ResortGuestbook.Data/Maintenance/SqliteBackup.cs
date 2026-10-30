using System.Globalization;
using Microsoft.Data.Sqlite;

namespace ResortGuestbook.Data.Maintenance;

/// <summary>Online SQLite backup with <c>VACUUM INTO</c>, keeping the newest <c>keep</c> files (v1 <c>db:backup</c>).</summary>
public static class SqliteBackup
{
    public static async Task<string> CreateAsync(string connectionString, string folder, int keep, TimeProvider time, CancellationToken cancellationToken)
    {
        Directory.CreateDirectory(folder);
        var path = Path.GetFullPath(Path.Combine(folder, $"stay-book-{time.GetUtcNow().ToString("yyyyMMdd-HHmmss", CultureInfo.InvariantCulture)}.sqlite"));
        await using (var connection = new SqliteConnection(connectionString))
        {
            await connection.OpenAsync(cancellationToken);
            await using var command = connection.CreateCommand();
            command.CommandText = "VACUUM INTO $path";
            command.Parameters.AddWithValue("$path", path);
            await command.ExecuteNonQueryAsync(cancellationToken);
        }

        foreach (var old in Directory.GetFiles(folder, "stay-book-*.sqlite").OrderDescending(StringComparer.Ordinal).Skip(Math.Max(1, keep)))
        {
            File.Delete(old);
        }

        return File.Exists(path) ? path : throw new InvalidOperationException("Backup was not created.");
    }
}
