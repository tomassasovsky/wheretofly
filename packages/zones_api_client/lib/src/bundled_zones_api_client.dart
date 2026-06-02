import 'package:zones_api_client/src/madhel_aerodromes.g.dart';
import 'package:zones_api_client/src/models/zone_data.dart';
import 'package:zones_api_client/src/remote_zones_api_client.dart'
    show RemoteZonesApiClient;
import 'package:zones_api_client/zones_api_client.dart'
    show RemoteZonesApiClient;

/// Data client that provides a bundled, offline snapshot of Argentine
/// drone-restriction zones, including the full ANAC MADHEL aerodrome catalog.
///
/// Aerodrome/heliport coordinates come from MADHEL; parks, government sites, and
/// infrastructure are curated manually. Always confirm against ANAC NOTAMs/AIP
/// before flying. Framework: Resolución ANAC 550/2025 and RAAC 100.
class BundledZonesApiClient {
  const BundledZonesApiClient();

  /// The bundled zones (synchronous).
  List<ZoneData> get zones => _zones;

  /// Async surface mirroring [RemoteZonesApiClient].
  Future<List<ZoneData>> fetchZones() async => _zones;

  static const _special = {'special_permit'};
  static const _none = <String>{};

  static ZoneData _park(
    String id,
    String name,
    double lat,
    double lon,
    double radius,
  ) =>
      ZoneData(
        id: id,
        name: name,
        categoryId: 'national_park',
        latitude: lat,
        longitude: lon,
        radiusMeters: radius,
        allowedPermissionIds: _special,
        details: 'Área protegida (Administración de Parques Nacionales). '
            'Vuelo de drones prohibido salvo permiso del organismo.',
      );

  static final List<ZoneData> _madhelAerodromes = loadBundledMadhelAerodromes();

  static final List<ZoneData> _zones = [
    // ----------------------------------------------------------------
    // Aerodromes / heliports — full ANAC MADHEL catalog (offline snapshot).
    // Regenerate: dart run packages/zones_api_client/tool/import_madhel.dart
    // ----------------------------------------------------------------
    ..._madhelAerodromes,

    // ----------------------------------------------------------------
    // Prohibited — national security / government / defence.
    // ----------------------------------------------------------------
    const ZoneData(
      id: 'prohibited_casa_rosada',
      name: 'Casa Rosada y Plaza de Mayo',
      categoryId: 'prohibited',
      latitude: -34.6080,
      longitude: -58.3702,
      radiusMeters: 700,
      allowedPermissionIds: _none,
      details: 'Sede del Poder Ejecutivo Nacional. Vuelo prohibido por '
          'seguridad.',
    ),
    const ZoneData(
      id: 'prohibited_quinta_olivos',
      name: 'Quinta de Olivos',
      categoryId: 'prohibited',
      latitude: -34.5093,
      longitude: -58.4856,
      radiusMeters: 2000,
      allowedPermissionIds: _none,
      details: 'Residencia presidencial. Vuelo prohibido por seguridad.',
    ),
    const ZoneData(
      id: 'prohibited_congreso',
      name: 'Congreso de la Nación',
      categoryId: 'prohibited',
      latitude: -34.6097,
      longitude: -58.3925,
      radiusMeters: 1000,
      allowedPermissionIds: _none,
      details: 'Edificio del Poder Legislativo Nacional.',
    ),
    const ZoneData(
      id: 'prohibited_campo_de_mayo',
      name: 'Campo de Mayo (guarnición militar)',
      categoryId: 'prohibited',
      latitude: -34.5200,
      longitude: -58.6700,
      radiusMeters: 6000,
      allowedPermissionIds: _none,
      details: 'Guarnición militar. Zona de defensa.',
    ),
    const ZoneData(
      id: 'military_puerto_belgrano',
      name: 'Base Naval Puerto Belgrano',
      categoryId: 'prohibited',
      latitude: -38.8950,
      longitude: -62.0950,
      radiusMeters: 8000,
      allowedPermissionIds: _none,
      details: 'Principal base naval del país. Zona de defensa.',
    ),

    // ----------------------------------------------------------------
    // Restricted — penitentiaries / security forces.
    // ----------------------------------------------------------------
    const ZoneData(
      id: 'restricted_penal_ezeiza',
      name: 'Complejo Penitenciario Federal de Ezeiza',
      categoryId: 'restricted',
      latitude: -34.8550,
      longitude: -58.5200,
      radiusMeters: 3000,
      allowedPermissionIds: _special,
      details: 'Establecimiento penitenciario federal. Zona restringida.',
    ),
    const ZoneData(
      id: 'military_moron',
      name: 'Guarnición Aérea Morón',
      categoryId: 'restricted',
      latitude: -34.6760,
      longitude: -58.6430,
      radiusMeters: 5000,
      allowedPermissionIds: _special,
      details: 'Instalación militar. Zona restringida.',
    ),

    // ----------------------------------------------------------------
    // Critical infrastructure.
    // ----------------------------------------------------------------
    const ZoneData(
      id: 'infra_atucha',
      name: 'Central Nuclear Atucha',
      categoryId: 'sensitive_infrastructure',
      latitude: -33.9670,
      longitude: -59.2030,
      radiusMeters: 5000,
      allowedPermissionIds: _none,
      details: 'Complejo nuclear. Infraestructura crítica de seguridad.',
    ),
    const ZoneData(
      id: 'infra_embalse',
      name: 'Central Nuclear Embalse',
      categoryId: 'sensitive_infrastructure',
      latitude: -32.2300,
      longitude: -64.4400,
      radiusMeters: 5000,
      allowedPermissionIds: _none,
      details: 'Central nuclear de Córdoba. Infraestructura crítica.',
    ),
    const ZoneData(
      id: 'infra_yacyreta',
      name: 'Represa de Yacyretá',
      categoryId: 'sensitive_infrastructure',
      latitude: -27.4830,
      longitude: -56.7170,
      radiusMeters: 6000,
      allowedPermissionIds: _none,
      details: 'Represa hidroeléctrica binacional. Infraestructura crítica.',
    ),
    const ZoneData(
      id: 'infra_salto_grande',
      name: 'Represa de Salto Grande',
      categoryId: 'sensitive_infrastructure',
      latitude: -31.2670,
      longitude: -57.9460,
      radiusMeters: 5000,
      allowedPermissionIds: _none,
      details: 'Represa hidroeléctrica binacional. Infraestructura crítica.',
    ),

    // ----------------------------------------------------------------
    // National parks / protected areas (APN) — all 35 national parks.
    // Coordinates from APN / Wikipedia. Vuelo prohibido salvo permiso.
    // ----------------------------------------------------------------
    _park('park_aconquija', 'Parque Nacional Aconquija', -26.48, -65.20, 15000),
    _park('park_baritu', 'Parque Nacional Baritú', -22.58, -64.62, 15000),
    _park(
      'park_bosques_jaramillo',
      'Parque Nacional Bosques Petrificados de Jaramillo',
      -47.67,
      -68.09,
      12000,
    ),
    _park('park_calilegua', 'Parque Nacional Calilegua', -23.69, -64.79, 15000),
    _park(
      'park_campos_tuyu',
      'Parque Nacional Campos del Tuyú',
      -36.35,
      -56.87,
      6000,
    ),
    _park('park_chaco', 'Parque Nacional Chaco', -26.83, -59.66, 8000),
    _park('park_copo', 'Parque Nacional Copo', -25.85, -61.91, 18000),
    _park(
      'park_el_impenetrable',
      'Parque Nacional El Impenetrable',
      -24.99,
      -61.08,
      20000,
    ),
    _park(
      'park_el_leoncito',
      'Parque Nacional El Leoncito',
      -31.92,
      -69.24,
      15000,
    ),
    _park('park_el_palmar', 'Parque Nacional El Palmar', -31.87, -58.25, 8000),
    _park('park_el_rey', 'Parque Nacional El Rey', -24.67, -64.63, 12000),
    _park('park_ibera', 'Parque Nacional Iberá', -27.93, -59.07, 25000),
    _park('park_iguazu', 'Parque Nacional Iguazú', -25.64, -54.34, 15000),
    _park(
      'park_islas_santa_fe',
      'Parque Nacional Islas de Santa Fe',
      -32.27,
      -60.71,
      6000,
    ),
    _park(
      'park_islote_lobos',
      'Parque Nacional Islote Lobos',
      -41.44,
      -65.06,
      8000,
    ),
    _park(
      'park_lago_puelo',
      'Parque Nacional Lago Puelo',
      -42.17,
      -71.69,
      12000,
    ),
    _park(
      'park_laguna_blanca',
      'Parque Nacional Laguna Blanca',
      -39.03,
      -70.35,
      8000,
    ),
    _park('park_lanin', 'Parque Nacional Lanín', -39.89, -71.48, 35000),
    _park(
      'park_lihue_calel',
      'Parque Nacional Lihué Calel',
      -37.95,
      -65.61,
      12000,
    ),
    _park(
      'park_los_alerces',
      'Parque Nacional Los Alerces',
      -42.87,
      -71.87,
      30000,
    ),
    _park(
      'park_los_arrayanes',
      'Parque Nacional Los Arrayanes',
      -40.83,
      -71.61,
      6000,
    ),
    _park(
      'park_los_cardones',
      'Parque Nacional Los Cardones',
      -25.28,
      -65.92,
      15000,
    ),
    _park(
      'park_los_glaciares',
      'Parque Nacional Los Glaciares',
      -50,
      -73.13,
      40000,
    ),
    _park('park_mburucuya', 'Parque Nacional Mburucuyá', -28.02, -58.07, 8000),
    _park(
      'park_monte_leon',
      'Parque Nacional Monte León',
      -50.34,
      -68.90,
      12000,
    ),
    _park(
      'park_nahuel_huapi',
      'Parque Nacional Nahuel Huapi',
      -40.87,
      -71.49,
      35000,
    ),
    _park('park_patagonia', 'Parque Nacional Patagonia', -47.16, -71.32, 15000),
    _park(
      'park_perito_moreno',
      'Parque Nacional Perito Moreno',
      -47.92,
      -72.25,
      20000,
    ),
    _park('park_predelta', 'Parque Nacional Predelta', -32.15, -60.63, 6000),
    _park(
      'park_quebrada_condorito',
      'Parque Nacional Quebrada del Condorito',
      -31.67,
      -64.77,
      15000,
    ),
    _park(
      'park_rio_pilcomayo',
      'Parque Nacional Río Pilcomayo',
      -25.05,
      -58.13,
      12000,
    ),
    _park(
      'park_san_guillermo',
      'Parque Nacional San Guillermo',
      -29.31,
      -69.29,
      20000,
    ),
    _park(
      'park_sierra_quijadas',
      'Parque Nacional Sierra de las Quijadas',
      -32.55,
      -67.12,
      15000,
    ),
    _park('park_talampaya', 'Parque Nacional Talampaya', -29.90, -68.01, 20000),
    _park(
      'park_tierra_del_fuego',
      'Parque Nacional Tierra del Fuego',
      -54.65,
      -68.47,
      15000,
    ),
    _park(
      'park_traslasierra',
      'Parque Nacional Traslasierra',
      -31.15,
      -65.49,
      15000,
    ),
  ];
}
