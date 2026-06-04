import 'dart:io';

/// Ensures [path] exists and is a readable file (not a directory).
///
/// Docker creates an empty **directory** when a bind-mounted file is missing
/// on the host (`errno = 21`). Failing here produces a clear message instead of
/// a cryptic error on first `/health` or `/v1/zones` request.
void validateZoneFeedPath(String path) {
  final type = FileSystemEntity.typeSync(path, followLinks: false);
  if (type == FileSystemEntityType.notFound) {
    throw StateError(
      'Zone feed file not found at $path. '
      'Rebuild the API image (feed/zones.geojson) or run zone ingest.',
    );
  }
  if (type == FileSystemEntityType.directory) {
    throw StateError(
      'ZONE_FEED_PATH must be a file, not a directory: $path. '
      'This usually means the host bind-mount source was missing when the '
      'container started. Remove the directory, restore zones.geojson, and '
      'redeploy (or use an image that bakes the feed in at build time).',
    );
  }
  if (type != FileSystemEntityType.file) {
    throw StateError('ZONE_FEED_PATH is not a regular file: $path');
  }
}
