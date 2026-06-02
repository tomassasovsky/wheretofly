import 'package:flight_rules_repository/flight_rules_repository.dart';
import 'package:where_to_fly/l10n/gen/app_localizations.dart';

/// Presentation-layer mappers from domain enums to localized display strings,
/// so the UI never shows the (Spanish) fallback labels baked into the domain.
///
/// Method names are prefixed with `l10n` to avoid colliding with the enums'
/// own `label` / `description` fields.
extension PermissionLevelL10n on PermissionLevel {
  String l10nLabel(AppLocalizations l10n) {
    switch (this) {
      case PermissionLevel.recreational:
        return l10n.permRecreational;
      case PermissionLevel.registeredPilot:
        return l10n.permRegistered;
      case PermissionLevel.authorizedCommercial:
        return l10n.permCommercial;
      case PermissionLevel.specialPermit:
        return l10n.permSpecial;
    }
  }

  String l10nShort(AppLocalizations l10n) {
    switch (this) {
      case PermissionLevel.recreational:
        return l10n.permRecreationalShort;
      case PermissionLevel.registeredPilot:
        return l10n.permRegisteredShort;
      case PermissionLevel.authorizedCommercial:
        return l10n.permCommercialShort;
      case PermissionLevel.specialPermit:
        return l10n.permSpecialShort;
    }
  }

  String l10nCategory(AppLocalizations l10n) {
    switch (this) {
      case PermissionLevel.recreational:
        return l10n.anacAbierta;
      case PermissionLevel.registeredPilot:
        return l10n.anacAbiertaReg;
      case PermissionLevel.authorizedCommercial:
        return l10n.anacEspecifica;
      case PermissionLevel.specialPermit:
        return l10n.anacCaseByCase;
    }
  }

  /// Subtitle shown in the permission picker.
  String l10nConfigHint(AppLocalizations l10n) {
    switch (this) {
      case PermissionLevel.authorizedCommercial:
        return l10n.permCommercialConfigHint;
      case PermissionLevel.specialPermit:
        return l10n.permSpecialConfigHint;
      case PermissionLevel.recreational:
      case PermissionLevel.registeredPilot:
        return l10nCategory(l10n);
    }
  }
}

extension FlightModalityL10n on FlightModality {
  String l10nLabel(AppLocalizations l10n) {
    switch (this) {
      case FlightModality.vlos:
        return l10n.modVlos;
      case FlightModality.evlos:
        return l10n.modEvlos;
      case FlightModality.bvlosFpv:
        return l10n.modBvlos;
      case FlightModality.night:
        return l10n.modNight;
      case FlightModality.overPeople:
        return l10n.modOverPeople;
    }
  }

  String l10nDescription(AppLocalizations l10n) {
    switch (this) {
      case FlightModality.vlos:
        return l10n.modVlosDesc;
      case FlightModality.evlos:
        return l10n.modEvlosDesc;
      case FlightModality.bvlosFpv:
        return l10n.modBvlosDesc;
      case FlightModality.night:
        return l10n.modNightDesc;
      case FlightModality.overPeople:
        return l10n.modOverPeopleDesc;
    }
  }
}

extension FlyZoneL10n on FlyZone {
  String l10nVerticalExtent(AppLocalizations l10n) {
    if (!hasVerticalLimits) return l10n.zoneVerticalUnknown;

    final parts = <String>[];
    if (lowerLimitMetersAgl != null) {
      parts.add(l10n.zoneVerticalFloorAgl(lowerLimitMetersAgl!.round()));
    } else if (lowerLimitMetersMsl != null) {
      parts.add(l10n.zoneVerticalFloorMsl(lowerLimitMetersMsl!.round()));
    }
    if (upperLimitMetersAgl != null) {
      parts.add(l10n.zoneVerticalCeilingAgl(upperLimitMetersAgl!.round()));
    } else if (upperLimitMetersMsl != null) {
      parts.add(l10n.zoneVerticalCeilingMsl(upperLimitMetersMsl!.round()));
    }

    if (lowerLimitMetersAgl != null &&
        upperLimitMetersAgl != null &&
        parts.length == 2) {
      return l10n.zoneVerticalRangeAgl(
        lowerLimitMetersAgl!.round(),
        upperLimitMetersAgl!.round(),
      );
    }
    return parts.join(' · ');
  }
}

extension ZoneCategoryL10n on ZoneCategory {
  String l10nLabel(AppLocalizations l10n) {
    switch (this) {
      case ZoneCategory.controlledAirspace:
        return l10n.zcControlled;
      case ZoneCategory.prohibited:
        return l10n.zcProhibited;
      case ZoneCategory.restricted:
        return l10n.zcRestricted;
      case ZoneCategory.nationalPark:
        return l10n.zcPark;
      case ZoneCategory.sensitiveInfrastructure:
        return l10n.zcInfra;
      case ZoneCategory.open:
        return l10n.zcOpen;
    }
  }
}
