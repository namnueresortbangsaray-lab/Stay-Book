using System.ComponentModel.DataAnnotations;

namespace ResortGuestbook.Web.Models.ViewModels;

/// <summary>Login form. Invalid input is answered like wrong credentials (as in PHP), so annotations only shape the form.</summary>
public sealed record LoginViewModel
{
    [EmailAddress]
    [Display(Name = "อีเมลเข้าใช้งาน")]
    public string? Email { get; init; }

    [DataType(DataType.Password)]
    [Display(Name = "รหัสผ่าน")]
    public string? Password { get; init; }

    public string? Error { get; init; }
}
