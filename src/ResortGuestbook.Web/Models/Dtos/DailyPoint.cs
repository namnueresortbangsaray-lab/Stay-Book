namespace ResortGuestbook.Web.Models.Dtos;

public sealed record DailyPoint(DateOnly Date, int Occupied, long RevenueSatang);
