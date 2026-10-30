# syntax=docker/dockerfile:1

# 1. Front-end: contrast gate, fonts, icon sprite, Tailwind CSS and esbuild bundle -> wwwroot
FROM node:22-bookworm-slim AS assets
WORKDIR /web
COPY src/ResortGuestbook.Web/package.json src/ResortGuestbook.Web/package-lock.json ./
RUN npm ci --no-audit --no-fund
COPY src/ResortGuestbook.Web/build.mjs src/ResortGuestbook.Web/tailwind.config.js ./
COPY src/ResortGuestbook.Web/scripts ./scripts
COPY src/ResortGuestbook.Web/Styles ./Styles
COPY src/ResortGuestbook.Web/Scripts ./Scripts
COPY src/ResortGuestbook.Web/Views ./Views
RUN npm run build

# 2. Restore (cached on project files only) and publish
FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build
WORKDIR /src
COPY global.json Directory.Build.props Directory.Packages.props ./
COPY src/ResortGuestbook.Data/ResortGuestbook.Data.csproj src/ResortGuestbook.Data/
COPY src/ResortGuestbook.Migrations.Sqlite/ResortGuestbook.Migrations.Sqlite.csproj src/ResortGuestbook.Migrations.Sqlite/
COPY src/ResortGuestbook.Migrations.Postgres/ResortGuestbook.Migrations.Postgres.csproj src/ResortGuestbook.Migrations.Postgres/
COPY src/ResortGuestbook.Web/ResortGuestbook.Web.csproj src/ResortGuestbook.Web/
RUN dotnet restore src/ResortGuestbook.Web/ResortGuestbook.Web.csproj
COPY src/ src/
COPY --from=assets /web/wwwroot/css src/ResortGuestbook.Web/wwwroot/css
COPY --from=assets /web/wwwroot/js src/ResortGuestbook.Web/wwwroot/js
COPY --from=assets /web/wwwroot/fonts src/ResortGuestbook.Web/wwwroot/fonts
COPY --from=assets /web/wwwroot/icons.svg src/ResortGuestbook.Web/wwwroot/icons.svg
RUN dotnet publish src/ResortGuestbook.Web/ResortGuestbook.Web.csproj -c Release -o /app --no-restore -p:UseAppHost=false

# 3. Runtime: Ubuntu-based ASP.NET image (ICU and tzdata included), non-root user "app" (uid 1654)
FROM mcr.microsoft.com/dotnet/aspnet:10.0 AS runtime
ENV DOTNET_SYSTEM_GLOBALIZATION_INVARIANT=false \
    TZ=Asia/Bangkok
WORKDIR /app
COPY --from=build /app ./
RUN mkdir -p storage/database storage/uploads storage/backups storage/logs storage/keys \
    && chown -R app:app storage
USER app
EXPOSE 8080
HEALTHCHECK --interval=15s --timeout=5s --start-period=30s --retries=5 \
    CMD ["bash", "-c", "exec 3<>/dev/tcp/127.0.0.1/8080 && printf 'GET /health HTTP/1.0\\r\\nHost: localhost\\r\\n\\r\\n' >&3 && grep -q '^ok' <&3"]
ENTRYPOINT ["dotnet", "ResortGuestbook.Web.dll"]
