using Microsoft.EntityFrameworkCore;
using ResortGuestbook.Data;
using ResortGuestbook.Data.Entities;
using ResortGuestbook.Data.Seed;
using ResortGuestbook.Web.Infrastructure.Http;
using ResortGuestbook.Web.Models.Dtos;
using ResortGuestbook.Web.Services.Errors;
using ResortGuestbook.Web.Services.Validation;

namespace ResortGuestbook.Web.Services;

/// <summary>
/// Zone and room-type lists. Rooms keep storing the names, so renaming an entry renames it on its rooms (audited per
/// room) and an entry can only be deleted while no room uses it.
/// </summary>
public sealed class RoomCategoryService(AppDbContext db, AuditService audit)
{
    private const string ZoneNotFound = "ไม่พบโซน";
    private const string TypeNotFound = "ไม่พบประเภทห้อง";

    public async Task<RoomCategoriesDto> ListAsync(CancellationToken cancellationToken)
    {
        var rooms = await db.Rooms.AsNoTracking().Select(r => new { r.Zone, r.Type }).ToListAsync(cancellationToken);
        var zones = await db.RoomZones.AsNoTracking().OrderBy(z => z.SortOrder).ThenBy(z => z.Name).ToListAsync(cancellationToken);
        var types = await db.RoomTypes.AsNoTracking().OrderBy(t => t.SortOrder).ThenBy(t => t.Name).ToListAsync(cancellationToken);
        return new RoomCategoriesDto(
            [.. zones.Select(z => ToDto(z, rooms.Count(r => r.Zone == z.Name)))],
            [.. types.Select(t => ToDto(t, rooms.Count(r => r.Type == t.Name)))]);
    }

    public async Task<RoomZoneDto> SaveZoneAsync(RequestInput input, string? id, Actor actor, CancellationToken cancellationToken)
    {
        var data = RoomZoneRequest.Validate(input);
        await using var transaction = await db.Database.BeginTransactionAsync(cancellationToken);
        RoomZone zone;
        RoomZoneDto? before = null;
        if (id is null)
        {
            zone = new RoomZone { Id = Guid.NewGuid() };
            db.RoomZones.Add(zone);
        }
        else
        {
            zone = await FindAsync(db.RoomZones, id, cancellationToken) ?? throw new NotFoundException(ZoneNotFound);
            before = ToDto(zone, await db.Rooms.CountAsync(r => r.Zone == zone.Name, cancellationToken));
        }

        var oldName = zone.Name;
        zone.Name = data.Name;
        zone.SortOrder = data.SortOrder;
        await db.SaveChangesAsync(cancellationToken);
        if (before is not null && oldName != data.Name)
        {
            await RenameOnRoomsAsync(db.Rooms.Where(r => r.Zone == oldName), r => r.Zone = data.Name, actor, cancellationToken);
        }

        var after = ToDto(zone, await db.Rooms.CountAsync(r => r.Zone == zone.Name, cancellationToken));
        await audit.RecordAsync(id is null ? "create" : "update", "room_zone", zone.Id, before, after, actor, cancellationToken);
        await transaction.CommitAsync(cancellationToken);
        return after;
    }

    public async Task<RoomTypeDto> SaveTypeAsync(RequestInput input, string? id, Actor actor, CancellationToken cancellationToken)
    {
        var data = RoomTypeRequest.Validate(input);
        await using var transaction = await db.Database.BeginTransactionAsync(cancellationToken);
        RoomType type;
        RoomTypeDto? before = null;
        if (id is null)
        {
            type = new RoomType { Id = Guid.NewGuid() };
            db.RoomTypes.Add(type);
        }
        else
        {
            type = await FindAsync(db.RoomTypes, id, cancellationToken) ?? throw new NotFoundException(TypeNotFound);
            before = ToDto(type, await db.Rooms.CountAsync(r => r.Type == type.Name, cancellationToken));
        }

        var oldName = type.Name;
        type.Name = data.Name;
        type.PriceSatang = data.PriceSatang;
        type.BaseGuests = data.BaseGuests;
        type.MaxGuests = data.MaxGuests;
        type.ExtraGuestFeeSatang = data.ExtraGuestFeeSatang;
        type.IsPetFriendly = data.IsPetFriendly;
        type.SortOrder = data.SortOrder;
        await db.SaveChangesAsync(cancellationToken);
        if (before is not null && oldName != data.Name)
        {
            await RenameOnRoomsAsync(db.Rooms.Where(r => r.Type == oldName), r => r.Type = data.Name, actor, cancellationToken);
        }

        var after = ToDto(type, await db.Rooms.CountAsync(r => r.Type == type.Name, cancellationToken));
        await audit.RecordAsync(id is null ? "create" : "update", "room_type", type.Id, before, after, actor, cancellationToken);
        await transaction.CommitAsync(cancellationToken);
        return after;
    }

    public async Task DeleteZoneAsync(string id, Actor actor, CancellationToken cancellationToken)
    {
        var zone = await FindAsync(db.RoomZones, id, cancellationToken) ?? throw new NotFoundException(ZoneNotFound);
        var used = await db.Rooms.CountAsync(r => r.Zone == zone.Name, cancellationToken);
        if (used > 0)
        {
            throw new ValidationException("name", $"มีห้องพักใช้โซนนี้อยู่ {used} ห้อง");
        }

        var before = ToDto(zone, 0);
        db.RoomZones.Remove(zone);
        await db.SaveChangesAsync(cancellationToken);
        await audit.RecordAsync("delete", "room_zone", zone.Id, before, null, actor, cancellationToken);
    }

    public async Task DeleteTypeAsync(string id, Actor actor, CancellationToken cancellationToken)
    {
        var type = await FindAsync(db.RoomTypes, id, cancellationToken) ?? throw new NotFoundException(TypeNotFound);
        var used = await db.Rooms.CountAsync(r => r.Type == type.Name, cancellationToken);
        if (used > 0)
        {
            throw new ValidationException("name", $"มีห้องพักใช้ประเภทนี้อยู่ {used} ห้อง");
        }

        var before = ToDto(type, 0);
        db.RoomTypes.Remove(type);
        await db.SaveChangesAsync(cancellationToken);
        await audit.RecordAsync("delete", "room_type", type.Id, before, null, actor, cancellationToken);
    }

    /// <summary>Adds the room's zone and type to the lists when they are not there yet (rooms saved through the API).</summary>
    public async Task AddMissingForRoomAsync(Room room, Actor actor, CancellationToken cancellationToken)
    {
        var now = DateTimeOffset.UtcNow;
        if (!await db.RoomZones.AnyAsync(z => z.Name == room.Zone, cancellationToken))
        {
            var sortOrder = await db.RoomZones.CountAsync(cancellationToken) + 1;
            var zone = new RoomZone { Id = Guid.NewGuid(), Name = room.Zone, SortOrder = sortOrder, CreatedAt = now, UpdatedAt = now };
            db.RoomZones.Add(zone);
            await db.SaveChangesAsync(cancellationToken);
            await audit.RecordAsync("create", "room_zone", zone.Id, null, ToDto(zone, 1), actor, cancellationToken);
        }

        if (!await db.RoomTypes.AnyAsync(t => t.Name == room.Type, cancellationToken))
        {
            var type = RoomCategorySync.FromRoom(room, await db.RoomTypes.CountAsync(cancellationToken) + 1, now);
            db.RoomTypes.Add(type);
            await db.SaveChangesAsync(cancellationToken);
            await audit.RecordAsync("create", "room_type", type.Id, null, ToDto(type, 1), actor, cancellationToken);
        }
    }

    private async Task RenameOnRoomsAsync(IQueryable<Room> rooms, Action<Room> rename, Actor actor, CancellationToken cancellationToken)
    {
        foreach (var room in await rooms.ToListAsync(cancellationToken))
        {
            var before = ResortQueries.ToDto(room);
            rename(room);
            await db.SaveChangesAsync(cancellationToken);
            await audit.RecordAsync("update", "room", room.Id, before, ResortQueries.ToDto(room), actor, cancellationToken);
        }
    }

    private static Task<T?> FindAsync<T>(DbSet<T> set, string id, CancellationToken cancellationToken)
        where T : class =>
        Guid.TryParse(id, out var key) ? set.FindAsync([key], cancellationToken).AsTask() : Task.FromResult<T?>(null);

    private static RoomZoneDto ToDto(RoomZone z, int roomCount) => new(z.Id, z.Name, z.SortOrder, roomCount, z.CreatedAt, z.UpdatedAt);

    private static RoomTypeDto ToDto(RoomType t, int roomCount) => new(
        t.Id, t.Name, t.PriceSatang, t.BaseGuests, t.MaxGuests, t.ExtraGuestFeeSatang, t.IsPetFriendly, t.SortOrder, roomCount, t.CreatedAt, t.UpdatedAt);
}
