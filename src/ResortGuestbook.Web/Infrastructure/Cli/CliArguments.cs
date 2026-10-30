namespace ResortGuestbook.Web.Infrastructure.Cli;

/// <summary><c>--key=value</c> options and <c>--flag</c> switches (PHP <c>bin/console</c> syntax).</summary>
public sealed class CliArguments
{
    private readonly Dictionary<string, string> options = new(StringComparer.Ordinal);
    private readonly HashSet<string> flags = new(StringComparer.Ordinal);

    public CliArguments(IEnumerable<string> arguments)
    {
        foreach (var argument in arguments)
        {
            if (!argument.StartsWith("--", StringComparison.Ordinal))
            {
                continue;
            }

            var separator = argument.IndexOf('=', StringComparison.Ordinal);
            if (separator > 2)
            {
                options[argument[2..separator]] = argument[(separator + 1)..];
            }
            else
            {
                flags.Add(argument[2..]);
            }
        }
    }

    public string? Option(string name) => options.GetValueOrDefault(name);

    public bool Flag(string name) => flags.Contains(name);
}
