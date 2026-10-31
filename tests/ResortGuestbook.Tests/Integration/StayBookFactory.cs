using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc.Testing;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using ResortGuestbook.Data;
using ResortGuestbook.Data.Entities;

namespace ResortGuestbook.Tests.Integration;

/// <summary>
/// The real application on a fresh SQLite database and storage folder. Configuration is passed through environment
/// variables because <c>Program</c> reads it while building services; factories therefore share one test collection.
/// </summary>
public class StayBookFactory : WebApplicationFactory<Program>
{
    public const string AdminEmail = "admin@staybook.local";
    public const string AdminPassword = "ChangeMe123!";

    public StayBookFactory()
    {
        Root = Directory.CreateTempSubdirectory("staybook-web-").FullName;
        var settings = new Dictionary<string, string>
        {
            ["ASPNETCORE_ENVIRONMENT"] = "Testing",
            ["ConnectionStrings__Sqlite"] = $"Data Source={Path.Combine(Root, "staybook.db")};Pooling=False",
            ["Database__Provider"] = "Sqlite",
            ["Database__AutoMigrate"] = "true",
            ["Database__Seed"] = "true",
            ["Storage__UploadsPath"] = Path.Combine(Root, "uploads"),
            ["Storage__BackupsPath"] = Path.Combine(Root, "backups"),
            ["Storage__LogsPath"] = Path.Combine(Root, "logs"),
            ["Storage__KeysPath"] = Path.Combine(Root, "keys"),
            ["DEMO_ADMIN_EMAIL"] = AdminEmail,
            ["DEMO_ADMIN_PASSWORD"] = AdminPassword,
            ["Auth__SessionCheckSeconds"] = "0",
        };
        foreach (var (key, value) in settings)
        {
            Environment.SetEnvironmentVariable(key, value);
        }
    }

    public string Root { get; }

    public HttpClient CreateBrowser() => CreateClient(new WebApplicationFactoryClientOptions { AllowAutoRedirect = false, HandleCookies = true });

    /// <summary>Adds a user directly; a <paramref name="passwordHash"/> may be a v1 bcrypt hash.</summary>
    public async Task<AppUser> AddUserAsync(string email, string role, string? password = null, string? passwordHash = null)
    {
        using var scope = Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
        var user = new AppUser { Id = Guid.NewGuid(), Name = role, Email = email, Role = role };
        user.PasswordHash = passwordHash ?? scope.ServiceProvider.GetRequiredService<IPasswordHasher<AppUser>>().HashPassword(user, password!);
        db.Users.Add(user);
        await db.SaveChangesAsync();
        return user;
    }

    public async Task<T> QueryAsync<T>(Func<AppDbContext, Task<T>> query)
    {
        using var scope = Services.CreateScope();
        return await query(scope.ServiceProvider.GetRequiredService<AppDbContext>());
    }

    protected override void Dispose(bool disposing)
    {
        base.Dispose(disposing);
        Microsoft.Data.Sqlite.SqliteConnection.ClearAllPools();
        try
        {
            Directory.Delete(Root, recursive: true);
        }
        catch (IOException)
        {
            // Log files can stay locked briefly; the OS cleans the temp folder.
        }
        catch (UnauthorizedAccessException)
        {
            // Same as above.
        }
    }

    public Task<int> CountAsync<TEntity>()
        where TEntity : class => QueryAsync(db => db.Set<TEntity>().IgnoreQueryFilters().CountAsync());
}
