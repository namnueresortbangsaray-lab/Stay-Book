using Microsoft.AspNetCore.Mvc;
using ResortGuestbook.Web.Infrastructure.Http;
using ResortGuestbook.Web.Models.Dtos;
using ResortGuestbook.Web.Services;

namespace ResortGuestbook.Web.Controllers.Api.V1;

public sealed class SnapshotController(SnapshotService snapshots) : ApiControllerBase
{
    /// <summary>Rooms, stays, guests, attachments and analytics for <c>start</c>..<c>end</c> (default: current month).</summary>
    [HttpGet("snapshot")]
    [HttpHead("snapshot")]
    [ProducesResponseType<ApiEnvelope>(StatusCodes.Status200OK)]
    public async Task<IActionResult> Get([FromQuery] string? start, [FromQuery] string? end, CancellationToken cancellationToken) =>
        ApiResults.Ok(await snapshots.GetAsync(start, end, cancellationToken), "โหลดข้อมูลแล้ว");
}
