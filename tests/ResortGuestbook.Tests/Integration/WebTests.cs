using System.Net;
using System.Net.Http.Headers;
using Microsoft.EntityFrameworkCore;
using ResortGuestbook.Data.Entities;
using ResortGuestbook.Web.Infrastructure.Identity;

namespace ResortGuestbook.Tests.Integration;

[Collection(WebCollection.Name)]
public sealed class WebTests : IClassFixture<StayBookFactory>
{
    private readonly StayBookFactory app;

    public WebTests(StayBookFactory app) => this.app = app;

    [Fact]
    public async Task LoginPageAnswersGetAndHeadInThai()
    {
        using var client = app.CreateBrowser();
        var get = await client.GetAsync("/login");
        Assert.Equal(HttpStatusCode.OK, get.StatusCode);
        Assert.Contains("<title>เข้าสู่ระบบ · Stay Book · น้ำเหนือรีสอร์ท</title>", await get.Content.ReadAsStringAsync(), StringComparison.Ordinal);
        Assert.Equal(HttpStatusCode.OK, (await client.SendAsync(new HttpRequestMessage(HttpMethod.Head, "/login"))).StatusCode);
    }

    [Fact]
    public async Task SecurityHeadersAreSet()
    {
        using var client = app.CreateBrowser();
        var response = await client.GetAsync("/login");
        Assert.Equal("DENY", response.Headers.GetValues("X-Frame-Options").Single());
        Assert.Equal("nosniff", response.Headers.GetValues("X-Content-Type-Options").Single());
        Assert.Equal("strict-origin-when-cross-origin", response.Headers.GetValues("Referrer-Policy").Single());
        var csp = response.Headers.GetValues("Content-Security-Policy").Single();
        Assert.Contains("script-src 'self' 'nonce-", csp, StringComparison.Ordinal);
        Assert.Contains("frame-ancestors 'none'", csp, StringComparison.Ordinal);
    }

    [Fact]
    public async Task AnonymousUsersAreRedirectedOrGet401Json()
    {
        using var client = app.CreateBrowser();
        var page = await client.GetAsync("/");
        Assert.Equal(HttpStatusCode.Redirect, page.StatusCode);
        Assert.Equal("/login", page.Headers.Location?.OriginalString);

        var api = await client.GetAsync("/api/v1/snapshot");
        Assert.Equal(HttpStatusCode.Unauthorized, api.StatusCode);
        var body = await Browser.EnvelopeAsync(api);
        Assert.False(body.GetProperty("success").GetBoolean());
        Assert.Equal("กรุณาเข้าสู่ระบบ", body.GetProperty("message").GetString());
    }

    [Fact]
    public async Task UnknownPathsAre404ForEveryone()
    {
        using var client = app.CreateBrowser();
        var html = await client.GetAsync("/does-not-exist.html");
        Assert.Equal(HttpStatusCode.NotFound, html.StatusCode);
        Assert.Contains("ไม่พบหน้าที่ต้องการ", await html.Content.ReadAsStringAsync(), StringComparison.Ordinal);

        var api = await client.GetAsync("/api/v1/nope");
        Assert.Equal(HttpStatusCode.NotFound, api.StatusCode);
        Assert.Equal("ไม่พบหน้าที่ต้องการ", (await Browser.EnvelopeAsync(api)).GetProperty("message").GetString());
    }

    [Fact]
    public async Task PostWithoutCsrfTokenIs419()
    {
        using var client = app.CreateBrowser();
        var login = await Browser.PostLoginAsync(client, StayBookFactory.AdminEmail, StayBookFactory.AdminPassword, withToken: false);
        Assert.Equal((HttpStatusCode)419, login.StatusCode);

        await Browser.SignInAsync(client, StayBookFactory.AdminEmail, StayBookFactory.AdminPassword);
        var api = await Browser.SendJsonAsync(client, HttpMethod.Post, "/api/v1/rooms", new { }, token: null);
        Assert.Equal((HttpStatusCode)419, api.StatusCode);
        Assert.Equal("เซสชันหมดอายุ กรุณาลองใหม่", (await Browser.EnvelopeAsync(api)).GetProperty("message").GetString());
    }

    [Fact]
    public async Task WrongPasswordShowsErrorOnLoginPage()
    {
        using var client = app.CreateBrowser();
        var response = await Browser.PostLoginAsync(client, "nobody@staybook.local", "wrong");
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        Assert.Contains("อีเมลหรือรหัสผ่านไม่ถูกต้อง", await response.Content.ReadAsStringAsync(), StringComparison.Ordinal);
    }

    [Fact]
    public async Task HousekeepingCanCheckOutButNotBook()
    {
        await app.AddUserAsync("keeper@staybook.local", Roles.Housekeeping, "Housekeeping123!");
        using var client = app.CreateBrowser();
        var token = await Browser.SignInAsync(client, "keeper@staybook.local", "Housekeeping123!");

        var forbidden = await Browser.SendJsonAsync(client, HttpMethod.Post, "/api/v1/stays", new { }, token);
        Assert.Equal(HttpStatusCode.Forbidden, forbidden.StatusCode);
        Assert.Equal("ไม่มีสิทธิ์ดำเนินการ", (await Browser.EnvelopeAsync(forbidden)).GetProperty("message").GetString());

        var allowed = await Browser.SendJsonAsync(client, HttpMethod.Post, $"/api/v1/stays/{Guid.NewGuid()}/checkout", new { no_damage = true }, token);
        Assert.Equal(HttpStatusCode.NotFound, allowed.StatusCode);
        Assert.Equal(HttpStatusCode.OK, (await client.GetAsync("/api/v1/snapshot")).StatusCode);
    }

    [Fact]
    public async Task RoomCategoriesAreReadableByStaffAndManagedOnlyWithRoomAbility()
    {
        await app.AddUserAsync("keeper-categories@staybook.local", Roles.Housekeeping, "Housekeeping123!");
        using var keeper = app.CreateBrowser();
        var keeperToken = await Browser.SignInAsync(keeper, "keeper-categories@staybook.local", "Housekeeping123!");

        var list = await keeper.GetAsync("/api/v1/room-categories");
        Assert.Equal(HttpStatusCode.OK, list.StatusCode);
        var data = (await Browser.EnvelopeAsync(list)).GetProperty("data");
        Assert.Equal("อาคารหลัก", data.GetProperty("zones")[0].GetProperty("name").GetString());
        Assert.Equal(50_000, data.GetProperty("types")[0].GetProperty("price_satang").GetInt64());

        var forbidden = await Browser.SendJsonAsync(keeper, HttpMethod.Post, "/api/v1/room-zones", new { name = "ริมสระ" }, keeperToken);
        Assert.Equal(HttpStatusCode.Forbidden, forbidden.StatusCode);

        using var admin = app.CreateBrowser();
        var adminToken = await Browser.SignInAsync(admin, StayBookFactory.AdminEmail, StayBookFactory.AdminPassword);
        var invalid = await Browser.SendJsonAsync(admin, HttpMethod.Post, "/api/v1/room-types", new { name = "", price = 0 }, adminToken);
        Assert.Equal(HttpStatusCode.UnprocessableEntity, invalid.StatusCode);
        Assert.Equal("กรุณากรอกชื่อประเภทห้อง", (await Browser.EnvelopeAsync(invalid)).GetProperty("errors").GetProperty("name").GetString());
    }

    [Fact]
    public async Task LegacyBcryptPasswordStillWorksAndIsUpgraded()
    {
        var legacyHash = BCrypt.Net.BCrypt.HashPassword("LegacyPassword123!", 10).Replace("$2a$", "$2y$", StringComparison.Ordinal);
        var user = await app.AddUserAsync("legacy-user@staybook.local", Roles.FrontDesk, passwordHash: legacyHash);
        using var client = app.CreateBrowser();
        await Browser.SignInAsync(client, "legacy-user@staybook.local", "LegacyPassword123!");
        var stored = await app.QueryAsync(db => db.Users.Where(u => u.Id == user.Id).Select(u => u.PasswordHash).SingleAsync());
        Assert.False(LegacyBcryptPasswordHasher.IsBcrypt(stored));

        using var again = app.CreateBrowser();
        await Browser.SignInAsync(again, "legacy-user@staybook.local", "LegacyPassword123!");
    }

    [Fact]
    public async Task UploadIsSniffedStoredPrivatelyAndDownloadedAfterAuthorization()
    {
        using var client = app.CreateBrowser();
        var token = await Browser.SignInAsync(client, StayBookFactory.AdminEmail, StayBookFactory.AdminPassword);
        var roomId = await app.QueryAsync(db => db.Rooms.OrderBy(r => r.SortOrder).Select(r => r.Id).FirstAsync());
        var created = await Browser.SendJsonAsync(client, HttpMethod.Post, "/api/v1/stays", new
        {
            guest_name = "ทดสอบ อัปโหลด",
            phone = "0811111111",
            room_id = roomId,
            check_in_date = "2031-03-01",
            check_out_date = "2031-03-02",
            guests = 1,
        }, token);
        Assert.Equal(HttpStatusCode.OK, created.StatusCode);
        var stayId = (await Browser.EnvelopeAsync(created)).GetProperty("data").GetProperty("id").GetString();

        var bytes = await File.ReadAllBytesAsync(Path.Combine(AppContext.BaseDirectory, "Baseline", "fixtures", "logo_square.webp"));
        using var image = new MultipartFormDataContent { { new ByteArrayContent(bytes) { Headers = { ContentType = new MediaTypeHeaderValue("image/png") } }, "file", "รูป บัตร.webp" } };
        using var upload = new HttpRequestMessage(HttpMethod.Post, $"/api/v1/stays/{stayId}/attachments") { Content = image };
        upload.Headers.Add("X-CSRF-Token", token);
        var uploaded = await client.SendAsync(upload);
        Assert.Equal(HttpStatusCode.OK, uploaded.StatusCode);
        var data = (await Browser.EnvelopeAsync(uploaded)).GetProperty("data");
        Assert.Equal("image/webp", data.GetProperty("mime_type").GetString());
        var storedName = data.GetProperty("stored_name").GetString()!;
        Assert.Matches("^[0-9a-f]{48}\\.webp$", storedName);
        Assert.True(File.Exists(Path.Combine(app.Root, "uploads", storedName)));

        var download = await client.GetAsync($"/files/{data.GetProperty("id").GetString()}");
        Assert.Equal(HttpStatusCode.OK, download.StatusCode);
        Assert.Equal("image/webp", download.Content.Headers.ContentType?.MediaType);
        Assert.Equal(bytes, await download.Content.ReadAsByteArrayAsync());
        Assert.Equal("nosniff", download.Headers.GetValues("X-Content-Type-Options").Single());

        using var anonymous = app.CreateBrowser();
        Assert.Equal(HttpStatusCode.Redirect, (await anonymous.GetAsync($"/files/{data.GetProperty("id").GetString()}")).StatusCode);
        Assert.Equal(HttpStatusCode.NotFound, (await anonymous.GetAsync($"/uploads/{storedName}")).StatusCode);

        using var text = new MultipartFormDataContent { { new StringContent("not an image"), "file", "fake.png" } };
        using var bad = new HttpRequestMessage(HttpMethod.Post, $"/api/v1/stays/{stayId}/attachments") { Content = text };
        bad.Headers.Add("X-CSRF-Token", token);
        var rejected = await client.SendAsync(bad);
        Assert.Equal(HttpStatusCode.UnprocessableEntity, rejected.StatusCode);
        Assert.Equal("ประเภทไฟล์ไม่ได้รับอนุญาต", (await Browser.EnvelopeAsync(rejected)).GetProperty("errors").GetProperty("file").GetString());
    }

    [Fact]
    public async Task CsvExportHasBomAndThaiHeader()
    {
        using var client = app.CreateBrowser();
        await Browser.SignInAsync(client, StayBookFactory.AdminEmail, StayBookFactory.AdminPassword);
        var response = await client.GetAsync("/api/v1/reports/bookings.csv");
        Assert.Equal("text/csv", response.Content.Headers.ContentType?.MediaType);
        var bytes = await response.Content.ReadAsByteArrayAsync();
        Assert.Equal([0xEF, 0xBB, 0xBF], bytes[..3]);
        Assert.StartsWith("\"Booking ID\",ชื่อลูกค้า", System.Text.Encoding.UTF8.GetString(bytes[3..]), StringComparison.Ordinal);
    }

    [Fact]
    public async Task LogoutEndsTheSession()
    {
        using var client = app.CreateBrowser();
        var token = await Browser.SignInAsync(client, StayBookFactory.AdminEmail, StayBookFactory.AdminPassword);
        var logout = await client.PostAsync("/logout", new FormUrlEncodedContent(new Dictionary<string, string> { ["_token"] = token }));
        Assert.Equal("/login", logout.Headers.Location?.OriginalString);
        Assert.Equal(HttpStatusCode.Unauthorized, (await client.GetAsync("/api/v1/snapshot")).StatusCode);
    }

    [Fact]
    public async Task HealthReportsOk()
    {
        using var client = app.CreateBrowser();
        Assert.Equal("ok\n", await client.GetStringAsync("/health"));
    }
}
