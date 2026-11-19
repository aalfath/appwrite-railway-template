#!/bin/sh
# Starts one Appwrite role: api (default), realtime, worker, scheduler, maintenance, interval,
# or any other command shipped in the image's /usr/local/bin.
# The role comes from the first argument, else APPWRITE_ROLE, else "api".
set -e

role="${1:-${APPWRITE_ROLE:-api}}"
echo "[railway-start] Appwrite ${_APP_VERSION:-} role: ${role}"

# Wait for PostgreSQL (first deploys start every service at once).
i=0
until php -r '$s=@fsockopen(getenv("_APP_DB_HOST"), (int) (getenv("_APP_DB_PORT") ?: 5432), $e, $m, 3); exit($s ? 0 : 1);'; do
  i=$((i + 1))
  if [ "$i" -ge 120 ]; then echo "[railway-start] PostgreSQL at ${_APP_DB_HOST} not reachable after 10 minutes"; exit 1; fi
  echo "[railway-start] waiting for PostgreSQL at ${_APP_DB_HOST}:${_APP_DB_PORT:-5432} ..."
  sleep 5
done

# Every role except the API waits until the API has created the schema.
if [ "$role" != "api" ] && [ -n "${APPWRITE_API_HOST:-}" ]; then
  i=0
  until curl -fsS -o /dev/null "http://${APPWRITE_API_HOST}/v1/health/version"; do
    i=$((i + 1))
    if [ "$i" -ge 120 ]; then echo "[railway-start] API at ${APPWRITE_API_HOST} not answering after 10 minutes"; exit 1; fi
    echo "[railway-start] waiting for the Appwrite API at ${APPWRITE_API_HOST} ..."
    sleep 5
  done
fi

case "$role" in
  api)         exec php /usr/src/code/app/http.php ;;
  realtime)    exec realtime ;;
  worker)      exec worker ;;
  scheduler)   exec schedule ;;
  maintenance) exec maintenance ;;
  interval)    exec interval ;;
  *)           exec "$role" ;;
esac
