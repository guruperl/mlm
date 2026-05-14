SHELL := /bin/bash

COMPOSE := docker compose -f docker-compose.test.yml
MYSQL_SERVICE := mysql
TEST_PERL5LIB := ../perl:lib
export PERL5LIB := $(TEST_PERL5LIB)
export MLM_DB_DSN ?= dbi:mysql:database=mlm_test;host=127.0.0.1;port=53307
export MLM_DB_USER ?= mlm
export MLM_DB_PASSWORD ?= mlm

.PHONY: deps mysql-up mysql-reset compile-check json-check unit-test functional-test test

deps:
	sudo apt-get update
	sudo apt-get install -y libdbi-perl libdbd-mysql-perl libjson-perl libcgi-pm-perl libhttp-message-perl libwww-perl libtemplate-perl libxml-libxml-perl libtest-class-perl libdigest-hmac-perl libmime-lite-perl

mysql-up:
	$(COMPOSE) up -d $(MYSQL_SERVICE)
	@cid="$$($(COMPOSE) ps -q $(MYSQL_SERVICE))"; \
	for i in {1..90}; do \
	  status="$$(docker inspect -f '{{.State.Health.Status}}' "$$cid" 2>/dev/null || true)"; \
	  if [[ "$$status" == "healthy" ]]; then exit 0; fi; \
	  sleep 2; \
	done; \
	echo "MySQL did not become healthy" >&2; exit 1

mysql-reset:
	$(COMPOSE) exec -T $(MYSQL_SERVICE) mysql -umlm -pmlm mlm_test < conf/01_init.sql
	$(COMPOSE) exec -T $(MYSQL_SERVICE) mysql -umlm -pmlm mlm_test < conf/03_setup.sql

compile-check:
	@find lib/MLM ../perl/Genelet -name '*.pm' -print0 | xargs -0 -n1 perl -I../perl -Ilib -c

json-check:
	@find lib/MLM -name component.json -print0 | xargs -0 -n1 jq -e . >/dev/null

unit-test:
	prove -I../perl -Ilib lib/MLM

functional-test:
	prove -I../perl -Ilib \
	  conf/SAMPLE_bin/01_product.t \
	  conf/SAMPLE_bin/02_member.t \
	  conf/SAMPLE_bin/03_income.t \
	  conf/SAMPLE_bin/04_ledger.t \
	  conf/SAMPLE_bin/05_shopping.t

test: compile-check json-check unit-test mysql-reset functional-test
