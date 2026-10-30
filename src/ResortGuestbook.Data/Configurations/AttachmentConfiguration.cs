using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using ResortGuestbook.Data.Entities;

namespace ResortGuestbook.Data.Configurations;

public sealed class AttachmentConfiguration : IEntityTypeConfiguration<Attachment>
{
    public void Configure(EntityTypeBuilder<Attachment> builder)
    {
        builder.ToTable("attachments");
        builder.HasKey(a => a.Id);
        builder.HasIndex(a => a.StoredName, "ux_attachments_stored_name").IsUnique();
        builder.HasOne<Stay>().WithMany().HasForeignKey(a => a.StayId).OnDelete(DeleteBehavior.Cascade);
        builder.HasOne<AppUser>().WithMany().HasForeignKey(a => a.UploadedBy).OnDelete(DeleteBehavior.NoAction);
    }
}
