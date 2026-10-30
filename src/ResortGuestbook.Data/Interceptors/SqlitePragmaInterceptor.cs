using System.Data.Common;
using Microsoft.EntityFrameworkCore.Diagnostics;

namespace ResortGuestbook.Data.Interceptors;

/// <summary>Applies the same per-connection pragmas as the PHP connection: foreign keys, WAL, and a 5 s busy timeout.</summary>
public sealed class SqlitePragmaInterceptor : DbConnectionInterceptor
{
    private const string Pragmas = "PRAGMA foreign_keys=ON; PRAGMA journal_mode=WAL; PRAGMA busy_timeout=5000;";

    public override void ConnectionOpened(DbConnection connection, ConnectionEndEventData eventData)
    {
        using var command = connection.CreateCommand();
        command.CommandText = Pragmas;
        command.ExecuteNonQuery();
    }

    public override async Task ConnectionOpenedAsync(DbConnection connection, ConnectionEndEventData eventData, CancellationToken cancellationToken = default)
    {
        await using var command = connection.CreateCommand();
        command.CommandText = Pragmas;
        await command.ExecuteNonQueryAsync(cancellationToken);
    }
}
