using Microsoft.AspNetCore.Identity;
using ResortGuestbook.Data.Entities;
using ResortGuestbook.Web.Authorization;
using ResortGuestbook.Web.Infrastructure.Identity;
using ResortGuestbook.Web.Infrastructure.Storage;

namespace ResortGuestbook.Tests.Unit;

public sealed class SecurityUnitTests
{
    private static readonly AppUser User = new() { Id = Guid.NewGuid(), Email = "a@b.c" };

    [Fact]
    public void PhpBcryptHashVerifiesAndRequestsRehash()
    {
        var hasher = new LegacyBcryptPasswordHasher();
        var php = BCrypt.Net.BCrypt.HashPassword("Secret123!", 10).Replace("$2a$", "$2y$", StringComparison.Ordinal);
        Assert.Equal(PasswordVerificationResult.SuccessRehashNeeded, hasher.VerifyHashedPassword(User, php, "Secret123!"));
        Assert.Equal(PasswordVerificationResult.Failed, hasher.VerifyHashedPassword(User, php, "wrong"));
    }

    [Fact]
    public void NewHashesUseIdentityFormat()
    {
        var hasher = new LegacyBcryptPasswordHasher();
        var hash = hasher.HashPassword(User, "Secret123!");
        Assert.False(LegacyBcryptPasswordHasher.IsBcrypt(hash));
        Assert.Equal(PasswordVerificationResult.Success, hasher.VerifyHashedPassword(User, hash, "Secret123!"));
    }

    [Theory]
    [InlineData(Roles.Admin, Abilities.ManageUsers, true)]
    [InlineData(Roles.FrontDesk, Abilities.ManageUsers, false)]
    [InlineData(Roles.FrontDesk, Abilities.ManageRooms, true)]
    [InlineData(Roles.Housekeeping, Abilities.Checkout, true)]
    [InlineData(Roles.Housekeeping, Abilities.Upload, true)]
    [InlineData(Roles.Housekeeping, Abilities.View, true)]
    [InlineData(Roles.Housekeeping, Abilities.Booking, false)]
    [InlineData(Roles.Housekeeping, Abilities.EditGuest, false)]
    [InlineData(null, Abilities.View, false)]
    public void AbilityMatrixMatchesPhpPolicy(string? role, string ability, bool allowed) =>
        Assert.Equal(allowed, Abilities.Allows(role, ability));

    [Fact]
    public void SnifferRecognisesAllowedSignaturesOnly()
    {
        Assert.Equal("image/jpeg", FileSignatureSniffer.Detect([0xFF, 0xD8, 0xFF, 0xE0]));
        Assert.Equal("image/png", FileSignatureSniffer.Detect([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]));
        Assert.Equal("image/webp", FileSignatureSniffer.Detect("RIFF\0\0\0\0WEBP"u8));
        Assert.Equal("application/pdf", FileSignatureSniffer.Detect("%PDF-1.7"u8));
        Assert.Null(FileSignatureSniffer.Detect("plain text"u8));
        Assert.Null(FileSignatureSniffer.Detect("<svg"u8));
    }
}
