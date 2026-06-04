#!/usr/bin/env bash
# Thin wrapper — all logic lives in tool/capture_store_screenshots.dart.
exec dart run tool/capture_store_screenshots.dart "$@"
