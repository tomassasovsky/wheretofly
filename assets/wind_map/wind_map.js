/* Wind map shell for Flutter WebView — inlined by WindMapHtmlLoader. */
(function () {
  'use strict';

  var map = null;
  var config = {};
  var shellTimeoutId = null;
  var windCheckTimeoutId = null;
  var windTileErrorTimerId = null;
  var omProtocolRegistered = false;

  function post(type, message) {
    var payload = JSON.stringify({ type: type, message: message || '' });
    if (window.WindMap && window.WindMap.postMessage) {
      window.WindMap.postMessage(payload);
    }
  }

  function clearShellTimeout() {
    if (shellTimeoutId != null) {
      clearTimeout(shellTimeoutId);
      shellTimeoutId = null;
    }
  }

  function clearWindCheckTimeout() {
    if (windCheckTimeoutId != null) {
      clearTimeout(windCheckTimeoutId);
      windCheckTimeoutId = null;
    }
  }

  function clearWindTileErrorTimer() {
    if (windTileErrorTimerId != null) {
      clearTimeout(windTileErrorTimerId);
      windTileErrorTimerId = null;
    }
  }

  function startShellTimeout(ms) {
    clearShellTimeout();
    shellTimeoutId = setTimeout(function () {
      post('error', 'basemap_timeout');
    }, ms || 20000);
  }

  function scheduleWindCheck(ms) {
    clearWindCheckTimeout();
    windCheckTimeoutId = setTimeout(function () {
      if (!map || !map.getSource('open-meteo-wind')) return;
      if (!map.isSourceLoaded('open-meteo-wind')) {
        post('windError', 'wind_tiles_timeout');
      }
    }, ms || 45000);
  }

  function notifyWindReadyIfLoaded() {
    if (!map || !map.getSource('open-meteo-wind')) return;
    if (map.isSourceLoaded('open-meteo-wind')) {
      clearWindCheckTimeout();
      clearWindTileErrorTimer();
      post('windReady', '');
    }
  }

  function scheduleWindTileErrorCheck(ms) {
    clearWindTileErrorTimer();
    windTileErrorTimerId = setTimeout(function () {
      if (!map || !map.getSource('open-meteo-wind')) return;
      if (!map.isSourceLoaded('open-meteo-wind')) {
        post('windError', 'map_tile_error');
      }
    }, ms || 12000);
  }

  function watchWindSourceLoad() {
    map.on('sourcedata', function (e) {
      if (e.sourceId !== 'open-meteo-wind') return;
      notifyWindReadyIfLoaded();
    });
    map.on('idle', notifyWindReadyIfLoaded);
  }

  function destroyMap() {
    clearShellTimeout();
    clearWindCheckTimeout();
    clearWindTileErrorTimer();
    if (map) {
      map.remove();
      map = null;
    }
  }

  function buildOmUrl() {
    if (config.omSourceUrl) {
      return config.omSourceUrl;
    }
    var model = config.model || 'dwd_icon';
    var variable = config.variable || 'wind_gusts_10m';
    var timeStep = config.timeStep || 'current_time_1H';
    return (
      'https://map-tiles.open-meteo.com/data_spatial/' +
      model +
      '/latest.json?time_step=' +
      encodeURIComponent(timeStep) +
      '&variable=' +
      encodeURIComponent(variable)
    );
  }

  function registerOmProtocol() {
    if (omProtocolRegistered) return;
    if (!window.OMWeatherMapLayer || !OMWeatherMapLayer.omProtocol) {
      throw new Error('om_layer_missing');
    }
    maplibregl.addProtocol('om', OMWeatherMapLayer.omProtocol);
    omProtocolRegistered = true;
  }

  function addWindLayer() {
    var omUrl = buildOmUrl();
    registerOmProtocol();
    map.addSource('open-meteo-wind', {
      url: 'om://' + omUrl,
      type: 'raster',
      tileSize: 256,
      maxzoom: 12,
    });
    map.addLayer({
      id: 'open-meteo-wind-layer',
      type: 'raster',
      source: 'open-meteo-wind',
      paint: { 'raster-opacity': 0.85 },
    });
  }

  window.WindMapApp = {
    init: function (options) {
      config = options || {};
      destroyMap();
      startShellTimeout(config.shellTimeoutMs);

      if (!window.maplibregl) {
        post('error', 'maplibre_missing');
        return;
      }

      try {
        var style = config.overlayOnly
          ? { version: 8, sources: {}, layers: [] }
          : config.styleUrl;
        map = new maplibregl.Map({
          container: 'map',
          style: style,
          center: [config.lon, config.lat],
          zoom: config.zoom,
          attributionControl: false,
          fadeDuration: 0,
        });

        map.on('load', function () {
          clearShellTimeout();
          map.resize();
          if (config.overlayOnly) {
            var el = document.getElementById('map');
            if (el) {
              el.style.pointerEvents = 'none';
            }
            map.dragPan.disable();
            map.scrollZoom.disable();
            map.boxZoom.disable();
            map.dragRotate.disable();
            map.keyboard.disable();
            map.doubleClickZoom.disable();
            map.touchZoomRotate.disable();
          }
          try {
            addWindLayer();
            watchWindSourceLoad();
            scheduleWindCheck(config.windCheckTimeoutMs);
          } catch (err) {
            var code =
              err && err.message === 'om_layer_missing'
                ? 'om_layer_missing'
                : 'wind_layer_init_failed';
            post('windError', code);
          }
          post('mapReady');
        });

        map.on('error', function (e) {
          if (e && e.sourceId && e.sourceId !== 'open-meteo-wind') return;
          scheduleWindTileErrorCheck(12000);
        });
      } catch (err) {
        clearShellTimeout();
        var code =
          err && err.message === 'om_layer_missing'
            ? 'om_layer_missing'
            : 'wind_layer_init_failed';
        post('error', code);
      }
    },
    setCenter: function (lat, lon, zoom, instant) {
      if (!map) return;
      if (instant) {
        map.jumpTo({ center: [lon, lat], zoom: zoom });
      } else {
        map.flyTo({ center: [lon, lat], zoom: zoom, duration: 450 });
      }
    },
    zoomBy: function (delta) {
      if (!map) return;
      map.zoomTo(map.getZoom() + delta, { duration: 200 });
    },
  };
})();
