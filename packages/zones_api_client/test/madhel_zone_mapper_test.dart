import 'package:test/test.dart';
import 'package:zones_api_client/src/madhel_zone_mapper.dart';
import 'package:zones_api_client/src/zone_permission_ids.dart';
import 'package:zones_api_client/src/zone_source_ids.dart';

void main() {
  group('MadhelZoneMapper', () {
    test('maps controlled international aerodrome', () {
      final zone = MadhelZoneMapper.fromListEntry({
        'local_identifier': 'AER',
        'human_readable_identifier':
            'BUENOS AIRES / AEROPARQUE J. NEWBERY - (AER / SABE) - DRCE - '
                'PÚBLICO CONTROLADO INTERNACIONAL',
        'the_geom': {
          'geometry': {
            'coordinates': [-58.4163888888889, -34.5588888888889],
          },
        },
      });

      expect(zone, isNotNull);
      expect(zone!.id, 'madhel_AER');
      expect(zone.categoryId, 'controlled_airspace');
      expect(zone.radiusMeters, 9000);
      expect(zone.allowedPermissionIds, ZonePermissionIds.controlledAirspace);
      expect(zone.source, ZoneSourceIds.madhel);
    });

    test('maps uncontrolled aerodrome as restricted', () {
      final zone = MadhelZoneMapper.fromListEntry({
        'local_identifier': 'ACM',
        'human_readable_identifier':
            'ARRECIFES / LA CURA MALAL - (ACM) - DRCE - PRIVADO NO CONTROLADO',
        'the_geom': {
          'geometry': {
            'coordinates': [-60.1417, -34.07574],
          },
        },
      });

      expect(zone, isNotNull);
      expect(zone!.categoryId, 'restricted');
      expect(zone.radiusMeters, 2500);
      expect(zone.allowedPermissionIds, ZonePermissionIds.controlledAirspace);
    });

    test('maps heliport with smaller radius', () {
      final zone = MadhelZoneMapper.fromListEntry({
        'local_identifier': 'HAC',
        'human_readable_identifier':
            'ALPA CORRAL / HELIPUERTO JUAN Y LUCI - (HAC) - DRNO - '
                'PRIVADO NO CONTROLADO',
        'the_geom': {
          'geometry': {
            'coordinates': [-66.0, -34.0],
          },
        },
      });

      expect(zone, isNotNull);
      expect(zone!.categoryId, 'controlled_airspace');
      expect(zone.radiusMeters, 2000);
      expect(zone.allowedPermissionIds, ZonePermissionIds.controlledAirspace);
    });

    test('does not treat hospital HNP code as heliport', () {
      final zone = MadhelZoneMapper.fromListEntry({
        'local_identifier': 'HNP',
        'human_readable_identifier':
            'BUENOS AIRES / HOSPITAL NAC. DE PEDIATRÍA J. GARRAHAN - (HNP) - '
                'DRCE - PÚBLICO NO CONTROLADO (ELEVADO DE USO SANITARIO)',
        'the_geom': {
          'geometry': {
            'coordinates': [-58.381, -34.642],
          },
        },
      });

      expect(zone, isNotNull);
      expect(zone!.categoryId, 'restricted');
      expect(zone.radiusMeters, 2500);
    });

    test('does not treat FIR region code DRCE as controlled airspace', () {
      expect(
        MadhelZoneMapper.fromListEntry({
          'local_identifier': 'HBM',
          'human_readable_identifier':
              'BUENOS AIRES / MADERO - (HBM) - DRCE - PRIVADO '
                  '[** HLP CERRADO (CLSD) **]',
          'the_geom': {
            'geometry': {
              'coordinates': [-58.36, -34.61],
            },
          },
        }),
        isNull,
      );
    });

    test('skips closed aerodromes marked CLSD', () {
      expect(
        MadhelZoneMapper.fromListEntry({
          'local_identifier': 'XYZ',
          'human_readable_identifier': 'TEST / HELIPUERTO - CLSD',
          'the_geom': {
            'geometry': {
              'coordinates': [-58.0, -34.0],
            },
          },
        }),
        isNull,
      );
    });

    test('DRCE alone maps to restricted not controlled', () {
      final zone = MadhelZoneMapper.fromListEntry({
        'local_identifier': 'HDA',
        'human_readable_identifier':
            'BUENOS AIRES / DÁRSENA SUR - (HDA) - DRCE - PÚBLICO NO CONTROLADO',
        'the_geom': {
          'geometry': {
            'coordinates': [-58.36, -34.62],
          },
        },
      });

      expect(zone, isNotNull);
      expect(zone!.categoryId, 'restricted');
      expect(zone.radiusMeters, 2500);
    });

    test('returns null when coordinates are missing', () {
      expect(
        MadhelZoneMapper.fromListEntry({
          'local_identifier': 'BAD',
          'human_readable_identifier': 'Bad entry',
        }),
        isNull,
      );
    });
  });
}
