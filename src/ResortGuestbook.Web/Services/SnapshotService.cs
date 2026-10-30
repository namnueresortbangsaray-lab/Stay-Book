using ResortGuestbook.Data.Entities;
using ResortGuestbook.Web.Infrastructure.Http;
using ResortGuestbook.Web.Models.Dtos;
using ResortGuestbook.Web.Services.Errors;

namespace ResortGuestbook.Web.Services;

/// <summary><c>GET /api/v1/snapshot</c>: everything the dashboard needs plus analytics for a date range.</summary>
public sealed class SnapshotService(ResortQueries queries, AppClock clock)
{
    public const int MaxRangeDays = 366;

    public async Task<SnapshotDto> GetAsync(string? start, string? end, CancellationToken cancellationToken)
    {
        var (from, to) = ResolveRange(start, end);
        var rooms = await queries.RoomsAsync(cancellationToken);
        var stays = await queries.StaysAsync(cancellationToken);
        var guests = await queries.GuestSummariesAsync(cancellationToken);
        var attachments = await queries.AttachmentsAsync(cancellationToken);
        return new SnapshotDto(rooms, stays, guests, attachments, Analytics(rooms.Count, stays, from, to), clock.Today);
    }

    /// <summary>Defaults to the current month (Bangkok) and validates like v1 <c>validateRange</c>.</summary>
    public (DateOnly Start, DateOnly End) ResolveRange(string? start, string? end)
    {
        var today = clock.Today;
        start = string.IsNullOrEmpty(start) ? new DateOnly(today.Year, today.Month, 1).ToString("yyyy-MM-dd", System.Globalization.CultureInfo.InvariantCulture) : start;
        end = string.IsNullOrEmpty(end) ? new DateOnly(today.Year, today.Month, DateTime.DaysInMonth(today.Year, today.Month)).ToString("yyyy-MM-dd", System.Globalization.CultureInfo.InvariantCulture) : end;
        if (!Coerce.TryParseDate(start, out var from))
        {
            throw new ValidationException("start", "วันที่เริ่มต้นไม่ถูกต้อง");
        }

        if (!Coerce.TryParseDate(end, out var to))
        {
            throw new ValidationException("end", "วันที่สิ้นสุดไม่ถูกต้อง");
        }

        if (to < from)
        {
            throw new ValidationException("end", "วันที่สิ้นสุดต้องไม่น้อยกว่าวันที่เริ่มต้น");
        }

        if (to.DayNumber - from.DayNumber > MaxRangeDays)
        {
            throw new ValidationException("end", "ช่วงรายงานต้องไม่เกิน 366 วัน");
        }

        return (from, to);
    }

    public static AnalyticsDto Analytics(int totalRooms, IReadOnlyList<StayDto> stays, DateOnly start, DateOnly end)
    {
        var days = Math.Max(1, end.DayNumber - start.DayNumber + 1);
        var started = stays.Where(s => s.CheckInDate >= start && s.CheckInDate <= end).ToList();
        var daily = new List<DailyPoint>();
        long occupiedNights = 0;
        for (var d = start; d <= end; d = d.AddDays(1))
        {
            var present = stays.Count(s => s.CheckInDate <= d && s.CheckOutDate > d);
            var revenue = stays.Where(s => s.CheckInDate == d && s.Status != StayStatus.Booked).Sum(s => s.TotalAmountSatang);
            daily.Add(new DailyPoint(d, present, revenue));
            occupiedNights += present;
        }

        var billable = started.Where(s => s.Status != StayStatus.Booked).ToList();
        var rated = started.Where(s => s.FeedbackRating is not null).ToList();
        return new AnalyticsDto(
            start,
            end,
            days,
            totalRooms,
            started.Count,
            started.Count(s => s.Status >= StayStatus.CheckedIn),
            started.Count(s => s.Status == StayStatus.CheckedOut),
            started.Sum(s => (long)s.Guests),
            occupiedNights,
            totalRooms > 0 ? occupiedNights / (double)(totalRooms * days) : 0,
            billable.Sum(s => s.TotalAmountSatang + s.DiscountAmountSatang),
            billable.Sum(s => s.DiscountAmountSatang),
            billable.Sum(s => s.TotalAmountSatang),
            started.Where(s => s.DepositPaid).Sum(s => s.DepositAmountSatang),
            started.Where(s => !s.DepositPaid).Sum(s => s.DepositAmountSatang),
            started.Count(s => s.PetCount > 0),
            rated.Count > 0 ? rated.Sum(s => s.FeedbackRating!.Value) / (double)rated.Count : 0,
            new StatusCounts(
                started.Count(s => s.Status == StayStatus.Booked),
                started.Count(s => s.Status == StayStatus.CheckedIn),
                started.Count(s => s.Status == StayStatus.CheckedOut)),
            new DepositCounts(
                started.Count(s => s.DepositAmountSatang == 0),
                started.Count(s => s.DepositAmountSatang != 0 && s.DepositPaid),
                started.Count(s => s.DepositAmountSatang != 0 && !s.DepositPaid)),
            daily);
    }
}
