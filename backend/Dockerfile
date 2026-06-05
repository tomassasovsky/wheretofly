# Build from the repository root (monorepo path dependencies):
#   docker build -f backend/Dockerfile .
#
# Portainer / deploy/home-server compose sets context: ../.. (repo root).

FROM dart:stable AS build

WORKDIR /workspace

# Path-dependency packages (backend/pubspec.yaml → ../packages/…)
COPY packages/argentina_bounds/pubspec.yaml packages/argentina_bounds/
COPY packages/zones_api_client/pubspec.yaml packages/zones_api_client/
COPY tooling/om_smoke/pubspec.yaml tooling/om_smoke/
COPY tooling/om_tile_server/pubspec.yaml tooling/om_tile_server/
COPY backend/pubspec.yaml backend/

WORKDIR /workspace/backend
RUN dart pub get

# Destinations must be absolute: WORKDIR is backend/, but path deps live in ../packages/.
COPY packages/argentina_bounds /workspace/packages/argentina_bounds
COPY packages/zones_api_client /workspace/packages/zones_api_client
COPY tooling/om_smoke /workspace/tooling/om_smoke
COPY tooling/om_tile_server /workspace/tooling/om_tile_server
COPY assets/om /workspace/assets/om
COPY backend /workspace/backend

WORKDIR /workspace/backend
RUN dart run wasm_run:setup

# Never reuse a host-generated build/ (path deps differ inside Docker).
RUN rm -rf build .dart_frog

RUN dart pub global activate dart_frog_cli
ENV PATH="$PATH:/root/.pub-cache/bin"
RUN dart_frog build
# dart_frog binds anyIPv6 (:::port); Docker/NPM reach the container over IPv4.
RUN sed -i 's/InternetAddress\.anyIPv6/InternetAddress.anyIPv4/' build/bin/server.dart
RUN dart compile exe build/bin/server.dart -o server

FROM debian:bookworm-slim
RUN apt-get update && apt-get install -y ca-certificates wget && rm -rf /var/lib/apt/lists/*
WORKDIR /app
COPY --from=build /workspace/backend/server /app/server
COPY --from=build /workspace/backend/lib/db/migrations /app/lib/db/migrations
COPY --from=build /workspace/assets/om /app/assets/om
COPY --from=build /workspace/backend/.dart_tool/wasm_run/libwasm_run_dart.so /app/libwasm_run_dart.so
COPY feed/zones.geojson /app/data/zones.geojson
ENV PORT=9080
ENV WIND_OM_WASM_PATH=/app/assets/om/om_reader_wasm.wasm
ENV WASM_RUN_DART_DYNAMIC_LIBRARY=/app/libwasm_run_dart.so
EXPOSE 9080
CMD ["/app/server"]
