using Microsoft.EntityFrameworkCore;

namespace ResortGuestbook.Tests.Data;

[Collection(PostgresCollection.Name)]
public sealed class PostgresResortDataTests(PostgresDatabaseFactory factory) : ResortDataTests(factory)
{
    [Fact]
    public async Task RowLevelSecurityIsEnabledOnEveryTable()
    {
        await using var s = await TestServices.CreateAsync(factory);
        var tables = await s.Db.Database
            .SqlQueryRaw<string>("SELECT relname AS \"Value\" FROM pg_class WHERE relkind = 'r' AND relnamespace = 'public'::regnamespace AND NOT relrowsecurity")
            .ToListAsync();
        Assert.Empty(tables);
    }
}
