namespace ResortGuestbook.Web.Models.Dtos;

public sealed record FeedbackDto(
    Guid Id,
    Guid StayId,
    int CleanlinessRating,
    int ServiceRating,
    int FacilityRating,
    int OverallRating,
    bool WouldReturn,
    string? Comment,
    DateTimeOffset CreatedAt,
    DateTimeOffset UpdatedAt);
