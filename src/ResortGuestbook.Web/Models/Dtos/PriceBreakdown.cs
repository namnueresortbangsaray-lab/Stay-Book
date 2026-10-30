namespace ResortGuestbook.Web.Models.Dtos;

public sealed record PriceBreakdown(
    int Nights,
    long RoomTotalSatang,
    long ExtraGuestTotalSatang,
    long ExtraBedTotalSatang,
    long PetTotalSatang,
    long GrossTotalSatang,
    long TotalAmountSatang,
    long BalanceDueSatang);
