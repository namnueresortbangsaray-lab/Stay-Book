namespace ResortGuestbook.Web.Services;

/// <summary>The signed-in staff member performing an action, plus the client IP recorded in the audit log.</summary>
public sealed record Actor(Guid Id, string Name, string Email, string Role, string Ip);
