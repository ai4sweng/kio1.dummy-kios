.DEFAULT_GOAL := help
VENV ?= .venv
PYTHON := $(VENV)/bin/python
DOCKER ?= docker
KIO_DUMMY_NETWORK ?= kio1-network
export KIO_DUMMY_NETWORK
COMPOSE = $(DOCKER) compose -f compose.yaml
SOURCES := dummy_kios/ tests/test_dummy_kios.py tests/test_integration.py

.PHONY: help install test test-cov test-integration format format-check lint typecheck check ci build network run up logs status stop down
help:
	@printf 'Targets: install test test-cov test-integration check format-check ci build run up logs status stop down\n'
install:
	python3 -m venv $(VENV)
	$(PYTHON) -m pip install -r requirements-dev.txt
test:
	$(PYTHON) -m pytest tests/ -m 'not integration' -q
test-cov:
	$(PYTHON) -m pytest tests/ -m 'not integration' --cov=dummy_kios --cov-report=term-missing
test-integration:
	@test -n "$(KIO1_SOURCE)" && test -f "$(KIO1_SOURCE)/main.py" || (printf 'Set KIO1_SOURCE to a KIO1 checkout\n'; exit 1)
	PYTHONPATH="$(abspath $(KIO1_SOURCE))" $(PYTHON) -m pytest tests/test_integration.py -q
format:
	$(VENV)/bin/isort --profile black $(SOURCES)
	$(VENV)/bin/black $(SOURCES)
format-check:
	$(VENV)/bin/isort --profile black --check-only $(SOURCES)
	$(VENV)/bin/black --check $(SOURCES)
lint:
	$(VENV)/bin/ruff check $(SOURCES)
typecheck:
	$(VENV)/bin/mypy dummy_kios/
check: lint typecheck
ci: format-check check test
build:
	$(COMPOSE) build
network:
	$(DOCKER) network inspect "$(KIO_DUMMY_NETWORK)" >/dev/null 2>&1 || $(DOCKER) network create "$(KIO_DUMMY_NETWORK)"
run: network
	$(COMPOSE) up --no-log-prefix --no-color
up: network
	$(COMPOSE) up -d --wait
logs:
	$(COMPOSE) logs -f --no-log-prefix --no-color
status:
	$(COMPOSE) ps
stop:
	$(COMPOSE) stop
down:
	$(COMPOSE) down