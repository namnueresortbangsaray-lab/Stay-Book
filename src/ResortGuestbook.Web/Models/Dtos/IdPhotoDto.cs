namespace ResortGuestbook.Web.Models.Dtos;

/// <summary>Which booking has an ID card photo, and when it will be deleted (null until the guest has checked out).</summary>
public sealed record IdPhotoDto(Guid StayId, long SizeBytes, DateTimeOffset CreatedAt, DateOnly? DeleteAfter);
