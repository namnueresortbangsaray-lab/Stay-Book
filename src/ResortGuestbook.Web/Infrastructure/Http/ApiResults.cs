using Microsoft.AspNetCore.Mvc;
using ResortGuestbook.Web.Models.Dtos;

namespace ResortGuestbook.Web.Infrastructure.Http;

/// <summary>Builds the v1-compatible JSON envelope; <c>success</c> is <c>status &lt; 400</c>.</summary>
public static class ApiResults
{
    public const string ContentType = "application/json; charset=utf-8";

    private static readonly IReadOnlyDictionary<string, string> NoErrors = new Dictionary<string, string>();

    public static ObjectResult Ok(object? data, string message) => Envelope(StatusCodes.Status200OK, data, message, NoErrors);

    public static ObjectResult Error(int status, string message, IReadOnlyDictionary<string, string>? errors = null) =>
        Envelope(status, null, message, errors ?? NoErrors);

    public static ApiEnvelope Body(int status, object? data, string message, IReadOnlyDictionary<string, string>? errors = null) =>
        new(status < 400, data, message, errors ?? NoErrors);

    /// <summary>Writes an envelope directly (middleware and authentication events).</summary>
    public static Task WriteAsync(HttpContext context, int status, string message)
    {
        context.Response.StatusCode = status;
        context.Response.ContentType = ContentType;
        return context.Response.WriteAsync(System.Text.Json.JsonSerializer.Serialize(Body(status, null, message), ApiJson.Options), context.RequestAborted);
    }

    public static bool IsApi(HttpRequest request) => request.Path.StartsWithSegments("/api", StringComparison.Ordinal);

    private static ObjectResult Envelope(int status, object? data, string message, IReadOnlyDictionary<string, string> errors) =>
        new(Body(status, data, message, errors)) { StatusCode = status };
}
