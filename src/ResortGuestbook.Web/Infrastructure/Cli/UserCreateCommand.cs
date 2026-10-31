using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Options;
using ResortGuestbook.Data;
using ResortGuestbook.Data.Entities;
using ResortGuestbook.Data.Identity;
using ResortGuestbook.Web.Infrastructure.Options;

namespace ResortGuestbook.Web.Infrastructure.Cli;

public sealed class UserCreateCommand(AppDbContext db, IPasswordHasher<AppUser> hasher, IOptions<AuthOptions> auth) : ICliCommand
{
    public string Name => "user:create";

    public string Usage => "user:create --name=... --email=... --password=... [--role=front_desk|admin|housekeeping]";

    public async Task<int> RunAsync(CliArguments arguments, TextWriter output, TextWriter error, CancellationToken cancellationToken)
    {
        foreach (var key in new[] { "email", "password", "name" })
        {
            if (string.IsNullOrEmpty(arguments.Option(key)))
            {
                await error.WriteLineAsync($"Missing --{key}");
                return 1;
            }
        }

        if (arguments.Option("password")!.Length < auth.Value.PasswordMinLength)
        {
            await error.WriteLineAsync($"Password must be at least {auth.Value.PasswordMinLength} characters.");
            return 1;
        }

        var role = arguments.Option("role") ?? Roles.FrontDesk;
        if (!Roles.All.Contains(role))
        {
            await error.WriteLineAsync("Invalid role.");
            return 1;
        }

        var email = AppUserStore.Normalize(arguments.Option("email"));
        if (await db.Users.IgnoreQueryFilters().AnyAsync(u => u.Email == email, cancellationToken))
        {
            await error.WriteLineAsync("A user with this email already exists.");
            return 1;
        }

        var user = new AppUser { Id = Guid.NewGuid(), Name = arguments.Option("name")!, Email = email, Role = role };
        user.PasswordHash = hasher.HashPassword(user, arguments.Option("password")!);
        db.Users.Add(user);
        await db.SaveChangesAsync(cancellationToken);
        await output.WriteLineAsync("User created.");
        return 0;
    }
}
