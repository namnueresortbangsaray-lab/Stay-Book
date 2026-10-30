using System.Text.Json.Serialization;

namespace ResortGuestbook.Web.Models.Dtos;

/// <summary>Guest summary plus the guest’s stays; used as the audit “before” image of a guest update.</summary>
public sealed class GuestDetailDto : GuestSummaryDto
{
    [JsonPropertyOrder(2)] public required IReadOnlyList<StayDto> Stays { get; init; }
}
