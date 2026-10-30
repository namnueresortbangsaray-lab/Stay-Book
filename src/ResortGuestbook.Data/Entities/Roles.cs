namespace ResortGuestbook.Data.Entities;

/// <summary>Values allowed in <c>users.role</c>.</summary>
public static class Roles
{
    public const string Admin = "admin";
    public const string FrontDesk = "front_desk";
    public const string Housekeeping = "housekeeping";

    public static readonly IReadOnlyList<string> All = [Admin, FrontDesk, Housekeeping];
}
