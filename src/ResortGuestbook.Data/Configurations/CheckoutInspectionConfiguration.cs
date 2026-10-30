using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using ResortGuestbook.Data.Entities;

namespace ResortGuestbook.Data.Configurations;

public sealed class CheckoutInspectionConfiguration : IEntityTypeConfiguration<CheckoutInspection>
{
    public void Configure(EntityTypeBuilder<CheckoutInspection> builder)
    {
        builder.ToTable("checkout_inspections");
        builder.HasKey(i => i.Id);
        builder.HasIndex(i => i.StayId, "ux_checkout_inspections_stay_id").IsUnique();
        builder.HasOne<Stay>().WithMany().HasForeignKey(i => i.StayId).OnDelete(DeleteBehavior.Cascade);
        builder.HasOne<AppUser>().WithMany().HasForeignKey(i => i.InspectedBy).OnDelete(DeleteBehavior.NoAction);
    }
}
