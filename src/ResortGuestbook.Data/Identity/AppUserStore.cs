using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using ResortGuestbook.Data.Entities;

namespace ResortGuestbook.Data.Identity;

/// <summary>
/// Identity store over the PHP-compatible <c>users</c> table. The user name is the (lowercase) email; roles live in
/// <c>users.role</c>, so no claim, login, token or role tables are needed.
/// </summary>
public sealed class AppUserStore(AppDbContext db) :
    IUserPasswordStore<AppUser>,
    IUserEmailStore<AppUser>,
    IUserSecurityStampStore<AppUser>,
    IUserLockoutStore<AppUser>
{
    public void Dispose()
    {
    }

    public Task<string> GetUserIdAsync(AppUser user, CancellationToken cancellationToken) => Task.FromResult(user.Id.ToString());

    public Task<string?> GetUserNameAsync(AppUser user, CancellationToken cancellationToken) => Task.FromResult<string?>(user.Email);

    public Task SetUserNameAsync(AppUser user, string? userName, CancellationToken cancellationToken)
    {
        user.Email = Normalize(userName);
        return Task.CompletedTask;
    }

    public Task<string?> GetNormalizedUserNameAsync(AppUser user, CancellationToken cancellationToken) =>
        Task.FromResult<string?>(user.Email.ToUpperInvariant());

    public Task SetNormalizedUserNameAsync(AppUser user, string? normalizedName, CancellationToken cancellationToken) => Task.CompletedTask;

    public async Task<IdentityResult> CreateAsync(AppUser user, CancellationToken cancellationToken)
    {
        db.Users.Add(user);
        await db.SaveChangesAsync(cancellationToken);
        return IdentityResult.Success;
    }

    public async Task<IdentityResult> UpdateAsync(AppUser user, CancellationToken cancellationToken)
    {
        if (db.Entry(user).State == EntityState.Detached)
        {
            db.Users.Update(user);
        }

        await db.SaveChangesAsync(cancellationToken);
        return IdentityResult.Success;
    }

    public async Task<IdentityResult> DeleteAsync(AppUser user, CancellationToken cancellationToken)
    {
        db.Users.Remove(user);
        await db.SaveChangesAsync(cancellationToken);
        return IdentityResult.Success;
    }

    public Task<AppUser?> FindByIdAsync(string userId, CancellationToken cancellationToken) =>
        Guid.TryParse(userId, out var id)
            ? db.Users.FirstOrDefaultAsync(u => u.Id == id, cancellationToken)
            : Task.FromResult<AppUser?>(null);

    public Task<AppUser?> FindByNameAsync(string normalizedUserName, CancellationToken cancellationToken) =>
        FindByEmailAsync(normalizedUserName, cancellationToken);

    public Task SetPasswordHashAsync(AppUser user, string? passwordHash, CancellationToken cancellationToken)
    {
        user.PasswordHash = passwordHash ?? string.Empty;
        return Task.CompletedTask;
    }

    public Task<string?> GetPasswordHashAsync(AppUser user, CancellationToken cancellationToken) => Task.FromResult<string?>(user.PasswordHash);

    public Task<bool> HasPasswordAsync(AppUser user, CancellationToken cancellationToken) => Task.FromResult(user.PasswordHash.Length > 0);

    public Task SetEmailAsync(AppUser user, string? email, CancellationToken cancellationToken)
    {
        user.Email = Normalize(email);
        return Task.CompletedTask;
    }

    public Task<string?> GetEmailAsync(AppUser user, CancellationToken cancellationToken) => Task.FromResult<string?>(user.Email);

    public Task<bool> GetEmailConfirmedAsync(AppUser user, CancellationToken cancellationToken) => Task.FromResult(true);

    public Task SetEmailConfirmedAsync(AppUser user, bool confirmed, CancellationToken cancellationToken) => Task.CompletedTask;

    public Task<AppUser?> FindByEmailAsync(string normalizedEmail, CancellationToken cancellationToken)
    {
        var email = Normalize(normalizedEmail);
        return db.Users.FirstOrDefaultAsync(u => u.Email == email, cancellationToken);
    }

    public Task<string?> GetNormalizedEmailAsync(AppUser user, CancellationToken cancellationToken) =>
        Task.FromResult<string?>(user.Email.ToUpperInvariant());

    public Task SetNormalizedEmailAsync(AppUser user, string? normalizedEmail, CancellationToken cancellationToken) => Task.CompletedTask;

    public Task SetSecurityStampAsync(AppUser user, string stamp, CancellationToken cancellationToken)
    {
        user.SecurityStamp = stamp;
        return Task.CompletedTask;
    }

    public Task<string?> GetSecurityStampAsync(AppUser user, CancellationToken cancellationToken) => Task.FromResult<string?>(user.SecurityStamp);

    public Task<DateTimeOffset?> GetLockoutEndDateAsync(AppUser user, CancellationToken cancellationToken) => Task.FromResult(user.LockoutEnd);

    public Task SetLockoutEndDateAsync(AppUser user, DateTimeOffset? lockoutEnd, CancellationToken cancellationToken)
    {
        user.LockoutEnd = lockoutEnd?.ToUniversalTime();
        return Task.CompletedTask;
    }

    public Task<int> IncrementAccessFailedCountAsync(AppUser user, CancellationToken cancellationToken) => Task.FromResult(++user.AccessFailedCount);

    public Task ResetAccessFailedCountAsync(AppUser user, CancellationToken cancellationToken)
    {
        user.AccessFailedCount = 0;
        return Task.CompletedTask;
    }

    public Task<int> GetAccessFailedCountAsync(AppUser user, CancellationToken cancellationToken) => Task.FromResult(user.AccessFailedCount);

    public Task<bool> GetLockoutEnabledAsync(AppUser user, CancellationToken cancellationToken) => Task.FromResult(true);

    public Task SetLockoutEnabledAsync(AppUser user, bool enabled, CancellationToken cancellationToken) => Task.CompletedTask;

    /// <summary>PHP stored and looked up emails with <c>strtolower(trim())</c>.</summary>
    public static string Normalize(string? email) => (email ?? string.Empty).Trim().ToLowerInvariant();
}
