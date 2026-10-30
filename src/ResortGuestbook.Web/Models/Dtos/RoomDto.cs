namespace ResortGuestbook.Web.Models.Dtos;

/// <summary>A <c>rooms</c> row as the v1 API returned it.</summary>
public sealed record RoomDto(
    Guid Id,
    string Name,
    string Zone,
    string Type,
    long PriceSatang,
    int BaseGuests,
    int MaxGuests,
    long ExtraGuestFeeSatang,
    int SortOrder,
    int Status,
    bool IsPetFriendly,
    DateTimeOffset CreatedAt,
    DateTimeOffset UpdatedAt,
    DateTimeOffset? DeletedAt);
