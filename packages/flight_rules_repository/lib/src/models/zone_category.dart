/// The kind of airspace restriction a zone represents.
enum ZoneCategory {
  controlledAirspace(
    id: 'controlled_airspace',
    label: 'Espacio aéreo controlado (CTR)',
    rationale:
        'Entorno de aeropuerto / aeródromo. Requiere coordinación con la '
        'autoridad de tránsito aéreo.',
  ),
  prohibited(
    id: 'prohibited',
    label: 'Zona prohibida',
    rationale:
        'Vuelo prohibido por seguridad nacional, instalaciones de gobierno '
        'o defensa.',
  ),
  restricted(
    id: 'restricted',
    label: 'Zona restringida',
    rationale:
        'Vuelo restringido salvo autorización específica (penitenciarías, '
        'fuerzas de seguridad, infraestructura crítica).',
  ),
  nationalPark(
    id: 'national_park',
    label: 'Área natural protegida',
    rationale:
        'Administración de Parques Nacionales: vuelo de drones prohibido '
        'salvo permiso del organismo.',
  ),
  sensitiveInfrastructure(
    id: 'sensitive_infrastructure',
    label: 'Infraestructura crítica',
    rationale:
        'Usinas, plantas químicas, puentes, líneas de alta tensión y rutas '
        'nacionales.',
  ),
  open(
    id: 'open',
    label: 'Zona abierta',
    rationale: 'Sin restricciones específicas publicadas. Aplican las reglas '
        'generales de la Categoría Abierta.',
  );

  const ZoneCategory({
    required this.id,
    required this.label,
    required this.rationale,
  });

  final String id;
  final String label;
  final String rationale;

  /// Resolves a [ZoneCategory] from its [id], defaulting to [open].
  static ZoneCategory fromId(String? id) => values.firstWhere(
        (c) => c.id == id,
        orElse: () => ZoneCategory.open,
      );
}
