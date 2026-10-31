namespace ResortGuestbook.Data.Entities;

/// <summary>A location zone that rooms are grouped by (rooms store the zone name).</summary>
public sealed class RoomZone : ICreatedAt, IUpdatedAt
{
    public Guid Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public int SortOrder { get; set; }
    public DateTimeOffset CreatedAt { get; set; }
    public DateTimeOffset UpdatedAt { get; set; }
}
