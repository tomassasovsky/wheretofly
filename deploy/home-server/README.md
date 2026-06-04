# Home server deployment (Portainer + nginx + aquiles.dev)

This stack runs **one public backend** for the Flutter app. Auth, weather, zones,
geocoding, social, and messaging all go through the Dart Frog API on a single
hostname. [Photon](https://github.com/komoot/photon), PostgreSQL, Redis, and
MinIO are sidecars on the Docker network — they are **not** exposed on separate
subdomains.

**TLS and port 80/443** are handled by your existing **nginx** container, not by
this compose file.

## Subdomains

| Host | Role |
|------|------|
| `dondevolar.aquiles.dev` | Public HTTPS API (nginx → `dondevolar-api:8080`) |

Internal only (no DNS records):

| Service | URL inside compose |
|---------|-------------------|
| Photon | `http://photon:2322` |
| Postgres | `postgres:5432` |
| Redis | `redis:6379` |
| MinIO | `minio:9000` |

## nginx

1. Copy or include [`nginx/dondevolar.aquiles.dev.conf`](nginx/dondevolar.aquiles.dev.conf) in your nginx config.
2. Point `ssl_certificate` / `ssl_certificate_key` at your existing certs for
   `dondevolar.aquiles.dev` (or a wildcard `*.aquiles.dev`).
3. Reload nginx after the stack is up.

### Wiring the API upstream

**Option A — nginx container on a shared Docker network (recommended)**

1. Find the network your nginx container uses:

   ```bash
   docker inspect <nginx-container-name> --format '{{range $k,$v := .NetworkSettings.Networks}}{{$k}}{{"\n"}}{{end}}'
   ```

2. Copy `docker-compose.override.example.yml` → `docker-compose.override.yml` and set
   the external network name to match nginx.

3. In `nginx/dondevolar.aquiles.dev.conf`, use the **A)** upstream (`dondevolar-api:8080`).
   The stack sets `container_name: dondevolar-api`.

**Option B — nginx on the host (or host network)**

1. Leave `API_HOST_PORT` at the default `127.0.0.1:18080` (published by the stack).
2. In the nginx config, uncomment the **B)** upstream (`127.0.0.1:18080`).
3. If nginx runs in Docker with `network_mode: host`, it can use the same loopback
   upstream.

Do not expose Postgres, Redis, MinIO, or Photon on the public internet.

## DNS

```
dondevolar.aquiles.dev  →  <your home public IP>
```

Forward **TCP 80 and 443** to the machine where **nginx** listens (same as today).

## Portainer

1. Clone this repository on the server (or use Portainer “Git repository” deploy).
2. **Stacks → Add stack** → `deploy/home-server/docker-compose.yml`
3. Copy `.env.example` → `.env` and set `POSTGRES_PASSWORD`, `DATABASE_URL`,
   `JWT_SECRET`, and MinIO keys. Add `docker-compose.override.yml` if using Option A.
4. Deploy. First Photon start downloads ~3.9 GB Argentina index; geocoding works
   after Photon logs `Listening on http://0.0.0.0:2322/`.

Verify from a machine that can reach your server:

```bash
curl -sS https://dondevolar.aquiles.dev/health | jq .
```

Internal check before nginx:

```bash
curl -sS http://127.0.0.1:18080/health
# or, from the nginx container on the shared network:
curl -sS http://dondevolar-api:8080/health
```

## Cron (zone feed + weather alerts)

Header `x-cron-secret` must equal **`JWT_SECRET`** from `.env`.

```bash
curl -sS -X POST https://dondevolar.aquiles.dev/v1/cron/zone_ingest \
  -H "x-cron-secret: YOUR_JWT_SECRET"
```

## Flutter app

Release builds default to `https://dondevolar.aquiles.dev` (`lib/config/api_config.dart`).

```bash
flutter run --dart-define=API_BASE_URL=https://dondevolar.aquiles.dev
```

## Local development

Use `backend/docker-compose.yaml` (published ports for Postgres, Photon, etc.).

## Updating

Pull latest Git → **Update the stack** in Portainer (rebuilds `api`). Zone feed is
bind-mounted from `feed/zones.geojson`.
