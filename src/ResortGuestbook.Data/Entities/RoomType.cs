namespace ResortGuestbook.Data.Entities;

/// <summary>A room type with the defaults the room form fills in when the type is chosen (rooms store the type name).</summary>
public sealed class RoomType : ICreatedAt, IUpdatedAt
{
    public Guid Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public long PriceSatang { get; set; }
    public int BaseGuests { get; set; }
    public int MaxGuests { get; set; }
    public long ExtraGuestFeeSatang { get; set; }
    public bool IsPetFriendly { get; set; }
    public int SortOrder { get; set; }
    public DateTimeOffset CreatedAt { get; set; }
    public DateTimeOffset UpdatedAt { get; set; }
}
