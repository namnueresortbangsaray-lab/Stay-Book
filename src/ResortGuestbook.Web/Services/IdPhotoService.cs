using System.Globalization;
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

/// <summary>
/// One ID card photo per booking (JPEG, PNG or WebP, shrunk by the browser before upload), in private storage.
/// Photos are personal data: they go with their booking or room, and are purged a set number of days after check-out.
/// </summary>
public sealed class IdPhotoService(AppDbContext db, IFileStorage storage, AuditService audit, AppClock clock, IOptions<IdPhotoOptions> options, ILogger<IdPhotoService> logger)
{
    private const string EntityType = "stay_id_photo";

    public async Task<List<IdPhotoDto>> ListAsync(CancellationToken cancellationToken)
    {
        var rows = await db.StayIdPhotos.AsNoTracking()
            .Join(db.Stays, p => p.StayId, s => s.Id, (p, s) => new { p.StayId, p.SizeBytes, p.CreatedAt, s.Status, s.CheckOutDate })
            .ToListAsync(cancellationToken);
        return [.. rows.Select(r => new IdPhotoDto(r.StayId, r.SizeBytes, r.CreatedAt, r.Status == StayStatus.CheckedOut ? r.CheckOutDate.AddDays(options.Value.RetentionDays) : null))];
    }

    public async Task<IdPhotoDto> StoreAsync(string stayId, IFormFile? file, Actor actor, CancellationToken cancellationToken)
    {
        var stay = (Guid.TryParse(stayId, out var key) ? await db.Stays.AsNoTracking().FirstOrDefaultAsync(s => s.Id == key, cancellationToken) : null)
            ?? throw new NotFoundException("ไม่พบ Booking");
        if (file is null || file.Length < 1 || file.Length > options.Value.MaxBytes)
        {
            throw new ValidationException("file", string.Create(CultureInfo.InvariantCulture, $"รูปบัตรต้องเป็นไฟล์รูปขนาดไม่เกิน {options.Value.MaxBytes / 1_048_576d:0.#} MB"));
        }

        var header = new byte[FileSignatureSniffer.HeaderLength];
        int read;
        await using (var probe = file.OpenReadStream())
        {
            read = await probe.ReadAtLeastAsync(header, header.Length, throwOnEndOfStream: false, cancellationToken);
        }

        var mime = FileSignatureSniffer.Detect(header.AsSpan(0, read));
        if (mime is null || !mime.StartsWith("image/", StringComparison.Ordinal))
        {
            throw new ValidationException("file", "รูปบัตรต้องเป็นไฟล์ JPEG, PNG หรือ WebP");
        }

        var storedName = $"id-{Convert.ToHexStringLower(RandomNumberGenerator.GetBytes(24))}.{FileSignatureSniffer.Allowed[mime]}";
        await using (var content = file.OpenReadStream())
        {
            await storage.SaveAsync(storedName, content, cancellationToken);
        }

        var previous = await db.StayIdPhotos.FirstOrDefaultAsync(p => p.StayId == stay.Id, cancellationToken);
        var photo = new StayIdPhoto { Id = Guid.NewGuid(), StayId = stay.Id, UploadedBy = actor.Id, StoredName = storedName, MimeType = mime, SizeBytes = file.Length };
        try
        {
            if (previous is not null)
            {
                db.StayIdPhotos.Remove(previous);
                await db.SaveChangesAsync(cancellationToken);
            }

            db.StayIdPhotos.Add(photo);
            await db.SaveChangesAsync(cancellationToken);
        }
        catch (Exception exception)
        {
            logger.LogWarning(exception, "ID photo row could not be saved; removing stored file");
            await storage.DeleteAsync(storedName, CancellationToken.None);
            throw;
        }

        if (previous is not null)
        {
            await storage.DeleteAsync(previous.StoredName, cancellationToken);
        }

        var dto = new IdPhotoDto(stay.Id, photo.SizeBytes, photo.CreatedAt, stay.Status == StayStatus.CheckedOut ? stay.CheckOutDate.AddDays(options.Value.RetentionDays) : null);
        await audit.RecordAsync(previous is null ? "create" : "update", EntityType, stay.Id, null, new { dto.SizeBytes, photo.MimeType }, actor, cancellationToken);
        return dto;
    }

    public async Task DeleteAsync(string stayId, Actor actor, CancellationToken cancellationToken)
    {
        var photo = (Guid.TryParse(stayId, out var key) ? await db.StayIdPhotos.FirstOrDefaultAsync(p => p.StayId == key, cancellationToken) : null)
            ?? throw new NotFoundException("ไม่พบรูปบัตร");
        db.StayIdPhotos.Remove(photo);
        await db.SaveChangesAsync(cancellationToken);
        await storage.DeleteAsync(photo.StoredName, cancellationToken);
        await audit.RecordAsync("delete", EntityType, photo.StayId, new { photo.SizeBytes, photo.MimeType }, null, actor, cancellationToken);
    }

    /// <summary>Removes the photo files of bookings that are about to be deleted (their rows go with the bookings).</summary>
    public async Task DeleteFilesForStaysAsync(IQueryable<Guid> stayIds, CancellationToken cancellationToken)
    {
        foreach (var name in await db.StayIdPhotos.Where(p => stayIds.Contains(p.StayId)).Select(p => p.StoredName).ToListAsync(cancellationToken))
        {
            await storage.DeleteAsync(name, cancellationToken);
        }
    }

    /// <summary>Deletes photos of bookings checked out more than <c>RetentionDays</c> days ago; returns how many.</summary>
    public async Task<int> PurgeExpiredAsync(CancellationToken cancellationToken)
    {
        var cutoff = clock.Today.AddDays(-options.Value.RetentionDays);
        var expired = await db.StayIdPhotos
            .Where(p => db.Stays.Any(s => s.Id == p.StayId && s.Status == StayStatus.CheckedOut && s.CheckOutDate < cutoff))
            .ToListAsync(cancellationToken);
        foreach (var photo in expired)
        {
            db.StayIdPhotos.Remove(photo);
            await db.SaveChangesAsync(cancellationToken);
            await storage.DeleteAsync(photo.StoredName, cancellationToken);
            await audit.RecordSystemAsync("purge", EntityType, photo.StayId, new { photo.SizeBytes, photo.MimeType }, null, cancellationToken);
        }

        return expired.Count;
    }
}
