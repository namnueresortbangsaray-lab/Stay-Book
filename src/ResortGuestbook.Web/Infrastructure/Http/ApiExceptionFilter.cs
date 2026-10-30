using Microsoft.AspNetCore.Mvc.Filters;
using Microsoft.EntityFrameworkCore;
using ResortGuestbook.Data.Providers;
using ResortGuestbook.Web.Services.Errors;

namespace ResortGuestbook.Web.Infrastructure.Http;

/// <summary>
/// Maps service exceptions to envelopes like the v1 <c>mutate()</c> helper: 422 validation, 404 not found,
/// 409 duplicate, 500 otherwise (with the "cannot save" message for writes).
/// </summary>
public sealed class ApiExceptionFilter(ILogger<ApiExceptionFilter> logger) : IExceptionFilter
{
    public void OnException(ExceptionContext context)
    {
        context.Result = context.Exception switch
        {
            ValidationException validation => ApiResults.Error(StatusCodes.Status422UnprocessableEntity, validation.Message, validation.Errors),
            NotFoundException notFound => ApiResults.Error(StatusCodes.Status404NotFound, notFound.Message),
            BadHttpRequestException { StatusCode: StatusCodes.Status413PayloadTooLarge } =>
                ApiResults.Error(StatusCodes.Status413PayloadTooLarge, "ไฟล์มีขนาดไม่ถูกต้องหรือใหญ่เกินกำหนด"),
            DbUpdateException update when DbErrors.IsDuplicate(update) => Duplicate(update),
            _ => Unexpected(context),
        };
        context.ExceptionHandled = true;
    }

    private Microsoft.AspNetCore.Mvc.ObjectResult Duplicate(DbUpdateException exception)
    {
        logger.LogWarning(exception, "Duplicate data rejected");
        return ApiResults.Error(StatusCodes.Status409Conflict, "ข้อมูลนี้มีอยู่ในระบบแล้ว");
    }

    private Microsoft.AspNetCore.Mvc.ObjectResult Unexpected(ExceptionContext context)
    {
        logger.LogError(context.Exception, "Unhandled API error");
        var write = !HttpMethods.IsGet(context.HttpContext.Request.Method) && !HttpMethods.IsHead(context.HttpContext.Request.Method);
        return ApiResults.Error(StatusCodes.Status500InternalServerError, write ? "ระบบไม่สามารถบันทึกข้อมูลได้" : "ระบบขัดข้อง กรุณาลองใหม่");
    }
}
