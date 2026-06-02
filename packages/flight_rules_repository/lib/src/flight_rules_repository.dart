import 'package:flight_rules_repository/src/models/altitude_range.dart';
import 'package:flight_rules_repository/src/models/flight_assessment.dart';
import 'package:flight_rules_repository/src/models/flight_modality.dart';
import 'package:flight_rules_repository/src/models/fly_zone.dart';
import 'package:flight_rules_repository/src/models/permission_level.dart';
import 'package:flight_rules_repository/src/models/zone_category.dart';
import 'package:flight_rules_repository/src/zone_deduplicator.dart';
import 'package:latlong2/latlong.dart';
import 'package:zones_api_client/zones_api_client.dart';

/// Repository: composes the zone data clients (bundled + optional remote feed),
/// maps raw [ZoneData] to domain [FlyZone]s, and applies the flight-verdict
/// business rules for a given permission level and flight modality.
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

  /// Loads zones from the live sources and merges them, falling back to the
  /// bundled offline snapshot when no source returns data.
  ///
  /// Both a self-hosted [geojson] feed, an [openaip] airspace feed, and the
  /// official [madhel] aerodrome catalog can be supplied; live results overlay
  /// the bundled offline snapshot by id. Any source that errors is ignored so
  /// the app always ends up with data.
  static Future<FlightRulesRepository> load({
    ZonesFeedClient? geojson,
    OpenAipZonesApiClient? openaip,
    MadhelZonesApiClient? madhel,
    BundledZonesApiClient bundled = const BundledZonesApiClient(),
  }) async {
    final fromGeojson =
        geojson == null ? <ZoneData>[] : await _safe(geojson.fetchZones);
    final fromOpenAip =
        openaip == null ? <ZoneData>[] : await _safe(openaip.fetchZones);
    final fromMadhel =
        madhel == null ? <ZoneData>[] : await _safe(madhel.fetchZones);

    final bundledZones = await bundled.fetchZones();
    final merged = <String, ZoneData>{
      for (final zone in bundledZones) zone.id: zone,
    };
    for (final zone in [...fromMadhel, ...fromGeojson, ...fromOpenAip]) {
      merged[zone.id] = zone;
    }

    return FlightRulesRepository._fromData(merged.values.toList());
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
        permissionsThatAllowFlight:
            data.allowedPermissionIds.map(PermissionLevel.fromId).toSet(),
        details: data.details,
        lowerLimitMetersAgl: data.lowerLimitMetersAgl,
        upperLimitMetersAgl: data.upperLimitMetersAgl,
        lowerLimitMetersMsl: data.lowerLimitMetersMsl,
        upperLimitMetersMsl: data.upperLimitMetersMsl,
      );
}
