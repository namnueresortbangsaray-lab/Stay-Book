using Microsoft.EntityFrameworkCore;
using ResortGuestbook.Data;
using ResortGuestbook.Data.Providers;
using ResortGuestbook.Data.Seed;
using ResortGuestbook.Web.Infrastructure.Identity;
using ResortGuestbook.Web.Infrastructure.Options;
using ResortGuestbook.Web.Infrastructure.Storage;
using ResortGuestbook.Web.Services;

namespace ResortGuestbook.Tests.Data;

/// <summary>The application services wired by hand against one migrated and seeded database.</summary>
public sealed class TestServices : IAsyncDisposable
{
    private TestServices(AppDbContext db, DatabaseProvider provider, string connectionString)
    {
        Db = db;
        Provider = provider;
        ConnectionString = connectionString;
        var clock = new AppClock(TimeProvider.System, Microsoft.Extensions.Options.Options.Create(new AppOptions()));
        Queries = new ResortQueries(db);
        var audit = new AuditService(db);
        Categories = new RoomCategoryService(db, audit);
        UploadsPath = Directory.CreateTempSubdirectory("staybook-uploads-").FullName;
        Storage = new LocalFileStorage(Microsoft.Extensions.Options.Options.Create(new StorageOptions { UploadsPath = UploadsPath }));
        IdPhotos = new IdPhotoService(db, Storage, audit, clock, Microsoft.Extensions.Options.Options.Create(new IdPhotoOptions()), Microsoft.Extensions.Logging.Abstractions.NullLogger<IdPhotoService>.Instance);
        Rooms = new RoomService(db, audit, Categories, IdPhotos);
        Guests = new GuestService(db, Queries, audit);
        Stays = new StayService(db, Queries, audit, clock, IdPhotos);
        Snapshots = new SnapshotService(Queries, clock);
        Users = new UserService(db, audit, new LegacyBcryptPasswordHasher(), clock, Microsoft.Extensions.Options.Options.Create(new AuthOptions()));
    }

    public AppDbContext Db { get; }
    public DatabaseProvider Provider { get; }
    public string ConnectionString { get; }
    public ResortQueries Queries { get; }
    public RoomService Rooms { get; }
    public RoomCategoryService Categories { get; }
    public GuestService Guests { get; }
    public StayService Stays { get; }
    public SnapshotService Snapshots { get; }
    public UserService Users { get; }
    public IdPhotoService IdPhotos { get; }
    public LocalFileStorage Storage { get; }
    public string UploadsPath { get; }
    public Actor Admin { get; private set; } = null!;

    public static async Task<TestServices> CreateAsync(IDatabaseFactory factory)
    {
        var connectionString = await factory.CreateDatabaseAsync();
        var db = new AppDbContext(AppDbContextOptions.Create(factory.Provider, connectionString, TimeProvider.System));
        await db.Database.MigrateAsync();
        await new DatabaseSeeder(db, new LegacyBcryptPasswordHasher()).SeedAsync("admin@staybook.local", "ChangeMe123!");
        var admin = await db.Users.SingleAsync();
        return new TestServices(db, factory.Provider, connectionString)
        {
            Admin = new Actor(admin.Id, admin.Name, admin.Email, admin.Role, "127.0.0.1"),
        };
    }

    public ValueTask DisposeAsync() => Db.DisposeAsync();
}
