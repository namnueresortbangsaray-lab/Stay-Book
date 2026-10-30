using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using ResortGuestbook.Data.Entities;

namespace ResortGuestbook.Data.Configurations;

public sealed class FeedbackConfiguration : IEntityTypeConfiguration<Feedback>
{
    public void Configure(EntityTypeBuilder<Feedback> builder)
    {
        builder.ToTable("feedbacks", t =>
        {
            t.HasCheckConstraint("ck_feedbacks_cleanliness_rating", "cleanliness_rating BETWEEN 1 AND 5");
            t.HasCheckConstraint("ck_feedbacks_service_rating", "service_rating BETWEEN 1 AND 5");
            t.HasCheckConstraint("ck_feedbacks_facility_rating", "facility_rating BETWEEN 1 AND 5");
            t.HasCheckConstraint("ck_feedbacks_overall_rating", "overall_rating BETWEEN 1 AND 5");
        });
        builder.HasKey(f => f.Id);
        builder.HasIndex(f => f.StayId, "ux_feedbacks_stay_id").IsUnique();
        builder.Property(f => f.WouldReturn).HasDefaultValue(true).HasSentinel(true);
    }
}
