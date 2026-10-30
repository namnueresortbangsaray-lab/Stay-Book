using System.Text.Json.Serialization;

namespace ResortGuestbook.Web.Models.Dtos;

/// <summary>Response of a booking create/update: the stay plus its price breakdown.</summary>
public sealed class StayWithPriceDto : StayDto
{
    [JsonPropertyOrder(1)] public required PriceBreakdown PriceBreakdown { get; init; }
}
