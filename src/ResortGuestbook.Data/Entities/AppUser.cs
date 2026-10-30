namespace ResortGuestbook.Data.Entities;

public sealed class AppUser : ICreatedAt, IUpdatedAt, ISoftDeletable
{
    public Guid Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public string PasswordHash { get; set; } = string.Empty;
    public string Role { get; set; } = Roles.FrontDesk;
    public bool Active { get; set; } = true;
    public string SecurityStamp { get; set; } = Guid.NewGuid().ToString("N");
    public DateTimeOffset? LockoutEnd { get; set; }
    public int AccessFailedCount { get; set; }
    public DateTimeOffset CreatedAt { get; set; }
    public DateTimeOffset UpdatedAt { get; set; }
    public DateTimeOffset? DeletedAt { get; set; }
}
