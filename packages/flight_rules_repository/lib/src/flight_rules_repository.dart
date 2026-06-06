import 'package:flight_rules_repository/src/models/altitude_range.dart';
import 'package:flight_rules_repository/src/models/flight_assessment.dart';
import 'package:flight_rules_repository/src/models/flight_modality.dart';
import 'package:flight_rules_repository/src/models/fly_zone.dart';
import 'package:flight_rules_repository/src/models/permission_level.dart';
import 'package:flight_rules_repository/src/models/zone_category.dart';
import 'package:flight_rules_repository/src/zone_deduplicator.dart';
import 'package:latlong2/latlong.dart';
import 'package:zones_api_client/zones_api_client.dart';

/// Repository: loads zone data from the backend feed, maps raw [ZoneData] to
/// domain [FlyZone]s, and applies flight-verdict business rules.
class FlightRulesRepository {
  /// Builds the repository from the bundled offline snapshot (synchronous).
  FlightRulesRepository({
    BundledZonesApiClient bundled = const BundledZonesApiClient(),
  }) : _zones = ZoneDeduplicator.dedupe(bundled.zones).map(_toFlyZone).toList();

  FlightRulesRepository._fromData(List<ZoneData> data)
      : _zones = ZoneDeduplicator.dedupe(data).map(_toFlyZone).toList();

  /// Builds a repository from raw [ZoneData] (tests and tooling).
  factory FlightRulesRepository.fromZoneData(List<ZoneData> data) =>
      FlightRulesRepository._fromData(data);

  final List<FlyZone> _zones;

  /// Loads zones from the backend feed, falling back to [offlineFallback] when
  /// the feed and its local cache are both empty.
  static Future<FlightRulesRepository> load({
    required ZonesFeedClient feed,
    BundledZonesApiClient offlineFallback = const BundledZonesApiClient(),
  }) async {
    final fromFeed = await _safe(feed.fetchZones);
    if (fromFeed.isNotEmpty) {
      return FlightRulesRepository._fromData(fromFeed);
    }
    final fromBundled = await _safe(offlineFallback.fetchZones);
    return FlightRulesRepository._fromData(fromBundled);
  }

  static Future<List<ZoneData>> _safe(
    Future<List<ZoneData>> Function() fetch,
  ) async {
    try {
      return await fetch();
    } catch (_) {
      return const [];
    }
  }

  /// All known zones (domain models).
  List<FlyZone> get zones => List.unmodifiable(_zones);

  /// Returns all zones whose horizontal footprint contains [point].
  List<FlyZone> zonesAt(LatLng point) =>
      _zones.where((z) => z.contains(point)).toList();

  /// Zones that contain [point] and overlap [altitude] vertically.
  List<FlyZone> zonesAtAltitude(
    LatLng point,
    AltitudeRange altitude, {
    double groundElevationMslMeters = 0,
  }) =>
      zonesAt(point)
          .where(
            (z) => z.overlapsAltitudeRange(
              altitude.minMetersAgl,
              altitude.maxMetersAgl,
              groundElevationMslMeters: groundElevationMslMeters,
            ),
          )
          .toList();

  /// Evaluates whether a pilot holding [permission] may fly [modality] at
  /// [point] through [altitudeRange] (takeoff to cruise).
  FlightAssessment assess(
    LatLng point,
    PermissionLevel permission,
    FlightModality modality, {
    AltitudeRange altitudeRange = AltitudeRange.openCategoryDefault,
    double groundElevationMslMeters = 0,
  }) {
    final horizontal = zonesAt(point);
    final hits = zonesAtAltitude(
      point,
      altitudeRange,
      groundElevationMslMeters: groundElevationMslMeters,
    );
    final skippedByAltitude =
        horizontal.where((z) => !hits.contains(z)).toList();
    final modalityAllowed = permission.rank >= modality.minimumPermission.rank;
    final zonesAllowed = hits.every((z) => z.allowsFlightFor(permission));

    final FlightVerdict verdict;
    if (!modalityAllowed || !zonesAllowed) {
      verdict = FlightVerdict.notAllowed;
    } else if (hits.isNotEmpty) {
      verdict = FlightVerdict.allowedWithPermission;
    } else {
      verdict = FlightVerdict.allowed;
    }

    return FlightAssessment(
      permission: permission,
      modality: modality,
      verdict: verdict,
      modalityAllowed: modalityAllowed,
      altitudeRange: altitudeRange,
      zones: hits,
      skippedByAltitude: skippedByAltitude,
    );
  }

  static FlyZone _toFlyZone(ZoneData data) => FlyZone(
        id: data.id,
        name: data.name,
        category: ZoneCategory.fromId(data.categoryId),
        center: LatLng(data.latitude, data.longitude),
        radiusMeters: data.radiusMeters,
        boundary: data.polygon
            ?.map((p) => LatLng(p[1], p[0]))
            .toList(growable: false),
        permissionsThatAllowFlight:
            data.allowedPermissionIds.map(PermissionLevel.fromId).toSet(),
        details: data.details,
        lowerLimitMetersAgl: data.lowerLimitMetersAgl,
        upperLimitMetersAgl: data.upperLimitMetersAgl,
        lowerLimitMetersMsl: data.lowerLimitMetersMsl,
        upperLimitMetersMsl: data.upperLimitMetersMsl,
      );
}
