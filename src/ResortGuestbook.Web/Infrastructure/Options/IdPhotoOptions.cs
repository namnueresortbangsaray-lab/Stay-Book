namespace ResortGuestbook.Web.Infrastructure.Options;

/// <summary>ID card photos (<c>IdPhotos__*</c>): size limit and how long they are kept after check-out.</summary>
public sealed class IdPhotoOptions
{
    /// <summary>Photos are shrunk in the browser first (about 100–300 KB), so 2 MB is generous.</summary>
    public long MaxBytes { get; set; } = 2_097_152;

    public int RetentionDays { get; set; } = 90;
}
