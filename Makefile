SHELL := /bin/bash

COMPOSE := docker compose -f docker-compose.test.yml
MYSQL_SERVICE := mysql
MYSQL_HOST ?= 127.0.0.1
MYSQL_PORT ?= 53307
MYSQL_DATABASE ?= mlm_test
MYSQL_USER ?= mlm
MYSQL_PASSWORD ?= mlm
GENELET_LIB ?= ../perl
TEST_PERL5LIB := $(GENELET_LIB):lib
UNIT_TESTS := $(shell find lib/MLM -name '*.t' \
	! -path 'lib/MLM/Test/*' \
	! -path 'lib/MLM/Admin/admin.t' \
	! -path 'lib/MLM/Placement/placement.t' \
	-print | sort)
export PERL5LIB := $(TEST_PERL5LIB)
export MLM_DB_DSN ?= dbi:mysql:database=$(MYSQL_DATABASE);host=$(MYSQL_HOST);port=$(MYSQL_PORT)
export MLM_DB_USER ?= $(MYSQL_USER)
export MLM_DB_PASSWORD ?= $(MYSQL_PASSWORD)

.PHONY: deps mysql-up mysql-reset mysql-reset-external compile-check json-check unit-test functional-test test test-external

deps:
	sudo apt-get update
	sudo apt-get install -y default-mysql-client jq libdbi-perl libdbd-mysql-perl libjson-perl libcgi-pm-perl libhttp-message-perl libwww-perl libtemplate-perl libxml-libxml-perl libtest-class-perl libdigest-hmac-perl libmime-lite-perl

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

mysql-reset-external:
	MYSQL_PWD='$(MYSQL_PASSWORD)' mysql -h '$(MYSQL_HOST)' -P '$(MYSQL_PORT)' -u '$(MYSQL_USER)' '$(MYSQL_DATABASE)' < conf/01_init.sql
	MYSQL_PWD='$(MYSQL_PASSWORD)' mysql -h '$(MYSQL_HOST)' -P '$(MYSQL_PORT)' -u '$(MYSQL_USER)' '$(MYSQL_DATABASE)' < conf/03_setup.sql

compile-check:
	@find lib/MLM $(GENELET_LIB)/Genelet -name '*.pm' -print0 | xargs -0 -n1 perl -I$(GENELET_LIB) -Ilib -c

json-check:
	@find lib/MLM -name component.json -print0 | xargs -0 -n1 jq -e . >/dev/null

unit-test:
	prove -I$(GENELET_LIB) -Ilib $(UNIT_TESTS)

functional-test:
	prove -I$(GENELET_LIB) -Ilib \
	  conf/SAMPLE_bin/01_product.t \
	  conf/SAMPLE_bin/02_member.t \
	  conf/SAMPLE_bin/03_income.t \
	  conf/SAMPLE_bin/04_ledger.t \
	  conf/SAMPLE_bin/05_shopping.t

test: compile-check json-check unit-test mysql-reset functional-test

test-external: compile-check json-check unit-test mysql-reset-external functional-test
