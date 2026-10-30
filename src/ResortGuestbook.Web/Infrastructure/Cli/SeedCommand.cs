using Microsoft.Extensions.Options;
using ResortGuestbook.Data.Seed;
using ResortGuestbook.Web.Infrastructure.Options;

namespace ResortGuestbook.Web.Infrastructure.Cli;

public sealed class SeedCommand(DatabaseSeeder seeder, IOptions<SeedOptions> options) : ICliCommand
{
    public string Name => "seed";

    public string Usage => "seed";

    public async Task<int> RunAsync(CliArguments arguments, TextWriter output, TextWriter error, CancellationToken cancellationToken)
    {
        await seeder.SeedAsync(options.Value.AdminEmail, options.Value.AdminPassword, cancellationToken);
        await output.WriteLineAsync("Seed complete.");
        return 0;
    }
}
