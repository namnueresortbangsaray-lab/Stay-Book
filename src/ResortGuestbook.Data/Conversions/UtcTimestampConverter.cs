using System.Globalization;
using Microsoft.EntityFrameworkCore.Storage.ValueConversion;

namespace ResortGuestbook.Data.Conversions;

/// <summary>
/// Stores timestamps on SQLite as UTC TEXT in the PHP <c>gmdate('c')</c> format (<c>2026-01-31T08:15:00+00:00</c>),
/// which sorts correctly as text and keeps data written by the PHP version readable.
/// </summary>
public sealed class UtcTimestampConverter() : ValueConverter<DateTimeOffset, string>(
    value => Format(value),
    value => Parse(value))
{
    public const string Pattern = "yyyy-MM-dd'T'HH:mm:ss'+00:00'";

    public static string Format(DateTimeOffset value) =>
        value.ToUniversalTime().ToString(Pattern, CultureInfo.InvariantCulture);

    public static DateTimeOffset Parse(string value) =>
        DateTimeOffset.Parse(value, CultureInfo.InvariantCulture, DateTimeStyles.AssumeUniversal).ToUniversalTime();
}
