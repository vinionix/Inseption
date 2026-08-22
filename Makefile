COMPOSE = docker compose -f srcs/docker-compose.yml --env-file srcs/.env
DATA_DIR = /home/vfidelis/data
SECRETS_DIR = srcs/secrets
SECRETS = db_password.txt db_root_password.txt wp_password.txt wp_root_password.txt

.PHONY: all prepare up down clean fclean re logs status config

all: up

prepare:
	@test -f srcs/.env || (echo "Missing srcs/.env. Copy srcs/.env.example first." && exit 1)
	@for secret in $(SECRETS); do \
		test -s "$(SECRETS_DIR)/$$secret" || { \
			echo "Missing or empty secret: $(SECRETS_DIR)/$$secret"; \
			exit 1; \
		}; \
	done
	mkdir -p $(DATA_DIR)/mariadb
	mkdir -p $(DATA_DIR)/wordpress

up: prepare
	$(COMPOSE) up -d --build

down:
	$(COMPOSE) down

clean:
	$(COMPOSE) down --remove-orphans

fclean:
	$(COMPOSE) down -v --rmi all --remove-orphans
	sudo rm -rf $(DATA_DIR)/mariadb
	sudo rm -rf $(DATA_DIR)/wordpress

re: fclean up

logs:
	$(COMPOSE) logs -f

status:
	$(COMPOSE) ps

config:
	$(COMPOSE) config
