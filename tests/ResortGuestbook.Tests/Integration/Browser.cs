using System.Net.Http.Json;
using System.Text.Json;
using System.Text.RegularExpressions;

namespace ResortGuestbook.Tests.Integration;

/// <summary>Signs in like a browser and keeps the antiforgery token from the page's <c>csrf-token</c> meta tag.</summary>
public static partial class Browser
{
    public static async Task<string> TokenAsync(HttpClient client, string path)
    {
        var html = await client.GetStringAsync(path);
        return CsrfMeta().Match(html).Groups[1].Value;
    }

    public static async Task<HttpResponseMessage> PostLoginAsync(HttpClient client, string email, string password, bool withToken = true)
    {
        var token = await TokenAsync(client, "/login");
        var form = new Dictionary<string, string> { ["email"] = email, ["password"] = password };
        if (withToken)
        {
            form["_token"] = token;
        }

        return await client.PostAsync("/login", new FormUrlEncodedContent(form));
    }

    /// <returns>The antiforgery token for API calls after signing in.</returns>
    public static async Task<string> SignInAsync(HttpClient client, string email, string password)
    {
        var response = await PostLoginAsync(client, email, password);
        Assert.Equal(System.Net.HttpStatusCode.Redirect, response.StatusCode);
        return await TokenAsync(client, "/");
    }

    public static async Task<HttpResponseMessage> SendJsonAsync(HttpClient client, HttpMethod method, string path, object body, string? token)
    {
        using var request = new HttpRequestMessage(method, path) { Content = JsonContent.Create(body) };
        request.Headers.Accept.ParseAdd("application/json");
        if (token is not null)
        {
            request.Headers.Add("X-CSRF-Token", token);
        }

        return await client.SendAsync(request);
    }

    public static async Task<JsonElement> EnvelopeAsync(HttpResponseMessage response) =>
        (await response.Content.ReadFromJsonAsync<JsonElement>()).Clone();

    [GeneratedRegex("name=\"csrf-token\" content=\"([^\"]+)\"")]
    private static partial Regex CsrfMeta();
}
