using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using ResortGuestbook.Data.Entities;
using ResortGuestbook.Data.Identity;

namespace ResortGuestbook.Data.Seed;

/// <summary>Creates the demo admin (when missing), the resort rooms (when the room table is empty) and their zones and types.</summary>
public sealed class DatabaseSeeder(AppDbContext db, IPasswordHasher<AppUser> hasher)
{
    public const string DefaultAdminName = "ผู้ดูแลระบบ";

    public async Task SeedAsync(string adminEmail, string adminPassword, CancellationToken cancellationToken = default)
    {
        var email = AppUserStore.Normalize(adminEmail);
        if (!await db.Users.IgnoreQueryFilters().AnyAsync(u => u.Email == email, cancellationToken))
        {
            var admin = new AppUser { Id = Guid.NewGuid(), Name = DefaultAdminName, Email = email, Role = Roles.Admin };
            admin.PasswordHash = hasher.HashPassword(admin, adminPassword);
            db.Users.Add(admin);
            await db.SaveChangesAsync(cancellationToken);
        }

        if (!await db.Rooms.AnyAsync(cancellationToken))
        {
            db.Rooms.AddRange(RoomSeedData.Create());
            await db.SaveChangesAsync(cancellationToken);
        }

        await RoomCategorySync.AddMissingAsync(db, cancellationToken);
    }
}
