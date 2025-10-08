COMPOSE=docker compose -f compose/ollama-openwebui.yml

up:
	$(COMPOSE) up -d

down:
	$(COMPOSE) down

pull:
	$(COMPOSE) pull

logs:
	$(COMPOSE) logs -f

backup:
	mkdir -p backups
	tar czf backups/ollama-openwebui-$$(date +%Y%m%d-%H%M%S).tgz -C "$$(grep ^DATA_ROOT .env | cut -d= -f2)" ollama openwebui

restore:
	@[ -n "$$ARCHIVE" ] || (echo "set ARCHIVE=backups/....tgz"; exit 1)
	tar xzf "$$ARCHIVE" -C "$$(grep ^DATA_ROOT .env | cut -d= -f2)"
