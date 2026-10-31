using Microsoft.EntityFrameworkCore;
using ResortGuestbook.Data;
using ResortGuestbook.Data.Entities;
using ResortGuestbook.Web.Infrastructure.Http;
using ResortGuestbook.Web.Models.Dtos;
using ResortGuestbook.Web.Services.Errors;
using ResortGuestbook.Web.Services.Validation;

namespace ResortGuestbook.Web.Services;

/// <summary>Booking lifecycle: create/edit, check-in, checkout with inspection, delete.</summary>
public sealed class StayService(AppDbContext db, ResortQueries queries, AuditService audit, AppClock clock, IdPhotoService idPhotos)
{
    private const string BookingNotFound = "ไม่พบ Booking";

    public async Task<StayWithPriceDto> SaveAsync(RequestInput input, string? id, Actor actor, CancellationToken cancellationToken)
    {
        var data = StayRequest.Validate(input);
        Stay? stay = null;
        StayDto? before = null;
        if (id is not null)
        {
            stay = await FindAsync(id, cancellationToken);
            before = stay is null ? null : await queries.StayAsync(stay.Id, cancellationToken);
            if (stay is null || before is null)
            {
                throw new ValidationException("id", BookingNotFound);
            }
        }

        var status = data.Status;
        if (stay is null && status == StayStatus.CheckedOut)
        {
            throw new ValidationException("status", "ต้องเช็กอินและตรวจห้องก่อนเช็กเอาต์");
        }

        if (stay is not null)
        {
            if (stay.Status == StayStatus.CheckedOut)
            {
                throw new ValidationException("status", "Booking ที่เช็กเอาต์แล้วไม่สามารถแก้ไขได้");
            }

            if (stay.Status == StayStatus.CheckedIn && !string.Equals(data.RoomId, stay.RoomId.ToString(), StringComparison.Ordinal))
            {
                throw new ValidationException("room_id", "ไม่สามารถย้ายห้องระหว่างเข้าพักได้ กรุณาเช็กเอาต์ก่อน");
            }

            status = stay.Status;
        }

        var room = Guid.TryParse(data.RoomId, out var roomId)
            ? await db.Rooms.FirstOrDefaultAsync(r => r.Id == roomId, cancellationToken)
            : null;
        if (room is null)
        {
            throw new ValidationException("room_id", "ไม่พบห้องพัก");
        }

        if (data.Guests > room.MaxGuests)
        {
            throw new ValidationException("guests", "จำนวนผู้เข้าพักเกินความจุห้อง");
        }

        if (data.PetCount > 0 && !room.IsPetFriendly)
        {
            throw new ValidationException("room_id", "ห้องนี้ไม่รองรับสัตว์เลี้ยง");
        }

        if (await HasOverlapAsync(room.Id, data.CheckInDate, data.CheckOutDate, stay?.Id, cancellationToken))
        {
            throw new ValidationException("room_id", "ห้องนี้มี Booking ทับซ้อนในช่วงวันที่เลือก");
        }

        var guest = await FindOrCreateGuestAsync(data, cancellationToken);
        var price = PriceCalculator.Calculate(room, data.Guests, data.CheckInDate, data.CheckOutDate, data.ExtraBed, data.PetCount, data.DiscountAmountSatang, data.DepositAmountSatang, data.DepositPaid);

        if (stay is null)
        {
            stay = new Stay { Id = Guid.NewGuid() };
            db.Stays.Add(stay);
        }

        stay.GuestId = guest.Id;
        stay.RoomId = room.Id;
        stay.GuestName = data.GuestName;
        stay.Phone = data.Phone;
        stay.CheckInDate = data.CheckInDate;
        stay.CheckOutDate = data.CheckOutDate;
        stay.Guests = data.Guests;
        stay.ExtraBed = data.ExtraBed;
        stay.TotalAmountSatang = price.TotalAmountSatang;
        stay.Status = status;
        stay.Note = data.Note;
        stay.DepositAmountSatang = data.DepositAmountSatang;
        stay.DepositPaid = data.DepositPaid;
        stay.IdVerified = data.IdVerified;
        stay.PetType = data.PetType;
        stay.PetCount = data.PetCount;
        stay.PetFeeSatang = price.PetTotalSatang;
        stay.DiscountAmountSatang = data.DiscountAmountSatang;
        if (status == StayStatus.CheckedIn)
        {
            room.Status = 1;
        }

        await db.SaveChangesAsync(cancellationToken);

        var saved = await queries.StayAsync(stay.Id, cancellationToken) ?? throw new InvalidOperationException("Stay not found after save.");
        var after = WithPrice(saved, price);
        await audit.RecordAsync(id is null ? "create" : "update", "stay", stay.Id, before, after, actor, cancellationToken);
        return after;
    }

    public async Task<StayDto> CheckInAsync(string id, Actor actor, CancellationToken cancellationToken)
    {
        var (stay, before) = await LoadAsync(id, cancellationToken);
        if (stay.Status != StayStatus.Booked)
        {
            throw new ValidationException("status", "Booking นี้ไม่อยู่ในสถานะรอเช็กอิน");
        }

        if (!stay.IdVerified)
        {
            throw new ValidationException("id_verified", "ต้องตรวจสอบบัตรประชาชนก่อนเช็กอิน");
        }

        if (await HasOverlapAsync(stay.RoomId, stay.CheckInDate, stay.CheckOutDate, stay.Id, cancellationToken))
        {
            throw new ValidationException("room_id", "ห้องมีรายการเข้าพักอื่นทับซ้อน");
        }

        var after = await SetStatusAsync(stay, StayStatus.CheckedIn, null, cancellationToken);
        await audit.RecordAsync("check_in", "stay", stay.Id, before, after, actor, cancellationToken);
        return after;
    }

    public async Task<StayDto> CheckoutAsync(string id, RequestInput input, Actor actor, CancellationToken cancellationToken)
    {
        var (stay, before) = await LoadAsync(id, cancellationToken);
        if (stay.Status != StayStatus.CheckedIn)
        {
            throw new ValidationException("status", "Booking นี้ยังไม่ได้เช็กอิน");
        }

        var inspection = new CheckoutInspection
        {
            Id = Guid.NewGuid(),
            StayId = stay.Id,
            KeyReturned = Coerce.ToBool(input.Get("key_returned", false)),
            RoomClean = Coerce.ToBool(input.Get("room_clean", false)),
            EquipmentComplete = Coerce.ToBool(input.Get("equipment_complete", false)),
            NoDamage = Coerce.ToBool(input.Get("no_damage", false)),
            MinibarChecked = Coerce.ToBool(input.Get("minibar_checked", false)),
            InspectionNote = Coerce.Clean(input["inspection_note"]),
            InspectedBy = actor.Id,
            InspectedAt = TruncatedNow(),
        };
        if (!inspection.NoDamage && inspection.InspectionNote is null)
        {
            throw new ValidationException("inspection_note", "กรุณาระบุรายละเอียดความเสียหาย");
        }

        var after = await SetStatusAsync(stay, StayStatus.CheckedOut, inspection, cancellationToken);
        await audit.RecordAsync("check_out", "stay", stay.Id, before, after, actor, cancellationToken);
        return after;
    }

    /// <summary>Hard delete with feedback, inspection, attachment and ID photo rows (and the ID photo file); frees the room if the guest was checked in.</summary>
    public async Task DeleteAsync(string id, Actor actor, CancellationToken cancellationToken)
    {
        var (stay, before) = await LoadAsync(id, cancellationToken);
        await using (var transaction = await db.Database.BeginTransactionAsync(cancellationToken))
        {
            await db.Feedbacks.Where(f => f.StayId == stay.Id).ExecuteDeleteAsync(cancellationToken);
            await db.CheckoutInspections.Where(i => i.StayId == stay.Id).ExecuteDeleteAsync(cancellationToken);
            await db.Attachments.Where(a => a.StayId == stay.Id).ExecuteDeleteAsync(cancellationToken);
            await idPhotos.DeleteFilesForStaysAsync(new[] { stay.Id }.AsQueryable(), cancellationToken);
            await db.StayIdPhotos.Where(p => p.StayId == stay.Id).ExecuteDeleteAsync(cancellationToken);
            await db.Stays.IgnoreQueryFilters().Where(s => s.Id == stay.Id).ExecuteDeleteAsync(cancellationToken);
            if (stay.Status == StayStatus.CheckedIn)
            {
                var room = await db.Rooms.IgnoreQueryFilters().FirstAsync(r => r.Id == stay.RoomId, cancellationToken);
                room.Status = 0;
                await db.SaveChangesAsync(cancellationToken);
            }

            await transaction.CommitAsync(cancellationToken);
        }

        db.Entry(stay).State = EntityState.Detached;
        await audit.RecordAsync("delete", "stay", stay.Id, before, null, actor, cancellationToken);
    }

    /// <summary>Half-open range overlap with booked/checked-in stays of the room: same-day turnover is allowed.</summary>
    public Task<bool> HasOverlapAsync(Guid roomId, DateOnly from, DateOnly to, Guid? except, CancellationToken cancellationToken) =>
        db.Stays.AnyAsync(
            s => s.RoomId == roomId
                && (s.Status == StayStatus.Booked || s.Status == StayStatus.CheckedIn)
                && s.CheckInDate < to
                && s.CheckOutDate > from
                && (except == null || s.Id != except),
            cancellationToken);

    private async Task<StayDto> SetStatusAsync(Stay stay, int status, CheckoutInspection? inspection, CancellationToken cancellationToken)
    {
        var room = await db.Rooms.IgnoreQueryFilters().FirstAsync(r => r.Id == stay.RoomId, cancellationToken);
        stay.Status = status;
        room.Status = status == StayStatus.CheckedIn ? 1 : 0;
        if (inspection is not null)
        {
            db.CheckoutInspections.RemoveRange(await db.CheckoutInspections.Where(i => i.StayId == stay.Id).ToListAsync(cancellationToken));
            db.CheckoutInspections.Add(inspection);
        }

        await db.SaveChangesAsync(cancellationToken);
        return await queries.StayAsync(stay.Id, cancellationToken) ?? throw new InvalidOperationException("Stay not found after update.");
    }

    private async Task<Guest> FindOrCreateGuestAsync(StayInput data, CancellationToken cancellationToken)
    {
        var normalized = Coerce.Digits(data.Phone);
        var guest = await db.Guests.FirstOrDefaultAsync(g => g.NormalizedPhone == normalized, cancellationToken);
        if (guest is not null)
        {
            return guest;
        }

        guest = new Guest
        {
            Id = Guid.NewGuid(),
            Name = data.GuestName,
            Phone = data.Phone,
            NormalizedPhone = normalized,
            CustomerType = Guest.DefaultCustomerType,
            IsRegular = false,
        };
        db.Guests.Add(guest);
        await db.SaveChangesAsync(cancellationToken);
        return guest;
    }

    private async Task<(Stay Stay, StayDto Before)> LoadAsync(string id, CancellationToken cancellationToken)
    {
        var stay = await FindAsync(id, cancellationToken);
        var before = stay is null ? null : await queries.StayAsync(stay.Id, cancellationToken);
        return stay is null || before is null ? throw new NotFoundException(BookingNotFound) : (stay, before);
    }

    private Task<Stay?> FindAsync(string id, CancellationToken cancellationToken) =>
        Guid.TryParse(id, out var key) ? db.Stays.FirstOrDefaultAsync(s => s.Id == key, cancellationToken) : Task.FromResult<Stay?>(null);

    private DateTimeOffset TruncatedNow()
    {
        var now = clock.UtcNow;
        return now.AddTicks(-(now.Ticks % TimeSpan.TicksPerSecond));
    }

    private static StayWithPriceDto WithPrice(StayDto s, PriceBreakdown price) => new()
    {
        Id = s.Id,
        GuestId = s.GuestId,
        RoomId = s.RoomId,
        GuestName = s.GuestName,
        Phone = s.Phone,
        CheckInDate = s.CheckInDate,
        CheckOutDate = s.CheckOutDate,
        Guests = s.Guests,
        ExtraBed = s.ExtraBed,
        TotalAmountSatang = s.TotalAmountSatang,
        Status = s.Status,
        Note = s.Note,
        DepositAmountSatang = s.DepositAmountSatang,
        DepositPaid = s.DepositPaid,
        IdVerified = s.IdVerified,
        PetType = s.PetType,
        PetCount = s.PetCount,
        PetFeeSatang = s.PetFeeSatang,
        DiscountAmountSatang = s.DiscountAmountSatang,
        CreatedAt = s.CreatedAt,
        UpdatedAt = s.UpdatedAt,
        DeletedAt = s.DeletedAt,
        RoomName = s.RoomName,
        Zone = s.Zone,
        RoomType = s.RoomType,
        RoomRateSatang = s.RoomRateSatang,
        BaseGuests = s.BaseGuests,
        MaxGuests = s.MaxGuests,
        ExtraGuestFeeSatang = s.ExtraGuestFeeSatang,
        IsPetFriendly = s.IsPetFriendly,
        CustomerType = s.CustomerType,
        IsRegular = s.IsRegular,
        FeedbackRating = s.FeedbackRating,
        PriceBreakdown = price,
    };
}
