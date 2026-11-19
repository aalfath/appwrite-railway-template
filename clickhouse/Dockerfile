# ClickHouse for Appwrite usage statistics and execution logs (as in Appwrite 2.7.3's compose file).
FROM clickhouse/clickhouse-server:26.4.3-alpine@sha256:128168041226ef603588377b42e07ab4afd7d8f87f59ea46558a69655ff5ad4b

ENV CLICKHOUSE_DB=appwrite \
    CLICKHOUSE_USER=appwrite \
    CLICKHOUSE_DEFAULT_ACCESS_MANAGEMENT=1 \
    CLICKHOUSE_ALWAYS_RUN_INITDB_SCRIPTS=1

# Both files are copied unchanged from appwrite/appwrite at tag 2.7.3.
COPY clickhouse-config.xml /etc/clickhouse-server/config.d/appwrite.xml
COPY clickhouse-init.sh /docker-entrypoint-initdb.d/clickhouse-init.sh
