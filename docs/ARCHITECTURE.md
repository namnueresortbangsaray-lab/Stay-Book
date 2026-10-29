# Architecture

## Request lifecycle

Nginx exposes only `public/`, applies security headers, serves hashed assets, and forwards PHP requests to PHP-FPM. `public/index.php` boots configuration and dependency bindings, the router matches the request, then session authentication and CSRF checks run before a controller. Controllers validate/authorize, call a service, and return either a server-rendered response or the standard JSON envelope.

```text
Browser → Nginx → Router → Session/CSRF → Controller → Service → Repository → PDO
                                                           ↘ Audit log
```

Controllers do not contain SQL. Domain decisions such as overlap checks, ID-verification gating, inspection validation, money calculations, and audit events live in services. Only `app/Repositories/Database` performs application queries. Migrations, transfer, seed, and backup are infrastructure operations under `app/Database`.

## Database portability

`DB_DRIVER` selects a PDO connection and dialect. Both migration folders have the same filenames and equivalent columns. UUIDs are generated in PHP, money is integer satang, timestamps are UTC, booleans and JSON are normalized at repository boundaries, and half-open stay ranges use `check_in < other_checkout AND check_out > other_checkin`. SQLite enables foreign keys, WAL, and a busy timeout on every connection.

## Security boundaries

PHP file sessions are HttpOnly and SameSite=Lax (Secure in production), regenerated at login, and expire by configuration. Login failures are throttled by IP. Every mutation requires a CSRF token, server-side validation, role policy, prepared statements, and audit entry. Uploads are MIME-sniffed, randomly named, stored outside `public/`, and only delivered after authentication using `X-Accel-Redirect` to an Nginx `internal` location.

PostgreSQL migrations enable RLS on every application table and define no public policy. The browser never receives Supabase credentials; the backend database role is the only database client.

## Front end

Pages are server-rendered shells enhanced by one ES module bundle. The responsive five-section interface mirrors the Flutter navigation. Fetch uses a CSRF-aware wrapper; loading, empty, success, and failure states are visible. Native dialogs provide focus management and keyboard dismissal. Tailwind is compiled at build time, and views read `public/build/manifest.json` to resolve content-hashed assets.
