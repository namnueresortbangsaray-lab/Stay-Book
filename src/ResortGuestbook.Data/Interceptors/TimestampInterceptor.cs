using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Diagnostics;
using ResortGuestbook.Data.Entities;

namespace ResortGuestbook.Data.Interceptors;

/// <summary>Sets <c>created_at</c> on insert and <c>updated_at</c> on insert/update, in UTC truncated to seconds like PHP.</summary>
public sealed class TimestampInterceptor(TimeProvider clock) : SaveChangesInterceptor
{
    public override InterceptionResult<int> SavingChanges(DbContextEventData eventData, InterceptionResult<int> result)
    {
        Stamp(eventData.Context);
        return result;
    }

    public override ValueTask<InterceptionResult<int>> SavingChangesAsync(DbContextEventData eventData, InterceptionResult<int> result, CancellationToken cancellationToken = default)
    {
        Stamp(eventData.Context);
        return ValueTask.FromResult(result);
    }

    private void Stamp(DbContext? context)
    {
        if (context is null)
        {
            return;
        }

        var now = clock.GetUtcNow();
        now = now.AddTicks(-(now.Ticks % TimeSpan.TicksPerSecond));
        foreach (var entry in context.ChangeTracker.Entries())
        {
            if (entry.State == EntityState.Added && entry.Entity is ICreatedAt created && created.CreatedAt == default)
            {
                created.CreatedAt = now;
            }

            if (entry.State is EntityState.Added or EntityState.Modified && entry.Entity is IUpdatedAt updated)
            {
                if (entry.State == EntityState.Modified || updated.UpdatedAt == default)
                {
                    updated.UpdatedAt = now;
                }
            }
        }
    }
}
