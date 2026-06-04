import 'package:flutter_test/flutter_test.dart';
import 'package:where_to_fly/map/cubit/map_search_cubit.dart';
import 'package:where_to_fly/map/map_overlay_policy.dart';

void main() {
  const searchWithResults = MapSearchState(showResults: true);

  test('only one legend when both toggles are on', () {
    expect(
      MapOverlayPolicy.showWindLegend(
        windLegendToggleOn: true,
        legendToggleOn: true,
        search: const MapSearchState(),
      ),
      isTrue,
    );
    expect(
      MapOverlayPolicy.showZoneLegend(
        legendToggleOn: true,
        windLegendToggleOn: true,
        search: const MapSearchState(),
      ),
      isFalse,
    );
  });

  test('legends hidden while search results are open', () {
    expect(
      MapOverlayPolicy.showWindLegend(
        windLegendToggleOn: true,
        legendToggleOn: false,
        search: searchWithResults,
      ),
      isFalse,
    );
    expect(
      MapOverlayPolicy.showZoneLegend(
        legendToggleOn: true,
        windLegendToggleOn: false,
        search: searchWithResults,
      ),
      isFalse,
    );
  });

  test('stale banner hidden when search dropdown is open', () {
    expect(
      MapOverlayPolicy.showStaleBanner(
        searchFocused: true,
        search: searchWithResults,
      ),
      isFalse,
    );
    expect(
      MapOverlayPolicy.showStaleBanner(
        searchFocused: true,
        search: const MapSearchState(),
      ),
      isTrue,
    );
  });
}
