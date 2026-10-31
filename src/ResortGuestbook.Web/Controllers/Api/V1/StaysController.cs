using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.RateLimiting;
using ResortGuestbook.Web.Authorization;
using ResortGuestbook.Web.Infrastructure.Http;
using ResortGuestbook.Web.Services;

namespace ResortGuestbook.Web.Controllers.Api.V1;

public sealed class StaysController(ResortQueries queries, StayService stays, UploadService uploads) : ApiControllerBase
{
    /// <summary>Case-insensitive search over guest name, phone, room, zone and note; optional status 0/1/2.</summary>
    [HttpGet("stays")]
    [HttpHead("stays")]
    public async Task<IActionResult> Search([FromQuery] string? search, [FromQuery] string? status, CancellationToken cancellationToken)
    {
        if (!string.IsNullOrEmpty(status) && status is not ("0" or "1" or "2"))
        {
            return ApiResults.Error(StatusCodes.Status422UnprocessableEntity, "สถานะไม่ถูกต้อง", new Dictionary<string, string> { ["status"] = "กรุณาเลือกสถานะที่ถูกต้อง" });
        }

        int? filter = string.IsNullOrEmpty(status) ? null : status[0] - '0';
        return ApiResults.Ok(await queries.SearchStaysAsync(search ?? string.Empty, filter, cancellationToken), "โหลดรายการแล้ว");
    }

    [HttpPost("stays")]
    [RequireAbility(Abilities.Booking)]
    [EnableRateLimiting(RateLimitPolicies.Writes)]
    public async Task<IActionResult> Create(CancellationToken cancellationToken) =>
        ApiResults.Ok(await stays.SaveAsync(await InputAsync(), null, HttpContext.Actor(), cancellationToken), Saved);

    [HttpPut("stays/{id}")]
    [RequireAbility(Abilities.Booking)]
    [EnableRateLimiting(RateLimitPolicies.Writes)]
    public async Task<IActionResult> Update(string id, CancellationToken cancellationToken) =>
        ApiResults.Ok(await stays.SaveAsync(await InputAsync(), id, HttpContext.Actor(), cancellationToken), Saved);

    [HttpDelete("stays/{id}")]
    [RequireAbility(Abilities.Booking)]
    [EnableRateLimiting(RateLimitPolicies.Writes)]
    public async Task<IActionResult> Delete(string id, CancellationToken cancellationToken)
    {
        await stays.DeleteAsync(id, HttpContext.Actor(), cancellationToken);
        return ApiResults.Ok(null, Saved);
    }

    [HttpPost("stays/{id}/check-in")]
    [RequireAbility(Abilities.Booking)]
    [EnableRateLimiting(RateLimitPolicies.Writes)]
    public async Task<IActionResult> CheckIn(string id, CancellationToken cancellationToken) =>
        ApiResults.Ok(await stays.CheckInAsync(id, HttpContext.Actor(), cancellationToken), Saved);

    [HttpPost("stays/{id}/checkout")]
    [RequireAbility(Abilities.Checkout)]
    [EnableRateLimiting(RateLimitPolicies.Writes)]
    public async Task<IActionResult> Checkout(string id, CancellationToken cancellationToken) =>
        ApiResults.Ok(await stays.CheckoutAsync(id, await InputAsync(), HttpContext.Actor(), cancellationToken), Saved);

    /// <summary>Multipart field <c>file</c>: JPEG, PNG, WebP or PDF up to <c>UPLOAD_MAX_BYTES</c>.</summary>
    [HttpPost("stays/{id}/attachments")]
    [RequireAbility(Abilities.Upload)]
    [EnableRateLimiting(RateLimitPolicies.Writes)]
    public async Task<IActionResult> Upload(string id, CancellationToken cancellationToken)
    {
        var file = Request.HasFormContentType ? (await Request.ReadFormAsync(cancellationToken)).Files.GetFile("file") : null;
        return ApiResults.Ok(await uploads.StoreAsync(id, file, HttpContext.Actor(), cancellationToken), Saved);
    }
}
