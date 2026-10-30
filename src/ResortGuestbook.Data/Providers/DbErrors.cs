using Microsoft.Data.Sqlite;
using Microsoft.EntityFrameworkCore;
using Npgsql;

namespace ResortGuestbook.Data.Providers;

public static class DbErrors
{
    private const int SqliteConstraint = 19;

    /// <summary>
    /// Mirrors the PHP check (<c>SQLSTATE 23000</c> or a message mentioning "unique"): any SQLite constraint failure,
    /// or a PostgreSQL unique violation, means "this data already exists" (HTTP 409).
    /// </summary>
    public static bool IsDuplicate(DbUpdateException exception) => exception.InnerException switch
    {
        SqliteException sqlite => sqlite.SqliteErrorCode == SqliteConstraint,
        PostgresException postgres => postgres.SqlState == PostgresErrorCodes.UniqueViolation
            || postgres.MessageText.Contains("unique", StringComparison.OrdinalIgnoreCase),
        _ => false,
    };
}
