namespace ResortGuestbook.Web.Infrastructure.Http;

public static class RateLimitPolicies
{
    /// <summary>Login POSTs per client IP (coarse flood guard; failed attempts are throttled by <c>LoginThrottle</c>).</summary>
    public const string Login = "login";

    /// <summary>API writes per signed-in user.</summary>
    public const string Writes = "writes";
}
