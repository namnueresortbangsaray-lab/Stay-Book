namespace ResortGuestbook.Web.Services.Validation;

public sealed record RoomTypeInput(
    string Name,
    long PriceSatang,
    int BaseGuests,
    int MaxGuests,
    long ExtraGuestFeeSatang,
    bool IsPetFriendly,
    int SortOrder);
