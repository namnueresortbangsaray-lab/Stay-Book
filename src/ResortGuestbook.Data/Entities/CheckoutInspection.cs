namespace ResortGuestbook.Data.Entities;

public sealed class CheckoutInspection
{
    public Guid Id { get; set; }
    public Guid StayId { get; set; }
    public bool KeyReturned { get; set; }
    public bool RoomClean { get; set; }
    public bool EquipmentComplete { get; set; }
    public bool NoDamage { get; set; }
    public bool MinibarChecked { get; set; }
    public string? InspectionNote { get; set; }
    public Guid? InspectedBy { get; set; }
    public DateTimeOffset InspectedAt { get; set; }
}
