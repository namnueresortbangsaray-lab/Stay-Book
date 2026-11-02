namespace ResortGuestbook.Web.Services.Validation;

public sealed record StayInput(
    string GuestName,
    string Phone,
    string RoomId,
    DateOnly CheckInDate,
    DateOnly CheckOutDate,
    int Guests,
    bool ExtraBed,
    int Status,
    string? Note,
    long DepositAmountSatang,
    bool DepositPaid,
    bool IdVerified,
    string? PetType,
    int PetCount,
    long DiscountAmountSatang,
    string? BookingChannel = null);
