using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Infrastructure;
using ResortGuestbook.Data.Entities;

namespace ResortGuestbook.Data.Providers;

/// <summary>
/// Case-insensitive substring search over guest name, phone, room name, zone and note, reproducing the PHP
/// <c>Dialect::search</c>: <c>LOWER(col) LIKE LOWER(:p)</c> on SQLite and <c>col ILIKE :p</c> on PostgreSQL.
/// The pattern is used as given (<c>%</c>/<c>_</c> are wildcards, as in PHP).
/// </summary>
public static class StaySearchExtensions
{
    public static IQueryable<Stay> WhereTextMatches(this IQueryable<Stay> stays, DatabaseFacade database, string pattern) =>
        database.IsNpgsql()
            ? stays.Where(s =>
                EF.Functions.ILike(s.GuestName, pattern)
                || EF.Functions.ILike(s.Phone!, pattern)
                || EF.Functions.ILike(s.Room!.Name, pattern)
                || EF.Functions.ILike(s.Room!.Zone, pattern)
                || EF.Functions.ILike(s.Note!, pattern))
            : stays.Where(s =>
                EF.Functions.Like(s.GuestName.ToLower(), pattern.ToLower())
                || EF.Functions.Like(s.Phone!.ToLower(), pattern.ToLower())
                || EF.Functions.Like(s.Room!.Name.ToLower(), pattern.ToLower())
                || EF.Functions.Like(s.Room!.Zone.ToLower(), pattern.ToLower())
                || EF.Functions.Like(s.Note!.ToLower(), pattern.ToLower()));
}
