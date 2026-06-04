# Home server deployment (Portainer + Nginx Proxy Manager + aquiles.dev)

This stack runs **one public backend** for the Flutter app. Auth, weather, zones,
geocoding, social, and messaging all go through the Dart Frog API on a single
hostname. [Photon](https://github.com/komoot/photon), PostgreSQL, Redis, and
MinIO are sidecars on the Docker network — they are **not** exposed on separate
subdomains.

**TLS and ports 80/443** are handled by **[Nginx Proxy Manager](https://nginxproxymanager.com/)**
(NPM), not by this compose file. You do not need to edit raw nginx configs.

## Subdomains

| Host | Role |
|------|------|
| `dondevolar.aquiles.dev` | Public HTTPS API (NPM → `dondevolar-api:9080`) |

Internal only (no DNS records):

| Service | URL inside compose |
|---------|-------------------|
| Photon | `http://photon:2322` |
| Postgres | `postgres:5432` |
| Redis | `redis:6379` |
| MinIO | `minio:9000` |

## Nginx Proxy Manager

### 1. Join the NPM Docker network

NPM must reach the API container by name. Attach this stack to the **same network**
as your NPM container.

Find NPM’s network:

```bash
docker inspect nginx-proxy-manager --format '{{range $k,$v := .NetworkSettings.Networks}}{{$k}}{{"\n"}}{{end}}'
```

(Replace `nginx-proxy-manager` with your NPM container name if different.)

Copy `docker-compose.override.example.yml` → `docker-compose.override.yml` and set
the external network name (often `npm_default`, `nginx-proxy-manager_default`, or
a custom `proxy` network from your NPM stack).

Redeploy the Dónde Volar stack after adding the override.

### 2. Add a Proxy Host in the NPM UI

**Hosts → Proxy Hosts → Add Proxy Host**

| Field | Value |
|-------|--------|
| Domain Names | `dondevolar.aquiles.dev` |
| Scheme | `http` |
| Forward Hostname / IP | `dondevolar-api` |
| Forward Port | `9080` |
| Cache Assets | Off |
| Block Common Exploits | On (optional) |
| Websockets Support | On (safe default for future routes) |

**SSL** tab:

- SSL Certificate: **Request a new SSL Certificate** (Let’s Encrypt), or use an
  existing wildcard for `*.aquiles.dev`
- Force SSL, HTTP/2, and HSTS — per your preference

Save. NPM terminates HTTPS; the API stays on plain HTTP inside Docker.

### 3. Verify

```bash
curl -sS https://dondevolar.aquiles.dev/health | jq .
```

From the NPM container (optional):

```bash
docker exec nginx-proxy-manager curl -sS http://dondevolar-api:9080/health
```

### If you cannot share a Docker network

Publishing `127.0.0.1:9080` is **not** reachable from NPM in another container
(that loopback is inside each container). Either use the override network above, or:

- Set `API_BIND=0.0.0.0` in `.env` and redeploy, then in NPM forward to your
  **host LAN IP** (e.g. `192.168.1.x`) port `9080`, or
- In Portainer, connect the `dondevolar-api` container to the NPM network manually
  (**Networks** → connect container).

Do not expose Postgres, Redis, MinIO, or Photon on the public internet.

## DNS

```
dondevolar.aquiles.dev  →  <your home public IP>
```

Forward **TCP 80 and 443** to the machine where **NPM** listens (unchanged from your
current setup).

## Portainer

1. Clone this repository on the server (or use Portainer “Git repository” deploy).
2. **Stacks → Add stack** → `deploy/home-server/docker-compose.yml`
3. Copy `.env.example` → `.env` and set `POSTGRES_PASSWORD`, `DATABASE_URL`,
   `JWT_SECRET`, and MinIO keys.
4. Add `docker-compose.override.yml` (NPM network) and redeploy.
5. First Photon start downloads ~3.9 GB Argentina index; geocoding works after
   Photon logs `Listening on http://0.0.0.0:2322/`.

## API port

Default **`9080`** (avoids conflict with other services on `8080`). Change in `.env`:

```bash
API_PORT=9080
PORT=9080
```

Update the NPM **Forward Port** to match.

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
