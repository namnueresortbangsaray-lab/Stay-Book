using ResortGuestbook.Web.Infrastructure.Http;
using ResortGuestbook.Web.Services.Errors;
using ResortGuestbook.Web.Services.Validation;

namespace ResortGuestbook.Tests.Unit;

/// <summary>Ported from the PHP <c>StayRequestTest</c>, plus coercion cases.</summary>
public sealed class StayRequestTests
{
    [Theory]
    [InlineData("2030-01-10", "2030-01-10")]
    [InlineData("2030-01-10", "2030-01-09")]
    [InlineData("2030-02-29", "2030-03-01")]
    public void RejectsInvalidOrZeroNightRanges(string checkIn, string checkOut) =>
        Assert.Throws<ValidationException>(() => StayRequest.Validate(Input(("check_in_date", checkIn), ("check_out_date", checkOut))));

    [Fact]
    public void RejectsNegativeFinancialAmountsInsteadOfSilentlyClampingThem()
    {
        var error = Assert.Throws<ValidationException>(() => StayRequest.Validate(Input(("deposit_amount", -1L), ("discount_amount", -50L))));
        Assert.Equal("เงินมัดจำต้องเป็นตัวเลขที่ไม่ติดลบ", error.Errors["deposit_amount"]);
        Assert.Equal("ส่วนลดต้องเป็นตัวเลขที่ไม่ติดลบ", error.Errors["discount_amount"]);
    }

    [Fact]
    public void CheckedInStatusRequiresIdVerification()
    {
        var error = Assert.Throws<ValidationException>(() => StayRequest.Validate(Input(("status", 1L))));
        Assert.True(error.Errors.ContainsKey("id_verified"));
    }

    [Fact]
    public void CoercesLooseInputLikePhp()
    {
        var data = StayRequest.Validate(Input(("guests", "2"), ("deposit_amount", "300.5"), ("deposit_paid", "on"), ("pet_count", "1"), ("pet_type", " แมว ")));
        Assert.Equal(2, data.Guests);
        Assert.Equal(30_050, data.DepositAmountSatang);
        Assert.True(data.DepositPaid);
        Assert.Equal("แมว", data.PetType);
    }

    [Fact]
    public void ReportsErrorsInPhpOrder()
    {
        var error = Assert.Throws<ValidationException>(() => StayRequest.Validate(RequestInput.Empty));
        Assert.Equal(["guest_name", "phone", "check_in_date", "check_out_date", "room_id", "guests"], error.Errors.Keys);
    }

    private static RequestInput Input(params (string Key, object? Value)[] overrides)
    {
        var values = new Dictionary<string, object?>
        {
            ["guest_name"] = "ผู้เข้าพัก ทดสอบ",
            ["phone"] = "0812345678",
            ["room_id"] = "room-id",
            ["check_in_date"] = "2030-01-10",
            ["check_out_date"] = "2030-01-12",
            ["guests"] = 2L,
            ["status"] = 0L,
            ["pet_count"] = 0L,
            ["deposit_amount"] = 0L,
            ["discount_amount"] = 0L,
        };
        foreach (var (key, value) in overrides)
        {
            values[key] = value;
        }

        return new RequestInput(values);
    }
}
