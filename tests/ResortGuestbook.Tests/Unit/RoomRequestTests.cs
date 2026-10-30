using ResortGuestbook.Web.Infrastructure.Http;
using ResortGuestbook.Web.Services.Errors;
using ResortGuestbook.Web.Services.Validation;

namespace ResortGuestbook.Tests.Unit;

public sealed class RoomRequestTests
{
    [Fact]
    public void ValidRoomIsConvertedToSatang()
    {
        var room = RoomRequest.Validate(new RequestInput(new Dictionary<string, object?>
        {
            ["name"] = " B-101 ",
            ["zone"] = "โซน C",
            ["type"] = "วิลล่า",
            ["price"] = "650.50",
            ["base_guests"] = 2L,
            ["max_guests"] = "4",
            ["extra_guest_fee"] = 150L,
            ["is_pet_friendly"] = "yes",
        }));
        Assert.Equal("B-101", room.Name);
        Assert.Equal(65_050, room.PriceSatang);
        Assert.Equal(15_000, room.ExtraGuestFeeSatang);
        Assert.True(room.IsPetFriendly);
    }

    [Fact]
    public void InvalidRoomReportsEveryFieldWithV1Messages()
    {
        var error = Assert.Throws<ValidationException>(() => RoomRequest.Validate(new RequestInput(new Dictionary<string, object?>
        {
            ["name"] = " ",
            ["price"] = 0L,
            ["base_guests"] = 0L,
            ["max_guests"] = -1L,
            ["extra_guest_fee"] = -1L,
        })));
        Assert.Equal("กรุณากรอกชื่อห้อง", error.Errors["name"]);
        Assert.Equal("ราคาต้องเป็นตัวเลขที่มากกว่า 0", error.Errors["price"]);
        Assert.Equal("ค่าแขกเสริมต้องเป็นตัวเลขที่ไม่ติดลบ", error.Errors["extra_guest_fee"]);
        Assert.Equal("จำนวนคนพื้นฐานต้องอย่างน้อย 1", error.Errors["base_guests"]);
        Assert.Equal("จำนวนคนสูงสุดต้องไม่น้อยกว่าจำนวนคนพื้นฐาน", error.Errors["max_guests"]);
    }
}
