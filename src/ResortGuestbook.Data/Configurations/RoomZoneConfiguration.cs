using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using ResortGuestbook.Data.Entities;

namespace ResortGuestbook.Data.Configurations;

public sealed class RoomZoneConfiguration : IEntityTypeConfiguration<RoomZone>
{
    public void Configure(EntityTypeBuilder<RoomZone> builder)
    {
        builder.ToTable("room_zones");
        builder.HasKey(z => z.Id);
        builder.HasIndex(z => z.Name, "ux_room_zones_name").IsUnique();
        builder.Property(z => z.SortOrder).HasDefaultValue(0);
    }
}
