using Microsoft.EntityFrameworkCore.Design;
using ResortGuestbook.Data;
using ResortGuestbook.Data.Providers;

namespace ResortGuestbook.Migrations.Postgres;

/// <summary>Lets <c>dotnet ef</c> build the Postgres model without a running host or database.</summary>
public sealed class PostgresDesignTimeDbContextFactory : IDesignTimeDbContextFactory<AppDbContext>
{
    public AppDbContext CreateDbContext(string[] args) =>
        new(AppDbContextOptions.Create(DatabaseProvider.Postgres, "Host=localhost;Database=postgres;Username=postgres", clock: null));
}
