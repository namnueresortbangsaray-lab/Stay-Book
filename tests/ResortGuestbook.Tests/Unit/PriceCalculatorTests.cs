using ResortGuestbook.Data.Entities;
using ResortGuestbook.Web.Services;

namespace ResortGuestbook.Tests.Unit;

/// <summary>Ported from the PHP <c>PriceCalculatorTest</c>.</summary>
public sealed class PriceCalculatorTests
{
    private static readonly Room Room = new() { PriceSatang = 50_000, BaseGuests = 2, ExtraGuestFeeSatang = 10_000 };

    [Fact]
    public void PricingMatchesOriginalRules()
    {
        var price = PriceCalculator.Calculate(Room, 3, new DateOnly(2026, 8, 18), new DateOnly(2026, 8, 20), true, 0, 0, 0, false);
        Assert.Equal(2, price.Nights);
        Assert.Equal(140_000, price.TotalAmountSatang);
    }

    [Fact]
    public void PetDiscountAndPaidDeposit()
    {
        var price = PriceCalculator.Calculate(Room, 2, new DateOnly(2026, 8, 18), new DateOnly(2026, 8, 20), true, 2, 30_000, 50_000, true);
        Assert.Equal(160_000, price.GrossTotalSatang);
        Assert.Equal(130_000, price.TotalAmountSatang);
        Assert.Equal(80_000, price.BalanceDueSatang);
    }

    [Fact]
    public void UnpaidDepositDoesNotReduceBalance()
    {
        var price = PriceCalculator.Calculate(Room, 2, new DateOnly(2026, 8, 18), new DateOnly(2026, 8, 19), false, 0, 0, 30_000, false);
        Assert.Equal(50_000, price.BalanceDueSatang);
    }

    [Fact]
    public void DiscountNeverMakesTotalNegative()
    {
        var price = PriceCalculator.Calculate(Room, 2, new DateOnly(2026, 8, 18), new DateOnly(2026, 8, 19), false, 0, 999_999, 0, false);
        Assert.Equal(0, price.TotalAmountSatang);
    }
}
