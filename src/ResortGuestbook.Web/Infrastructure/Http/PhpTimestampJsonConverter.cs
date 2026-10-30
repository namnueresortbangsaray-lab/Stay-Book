using System.Text.Json;
using System.Text.Json.Serialization;
using ResortGuestbook.Data.Conversions;

namespace ResortGuestbook.Web.Infrastructure.Http;

/// <summary>Writes timestamps as UTC <c>2026-01-31T08:15:00+00:00</c>, the format the PHP API produced.</summary>
public sealed class PhpTimestampJsonConverter : JsonConverter<DateTimeOffset>
{
    public override DateTimeOffset Read(ref Utf8JsonReader reader, Type typeToConvert, JsonSerializerOptions options) =>
        UtcTimestampConverter.Parse(reader.GetString() ?? string.Empty);

    public override void Write(Utf8JsonWriter writer, DateTimeOffset value, JsonSerializerOptions options) =>
        writer.WriteStringValue(UtcTimestampConverter.Format(value));
}
