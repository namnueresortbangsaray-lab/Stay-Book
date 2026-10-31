using ResortGuestbook.Web.Infrastructure.Http;
using ResortGuestbook.Web.Services.Errors;
using ResortGuestbook.Web.Services.Validation;

namespace ResortGuestbook.Tests.Unit;

public sealed class UserRequestTests
{
    [Fact]
    public void ValidAccountIsNormalised()
    {
        var user = UserRequest.Validate(Input(("name", " สมชาย "), ("email", " Somchai@Resort.TEST "), ("role", "housekeeping"), ("active", "0")), creating: false, 10);
        Assert.Equal(new UserInput("สมชาย", "somchai@resort.test", "housekeeping", false, null), user);
    }

    [Fact]
    public void InvalidAccountReportsEveryField()
    {
        var exception = Assert.Throws<ValidationException>(() => UserRequest.Validate(
            Input(("name", "ก"), ("email", "not-an-email"), ("role", "owner"), ("password", "123"), ("confirm_password", "123")), creating: true, 10));
        Assert.Equal(["name", "email", "role", "password"], exception.Errors.Keys);
        Assert.Equal("รหัสผ่านต้องมีอย่างน้อย 10 ตัวอักษร", exception.Errors["password"]);
    }

    [Fact]
    public void PasswordNeedsLengthAndMatchingConfirmationOnly()
    {
        Assert.Equal("all lowercase words", PasswordRequest.Validate(Input(("password", "all lowercase words"), ("confirm_password", "all lowercase words")), 10));
        var mismatch = Assert.Throws<ValidationException>(() => PasswordRequest.Validate(Input(("password", "long enough 1"), ("confirm_password", "long enough 2")), 10));
        Assert.Equal("รหัสผ่านยืนยันไม่ตรงกัน", mismatch.Errors["confirm_password"]);
    }

    private static RequestInput Input(params (string Key, object? Value)[] values) =>
        new(values.ToDictionary(v => v.Key, v => v.Value));
}
