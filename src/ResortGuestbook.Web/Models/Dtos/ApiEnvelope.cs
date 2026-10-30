namespace ResortGuestbook.Web.Models.Dtos;

/// <summary>The JSON envelope of every API response: <c>{success, data, message, errors}</c>.</summary>
public sealed record ApiEnvelope(bool Success, object? Data, string Message, IReadOnlyDictionary<string, string> Errors);
