import 'package:flight_rules_repository/src/models/altitude_range.dart';

/// The permission / authorization a pilot holds.
///
/// Maps onto the ANAC operating framework introduced by Resolución ANAC
/// 550/2025 and consolidated in RAAC 100 (categories Abierta, Específica and
/// Certificada).
enum PermissionLevel {
  recreational(
    id: 'recreational',
    label: 'Recreativo / sin licencia',
    shortLabel: 'Recreativo',
    anacCategory: 'Categoría Abierta',
    description:
        'Vuelo recreativo dentro del alcance visual (VLOS), de día, hasta '
        '122 m de altura y lejos de personas. Los drones de menos de 250 g '
        'están prácticamente desregulados.',
  ),
  registeredPilot(
    id: 'registered_pilot',
    label: 'Piloto registrado ANAC',
    shortLabel: 'Registrado',
    anacCategory: 'Categoría Abierta (registrado)',
    description:
        'Operador inscripto en el registro de ANAC. Habilita la operación '
        'plena en Categoría Abierta y es requisito para solicitar '
        'autorizaciones de la Categoría Específica.',
  ),
  authorizedCommercial(
    id: 'authorized_commercial',
    label: 'Autorizado / comercial',
    shortLabel: 'Comercial',
    anacCategory: 'Categoría Específica',
    description: 'Operador comercial con autorización operacional de ANAC '
        '(Categoría Específica): habilita escenarios como vuelo nocturno, '
        'zonas urbanas o más allá del alcance visual (BVLOS).',
  ),
  specialPermit(
    id: 'special_permit',
    label: 'Permiso especial por zona',
    shortLabel: 'Permiso',
    anacCategory: 'Autorización caso por caso',
    description: 'Autorización puntual emitida caso por caso (por ejemplo, '
        'coordinación con la torre de control para espacio aéreo controlado, '
        'o permiso específico para un área normalmente restringida).',
  );

  const PermissionLevel({
    required this.id,
    required this.label,
    required this.shortLabel,
    required this.anacCategory,
    required this.description,
  });

  final String id;
  final String label;
  final String shortLabel;
  final String anacCategory;
  final String description;

  /// Whether this level is limited to Categoría Abierta rules (incl. 122 m).
  bool get isOpenCategoryOnly =>
      this == PermissionLevel.recreational ||
      this == PermissionLevel.registeredPilot;

  /// Maximum altitude offered in the planning slider for this permission.
  double get maxPlannedAltitudeMetersAgl => isOpenCategoryOnly
      ? AltitudeRange.defaultMaxMetersAgl
      : AltitudeRange.maxPlanningAltitudeMetersAgl;

  /// Relative authority of this permission, used to gate flight modalities.
  /// Higher means more is permitted. `specialPermit` ranks highest because it
  /// represents a bespoke case-by-case authorization.
  int get rank {
    switch (this) {
      case PermissionLevel.recreational:
        return 0;
      case PermissionLevel.registeredPilot:
        return 1;
      case PermissionLevel.authorizedCommercial:
        return 2;
      case PermissionLevel.specialPermit:
        return 3;
    }
  }

  /// Resolves a [PermissionLevel] from its [id], defaulting to recreational.
  static PermissionLevel fromId(String? id) => values.firstWhere(
        (p) => p.id == id,
        orElse: () => PermissionLevel.recreational,
      );
}
