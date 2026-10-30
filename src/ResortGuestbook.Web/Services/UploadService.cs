using System.Security.Cryptography;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Options;
using ResortGuestbook.Data;
using ResortGuestbook.Data.Entities;
using ResortGuestbook.Web.Infrastructure.Options;
using ResortGuestbook.Web.Infrastructure.Storage;
using ResortGuestbook.Web.Models.Dtos;
using ResortGuestbook.Web.Services.Errors;

namespace ResortGuestbook.Web.Services;

/// <summary>Stores a booking attachment (JPEG, PNG, WebP or PDF) under a random name in private storage.</summary>
public sealed class UploadService(AppDbContext db, IFileStorage storage, IOptions<UploadOptions> options, ILogger<UploadService> logger)
{
    public async Task<AttachmentUploadDto> StoreAsync(string stayId, IFormFile? file, Actor actor, CancellationToken cancellationToken)
    {
        var stayKey = Guid.TryParse(stayId, out var parsed) ? parsed : Guid.Empty;
        if (!await db.Stays.AnyAsync(s => s.Id == stayKey, cancellationToken))
        {
            throw new NotFoundException("ไม่พบ Booking");
        }

        if (file is null)
        {
            throw new ValidationException("file", "อัปโหลดไฟล์ไม่สำเร็จ");
        }

        if (file.Length < 1 || file.Length > options.Value.MaxBytes)
        {
            throw new ValidationException("file", "ไฟล์มีขนาดไม่ถูกต้องหรือใหญ่เกินกำหนด");
        }

        var header = new byte[FileSignatureSniffer.HeaderLength];
        int read;
        await using (var probe = file.OpenReadStream())
        {
            read = await probe.ReadAtLeastAsync(header, header.Length, throwOnEndOfStream: false, cancellationToken);
        }

        var mime = FileSignatureSniffer.Detect(header.AsSpan(0, read));
        if (mime is null)
        {
            throw new ValidationException("file", "ประเภทไฟล์ไม่ได้รับอนุญาต");
        }

        var storedName = $"{Convert.ToHexStringLower(RandomNumberGenerator.GetBytes(24))}.{FileSignatureSniffer.Allowed[mime]}";
        await using (var content = file.OpenReadStream())
        {
            await storage.SaveAsync(storedName, content, cancellationToken);
        }

        var attachment = new Attachment
        {
            Id = Guid.NewGuid(),
            StayId = stayKey,
            UploadedBy = actor.Id,
            OriginalName = Path.GetFileName(file.FileName),
            StoredName = storedName,
            MimeType = mime,
            SizeBytes = file.Length,
        };
        try
        {
            db.Attachments.Add(attachment);
            await db.SaveChangesAsync(cancellationToken);
        }
        catch (Exception exception)
        {
            logger.LogWarning(exception, "Attachment row could not be saved; removing stored file");
            await storage.DeleteAsync(storedName, CancellationToken.None);
            throw;
        }

        return new AttachmentUploadDto(attachment.Id, attachment.StayId, attachment.UploadedBy, attachment.OriginalName, attachment.StoredName, attachment.MimeType, attachment.SizeBytes, attachment.CreatedAt);
    }
}
