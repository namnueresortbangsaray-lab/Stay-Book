using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.ModelBinding;
using Microsoft.AspNetCore.Mvc.ViewFeatures;
using ResortGuestbook.Web.Models;

namespace ResortGuestbook.Web.Infrastructure.Http;

/// <summary>The HTML error page (PHP <c>errors/error</c> in the base layout) with a given status code.</summary>
public static class ErrorPages
{
    public const string NotFound = "ไม่พบหน้าที่ต้องการ";
    public const string ServerError = "ระบบขัดข้อง กรุณาลองใหม่";

    public static ViewResult View(int status, string message) => new()
    {
        ViewName = "~/Views/Shared/Error.cshtml",
        StatusCode = status,
        ViewData = new ViewDataDictionary<ErrorViewModel>(new EmptyModelMetadataProvider(), new ModelStateDictionary())
        {
            Model = new ErrorViewModel(status, message),
        },
    };

    /// <summary>Message for a bare status code, as PHP produced or as the closest Thai equivalent.</summary>
    public static (int Status, string Message) Describe(int status) => status switch
    {
        StatusCodes.Status404NotFound or StatusCodes.Status405MethodNotAllowed => (StatusCodes.Status404NotFound, NotFound),
        StatusCodes.Status403Forbidden => (status, "ไม่มีสิทธิ์ดำเนินการ"),
        StatusCodes.Status413PayloadTooLarge => (status, "ไฟล์มีขนาดไม่ถูกต้องหรือใหญ่เกินกำหนด"),
        StatusCodes.Status419AuthenticationTimeout => (status, AntiforgeryFailureFilter.Message),
        StatusCodes.Status429TooManyRequests => (status, "คำขอมากเกินไป กรุณาลองใหม่ภายหลัง"),
        >= 400 and < 500 => (status, "คำขอไม่ถูกต้อง"),
        _ => (StatusCodes.Status500InternalServerError, ServerError),
    };
}
