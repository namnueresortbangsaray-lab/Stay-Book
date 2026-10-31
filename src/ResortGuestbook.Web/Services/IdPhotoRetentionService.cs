namespace ResortGuestbook.Web.Services;

/// <summary>Purges expired ID card photos at start-up and then once a day.</summary>
public sealed class IdPhotoRetentionService(IServiceScopeFactory scopes, ILogger<IdPhotoRetentionService> logger) : BackgroundService
{
    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        using var timer = new PeriodicTimer(TimeSpan.FromDays(1));
        do
        {
            try
            {
                await using var scope = scopes.CreateAsyncScope();
                var purged = await scope.ServiceProvider.GetRequiredService<IdPhotoService>().PurgeExpiredAsync(stoppingToken);
                if (purged > 0)
                {
                    logger.LogInformation("Deleted {Count} expired ID card photos", purged);
                }
            }
            catch (Exception exception) when (exception is not OperationCanceledException)
            {
                logger.LogError(exception, "ID card photo clean-up failed; retrying tomorrow");
            }
        }
        while (await timer.WaitForNextTickAsync(stoppingToken));
    }
}
