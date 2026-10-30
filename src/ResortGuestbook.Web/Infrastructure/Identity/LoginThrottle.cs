using System.Collections.Concurrent;
using Microsoft.Extensions.Options;
using ResortGuestbook.Web.Infrastructure.Options;

namespace ResortGuestbook.Web.Infrastructure.Identity;

/// <summary>
/// Per-IP failed-login window (v1: 5 failures in 900 s blocks further attempts; a success clears the counter).
/// Only failures count, which a request-rate limiter cannot express.
/// </summary>
public sealed class LoginThrottle(TimeProvider time, IOptions<AuthOptions> options)
{
    private readonly ConcurrentDictionary<string, List<DateTimeOffset>> failures = new(StringComparer.Ordinal);

    public bool IsThrottled(string ip) => Recent(ip).Count >= options.Value.LoginAttempts;

    public void RecordFailure(string ip)
    {
        var list = failures.GetOrAdd(ip, _ => []);
        lock (list)
        {
            Prune(list);
            list.Add(time.GetUtcNow());
        }
    }

    public void Clear(string ip) => failures.TryRemove(ip, out _);

    private List<DateTimeOffset> Recent(string ip)
    {
        if (!failures.TryGetValue(ip, out var list))
        {
            return [];
        }

        lock (list)
        {
            Prune(list);
            return [.. list];
        }
    }

    private void Prune(List<DateTimeOffset> list)
    {
        var cutoff = time.GetUtcNow().AddSeconds(-options.Value.LoginWindowSeconds);
        list.RemoveAll(t => t <= cutoff);
    }
}
