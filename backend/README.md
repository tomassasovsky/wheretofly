# Dónde Volar API (Dart Frog)

Self-hosted backend for weather, social features, hybrid zone sync, and messaging.

## Stack

- **Dart Frog** — HTTP + WebSocket routes
- **PostgreSQL** — users, posts, messages, flight logs
- **Redis** — cache / pub-sub (compose service ready)
- **MinIO** — photo/video storage
- **Docker Compose** — home server deployment

## Local development

```bash
cd backend
docker compose up -d postgres redis minio
dart pub get
export DATABASE_URL=postgresql://dondevolar:dondevolar@localhost:5432/dondevolar
export JWT_SECRET=dev-secret
dart_frog dev
```

Health check: `GET http://localhost:8080/health`

## Production (home server)

1. Set `JWT_SECRET`, `OPENWEATHER_API_KEY`, and OAuth client IDs in `.env`
2. Point a domain at your server and configure `Caddyfile`
3. Run `docker compose up -d`

## API overview

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| GET | `/health` | No | Version + zone feed metadata |
| POST | `/v1/auth/signup` | No | Register |
| POST | `/v1/auth/login` | No | Login |
| POST | `/v1/auth/refresh` | No | Refresh tokens |
| GET | `/v1/weather?lat=&lon=` | Yes | Weather proxy + advisory |
| GET | `/v1/zones` | Yes | GeoJSON zone feed (ETag) |
| GET/POST | `/v1/posts` | Yes | Feed / create post |
| GET | `/v1/users/:handle` | Yes | Public profile |
| POST | `/v1/users/:handle/follow` | Yes | Follow user |
| POST/GET | `/v1/messages/:threadId` | Yes | DM / group messages |

Map + offline zone checks remain in the Flutter app without an account.
