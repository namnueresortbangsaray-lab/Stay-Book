using Microsoft.EntityFrameworkCore;
using ResortGuestbook.Data;
using ResortGuestbook.Data.Entities;
using ResortGuestbook.Data.Providers;
using ResortGuestbook.Web.Models.Dtos;

namespace ResortGuestbook.Web.Services;

/// <summary>Read models with the same shape and ordering as the v1 repository queries.</summary>
public sealed class ResortQueries(AppDbContext db)
{
    public async Task<List<RoomDto>> RoomsAsync(CancellationToken cancellationToken = default)
    {
        var rooms = await db.Rooms.AsNoTracking()
            .OrderBy(r => r.Zone).ThenBy(r => r.SortOrder).ThenBy(r => r.Name)
            .ToListAsync(cancellationToken);
        return rooms.ConvertAll(ToDto);
    }

    public async Task<RoomDto?> RoomAsync(Guid id, CancellationToken cancellationToken = default) =>
        await db.Rooms.AsNoTracking().Where(r => r.Id == id).Select(r => ToDto(r)).FirstOrDefaultAsync(cancellationToken);

    public Task<List<StayDto>> StaysAsync(CancellationToken cancellationToken = default) =>
        ProjectStays(db.Stays).ToListAsync(cancellationToken);

    public Task<StayDto?> StayAsync(Guid id, CancellationToken cancellationToken = default) =>
        ProjectStays(db.Stays.Where(s => s.Id == id)).FirstOrDefaultAsync(cancellationToken);

    /// <summary><c>GET /api/v1/stays</c>: text search over name/phone/room/zone/note and optional status.</summary>
    public Task<List<StayDto>> SearchStaysAsync(string search, int? status, CancellationToken cancellationToken = default)
    {
        var query = db.Stays.AsQueryable();
        if (search.Length > 0)
        {
            query = query.WhereTextMatches(db.Database, $"%{search.Trim()}%");
        }

        if (status is { } value)
        {
            query = query.Where(s => s.Status == value);
        }

        return ProjectStays(query).ToListAsync(cancellationToken);
    }

    public async Task<List<GuestSummaryDto>> GuestSummariesAsync(CancellationToken cancellationToken = default)
    {
        var guests = await db.Guests.AsNoTracking().OrderByDescending(g => g.UpdatedAt).ToListAsync(cancellationToken);
        var stays = await db.Stays.AsNoTracking()
            .Where(s => s.GuestId != null)
            .Select(s => new GuestStayRow(s.GuestId!.Value, s.Id, s.CheckInDate, s.CheckOutDate, s.Status, s.TotalAmountSatang, s.DiscountAmountSatang, s.Room!.Name, s.CreatedAt))
            .ToListAsync(cancellationToken);
        var byGuest = stays
            .OrderBy(s => s.CreatedAt).ThenBy(s => s.Id)
            .GroupBy(s => s.GuestId)
            .ToDictionary(g => g.Key, g => g.ToList());
        return guests.ConvertAll(g => Summarize(g, byGuest.GetValueOrDefault(g.Id) ?? []));
    }

    public async Task<GuestDetailDto?> GuestDetailAsync(Guid id, CancellationToken cancellationToken = default)
    {
        var summary = (await GuestSummariesAsync(cancellationToken)).Find(g => g.Id == id);
        if (summary is null)
        {
            return null;
        }

        var stays = await ProjectStays(db.Stays.Where(s => s.GuestId == id)).ToListAsync(cancellationToken);
        return new GuestDetailDto
        {
            Id = summary.Id,
            Name = summary.Name,
            Phone = summary.Phone,
            NormalizedPhone = summary.NormalizedPhone,
            CustomerType = summary.CustomerType,
            IsRegular = summary.IsRegular,
            CustomerNote = summary.CustomerNote,
            Preferences = summary.Preferences,
            CreatedAt = summary.CreatedAt,
            UpdatedAt = summary.UpdatedAt,
            DeletedAt = summary.DeletedAt,
            StayId = summary.StayId,
            CheckInDate = summary.CheckInDate,
            CheckOutDate = summary.CheckOutDate,
            StayStatus = summary.StayStatus,
            TotalAmountSatang = summary.TotalAmountSatang,
            DiscountAmountSatang = summary.DiscountAmountSatang,
            RoomName = summary.RoomName,
            CompletedStays = summary.CompletedStays,
            TotalNights = summary.TotalNights,
            LifetimeValueSatang = summary.LifetimeValueSatang,
            TotalDiscountSatang = summary.TotalDiscountSatang,
            LastStayDate = summary.LastStayDate,
            LastRoomName = summary.LastRoomName,
            Stays = stays,
        };
    }

    public async Task<List<AttachmentDto>> AttachmentsAsync(CancellationToken cancellationToken = default)
    {
        var rows = await db.Attachments.AsNoTracking()
            .OrderByDescending(a => a.CreatedAt)
            .Select(a => new AttachmentDto(a.Id, a.StayId, a.OriginalName, a.MimeType, a.SizeBytes, a.CreatedAt))
            .ToListAsync(cancellationToken);
        return rows;
    }

    public static RoomDto ToDto(Room r) => new(
        r.Id, r.Name, r.Zone, r.Type, r.PriceSatang, r.BaseGuests, r.MaxGuests, r.ExtraGuestFeeSatang,
        r.SortOrder, r.Status, r.IsPetFriendly, r.CreatedAt, r.UpdatedAt, r.DeletedAt);

    public static GuestDto ToDto(Guest g) => new()
    {
        Id = g.Id,
        Name = g.Name,
        Phone = g.Phone,
        NormalizedPhone = g.NormalizedPhone,
        CustomerType = g.CustomerType,
        IsRegular = g.IsRegular,
        CustomerNote = g.CustomerNote,
        Preferences = g.Preferences,
        CreatedAt = g.CreatedAt,
        UpdatedAt = g.UpdatedAt,
        DeletedAt = g.DeletedAt,
    };

    public static FeedbackDto ToDto(Feedback f) => new(
        f.Id, f.StayId, f.CleanlinessRating, f.ServiceRating, f.FacilityRating, f.OverallRating, f.WouldReturn, f.Comment, f.CreatedAt, f.UpdatedAt);

    private static IQueryable<StayDto> ProjectStays(IQueryable<Stay> stays) => stays
        .AsNoTracking()
        .OrderByDescending(s => s.CheckInDate).ThenByDescending(s => s.CreatedAt)
        .Select(s => new StayDto
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
            RoomName = s.Room!.Name,
            Zone = s.Room.Zone,
            RoomType = s.Room.Type,
            RoomRateSatang = s.Room.PriceSatang,
            BaseGuests = s.Room.BaseGuests,
            MaxGuests = s.Room.MaxGuests,
            ExtraGuestFeeSatang = s.Room.ExtraGuestFeeSatang,
            IsPetFriendly = s.Room.IsPetFriendly,
            CustomerType = s.Guest == null ? null : s.Guest.CustomerType,
            IsRegular = s.Guest != null && s.Guest.IsRegular,
            FeedbackRating = s.Feedback == null ? null : s.Feedback.OverallRating,
        });

    private static GuestSummaryDto Summarize(Guest g, List<GuestStayRow> stays)
    {
        var first = stays.Count > 0 ? stays[0] : null;
        var completed = stays.Where(s => s.Status == StayStatus.CheckedOut).ToList();
        GuestStayRow? last = null;
        foreach (var stay in stays)
        {
            if (last is null || stay.CheckInDate > last.CheckInDate)
            {
                last = stay;
            }
        }

        return new GuestSummaryDto
        {
            Id = g.Id,
            Name = g.Name,
            Phone = g.Phone,
            NormalizedPhone = g.NormalizedPhone,
            CustomerType = g.CustomerType,
            IsRegular = g.IsRegular,
            CustomerNote = g.CustomerNote,
            Preferences = g.Preferences,
            CreatedAt = g.CreatedAt,
            UpdatedAt = g.UpdatedAt,
            DeletedAt = g.DeletedAt,
            StayId = first?.Id,
            CheckInDate = first?.CheckInDate,
            CheckOutDate = first?.CheckOutDate,
            StayStatus = first?.Status,
            TotalAmountSatang = first?.TotalAmountSatang,
            DiscountAmountSatang = first?.DiscountAmountSatang,
            RoomName = first?.RoomName,
            CompletedStays = completed.Count,
            TotalNights = completed.Sum(s => (long)PriceCalculator.Nights(s.CheckInDate, s.CheckOutDate)),
            LifetimeValueSatang = completed.Sum(s => s.TotalAmountSatang),
            TotalDiscountSatang = completed.Sum(s => s.DiscountAmountSatang),
            LastStayDate = last?.CheckInDate,
            LastRoomName = last?.RoomName,
        };
    }

    private sealed record GuestStayRow(
        Guid GuestId,
        Guid Id,
        DateOnly CheckInDate,
        DateOnly CheckOutDate,
        int Status,
        long TotalAmountSatang,
        long DiscountAmountSatang,
        string RoomName,
        DateTimeOffset CreatedAt);
}
