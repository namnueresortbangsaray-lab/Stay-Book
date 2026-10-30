using ResortGuestbook.Web.Infrastructure.Http;

namespace ResortGuestbook.Tests.Data;

/// <summary>Request input builders mirroring the v1 test fixtures.</summary>
public static class TestInputs
{
    public static RequestInput Input(params (string Key, object? Value)[] values) =>
        new(values.ToDictionary(v => v.Key, v => v.Value));

    public static RequestInput Stay(Guid roomId, params (string Key, object? Value)[] overrides)
    {
        var values = new Dictionary<string, object?>
        {
            ["guest_name"] = "ลูกค้า ทดสอบ",
            ["phone"] = "0812345678",
            ["room_id"] = roomId.ToString(),
            ["check_in_date"] = "2030-01-10",
            ["check_out_date"] = "2030-01-12",
            ["guests"] = 2L,
            ["extra_bed"] = false,
            ["status"] = 0L,
            ["deposit_amount"] = 0L,
            ["deposit_paid"] = false,
            ["id_verified"] = false,
            ["pet_count"] = 0L,
            ["discount_amount"] = 0L,
            ["note"] = "ทดสอบระบบ",
        };
        foreach (var (key, value) in overrides)
        {
            values[key] = value;
        }

        return new RequestInput(values);
    }
}
