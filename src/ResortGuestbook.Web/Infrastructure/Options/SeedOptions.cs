namespace ResortGuestbook.Web.Infrastructure.Options;

/// <summary>Demo administrator (<c>DEMO_ADMIN_EMAIL</c>, <c>DEMO_ADMIN_PASSWORD</c>).</summary>
public sealed class SeedOptions
{
    public string AdminEmail { get; set; } = "admin@staybook.local";
    public string AdminPassword { get; set; } = "ChangeMe123!";
}
