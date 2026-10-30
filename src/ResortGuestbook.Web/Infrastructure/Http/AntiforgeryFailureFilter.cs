using Microsoft.AspNetCore.Mvc.Core.Infrastructure;
using Microsoft.AspNetCore.Mvc.Filters;

namespace ResortGuestbook.Web.Infrastructure.Http;

/// <summary>Turns a failed antiforgery check (MVC's 400) into v1's 419 "session expired" response.</summary>
public sealed class AntiforgeryFailureFilter : IAlwaysRunResultFilter
{
    public const string Message = "เซสชันหมดอายุ กรุณาลองใหม่";

    public void OnResultExecuting(ResultExecutingContext context)
    {
        if (context.Result is IAntiforgeryValidationFailedResult)
        {
            context.Result = ApiResults.IsApi(context.HttpContext.Request)
                ? ApiResults.Error(StatusCodes.Status419AuthenticationTimeout, Message)
                : ErrorPages.View(StatusCodes.Status419AuthenticationTimeout, Message);
        }
    }

    public void OnResultExecuted(ResultExecutedContext context)
    {
    }
}
