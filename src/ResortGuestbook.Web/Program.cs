using ResortGuestbook.Web.Infrastructure.Cli;
using ResortGuestbook.Web.Infrastructure.Extensions;

var cli = CliRunner.IsCommand(args);

// CLI commands read appsettings.json next to the binaries whatever the working directory is.
var builder = WebApplication.CreateBuilder(new WebApplicationOptions { Args = args, ContentRootPath = cli ? AppContext.BaseDirectory : null });
builder.AddStayBook();

if (cli)
{
    await using var host = builder.Build();
    return await CliRunner.RunAsync(host.Services, args, Console.Out, Console.Error, CancellationToken.None);
}

var app = builder.Build();
app.UseStayBook();
await app.InitializeDatabaseAsync();
await app.RunAsync();
return 0;

/// <summary>Entry point; public so integration tests can use <c>WebApplicationFactory&lt;Program&gt;</c>.</summary>
public partial class Program;
