using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Diagnostics;
using Microsoft.AspNetCore.Mvc;
using ResortGuestbook.Web.Infrastructure.Http;

namespace ResortGuestbook.Web.Controllers;

/// <summary>
/// Re-executed for unmatched routes, bare status codes and unhandled exceptions. API paths get the JSON envelope,
/// everything else the HTML error page. Accepts any method because re-execution keeps the original one.
/// </summary>
[AllowAnonymous]
[IgnoreAntiforgeryToken]
[ApiExplorerSettings(IgnoreApi = true)]
public sealed class ErrorsController : Controller
{
    [Route("errors/{status:int}")]
    public IActionResult Status(int status)
    {
        var path = HttpContext.Features.Get<IStatusCodeReExecuteFeature>()?.OriginalPath ?? Request.Path.Value ?? "/";
        var (code, message) = ErrorPages.Describe(status);
        return Render(path, code, message);
    }

    [Route("errors/exception")]
    public IActionResult Exception()
    {
        var path = HttpContext.Features.Get<IExceptionHandlerPathFeature>()?.Path ?? "/";
        return Render(path, StatusCodes.Status500InternalServerError, ErrorPages.ServerError);
    }

    private IActionResult Render(string originalPath, int status, string message) =>
        originalPath.StartsWith("/api/", StringComparison.Ordinal)
            ? ApiResults.Error(status, message)
            : ErrorPages.View(status, message);
}
