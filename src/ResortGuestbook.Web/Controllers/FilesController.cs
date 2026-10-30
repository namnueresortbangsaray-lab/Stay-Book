using System.Text.RegularExpressions;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using ResortGuestbook.Data;
using ResortGuestbook.Web.Infrastructure.Http;
using ResortGuestbook.Web.Infrastructure.Storage;

namespace ResortGuestbook.Web.Controllers;

/// <summary>Authenticated attachment download; uploads have no public URL.</summary>
public sealed partial class FilesController(AppDbContext db, IFileStorage storage) : Controller
{
    private const string NotFoundMessage = "ไม่พบไฟล์";

    [HttpGet("/files/{id}")]
    [HttpHead("/files/{id}")]
    public async Task<IActionResult> Download(string id, CancellationToken cancellationToken)
    {
        var attachment = Guid.TryParse(id, out var key)
            ? await db.Attachments.AsNoTracking().FirstOrDefaultAsync(a => a.Id == key, cancellationToken)
            : null;
        var stream = attachment is null ? null : await storage.OpenReadAsync(attachment.StoredName, cancellationToken);
        if (attachment is null || stream is null)
        {
            return ApiResults.Error(StatusCodes.Status404NotFound, NotFoundMessage);
        }

        var name = UnsafeFileNameCharacters().Replace(attachment.OriginalName, "_");
        Response.Headers.ContentDisposition = $"attachment; filename=\"{(name.Length > 0 ? name : "download")}\"";
        return File(stream, attachment.MimeType);
    }

    /// <summary>v1: <c>preg_replace('/[^\pL\pN._ -]+/u', '_', $name)</c>.</summary>
    [GeneratedRegex(@"[^\p{L}\p{N}._ -]+")]
    private static partial Regex UnsafeFileNameCharacters();
}
