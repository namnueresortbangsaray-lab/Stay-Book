namespace ResortGuestbook.Web.Infrastructure.Cli;

/// <summary>Dispatches CLI commands before the web host starts.</summary>
public static class CliRunner
{
    private static readonly HashSet<string> Names = new(StringComparer.Ordinal)
    {
        "help", "migrate", "seed", "user:create", "db:backup", "db:transfer", "import:php",
    };

    public static bool IsCommand(string[] args) => args.Length > 0 && Names.Contains(args[0]);

    public static async Task<int> RunAsync(IServiceProvider services, string[] args, TextWriter output, TextWriter error, CancellationToken cancellationToken)
    {
        await using var scope = services.CreateAsyncScope();
        var commands = scope.ServiceProvider.GetServices<ICliCommand>().ToList();
        var command = commands.Find(c => c.Name == args[0]);
        if (command is null)
        {
            await output.WriteLineAsync("Stay Book CLI");
            foreach (var c in commands)
            {
                await output.WriteLineAsync($"  {c.Usage}");
            }

            return 0;
        }

        return await command.RunAsync(new CliArguments(args.Skip(1)), output, error, cancellationToken);
    }
}
