using System.Globalization;
using Microsoft.Extensions.Configuration;
using Npgsql;

namespace ResortGuestbook.Data.Providers;

/// <summary>
/// Database configuration resolved from <c>Database:*</c>, <c>ConnectionStrings:*</c> and the <c>SUPABASE_DB_*</c> variables.
/// </summary>
public sealed record DatabaseSettings(
    DatabaseProvider Provider,
    string SqliteConnectionString,
    string PostgresConnectionString,
    bool AutoMigrate,
    bool Seed)
{
    public const string DefaultSqliteConnectionString = "Data Source=storage/database/staybook.db";

    public string ConnectionString(DatabaseProvider provider) =>
        provider == DatabaseProvider.Sqlite ? SqliteConnectionString : PostgresConnectionString;

    public static DatabaseSettings FromConfiguration(IConfiguration configuration) => new(
        ParseProvider(configuration["Database:Provider"]),
        configuration.GetConnectionString("Sqlite") is { Length: > 0 } sqlite ? sqlite : DefaultSqliteConnectionString,
        configuration.GetConnectionString("Postgres") is { Length: > 0 } postgres ? postgres : BuildPostgres(configuration),
        configuration.GetValue("Database:AutoMigrate", true),
        configuration.GetValue("Database:Seed", false));

    /// <summary>Accepts <c>Sqlite</c>/<c>sqlite</c> and <c>Postgres</c>/<c>postgresql</c>/<c>pgsql</c> (the v1 driver name).</summary>
    public static DatabaseProvider ParseProvider(string? value) => value?.Trim().ToLowerInvariant() switch
    {
        null or "" or "sqlite" => DatabaseProvider.Sqlite,
        "postgres" or "postgresql" or "pgsql" or "supabase" => DatabaseProvider.Postgres,
        _ => throw new InvalidOperationException($"Database provider '{value}' is not supported. Use Sqlite or Postgres."),
    };

    private static string BuildPostgres(IConfiguration configuration)
    {
        var port = int.Parse(configuration["SUPABASE_DB_PORT"] is { Length: > 0 } p ? p : "5432", CultureInfo.InvariantCulture);
        var builder = new NpgsqlConnectionStringBuilder
        {
            Host = configuration["SUPABASE_DB_HOST"] is { Length: > 0 } host ? host : "localhost",
            Port = port,
            Database = configuration["SUPABASE_DB_NAME"] is { Length: > 0 } name ? name : "postgres",
            Username = configuration["SUPABASE_DB_USER"] is { Length: > 0 } user ? user : "postgres",
            Password = configuration["SUPABASE_DB_PASSWORD"] ?? string.Empty,
            SslMode = Enum.Parse<SslMode>(configuration["PGSQL_SSLMODE"] is { Length: > 0 } ssl ? ssl : nameof(SslMode.Require), ignoreCase: true),
        };

        // Supabase's transaction pooler (port 6543) cannot keep prepared statements between transactions.
        if (port == 6543 || configuration.GetValue("SUPABASE_DB_TRANSACTION_POOLER", false))
        {
            builder.MaxAutoPrepare = 0;
            builder.NoResetOnClose = true;
        }

        return builder.ConnectionString;
    }
}
