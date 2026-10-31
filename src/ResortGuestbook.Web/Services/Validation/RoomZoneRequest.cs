using ResortGuestbook.Web.Infrastructure.Http;
using ResortGuestbook.Web.Services.Errors;

namespace ResortGuestbook.Web.Services.Validation;

/// <summary>A location zone: a name and its place in lists.</summary>
public static class RoomZoneRequest
{
    public static RoomZoneInput Validate(RequestInput input)
    {
        var name = Coerce.TrimStr(input["name"]);
        if (name.Length == 0)
        {
            throw new ValidationException("name", "กรุณากรอกชื่อโซน");
        }

        return new RoomZoneInput(name, (int)Math.Max(0, Coerce.ToInt(input.Get("sort_order", 0L))));
    }
}
