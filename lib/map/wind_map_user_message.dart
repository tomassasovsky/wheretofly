import 'package:where_to_fly/l10n/gen/app_localizations.dart';
import 'package:where_to_fly/map/wind_map_om_url_resolver.dart';

/// Stable codes posted from the wind WebView or resolver.
abstract final class WindMapMessageCode {
  static const basemapTimeout = 'basemap_timeout';
  static const windTilesTimeout = 'wind_tiles_timeout';
  static const maplibreMissing = 'maplibre_missing';
  static const omLayerMissing = 'om_layer_missing';
  static const scriptsNotLoaded = 'scripts_not_loaded';
  static const windLayerInitFailed = 'wind_layer_init_failed';
  static const mapTileError = 'map_tile_error';
}

/// User-visible wind map errors localized via [label].
enum WindMapUserMessage {
  openOverlay,
  reachTiles,
  scriptsNotLoaded,
  bridgeError,
  metadataFailed,
  variableNotInFeed,
  overlayPartialFailed,
  basemapTimeout,
  windTilesTimeout,
  maplibreMissing,
  omLayerMissing,
  windLayerInitFailed,
  mapTileError,
  tileWarning,
}

extension WindMapUserMessageL10n on WindMapUserMessage {
  String label(AppLocalizations l10n, {int? statusCode}) => switch (this) {
        WindMapUserMessage.openOverlay => l10n.mapWindErrorOpenOverlay,
        WindMapUserMessage.reachTiles => l10n.mapWindErrorReachTiles,
        WindMapUserMessage.scriptsNotLoaded => l10n.mapWindScriptsNotLoaded,
        WindMapUserMessage.bridgeError => l10n.mapWindBridgeError,
        WindMapUserMessage.metadataFailed => l10n.mapWindMetadataFailed(
            statusCode ?? 0,
          ),
        WindMapUserMessage.variableNotInFeed => l10n.mapWindVariableNotInFeed,
        WindMapUserMessage.overlayPartialFailed =>
          l10n.mapWindOverlayPartialFailed,
        WindMapUserMessage.basemapTimeout => l10n.mapWindBasemapTimeout,
        WindMapUserMessage.windTilesTimeout => l10n.mapWindTilesTimeout,
        WindMapUserMessage.maplibreMissing => l10n.mapWindMaplibreMissing,
        WindMapUserMessage.omLayerMissing => l10n.mapWindOmLayerMissing,
        WindMapUserMessage.windLayerInitFailed =>
          l10n.mapWindOverlayPartialFailed,
        WindMapUserMessage.mapTileError => l10n.mapWindOverlayPartialFailed,
        WindMapUserMessage.tileWarning => l10n.mapWindTileWarning,
      };
}

WindMapUserMessage? windMapUserMessageFromCode(String? code) {
  return switch (code) {
    WindMapMessageCode.basemapTimeout => WindMapUserMessage.basemapTimeout,
    WindMapMessageCode.windTilesTimeout => WindMapUserMessage.windTilesTimeout,
    WindMapMessageCode.maplibreMissing => WindMapUserMessage.maplibreMissing,
    WindMapMessageCode.omLayerMissing => WindMapUserMessage.omLayerMissing,
    WindMapMessageCode.scriptsNotLoaded => WindMapUserMessage.scriptsNotLoaded,
    WindMapMessageCode.windLayerInitFailed =>
      WindMapUserMessage.windLayerInitFailed,
    WindMapMessageCode.mapTileError => WindMapUserMessage.mapTileError,
    _ => null,
  };
}

WindMapUserMessage windMapUserMessageFromResolve(WindMapResolveCode code) =>
    switch (code) {
      WindMapResolveCode.metadataFailed => WindMapUserMessage.metadataFailed,
      WindMapResolveCode.variableNotInFeed =>
        WindMapUserMessage.variableNotInFeed,
    };
