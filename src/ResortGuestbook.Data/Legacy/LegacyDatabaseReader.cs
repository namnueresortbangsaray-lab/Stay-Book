using Microsoft.Data.Sqlite;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Infrastructure;
using ResortGuestbook.Data.Conversions;
using ResortGuestbook.Data.Entities;
using ResortGuestbook.Data.Providers;
using ResortGuestbook.Data.Transfer;

namespace ResortGuestbook.Data.Legacy;

/// <summary>
/// Reads a database created by v1 (<c>stay_book.sqlite</c>) without modifying it. Its tables use the same
/// names, columns and storage formats as the SQLite model, except that <c>users</c> lacks the Identity columns.
/// </summary>
public static class LegacyDatabaseReader
{
    public static async Task<DataSet> ReadAsync(string path, CancellationToken cancellationToken)
    {
        if (!File.Exists(path))
        {
            throw new FileNotFoundException($"v1 database not found: {path}", path);
        }

        var connectionString = new SqliteConnectionStringBuilder { DataSource = path, Mode = SqliteOpenMode.ReadOnly, Pooling = false }.ToString();
        var options = new DbContextOptionsBuilder<AppDbContext>()
            .UseSqlite(connectionString)
            .ReplaceService<IModelCacheKeyFactory, ProviderModelCacheKeyFactory>()
            .Options;

        await using var db = new AppDbContext(options);
        var rest = await DataSet.ReadRestAsync(db, cancellationToken);
        var users = await ReadUsersAsync(connectionString, cancellationToken);
        return new DataSet(users, rest);
    }

    /// <summary>v1 bcrypt hashes are kept as they are; Identity re-hashes them on the next successful sign-in.</summary>
    private static async Task<List<AppUser>> ReadUsersAsync(string connectionString, CancellationToken cancellationToken)
    {
        await using var connection = new SqliteConnection(connectionString);
        await connection.OpenAsync(cancellationToken);
        await using var command = connection.CreateCommand();
        command.CommandText = "SELECT id, name, email, password_hash, role, active, created_at, updated_at, deleted_at FROM users";
        await using var reader = await command.ExecuteReaderAsync(cancellationToken);
        var users = new List<AppUser>();
        while (await reader.ReadAsync(cancellationToken))
        {
            users.Add(new AppUser
            {
                Id = Guid.Parse(reader.GetString(0)),
                Name = reader.GetString(1),
                Email = reader.GetString(2),
                PasswordHash = reader.GetString(3),
                Role = reader.GetString(4),
                Active = reader.GetInt64(5) != 0,
                SecurityStamp = Guid.NewGuid().ToString("N"),
                CreatedAt = UtcTimestampConverter.Parse(reader.GetString(6)),
                UpdatedAt = UtcTimestampConverter.Parse(reader.GetString(7)),
                DeletedAt = reader.IsDBNull(8) ? null : UtcTimestampConverter.Parse(reader.GetString(8)),
            });
        }

        return users;
    }
}
