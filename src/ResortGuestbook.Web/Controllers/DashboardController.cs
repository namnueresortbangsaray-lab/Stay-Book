using Microsoft.AspNetCore.Mvc;
using ResortGuestbook.Web.Infrastructure.Http;

namespace ResortGuestbook.Web.Controllers;

/// <summary>The single-page staff dashboard shell; data comes from <c>/api/v1/snapshot</c>.</summary>
public sealed class DashboardController : Controller
{
    [HttpGet("/")]
    [HttpHead("/")]
    public IActionResult Index() => View(HttpContext.Actor());
}
