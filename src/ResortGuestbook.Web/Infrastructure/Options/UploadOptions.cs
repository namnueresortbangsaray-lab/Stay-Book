namespace ResortGuestbook.Web.Infrastructure.Options;

/// <summary>Upload limits (<c>UPLOAD_MAX_BYTES</c>, default 5 MiB; requests up to 6 MiB like Nginx's <c>client_max_body_size</c>).</summary>
public sealed class UploadOptions
{
    public long MaxBytes { get; set; } = 5_242_880;
    public long MaxRequestBytes { get; set; } = 6 * 1024 * 1024;
}
