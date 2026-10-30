using Microsoft.EntityFrameworkCore;
using ResortGuestbook.Data;
using ResortGuestbook.Data.Entities;
using ResortGuestbook.Web.Infrastructure.Http;
using ResortGuestbook.Web.Models.Dtos;
using ResortGuestbook.Web.Services.Errors;
using ResortGuestbook.Web.Services.Validation;

namespace ResortGuestbook.Web.Services;

public sealed class RoomService(AppDbContext db, AuditService audit)
{
    private const string NotFound = "ไม่พบห้องพัก";

    public async Task<RoomDto> SaveAsync(RequestInput input, string? id, Actor actor, CancellationToken cancellationToken)
    {
        var data = RoomRequest.Validate(input);
        Room room;
        RoomDto? before = null;
        if (id is null)
        {
            room = new Room { Id = Guid.NewGuid(), Status = 0 };
            db.Rooms.Add(room);
        }
        else
        {
            room = await FindAsync(id, cancellationToken) ?? throw new NotFoundException(NotFound);
            before = ResortQueries.ToDto(room);
        }

        room.Name = data.Name;
        room.Zone = data.Zone;
        room.Type = data.Type;
        room.PriceSatang = data.PriceSatang;
        room.BaseGuests = data.BaseGuests;
        room.MaxGuests = data.MaxGuests;
        room.ExtraGuestFeeSatang = data.ExtraGuestFeeSatang;
        room.SortOrder = data.SortOrder;
        room.IsPetFriendly = data.IsPetFriendly;
        await db.SaveChangesAsync(cancellationToken);

        var after = ResortQueries.ToDto(room);
        await audit.RecordAsync(id is null ? "create" : "update", "room", room.Id, before, after, actor, cancellationToken);
        return after;
    }

    /// <summary>Hard delete, removing the room's stays and their feedback, inspections and attachment rows first.</summary>
    public async Task DeleteAsync(string id, Actor actor, CancellationToken cancellationToken)
    {
        var room = await FindAsync(id, cancellationToken) ?? throw new NotFoundException(NotFound);
        var before = ResortQueries.ToDto(room);
        var stayIds = db.Stays.IgnoreQueryFilters().Where(s => s.RoomId == room.Id).Select(s => s.Id);

        await using (var transaction = await db.Database.BeginTransactionAsync(cancellationToken))
        {
            await db.Feedbacks.Where(f => stayIds.Contains(f.StayId)).ExecuteDeleteAsync(cancellationToken);
            await db.CheckoutInspections.Where(i => stayIds.Contains(i.StayId)).ExecuteDeleteAsync(cancellationToken);
            await db.Attachments.Where(a => stayIds.Contains(a.StayId)).ExecuteDeleteAsync(cancellationToken);
            await db.Stays.IgnoreQueryFilters().Where(s => s.RoomId == room.Id).ExecuteDeleteAsync(cancellationToken);
            await db.Rooms.IgnoreQueryFilters().Where(r => r.Id == room.Id).ExecuteDeleteAsync(cancellationToken);
            await transaction.CommitAsync(cancellationToken);
        }

        db.Entry(room).State = EntityState.Detached;
        await audit.RecordAsync("delete", "room", room.Id, before, null, actor, cancellationToken);
    }

    private Task<Room?> FindAsync(string id, CancellationToken cancellationToken) =>
        Guid.TryParse(id, out var key) ? db.Rooms.FirstOrDefaultAsync(r => r.Id == key, cancellationToken) : Task.FromResult<Room?>(null);
}
