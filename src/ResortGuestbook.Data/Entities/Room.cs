namespace ResortGuestbook.Data.Entities;

public sealed class Room : ICreatedAt, IUpdatedAt, ISoftDeletable
{
    public Guid Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public string Zone { get; set; } = string.Empty;
    public string Type { get; set; } = string.Empty;
    public long PriceSatang { get; set; }
    public int BaseGuests { get; set; }
    public int MaxGuests { get; set; }
    public long ExtraGuestFeeSatang { get; set; }
    public int SortOrder { get; set; }

    /// <summary>0 vacant, 1 occupied.</summary>
    public int Status { get; set; }
    public bool IsPetFriendly { get; set; }
    public DateTimeOffset CreatedAt { get; set; }
    public DateTimeOffset UpdatedAt { get; set; }
    public DateTimeOffset? DeletedAt { get; set; }
}
