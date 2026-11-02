namespace ResortGuestbook.Data.Entities;

/// <summary>Values stored in <c>stays.booking_channel</c> (null = not recorded, e.g. bookings from before the field existed).</summary>
public static class BookingChannels
{
    public const string WalkIn = "walk_in";
    public const string Phone = "phone";
    public const string Line = "line";
    public const string Facebook = "facebook";
    public const string Agoda = "agoda";
    public const string BookingCom = "booking_com";
    public const string Other = "other";

    /// <summary>In the order the booking form and reports list them.</summary>
    public static readonly IReadOnlyList<string> All = [WalkIn, Phone, Line, Facebook, Agoda, BookingCom, Other];
}
