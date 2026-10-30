namespace ResortGuestbook.Web.Models.Dtos;

/// <summary>A <c>stays</c> row joined with its room, guest and feedback rating, as the PHP API returned it.</summary>
public class StayDto
{
    public required Guid Id { get; init; }
    public required Guid? GuestId { get; init; }
    public required Guid RoomId { get; init; }
    public required string GuestName { get; init; }
    public required string? Phone { get; init; }
    public required DateOnly CheckInDate { get; init; }
    public required DateOnly CheckOutDate { get; init; }
    public required int Guests { get; init; }
    public required bool ExtraBed { get; init; }
    public required long TotalAmountSatang { get; init; }
    public required int Status { get; init; }
    public required string? Note { get; init; }
    public required long DepositAmountSatang { get; init; }
    public required bool DepositPaid { get; init; }
    public required bool IdVerified { get; init; }
    public required string? PetType { get; init; }
    public required int PetCount { get; init; }
    public required long PetFeeSatang { get; init; }
    public required long DiscountAmountSatang { get; init; }
    public required DateTimeOffset CreatedAt { get; init; }
    public required DateTimeOffset UpdatedAt { get; init; }
    public required DateTimeOffset? DeletedAt { get; init; }
    public required string RoomName { get; init; }
    public required string Zone { get; init; }
    public required string RoomType { get; init; }
    public required long RoomRateSatang { get; init; }
    public required int BaseGuests { get; init; }
    public required int MaxGuests { get; init; }
    public required long ExtraGuestFeeSatang { get; init; }
    public required bool IsPetFriendly { get; init; }
    public required string? CustomerType { get; init; }
    public required bool IsRegular { get; init; }
    public required int? FeedbackRating { get; init; }
}
