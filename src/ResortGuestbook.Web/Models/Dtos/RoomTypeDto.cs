namespace ResortGuestbook.Web.Models.Dtos;

/// <summary>A <c>room_types</c> row (name and room defaults) with the number of rooms of that type.</summary>
public sealed record RoomTypeDto(
    Guid Id,
    string Name,
    long PriceSatang,
    int BaseGuests,
    int MaxGuests,
    long ExtraGuestFeeSatang,
    bool IsPetFriendly,
    int SortOrder,
    int RoomCount,
    DateTimeOffset CreatedAt,
    DateTimeOffset UpdatedAt);
