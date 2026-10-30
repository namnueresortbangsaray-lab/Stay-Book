using Npgsql;
using ResortGuestbook.Data.Providers;
using Testcontainers.PostgreSql;

namespace ResortGuestbook.Tests.Data;

/// <summary>
/// PostgreSQL 15 in Docker via Testcontainers (the same major version as Supabase's default and the <c>pgtest</c>
/// compose profile). Set <c>STAYBOOK_TEST_POSTGRES</c> to an admin connection string to use an existing server instead.
/// </summary>
public sealed class PostgresDatabaseFactory : IDatabaseFactory, IAsyncLifetime
{
    private readonly PostgreSqlContainer? container =
        Environment.GetEnvironmentVariable("STAYBOOK_TEST_POSTGRES") is { Length: > 0 }
            ? null
            : new PostgreSqlBuilder("postgres:15-alpine").Build();

    private string adminConnectionString = string.Empty;

    public DatabaseProvider Provider => DatabaseProvider.Postgres;

    public async Task InitializeAsync()
    {
        if (container is null)
        {
            adminConnectionString = Environment.GetEnvironmentVariable("STAYBOOK_TEST_POSTGRES")!;
            return;
        }

        await container.StartAsync();
        adminConnectionString = container.GetConnectionString();
    }

    public async Task DisposeAsync()
    {
        if (container is not null)
        {
            await container.DisposeAsync();
        }
    }

    public async Task<string> CreateDatabaseAsync()
    {
        var name = $"staybook_{Guid.NewGuid():N}";
        await using (var connection = new NpgsqlConnection(adminConnectionString))
        {
            await connection.OpenAsync();
            await using var command = connection.CreateCommand();
            command.CommandText = $"CREATE DATABASE \"{name}\"";
            await command.ExecuteNonQueryAsync();
        }

        return new NpgsqlConnectionStringBuilder(adminConnectionString) { Database = name, Pooling = false }.ConnectionString;
    }
}
