namespace ResortGuestbook.Data.Entities;

public sealed class Guest : ICreatedAt, IUpdatedAt, ISoftDeletable
{
    public const string DefaultCustomerType = "ลูกค้าทั่วไป";

    public Guid Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public string Phone { get; set; } = string.Empty;
    public string NormalizedPhone { get; set; } = string.Empty;
    public string CustomerType { get; set; } = DefaultCustomerType;
    public bool IsRegular { get; set; }
    public string? CustomerNote { get; set; }
    public string? Preferences { get; set; }
    public DateTimeOffset CreatedAt { get; set; }
    public DateTimeOffset UpdatedAt { get; set; }
    public DateTimeOffset? DeletedAt { get; set; }
}
