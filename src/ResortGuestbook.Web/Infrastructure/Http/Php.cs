using System.Globalization;
using System.Text;
using System.Text.RegularExpressions;

namespace ResortGuestbook.Web.Infrastructure.Http;

/// <summary>
/// PHP 8 scalar coercion rules used by the original request validators, so loosely typed clients
/// (form posts, string numbers, <c>"on"</c> checkboxes) behave exactly as before.
/// Values are <c>null</c>, <see cref="bool"/>, <see cref="long"/>, <see cref="double"/>, <see cref="string"/>
/// or <see cref="InputArray"/>.
/// </summary>
public static partial class Php
{
    private static readonly char[] TrimChars = [' ', '\t', '\n', '\r', '\0', '\v'];

    /// <summary><c>(string) $value</c>.</summary>
    public static string ToStr(object? value) => value switch
    {
        null => string.Empty,
        bool b => b ? "1" : string.Empty,
        long l => l.ToString(CultureInfo.InvariantCulture),
        double d => FloatToString(d),
        string s => s,
        InputArray => "Array",
        _ => Convert.ToString(value, CultureInfo.InvariantCulture) ?? string.Empty,
    };

    /// <summary><c>trim((string) $value)</c>.</summary>
    public static string TrimStr(object? value) => Trim(ToStr(value));

    /// <summary>PHP <c>trim()</c> with its default character list.</summary>
    public static string Trim(string value) => value.Trim(TrimChars);

    /// <summary><c>(int) $value</c>.</summary>
    public static long ToInt(object? value) => value switch
    {
        null => 0,
        bool b => b ? 1 : 0,
        long l => l,
        double d => Truncate(d),
        string s => LeadingNumber(s) is { } parsed ? parsed.Integer ?? Truncate(parsed.Float) : 0,
        InputArray a => a.Count > 0 ? 1 : 0,
        _ => 0,
    };

    /// <summary><c>(float) $value</c>.</summary>
    public static double ToFloat(object? value) => value switch
    {
        null => 0,
        bool b => b ? 1 : 0,
        long l => l,
        double d => d,
        string s => LeadingNumber(s)?.Float ?? 0,
        InputArray a => a.Count > 0 ? 1 : 0,
        _ => 0,
    };

    /// <summary><c>is_numeric($value)</c>.</summary>
    public static bool IsNumeric(object? value) => value switch
    {
        long or double => true,
        string s => NumericString().IsMatch(s),
        _ => false,
    };

    /// <summary><c>filter_var($value, FILTER_VALIDATE_BOOLEAN)</c> (false on failure).</summary>
    public static bool ToBool(object? value) => value switch
    {
        bool b => b,
        null or InputArray => false,
        _ => Trim(ToStr(value)).ToLowerInvariant() is "1" or "true" or "on" or "yes",
    };

    /// <summary><c>mb_strlen($value)</c>: number of Unicode code points.</summary>
    public static int MbStrlen(string value) => value.EnumerateRunes().Count();

    /// <summary><c>preg_replace('/\D+/', '', $value)</c>: ASCII digits only.</summary>
    public static string Digits(string value)
    {
        var builder = new StringBuilder(value.Length);
        foreach (var c in value)
        {
            if (char.IsAsciiDigit(c))
            {
                builder.Append(c);
            }
        }

        return builder.ToString();
    }

    /// <summary><c>Str::clean</c>: trimmed string, or null when empty.</summary>
    public static string? Clean(object? value)
    {
        var trimmed = TrimStr(value);
        return trimmed.Length == 0 ? null : trimmed;
    }

    /// <summary>Strict <c>Y-m-d</c> parse that rejects anything that does not round-trip (e.g. 2030-02-29).</summary>
    public static bool TryParseDate(string value, out DateOnly date) =>
        DateOnly.TryParseExact(value, "yyyy-MM-dd", CultureInfo.InvariantCulture, DateTimeStyles.None, out date);

    private static long Truncate(double value) =>
        double.IsNaN(value) || double.IsInfinity(value) ? 0 : (long)Math.Clamp(Math.Truncate(value), long.MinValue, long.MaxValue);

    private static string FloatToString(double value)
    {
        if (double.IsNaN(value))
        {
            return "NAN";
        }

        if (double.IsInfinity(value))
        {
            return value > 0 ? "INF" : "-INF";
        }

        return value == Math.Truncate(value) && Math.Abs(value) < 1e15
            ? ((long)value).ToString(CultureInfo.InvariantCulture)
            : value.ToString("R", CultureInfo.InvariantCulture);
    }

    private static (long? Integer, double Float)? LeadingNumber(string value)
    {
        var match = LeadingNumeric().Match(value);
        if (!match.Success || match.Groups["number"].Length == 0)
        {
            return null;
        }

        var text = match.Groups["number"].Value;
        var isInteger = !text.Contains('.', StringComparison.Ordinal) && !text.Contains('e', StringComparison.OrdinalIgnoreCase);
        var number = double.Parse(text, NumberStyles.Float, CultureInfo.InvariantCulture);
        return isInteger && long.TryParse(text, NumberStyles.AllowLeadingSign, CultureInfo.InvariantCulture, out var integer)
            ? (integer, number)
            : (null, number);
    }

    [GeneratedRegex(@"^[ \t\n\r\v\f]*[+-]?(\d+(\.\d*)?|\.\d+)([eE][+-]?\d+)?[ \t\n\r\v\f]*$")]
    private static partial Regex NumericString();

    [GeneratedRegex(@"^[ \t\n\r\v\f]*(?<number>[+-]?(\d+(\.\d*)?|\.\d+)([eE][+-]?\d+)?)")]
    private static partial Regex LeadingNumeric();
}
