using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.RateLimiting;
using ResortGuestbook.Web.Authorization;
using ResortGuestbook.Web.Infrastructure.Http;
using ResortGuestbook.Web.Services;

namespace ResortGuestbook.Web.Controllers.Api.V1;

/// <summary>Zone and room-type lists: readable by every signed-in user, managed with the <c>manage_rooms</c> ability.</summary>
public sealed class RoomCategoriesController(RoomCategoryService categories) : ApiControllerBase
{
    [HttpGet("room-categories")]
    public async Task<IActionResult> List(CancellationToken cancellationToken) =>
        ApiResults.Ok(await categories.ListAsync(cancellationToken), "โหลดรายการแล้ว");

    [HttpPost("room-zones")]
    [RequireAbility(Abilities.ManageRooms)]
    [EnableRateLimiting(RateLimitPolicies.Writes)]
    public async Task<IActionResult> CreateZone(CancellationToken cancellationToken) =>
        ApiResults.Ok(await categories.SaveZoneAsync(await InputAsync(), null, HttpContext.Actor(), cancellationToken), Saved);

    [HttpPut("room-zones/{id}")]
    [RequireAbility(Abilities.ManageRooms)]
    [EnableRateLimiting(RateLimitPolicies.Writes)]
    public async Task<IActionResult> UpdateZone(string id, CancellationToken cancellationToken) =>
        ApiResults.Ok(await categories.SaveZoneAsync(await InputAsync(), id, HttpContext.Actor(), cancellationToken), Saved);

    [HttpDelete("room-zones/{id}")]
    [RequireAbility(Abilities.ManageRooms)]
    [EnableRateLimiting(RateLimitPolicies.Writes)]
    public async Task<IActionResult> DeleteZone(string id, CancellationToken cancellationToken)
    {
        await categories.DeleteZoneAsync(id, HttpContext.Actor(), cancellationToken);
        return ApiResults.Ok(null, Saved);
    }

    [HttpPost("room-types")]
    [RequireAbility(Abilities.ManageRooms)]
    [EnableRateLimiting(RateLimitPolicies.Writes)]
    public async Task<IActionResult> CreateType(CancellationToken cancellationToken) =>
        ApiResults.Ok(await categories.SaveTypeAsync(await InputAsync(), null, HttpContext.Actor(), cancellationToken), Saved);

    [HttpPut("room-types/{id}")]
    [RequireAbility(Abilities.ManageRooms)]
    [EnableRateLimiting(RateLimitPolicies.Writes)]
    public async Task<IActionResult> UpdateType(string id, CancellationToken cancellationToken) =>
        ApiResults.Ok(await categories.SaveTypeAsync(await InputAsync(), id, HttpContext.Actor(), cancellationToken), Saved);

    [HttpDelete("room-types/{id}")]
    [RequireAbility(Abilities.ManageRooms)]
    [EnableRateLimiting(RateLimitPolicies.Writes)]
    public async Task<IActionResult> DeleteType(string id, CancellationToken cancellationToken)
    {
        await categories.DeleteTypeAsync(id, HttpContext.Actor(), cancellationToken);
        return ApiResults.Ok(null, Saved);
    }
}
