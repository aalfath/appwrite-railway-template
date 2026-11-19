[![Deploy on Railway](https://railway.com/button.svg)](https://railway.com/new/template/appwrite-2?utm_medium=integration&utm_source=button&utm_campaign=appwrite)

# Appwrite on Railway

A one-click [Railway](https://railway.com) template for [Appwrite](https://github.com/appwrite/appwrite) **2.7.3**, the open-source backend platform: auth, databases, storage, messaging and realtime behind one API and a web console.

It deploys the stack from Appwrite 2.7.3's own `docker-compose.yml` as separate Railway services, wired over the private network:

| Service | Built from | What it does |
|---|---|---|
| **Appwrite** (public) | `router/` (`caddy:2.11.9-alpine`, pinned by digest) | Public entry point: `/v1/realtime` to Realtime, `/v1` and `/.well-known` to the API, everything else to the Console. Health at `/__router/health` |
| **Appwrite API** | `appwrite/` (`appwrite/appwrite:2.7.3`, pinned by digest) | The REST and GraphQL API; creates and migrates the database schema on start. Health at `/v1/health/version` |
| **Appwrite Realtime** | `appwrite/` | WebSocket server for realtime subscriptions |
| **Appwrite Worker** | `appwrite/` | All background queues (databases, mails, messaging, webhooks, audits, usage, deletes, certificates, migrations…) |
| **Appwrite Scheduler** | `appwrite/` | Scheduled functions, executions and messages |
| **Appwrite Maintenance** | `appwrite/` | Daily cleanup of logs, cache and old usage data |
| **Appwrite Interval** | `appwrite/` | Periodic tasks (domain verification, stale executions) |
| **Appwrite Console** | `console/` (`appwrite/new:1.2.181-self-hosted`, pinned by digest) | The web console. Health at `/health` |
| **PostgreSQL** | `postgresql/` (`appwrite/postgres:0.1.0`, PostgreSQL 18 with pgvector and PostGIS, pinned by digest) | Main database. Volume on `/var/lib/postgresql` |
| **ClickHouse** | `clickhouse/` (`clickhouse/clickhouse-server:26.4.3-alpine`, pinned by digest) | Usage statistics and execution logs. Volume on `/var/lib/clickhouse` |
| **Geo** | `geo/` (`appwrite/geo:0.3.2`) | IP to country and locale lookups |
| **ExifTool** | `exiftool/` (`ghcr.io/appwrite/exiftool:0.1.1`) | Strips metadata from uploaded images |
| **AutoGravity** | `autogravity/` (`ghcr.io/appwrite/autogravity:0.0.11`) | Focal point detection for image previews |
| **Redis** | Railway's Redis | Cache, queues and pub/sub |
| **Bucket** | Railway Bucket | File storage (S3-compatible), so every Appwrite service sees the same files |

Every Appwrite role runs the same image; the role is the start command (`railway-start api|realtime|worker|scheduler|maintenance|interval`). Each role waits for PostgreSQL, and every role except the API waits until the API answers, so the first deploy comes up in the right order.

## Left out

- **Functions and Sites** (builds and executions): Appwrite's executor needs the host's Docker socket, which Railway does not offer. Everything else works.
- Traefik (replaced by the small Caddy router), MQTT (raw TCP), the screenshot browser, the AI review service and the optional embedding model.

## Variables

Nothing has to be typed in at deploy.

- `_APP_OPENSSL_KEY_V1` (Appwrite API): generated, 64 characters. Encrypts secrets stored in the database. **Never change it after the first deploy**, or stored secrets can no longer be read. The other roles reference it.
- `_APP_EXECUTOR_SECRET`, `_APP_NOTIFICATIONS_TRACKING_SECRET` (Appwrite API), `GEO_SECRET` (Geo), `POSTGRES_PASSWORD` (PostgreSQL), `CLICKHOUSE_PASSWORD` (ClickHouse): generated.
- `_APP_DOMAIN`, `_APP_CONSOLE_URL`: the public domain of the **Appwrite** service. If you add a custom domain, change them on all six Appwrite role services.
- `_APP_DB_*`, `_APP_REDIS_*`, `_APP_CONNECTIONS_DB_*`, `_APP_STORAGE_S3_*`, `_APP_GEO_*`, `_APP_*_HOST`: references to the other services and the bucket.

Fixed settings (PostgreSQL adapter, S3 storage, abuse protection on, console sign-up limited to the first user) are set in `appwrite/Dockerfile`; any of them can be overridden with a service variable. To send email (verification, password recovery, invites), set `_APP_SMTP_HOST`, `_APP_SMTP_PORT`, `_APP_SMTP_SECURE`, `_APP_SMTP_USERNAME`, `_APP_SMTP_PASSWORD` and `_APP_SYSTEM_EMAIL_ADDRESS` on the API and Worker services.

## After deploy

1. Open the **Appwrite** service's public URL and sign up right away: the first account becomes the console owner, and further console sign-ups are refused (`_APP_CONSOLE_WHITELIST_ROOT=enabled`).
2. Create a project and add a Web platform for your app's hostname.
3. Point your SDK at `https://YOUR-DOMAIN/v1`.

## Updates

Every image is pinned by version and digest in the service folders' Dockerfiles. A new Appwrite version lands here as a commit on `main`; Railway then shows an "update available" notice on your project and you choose when to apply it. Read [CHANGELOG.md](CHANGELOG.md) first: breaking changes are listed first. The API runs Appwrite's schema migration when it starts.

## Repo layout

- `appwrite/`: Dockerfile and `railway-start.sh` for the six Appwrite roles.
- `console/`, `postgresql/`, `clickhouse/`, `geo/`, `exiftool/`, `autogravity/`, `router/`: one folder per service.
- `compose.test.yml`: local test of the same stack (SeaweedFS stands in for the bucket). Not used by Railway.

Appwrite is licensed under BSD-3-Clause by Appwrite Code Ltd. This repo only packages it for Railway.
