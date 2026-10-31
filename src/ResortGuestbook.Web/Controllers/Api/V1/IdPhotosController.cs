using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.RateLimiting;
using ResortGuestbook.Web.Authorization;
using ResortGuestbook.Web.Infrastructure.Http;
using ResortGuestbook.Web.Services;

namespace ResortGuestbook.Web.Controllers.Api.V1;

/// <summary>ID card photos: every signed-in user can see which bookings have one; uploading and deleting need <c>booking</c>.</summary>
public sealed class IdPhotosController(IdPhotoService photos) : ApiControllerBase
{
    [HttpGet("id-photos")]
    public async Task<IActionResult> List(CancellationToken cancellationToken) =>
        ApiResults.Ok(await photos.ListAsync(cancellationToken), "โหลดรายการแล้ว");

    /// <summary>Multipart field <c>file</c>: JPEG, PNG or WebP up to <c>IdPhotos__MaxBytes</c>; replaces an earlier photo.</summary>
    [HttpPost("stays/{id}/id-photo")]
    [RequireAbility(Abilities.Booking)]
    [EnableRateLimiting(RateLimitPolicies.Writes)]
    public async Task<IActionResult> Upload(string id, CancellationToken cancellationToken)
    {
        var file = Request.HasFormContentType ? (await Request.ReadFormAsync(cancellationToken)).Files.GetFile("file") : null;
        return ApiResults.Ok(await photos.StoreAsync(id, file, HttpContext.Actor(), cancellationToken), Saved);
    }

    [HttpDelete("stays/{id}/id-photo")]
    [RequireAbility(Abilities.Booking)]
    [EnableRateLimiting(RateLimitPolicies.Writes)]
    public async Task<IActionResult> Delete(string id, CancellationToken cancellationToken)
    {
        await photos.DeleteAsync(id, HttpContext.Actor(), cancellationToken);
        return ApiResults.Ok(null, Saved);
    }
}
