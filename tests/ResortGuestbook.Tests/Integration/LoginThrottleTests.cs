using System.Net;

namespace ResortGuestbook.Tests.Integration;

/// <summary>Uses its own app instance because the throttle blocks every login from the test client's address.</summary>
[Collection(WebCollection.Name)]
public sealed class LoginThrottleTests : IDisposable
{
    private readonly StayBookFactory app = new();

    [Fact]
    public async Task SixthAttemptAfterFiveFailuresIs429()
    {
        using var client = app.CreateBrowser();
        for (var i = 0; i < 5; i++)
        {
            Assert.Equal(HttpStatusCode.OK, (await Browser.PostLoginAsync(client, "nobody@staybook.local", "bad")).StatusCode);
        }

        var throttled = await Browser.PostLoginAsync(client, StayBookFactory.AdminEmail, StayBookFactory.AdminPassword);
        Assert.Equal(HttpStatusCode.TooManyRequests, throttled.StatusCode);
        Assert.Contains("ลองเข้าสู่ระบบมากเกินไป", await throttled.Content.ReadAsStringAsync(), StringComparison.Ordinal);
    }

    public void Dispose() => app.Dispose();
}
