namespace ResortGuestbook.Data.Entities;

public sealed class Feedback : ICreatedAt, IUpdatedAt
{
    public Guid Id { get; set; }
    public Guid StayId { get; set; }
    public int CleanlinessRating { get; set; }
    public int ServiceRating { get; set; }
    public int FacilityRating { get; set; }
    public int OverallRating { get; set; }
    public bool WouldReturn { get; set; } = true;
    public string? Comment { get; set; }
    public DateTimeOffset CreatedAt { get; set; }
    public DateTimeOffset UpdatedAt { get; set; }
}
