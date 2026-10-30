using Microsoft.EntityFrameworkCore;
using ResortGuestbook.Data.Entities;
using ResortGuestbook.Data.Providers;
using ResortGuestbook.Web.Services.Errors;

namespace ResortGuestbook.Tests.Data;

/// <summary>
/// Business rules and queries run against a real database, once per provider (ported from the PHP
/// <c>ResortServiceTest</c>, <c>SqliteRepositoryTest</c> and <c>MigrationParityTest</c>).
/// </summary>
public abstract class ResortDataTests(IDatabaseFactory factory)
{
    [Fact]
    public async Task MigrationsMatchTheModel()
    {
        await using var s = await TestServices.CreateAsync(factory);
        Assert.False(s.Db.Database.HasPendingModelChanges());
        Assert.Empty(await s.Db.Database.GetPendingMigrationsAsync());
    }

    [Fact]
    public async Task SeedCreatesAdminRoomsAndNoOverlap()
    {
        await using var s = await TestServices.CreateAsync(factory);
        var rooms = await s.Queries.RoomsAsync();
        Assert.Equal(["1", "2", "3", "4", "5"], rooms.Select(r => r.Name));
        Assert.Equal(Roles.Admin, s.Admin.Role);
        Assert.False(await s.Stays.HasOverlapAsync(rooms[0].Id, new DateOnly(2026, 1, 1), new DateOnly(2026, 1, 2), null, default));
    }

    [Fact]
    public async Task CompletedStayCannotBeCreatedWithoutCheckoutWorkflow()
    {
        await using var s = await TestServices.CreateAsync(factory);
        var room = (await s.Queries.RoomsAsync())[0];
        await Assert.ThrowsAsync<ValidationException>(() => s.Stays.SaveAsync(TestInputs.Stay(room.Id, ("status", 2L)), null, s.Admin, default));
    }

    [Fact]
    public async Task OverlappingStayIsRejectedButSameDayTurnoverIsAllowed()
    {
        await using var s = await TestServices.CreateAsync(factory);
        var room = (await s.Queries.RoomsAsync())[0];
        await s.Stays.SaveAsync(TestInputs.Stay(room.Id), null, s.Admin, default);

        var turnover = await s.Stays.SaveAsync(
            TestInputs.Stay(room.Id, ("guest_name", "ลูกค้า ถัดไป"), ("phone", "0899999999"), ("check_in_date", "2030-01-12"), ("check_out_date", "2030-01-13")),
            null, s.Admin, default);
        Assert.Equal(new DateOnly(2030, 1, 12), turnover.CheckInDate);

        var overlap = await Assert.ThrowsAsync<ValidationException>(() => s.Stays.SaveAsync(
            TestInputs.Stay(room.Id, ("guest_name", "ลูกค้า ชนกัน"), ("phone", "0877777777"), ("check_in_date", "2030-01-11"), ("check_out_date", "2030-01-13")),
            null, s.Admin, default));
        Assert.Equal("ห้องนี้มี Booking ทับซ้อนในช่วงวันที่เลือก", overlap.Errors["room_id"]);
    }

    [Fact]
    public async Task BookingCompletesCreateCheckInCheckoutFeedbackLifecycle()
    {
        await using var s = await TestServices.CreateAsync(factory);
        var room = (await s.Queries.RoomsAsync())[0];
        var created = await s.Stays.SaveAsync(TestInputs.Stay(room.Id, ("id_verified", true)), null, s.Admin, default);
        Assert.Equal(StayStatus.Booked, created.Status);
        Assert.Equal(100_000, created.PriceBreakdown.RoomTotalSatang);

        var checkedIn = await s.Stays.CheckInAsync(created.Id.ToString(), s.Admin, default);
        Assert.Equal(StayStatus.CheckedIn, checkedIn.Status);
        Assert.Equal(1, (await s.Queries.RoomAsync(room.Id))!.Status);

        var checkedOut = await s.Stays.CheckoutAsync(created.Id.ToString(), TestInputs.Input(("key_returned", true), ("room_clean", true), ("equipment_complete", true), ("no_damage", true), ("minibar_checked", true)), s.Admin, default);
        Assert.Equal(StayStatus.CheckedOut, checkedOut.Status);
        Assert.Equal(0, (await s.Queries.RoomAsync(room.Id))!.Status);

        var feedback = await s.Stays.FeedbackAsync(created.Id.ToString(), TestInputs.Input(("cleanliness_rating", 5L), ("service_rating", "4"), ("facility_rating", 3L), ("overall_rating", 5L)), s.Admin, default);
        Assert.True(feedback.WouldReturn);
        Assert.Equal(5, (await s.Queries.StayAsync(created.Id))!.FeedbackRating);

        var guest = (await s.Queries.GuestSummariesAsync()).Single();
        Assert.Equal(1, guest.CompletedStays);
        Assert.Equal(2, guest.TotalNights);

        var actions = await s.Db.AuditLogs.Select(a => a.Action).ToListAsync();
        Assert.Equal(["check_in", "check_out", "create", "feedback"], actions.Order(StringComparer.Ordinal));
    }

    [Fact]
    public async Task CheckoutWithDamageRequiresNote()
    {
        await using var s = await TestServices.CreateAsync(factory);
        var room = (await s.Queries.RoomsAsync())[0];
        var created = await s.Stays.SaveAsync(TestInputs.Stay(room.Id, ("id_verified", true), ("status", 1L)), null, s.Admin, default);
        var error = await Assert.ThrowsAsync<ValidationException>(() => s.Stays.CheckoutAsync(created.Id.ToString(), TestInputs.Input(("no_damage", false)), s.Admin, default));
        Assert.True(error.Errors.ContainsKey("inspection_note"));
    }

    [Fact]
    public async Task PendingBookingCanBeCancelled()
    {
        await using var s = await TestServices.CreateAsync(factory);
        var room = (await s.Queries.RoomsAsync())[0];
        var created = await s.Stays.SaveAsync(TestInputs.Stay(room.Id), null, s.Admin, default);
        Assert.NotNull(await s.Queries.StayAsync(created.Id));
        await s.Stays.DeleteAsync(created.Id.ToString(), s.Admin, default);
        Assert.Null(await s.Queries.StayAsync(created.Id));
        await Assert.ThrowsAsync<NotFoundException>(() => s.Stays.DeleteAsync(created.Id.ToString(), s.Admin, default));
    }

    [Fact]
    public async Task SearchIsCaseInsensitiveAndMatchesThai()
    {
        await using var s = await TestServices.CreateAsync(factory);
        var room = (await s.Queries.RoomsAsync())[0];
        await s.Stays.SaveAsync(TestInputs.Stay(room.Id, ("guest_name", "ทดสอบ Baseline"), ("note", "Baseline NOTE")), null, s.Admin, default);

        Assert.Single(await s.Queries.SearchStaysAsync("baseline note", 0));
        Assert.Single(await s.Queries.SearchStaysAsync("ทดสอบ", null));
        Assert.Single(await s.Queries.SearchStaysAsync("อาคารหลัก", null));
        Assert.Empty(await s.Queries.SearchStaysAsync("ทดสอบ", 1));
        Assert.Empty(await s.Queries.SearchStaysAsync("ไม่มี", null));
    }

    [Fact]
    public async Task DuplicateRoomNameIsReportedAsDuplicate()
    {
        await using var s = await TestServices.CreateAsync(factory);
        var exception = await Assert.ThrowsAsync<DbUpdateException>(() => s.Rooms.SaveAsync(
            TestInputs.Input(("name", "1"), ("zone", "Z"), ("type", "T"), ("price", 100L), ("base_guests", 1L), ("max_guests", 1L)), null, s.Admin, default));
        Assert.True(DbErrors.IsDuplicate(exception));
    }

    [Fact]
    public async Task DeletingRoomRemovesItsStays()
    {
        await using var s = await TestServices.CreateAsync(factory);
        var room = (await s.Queries.RoomsAsync())[0];
        var stay = await s.Stays.SaveAsync(TestInputs.Stay(room.Id, ("id_verified", true), ("status", 1L)), null, s.Admin, default);
        await s.Stays.CheckoutAsync(stay.Id.ToString(), TestInputs.Input(("no_damage", true)), s.Admin, default);
        await s.Rooms.DeleteAsync(room.Id.ToString(), s.Admin, default);
        Assert.Null(await s.Queries.RoomAsync(room.Id));
        Assert.Empty(await s.Queries.StaysAsync());
        Assert.Equal(0, await s.Db.CheckoutInspections.CountAsync());
    }

    [Fact]
    public async Task GuestUpdateKeepsSummaryInAudit()
    {
        await using var s = await TestServices.CreateAsync(factory);
        var room = (await s.Queries.RoomsAsync())[0];
        var stay = await s.Stays.SaveAsync(TestInputs.Stay(room.Id), null, s.Admin, default);
        var guest = await s.Guests.UpdateAsync(TestInputs.Input(("name", "คุณ ทดสอบ"), ("phone", "081-234-5678"), ("customer_type", "VIP"), ("is_regular", true), ("customer_note", " แพ้อาหารทะเล ")), stay.GuestId!.Value.ToString(), s.Admin, default);
        Assert.Equal("แพ้อาหารทะเล", guest.CustomerNote);
        Assert.True(guest.IsRegular);
        var audit = await s.Db.AuditLogs.SingleAsync(a => a.EntityType == "guest");
        Assert.Contains("\"stays\":[", audit.BeforeJson, StringComparison.Ordinal);
        Assert.Contains("\"customer_type\":\"VIP\"", audit.AfterJson, StringComparison.Ordinal);
    }

    [Fact]
    public async Task SnapshotAnalyticsCountsBillableStays()
    {
        await using var s = await TestServices.CreateAsync(factory);
        var room = (await s.Queries.RoomsAsync())[0];
        await s.Stays.SaveAsync(TestInputs.Stay(room.Id, ("id_verified", true), ("status", 1L), ("deposit_amount", 300L), ("deposit_paid", true)), null, s.Admin, default);
        var snapshot = await s.Snapshots.GetAsync("2030-01-01", "2030-01-31", default);
        Assert.Equal(1, snapshot.Analytics.BookingCount);
        Assert.Equal(2, snapshot.Analytics.OccupiedRoomNights);
        Assert.Equal(30_000, snapshot.Analytics.DepositReceivedSatang);
        Assert.Equal(31, snapshot.Analytics.Daily.Count);
        await Assert.ThrowsAsync<ValidationException>(() => s.Snapshots.GetAsync("2030-01-01", "2031-02-01", default));
    }
}
