using System.Text.Json.Serialization;

namespace ResortGuestbook.Web.Models.Dtos;

/// <summary>
/// Guest list row: the guest columns, the columns of the first joined stay (a side effect of the PHP LEFT JOIN, kept for
/// parity) and the lifetime summary.
/// </summary>
public class GuestSummaryDto : GuestDto
{
    [JsonPropertyOrder(1)] public Guid? StayId { get; init; }
    [JsonPropertyOrder(1)] public DateOnly? CheckInDate { get; init; }
    [JsonPropertyOrder(1)] public DateOnly? CheckOutDate { get; init; }
    [JsonPropertyOrder(1)] public int? StayStatus { get; init; }
    [JsonPropertyOrder(1)] public long? TotalAmountSatang { get; init; }
    [JsonPropertyOrder(1)] public long? DiscountAmountSatang { get; init; }
    [JsonPropertyOrder(1)] public string? RoomName { get; init; }
    [JsonPropertyOrder(1)] public int CompletedStays { get; init; }
    [JsonPropertyOrder(1)] public long TotalNights { get; init; }
    [JsonPropertyOrder(1)] public long LifetimeValueSatang { get; init; }
    [JsonPropertyOrder(1)] public long TotalDiscountSatang { get; init; }
    [JsonPropertyOrder(1)] public DateOnly? LastStayDate { get; init; }
    [JsonPropertyOrder(1)] public string? LastRoomName { get; init; }
}
