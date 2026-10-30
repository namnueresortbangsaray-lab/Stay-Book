using ResortGuestbook.Data.Providers;

namespace ResortGuestbook.Tests.Data;

/// <summary>Creates an empty database per test for one provider.</summary>
public interface IDatabaseFactory
{
    DatabaseProvider Provider { get; }

    Task<string> CreateDatabaseAsync();
}
