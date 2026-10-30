namespace ResortGuestbook.Data.Entities;

/// <summary>Rows with a <c>deleted_at</c> value are hidden by a global query filter.</summary>
public interface ISoftDeletable
{
    DateTimeOffset? DeletedAt { get; set; }
}
