using System.Text.RegularExpressions;
using ResortGuestbook.Data.Entities;
using ResortGuestbook.Data.Identity;
using ResortGuestbook.Web.Infrastructure.Http;
using ResortGuestbook.Web.Services.Errors;

namespace ResortGuestbook.Web.Services.Validation;

/// <summary>A staff account: name, sign-in email, role, status and (when creating) the first password.</summary>
public static partial class UserRequest
{
    public static UserInput Validate(RequestInput input, bool creating, int passwordMinLength)
    {
        var errors = new Dictionary<string, string>();
        var name = Coerce.TrimStr(input["name"]);
        if (name.Length < 2)
        {
            errors["name"] = "กรุณากรอกชื่ออย่างน้อย 2 ตัวอักษร";
        }

        var email = AppUserStore.Normalize(Coerce.TrimStr(input["email"]));
        if (!EmailPattern().IsMatch(email))
        {
            errors["email"] = "กรุณากรอกอีเมลให้ถูกต้อง";
        }

        var role = Coerce.TrimStr(input["role"]);
        if (!Roles.All.Contains(role))
        {
            errors["role"] = "กรุณาเลือกสิทธิ์การใช้งาน";
        }

        string? password = null;
        if (creating)
        {
            password = PasswordRequest.CheckNew(input, passwordMinLength, errors);
        }

        if (errors.Count > 0)
        {
            throw new ValidationException(errors);
        }

        return new UserInput(name, email, role, Coerce.ToBool(input.Get("active", true)), password);
    }

    [GeneratedRegex(@"^[^@\s]+@[^@\s]+\.[^@\s]+$")]
    private static partial Regex EmailPattern();
}
