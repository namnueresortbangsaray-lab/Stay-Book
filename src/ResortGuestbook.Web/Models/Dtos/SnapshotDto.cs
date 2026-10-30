namespace ResortGuestbook.Web.Models.Dtos;

public sealed record SnapshotDto(
    IReadOnlyList<RoomDto> Rooms,
    IReadOnlyList<StayDto> Stays,
    IReadOnlyList<GuestSummaryDto> Guests,
    IReadOnlyList<AttachmentDto> Attachments,
    AnalyticsDto Analytics,
    DateOnly Today);
