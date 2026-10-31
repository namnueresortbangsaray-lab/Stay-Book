using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Options;
using ResortGuestbook.Data;
using ResortGuestbook.Data.Entities;
using ResortGuestbook.Web.Infrastructure.Http;
using ResortGuestbook.Web.Infrastructure.Options;
using ResortGuestbook.Web.Models.Dtos;
using ResortGuestbook.Web.Services.Errors;
using ResortGuestbook.Web.Services.Validation;

namespace ResortGuestbook.Web.Services;

/// <summary>
/// Staff accounts. Accounts are deactivated, never deleted (audit rows keep pointing at them). A new password, role or
/// status gets a new security stamp, which ends that user's other sessions at the next check. Admins cannot lock
/// themselves out, and the last active admin cannot be demoted or deactivated.
/// </summary>
public sealed class UserService(AppDbContext db, AuditService audit, IPasswordHasher<AppUser> hasher, AppClock clock, IOptions<AuthOptions> options)
{
    private const string NotFound = "ไม่พบผู้ใช้";

    private int MinLength => options.Value.PasswordMinLength;

    public async Task<List<UserDto>> ListAsync(CancellationToken cancellationToken)
    {
        var users = await db.Users.AsNoTracking().OrderByDescending(u => u.Active).ThenBy(u => u.Name).ToListAsync(cancellationToken);
        return [.. users.Select(ToDto)];
    }

    public async Task<UserDto> CreateAsync(RequestInput input, Actor actor, CancellationToken cancellationToken)
    {
        var data = UserRequest.Validate(input, creating: true, MinLength);
        var user = new AppUser { Id = Guid.NewGuid(), Name = data.Name, Email = data.Email, Role = data.Role, Active = data.Active };
        user.PasswordHash = hasher.HashPassword(user, data.Password!);
        db.Users.Add(user);
        await db.SaveChangesAsync(cancellationToken);
        var after = ToDto(user);
        await audit.RecordAsync("create", "user", user.Id, null, after, actor, cancellationToken);
        return after;
    }

    public async Task<UserDto> UpdateAsync(RequestInput input, string id, Actor actor, CancellationToken cancellationToken)
    {
        var data = UserRequest.Validate(input, creating: false, MinLength);
        var user = await FindAsync(id, cancellationToken) ?? throw new NotFoundException(NotFound);
        var before = ToDto(user);

        if (user.Id == actor.Id && data.Role != user.Role)
        {
            throw new ValidationException("role", "เปลี่ยนสิทธิ์ของบัญชีตัวเองไม่ได้");
        }

        if (user.Id == actor.Id && !data.Active)
        {
            throw new ValidationException("active", "ปิดใช้งานบัญชีตัวเองไม่ได้");
        }

        var losesAdmin = user is { Role: Roles.Admin, Active: true } && (data.Role != Roles.Admin || !data.Active);
        if (losesAdmin && !await db.Users.AnyAsync(u => u.Id != user.Id && u.Role == Roles.Admin && u.Active, cancellationToken))
        {
            throw new ValidationException(data.Role != Roles.Admin ? "role" : "active", "ต้องมีผู้ดูแลระบบที่ใช้งานอยู่อย่างน้อย 1 คน");
        }

        var signInChanged = data.Email != user.Email || data.Role != user.Role || data.Active != user.Active;
        user.Name = data.Name;
        user.Email = data.Email;
        user.Role = data.Role;
        user.Active = data.Active;
        if (signInChanged)
        {
            user.SecurityStamp = NewStamp();
        }

        await db.SaveChangesAsync(cancellationToken);
        var after = ToDto(user);
        await audit.RecordAsync("update", "user", user.Id, before, after, actor, cancellationToken);
        return after;
    }

    /// <summary>An admin sets a new password (for a forgotten one); also lifts a sign-in lockout.</summary>
    public async Task<UserDto> SetPasswordAsync(RequestInput input, string id, Actor actor, CancellationToken cancellationToken)
    {
        var password = PasswordRequest.Validate(input, MinLength);
        var user = await FindAsync(id, cancellationToken) ?? throw new NotFoundException(NotFound);
        await ReplacePasswordAsync(user, password, actor, cancellationToken);
        return ToDto(user);
    }

    /// <summary>Signed-in users change their own password; the current one is required.</summary>
    public async Task<AppUser> ChangeOwnPasswordAsync(RequestInput input, Actor actor, CancellationToken cancellationToken)
    {
        var user = await db.Users.FirstOrDefaultAsync(u => u.Id == actor.Id, cancellationToken) ?? throw new NotFoundException(NotFound);
        var errors = new Dictionary<string, string>();
        if (hasher.VerifyHashedPassword(user, user.PasswordHash, input["current_password"] as string ?? string.Empty) == PasswordVerificationResult.Failed)
        {
            errors["current_password"] = "รหัสผ่านปัจจุบันไม่ถูกต้อง";
        }

        var password = PasswordRequest.CheckNew(input, MinLength, errors);
        if (errors.Count > 0)
        {
            throw new ValidationException(errors);
        }

        await ReplacePasswordAsync(user, password, actor, cancellationToken);
        return user;
    }

    private async Task ReplacePasswordAsync(AppUser user, string password, Actor actor, CancellationToken cancellationToken)
    {
        user.PasswordHash = hasher.HashPassword(user, password);
        user.SecurityStamp = NewStamp();
        user.LockoutEnd = null;
        user.AccessFailedCount = 0;
        await db.SaveChangesAsync(cancellationToken);
        await audit.RecordAsync("password", "user", user.Id, null, null, actor, cancellationToken);
    }

    private Task<AppUser?> FindAsync(string id, CancellationToken cancellationToken) =>
        Guid.TryParse(id, out var key) ? db.Users.FirstOrDefaultAsync(u => u.Id == key, cancellationToken) : Task.FromResult<AppUser?>(null);

    private static string NewStamp() => Guid.NewGuid().ToString("N");

    private UserDto ToDto(AppUser u) => new(
        u.Id, u.Name, u.Email, u.Role, u.Active, u.LockoutEnd > clock.UtcNow ? u.LockoutEnd : null, u.CreatedAt, u.UpdatedAt);
}
