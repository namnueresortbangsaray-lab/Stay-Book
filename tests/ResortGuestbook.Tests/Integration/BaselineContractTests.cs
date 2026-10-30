using System.Diagnostics;
using System.Net;
using System.Net.Sockets;
using ResortGuestbook.Data.Entities;

namespace ResortGuestbook.Tests.Integration;

/// <summary>
/// Replays the recorded v1 behaviour (<c>tests/baseline</c>) against the app on a real Kestrel port and fails on any
/// difference that is not listed in <c>tests/baseline/deviations.json</c>. Requires Node.js on the PATH.
/// </summary>
[Collection(WebCollection.Name)]
public sealed class BaselineContractTests : IDisposable
{
    private readonly StayBookFactory app = new();

    [Fact]
    public async Task ApiAndPagesMatchTheV1Baseline()
    {
        var port = FreePort();
        app.UseKestrel(port);
        app.StartServer();
        await app.AddUserAsync("housekeeping@staybook.local", Roles.Housekeeping, "Housekeeping123!");

        var baseline = Path.Combine(RepositoryRoot(), "tests", "baseline");
        var replay = Path.Combine(app.Root, "replay");
        var capture = await NodeAsync(baseline, "capture.mjs", [], new() { ["BASE_URL"] = $"http://localhost:{port}", ["BASELINE_OUT"] = replay });
        Assert.True(capture.ExitCode == 0, capture.Output);

        var compare = await NodeAsync(baseline, "compare.mjs", [replay], []);
        Assert.True(compare.ExitCode == 0, compare.Output);
    }

    public void Dispose() => app.Dispose();

    private static int FreePort()
    {
        using var listener = new TcpListener(IPAddress.Loopback, 0);
        listener.Start();
        return ((IPEndPoint)listener.LocalEndpoint).Port;
    }

    private static string RepositoryRoot()
    {
        var directory = new DirectoryInfo(AppContext.BaseDirectory);
        while (directory is not null && !File.Exists(Path.Combine(directory.FullName, "ResortGuestbook.sln")))
        {
            directory = directory.Parent;
        }

        return directory?.FullName ?? throw new InvalidOperationException("Repository root not found.");
    }

    private static async Task<(int ExitCode, string Output)> NodeAsync(string directory, string script, string[] arguments, Dictionary<string, string> environment)
    {
        var start = new ProcessStartInfo("node") { WorkingDirectory = directory, RedirectStandardOutput = true, RedirectStandardError = true };
        start.ArgumentList.Add(script);
        foreach (var argument in arguments)
        {
            start.ArgumentList.Add(argument);
        }

        foreach (var (key, value) in environment)
        {
            start.Environment[key] = value;
        }

        using var process = Process.Start(start) ?? throw new InvalidOperationException("node could not be started.");
        var output = process.StandardOutput.ReadToEndAsync();
        var error = process.StandardError.ReadToEndAsync();
        await process.WaitForExitAsync().WaitAsync(TimeSpan.FromMinutes(3));
        return (process.ExitCode, await output + await error);
    }
}
