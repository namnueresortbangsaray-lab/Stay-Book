namespace ResortGuestbook.Web.Models.Dtos;

public sealed record AnalyticsDto(
    DateOnly Start,
    DateOnly End,
    int DayCount,
    int TotalRooms,
    int BookingCount,
    int CheckInCount,
    int CheckOutCount,
    long GuestCount,
    long OccupiedRoomNights,
    double OccupancyRate,
    long GrossRevenueSatang,
    long DiscountSatang,
    long NetRevenueSatang,
    long DepositReceivedSatang,
    long DepositPendingSatang,
    int PetBookings,
    double AverageFeedback,
    StatusCounts Statuses,
    DepositCounts Deposits,
    IReadOnlyList<DailyPoint> Daily);
