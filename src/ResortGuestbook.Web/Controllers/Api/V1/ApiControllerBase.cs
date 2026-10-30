using Microsoft.AspNetCore.Mvc;
using ResortGuestbook.Web.Infrastructure.Http;

namespace ResortGuestbook.Web.Controllers.Api.V1;

/// <summary>
/// Base for <c>/api/v1</c> controllers. Request bodies are read with PHP coercion (<see cref="RequestInput"/>) instead of
/// strict model binding, so <c>[ApiController]</c>'s automatic 400 responses are not used.
/// </summary>
[Route("api/v1")]
[TypeFilter<ApiExceptionFilter>]
[Produces("application/json")]
public abstract class ApiControllerBase : ControllerBase
{
    public const string Saved = "บันทึกเรียบร้อย";

    protected Task<RequestInput> InputAsync() => RequestInput.ReadAsync(Request, HttpContext.RequestAborted);
}
