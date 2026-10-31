using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.RateLimiting;
using ResortGuestbook.Data.Entities;
using ResortGuestbook.Web.Authorization;
using ResortGuestbook.Web.Infrastructure.Http;
using ResortGuestbook.Web.Services;

namespace ResortGuestbook.Web.Controllers.Api.V1;

/// <summary>Staff accounts (admins only, <c>manage_users</c>) and the signed-in user's own password.</summary>
public sealed class UsersController(UserService users, SignInManager<AppUser> signIn) : ApiControllerBase
{
    [HttpGet("users")]
    [RequireAbility(Abilities.ManageUsers)]
    public async Task<IActionResult> List(CancellationToken cancellationToken) =>
        ApiResults.Ok(await users.ListAsync(cancellationToken), "โหลดรายการแล้ว");

    [HttpPost("users")]
    [RequireAbility(Abilities.ManageUsers)]
    [EnableRateLimiting(RateLimitPolicies.Writes)]
    public async Task<IActionResult> Create(CancellationToken cancellationToken) =>
        ApiResults.Ok(await users.CreateAsync(await InputAsync(), HttpContext.Actor(), cancellationToken), Saved);

    [HttpPut("users/{id}")]
    [RequireAbility(Abilities.ManageUsers)]
    [EnableRateLimiting(RateLimitPolicies.Writes)]
    public async Task<IActionResult> Update(string id, CancellationToken cancellationToken) =>
        ApiResults.Ok(await users.UpdateAsync(await InputAsync(), id, HttpContext.Actor(), cancellationToken), Saved);

    [HttpPost("users/{id}/password")]
    [RequireAbility(Abilities.ManageUsers)]
    [EnableRateLimiting(RateLimitPolicies.Writes)]
    public async Task<IActionResult> SetPassword(string id, CancellationToken cancellationToken) =>
        ApiResults.Ok(await users.SetPasswordAsync(await InputAsync(), id, HttpContext.Actor(), cancellationToken), Saved);

    /// <summary>Any signed-in user; this session stays signed in, the user's other sessions end.</summary>
    [HttpPost("account/password")]
    [EnableRateLimiting(RateLimitPolicies.Writes)]
    public async Task<IActionResult> ChangeOwnPassword(CancellationToken cancellationToken)
    {
        var user = await users.ChangeOwnPasswordAsync(await InputAsync(), HttpContext.Actor(), cancellationToken);
        await signIn.RefreshSignInAsync(user);
        return ApiResults.Ok(null, Saved);
    }
}
