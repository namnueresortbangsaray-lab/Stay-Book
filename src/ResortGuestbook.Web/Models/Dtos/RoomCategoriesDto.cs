namespace ResortGuestbook.Web.Models.Dtos;

/// <summary>The zone and room-type lists the room form chooses from, in their sort order.</summary>
public sealed record RoomCategoriesDto(IReadOnlyList<RoomZoneDto> Zones, IReadOnlyList<RoomTypeDto> Types);
