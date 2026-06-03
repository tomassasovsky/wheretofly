import 'dart:async';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';
import 'package:where_to_fly/l10n/gen/app_localizations.dart';
import 'package:where_to_fly/map/map_camera_snapshot.dart';
import 'package:where_to_fly/map/map_config.dart';
import 'package:where_to_fly/map/map_initializer.dart';
import 'package:where_to_fly/map/wind_map_bridge.dart';
import 'package:where_to_fly/map/wind_map_config.dart';
import 'package:where_to_fly/map/wind_map_html_loader.dart';
import 'package:where_to_fly/map/wind_map_om_url_resolver.dart';
import 'package:where_to_fly/map/wind_map_user_message.dart';

/// Imperative handle for [WindMapWebView] camera control.
class WindMapController {
  WebViewController? _webView;
  MapCameraSnapshot? _pendingCamera;

  void registerWebView(WebViewController webView) {
    _webView = webView;
    final pending = _pendingCamera;
    if (pending != null) {
      syncFrom(pending);
    }
  }

  void clearWebView() => _webView = null;

  void syncFrom(MapCameraSnapshot camera) {
    _pendingCamera = camera;
    final webView = _webView;
    if (webView == null) return;
    unawaited(
      webView.runJavaScript(
        WindMapBridgeCommands.setCenter(
          lat: camera.lat,
          lon: camera.lon,
          zoom: camera.zoom,
          instant: true,
        ),
      ),
    );
  }

  Future<void> moveTo({
    required double lat,
    required double lon,
    required double zoom,
    bool instant = false,
  }) async {
    _pendingCamera = MapCameraSnapshot(lat: lat, lon: lon, zoom: zoom);
    final webView = _webView;
    if (webView == null) return;
    await webView.runJavaScript(
      WindMapBridgeCommands.setCenter(
        lat: lat,
        lon: lon,
        zoom: zoom,
        instant: instant,
      ),
    );
  }
}

enum WindMapLoadState { loading, ready, error }

/// Open-Meteo wind gust raster in a WebView (full map or transparent overlay).
class WindMapWebView extends StatefulWidget {
  const WindMapWebView({
    required this.controller,
    required this.brightness,
    this.overlayMode = false,
    this.initialCamera,
    super.key,
  });

  final WindMapController controller;
  final Brightness brightness;

  /// When true, only the gust raster is drawn over the native MapLibre map.
  final bool overlayMode;

  final MapCameraSnapshot? initialCamera;

  @override
  State<WindMapWebView> createState() => _WindMapWebViewState();
}

class _WindMapWebViewState extends State<WindMapWebView> {
  late final WebViewController _webViewController;
  final _omResolver = WindMapOmUrlResolver();

  var _loadState = WindMapLoadState.loading;
  WindMapUserMessage? _fatalError;
  int? _fatalErrorStatusCode;
  WindMapUserMessage? _warningMessage;
  var _pageReady = false;
  var _mapInitStarted = false;
  String? _omSourceUrl;

  @override
  void initState() {
    super.initState();
    _webViewController = _createWebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.transparent)
      ..addJavaScriptChannel(
        'WindMap',
        onMessageReceived: _onBridgeMessage,
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) {
            _pageReady = true;
            unawaited(_tryStartMap());
          },
          onWebResourceError: _onWebResourceError,
        ),
      );
    widget.controller.registerWebView(_webViewController);
    unawaited(_loadShell());
    unawaited(_resolveOmUrl());
  }

  @override
  void didUpdateWidget(WindMapWebView oldWidget) {
    super.didUpdateWidget(oldWidget);
    final camera = widget.initialCamera;
    if (camera != null &&
        camera != oldWidget.initialCamera &&
        _loadState == WindMapLoadState.ready) {
      widget.controller.syncFrom(camera);
    }
  }

  WebViewController _createWebViewController() {
    const params = PlatformWebViewControllerCreationParams();
    if (WebViewPlatform.instance is WebKitWebViewPlatform) {
      return WebViewController.fromPlatformCreationParams(
        WebKitWebViewControllerCreationParams
            .fromPlatformWebViewControllerCreationParams(
          params,
        ),
      );
    }
    if (WebViewPlatform.instance is AndroidWebViewPlatform) {
      final controller = WebViewController.fromPlatformCreationParams(
        AndroidWebViewControllerCreationParams
            .fromPlatformWebViewControllerCreationParams(
          params,
        ),
      );
      final platform = controller.platform;
      if (platform is AndroidWebViewController) {
        unawaited(platform.setMediaPlaybackRequiresUserGesture(false));
      }
      return controller;
    }
    return WebViewController.fromPlatformCreationParams(params);
  }

  @override
  void dispose() {
    widget.controller.clearWebView();
    super.dispose();
  }

  Future<void> _loadShell() async {
    try {
      await WindMapHtmlLoader.load(_webViewController);
    } on Object {
      if (!mounted) return;
      _setFatalError(WindMapUserMessage.openOverlay);
    }
  }

  Future<void> _resolveOmUrl() async {
    try {
      final url = await _omResolver.resolve();
      if (!mounted) return;
      setState(() => _omSourceUrl = url);
      await _tryStartMap();
    } on WindMapResolveException catch (e) {
      if (!mounted) return;
      _setFatalError(
        windMapUserMessageFromResolve(e.code),
        statusCode: e.statusCode,
      );
    } on Object {
      if (!mounted) return;
      _setFatalError(WindMapUserMessage.reachTiles);
    }
  }

  void _onWebResourceError(WebResourceError error) {
    if (error.isForMainFrame == false) {
      if (_loadState == WindMapLoadState.ready) {
        setState(() => _warningMessage = WindMapUserMessage.tileWarning);
      }
      return;
    }
    if (_loadState != WindMapLoadState.ready) {
      _setFatalError(WindMapUserMessage.reachTiles);
    }
  }

  MapCameraSnapshot _initialCamera() {
    return widget.initialCamera ??
        MapCameraSnapshot(
          lat: MapInitializer.argentinaCenter.latitude,
          lon: MapInitializer.argentinaCenter.longitude,
          zoom: MapInitializer.initialZoom,
        );
  }

  Future<void> _tryStartMap() async {
    if (!_pageReady ||
        _omSourceUrl == null ||
        _loadState == WindMapLoadState.error ||
        _mapInitStarted) {
      return;
    }

    var scriptsReady = false;
    for (var attempt = 0; attempt < 30; attempt++) {
      if (!mounted) return;
      final ready = await _webViewController.runJavaScriptReturningResult(
        'window.WindMapApp != null'
        ' && window.maplibregl != null'
        ' && window.OMWeatherMapLayer != null',
      );
      if (_isScriptReady(ready)) {
        scriptsReady = true;
        break;
      }
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }

    if (!mounted) return;
    if (!scriptsReady) {
      _setFatalError(WindMapUserMessage.scriptsNotLoaded);
      return;
    }

    _mapInitStarted = true;
    final camera = _initialCamera();
    await _webViewController.runJavaScript(
      WindMapBridgeCommands.init(
        styleUrl:
            widget.overlayMode ? '' : MapConfig.styleUrlFor(widget.brightness),
        overlayOnly: widget.overlayMode,
        lat: camera.lat,
        lon: camera.lon,
        zoom: camera.zoom,
        shellTimeoutMs: WindMapConfig.shellTimeout.inMilliseconds,
        omSourceUrl: _omSourceUrl,
      ),
    );
  }

  bool _isScriptReady(Object? value) =>
      value == true || value == 1 || value == 'true';

  void _onBridgeMessage(JavaScriptMessage message) {
    try {
      final bridgeMessage = WindMapBridgeMessage.decode(message.message);
      switch (bridgeMessage.type) {
        case WindMapMessageType.mapReady:
          setState(() {
            _loadState = WindMapLoadState.ready;
            _fatalError = null;
            _fatalErrorStatusCode = null;
          });
          final camera = widget.initialCamera;
          if (camera != null) {
            widget.controller.syncFrom(camera);
          }
        case WindMapMessageType.windError:
          setState(() {
            _warningMessage = windMapUserMessageFromCode(
                  bridgeMessage.message,
                ) ??
                WindMapUserMessage.overlayPartialFailed;
          });
        case WindMapMessageType.error:
          _setFatalError(
            windMapUserMessageFromCode(bridgeMessage.message) ??
                WindMapUserMessage.bridgeError,
          );
        case WindMapMessageType.unknown:
          break;
      }
    } on Object {
      _setFatalError(WindMapUserMessage.bridgeError);
    }
  }

  void _setFatalError(
    WindMapUserMessage message, {
    int? statusCode,
  }) {
    if (!mounted) return;
    setState(() {
      _loadState = WindMapLoadState.error;
      _fatalError = message;
      _fatalErrorStatusCode = statusCode;
    });
  }

  Future<void> _reload() async {
    setState(() {
      _loadState = WindMapLoadState.loading;
      _fatalError = null;
      _fatalErrorStatusCode = null;
      _warningMessage = null;
      _pageReady = false;
      _omSourceUrl = null;
      _mapInitStarted = false;
    });
    await _loadShell();
    unawaited(_resolveOmUrl());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final overlay = widget.overlayMode;
    final topInset = MediaQuery.paddingOf(context).top + 72;
    final fatalDetail = _fatalError?.label(
          l10n,
          statusCode: _fatalErrorStatusCode,
        ) ??
        '';
    final warningText = _warningMessage?.label(l10n) ?? '';

    return Stack(
      children: [
        Positioned.fill(
          child: WebViewWidget(controller: _webViewController),
        ),
        if (_loadState == WindMapLoadState.loading)
          Positioned(
            top: overlay ? topInset : null,
            right: overlay ? 12 : null,
            left: overlay ? null : 0,
            bottom: overlay ? null : 0,
            child: overlay
                ? const Padding(
                    padding: EdgeInsets.all(8),
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : const Center(child: CircularProgressIndicator()),
          ),
        if (_loadState == WindMapLoadState.error)
          Positioned(
            top: overlay ? topInset : 0,
            left: 12,
            right: 12,
            bottom: overlay ? null : 0,
            child: overlay
                ? _OverlayBanner(
                    message: l10n.mapWindLoadFailed,
                    detail: fatalDetail,
                    onRetry: () => unawaited(_reload()),
                    retryLabel: l10n.mapWindRetry,
                  )
                : Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.cloud_off_outlined,
                            size: 48,
                            color: theme.colorScheme.error,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            l10n.mapWindLoadFailed,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyLarge,
                          ),
                          if (fatalDetail.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              fatalDetail,
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                          const SizedBox(height: 16),
                          FilledButton.icon(
                            onPressed: () => unawaited(_reload()),
                            icon: const Icon(Icons.refresh),
                            label: Text(l10n.mapWindRetry),
                          ),
                        ],
                      ),
                    ),
                  ),
          ),
        if (_loadState == WindMapLoadState.ready && warningText.isNotEmpty)
          Positioned(
            top: topInset,
            left: 12,
            right: 12,
            child: _OverlayBanner(
              message: warningText,
              detail: '',
            ),
          ),
        if (!overlay)
          Positioned(
            left: 12,
            right: 12,
            bottom: 12,
            child: SafeArea(
              top: false,
              child: Material(
                color: theme.colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.92,
                ),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        l10n.openMeteoAttribution,
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        l10n.weatherDisclaimer,
                        style: theme.textTheme.labelSmall,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _OverlayBanner extends StatelessWidget {
  const _OverlayBanner({
    required this.message,
    required this.detail,
    this.onRetry,
    this.retryLabel,
  });

  final String message;
  final String detail;
  final VoidCallback? onRetry;
  final String? retryLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.errorContainer,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    message,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onErrorContainer,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (detail.isNotEmpty)
                    Text(
                      detail,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onErrorContainer,
                      ),
                    ),
                ],
              ),
            ),
            if (onRetry != null && retryLabel != null)
              TextButton(
                onPressed: onRetry,
                child: Text(retryLabel!),
              ),
          ],
        ),
      ),
    );
  }
}
