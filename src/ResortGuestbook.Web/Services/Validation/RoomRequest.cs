using ResortGuestbook.Web.Infrastructure.Http;
using ResortGuestbook.Web.Services.Errors;

namespace ResortGuestbook.Web.Services.Validation;

/// <summary>Port of the v1 <c>RoomRequest</c>: same rules, coercion, messages and error order.</summary>
public static class RoomRequest
{
    public static RoomInput Validate(RequestInput input)
    {
        var errors = new Dictionary<string, string>();
        foreach (var (key, label) in new[] { ("name", "ชื่อห้อง"), ("zone", "โซน"), ("type", "ประเภทห้อง") })
        {
            if (Coerce.TrimStr(input[key]).Length == 0)
            {
                errors[key] = $"กรุณากรอก{label}";
            }
        }

        var (price, extraGuestFee, baseGuests, maxGuests) = Pricing(input, errors);
        if (errors.Count > 0)
        {
            throw new ValidationException(errors);
        }

        return new RoomInput(
            Coerce.TrimStr(input["name"]),
            Coerce.TrimStr(input["zone"]),
            Coerce.TrimStr(input["type"]),
            price,
            baseGuests,
            maxGuests,
            extraGuestFee,
            (int)Math.Max(0, Coerce.ToInt(input.Get("sort_order", 0L))),
            Coerce.ToBool(input.Get("is_pet_friendly", false)));
    }

    /// <summary>Price, extra-guest fee and guest counts with the v1 rules and messages (shared with room types).</summary>
    public static (long Price, long ExtraGuestFee, int BaseGuests, int MaxGuests) Pricing(RequestInput input, Dictionary<string, string> errors)
    {
        var price = Money(input["price"]);
        var extraGuestFee = Money(input.Get("extra_guest_fee", 0L));
        var baseGuests = (int)Coerce.ToInt(input.Get("base_guests", 0L));
        var maxGuests = (int)Coerce.ToInt(input.Get("max_guests", 0L));
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

        return (price, extraGuestFee, baseGuests, maxGuests);
    }

    /// <summary>Decimal baht to satang: <c>(int) round(max(0, (float) $value) * 100)</c>.</summary>
    public static long Money(object? value) =>
        (long)Math.Round(Math.Max(0, Coerce.ToFloat(value)) * 100, MidpointRounding.AwayFromZero);

    public static bool ValidMoney(object? value, bool allowZero = true) =>
        Coerce.IsNumeric(value) && (allowZero ? Coerce.ToFloat(value) >= 0 : Coerce.ToFloat(value) > 0);
}
