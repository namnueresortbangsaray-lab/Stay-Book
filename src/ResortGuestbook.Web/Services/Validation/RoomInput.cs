namespace ResortGuestbook.Web.Services.Validation;

public sealed record RoomInput(
    string Name,
    string Zone,
    string Type,
    long PriceSatang,
    int BaseGuests,
    int MaxGuests,
    long ExtraGuestFeeSatang,
    int SortOrder,
    bool IsPetFriendly);
