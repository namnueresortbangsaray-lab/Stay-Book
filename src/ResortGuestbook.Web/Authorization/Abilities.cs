using ResortGuestbook.Data.Entities;

namespace ResortGuestbook.Web.Authorization;

/// <summary>Abilities from the PHP <c>ResortPolicy</c>; each one is also an authorization policy name.</summary>
public static class Abilities
{
    public const string View = "view";
    public const string ManageRooms = "manage_rooms";
    public const string EditGuest = "edit_guest";
    public const string Booking = "booking";
    public const string Checkout = "checkout";
    public const string Upload = "upload";
    public const string ManageUsers = "manage_users";

    public static readonly IReadOnlyList<string> All = [View, ManageRooms, EditGuest, Booking, Checkout, Upload, ManageUsers];

    /// <summary>admin: everything; front_desk: everything but manage_users; housekeeping: view, checkout, upload.</summary>
    public static bool Allows(string? role, string ability) => role switch
    {
        Roles.Admin => true,
        Roles.FrontDesk => ability != ManageUsers,
        Roles.Housekeeping => ability is View or Checkout or Upload,
        _ => false,
    };
}
