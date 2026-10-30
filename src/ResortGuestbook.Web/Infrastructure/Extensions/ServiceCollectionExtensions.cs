using System.Globalization;
using System.Text;
using System.Text.Encodings.Web;
using System.Text.Unicode;
using System.Threading.RateLimiting;
using Microsoft.AspNetCore.Authentication.Cookies;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.DataProtection;
using Microsoft.AspNetCore.HttpOverrides;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Localization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.WebEncoders;
using ResortGuestbook.Data;
using ResortGuestbook.Data.Entities;
using ResortGuestbook.Data.Identity;
using ResortGuestbook.Data.Providers;
using ResortGuestbook.Data.Seed;
using ResortGuestbook.Web.Authorization;
using ResortGuestbook.Web.Infrastructure.Cli;
using ResortGuestbook.Web.Infrastructure.Http;
using ResortGuestbook.Web.Infrastructure.Identity;
using ResortGuestbook.Web.Infrastructure.Middleware;
using ResortGuestbook.Web.Infrastructure.Options;
using ResortGuestbook.Web.Infrastructure.Storage;
using ResortGuestbook.Web.Services;
using Serilog;

namespace ResortGuestbook.Web.Infrastructure.Extensions;

public static class ServiceCollectionExtensions
{
    public const string ApiUnauthenticated = "กรุณาเข้าสู่ระบบ";

    public static WebApplicationBuilder AddStayBook(this WebApplicationBuilder builder)
    {
        var configuration = builder.Configuration;
        var services = builder.Services;
        var storage = configuration.GetSection("Storage").Get<StorageOptions>() ?? new StorageOptions();
        var auth = new AuthOptions { SessionLifetimeMinutes = configuration.GetValue("SESSION_LIFETIME", 120) };
        var uploads = new UploadOptions { MaxBytes = configuration.GetValue("UPLOAD_MAX_BYTES", 5_242_880L) };

        builder.Host.UseSerilog((context, logger) => logger
            .ReadFrom.Configuration(context.Configuration)
            .Enrich.FromLogContext()
            .WriteTo.Console()
            .WriteTo.File(Path.Combine(storage.LogsPath, "app-.log"), rollingInterval: RollingInterval.Day, retainedFileCountLimit: 14, formatProvider: CultureInfo.InvariantCulture));

        builder.WebHost.ConfigureKestrel(kestrel =>
        {
            kestrel.AddServerHeader = false;
            kestrel.Limits.MaxRequestBodySize = uploads.MaxRequestBytes;
            kestrel.ResponseHeaderEncodingSelector = _ => Encoding.UTF8;
        });

        services.Configure<AppOptions>(configuration.GetSection("App"));
        services.Configure<StorageOptions>(configuration.GetSection("Storage"));
        services.Configure<UploadOptions>(o => o.MaxBytes = uploads.MaxBytes);
        services.Configure<AuthOptions>(o => o.SessionLifetimeMinutes = auth.SessionLifetimeMinutes);
        services.Configure<BackupOptions>(o => o.Keep = configuration.GetValue("BACKUP_KEEP", 7));
        services.Configure<SeedOptions>(o =>
        {
            o.AdminEmail = configuration["DEMO_ADMIN_EMAIL"] is { Length: > 0 } email ? email : o.AdminEmail;
            o.AdminPassword = configuration["DEMO_ADMIN_PASSWORD"] is { Length: > 0 } password ? password : o.AdminPassword;
        });

        services.AddSingleton(TimeProvider.System);
        var database = DatabaseSettings.FromConfiguration(configuration);
        services.AddSingleton(database);
        services.AddDbContext<AppDbContext>((sp, options) =>
            AppDbContextOptions.Configure(options, database.Provider, database.ConnectionString(database.Provider), sp.GetRequiredService<TimeProvider>()));
        services.AddHealthChecks().AddDbContextCheck<AppDbContext>();

        AddIdentity(services, auth);
        AddAuthorization(services);
        AddRateLimiting(services);

        services.AddAntiforgery(o =>
        {
            o.HeaderName = "X-CSRF-Token";
            o.FormFieldName = "_token";
            o.Cookie.Name = ".StayBook.Antiforgery";
            o.Cookie.SecurePolicy = CookieSecurePolicy.SameAsRequest;
        });
        services.AddLocalization();
        services.Configure<WebEncoderOptions>(o => o.TextEncoderSettings = new TextEncoderSettings(UnicodeRanges.All));
        services.AddControllersWithViews(o =>
            {
                o.Filters.Add(new AutoValidateAntiforgeryTokenAttribute());
                o.Filters.Add<AntiforgeryFailureFilter>();
            })
            .AddJsonOptions(o => ApiJson.Configure(o.JsonSerializerOptions))
            .AddViewLocalization();
        services.Configure<RequestLocalizationOptions>(o =>
        {
            var thai = new CultureInfo("th-TH");
            thai.DateTimeFormat.Calendar = new GregorianCalendar();
            o.DefaultRequestCulture = new RequestCulture(thai);
            o.SupportedCultures = o.SupportedUICultures = [thai, new CultureInfo("en")];

            // Thai unless chosen explicitly (?culture=en or the culture cookie); the browser language is ignored, as in PHP.
            o.RequestCultureProviders = [new QueryStringRequestCultureProvider(), new CookieRequestCultureProvider()];
        });
        services.AddResponseCompression();
        services.AddOpenApi();
        services.AddDataProtection()
            .PersistKeysToFileSystem(Directory.CreateDirectory(storage.KeysPath))
            .SetApplicationName("StayBook");
        services.Configure<ForwardedHeadersOptions>(o =>
        {
            if (configuration.GetValue("App:TrustForwardedHeaders", false))
            {
                o.ForwardedHeaders = ForwardedHeaders.XForwardedFor | ForwardedHeaders.XForwardedProto;
                o.KnownIPNetworks.Clear();
                o.KnownProxies.Clear();
            }
        });

        services.AddScoped<CspNonce>();
        services.AddScoped<AppClock>();
        services.AddScoped<ResortQueries>();
        services.AddScoped<AuditService>();
        services.AddScoped<RoomService>();
        services.AddScoped<GuestService>();
        services.AddScoped<StayService>();
        services.AddScoped<SnapshotService>();
        services.AddScoped<UploadService>();
        services.AddScoped<DatabaseSeeder>();
        services.AddSingleton<IFileStorage, LocalFileStorage>();

        services.AddScoped<ICliCommand, MigrateCommand>();
        services.AddScoped<ICliCommand, SeedCommand>();
        services.AddScoped<ICliCommand, UserCreateCommand>();
        services.AddScoped<ICliCommand, DbBackupCommand>();
        services.AddScoped<ICliCommand, DbTransferCommand>();
        services.AddScoped<ICliCommand, ImportPhpCommand>();
        return builder;
    }

    private static void AddIdentity(IServiceCollection services, AuthOptions auth)
    {
        services.AddSingleton<LoginThrottle>();
        services.AddScoped<IPasswordHasher<AppUser>, LegacyBcryptPasswordHasher>();
        services.AddIdentityCore<AppUser>(o =>
            {
                o.Lockout.MaxFailedAccessAttempts = auth.LoginAttempts;
                o.Lockout.DefaultLockoutTimeSpan = TimeSpan.FromSeconds(auth.LoginWindowSeconds);
            })
            .AddUserStore<AppUserStore>()
            .AddSignInManager()
            .AddClaimsPrincipalFactory<AppClaimsPrincipalFactory>();
        services.AddAuthentication(IdentityConstants.ApplicationScheme).AddIdentityCookies(cookies => cookies.ApplicationCookie?.Configure(o =>
        {
            o.Cookie.Name = ".StayBook.Auth";
            o.Cookie.HttpOnly = true;
            o.Cookie.SameSite = SameSiteMode.Lax;
            o.Cookie.SecurePolicy = CookieSecurePolicy.SameAsRequest;
            o.ExpireTimeSpan = TimeSpan.FromMinutes(auth.SessionLifetimeMinutes);
            o.SlidingExpiration = true;
            o.LoginPath = "/login";
            o.Events = new CookieAuthenticationEvents
            {
                OnRedirectToLogin = context =>
                {
                    if (ApiResults.IsApi(context.Request))
                    {
                        return ApiResults.WriteAsync(context.HttpContext, StatusCodes.Status401Unauthorized, ApiUnauthenticated);
                    }

                    context.Response.Redirect("/login");
                    return Task.CompletedTask;
                },
                OnRedirectToAccessDenied = context =>
                {
                    if (ApiResults.IsApi(context.Request))
                    {
                        return ApiResults.WriteAsync(context.HttpContext, StatusCodes.Status403Forbidden, "ไม่มีสิทธิ์ดำเนินการ");
                    }

                    context.Response.StatusCode = StatusCodes.Status403Forbidden;
                    return Task.CompletedTask;
                },
            };
        }));
    }

    private static void AddAuthorization(IServiceCollection services)
    {
        var authorization = services.AddAuthorizationBuilder()
            .SetFallbackPolicy(new AuthorizationPolicyBuilder().RequireAuthenticatedUser().Build());
        foreach (var ability in Abilities.All)
        {
            authorization.AddPolicy(ability, p => p.RequireAuthenticatedUser().AddRequirements(new AbilityRequirement(ability)));
        }

        services.AddSingleton<IAuthorizationHandler, AbilityHandler>();
    }

    private static void AddRateLimiting(IServiceCollection services) => services.AddRateLimiter(o =>
    {
        o.RejectionStatusCode = StatusCodes.Status429TooManyRequests;
        o.AddPolicy(RateLimitPolicies.Login, context => RateLimitPartition.GetFixedWindowLimiter(
            context.ClientIp(),
            _ => new FixedWindowRateLimiterOptions { PermitLimit = 30, Window = TimeSpan.FromMinutes(1) }));
        o.AddPolicy(RateLimitPolicies.Writes, context => RateLimitPartition.GetFixedWindowLimiter(
            context.User.Identity?.Name ?? context.ClientIp(),
            _ => new FixedWindowRateLimiterOptions { PermitLimit = 120, Window = TimeSpan.FromMinutes(1) }));
        o.OnRejected = (context, _) => ApiResults.IsApi(context.HttpContext.Request)
            ? new ValueTask(ApiResults.WriteAsync(context.HttpContext, StatusCodes.Status429TooManyRequests, "คำขอมากเกินไป กรุณาลองใหม่ภายหลัง"))
            : ValueTask.CompletedTask;
    });
}
