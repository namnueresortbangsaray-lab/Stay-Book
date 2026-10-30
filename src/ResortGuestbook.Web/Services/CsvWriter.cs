using System.Globalization;
using System.Text;
using ResortGuestbook.Web.Models.Dtos;

namespace ResortGuestbook.Web.Services;

/// <summary>The bookings CSV exactly as v1 produced it: UTF-8 BOM, <c>fputcsv</c> quoting, LF line endings.</summary>
public static class CsvWriter
{
    private static readonly string[] Header = ["Booking ID", "ชื่อลูกค้า", "โทรศัพท์", "ห้อง", "เช็กอิน", "เช็กเอาต์", "สถานะ", "ยอดสุทธิ (บาท)"];

    public static byte[] Bookings(IEnumerable<StayDto> stays)
    {
        var builder = new StringBuilder();
        WriteLine(builder, Header);
        foreach (var s in stays)
        {
            WriteLine(builder, new[]
            {
                s.Id.ToString(),
                s.GuestName,
                s.Phone ?? string.Empty,
                s.RoomName,
                s.CheckInDate.ToString("yyyy-MM-dd", CultureInfo.InvariantCulture),
                s.CheckOutDate.ToString("yyyy-MM-dd", CultureInfo.InvariantCulture),
                s.Status.ToString(CultureInfo.InvariantCulture),
                (s.TotalAmountSatang / 100m).ToString("0.00", CultureInfo.InvariantCulture),
            }.Select(Safe));
        }

        return [.. Encoding.UTF8.GetPreamble(), .. Encoding.UTF8.GetBytes(builder.ToString())];
    }

    /// <summary>Neutralises spreadsheet formulas: values starting with <c>= + - @</c> get a leading apostrophe.</summary>
    public static string Safe(string value) =>
        value.Length > 0 && value[0] is '=' or '+' or '-' or '@' ? "'" + value : value;

    private static void WriteLine(StringBuilder builder, IEnumerable<string> fields)
    {
        builder.AppendJoin(',', fields.Select(Quote));
        builder.Append('\n');
    }

    /// <summary>v1 <c>fputcsv</c>: enclose when the field contains a delimiter, quote, backslash, whitespace or newline.</summary>
    private static string Quote(string field) =>
        field.AsSpan().IndexOfAny(",\"\\ \t\r\n") >= 0 ? "\"" + field.Replace("\"", "\"\"", StringComparison.Ordinal) + "\"" : field;
}
