using Microsoft.EntityFrameworkCore.Storage.ValueConversion;

namespace ResortGuestbook.Data.Conversions;

/// <summary>
/// Stores <see cref="Guid"/> as lowercase TEXT on SQLite, matching the UUIDs written by v1
/// (EF Core's default SQLite mapping uses uppercase).
/// </summary>
public sealed class LowercaseGuidConverter() : ValueConverter<Guid, string>(
    value => value.ToString("D"),
    value => Guid.Parse(value));
