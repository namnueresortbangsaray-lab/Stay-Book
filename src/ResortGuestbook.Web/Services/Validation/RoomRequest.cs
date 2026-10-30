using ResortGuestbook.Web.Infrastructure.Http;
using ResortGuestbook.Web.Services.Errors;

namespace ResortGuestbook.Web.Services.Validation;

/// <summary>Port of the PHP <c>RoomRequest</c>: same rules, coercion, messages and error order.</summary>
public static class RoomRequest
{
    public static RoomInput Validate(RequestInput input)
    {
        var errors = new Dictionary<string, string>();
        foreach (var (key, label) in new[] { ("name", "ชื่อห้อง"), ("zone", "โซน"), ("type", "ประเภทห้อง") })
        {
            if (Php.TrimStr(input[key]).Length == 0)
            {
                errors[key] = $"กรุณากรอก{label}";
            }
        }

        var price = Money(input["price"]);
        var extraGuestFee = Money(input.Get("extra_guest_fee", 0L));
        var baseGuests = (int)Php.ToInt(input.Get("base_guests", 0L));
        var maxGuests = (int)Php.ToInt(input.Get("max_guests", 0L));
        if (price < 1)
        {
            errors["price"] = "ราคาต้องมากกว่า 0";
        }

        if (!ValidMoney(input["price"], allowZero: false))
        {
            errors["price"] = "ราคาต้องเป็นตัวเลขที่มากกว่า 0";
        }

        if (!ValidMoney(input.Get("extra_guest_fee", 0L)))
        {
            errors["extra_guest_fee"] = "ค่าแขกเสริมต้องเป็นตัวเลขที่ไม่ติดลบ";
        }

        if (baseGuests < 1)
        {
            errors["base_guests"] = "จำนวนคนพื้นฐานต้องอย่างน้อย 1";
        }

        if (maxGuests < baseGuests)
        {
            errors["max_guests"] = "จำนวนคนสูงสุดต้องไม่น้อยกว่าจำนวนคนพื้นฐาน";
        }

        if (errors.Count > 0)
        {
            throw new ValidationException(errors);
        }

        return new RoomInput(
            Php.TrimStr(input["name"]),
            Php.TrimStr(input["zone"]),
            Php.TrimStr(input["type"]),
            price,
            baseGuests,
            maxGuests,
            extraGuestFee,
            (int)Math.Max(0, Php.ToInt(input.Get("sort_order", 0L))),
            Php.ToBool(input.Get("is_pet_friendly", false)));
    }

    /// <summary>Decimal baht to satang: <c>(int) round(max(0, (float) $value) * 100)</c>.</summary>
    public static long Money(object? value) =>
        (long)Math.Round(Math.Max(0, Php.ToFloat(value)) * 100, MidpointRounding.AwayFromZero);

    public static bool ValidMoney(object? value, bool allowZero = true) =>
        Php.IsNumeric(value) && (allowZero ? Php.ToFloat(value) >= 0 : Php.ToFloat(value) > 0);
}
