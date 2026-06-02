/// Standard permission id sets used when mapping raw zone feeds.
abstract final class ZonePermissionIds {
  /// Controlled airspace and similar: Specific Category authorization may
  /// operate here after coordination; site clearance also accepted.
  static const controlledAirspace = {
    'authorized_commercial',
    'special_permit',
  };

  /// Parks, prohibited-adjacent sites, etc.: case-by-case clearance only.
  static const siteClearanceOnly = {'special_permit'};

  static const none = <String>{};
}
