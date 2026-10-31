using ResortGuestbook.Web.Infrastructure.Http;
using ResortGuestbook.Web.Services.Errors;
using ResortGuestbook.Web.Services.Validation;

namespace ResortGuestbook.Tests.Unit;

public sealed class RoomCategoryRequestTests
{
    [Fact]
    public void ValidTypeKeepsRoomDefaultsInSatang()
    {
        var type = RoomTypeRequest.Validate(new RequestInput(new Dictionary<string, object?>
        {
            ["name"] = " วิลล่าริมสระ ",
            ["price"] = "1800",
            ["base_guests"] = 2L,
            ["max_guests"] = "4",
            ["extra_guest_fee"] = "250.50",
            ["is_pet_friendly"] = "on",
            ["sort_order"] = -3L,
        }));
        Assert.Equal("วิลล่าริมสระ", type.Name);
        Assert.Equal(180_000, type.PriceSatang);
        Assert.Equal(25_050, type.ExtraGuestFeeSatang);
        Assert.Equal(4, type.MaxGuests);
        Assert.True(type.IsPetFriendly);
        Assert.Equal(0, type.SortOrder);
    }

    [Fact]
    public void InvalidTypeReportsNameAndRoomPricingMessages()
    {
        var exception = Assert.Throws<ValidationException>(() => RoomTypeRequest.Validate(new RequestInput(new Dictionary<string, object?>
        {
            ["name"] = "  ",
            ["price"] = "abc",
            ["base_guests"] = 2L,
            ["max_guests"] = 1L,
        })));
        Assert.Equal(["name", "price", "max_guests"], exception.Errors.Keys);
        Assert.Equal("กรุณากรอกชื่อประเภทห้อง", exception.Errors["name"]);
        Assert.Equal("ราคาต้องเป็นตัวเลขที่มากกว่า 0", exception.Errors["price"]);
        Assert.Equal("จำนวนคนสูงสุดต้องไม่น้อยกว่าจำนวนคนพื้นฐาน", exception.Errors["max_guests"]);
    }

    [Fact]
    public void ZoneNeedsAName()
    {
        var exception = Assert.Throws<ValidationException>(() => RoomZoneRequest.Validate(new RequestInput(new Dictionary<string, object?> { ["name"] = "" })));
        Assert.Equal("กรุณากรอกชื่อโซน", exception.Errors["name"]);
        Assert.Equal(new RoomZoneInput("โซน C", 2), RoomZoneRequest.Validate(new RequestInput(new Dictionary<string, object?> { ["name"] = " โซน C ", ["sort_order"] = "2" })));
    }
}
