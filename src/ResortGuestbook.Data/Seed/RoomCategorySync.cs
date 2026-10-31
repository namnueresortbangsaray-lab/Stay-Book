using Microsoft.EntityFrameworkCore;
using ResortGuestbook.Data.Entities;

namespace ResortGuestbook.Data.Seed;

/// <summary>
/// Keeps the zone and room-type lists in step with the names rooms use: every name a room uses gets a list entry.
/// A new type takes its defaults from the first room (by sort order) that uses it. Safe to run repeatedly.
/// </summary>
public static class RoomCategorySync
{
    public static async Task<int> AddMissingAsync(AppDbContext db, CancellationToken cancellationToken = default)
    {
        var rooms = await db.Rooms.AsNoTracking().OrderBy(r => r.SortOrder).ThenBy(r => r.Name).ToListAsync(cancellationToken);
        var zones = await db.RoomZones.Select(z => z.Name).ToListAsync(cancellationToken);
        var types = await db.RoomTypes.Select(t => t.Name).ToListAsync(cancellationToken);
        var nextZone = zones.Count;
        var nextType = types.Count;
        var now = DateTimeOffset.UtcNow;
        var added = 0;

        foreach (var name in rooms.Select(r => r.Zone).Where(n => n.Length > 0).Distinct().Except(zones))
        {
            db.RoomZones.Add(new RoomZone { Id = Guid.NewGuid(), Name = name, SortOrder = ++nextZone, CreatedAt = now, UpdatedAt = now });
            added++;
        }

        foreach (var room in rooms.Where(r => r.Type.Length > 0).DistinctBy(r => r.Type).Where(r => !types.Contains(r.Type)))
        {
            db.RoomTypes.Add(FromRoom(room, ++nextType, now));
            added++;
        }

        if (added > 0)
        {
            await db.SaveChangesAsync(cancellationToken);
        }

        return added;
    }

    public static RoomType FromRoom(Room room, int sortOrder, DateTimeOffset now) => new()
    {
        Id = Guid.NewGuid(),
        Name = room.Type,
        PriceSatang = room.PriceSatang,
        BaseGuests = room.BaseGuests,
        MaxGuests = room.MaxGuests,
        ExtraGuestFeeSatang = room.ExtraGuestFeeSatang,
        IsPetFriendly = room.IsPetFriendly,
        SortOrder = sortOrder,
        CreatedAt = now,
        UpdatedAt = now,
    };
}
