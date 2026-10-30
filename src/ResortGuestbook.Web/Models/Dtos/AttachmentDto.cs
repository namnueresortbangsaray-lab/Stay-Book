namespace ResortGuestbook.Web.Models.Dtos;

/// <summary>Attachment metadata as listed in the snapshot (no storage details).</summary>
public sealed record AttachmentDto(
    Guid Id,
    Guid StayId,
    string OriginalName,
    string MimeType,
    long SizeBytes,
    DateTimeOffset CreatedAt);
