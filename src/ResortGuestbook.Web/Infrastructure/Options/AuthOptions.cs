namespace ResortGuestbook.Web.Infrastructure.Options;

/// <summary>Session and login limits (v1 security settings and <c>SESSION_LIFETIME</c>).</summary>
public sealed class AuthOptions
{
    public int SessionLifetimeMinutes { get; set; } = 120;
    public int LoginAttempts { get; set; } = 5;
    public int LoginWindowSeconds { get; set; } = 900;
}
