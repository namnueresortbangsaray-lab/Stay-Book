using ResortGuestbook.Web.Infrastructure.Http;
using ResortGuestbook.Web.Services.Errors;

namespace ResortGuestbook.Web.Services.Validation;

/// <summary>A room type and its room defaults; price and guest rules and messages are the room ones.</summary>
public static class RoomTypeRequest
{
    public static RoomTypeInput Validate(RequestInput input)
    {
        var errors = new Dictionary<string, string>();
        var name = Coerce.TrimStr(input["name"]);
        if (name.Length == 0)
        {
            errors["name"] = "กรุณากรอกชื่อประเภทห้อง";
        }

        var (price, extraGuestFee, baseGuests, maxGuests) = RoomRequest.Pricing(input, errors);
        if (errors.Count > 0)
        {
            throw new ValidationException(errors);
        }

        return new RoomTypeInput(
            name,
            price,
            baseGuests,
            maxGuests,
            extraGuestFee,
            Coerce.ToBool(input.Get("is_pet_friendly", false)),
            (int)Math.Max(0, Coerce.ToInt(input.Get("sort_order", 0L))));
    }
}
