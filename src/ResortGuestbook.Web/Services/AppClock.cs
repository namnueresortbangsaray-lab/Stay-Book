using Microsoft.Extensions.Options;
using ResortGuestbook.Web.Infrastructure.Options;

namespace ResortGuestbook.Web.Services;

/// <summary>Current time in UTC and the current date in the resort's display timezone (Asia/Bangkok).</summary>
public sealed class AppClock(TimeProvider time, IOptions<AppOptions> options)
{
    private readonly TimeZoneInfo zone = TimeZoneInfo.FindSystemTimeZoneById(options.Value.Timezone);

    public DateTimeOffset UtcNow => time.GetUtcNow();

    public DateOnly Today => DateOnly.FromDateTime(TimeZoneInfo.ConvertTime(time.GetUtcNow(), zone).DateTime);
}
