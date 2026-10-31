using ResortGuestbook.Web.Infrastructure.Http;
using ResortGuestbook.Web.Services.Errors;

namespace ResortGuestbook.Web.Services.Validation;

/// <summary>New password plus confirmation: a minimum length only, no composition rules (NIST SP 800-63B).</summary>
public static class PasswordRequest
{
    public static string Validate(RequestInput input, int minLength)
    {
        var errors = new Dictionary<string, string>();
        var password = CheckNew(input, minLength, errors);
        if (errors.Count > 0)
        {
            throw new ValidationException(errors);
        }

        return password;
    }

    /// <summary>Checks <c>password</c> and <c>confirm_password</c>, adding errors; returns the password as typed.</summary>
    public static string CheckNew(RequestInput input, int minLength, Dictionary<string, string> errors)
    {
        var password = input["password"] as string ?? string.Empty;
        if (password.Length < minLength)
        {
            errors["password"] = $"รหัสผ่านต้องมีอย่างน้อย {minLength} ตัวอักษร";
        }
        else if (password != (input["confirm_password"] as string ?? string.Empty))
        {
            errors["confirm_password"] = "รหัสผ่านยืนยันไม่ตรงกัน";
        }

        return password;
    }
}
