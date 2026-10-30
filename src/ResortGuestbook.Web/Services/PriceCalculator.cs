using ResortGuestbook.Data.Entities;
using ResortGuestbook.Web.Models.Dtos;

namespace ResortGuestbook.Web.Services;

/// <summary>Pricing rules carried over from the Flutter app via PHP. All amounts are satang.</summary>
public static class PriceCalculator
{
    public const long ExtraBedFeeSatang = 20_000;
    public const long PetFeePerNightSatang = 20_000;

    public static PriceBreakdown Calculate(Room room, int guests, DateOnly from, DateOnly to, bool extraBed, int petCount, long discount, long deposit, bool depositPaid)
    {
        var nights = Nights(from, to);
        var extraGuests = Math.Max(0, guests - room.BaseGuests);
        var roomTotal = room.PriceSatang * nights;
        var extraGuestTotal = room.ExtraGuestFeeSatang * extraGuests * nights;
        var extraBedTotal = extraBed ? ExtraBedFeeSatang : 0;
        var petTotal = petCount > 0 ? PetFeePerNightSatang * nights : 0;
        var gross = roomTotal + extraGuestTotal + extraBedTotal + petTotal;
        var net = Math.Max(0, gross - discount);
        return new PriceBreakdown(nights, roomTotal, extraGuestTotal, extraBedTotal, petTotal, gross, net, Math.Max(0, net - (depositPaid ? deposit : 0)));
    }

    /// <summary><c>max(1, |to - from| in days)</c>.</summary>
    public static int Nights(DateOnly from, DateOnly to) => Math.Max(1, Math.Abs(to.DayNumber - from.DayNumber));
}
