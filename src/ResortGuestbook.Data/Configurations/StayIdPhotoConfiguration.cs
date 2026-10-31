using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using ResortGuestbook.Data.Entities;

namespace ResortGuestbook.Data.Configurations;

public sealed class StayIdPhotoConfiguration : IEntityTypeConfiguration<StayIdPhoto>
{
    public void Configure(EntityTypeBuilder<StayIdPhoto> builder)
    {
        builder.ToTable("stay_id_photos");
        builder.HasKey(p => p.Id);
        builder.HasIndex(p => p.StayId, "ux_stay_id_photos_stay_id").IsUnique();
        builder.HasIndex(p => p.StoredName, "ux_stay_id_photos_stored_name").IsUnique();
        builder.HasOne<Stay>().WithMany().HasForeignKey(p => p.StayId).OnDelete(DeleteBehavior.Cascade);
        builder.HasOne<AppUser>().WithMany().HasForeignKey(p => p.UploadedBy).OnDelete(DeleteBehavior.NoAction);
    }
}
