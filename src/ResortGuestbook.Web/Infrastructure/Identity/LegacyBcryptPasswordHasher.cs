using Microsoft.AspNetCore.Identity;
using ResortGuestbook.Data.Entities;

namespace ResortGuestbook.Web.Infrastructure.Identity;

/// <summary>
/// Verifies bcrypt hashes written by PHP <c>password_hash()</c> (<c>$2y$</c>, <c>$2a$</c>, <c>$2b$</c>) and asks Identity to
/// re-hash them on the next successful sign-in; everything else uses the standard Identity hasher.
/// </summary>
public sealed class LegacyBcryptPasswordHasher : IPasswordHasher<AppUser>
{
    private readonly PasswordHasher<AppUser> inner = new();

    public string HashPassword(AppUser user, string password) => inner.HashPassword(user, password);

    public PasswordVerificationResult VerifyHashedPassword(AppUser user, string hashedPassword, string providedPassword)
    {
        if (!IsBcrypt(hashedPassword))
        {
            return inner.VerifyHashedPassword(user, hashedPassword, providedPassword);
        }

        try
        {
            return BCrypt.Net.BCrypt.Verify(providedPassword, hashedPassword)
                ? PasswordVerificationResult.SuccessRehashNeeded
                : PasswordVerificationResult.Failed;
        }
        catch (BCrypt.Net.SaltParseException)
        {
            return PasswordVerificationResult.Failed;
        }
    }

    public static bool IsBcrypt(string hash) =>
        hash.StartsWith("$2y$", StringComparison.Ordinal)
        || hash.StartsWith("$2a$", StringComparison.Ordinal)
        || hash.StartsWith("$2b$", StringComparison.Ordinal);
}
