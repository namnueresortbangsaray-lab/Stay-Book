using Microsoft.EntityFrameworkCore.Design;
using ResortGuestbook.Data;
using ResortGuestbook.Data.Providers;

namespace ResortGuestbook.Migrations.Sqlite;

/// <summary>Lets <c>dotnet ef</c> build the Sqlite model without a running host or database.</summary>
public sealed class SqliteDesignTimeDbContextFactory : IDesignTimeDbContextFactory<AppDbContext>
{
    public AppDbContext CreateDbContext(string[] args) =>
        new(AppDbContextOptions.Create(DatabaseProvider.Sqlite, "Data Source=:memory:", clock: null));
}
