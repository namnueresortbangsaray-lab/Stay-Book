using System.Text.Json;

namespace ResortGuestbook.Web.Infrastructure.Http;

/// <summary>
/// The PHP <c>Request::input()</c>: the JSON object body when the content type is JSON, otherwise the form fields.
/// Invalid or non-object JSON yields an empty input (validation then reports the missing fields).
/// </summary>
public sealed class RequestInput
{
    private readonly Dictionary<string, object?> values;

    public RequestInput(Dictionary<string, object?> values) => this.values = values;

    public static RequestInput Empty { get; } = new([]);

    /// <summary><c>$input[$key] ?? null</c>.</summary>
    public object? this[string key] => values.GetValueOrDefault(key);

    /// <summary><c>$input[$key] ?? $fallback</c> (null counts as missing, like PHP's <c>??</c>).</summary>
    public object? Get(string key, object? fallback) => values.GetValueOrDefault(key) ?? fallback;

    public static async Task<RequestInput> ReadAsync(HttpRequest request, CancellationToken cancellationToken)
    {
        if (request.ContentType?.Contains("application/json", StringComparison.OrdinalIgnoreCase) == true)
        {
            try
            {
                using var document = await JsonDocument.ParseAsync(request.Body, cancellationToken: cancellationToken);
                if (document.RootElement.ValueKind != JsonValueKind.Object)
                {
                    return Empty;
                }

                var values = new Dictionary<string, object?>(StringComparer.Ordinal);
                foreach (var property in document.RootElement.EnumerateObject())
                {
                    values[property.Name] = FromJson(property.Value);
                }

                return new RequestInput(values);
            }
            catch (JsonException)
            {
                return Empty;
            }
        }

        if (request.HasFormContentType)
        {
            var form = await request.ReadFormAsync(cancellationToken);
            return new RequestInput(form.ToDictionary(f => f.Key, f => (object?)f.Value.ToString(), StringComparer.Ordinal));
        }

        return Empty;
    }

    private static object? FromJson(JsonElement element) => element.ValueKind switch
    {
        JsonValueKind.String => element.GetString(),
        JsonValueKind.Number => element.TryGetInt64(out var integer) ? integer : element.GetDouble(),
        JsonValueKind.True => true,
        JsonValueKind.False => false,
        JsonValueKind.Array => new InputArray(element.GetArrayLength()),
        JsonValueKind.Object => new InputArray(element.EnumerateObject().Count()),
        _ => null,
    };
}
