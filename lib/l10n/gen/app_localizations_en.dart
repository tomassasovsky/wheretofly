// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Where to Fly · Argentina';

  @override
  String get yourPermission => 'Your permission';

  @override
  String get tapHint =>
      'Tap a point on the map to see if you can fly. Guidance only — always verify with ANAC before operating.';

  @override
  String get permissionsAndResources => 'Permits and resources';

  @override
  String get verdictAllowed => 'You can fly here';

  @override
  String get verdictAllowedWithPermission => 'You can fly with your permit';

  @override
  String get verdictNotAllowed => 'You can\'t fly here';

  @override
  String permissionConsidered(Object label, Object category) {
    return 'Permission considered: $label ($category)';
  }

  @override
  String get noZones =>
      'No restricted zones registered at this point. General Open Category rules apply: VLOS, daytime, up to 122 m and away from people.';

  @override
  String get coversZone => '✓ Your permit covers this zone';

  @override
  String get notCoversZone => '✗ Your permit does not cover this zone';

  @override
  String get howToRequest => 'How to request a permit';

  @override
  String get recommendedPermitGuide => 'Recommended for this location';

  @override
  String get resourcesTitle => 'Permits and resources';

  @override
  String get resourcesIntro =>
      'How to request each permission level in Argentina. Links open official ANAC and government pages. This guide is indicative: ANAC is the authoritative source.';

  @override
  String get locateMe => 'Use my location';

  @override
  String couldNotOpen(Object url) {
    return 'Could not open $url';
  }

  @override
  String get locationServiceDisabled =>
      'Location services are off. Enable them and try again.';

  @override
  String get locationPermissionDenied => 'Location permission denied.';

  @override
  String get locationPermissionDeniedForever =>
      'Location permission permanently denied. Enable it in system settings.';

  @override
  String get locationUnavailable => 'Could not get your location.';

  @override
  String get outsideArgentina =>
      'This location may be outside Argentina. Zone data may be incomplete or unavailable.';

  @override
  String get searchHint => 'City or address';

  @override
  String get searchNoResults => 'No results found.';

  @override
  String get searchNetworkError => 'Could not search. Check your connection.';

  @override
  String get language => 'Language';

  @override
  String get languageSystem => 'System default';

  @override
  String get languageSpanish => 'Español';

  @override
  String get languageEnglish => 'English';

  @override
  String get settings => 'Settings';

  @override
  String get attributions => 'Licenses & attributions';

  @override
  String get attributionsSubtitle =>
      'Map data, weather sources, and open-source packages';

  @override
  String get theme => 'Appearance';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get cancel => 'Cancel';

  @override
  String get flightModality => 'Flight modality';

  @override
  String modalityRequires(Object modality, Object category) {
    return '$modality requires $category.';
  }

  @override
  String get tapToCheck => 'Tap the map to check a spot';

  @override
  String get done => 'Done';

  @override
  String get sponsorMe => 'Sponsor me';

  @override
  String get sponsorMeDescription => 'Support development on Cafecito.';

  @override
  String get creditsDevelopedBy => 'Developed by Tomás Sasovsky';

  @override
  String get creditsWebsite => 'Website';

  @override
  String get creditsGithub => 'GitHub';

  @override
  String get permRecreational => 'Recreational / no license';

  @override
  String get permRegistered => 'Registered ANAC pilot';

  @override
  String get permCommercial => 'Authorized / commercial';

  @override
  String get permSpecial => 'Special per-zone permit';

  @override
  String get permRecreationalShort => 'Recreational';

  @override
  String get permRegisteredShort => 'Registered';

  @override
  String get permCommercialShort => 'Commercial';

  @override
  String get permSpecialShort => 'Permit';

  @override
  String get anacAbierta => 'Open Category';

  @override
  String get anacAbiertaReg => 'Open Category (registered)';

  @override
  String get anacEspecifica => 'Specific Category';

  @override
  String get anacCaseByCase => 'Case-by-case authorization';

  @override
  String get modVlos => 'Visual line of sight (VLOS)';

  @override
  String get modVlosDesc =>
      'Within the pilot\'s visual line of sight, daytime. The baseline Open Category operation.';

  @override
  String get modEvlos => 'Extended visual (EVLOS)';

  @override
  String get modEvlosDesc =>
      'Visual range assisted by observers. Requires a registered operator.';

  @override
  String get modBvlos => 'BVLOS / FPV';

  @override
  String get modBvlosDesc =>
      'Beyond visual line of sight (including immersive FPV without an observer). Requires operational authorization (Specific Category).';

  @override
  String get modNight => 'Night flight';

  @override
  String get modNightDesc =>
      'Operation at night. Requires operational authorization (Specific Category).';

  @override
  String get modOverPeople => 'Over people';

  @override
  String get modOverPeopleDesc =>
      'Flight over people or crowds. Requires operational authorization (Specific Category).';

  @override
  String get zcControlled => 'Controlled airspace (CTR)';

  @override
  String get zcProhibited => 'Prohibited area';

  @override
  String get zcRestricted => 'Restricted area';

  @override
  String get zcPark => 'Protected natural area';

  @override
  String get zcInfra => 'Critical infrastructure';

  @override
  String get zcOpen => 'Open area';

  @override
  String get resRecSummary =>
      'Recreational flight in the Open Category needs no license. Drones under 250 g are essentially deregulated. Keep VLOS, daytime, max 122 m and away from people.';

  @override
  String get resRegSummary =>
      'Register as an operator with ANAC. Registration enables full Open Category operation and is the first step to request Specific Category authorizations.';

  @override
  String get resComSummary =>
      'For commercial or higher-risk operations (Specific Category) you need an ANAC operational authorization: risk assessment (SORA) and an operations manual.';

  @override
  String get resSpecSummary =>
      'To fly in controlled airspace or restricted areas you need a case-by-case permit: coordination with the control tower (ATC), the National Parks Administration, or the facility authority.';

  @override
  String get r1Title => 'Drone regulations (ANAC)';

  @override
  String get r1Desc => 'Official summary of Resolution 550/2025 and RAAC 100.';

  @override
  String get r2Title => 'Basic operating rules';

  @override
  String get r2Desc =>
      'VLOS, daytime, up to 122 m above ground, without flying over people or crowds.';

  @override
  String get r3Title => 'RPA / RPAS — ANAC procedures';

  @override
  String get r3Desc =>
      'Official remotely-piloted aircraft page: registration and requirements.';

  @override
  String get r4Title => 'Trámites a Distancia (TAD)';

  @override
  String get r4Desc =>
      'The State\'s platform to start registration and authorization procedures online.';

  @override
  String get r5Title => 'Operational authorization (Specific Category)';

  @override
  String get r5Desc =>
      'Requirements for night, urban or BVLOS flight. Handled by ANAC.';

  @override
  String get r6Title => 'Contact ANAC';

  @override
  String get r6Desc =>
      'Questions about certifications and operational authorizations.';

  @override
  String get r7Title => 'Controlled airspace (ATC)';

  @override
  String get r7Desc =>
      'Coordination with the air traffic control unit of the airport involved.';

  @override
  String get r8Title => 'Protected natural areas (APN)';

  @override
  String get r8Desc =>
      'Permit from the National Parks Administration to fly in national parks.';

  @override
  String get r9Title => 'NOTAM / AIP';

  @override
  String get r9Desc =>
      'Check notices to airmen and the aeronautical information publication before each flight.';

  @override
  String get plannedAltitude => 'Planned altitude (AGL)';

  @override
  String get plannedAltitudeHintOpen =>
      'Set takeoff (usually 0 m) through your max altitude. Categoría Abierta is generally up to 122 m AGL. Airspaces along the climb path are included.';

  @override
  String get plannedAltitudeHintExtended =>
      'Set takeoff through max altitude. Above 122 m requires ANAC Specific Category authorization or a written permit stating your ceiling.';

  @override
  String altitudeRangeMeters(String min, String max) {
    return '$min–$max m AGL';
  }

  @override
  String altitudeRangeConsidered(String min, String max) {
    return 'Altitude considered: $min–$max m AGL';
  }

  @override
  String altitudeMeters(String meters) {
    return '$meters m AGL';
  }

  @override
  String altitudeConsidered(String meters) {
    return 'Altitude considered: $meters m AGL';
  }

  @override
  String get zoneVerticalUnknown =>
      'Active at all altitudes (vertical limits unknown)';

  @override
  String zoneVerticalRangeAgl(Object lower, Object upper) {
    return '$lower–$upper m AGL';
  }

  @override
  String zoneVerticalFloorAgl(Object lower) {
    return 'Floor: $lower m AGL';
  }

  @override
  String zoneVerticalCeilingAgl(Object upper) {
    return 'Ceiling: $upper m AGL';
  }

  @override
  String zoneVerticalFloorMsl(Object lower) {
    return 'Floor: $lower m MSL (approx.)';
  }

  @override
  String zoneVerticalCeilingMsl(Object upper) {
    return 'Ceiling: $upper m MSL (approx.)';
  }

  @override
  String get zonesSkippedByAltitude =>
      'Not active at your altitude (for reference)';

  @override
  String get zoneSkippedAltitude => 'Inactive at your planned altitude';

  @override
  String get mslGroundElevationDisclaimer =>
      'MSL altitude limits assume sea-level ground nearby. In mountains, vertical checks may be approximate.';

  @override
  String minimumFlightRequirement(Object label, Object category) {
    return 'Minimum required: $label ($category)';
  }

  @override
  String get flightNotPossibleHere =>
      'Flight is not possible here with any standard authorization.';

  @override
  String get controlledAirspaceCoordination =>
      'Controlled airspace nearby — coordinate with ATC before flying. Your authorization does not replace tower clearance.';

  @override
  String get permCommercialConfigHint =>
      'National ANAC Specific Category authorization. Does not replace local ATC or site clearance.';

  @override
  String get permSpecialConfigHint =>
      'You already have case-by-case approval for this location (ATC, APN, facility).';

  @override
  String get authLoginTitle => 'Log in';

  @override
  String get authSignUpTitle => 'Create account';

  @override
  String get authSignUpPrompt => 'Need an account? Sign up';

  @override
  String get authEmail => 'Email';

  @override
  String get authPassword => 'Password';

  @override
  String get authHandle => 'Handle';

  @override
  String get authDisplayName => 'Display name';

  @override
  String get authAccount => 'Account';

  @override
  String get authLogOut => 'Log out';

  @override
  String get authLogIn => 'Log in';

  @override
  String get authLoginFailed =>
      'Could not log in. Check your credentials and connection.';

  @override
  String get authContinueWithoutAccount => 'Continue without account';

  @override
  String get splashLoading => 'Checking your session…';

  @override
  String get weatherAdvisoryTitle => 'Weather advisory';

  @override
  String weatherWind(Object speed, Object gust) {
    return 'Wind $speed m/s · gusts $gust m/s';
  }

  @override
  String get weatherDisclaimer =>
      'Advisory only — pilot responsibility under RAAC 100.';

  @override
  String get weatherReasonSmnAlert => 'Active weather alert (SMN)';

  @override
  String get weatherReasonWindHigh => 'Wind too strong for safe flight';

  @override
  String get weatherReasonWindElevated => 'Wind elevated for light drones';

  @override
  String get weatherReasonWindModerate => 'Caution: moderate wind';

  @override
  String get weatherReasonFavorable => 'Favorable conditions';

  @override
  String get mapLayerZones => 'Zones';

  @override
  String get mapLayerWind => 'Wind';

  @override
  String get mapWindOverlayToggle => 'Show wind gusts';

  @override
  String get mapWindLegendTitle => 'Wind gusts (10 m)';

  @override
  String get mapWindLegendUnit => 'm/s';

  @override
  String get openMeteoAttribution => '© Open-Meteo · DWD ICON';

  @override
  String get weatherLoading => 'Loading weather…';

  @override
  String get weatherRequiresAuth => 'Sign in to see weather for this point.';

  @override
  String get weatherFetchFailed =>
      'Weather unavailable. Zone check still applies.';

  @override
  String zoneFeedStale(Object version) {
    return 'Zone data may be outdated (version $version).';
  }

  @override
  String get weatherAlertsTitle => 'Weather alerts';

  @override
  String get weatherAlertSave => 'Alert me here';

  @override
  String get weatherAlertSaved => 'Weather alert saved.';

  @override
  String get weatherAlertLabel => 'Location name';

  @override
  String get weatherAlertEmpty => 'No saved weather alerts.';

  @override
  String weatherAlertWindThreshold(Object speed) {
    return 'Wind alert at $speed m/s';
  }

  @override
  String get socialFeedTitle => 'Community feed';

  @override
  String get socialFeedEmpty =>
      'No reels yet. Follow pilots to see their fly-check photos and videos here.';

  @override
  String get socialCreatePostMediaHint =>
      'A snapshot from your fly check will be attached when you publish.';

  @override
  String get socialFeedLoadFailed => 'Could not load the feed.';

  @override
  String get socialFeedOffline => 'Offline — showing saved posts';

  @override
  String get socialShareFlyCheck => 'Share fly check';

  @override
  String get socialCreatePostTitle => 'Share fly check';

  @override
  String get socialCreatePostHint =>
      'Add a caption for your followers (optional).';

  @override
  String get socialCaptionLabel => 'Caption';

  @override
  String get socialPublish => 'Publish';

  @override
  String get socialPostTitle => 'Post';

  @override
  String get socialPostLoadFailed => 'Could not load this post.';

  @override
  String get socialComments => 'Comments';

  @override
  String get socialCommentsEmpty => 'No comments yet.';

  @override
  String get socialCommentHint => 'Write a comment…';

  @override
  String get socialFollow => 'Follow';

  @override
  String get socialFollowRequest => 'Request follow';

  @override
  String get socialPosts => 'Posts';

  @override
  String get socialProfileLoadFailed => 'Could not load this profile.';

  @override
  String get socialProfilePostsEmpty => 'No posts yet.';

  @override
  String get navFeed => 'Feed';

  @override
  String get navExplore => 'Explore';

  @override
  String get navMap => 'Map';

  @override
  String get navMessages => 'Messages';

  @override
  String get navProfile => 'Profile';

  @override
  String get exploreSearchHint => 'Search pilots by @handle';

  @override
  String get exploreShortcuts => 'Shortcuts';

  @override
  String get exploreResourcesSubtitle => 'Permits, guides, and official links';

  @override
  String get exploreMapSubtitle => 'Check where you can fly';

  @override
  String get messagesRequiresAuth => 'Sign in to view your messages.';

  @override
  String get messagesEmpty => 'No conversations yet';

  @override
  String get messagesEmptySubtitle =>
      'Direct messages with other pilots will appear here.';

  @override
  String get messagesLoadFailed => 'Could not load your messages.';

  @override
  String get chatLoadFailed => 'Could not load this conversation.';

  @override
  String get chatEmpty => 'No messages yet. Say hello!';

  @override
  String get chatInputHint => 'Message…';

  @override
  String get socialMessage => 'Message';

  @override
  String get socialMessageOpenFailed => 'Could not start this conversation.';

  @override
  String get notificationPrefsTitle => 'Push notifications';

  @override
  String get notificationPrefsFollows => 'New followers';

  @override
  String get notificationPrefsMessages => 'Direct messages';

  @override
  String get notificationPrefsComments => 'Comments on your posts';

  @override
  String get notificationPrefsWeather => 'Weather alerts';

  @override
  String get notificationPrefsLoadFailed =>
      'Could not load notification settings.';

  @override
  String get profileSignInPrompt =>
      'Sign in to see your profile, posts, and saved alerts.';

  @override
  String get socialFlyCheckMissing => 'Missing fly-check data.';

  @override
  String get socialReelBadge => 'REEL';

  @override
  String get socialReelRetryVideo => 'Retry video';

  @override
  String get flightDataSourcesTitle => 'Where our data comes from';

  @override
  String get flightDataSourcesIntro =>
      'This app helps you explore where you may fly under Argentina’s drone rules. It combines public datasets, curated zones, and your chosen permission level. Guidance only. Always confirm with ANAC, NOTAMs, and the official AIP before operating.';

  @override
  String get flightDataSourcesHowWeDecideTitle =>
      'How we decide if you can fly';

  @override
  String get flightDataSourcesHowWeDecideBody =>
      'When you tap the map, we check whether any registered restriction circles overlap that point and whether your selected permission level and flight modality (recreational, commercial, etc.) are allowed there. Altitude and VLOS rules from ANAC Res. 550/2025 and RAAC 100 are summarized in the verdict text.';

  @override
  String get flightDataSourcesPermissionsTitle =>
      'Your permission and modality';

  @override
  String get flightDataSourcesPermissionsBody =>
      'Permission categories (recreational open category, specific category, certified operator, etc.) follow Argentina’s ANAC framework (Res. 550/2025 and RAAC 100). You choose them in the app; they are not downloaded from a government API. See Permits and resources for how to obtain each authorization.';

  @override
  String get flightDataSourcesZonesTitle => 'Restriction zones on the map';

  @override
  String get flightDataSourcesZoneMadhelTitle => 'ANAC MADHEL';

  @override
  String get flightDataSourcesZoneMadhelBody =>
      'Aerodromes and heliports from Argentina’s MADHEL open data (ANAC). Shown as protection circles around published coordinates. The app also keeps a bundled snapshot for offline use.';

  @override
  String get flightDataSourcesZoneOpenAipTitle => 'OpenAIP';

  @override
  String get flightDataSourcesZoneOpenAipBody =>
      'Community-maintained airspace (controlled areas, restrictions, etc.) from OpenAIP country exports, merged on the server when configured. Zones are approximated as circles for performance.';

  @override
  String get flightDataSourcesZoneCuratedTitle => 'Curated zones';

  @override
  String get flightDataSourcesZoneCuratedBody =>
      'Additional circles for parks, critical infrastructure, and other areas maintained in the project’s zone packages and baseline feed — not live government polygons.';

  @override
  String get flightDataSourcesZoneFeedTitle => 'Dónde Volar zone feed';

  @override
  String get flightDataSourcesZoneFeedBody =>
      'The backend merges MADHEL, OpenAIP, and curated sources into a published GeoJSON feed. The app downloads updates from the API when online and falls back to the last cached or bundled copy.';

  @override
  String get flightDataSourcesSearchTitle => 'Place search';

  @override
  String get flightDataSourcesSearchBody =>
      'City and address search goes through the Dónde Volar API, which queries a self-hosted Photon geocoder built from OpenStreetMap data (Argentina index). Contains OSM © contributors under ODbL.';

  @override
  String get flightDataSourcesWeatherTitle => 'Weather advisory';

  @override
  String get flightDataSourcesWeatherBody =>
      'Wind and temperature at the tapped point come from Open-Meteo (DWD ICON). Active short-term alerts use Argentina’s SMN CAP RSS feed. Weather does not change zone geometry — it adds an advisory layer only.';

  @override
  String get flightDataSourcesWeatherOpenMeteoTitle => 'Open-Meteo';

  @override
  String get flightDataSourcesWeatherOpenMeteoBody =>
      'Hourly wind gusts and related fields for the map overlay and fly-check card.';

  @override
  String get flightDataSourcesWeatherSmnTitle =>
      'SMN (Servicio Meteorológico Nacional)';

  @override
  String get flightDataSourcesWeatherSmnBody =>
      'Official Argentina weather alerts (CAP RSS) surfaced when an active warning applies to the area.';

  @override
  String get flightDataSourcesDisclaimer =>
      'Zone boundaries are simplified circles and may be incomplete or out of date. ANAC, aerodrome operators, NOTAMs, and the official AIP remain authoritative. Never rely on this app alone for operational decisions.';

  @override
  String get flightDataSourcesSettingsSubtitle =>
      'Zones, permissions framework, search, and weather';

  @override
  String get flightDataSourcesOpenLink => 'Open official site';

  @override
  String get flightDataSourcesMapLink => 'Where does this data come from?';

  @override
  String get flightDataSourcesResourcesLink => 'How we build the map';
}
