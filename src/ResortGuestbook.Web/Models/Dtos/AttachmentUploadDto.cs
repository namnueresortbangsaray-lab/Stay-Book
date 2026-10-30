namespace ResortGuestbook.Web.Models.Dtos;

/// <summary>Response of a successful upload (the inserted row).</summary>
public sealed record AttachmentUploadDto(
    Guid Id,
    Guid StayId,
    Guid UploadedBy,
    string OriginalName,
    string StoredName,
    string MimeType,
    long SizeBytes,
    DateTimeOffset CreatedAt);
