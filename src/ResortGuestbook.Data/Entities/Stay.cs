namespace ResortGuestbook.Data.Entities;

public sealed class Stay : ICreatedAt, IUpdatedAt, ISoftDeletable
{
    public Guid Id { get; set; }
    public Guid? GuestId { get; set; }
    public Guid RoomId { get; set; }
    public string GuestName { get; set; } = string.Empty;
    public string? Phone { get; set; }
    public DateOnly CheckInDate { get; set; }
    public DateOnly CheckOutDate { get; set; }
    public int Guests { get; set; }
    public bool ExtraBed { get; set; }
    public long TotalAmountSatang { get; set; }
    public int Status { get; set; }
    public string? Note { get; set; }
    public long DepositAmountSatang { get; set; }
    public bool DepositPaid { get; set; }
    public bool IdVerified { get; set; }
    public string? PetType { get; set; }
    public int PetCount { get; set; }
    public long PetFeeSatang { get; set; }
    public long DiscountAmountSatang { get; set; }
    public string? BookingChannel { get; set; }
    public DateTimeOffset CreatedAt { get; set; }
    public DateTimeOffset UpdatedAt { get; set; }
    public DateTimeOffset? DeletedAt { get; set; }

    public Room? Room { get; set; }
    public Guest? Guest { get; set; }
    public Feedback? Feedback { get; set; }
}
