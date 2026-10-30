using ResortGuestbook.Data.Providers;

namespace ResortGuestbook.Tests.Data;

public sealed class SqliteDatabaseFactory : IDatabaseFactory, IDisposable
{
    private readonly string directory = Directory.CreateTempSubdirectory("staybook-tests-").FullName;

    public DatabaseProvider Provider => DatabaseProvider.Sqlite;

    public Task<string> CreateDatabaseAsync() =>
        Task.FromResult($"Data Source={Path.Combine(directory, $"{Guid.NewGuid():N}.db")};Pooling=False");

    public void Dispose()
    {
        try
        {
            Directory.Delete(directory, recursive: true);
        }
        catch (IOException)
        {
            // A file can still be locked briefly on Windows; the temp folder is cleaned by the OS.
        }
    }
}
