namespace ResortGuestbook.Data.Entities;

/// <summary>Entity whose creation time is stamped by <c>TimestampInterceptor</c>.</summary>
public interface ICreatedAt
{
    DateTimeOffset CreatedAt { get; set; }
}
