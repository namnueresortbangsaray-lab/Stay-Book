namespace ResortGuestbook.Web.Infrastructure.Options;

/// <summary><c>App:*</c> settings.</summary>
public sealed class AppOptions
{
    public string Timezone { get; set; } = "Asia/Bangkok";

    /// <summary>Trust <c>X-Forwarded-*</c> from any proxy; enable only behind the bundled Nginx.</summary>
    public bool TrustForwardedHeaders { get; set; }
}
