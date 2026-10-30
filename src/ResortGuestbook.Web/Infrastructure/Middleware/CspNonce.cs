using System.Security.Cryptography;

namespace ResortGuestbook.Web.Infrastructure.Middleware;

/// <summary>Per-request nonce for <c>script-src</c>; render it on every <c>&lt;script&gt;</c> tag.</summary>
public sealed class CspNonce
{
    public string Value { get; } = Convert.ToBase64String(RandomNumberGenerator.GetBytes(16));
}
