using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc.Filters;
using ResortGuestbook.Web.Infrastructure.Http;

namespace ResortGuestbook.Web.Authorization;

/// <summary>
/// Checks an ability policy as an action filter, i.e. after authentication (401) and antiforgery (419), matching the
/// PHP order in which the policy check happened inside the handler. Failure is a 403 envelope.
/// </summary>
[AttributeUsage(AttributeTargets.Method)]
public sealed class RequireAbilityAttribute(string ability) : Attribute, IAsyncActionFilter
{
    public string Ability { get; } = ability;

    public async Task OnActionExecutionAsync(ActionExecutingContext context, ActionExecutionDelegate next)
    {
        var authorization = context.HttpContext.RequestServices.GetRequiredService<IAuthorizationService>();
        var result = await authorization.AuthorizeAsync(context.HttpContext.User, Ability);
        if (!result.Succeeded)
        {
            context.Result = ApiResults.Error(StatusCodes.Status403Forbidden, "ไม่มีสิทธิ์ดำเนินการ");
            return;
        }

        await next();
    }
}
