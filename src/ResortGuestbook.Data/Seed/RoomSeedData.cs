using ResortGuestbook.Data.Entities;

namespace ResortGuestbook.Data.Seed;

/// <summary>The five rooms of the resort (from the PHP <c>database/seeders/rooms.php</c>).</summary>
public static class RoomSeedData
{
    public static IReadOnlyList<Room> Create() =>
    [
        Room("1", "อาคารหลัก", "เตียงคู่", 50_000, 2, 3, 1, false),
        Room("2", "อาคารหลัก", "เตียงคู่", 50_000, 2, 3, 2, false),
        Room("3", "อาคารหลัก", "เตียงคู่", 50_000, 2, 3, 3, true),
        Room("4", "โซน B", "เตียงเดี่ยว", 45_000, 2, 2, 4, true),
        Room("5", "โซน B", "เตียงคู่", 55_000, 2, 4, 5, true),
    ];

    private static Room Room(string name, string zone, string type, long price, int baseGuests, int maxGuests, int sortOrder, bool petFriendly) => new()
    {
        Id = Guid.NewGuid(),
        Name = name,
        Zone = zone,
        Type = type,
        PriceSatang = price,
        BaseGuests = baseGuests,
        MaxGuests = maxGuests,
        ExtraGuestFeeSatang = 10_000,
        SortOrder = sortOrder,
        IsPetFriendly = petFriendly,
    };
}
