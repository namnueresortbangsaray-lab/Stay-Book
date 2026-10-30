using ResortGuestbook.Web.Infrastructure.Http;
using ResortGuestbook.Web.Services.Errors;

namespace ResortGuestbook.Web.Services.Validation;

/// <summary>Port of the PHP <c>StayRequest</c>: same rules, coercion, messages and error order.</summary>
public static class StayRequest
{
    public static StayInput Validate(RequestInput input)
    {
        var errors = new Dictionary<string, string>();
        var name = Php.TrimStr(input["guest_name"]);
        var phone = Php.TrimStr(input["phone"]);
        var from = Php.ToStr(input["check_in_date"]);
        var to = Php.ToStr(input["check_out_date"]);
        if (Php.MbStrlen(name) < 2)
        {
            errors["guest_name"] = "ชื่อลูกค้าต้องมีอย่างน้อย 2 ตัวอักษร";
        }

        if (Php.Digits(phone).Length < 9)
        {
            errors["phone"] = "เบอร์โทรต้องมีอย่างน้อย 9 หลัก";
        }

        var validFrom = Php.TryParseDate(from, out var checkIn);
        var validTo = Php.TryParseDate(to, out var checkOut);
        if (!validFrom)
        {
            errors["check_in_date"] = "วันที่เช็กอินไม่ถูกต้อง";
        }

        if (!validTo || (from.Length > 0 && string.CompareOrdinal(to, from) <= 0))
        {
            errors["check_out_date"] = "วันที่เช็กเอาต์ต้องอยู่หลังวันเช็กอิน";
        }

        var roomId = Php.TrimStr(input["room_id"]);
        if (roomId.Length == 0)
        {
            errors["room_id"] = "กรุณาเลือกห้อง";
        }

        var guests = Php.ToInt(input.Get("guests", 0L));
        if (guests < 1)
        {
            errors["guests"] = "จำนวนผู้เข้าพักต้องอย่างน้อย 1";
        }

        var petCount = (int)Math.Max(0, Php.ToInt(input.Get("pet_count", 0L)));
        var petType = Php.TrimStr(input["pet_type"]);
        if (petCount > 0 && petType.Length == 0)
        {
            errors["pet_type"] = "กรุณาระบุประเภทสัตว์เลี้ยง";
        }

        foreach (var (key, label) in new[] { ("deposit_amount", "เงินมัดจำ"), ("discount_amount", "ส่วนลด") })
        {
            if (!RoomRequest.ValidMoney(input.Get(key, 0L)))
            {
                errors[key] = $"{label}ต้องเป็นตัวเลขที่ไม่ติดลบ";
            }
        }

        var status = Php.ToInt(input.Get("status", 0L));
        if (status is < 0 or > 2)
        {
            errors["status"] = "สถานะไม่ถูกต้อง";
        }

        var idVerified = Php.ToBool(input.Get("id_verified", false));
        if (status == 1 && !idVerified)
        {
            errors["id_verified"] = "ต้องตรวจสอบบัตรประชาชนก่อนเช็กอิน";
        }

        if (errors.Count > 0)
        {
            throw new ValidationException(errors);
        }

        return new StayInput(
            name,
            phone,
            Php.ToStr(input["room_id"]),
            checkIn,
            checkOut,
            (int)guests,
            Php.ToBool(input.Get("extra_bed", false)),
            (int)status,
            Php.Clean(input["note"]),
            RoomRequest.Money(input.Get("deposit_amount", 0L)),
            Php.ToBool(input.Get("deposit_paid", false)),
            idVerified,
            petCount > 0 ? petType : null,
            petCount,
            RoomRequest.Money(input.Get("discount_amount", 0L)));
    }
}
