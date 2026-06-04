import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Registers data-source attributions shown in [LicensePage] / [showLicensePage].
void registerAppLicenses() {
  LicenseRegistry.addLicense(() async* {
    yield const LicenseEntryWithLineBreaks(
      <String>['Map data'],
      'Basemap tiles © CARTO (https://carto.com/attribution/).\n'
      'Contains data from OpenStreetMap © OpenStreetMap contributors,\n'
      'available under the Open Database License (ODbL) 1.0.\n'
      'https://www.openstreetmap.org/copyright',
    );
    yield const LicenseEntryWithLineBreaks(
      <String>['Weather overlay'],
      'Wind gust and direction fields from Open-Meteo (DWD ICON model).\n'
      'https://open-meteo.com/',
    );
    yield const LicenseEntryWithLineBreaks(
      <String>['Flight restriction zones'],
      'Zone circles combine ANAC MADHEL open data, optional OpenAIP exports,\n'
      'and curated project zones, published via the Dónde Volar API.\n'
      'https://datos.anac.gob.ar/madhel/\n'
      'https://www.openaip.net/',
    );
    yield const LicenseEntryWithLineBreaks(
      <String>['Place search'],
      'Geocoding via self-hosted Photon (OpenStreetMap Argentina index).\n'
      'https://www.openstreetmap.org/copyright',
    );
    yield const LicenseEntryWithLineBreaks(
      <String>['Weather alerts'],
      'Argentina Servicio Meteorológico Nacional (SMN) CAP RSS advisories.\n'
      'https://www.smn.gob.ar/',
    );
  });
}
