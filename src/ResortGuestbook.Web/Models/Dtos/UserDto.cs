namespace ResortGuestbook.Web.Models.Dtos;

/// <summary>A staff account as admins see it; never carries the password hash or security stamp.</summary>
public sealed record UserDto(
    Guid Id,
    string Name,
    string Email,
    string Role,
    bool Active,
    DateTimeOffset? LockedUntil,
    DateTimeOffset CreatedAt,
    DateTimeOffset UpdatedAt);
