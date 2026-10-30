using Microsoft.Net.Http.Headers;

namespace ResortGuestbook.Web.Infrastructure.Middleware;

/// <summary>
/// The headers the v1 stack set in Nginx, with a nonce added to <c>script-src</c>. Dynamic responses are marked
/// <c>no-store</c> (as v1 sessions did); static files keep the caching set by the static file middleware.
/// </summary>
public sealed class SecurityHeadersMiddleware(RequestDelegate next)
{
    public Task InvokeAsync(HttpContext context, CspNonce nonce)
    {
        context.Response.OnStarting(() =>
        {
            var headers = context.Response.Headers;
            headers.XFrameOptions = "DENY";
            headers.XContentTypeOptions = "nosniff";
            headers["Referrer-Policy"] = "strict-origin-when-cross-origin";
            headers["Permissions-Policy"] = "camera=(self), geolocation=(), microphone=()";
            if (!context.Request.Path.StartsWithSegments("/swagger", StringComparison.Ordinal))
            {
                headers.ContentSecurityPolicy =
                    $"default-src 'self'; img-src 'self' data:; style-src 'self' 'unsafe-inline'; script-src 'self' 'nonce-{nonce.Value}'; " +
                    "font-src 'self'; connect-src 'self'; frame-ancestors 'none'; base-uri 'self'; form-action 'self'";
            }

            if (!headers.ContainsKey(HeaderNames.CacheControl))
            {
                headers.CacheControl = "no-store, no-cache, must-revalidate";
            }

            return Task.CompletedTask;
        });
        return next(context);
    }
}
