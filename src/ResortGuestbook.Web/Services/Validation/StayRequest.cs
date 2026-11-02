using ResortGuestbook.Data.Entities;
using ResortGuestbook.Web.Infrastructure.Http;
using ResortGuestbook.Web.Services.Errors;

namespace ResortGuestbook.Web.Services.Validation;

/// <summary>Port of the v1 <c>StayRequest</c>: same rules, coercion, messages and error order.</summary>
public static class StayRequest
{
    public static StayInput Validate(RequestInput input)
    {
        var errors = new Dictionary<string, string>();
        var name = Coerce.TrimStr(input["guest_name"]);
        var phone = Coerce.TrimStr(input["phone"]);
        var from = Coerce.ToStr(input["check_in_date"]);
        var to = Coerce.ToStr(input["check_out_date"]);
        if (Coerce.MbStrlen(name) < 2)
        {
            errors["guest_name"] = "ชื่อลูกค้าต้องมีอย่างน้อย 2 ตัวอักษร";
        }

        if (Coerce.Digits(phone).Length < 9)
        {
            errors["phone"] = "เบอร์โทรต้องมีอย่างน้อย 9 หลัก";
        }

        var validFrom = Coerce.TryParseDate(from, out var checkIn);
        var validTo = Coerce.TryParseDate(to, out var checkOut);
        if (!validFrom)
        {
            errors["check_in_date"] = "วันที่เช็กอินไม่ถูกต้อง";
        }

        if (!validTo || (from.Length > 0 && string.CompareOrdinal(to, from) <= 0))
        {
            errors["check_out_date"] = "วันที่เช็กเอาต์ต้องอยู่หลังวันเช็กอิน";
        }

        var roomId = Coerce.TrimStr(input["room_id"]);
        if (roomId.Length == 0)
        {
            errors["room_id"] = "กรุณาเลือกห้อง";
        }

        var guests = Coerce.ToInt(input.Get("guests", 0L));
        if (guests < 1)
        {
            errors["guests"] = "จำนวนผู้เข้าพักต้องอย่างน้อย 1";
        }

        var petCount = (int)Math.Max(0, Coerce.ToInt(input.Get("pet_count", 0L)));
        var petType = Coerce.TrimStr(input["pet_type"]);
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

        var status = Coerce.ToInt(input.Get("status", 0L));
        if (status is < 0 or > 2)
        {
            errors["status"] = "สถานะไม่ถูกต้อง";
        }

        var idVerified = Coerce.ToBool(input.Get("id_verified", false));
        if (status == 1 && !idVerified)
        {
            errors["id_verified"] = "ต้องตรวจสอบบัตรประชาชนก่อนเช็กอิน";
        }

        // Added after v1 (D-27): optional; null when the field is not sent, so v1 clients keep the stored value.
        var channel = input["booking_channel"] is null ? null : Coerce.TrimStr(input["booking_channel"]);
        if (channel is { Length: > 0 } && !BookingChannels.All.Contains(channel))
        {
            errors["booking_channel"] = "กรุณาเลือกช่องทางการจองที่ถูกต้อง";
        }

        if (errors.Count > 0)
        {
            throw new ValidationException(errors);
        }

        return new StayInput(
            name,
            phone,
            Coerce.ToStr(input["room_id"]),
            checkIn,
            checkOut,
            (int)guests,
            Coerce.ToBool(input.Get("extra_bed", false)),
            (int)status,
            Coerce.Clean(input["note"]),
            RoomRequest.Money(input.Get("deposit_amount", 0L)),
            Coerce.ToBool(input.Get("deposit_paid", false)),
            idVerified,
            petCount > 0 ? petType : null,
            petCount,
            RoomRequest.Money(input.Get("discount_amount", 0L)),
            channel);
    }
}
