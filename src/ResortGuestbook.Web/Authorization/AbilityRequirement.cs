using Microsoft.AspNetCore.Authorization;

namespace ResortGuestbook.Web.Authorization;

public sealed record AbilityRequirement(string Ability) : IAuthorizationRequirement;
