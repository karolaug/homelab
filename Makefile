# Makefile — manage any compose stack or network
SHELL := /usr/bin/env bash
.DEFAULT_GOAL := help

# --- config ---
COMPOSE_DIR ?= compose
EXT ?= yml                 # change to yaml if needed
STACK ?= ai                # default stack
PROJECT ?= $(STACK)        # docker compose -p <project>
COMPOSE_FILE := $(COMPOSE_DIR)/$(STACK).$(EXT)
COMPOSE := docker compose -f $(COMPOSE_FILE) -p $(PROJECT)

NETWORK ?= homelab
SERVICE ?=
CMD ?= /bin/sh

STACK_FILES := $(shell ls $(COMPOSE_DIR)/*.yml $(COMPOSE_DIR)/*.yaml 2>/dev/null)
STACK_NAMES := $(shell for f in $(STACK_FILES); do bn=$$(basename $$f); echo $${bn%.*}; done)

# --- help ---
.PHONY: help
help: ## Show help
	@echo "Stacks dir: $(COMPOSE_DIR)"; \
	echo "Default stack: $(STACK) | file: $(COMPOSE_FILE)"; \
	echo; \
	echo "Targets:"; \
	echo "  ls-stacks                 List available stacks"; \
	echo "  up [STACK=...]           Create network if needed, up -d"; \
	echo "  down [STACK=...]         down --remove-orphans"; \
	echo "  start/stop/restart       Manage a stack"; \
	echo "  ps [STACK=...]           Show containers"; \
	echo "  logs [SERVICE=...]       Tail logs"; \
	echo "  pull/build/reup          Update images, build, force recreate"; \
	echo "  destroy                  Down + volumes"; \
	echo "  validate                 docker compose config -q"; \
	echo "  up-all|down-all|ps-all   Operate on every stack"; \
	echo "  net-create [NETWORK=...] Create bridge network"; \
	echo "  net-rm [NETWORK=...]     Remove network"; \
	echo "  net-ls|net-inspect|net-prune"; \
	echo "  net-connect|net-disconnect NETWORK=... CONTAINER=..."; \
	echo "  exec/sh                  SERVICE=... CMD=... | open shell"

# --- stack ops ---
.PHONY: ls-stacks ensure-net up down start stop restart ps logs pull build reup destroy validate up-all down-all ps-all exec sh
ls-stacks: ## List compose stacks
	@for f in $(STACK_FILES); do bn=$$(basename $$f); echo $${bn%.*}; done

ensure-net: ## Create $(NETWORK) if missing
	@docker network inspect $(NETWORK) >/dev/null 2>&1 || docker network create $(NETWORK)

up: ensure-net ## Up one stack
	@$(COMPOSE) up -d

down: ## Down one stack
	@$(COMPOSE) down --remove-orphans

start: ## Start a stack
	@$(COMPOSE) start

stop: ## Stop a stack
	@$(COMPOSE) stop

restart: ## Restart a stack (optionally SERVICE=...)
	@$(COMPOSE) restart $(SERVICE)

ps: ## Show containers in a stack
	@$(COMPOSE) ps

logs: ## Tail logs; optional SERVICE=...
	@$(COMPOSE) logs -f $(SERVICE)

pull: ## Pull images
	@$(COMPOSE) pull

build: ## Build images
	@$(COMPOSE) build

reup: ## Recreate with latest images
	@$(COMPOSE) up -d --build --force-recreate --remove-orphans

destroy: ## Down and remove volumes
	@$(COMPOSE) down --volumes --remove-orphans

validate: ## Validate compose file
	@$(COMPOSE) config -q

up-all: ensure-net ## Up every stack in $(COMPOSE_DIR)
	@for f in $(STACK_FILES); do \
	  name=$$(basename $$f); name=$${name%.*}; \
	  echo ">>> $$name"; \
	  docker compose -f $$f -p $$name up -d; \
	done

down-all: ## Down every stack
	@for f in $(STACK_FILES); do \
	  name=$$(basename $$f); name=$${name%.*}; \
	  echo ">>> $$name"; \
	  docker compose -f $$f -p $$name down --remove-orphans; \
	done

ps-all: ## Show all stacks
	@for f in $(STACK_FILES); do \
	  name=$$(basename $$f); name=$${name%.*}; \
	  echo ">>> $$name"; \
	  docker compose -f $$f -p $$name ps; \
	done

exec: ## Exec into a service; set SERVICE=... CMD='bash'
	@$(COMPOSE) exec $(SERVICE) $(CMD)

sh: ## Open a shell in SERVICE=...
	@$(MAKE) exec SERVICE="$(SERVICE)" CMD="/bin/sh"

# --- network ops ---
.PHONY: net-create net-rm net-ls net-inspect net-prune net-connect net-disconnect
net-create: ## Create a bridge network
	@docker network create $(NETWORK) 2>/dev/null || true

net-rm: ## Remove a network
	@docker network rm $(NETWORK) 2>/dev/null || true

net-ls: ## List networks
	@docker network ls

net-inspect: ## Inspect a network
	@docker network inspect $(NETWORK)

net-prune: ## Prune unused networks
	@docker network prune -f

net-connect: ## Connect container; set CONTAINER=...
	@docker network connect $(NETWORK) $(CONTAINER)

net-disconnect: ## Disconnect container; set CONTAINER=...
	@docker network disconnect $(NETWORK) $(CONTAINER)
