using ResortGuestbook.Web.Infrastructure.Cli;
using ResortGuestbook.Web.Infrastructure.Extensions;

var builder = WebApplication.CreateBuilder(args);
builder.AddStayBook();

if (CliRunner.IsCommand(args))
{
    await using var cli = builder.Build();
    return await CliRunner.RunAsync(cli.Services, args, Console.Out, Console.Error, CancellationToken.None);
}

var app = builder.Build();
app.UseStayBook();
await app.InitializeDatabaseAsync();
await app.RunAsync();
return 0;

/// <summary>Entry point; public so integration tests can use <c>WebApplicationFactory&lt;Program&gt;</c>.</summary>
public partial class Program;
