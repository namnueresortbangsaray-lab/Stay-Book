using System.Security.Claims;
using ResortGuestbook.Web.Infrastructure.Identity;
using ResortGuestbook.Web.Services;

namespace ResortGuestbook.Web.Infrastructure.Http;

public static class HttpContextExtensions
{
    /// <summary>The client IP as recorded by PHP's <c>REMOTE_ADDR</c> (after trusted forwarded headers).</summary>
    public static string ClientIp(this HttpContext context)
    {
        var address = context.Connection.RemoteIpAddress;
        if (address is null)
        {
            return "unknown";
        }

        return (address.IsIPv4MappedToIPv6 ? address.MapToIPv4() : address).ToString();
    }

    public static Actor Actor(this HttpContext context)
    {
        var user = context.User;
        return new Actor(
            Guid.Parse(user.FindFirstValue(ClaimTypes.NameIdentifier) ?? throw new InvalidOperationException("Not signed in.")),
            user.FindFirstValue(AppClaimsPrincipalFactory.DisplayNameClaim) ?? string.Empty,
            user.FindFirstValue(ClaimTypes.Email) ?? string.Empty,
            user.FindFirstValue(ClaimTypes.Role) ?? string.Empty,
            context.ClientIp());
    }
}
