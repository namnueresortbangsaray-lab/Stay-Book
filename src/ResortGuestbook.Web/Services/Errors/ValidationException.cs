namespace ResortGuestbook.Web.Services.Errors;

/// <summary>Rendered as HTTP 422 with message <c>ข้อมูลไม่ถูกต้อง</c> and the field errors (one message per field).</summary>
public sealed class ValidationException : Exception
{
    public const string DefaultMessage = "ข้อมูลไม่ถูกต้อง";

    public ValidationException(IReadOnlyDictionary<string, string> errors)
        : base(DefaultMessage) => Errors = errors;

    public ValidationException(string field, string message)
        : this(new Dictionary<string, string> { [field] = message })
    {
    }

    public ValidationException()
        : this(new Dictionary<string, string>())
    {
    }

    public ValidationException(string message)
        : base(message) => Errors = new Dictionary<string, string>();

    public ValidationException(string message, Exception innerException)
        : base(message, innerException) => Errors = new Dictionary<string, string>();

    public IReadOnlyDictionary<string, string> Errors { get; }
}
