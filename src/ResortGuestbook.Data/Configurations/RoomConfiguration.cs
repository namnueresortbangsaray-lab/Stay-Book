using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using ResortGuestbook.Data.Entities;

namespace ResortGuestbook.Data.Configurations;

public sealed class RoomConfiguration : IEntityTypeConfiguration<Room>
{
    public void Configure(EntityTypeBuilder<Room> builder)
    {
        builder.ToTable("rooms", t =>
        {
            t.HasCheckConstraint("ck_rooms_price_satang", "price_satang >= 0");
            t.HasCheckConstraint("ck_rooms_base_guests", "base_guests >= 1");
            t.HasCheckConstraint("ck_rooms_max_guests", "max_guests >= base_guests");
            t.HasCheckConstraint("ck_rooms_status", "status IN (0,1)");
        });
        builder.HasKey(r => r.Id);
        builder.HasIndex(r => r.Name, "ux_rooms_name").IsUnique();
        builder.HasIndex(r => new { r.Zone, r.Status }, "idx_rooms_zone_status");
        builder.Property(r => r.ExtraGuestFeeSatang).HasDefaultValue(0L);
        builder.Property(r => r.SortOrder).HasDefaultValue(0);
        builder.Property(r => r.Status).HasDefaultValue(0);
        builder.Property(r => r.IsPetFriendly).HasDefaultValue(false);
    }
}
