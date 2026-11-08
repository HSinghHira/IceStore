#!/bin/bash
# Upstream's self-hosting/clickhouse/init-db.sh: run by the ClickHouse image
# on the very first start.
set -e
clickhouse client -n <<-EOSQL
    CREATE DATABASE IF NOT EXISTS openpanel;
EOSQL
