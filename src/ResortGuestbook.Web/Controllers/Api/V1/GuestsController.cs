using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.RateLimiting;
using ResortGuestbook.Web.Authorization;
using ResortGuestbook.Web.Infrastructure.Http;
using ResortGuestbook.Web.Services;

namespace ResortGuestbook.Web.Controllers.Api.V1;

[EnableRateLimiting(RateLimitPolicies.Writes)]
public sealed class GuestsController(GuestService guests) : ApiControllerBase
{
    [HttpPut("guests/{id}")]
    [RequireAbility(Abilities.EditGuest)]
    public async Task<IActionResult> Update(string id, CancellationToken cancellationToken) =>
        ApiResults.Ok(await guests.UpdateAsync(await InputAsync(), id, HttpContext.Actor(), cancellationToken), Saved);
}
