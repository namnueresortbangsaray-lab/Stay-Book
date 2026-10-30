using System.Globalization;
using Microsoft.AspNetCore.Mvc;
using ResortGuestbook.Web.Services;

namespace ResortGuestbook.Web.Controllers.Api.V1;

public sealed class ReportsController(SnapshotService snapshots, ResortQueries queries, AppClock clock) : ApiControllerBase
{
    /// <summary>All bookings as CSV (UTF-8 with BOM). The range is validated like the snapshot, as in v1.</summary>
    [HttpGet("reports/bookings.csv")]
    [HttpHead("reports/bookings.csv")]
    [Produces("text/csv")]
    public async Task<IActionResult> Bookings([FromQuery] string? start, [FromQuery] string? end, CancellationToken cancellationToken)
    {
        snapshots.ResolveRange(start, end);
        var csv = CsvWriter.Bookings(await queries.StaysAsync(cancellationToken));
        Response.Headers.ContentDisposition = $"attachment; filename=\"stay-book-report-{clock.Today.ToString("yyyy-MM-dd", CultureInfo.InvariantCulture)}.csv\"";
        return File(csv, "text/csv; charset=utf-8");
    }
}
