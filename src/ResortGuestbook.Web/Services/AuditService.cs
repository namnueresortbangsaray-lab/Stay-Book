using System.Text.Json;
using ResortGuestbook.Data;
using ResortGuestbook.Data.Entities;
using ResortGuestbook.Web.Infrastructure.Http;

namespace ResortGuestbook.Web.Services;

/// <summary>
/// Writes <c>audit_logs</c> rows after a successful change, with the API representation of the entity before and after
/// (same semantics as the v1 <c>ResortRepository::audit</c>).
/// </summary>
public sealed class AuditService(AppDbContext db)
{
    public async Task RecordAsync(string action, string entityType, Guid entityId, object? before, object? after, Actor actor, CancellationToken cancellationToken)
    {
        db.AuditLogs.Add(new AuditLog
        {
            Id = Guid.NewGuid(),
            UserId = actor.Id,
            Action = action,
            EntityType = entityType,
            EntityId = entityId,
            BeforeJson = before is null ? null : JsonSerializer.Serialize(before, before.GetType(), ApiJson.Options),
            AfterJson = after is null ? null : JsonSerializer.Serialize(after, after.GetType(), ApiJson.Options),
            IpAddress = actor.Ip,
        });
        await db.SaveChangesAsync(cancellationToken);
    }
}
