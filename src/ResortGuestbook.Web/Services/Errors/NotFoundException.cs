namespace ResortGuestbook.Web.Services.Errors;

/// <summary>Rendered as HTTP 404 with the exception message.</summary>
public sealed class NotFoundException : Exception
{
    public NotFoundException()
    {
    }

    public NotFoundException(string message)
        : base(message)
    {
    }

    public NotFoundException(string message, Exception innerException)
        : base(message, innerException)
    {
    }
}
