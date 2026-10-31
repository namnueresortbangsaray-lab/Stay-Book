namespace ResortGuestbook.Web.Infrastructure.Options;

/// <summary>Session, login and password rules (v1 security settings, <c>SESSION_LIFETIME</c>, <c>Auth__*</c>).</summary>
public sealed class AuthOptions
{
    public int SessionLifetimeMinutes { get; set; } = 120;
    public int LoginAttempts { get; set; } = 5;
    public int LoginWindowSeconds { get; set; } = 900;

    /// <summary>Minimum password length; no composition rules (NIST SP 800-63B).</summary>
    public int PasswordMinLength { get; set; } = 10;

    /// <summary>How often a session is re-checked against the user's security stamp (password, role or status changes).</summary>
    public int SessionCheckSeconds { get; set; } = 60;
}
