# Stay Book — common tasks. Docker targets run inside the "web" container; others need the .NET 10 SDK and Node 22.
COMPOSE ?= docker compose
CLI = $(COMPOSE) exec web dotnet ResortGuestbook.Web.dll
WEB = src/ResortGuestbook.Web
NAME ?= NewMigration

.PHONY: up down logs shell prod-up dev pgtest-up migrate seed user-create backup db-transfer import-php \
        build assets test format format-check smoke migrations-add

up:            ## Build and start (http://localhost:8080)
	$(COMPOSE) up -d --build
down:
	$(COMPOSE) down
logs:
	$(COMPOSE) logs -f web
shell:
	$(COMPOSE) exec web bash
prod-up:       ## Nginx + Kestrel
	$(COMPOSE) -f docker-compose.yml -f docker-compose.prod.yml up -d --build
dev:           ## dotnet watch + Tailwind watcher on http://localhost:8082
	$(COMPOSE) --profile dev up web-dev assets-dev
pgtest-up:     ## Local PostgreSQL 15 for Supabase-provider testing
	$(COMPOSE) --profile pgtest up -d postgres

migrate:
	$(CLI) migrate
seed:
	$(CLI) seed
user-create:   ## make user-create NAME_ARG="..." EMAIL=... PASSWORD=... ROLE=front_desk
	$(CLI) user:create --name="$(NAME_ARG)" --email=$(EMAIL) --password=$(PASSWORD) --role=$(or $(ROLE),front_desk)
backup:
	$(CLI) db:backup
db-transfer:   ## SQLite -> PostgreSQL/Supabase (SUPABASE_DB_* must be set in .env)
	$(CLI) db:transfer --from=sqlite --to=postgres
import-php:    ## Import the PHP database and uploads from the reused volumes
	$(CLI) import:php --sqlite=/app/storage/database/stay_book.sqlite --uploads=/app/storage/uploads --truncate

assets:
	npm --prefix $(WEB) ci && npm --prefix $(WEB) run build
build: assets
	dotnet build ResortGuestbook.sln -c Release
test:
	dotnet test ResortGuestbook.sln
format:
	dotnet format ResortGuestbook.sln
format-check:
	dotnet format ResortGuestbook.sln --verify-no-changes
smoke:
	sh tests/smoke/smoke-test.sh

migrations-add: ## make migrations-add NAME=AddSomething  (both providers)
	dotnet ef migrations add $(NAME) -p src/ResortGuestbook.Migrations.Sqlite -s src/ResortGuestbook.Migrations.Sqlite
	dotnet ef migrations add $(NAME) -p src/ResortGuestbook.Migrations.Postgres -s src/ResortGuestbook.Migrations.Postgres
