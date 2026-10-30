using Microsoft.AspNetCore.Diagnostics.HealthChecks;
using Microsoft.AspNetCore.StaticFiles;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Options;
using ResortGuestbook.Data;
using ResortGuestbook.Data.Providers;
using ResortGuestbook.Data.Seed;
using ResortGuestbook.Web.Infrastructure.Middleware;
using ResortGuestbook.Web.Infrastructure.Options;
using Serilog;

namespace ResortGuestbook.Web.Infrastructure.Extensions;

public static class ApplicationBuilderExtensions
{
    public static WebApplication UseStayBook(this WebApplication app)
    {
        app.UseForwardedHeaders();
        app.UseSerilogRequestLogging();
        app.UseExceptionHandler("/errors/exception");
        if (app.Environment.IsProduction())
        {
            app.UseHsts();
        }

        app.UseMiddleware<SecurityHeadersMiddleware>();
        app.UseStatusCodePagesWithReExecute("/errors/{0}");
        app.UseResponseCompression();
        app.UseHttpMethodOverride(new HttpMethodOverrideOptions { FormFieldName = "_method" });
        app.UseStaticFiles(new StaticFileOptions
        {
            ContentTypeProvider = new FileExtensionContentTypeProvider { Mappings = { [".webp"] = "image/webp" } },
            OnPrepareResponse = context => context.Context.Response.Headers.CacheControl =
                context.Context.Request.Query.ContainsKey("v") ? "public, max-age=31536000, immutable" : "public, max-age=604800",
        });
        app.UseRouting();
        app.UseRequestLocalization();
        app.UseAuthentication();
        app.UseAuthorization();
        app.UseRateLimiter();

        if (app.Environment.IsDevelopment())
        {
            app.MapOpenApi().AllowAnonymous();
            app.UseSwaggerUI(o => o.SwaggerEndpoint("/openapi/v1.json", "Stay Book API v1"));
        }

        app.MapHealthChecks("/health", new HealthCheckOptions
        {
            ResponseWriter = (context, report) =>
            {
                context.Response.ContentType = "text/plain";
                return context.Response.WriteAsync(report.Status == Microsoft.Extensions.Diagnostics.HealthChecks.HealthStatus.Healthy ? "ok\n" : "unhealthy\n");
            },
        }).AllowAnonymous().DisableHttpMetrics();
        app.MapControllers();

        // Unknown paths and wrong methods are 404 for everyone (v1 matched routes before checking the session);
        // the status code page then renders the HTML page or the JSON envelope.
        app.MapFallback("{*path}", context =>
        {
            context.Response.StatusCode = StatusCodes.Status404NotFound;
            return Task.CompletedTask;
        }).AllowAnonymous();
        return app;
    }

    /// <summary>Applies migrations (<c>Database:AutoMigrate</c>) and seeds (<c>Database:Seed</c>) before serving requests.</summary>
    public static async Task InitializeDatabaseAsync(this WebApplication app)
    {
        var settings = app.Services.GetRequiredService<DatabaseSettings>();
        await using var scope = app.Services.CreateAsyncScope();
        if (settings.AutoMigrate)
        {
            await scope.ServiceProvider.GetRequiredService<AppDbContext>().Database.MigrateAsync();
        }

        if (settings.Seed)
        {
            var seed = scope.ServiceProvider.GetRequiredService<IOptions<SeedOptions>>().Value;
            await scope.ServiceProvider.GetRequiredService<DatabaseSeeder>().SeedAsync(seed.AdminEmail, seed.AdminPassword);
        }
    }
}
