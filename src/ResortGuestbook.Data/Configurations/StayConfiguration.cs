using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using ResortGuestbook.Data.Entities;

namespace ResortGuestbook.Data.Configurations;

public sealed class StayConfiguration : IEntityTypeConfiguration<Stay>
{
    public void Configure(EntityTypeBuilder<Stay> builder)
    {
        builder.ToTable("stays", t =>
        {
            t.HasCheckConstraint("ck_stays_guests", "guests >= 1");
            t.HasCheckConstraint("ck_stays_total_amount_satang", "total_amount_satang >= 0");
            t.HasCheckConstraint("ck_stays_status", "status IN (0,1,2)");
            t.HasCheckConstraint("ck_stays_dates", "check_out_date > check_in_date");
        });
        builder.HasKey(s => s.Id);
        builder.HasIndex(s => new { s.CheckInDate, s.CheckOutDate }, "idx_stays_dates");
        builder.HasIndex(s => new { s.RoomId, s.Status }, "idx_stays_room_status");
        builder.HasIndex(s => s.GuestId, "idx_stays_guest");
        builder.HasOne(s => s.Room).WithMany().HasForeignKey(s => s.RoomId).IsRequired().OnDelete(DeleteBehavior.NoAction);
        builder.HasOne(s => s.Guest).WithMany().HasForeignKey(s => s.GuestId).OnDelete(DeleteBehavior.NoAction);
        builder.HasOne(s => s.Feedback).WithOne().HasForeignKey<Feedback>(f => f.StayId).OnDelete(DeleteBehavior.Cascade);
        builder.Property(s => s.ExtraBed).HasDefaultValue(false);
        builder.Property(s => s.Status).HasDefaultValue(0);
        builder.Property(s => s.DepositAmountSatang).HasDefaultValue(0L);
        builder.Property(s => s.DepositPaid).HasDefaultValue(false);
        builder.Property(s => s.IdVerified).HasDefaultValue(false);
        builder.Property(s => s.PetCount).HasDefaultValue(0);
        builder.Property(s => s.PetFeeSatang).HasDefaultValue(0L);
        builder.Property(s => s.DiscountAmountSatang).HasDefaultValue(0L);
    }
}
