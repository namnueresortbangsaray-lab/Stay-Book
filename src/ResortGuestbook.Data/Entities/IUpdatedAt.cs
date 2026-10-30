namespace ResortGuestbook.Data.Entities;

/// <summary>Entity whose last-modified time is stamped by <c>TimestampInterceptor</c>.</summary>
public interface IUpdatedAt
{
    DateTimeOffset UpdatedAt { get; set; }
}
