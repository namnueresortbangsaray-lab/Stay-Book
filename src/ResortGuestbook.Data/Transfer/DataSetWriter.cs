using Microsoft.EntityFrameworkCore;

namespace ResortGuestbook.Data.Transfer;

/// <summary>
/// Upserts a <see cref="DataSet"/> by primary key into a migrated database in one transaction, then verifies that every
/// source row exists in the target. Re-running is safe. The target context must not stamp timestamps.
/// </summary>
public static class DataSetWriter
{
    private const int BatchSize = 500;

    public static async Task<IReadOnlyList<TableCount>> WriteAsync(AppDbContext target, DataSet data, bool truncate, bool dryRun, CancellationToken cancellationToken)
    {
        if (dryRun)
        {
            return Counts(data, null);
        }

        await using var transaction = await target.Database.BeginTransactionAsync(cancellationToken);
        if (truncate)
        {
            await target.AuditLogs.ExecuteDeleteAsync(cancellationToken);
            await target.Attachments.ExecuteDeleteAsync(cancellationToken);
            await target.Feedbacks.ExecuteDeleteAsync(cancellationToken);
            await target.CheckoutInspections.ExecuteDeleteAsync(cancellationToken);
            await target.Stays.IgnoreQueryFilters().ExecuteDeleteAsync(cancellationToken);
            await target.Guests.IgnoreQueryFilters().ExecuteDeleteAsync(cancellationToken);
            await target.Rooms.IgnoreQueryFilters().ExecuteDeleteAsync(cancellationToken);
            await target.RoomZones.ExecuteDeleteAsync(cancellationToken);
            await target.RoomTypes.ExecuteDeleteAsync(cancellationToken);
            await target.Users.IgnoreQueryFilters().ExecuteDeleteAsync(cancellationToken);
        }

        var counts = new Dictionary<string, int>
        {
            ["users"] = await UpsertAsync(target, data.Users, u => u.Id, cancellationToken),
            ["rooms"] = await UpsertAsync(target, data.Rooms, r => r.Id, cancellationToken),
            ["room_zones"] = await UpsertAsync(target, data.RoomZones, z => z.Id, cancellationToken),
            ["room_types"] = await UpsertAsync(target, data.RoomTypes, t => t.Id, cancellationToken),
            ["guests"] = await UpsertAsync(target, data.Guests, g => g.Id, cancellationToken),
            ["stays"] = await UpsertAsync(target, data.Stays, s => s.Id, cancellationToken),
            ["checkout_inspections"] = await UpsertAsync(target, data.CheckoutInspections, i => i.Id, cancellationToken),
            ["feedbacks"] = await UpsertAsync(target, data.Feedbacks, f => f.Id, cancellationToken),
            ["attachments"] = await UpsertAsync(target, data.Attachments, a => a.Id, cancellationToken),
            ["audit_logs"] = await UpsertAsync(target, data.AuditLogs, a => a.Id, cancellationToken),
        };

        await transaction.CommitAsync(cancellationToken);
        return Counts(data, counts);
    }

    private static IReadOnlyList<TableCount> Counts(DataSet data, Dictionary<string, int>? target) =>
    [
        new("users", data.Users.Count, target?["users"] ?? data.Users.Count),
        new("rooms", data.Rooms.Count, target?["rooms"] ?? data.Rooms.Count),
        new("room_zones", data.RoomZones.Count, target?["room_zones"] ?? data.RoomZones.Count),
        new("room_types", data.RoomTypes.Count, target?["room_types"] ?? data.RoomTypes.Count),
        new("guests", data.Guests.Count, target?["guests"] ?? data.Guests.Count),
        new("stays", data.Stays.Count, target?["stays"] ?? data.Stays.Count),
        new("checkout_inspections", data.CheckoutInspections.Count, target?["checkout_inspections"] ?? data.CheckoutInspections.Count),
        new("feedbacks", data.Feedbacks.Count, target?["feedbacks"] ?? data.Feedbacks.Count),
        new("attachments", data.Attachments.Count, target?["attachments"] ?? data.Attachments.Count),
        new("audit_logs", data.AuditLogs.Count, target?["audit_logs"] ?? data.AuditLogs.Count),
    ];

    /// <returns>The total number of rows in the target table afterwards.</returns>
    private static async Task<int> UpsertAsync<T>(AppDbContext target, IReadOnlyList<T> rows, Func<T, Guid> key, CancellationToken cancellationToken)
        where T : class
    {
        var set = target.Set<T>();
        var existing = (await set.IgnoreQueryFilters().AsNoTracking().ToListAsync(cancellationToken)).Select(key).ToHashSet();
        foreach (var batch in rows.Chunk(BatchSize))
        {
            foreach (var row in batch)
            {
                if (existing.Contains(key(row)))
                {
                    set.Update(row);
                }
                else
                {
                    set.Add(row);
                }
            }

            await target.SaveChangesAsync(cancellationToken);
            target.ChangeTracker.Clear();
        }

        var after = (await set.IgnoreQueryFilters().AsNoTracking().ToListAsync(cancellationToken)).Select(key).ToHashSet();
        var missing = rows.Count(r => !after.Contains(key(r)));
        if (missing > 0)
        {
            throw new InvalidOperationException($"Row verification failed for {typeof(T).Name}: {missing} source rows are missing in the target.");
        }

        return after.Count;
    }
}
