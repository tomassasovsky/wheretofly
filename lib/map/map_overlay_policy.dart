import 'package:where_to_fly/map/cubit/map_search_cubit.dart';

/// Rules for which map chrome can be visible at once.
///
/// Avoids accidental overlap between floating panels.
abstract final class MapOverlayPolicy {
  /// At most one legend panel; search results take priority over legends.
  static bool showZoneLegend({
    required bool legendToggleOn,
    required bool windLegendToggleOn,
    required MapSearchState search,
  }) {
    if (search.showResults) return false;
    if (windLegendToggleOn && legendToggleOn) return false;
    return legendToggleOn;
  }

  static bool showWindLegend({
    required bool windLegendToggleOn,
    required bool legendToggleOn,
    required MapSearchState search,
  }) {
    if (search.showResults) return false;
    return windLegendToggleOn;
  }

  /// Stale-zone banner competes with the search dropdown at the top.
  static bool showStaleBanner({
    required bool searchFocused,
    required MapSearchState search,
  }) {
    if (searchFocused && search.showResults) return false;
    return true;
  }
}
