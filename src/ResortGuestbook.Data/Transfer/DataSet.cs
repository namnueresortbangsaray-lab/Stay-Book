using Microsoft.EntityFrameworkCore;
using ResortGuestbook.Data.Entities;

namespace ResortGuestbook.Data.Transfer;

/// <summary>All application rows, including soft-deleted ones, in foreign-key order.</summary>
public sealed record DataSet(
    IReadOnlyList<AppUser> Users,
    IReadOnlyList<Room> Rooms,
    IReadOnlyList<Guest> Guests,
    IReadOnlyList<Stay> Stays,
    IReadOnlyList<CheckoutInspection> CheckoutInspections,
    IReadOnlyList<Feedback> Feedbacks,
    IReadOnlyList<Attachment> Attachments,
    IReadOnlyList<AuditLog> AuditLogs)
{
    /// <summary>Zone and room-type lists; empty when the source predates them (the v1 schema has no such tables).</summary>
    public IReadOnlyList<RoomZone> RoomZones { get; init; } = [];

    public IReadOnlyList<RoomType> RoomTypes { get; init; } = [];

    /// <summary>ID card photo rows (the files themselves live in upload storage).</summary>
    public IReadOnlyList<StayIdPhoto> StayIdPhotos { get; init; } = [];

    public static async Task<DataSet> ReadAsync(AppDbContext db, CancellationToken cancellationToken) => new(
        await db.Users.IgnoreQueryFilters().AsNoTracking().ToListAsync(cancellationToken),
        await ReadRestAsync(db, cancellationToken))
    {
        RoomZones = await db.RoomZones.AsNoTracking().ToListAsync(cancellationToken),
        RoomTypes = await db.RoomTypes.AsNoTracking().ToListAsync(cancellationToken),
        StayIdPhotos = await db.StayIdPhotos.AsNoTracking().ToListAsync(cancellationToken),
    };

    /// <summary>Builds a data set from users read separately (e.g. from the v1 schema) and the other tables via EF.</summary>
    public DataSet(IReadOnlyList<AppUser> users, DataSet rest)
        : this(users, rest.Rooms, rest.Guests, rest.Stays, rest.CheckoutInspections, rest.Feedbacks, rest.Attachments, rest.AuditLogs)
    {
    }

    /// <summary>All tables but users. With <c>v1Schema</c>, stays are read without columns added after v1 (<c>booking_channel</c>).</summary>
    public static async Task<DataSet> ReadRestAsync(AppDbContext db, CancellationToken cancellationToken, bool v1Schema = false) => new(
        [],
        await db.Rooms.IgnoreQueryFilters().AsNoTracking().ToListAsync(cancellationToken),
        await db.Guests.IgnoreQueryFilters().AsNoTracking().ToListAsync(cancellationToken),
        v1Schema ? await ReadV1StaysAsync(db, cancellationToken) : await db.Stays.IgnoreQueryFilters().AsNoTracking().ToListAsync(cancellationToken),
        await db.CheckoutInspections.AsNoTracking().ToListAsync(cancellationToken),
        await db.Feedbacks.AsNoTracking().ToListAsync(cancellationToken),
        await db.Attachments.AsNoTracking().ToListAsync(cancellationToken),
        await db.AuditLogs.AsNoTracking().ToListAsync(cancellationToken));

    private static Task<List<Stay>> ReadV1StaysAsync(AppDbContext db, CancellationToken cancellationToken) => db.Stays
        .IgnoreQueryFilters()
        .AsNoTracking()
        .Select(s => new Stay
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
        })
        .ToListAsync(cancellationToken);
}
