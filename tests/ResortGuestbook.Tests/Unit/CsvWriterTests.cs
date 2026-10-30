using System.Text;
using ResortGuestbook.Web.Models.Dtos;
using ResortGuestbook.Web.Services;

namespace ResortGuestbook.Tests.Unit;

/// <summary>Ported from the v1 <c>CsvTest</c>, plus the <c>fputcsv</c> format.</summary>
public sealed class CsvWriterTests
{
    [Fact]
    public void EscapesSpreadsheetFormulaPrefixes()
    {
        Assert.Equal("'=SUM(1,1)", CsvWriter.Safe("=SUM(1,1)"));
        Assert.Equal("'+441234", CsvWriter.Safe("+441234"));
        Assert.Equal("สมชาย", CsvWriter.Safe("สมชาย"));
    }

    [Fact]
    public void WritesBomHeaderAndV1Quoting()
    {
        var bytes = CsvWriter.Bookings([Stay("ทดสอบ Baseline", "081-234-5678", 195_000)]);
        Assert.Equal(Encoding.UTF8.GetPreamble(), bytes[..3]);
        var lines = Encoding.UTF8.GetString(bytes[3..]).Split('\n');
        Assert.Equal("\"Booking ID\",ชื่อลูกค้า,โทรศัพท์,ห้อง,เช็กอิน,เช็กเอาต์,สถานะ,\"ยอดสุทธิ (บาท)\"", lines[0]);
        Assert.Equal("00000000-0000-4000-8000-000000000001,\"ทดสอบ Baseline\",081-234-5678,1,2030-01-10,2030-01-13,2,1950.00", lines[1]);
        Assert.Equal(string.Empty, lines[2]);
    }

    private static StayDto Stay(string name, string phone, long total) => new()
    {
        Id = Guid.Parse("00000000-0000-4000-8000-000000000001"),
        GuestId = null,
        RoomId = Guid.Empty,
        GuestName = name,
        Phone = phone,
        CheckInDate = new DateOnly(2030, 1, 10),
        CheckOutDate = new DateOnly(2030, 1, 13),
        Guests = 2,
        ExtraBed = false,
        TotalAmountSatang = total,
        Status = 2,
        Note = null,
        DepositAmountSatang = 0,
        DepositPaid = false,
        IdVerified = true,
        PetType = null,
        PetCount = 0,
        PetFeeSatang = 0,
        DiscountAmountSatang = 0,
        CreatedAt = DateTimeOffset.UnixEpoch,
        UpdatedAt = DateTimeOffset.UnixEpoch,
        DeletedAt = null,
        RoomName = "1",
        Zone = "อาคารหลัก",
        RoomType = "เตียงคู่",
        RoomRateSatang = 50_000,
        BaseGuests = 2,
        MaxGuests = 3,
        ExtraGuestFeeSatang = 10_000,
        IsPetFriendly = false,
        CustomerType = null,
        IsRegular = false,
        FeedbackRating = null,
    };
}
