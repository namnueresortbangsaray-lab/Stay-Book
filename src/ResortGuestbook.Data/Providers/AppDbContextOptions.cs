using Microsoft.Data.Sqlite;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Infrastructure;
using ResortGuestbook.Data.Interceptors;

namespace ResortGuestbook.Data.Providers;

/// <summary>The only place that turns a <see cref="DatabaseProvider"/> into EF Core provider configuration.</summary>
public static class AppDbContextOptions
{
    public const string SqliteMigrationsAssembly = "ResortGuestbook.Migrations.Sqlite";
    public const string PostgresMigrationsAssembly = "ResortGuestbook.Migrations.Postgres";

    /// <param name="clock">When null, timestamps are not stamped (used when copying rows verbatim).</param>
    public static DbContextOptionsBuilder Configure(DbContextOptionsBuilder builder, DatabaseProvider provider, string connectionString, TimeProvider? clock)
    {
        if (provider == DatabaseProvider.Sqlite)
        {
            EnsureSqliteDirectory(connectionString);
            builder.UseSqlite(connectionString, sqlite => sqlite.MigrationsAssembly(SqliteMigrationsAssembly));
            builder.AddInterceptors(new SqlitePragmaInterceptor());
        }
        else
        {
            builder.UseNpgsql(connectionString, npgsql => npgsql.MigrationsAssembly(PostgresMigrationsAssembly));
        }

        if (clock is not null)
        {
            builder.AddInterceptors(new TimestampInterceptor(clock));
        }

        builder.ReplaceService<IModelCacheKeyFactory, ProviderModelCacheKeyFactory>();
        return builder;
    }

    public static DbContextOptions<AppDbContext> Create(DatabaseProvider provider, string connectionString, TimeProvider? clock)
    {
        var builder = new DbContextOptionsBuilder<AppDbContext>();
        Configure(builder, provider, connectionString, clock);
        return builder.Options;
    }

    private static void EnsureSqliteDirectory(string connectionString)
    {
        var dataSource = new SqliteConnectionStringBuilder(connectionString).DataSource;
        if (string.IsNullOrEmpty(dataSource) || dataSource == ":memory:" || dataSource.StartsWith("file:", StringComparison.Ordinal))
        {
            return;
        }

        var directory = Path.GetDirectoryName(Path.GetFullPath(dataSource));
        if (!string.IsNullOrEmpty(directory))
        {
            Directory.CreateDirectory(directory);
        }
    }
}
