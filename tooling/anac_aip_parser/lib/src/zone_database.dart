import 'aip_zone.dart';

// Source: ANAC Argentina AIP, ENR 2.1 (Espacio Aéreo Controlado) and AD
// sections, corroborated against IVAO Argentina ATC briefings
// (https://files.ar.ivao.aero/ATC/Fichas/) and VATSUR TMA BAIRES manual
// (https://argentina.vatsur.org/web/docs/Manual de Operaciones TMA Baires
// V1.3.2.pdf). Coordinates in DDMMSS[NS]-DDDMMSS[EW] (AIP format).
//
// AIRAC cycle: verify against ais.anac.gob.ar after each 28-day cycle.
// Last cross-checked: 2026-06.

const String _controlled = 'controlled_airspace';
const String _restricted = 'restricted';
const Set<String> _ctrlPerms = {'controlled_airspace'};
const Set<String> _restrictPerms = {'controlled_airspace'};

// Reference navaid used throughout the Buenos Aires TMA:
// VOR/DME EZE  344927S-0583207W  (34°49'27"S 058°32'07"W)
const String _eze = 'VOR/DME EZE (344927S-0583207W)';

/// All hardcoded ANAC AIP zone entries.
///
/// Extend this list as more AIP sections are transcribed. To add a zone, paste
/// the "Límites laterales" text from the AIP PDF verbatim as [boundaryText].
const List<AipZoneEntry> zoneDatabase = [
  // -------------------------------------------------------------------------
  // TMA BAIRES — Terminal Manoeuvring Area covering Buenos Aires basin
  // ENR 2.1 — Class C/D, FL045 / FL245 (lower sectors vary)
  // -------------------------------------------------------------------------
  AipZoneEntry(
    id: 'anac_tma_baires',
    name: 'TMA BAIRES',
    categoryId: _controlled,
    allowedPermissionIds: _ctrlPerms,
    lowerLimitMetersMsl: 45 * 30.48,  // FL045 ≈ 1372 m MSL
    upperLimitMetersMsl: 245 * 30.48, // FL245 ≈ 7468 m MSL
    details: 'Terminal Manoeuvring Area Buenos Aires. Class C. '
        'Vuelo de drones requiere autorización de Ezeiza Control.',
    // Límites laterales (from ENR 2.1):
    boundaryText: '''
      335428S-0582732W, 335958S-0582402W, 343458S-0575002W,
      345258S-0570602W, 350358S-0564302W, 350358S-0572802W,
      siguiendo un arco de 55 NM de radio con centro en $eze
      hacia el SO hasta 335428S-0582732W.
    ''',
  ),

  // -------------------------------------------------------------------------
  // CTR EZEIZA (SAEZ) — Aeropuerto Internacional Ministro Pistarini
  // ENR 2.1 — Class D, GND / FL055
  // -------------------------------------------------------------------------
  AipZoneEntry(
    id: 'anac_ctr_saez',
    name: 'CTR EZEIZA',
    categoryId: _controlled,
    allowedPermissionIds: _ctrlPerms,
    lowerLimitMetersAgl: 0,
    upperLimitMetersMsl: 55 * 30.48, // FL055 ≈ 1676 m MSL
    details: 'CTR Aeropuerto Internacional Ezeiza (SAEZ). Clase D. '
        'Drones prohibidos sin autorización expresa de ANAC y del aeródromo.',
    // Límites laterales (ENR 2.1 + IVAO SAEZ briefing v1.4):
    boundaryText: '''
      343658S-0582802W, 345258S-0580802W,
      siguiendo un arco de 20 NM de radio con centro en $eze
      hacia el Sur hasta 344158S-0585420W,
      344304S-0584320W, 343734S-0584308W,
      343810S-0583514W hasta 343658S-0582802W.
    ''',
  ),

  // -------------------------------------------------------------------------
  // CTR AEROPARQUE (SABE) — Aeroparque Jorge Newbery
  // ENR 2.1 — Class D, GND / 2500 ft MSL
  // -------------------------------------------------------------------------
  AipZoneEntry(
    id: 'anac_ctr_sabe',
    name: 'CTR AEROPARQUE',
    categoryId: _controlled,
    allowedPermissionIds: _ctrlPerms,
    lowerLimitMetersAgl: 0,
    upperLimitMetersMsl: 2500 * 0.3048, // 2500 ft MSL ≈ 762 m
    details: 'CTR Aeroparque Jorge Newbery (SABE). Clase D. '
        'Drones prohibidos sin autorización.',
    // Límites laterales (ENR 2.1 + IVAO SABE briefing v1.1):
    // Eastern boundary follows the EZEIZA/MONTEVIDEO FIR limit (Río de la Plata).
    boundaryText: '''
      341846S-0584608W,
      siguiendo un arco de 33 NM de radio con centro en $eze
      hacia el Este hasta 342058S-0581202W,
      342058S-0580302W,
      siguiendo el límite FIR hacia el Sur hasta 343058S-0575402W,
      343058S-0583902W, 342458S-0585202W,
      341846S-0584608W.
    ''',
  ),

  // -------------------------------------------------------------------------
  // CTR SAUCE VIEJO (SAAV) — Santa Fe
  // ENR 2.1 — Class D, GND / 2000 ft AGL
  // -------------------------------------------------------------------------
  AipZoneEntry(
    id: 'anac_ctr_saav',
    name: 'CTR SAUCE VIEJO',
    categoryId: _controlled,
    allowedPermissionIds: _ctrlPerms,
    lowerLimitMetersAgl: 0,
    upperLimitMetersAgl: 2000 * 0.3048, // 2000 ft AGL ≈ 610 m
    details: 'CTR Aeropuerto Sauce Viejo (SAAV), Santa Fe. Clase D.',
    // Simplified circular approximation — transcribe from ENR 2.1 to improve.
    boundaryText: '''
      siguiendo una circunferencia de 5 NM de radio con centro en
      312156S-0604959W.
    ''',
  ),

  // -------------------------------------------------------------------------
  // CTR CÓRDOBA (SACO) — Ingeniero Ambrosio L.V. Taravella
  // ENR 2.1 — Class D, GND / FL065
  // -------------------------------------------------------------------------
  AipZoneEntry(
    id: 'anac_ctr_saco',
    name: 'CTR CÓRDOBA',
    categoryId: _controlled,
    allowedPermissionIds: _ctrlPerms,
    lowerLimitMetersAgl: 0,
    upperLimitMetersMsl: 65 * 30.48, // FL065 ≈ 1981 m MSL
    details: 'CTR Aeropuerto Córdoba (SACO). Clase D.',
    // From ENR 2.1 — primarily defined by a circular arc around the airport.
    boundaryText: '''
      siguiendo una circunferencia de 8 NM de radio con centro en
      310031S-0641218W.
    ''',
  ),

  // -------------------------------------------------------------------------
  // CTR MENDOZA (SAME) — El Plumerillo
  // ENR 2.1 — Class D, GND / FL065
  // -------------------------------------------------------------------------
  AipZoneEntry(
    id: 'anac_ctr_same',
    name: 'CTR MENDOZA',
    categoryId: _controlled,
    allowedPermissionIds: _ctrlPerms,
    lowerLimitMetersAgl: 0,
    upperLimitMetersMsl: 65 * 30.48,
    details: 'CTR Aeropuerto Mendoza (SAME). Clase D.',
    boundaryText: '''
      siguiendo una circunferencia de 8 NM de radio con centro en
      325020S-0684706W.
    ''',
  ),

  // -------------------------------------------------------------------------
  // CTR ROSARIO (SAAR) — Islas Malvinas
  // ENR 2.1 — Class D, GND / FL055
  // -------------------------------------------------------------------------
  AipZoneEntry(
    id: 'anac_ctr_saar',
    name: 'CTR ROSARIO',
    categoryId: _controlled,
    allowedPermissionIds: _ctrlPerms,
    lowerLimitMetersAgl: 0,
    upperLimitMetersMsl: 55 * 30.48,
    details: 'CTR Aeropuerto Rosario (SAAR). Clase D.',
    boundaryText: '''
      siguiendo una circunferencia de 8 NM de radio con centro en
      325357S-0604630W.
    ''',
  ),

  // -------------------------------------------------------------------------
  // CTR MAR DEL PLATA (SAZM)
  // ENR 2.1 — Class D, GND / FL055
  // -------------------------------------------------------------------------
  AipZoneEntry(
    id: 'anac_ctr_sazm',
    name: 'CTR MAR DEL PLATA',
    categoryId: _controlled,
    allowedPermissionIds: _ctrlPerms,
    lowerLimitMetersAgl: 0,
    upperLimitMetersMsl: 55 * 30.48,
    details: 'CTR Aeropuerto Mar del Plata (SAZM). Clase D.',
    boundaryText: '''
      siguiendo una circunferencia de 7 NM de radio con centro en
      375405S-0574346W.
    ''',
  ),

  // -------------------------------------------------------------------------
  // CTR NEUQUÉN (SAZN)
  // ENR 2.1 — Class D, GND / FL055
  // -------------------------------------------------------------------------
  AipZoneEntry(
    id: 'anac_ctr_sazn',
    name: 'CTR NEUQUÉN',
    categoryId: _controlled,
    allowedPermissionIds: _ctrlPerms,
    lowerLimitMetersAgl: 0,
    upperLimitMetersMsl: 55 * 30.48,
    details: 'CTR Aeropuerto Neuquén (SAZN). Clase D.',
    boundaryText: '''
      siguiendo una circunferencia de 7 NM de radio con centro en
      385651S-0681002W.
    ''',
  ),

  // -------------------------------------------------------------------------
  // CTR BARILOCHE (SAZB)
  // ENR 2.1 — Class D, GND / FL075 (terrain-adjusted)
  // -------------------------------------------------------------------------
  AipZoneEntry(
    id: 'anac_ctr_sazb',
    name: 'CTR BARILOCHE',
    categoryId: _controlled,
    allowedPermissionIds: _ctrlPerms,
    lowerLimitMetersAgl: 0,
    upperLimitMetersMsl: 75 * 30.48,
    details: 'CTR Aeropuerto Bariloche (SAZB). Clase D.',
    boundaryText: '''
      siguiendo una circunferencia de 7 NM de radio con centro en
      411849S-0712502W.
    ''',
  ),

  // -------------------------------------------------------------------------
  // CTR TUCUMÁN (SANT) — Teniente Benjamín Matienzo
  // ENR 2.1 — Class D, GND / FL055
  // -------------------------------------------------------------------------
  AipZoneEntry(
    id: 'anac_ctr_sant',
    name: 'CTR TUCUMÁN',
    categoryId: _controlled,
    allowedPermissionIds: _ctrlPerms,
    lowerLimitMetersAgl: 0,
    upperLimitMetersMsl: 55 * 30.48,
    details: 'CTR Aeropuerto Tucumán (SANT). Clase D.',
    boundaryText: '''
      siguiendo una circunferencia de 7 NM de radio con centro en
      264937S-0650553W.
    ''',
  ),

  // -------------------------------------------------------------------------
  // SAR — Restricted Zones (selected; expand from ENR 5.1)
  // -------------------------------------------------------------------------

  // SAR 1 — Área Restringida Capital Federal (military airspace Buenos Aires)
  AipZoneEntry(
    id: 'anac_sar_01',
    name: 'SAR 01 Capital Federal',
    categoryId: _restricted,
    allowedPermissionIds: _restrictPerms,
    lowerLimitMetersAgl: 0,
    upperLimitMetersMsl: 600 * 0.3048, // 600 ft MSL
    details: 'Zona Restringida SAR 01 Capital Federal. '
        'ENR 5.1. Restricción de vuelo sobre área urbana densamente poblada.',
    // Boundary from AIP ENR 5.1 (approximate — transcribe from current AIP):
    boundaryText: '''
      341800S-0583100W, 341800S-0581500W,
      342700S-0581500W, 342700S-0583100W,
      341800S-0583100W.
    ''',
  ),
];
