using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.RateLimiting;
using ResortGuestbook.Data.Entities;
using ResortGuestbook.Web.Infrastructure.Http;
using ResortGuestbook.Web.Infrastructure.Identity;
using ResortGuestbook.Web.Models.ViewModels;

namespace ResortGuestbook.Web.Controllers;

public sealed class AuthController(SignInManager<AppUser> signIn, UserManager<AppUser> users, LoginThrottle throttle) : Controller
{
    public const string ThrottledMessage = "ลองเข้าสู่ระบบมากเกินไป กรุณารอ 15 นาทีแล้วลองใหม่";
    public const string InvalidMessage = "อีเมลหรือรหัสผ่านไม่ถูกต้อง";

    [AllowAnonymous]
    [HttpGet("/login")]
    [HttpHead("/login")]
    public IActionResult Login() =>
        User.Identity?.IsAuthenticated == true ? Redirect("/") : View(new LoginViewModel());

    [AllowAnonymous]
    [HttpPost("/login")]
    [EnableRateLimiting(RateLimitPolicies.Login)]
    public async Task<IActionResult> Login(LoginViewModel model)
    {
        var ip = HttpContext.ClientIp();
        if (throttle.IsThrottled(ip))
        {
            Response.StatusCode = StatusCodes.Status429TooManyRequests;
            return View(model with { Error = ThrottledMessage, Password = null });
        }

        var user = await users.FindByEmailAsync(model.Email ?? string.Empty);
        if (user is { Active: true })
        {
            var result = await signIn.CheckPasswordSignInAsync(user, model.Password ?? string.Empty, lockoutOnFailure: true);
            if (result.Succeeded)
            {
                await signIn.SignInAsync(user, isPersistent: true);
                throttle.Clear(ip);
                return Redirect("/");
            }
        }

        throttle.RecordFailure(ip);
        return View(model with { Error = InvalidMessage, Password = null });
    }

    [HttpPost("/logout")]
    public async Task<IActionResult> Logout()
    {
        await signIn.SignOutAsync();
        return Redirect("/login");
    }
}
