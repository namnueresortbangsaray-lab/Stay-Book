using Microsoft.EntityFrameworkCore;
using ResortGuestbook.Data;
using ResortGuestbook.Data.Entities;
using ResortGuestbook.Web.Infrastructure.Http;
using ResortGuestbook.Web.Models.Dtos;
using ResortGuestbook.Web.Services.Errors;

namespace ResortGuestbook.Web.Services;

public sealed class GuestService(AppDbContext db, ResortQueries queries, AuditService audit)
{
    /// <summary>Updates the permanent guest profile (<c>PUT /api/v1/guests/{id}</c>).</summary>
    public async Task<GuestDto> UpdateAsync(RequestInput input, string id, Actor actor, CancellationToken cancellationToken)
    {
        var name = Php.TrimStr(input["name"]);
        var phone = Php.TrimStr(input["phone"]);
        var normalized = Php.Digits(phone);
        var errors = new Dictionary<string, string>();
        if (Php.MbStrlen(name) < 2)
        {
            errors["name"] = "กรุณากรอกชื่ออย่างน้อย 2 ตัวอักษร";
        }

        if (normalized.Length < 9)
        {
            errors["phone"] = "เบอร์โทรต้องมีอย่างน้อย 9 หลัก";
        }

        if (errors.Count > 0)
        {
            throw new ValidationException(errors);
        }

        var key = Guid.TryParse(id, out var parsed) ? parsed : Guid.Empty;
        var before = await queries.GuestDetailAsync(key, cancellationToken);
        var guest = before is null ? null : await db.Guests.FirstOrDefaultAsync(g => g.Id == key, cancellationToken);
        if (guest is null)
        {
            throw new NotFoundException("ไม่พบลูกค้า");
        }

        guest.Name = name;
        guest.Phone = phone;
        guest.NormalizedPhone = normalized;
        guest.CustomerType = Php.TrimStr(input.Get("customer_type", Guest.DefaultCustomerType));
        guest.IsRegular = Php.ToBool(input.Get("is_regular", false));
        guest.CustomerNote = Php.Clean(input["customer_note"]);
        guest.Preferences = Php.Clean(input["preferences"]);
        await db.SaveChangesAsync(cancellationToken);

        var after = ResortQueries.ToDto(guest);
        await audit.RecordAsync("update", "guest", guest.Id, before, after, actor, cancellationToken);
        return after;
    }
}
