using System.Security.Claims;
using Microsoft.AspNetCore.Identity;
using Microsoft.Extensions.Options;
using ResortGuestbook.Data.Entities;

namespace ResortGuestbook.Web.Infrastructure.Identity;

/// <summary>Adds the display name and the <c>users.role</c> value as claims (the v1 session held id, name, email, role).</summary>
public sealed class AppClaimsPrincipalFactory(UserManager<AppUser> userManager, IOptions<IdentityOptions> options)
    : UserClaimsPrincipalFactory<AppUser>(userManager, options)
{
    public const string DisplayNameClaim = "display_name";

    protected override async Task<ClaimsIdentity> GenerateClaimsAsync(AppUser user)
    {
        var identity = await base.GenerateClaimsAsync(user);
        identity.AddClaim(new Claim(DisplayNameClaim, user.Name));
        identity.AddClaim(new Claim(ClaimTypes.Role, user.Role));
        return identity;
    }
}
