namespace ResortGuestbook.Data.Entities;

public sealed class Attachment : ICreatedAt
{
    public Guid Id { get; set; }
    public Guid StayId { get; set; }
    public Guid UploadedBy { get; set; }
    public string OriginalName { get; set; } = string.Empty;
    public string StoredName { get; set; } = string.Empty;
    public string MimeType { get; set; } = string.Empty;
    public long SizeBytes { get; set; }
    public DateTimeOffset CreatedAt { get; set; }
}
