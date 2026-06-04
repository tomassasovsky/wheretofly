# Dónde Volar API (Dart Frog)

Self-hosted backend for weather, social features, hybrid zone sync, and messaging.

## Stack

- **Dart Frog** — HTTP + WebSocket routes
- **PostgreSQL** — users, posts, messages, flight logs
- **Redis** — cache / pub-sub (compose service ready)
- **MinIO** — photo/video storage
- **Photon** — self-hosted OpenStreetMap geocoding (Argentina index)
- **Open-Meteo** — forecast + wind at point (no API key)
- **SMN CAP RSS** — Argentina weather alerts
- **Docker Compose** — home server deployment

## Local development

```bash
cd backend
docker compose up -d postgres redis minio photon
dart pub get
export DATABASE_URL=postgresql://dondevolar:dondevolar@localhost:5432/dondevolar
export JWT_SECRET=dev-secret
export PHOTON_BASE_URL=http://localhost:2322
dart_frog dev
```

**Photon first run:** The `photon` service downloads the Argentina index (~3.9 GB)
on first start, then extracts it. Port `2322` is published immediately, but the
API is **not** listening until the download finishes — `curl` may show
`Connection reset by peer` during that window (normal).

Watch progress:

```bash
docker compose logs -f photon
```

Ready when you see `Listening on http://0.0.0.0:2322/` and:

```bash
curl 'http://localhost:2322/api?q=Buenos%20Aires'
```

returns JSON (HTTP 200). Later restarts are fast because the index is stored in
the `photon_data` volume.

Health check: `GET http://localhost:8080/health`

## Production (home server / Portainer)

Use the Portainer stack under [`deploy/home-server/`](../deploy/home-server/README.md):

- Public API: **`https://dondevolar.aquiles.dev`** (Nginx Proxy Manager → Dart Frog; see `deploy/home-server/README.md`)
- Photon, Postgres, Redis, and MinIO stay internal to Docker (no extra subdomains)
- Copy `deploy/home-server/.env.example` → `.env`, set strong secrets, deploy stack

The Flutter app uses that URL in **release** builds by default (`lib/config/api_config.dart`).

## API overview

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| GET | `/health` | No | Version + zone feed metadata |
| POST | `/v1/auth/signup` | No | Register |
| POST | `/v1/auth/login` | No | Login |
| POST | `/v1/auth/refresh` | No | Refresh tokens |
| GET | `/v1/weather?lat=&lon=` | No | Open-Meteo proxy + SMN advisory |
| GET | `/v1/zones` | No | GeoJSON zone feed (ETag) |
| GET | `/v1/geocoding/search?q=&limit=` | No | Map search (self-hosted Photon) |
| GET | `/v1/geocoding/reverse?lat=&lon=` | No | Reverse geocoding |
| POST | `/v1/zones/ingest` | Yes | Rebuild zone feed from external sources |
| POST | `/v1/cron/zone_ingest` | Cron secret | Scheduled zone feed refresh |
| GET/POST | `/v1/posts` | Yes | Feed / create post |
| GET | `/v1/users/:handle` | Yes | Public profile |
| POST | `/v1/users/:handle/follow` | Yes | Follow user |
| POST/GET | `/v1/messages/:threadId` | Yes | DM / group messages |

Map zone checks and geocoding are served by the backend; the app caches zones
locally for offline use.
