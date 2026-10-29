.PHONY: up down logs shell migrate seed test lint db-transfer backup
up:
	docker compose up -d --build
down:
	docker compose down
logs:
	docker compose logs -f
shell:
	docker compose exec php sh
migrate:
	docker compose exec php php bin/console migrate
seed:
	docker compose exec php php bin/console seed
test:
	docker compose exec php vendor/bin/phpunit
lint:
	docker compose exec php vendor/bin/php-cs-fixer fix --dry-run --diff
	docker compose exec php vendor/bin/phpstan analyse
db-transfer:
	docker compose exec php php bin/console db:transfer --from=sqlite --to=pgsql
backup:
	docker compose exec php php bin/console db:backup
