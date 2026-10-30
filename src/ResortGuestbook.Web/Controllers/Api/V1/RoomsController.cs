using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.RateLimiting;
using ResortGuestbook.Web.Authorization;
using ResortGuestbook.Web.Infrastructure.Http;
using ResortGuestbook.Web.Services;

namespace ResortGuestbook.Web.Controllers.Api.V1;

[EnableRateLimiting(RateLimitPolicies.Writes)]
public sealed class RoomsController(RoomService rooms) : ApiControllerBase
{
    [HttpPost("rooms")]
    [RequireAbility(Abilities.ManageRooms)]
    public async Task<IActionResult> Create(CancellationToken cancellationToken) =>
        ApiResults.Ok(await rooms.SaveAsync(await InputAsync(), null, HttpContext.Actor(), cancellationToken), Saved);

    [HttpPut("rooms/{id}")]
    [RequireAbility(Abilities.ManageRooms)]
    public async Task<IActionResult> Update(string id, CancellationToken cancellationToken) =>
        ApiResults.Ok(await rooms.SaveAsync(await InputAsync(), id, HttpContext.Actor(), cancellationToken), Saved);

    [HttpDelete("rooms/{id}")]
    [RequireAbility(Abilities.ManageRooms)]
    public async Task<IActionResult> Delete(string id, CancellationToken cancellationToken)
    {
        await rooms.DeleteAsync(id, HttpContext.Actor(), cancellationToken);
        return ApiResults.Ok(null, Saved);
    }
}
