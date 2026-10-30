namespace ResortGuestbook.Web.Models.Dtos;

/// <summary>A <c>guests</c> row as the PHP API returned it.</summary>
public class GuestDto
{
    public required Guid Id { get; init; }
    public required string Name { get; init; }
    public required string Phone { get; init; }
    public required string NormalizedPhone { get; init; }
    public required string CustomerType { get; init; }
    public required bool IsRegular { get; init; }
    public required string? CustomerNote { get; init; }
    public required string? Preferences { get; init; }
    public required DateTimeOffset CreatedAt { get; init; }
    public required DateTimeOffset UpdatedAt { get; init; }
    public required DateTimeOffset? DeletedAt { get; init; }
}
