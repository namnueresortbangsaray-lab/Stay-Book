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
    public static async Task<DataSet> ReadAsync(AppDbContext db, CancellationToken cancellationToken) => new(
        await db.Users.IgnoreQueryFilters().AsNoTracking().ToListAsync(cancellationToken),
        await ReadRestAsync(db, cancellationToken));

    /// <summary>Builds a data set from users read separately (e.g. from the PHP schema) and the other tables via EF.</summary>
    public DataSet(IReadOnlyList<AppUser> users, DataSet rest)
        : this(users, rest.Rooms, rest.Guests, rest.Stays, rest.CheckoutInspections, rest.Feedbacks, rest.Attachments, rest.AuditLogs)
    {
    }

    public static async Task<DataSet> ReadRestAsync(AppDbContext db, CancellationToken cancellationToken) => new(
        [],
        await db.Rooms.IgnoreQueryFilters().AsNoTracking().ToListAsync(cancellationToken),
        await db.Guests.IgnoreQueryFilters().AsNoTracking().ToListAsync(cancellationToken),
        await db.Stays.IgnoreQueryFilters().AsNoTracking().ToListAsync(cancellationToken),
        await db.CheckoutInspections.AsNoTracking().ToListAsync(cancellationToken),
        await db.Feedbacks.AsNoTracking().ToListAsync(cancellationToken),
        await db.Attachments.AsNoTracking().ToListAsync(cancellationToken),
        await db.AuditLogs.AsNoTracking().ToListAsync(cancellationToken));
}
