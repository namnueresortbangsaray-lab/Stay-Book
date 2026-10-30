namespace ResortGuestbook.Web.Infrastructure.Http;

/// <summary>A JSON array/object value in request input; only its element count matters for v1 coercion.</summary>
public sealed record InputArray(int Count);
