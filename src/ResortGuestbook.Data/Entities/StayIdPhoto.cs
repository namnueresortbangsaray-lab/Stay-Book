namespace ResortGuestbook.Data.Entities;

/// <summary>
/// The guest's ID card photo for one booking (personal data): stored privately like attachments, kept apart from them so
/// it can be deleted on schedule, and removed with its booking.
/// </summary>
public sealed class StayIdPhoto : ICreatedAt
{
    public Guid Id { get; set; }
    public Guid StayId { get; set; }
    public Guid UploadedBy { get; set; }
    public string StoredName { get; set; } = string.Empty;
    public string MimeType { get; set; } = string.Empty;
    public long SizeBytes { get; set; }
    public DateTimeOffset CreatedAt { get; set; }
}
