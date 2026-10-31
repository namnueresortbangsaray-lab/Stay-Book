using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using ResortGuestbook.Data.Entities;

namespace ResortGuestbook.Data.Configurations;

public sealed class RoomTypeConfiguration : IEntityTypeConfiguration<RoomType>
{
    public void Configure(EntityTypeBuilder<RoomType> builder)
    {
        builder.ToTable("room_types", t =>
        {
            t.HasCheckConstraint("ck_room_types_price_satang", "price_satang >= 0");
            t.HasCheckConstraint("ck_room_types_base_guests", "base_guests >= 1");
            t.HasCheckConstraint("ck_room_types_max_guests", "max_guests >= base_guests");
        });
        builder.HasKey(t => t.Id);
        builder.HasIndex(t => t.Name, "ux_room_types_name").IsUnique();
        builder.Property(t => t.ExtraGuestFeeSatang).HasDefaultValue(0L);
        builder.Property(t => t.SortOrder).HasDefaultValue(0);
        builder.Property(t => t.IsPetFriendly).HasDefaultValue(false);
    }
}
