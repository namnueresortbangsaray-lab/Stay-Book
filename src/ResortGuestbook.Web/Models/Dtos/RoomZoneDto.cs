namespace ResortGuestbook.Web.Models.Dtos;

/// <summary>A <c>room_zones</c> row with the number of rooms in that zone.</summary>
public sealed record RoomZoneDto(
    Guid Id,
    string Name,
    int SortOrder,
    int RoomCount,
    DateTimeOffset CreatedAt,
    DateTimeOffset UpdatedAt);
