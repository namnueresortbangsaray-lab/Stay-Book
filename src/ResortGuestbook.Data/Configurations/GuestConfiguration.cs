using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using ResortGuestbook.Data.Entities;

namespace ResortGuestbook.Data.Configurations;

public sealed class GuestConfiguration : IEntityTypeConfiguration<Guest>
{
    public void Configure(EntityTypeBuilder<Guest> builder)
    {
        builder.ToTable("guests");
        builder.HasKey(g => g.Id);
        builder.HasIndex(g => g.NormalizedPhone, "ux_guests_normalized_phone").IsUnique();
        builder.HasIndex(g => g.Name, "idx_guests_name");
        builder.HasIndex(g => g.NormalizedPhone, "idx_guests_phone");
        builder.Property(g => g.CustomerType).HasDefaultValue(Guest.DefaultCustomerType);
        builder.Property(g => g.IsRegular).HasDefaultValue(false);
    }
}
