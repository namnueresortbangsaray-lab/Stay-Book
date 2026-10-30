using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Infrastructure;

namespace ResortGuestbook.Data.Providers;

/// <summary>
/// Caches one model per provider: the SQLite model carries value converters the PostgreSQL model does not,
/// and <c>db:transfer</c> uses both in the same process.
/// </summary>
public sealed class ProviderModelCacheKeyFactory : IModelCacheKeyFactory
{
    public object Create(DbContext context, bool designTime) =>
        (context.GetType(), context.Database.ProviderName, designTime);
}
