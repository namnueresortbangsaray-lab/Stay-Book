using Microsoft.EntityFrameworkCore;
using ResortGuestbook.Data;

namespace ResortGuestbook.Web.Infrastructure.Cli;

public sealed class MigrateCommand(AppDbContext db) : ICliCommand
{
    public string Name => "migrate";

    public string Usage => "migrate";

    public async Task<int> RunAsync(CliArguments arguments, TextWriter output, TextWriter error, CancellationToken cancellationToken)
    {
        var pending = (await db.Database.GetPendingMigrationsAsync(cancellationToken)).ToList();
        await db.Database.MigrateAsync(cancellationToken);
        await output.WriteLineAsync(pending.Count > 0 ? $"Applied: {string.Join(", ", pending)}" : "Database is current.");
        return 0;
    }
}
