using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using ResortGuestbook.Data.Entities;

namespace ResortGuestbook.Data.Configurations;

public sealed class AppUserConfiguration : IEntityTypeConfiguration<AppUser>
{
    public void Configure(EntityTypeBuilder<AppUser> builder)
    {
        builder.ToTable("users", t => t.HasCheckConstraint("ck_users_role", "role IN ('admin','front_desk','housekeeping')"));
        builder.HasKey(u => u.Id);
        builder.HasIndex(u => u.Email, "ux_users_email").IsUnique();
        builder.Property(u => u.Active).HasDefaultValue(true).HasSentinel(true);
        builder.Property(u => u.AccessFailedCount).HasDefaultValue(0);
    }
}
