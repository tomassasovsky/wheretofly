import 'package:flight_rules_repository/src/models/permission_level.dart';

/// How the drone is being flown. Different modalities require different
/// minimum ANAC authorizations regardless of location — e.g. BVLOS/FPV and
/// night operations fall under the Categoría Específica.
enum FlightModality {
  vlos(
    id: 'vlos',
    label: 'Vuelo visual (VLOS)',
    minimumPermission: PermissionLevel.recreational,
    description:
        'Dentro del alcance visual del piloto, de día. Es la operación base '
        'de la Categoría Abierta.',
  ),
  evlos(
    id: 'evlos',
    label: 'Visual extendido (EVLOS)',
    minimumPermission: PermissionLevel.registeredPilot,
    description: 'Alcance visual asistido por observadores. Requiere operador '
        'registrado.',
  ),
  bvlosFpv(
    id: 'bvlos_fpv',
    label: 'BVLOS / FPV',
    minimumPermission: PermissionLevel.authorizedCommercial,
    description:
        'Más allá del alcance visual (incluye FPV inmersivo sin observador). '
        'Requiere autorización operacional (Categoría Específica).',
  ),
  night(
    id: 'night',
    label: 'Vuelo nocturno',
    minimumPermission: PermissionLevel.authorizedCommercial,
    description:
        'Operación de noche. Requiere autorización operacional (Categoría '
        'Específica).',
  ),
  overPeople(
    id: 'over_people',
    label: 'Sobre personas',
    minimumPermission: PermissionLevel.authorizedCommercial,
    description: 'Vuelo sobre personas o aglomeraciones. Requiere autorización '
        'operacional (Categoría Específica).',
  );

  const FlightModality({
    required this.id,
    required this.label,
    required this.minimumPermission,
    required this.description,
  });

  final String id;
  final String label;

  /// The minimum permission level needed to fly this modality (anywhere).
  final PermissionLevel minimumPermission;
  final String description;

  /// Resolves a [FlightModality] from its [id], defaulting to [vlos].
  static FlightModality fromId(String? id) => values.firstWhere(
        (m) => m.id == id,
        orElse: () => FlightModality.vlos,
      );
}
