namespace ResortGuestbook.Web.Infrastructure.Cli;

/// <summary>A maintenance command run with <c>dotnet ResortGuestbook.Web.dll &lt;name&gt; [--options]</c>.</summary>
public interface ICliCommand
{
    string Name { get; }

    string Usage { get; }

    Task<int> RunAsync(CliArguments arguments, TextWriter output, TextWriter error, CancellationToken cancellationToken);
}
