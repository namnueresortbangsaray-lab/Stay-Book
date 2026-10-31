using System.Linq.Expressions;
using System.Text;
using Microsoft.EntityFrameworkCore;
using ResortGuestbook.Data.Conversions;
using ResortGuestbook.Data.Entities;

namespace ResortGuestbook.Data;

public sealed class AppDbContext(DbContextOptions<AppDbContext> options) : DbContext(options)
{
    public DbSet<AppUser> Users => Set<AppUser>();
    public DbSet<Room> Rooms => Set<Room>();
    public DbSet<RoomZone> RoomZones => Set<RoomZone>();
    public DbSet<RoomType> RoomTypes => Set<RoomType>();
    public DbSet<Guest> Guests => Set<Guest>();
    public DbSet<Stay> Stays => Set<Stay>();
    public DbSet<CheckoutInspection> CheckoutInspections => Set<CheckoutInspection>();
    public DbSet<Feedback> Feedbacks => Set<Feedback>();
    public DbSet<Attachment> Attachments => Set<Attachment>();
    public DbSet<StayIdPhoto> StayIdPhotos => Set<StayIdPhoto>();
    public DbSet<AuditLog> AuditLogs => Set<AuditLog>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.ApplyConfigurationsFromAssembly(typeof(AppDbContext).Assembly);

        var sqlite = Database.IsSqlite();
        foreach (var entity in modelBuilder.Model.GetEntityTypes())
        {
            foreach (var property in entity.GetProperties())
            {
                property.SetColumnName(ToSnakeCase(property.Name));
                var type = Nullable.GetUnderlyingType(property.ClrType) ?? property.ClrType;
                if (sqlite && type == typeof(Guid))
                {
                    property.SetValueConverter(new LowercaseGuidConverter());
                }
                else if (sqlite && type == typeof(DateTimeOffset))
                {
                    property.SetValueConverter(new UtcTimestampConverter());
                }
            }

            if (typeof(ISoftDeletable).IsAssignableFrom(entity.ClrType))
            {
                var row = Expression.Parameter(entity.ClrType, "row");
                var notDeleted = Expression.Equal(
                    Expression.Property(row, nameof(ISoftDeletable.DeletedAt)),
                    Expression.Constant(null, typeof(DateTimeOffset?)));
                modelBuilder.Entity(entity.ClrType).HasQueryFilter(Expression.Lambda(notDeleted, row));
            }
        }

        if (!sqlite)
        {
            modelBuilder.Entity<AuditLog>().Property(a => a.BeforeJson).HasColumnType("jsonb");
            modelBuilder.Entity<AuditLog>().Property(a => a.AfterJson).HasColumnType("jsonb");
        }
    }

    private static string ToSnakeCase(string name)
    {
        var builder = new StringBuilder(name.Length + 8);
        for (var i = 0; i < name.Length; i++)
        {
            var c = name[i];
            if (char.IsUpper(c) && i > 0)
            {
                builder.Append('_');
            }

            builder.Append(char.ToLowerInvariant(c));
        }

        return builder.ToString();
    }
}
