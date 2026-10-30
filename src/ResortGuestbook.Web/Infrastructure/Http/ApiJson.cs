using System.Text.Encodings.Web;
using System.Text.Json;

namespace ResortGuestbook.Web.Infrastructure.Http;

/// <summary>
/// JSON settings matching v1 <c>json_encode(..., JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES)</c> with snake_case keys.
/// </summary>
public static class ApiJson
{
    public static JsonSerializerOptions Options { get; } = Configure(new JsonSerializerOptions());

    public static JsonSerializerOptions Configure(JsonSerializerOptions options)
    {
        options.PropertyNamingPolicy = JsonNamingPolicy.SnakeCaseLower;
        options.DictionaryKeyPolicy = null;
        options.Encoder = JavaScriptEncoder.UnsafeRelaxedJsonEscaping;
        options.Converters.Add(new UtcTimestampJsonConverter());
        return options;
    }
}
