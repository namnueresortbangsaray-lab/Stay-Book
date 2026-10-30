using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;

namespace ResortGuestbook.Web.Authorization;

public sealed class AbilityHandler : AuthorizationHandler<AbilityRequirement>
{
    protected override Task HandleRequirementAsync(AuthorizationHandlerContext context, AbilityRequirement requirement)
    {
        if (Abilities.Allows(context.User.FindFirstValue(ClaimTypes.Role), requirement.Ability))
        {
            context.Succeed(requirement);
        }

        return Task.CompletedTask;
    }
}
