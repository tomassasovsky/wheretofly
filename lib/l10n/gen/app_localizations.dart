import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'gen/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Where to Fly · Argentina'**
  String get appTitle;

  /// No description provided for @yourPermission.
  ///
  /// In en, this message translates to:
  /// **'Your permission'**
  String get yourPermission;

  /// No description provided for @tapHint.
  ///
  /// In en, this message translates to:
  /// **'Tap a point on the map to see if you can fly. Guidance only — always verify with ANAC before operating.'**
  String get tapHint;

  /// No description provided for @permissionsAndResources.
  ///
  /// In en, this message translates to:
  /// **'Permits and resources'**
  String get permissionsAndResources;

  /// No description provided for @verdictAllowed.
  ///
  /// In en, this message translates to:
  /// **'You can fly here'**
  String get verdictAllowed;

  /// No description provided for @verdictAllowedWithPermission.
  ///
  /// In en, this message translates to:
  /// **'You can fly with your permit'**
  String get verdictAllowedWithPermission;

  /// No description provided for @verdictNotAllowed.
  ///
  /// In en, this message translates to:
  /// **'You can\'t fly here'**
  String get verdictNotAllowed;

  /// No description provided for @permissionConsidered.
  ///
  /// In en, this message translates to:
  /// **'Permission considered: {label} ({category})'**
  String permissionConsidered(Object label, Object category);

  /// No description provided for @noZones.
  ///
  /// In en, this message translates to:
  /// **'No restricted zones registered at this point. General Open Category rules apply: VLOS, daytime, up to 122 m and away from people.'**
  String get noZones;

  /// No description provided for @coversZone.
  ///
  /// In en, this message translates to:
  /// **'✓ Your permit covers this zone'**
  String get coversZone;

  /// No description provided for @notCoversZone.
  ///
  /// In en, this message translates to:
  /// **'✗ Your permit does not cover this zone'**
  String get notCoversZone;

  /// No description provided for @howToRequest.
  ///
  /// In en, this message translates to:
  /// **'How to request a permit'**
  String get howToRequest;

  /// No description provided for @recommendedPermitGuide.
  ///
  /// In en, this message translates to:
  /// **'Recommended for this location'**
  String get recommendedPermitGuide;

  /// No description provided for @resourcesTitle.
  ///
  /// In en, this message translates to:
  /// **'Permits and resources'**
  String get resourcesTitle;

  /// No description provided for @resourcesIntro.
  ///
  /// In en, this message translates to:
  /// **'How to request each permission level in Argentina. Links open official ANAC and government pages. This guide is indicative: ANAC is the authoritative source.'**
  String get resourcesIntro;

  /// No description provided for @locateMe.
  ///
  /// In en, this message translates to:
  /// **'Use my location'**
  String get locateMe;

  /// No description provided for @couldNotOpen.
  ///
  /// In en, this message translates to:
  /// **'Could not open {url}'**
  String couldNotOpen(Object url);

  /// No description provided for @locationServiceDisabled.
  ///
  /// In en, this message translates to:
  /// **'Location services are off. Enable them and try again.'**
  String get locationServiceDisabled;

  /// No description provided for @locationPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Location permission denied.'**
  String get locationPermissionDenied;

  /// No description provided for @locationPermissionDeniedForever.
  ///
  /// In en, this message translates to:
  /// **'Location permission permanently denied. Enable it in system settings.'**
  String get locationPermissionDeniedForever;

  /// No description provided for @locationUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Could not get your location.'**
  String get locationUnavailable;

  /// No description provided for @outsideArgentina.
  ///
  /// In en, this message translates to:
  /// **'This location may be outside Argentina. Zone data may be incomplete or unavailable.'**
  String get outsideArgentina;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'City or address'**
  String get searchHint;

  /// No description provided for @searchNoResults.
  ///
  /// In en, this message translates to:
  /// **'No results found.'**
  String get searchNoResults;

  /// No description provided for @searchNetworkError.
  ///
  /// In en, this message translates to:
  /// **'Could not search. Check your connection.'**
  String get searchNetworkError;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @languageSystem.
  ///
  /// In en, this message translates to:
  /// **'System default'**
  String get languageSystem;

  /// No description provided for @languageSpanish.
  ///
  /// In en, this message translates to:
  /// **'Español'**
  String get languageSpanish;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @attributions.
  ///
  /// In en, this message translates to:
  /// **'Licenses & attributions'**
  String get attributions;

  /// No description provided for @attributionsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Map data, weather sources, and open-source packages'**
  String get attributionsSubtitle;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get theme;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @flightModality.
  ///
  /// In en, this message translates to:
  /// **'Flight modality'**
  String get flightModality;

  /// No description provided for @modalityRequires.
  ///
  /// In en, this message translates to:
  /// **'{modality} requires {category}.'**
  String modalityRequires(Object modality, Object category);

  /// No description provided for @tapToCheck.
  ///
  /// In en, this message translates to:
  /// **'Tap the map to check a spot'**
  String get tapToCheck;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @sponsorMe.
  ///
  /// In en, this message translates to:
  /// **'Sponsor me'**
  String get sponsorMe;

  /// No description provided for @sponsorMeDescription.
  ///
  /// In en, this message translates to:
  /// **'Support development on Cafecito.'**
  String get sponsorMeDescription;

  /// No description provided for @creditsDevelopedBy.
  ///
  /// In en, this message translates to:
  /// **'Developed by Tomás Sasovsky'**
  String get creditsDevelopedBy;

  /// No description provided for @creditsWebsite.
  ///
  /// In en, this message translates to:
  /// **'Website'**
  String get creditsWebsite;

  /// No description provided for @creditsGithub.
  ///
  /// In en, this message translates to:
  /// **'GitHub'**
  String get creditsGithub;

  /// No description provided for @permRecreational.
  ///
  /// In en, this message translates to:
  /// **'Recreational / no license'**
  String get permRecreational;

  /// No description provided for @permRegistered.
  ///
  /// In en, this message translates to:
  /// **'Registered ANAC pilot'**
  String get permRegistered;

  /// No description provided for @permCommercial.
  ///
  /// In en, this message translates to:
  /// **'Authorized / commercial'**
  String get permCommercial;

  /// No description provided for @permSpecial.
  ///
  /// In en, this message translates to:
  /// **'Special per-zone permit'**
  String get permSpecial;

  /// No description provided for @permRecreationalShort.
  ///
  /// In en, this message translates to:
  /// **'Recreational'**
  String get permRecreationalShort;

  /// No description provided for @permRegisteredShort.
  ///
  /// In en, this message translates to:
  /// **'Registered'**
  String get permRegisteredShort;

  /// No description provided for @permCommercialShort.
  ///
  /// In en, this message translates to:
  /// **'Commercial'**
  String get permCommercialShort;

  /// No description provided for @permSpecialShort.
  ///
  /// In en, this message translates to:
  /// **'Permit'**
  String get permSpecialShort;

  /// No description provided for @anacAbierta.
  ///
  /// In en, this message translates to:
  /// **'Open Category'**
  String get anacAbierta;

  /// No description provided for @anacAbiertaReg.
  ///
  /// In en, this message translates to:
  /// **'Open Category (registered)'**
  String get anacAbiertaReg;

  /// No description provided for @anacEspecifica.
  ///
  /// In en, this message translates to:
  /// **'Specific Category'**
  String get anacEspecifica;

  /// No description provided for @anacCaseByCase.
  ///
  /// In en, this message translates to:
  /// **'Case-by-case authorization'**
  String get anacCaseByCase;

  /// No description provided for @modVlos.
  ///
  /// In en, this message translates to:
  /// **'Visual line of sight (VLOS)'**
  String get modVlos;

  /// No description provided for @modVlosDesc.
  ///
  /// In en, this message translates to:
  /// **'Within the pilot\'s visual line of sight, daytime. The baseline Open Category operation.'**
  String get modVlosDesc;

  /// No description provided for @modEvlos.
  ///
  /// In en, this message translates to:
  /// **'Extended visual (EVLOS)'**
  String get modEvlos;

  /// No description provided for @modEvlosDesc.
  ///
  /// In en, this message translates to:
  /// **'Visual range assisted by observers. Requires a registered operator.'**
  String get modEvlosDesc;

  /// No description provided for @modBvlos.
  ///
  /// In en, this message translates to:
  /// **'BVLOS / FPV'**
  String get modBvlos;

  /// No description provided for @modBvlosDesc.
  ///
  /// In en, this message translates to:
  /// **'Beyond visual line of sight (including immersive FPV without an observer). Requires operational authorization (Specific Category).'**
  String get modBvlosDesc;

  /// No description provided for @modNight.
  ///
  /// In en, this message translates to:
  /// **'Night flight'**
  String get modNight;

  /// No description provided for @modNightDesc.
  ///
  /// In en, this message translates to:
  /// **'Operation at night. Requires operational authorization (Specific Category).'**
  String get modNightDesc;

  /// No description provided for @modOverPeople.
  ///
  /// In en, this message translates to:
  /// **'Over people'**
  String get modOverPeople;

  /// No description provided for @modOverPeopleDesc.
  ///
  /// In en, this message translates to:
  /// **'Flight over people or crowds. Requires operational authorization (Specific Category).'**
  String get modOverPeopleDesc;

  /// No description provided for @zcControlled.
  ///
  /// In en, this message translates to:
  /// **'Controlled airspace (CTR)'**
  String get zcControlled;

  /// No description provided for @zcProhibited.
  ///
  /// In en, this message translates to:
  /// **'Prohibited area'**
  String get zcProhibited;

  /// No description provided for @zcRestricted.
  ///
  /// In en, this message translates to:
  /// **'Restricted area'**
  String get zcRestricted;

  /// No description provided for @zcPark.
  ///
  /// In en, this message translates to:
  /// **'Protected natural area'**
  String get zcPark;

  /// No description provided for @zcInfra.
  ///
  /// In en, this message translates to:
  /// **'Critical infrastructure'**
  String get zcInfra;

  /// No description provided for @zcOpen.
  ///
  /// In en, this message translates to:
  /// **'Open area'**
  String get zcOpen;

  /// No description provided for @resRecSummary.
  ///
  /// In en, this message translates to:
  /// **'Recreational flight in the Open Category needs no license. Drones under 250 g are essentially deregulated. Keep VLOS, daytime, max 122 m and away from people.'**
  String get resRecSummary;

  /// No description provided for @resRegSummary.
  ///
  /// In en, this message translates to:
  /// **'Register as an operator with ANAC. Registration enables full Open Category operation and is the first step to request Specific Category authorizations.'**
  String get resRegSummary;

  /// No description provided for @resComSummary.
  ///
  /// In en, this message translates to:
  /// **'For commercial or higher-risk operations (Specific Category) you need an ANAC operational authorization: risk assessment (SORA) and an operations manual.'**
  String get resComSummary;

  /// No description provided for @resSpecSummary.
  ///
  /// In en, this message translates to:
  /// **'To fly in controlled airspace or restricted areas you need a case-by-case permit: coordination with the control tower (ATC), the National Parks Administration, or the facility authority.'**
  String get resSpecSummary;

  /// No description provided for @r1Title.
  ///
  /// In en, this message translates to:
  /// **'Drone regulations (ANAC)'**
  String get r1Title;

  /// No description provided for @r1Desc.
  ///
  /// In en, this message translates to:
  /// **'Official summary of Resolution 550/2025 and RAAC 100.'**
  String get r1Desc;

  /// No description provided for @r2Title.
  ///
  /// In en, this message translates to:
  /// **'Basic operating rules'**
  String get r2Title;

  /// No description provided for @r2Desc.
  ///
  /// In en, this message translates to:
  /// **'VLOS, daytime, up to 122 m above ground, without flying over people or crowds.'**
  String get r2Desc;

  /// No description provided for @r3Title.
  ///
  /// In en, this message translates to:
  /// **'RPA / RPAS — ANAC procedures'**
  String get r3Title;

  /// No description provided for @r3Desc.
  ///
  /// In en, this message translates to:
  /// **'Official remotely-piloted aircraft page: registration and requirements.'**
  String get r3Desc;

  /// No description provided for @r4Title.
  ///
  /// In en, this message translates to:
  /// **'Trámites a Distancia (TAD)'**
  String get r4Title;

  /// No description provided for @r4Desc.
  ///
  /// In en, this message translates to:
  /// **'The State\'s platform to start registration and authorization procedures online.'**
  String get r4Desc;

  /// No description provided for @r5Title.
  ///
  /// In en, this message translates to:
  /// **'Operational authorization (Specific Category)'**
  String get r5Title;

  /// No description provided for @r5Desc.
  ///
  /// In en, this message translates to:
  /// **'Requirements for night, urban or BVLOS flight. Handled by ANAC.'**
  String get r5Desc;

  /// No description provided for @r6Title.
  ///
  /// In en, this message translates to:
  /// **'Contact ANAC'**
  String get r6Title;

  /// No description provided for @r6Desc.
  ///
  /// In en, this message translates to:
  /// **'Questions about certifications and operational authorizations.'**
  String get r6Desc;

  /// No description provided for @r7Title.
  ///
  /// In en, this message translates to:
  /// **'Controlled airspace (ATC)'**
  String get r7Title;

  /// No description provided for @r7Desc.
  ///
  /// In en, this message translates to:
  /// **'Coordination with the air traffic control unit of the airport involved.'**
  String get r7Desc;

  /// No description provided for @r8Title.
  ///
  /// In en, this message translates to:
  /// **'Protected natural areas (APN)'**
  String get r8Title;

  /// No description provided for @r8Desc.
  ///
  /// In en, this message translates to:
  /// **'Permit from the National Parks Administration to fly in national parks.'**
  String get r8Desc;

  /// No description provided for @r9Title.
  ///
  /// In en, this message translates to:
  /// **'NOTAM / AIP'**
  String get r9Title;

  /// No description provided for @r9Desc.
  ///
  /// In en, this message translates to:
  /// **'Check notices to airmen and the aeronautical information publication before each flight.'**
  String get r9Desc;

  /// No description provided for @plannedAltitude.
  ///
  /// In en, this message translates to:
  /// **'Planned altitude (AGL)'**
  String get plannedAltitude;

  /// No description provided for @plannedAltitudeHintOpen.
  ///
  /// In en, this message translates to:
  /// **'Set takeoff (usually 0 m) through your max altitude. Categoría Abierta is generally up to 122 m AGL. Airspaces along the climb path are included.'**
  String get plannedAltitudeHintOpen;

  /// No description provided for @plannedAltitudeHintExtended.
  ///
  /// In en, this message translates to:
  /// **'Set takeoff through max altitude. Above 122 m requires ANAC Specific Category authorization or a written permit stating your ceiling.'**
  String get plannedAltitudeHintExtended;

  /// No description provided for @altitudeRangeMeters.
  ///
  /// In en, this message translates to:
  /// **'{min}–{max} m AGL'**
  String altitudeRangeMeters(String min, String max);

  /// No description provided for @altitudeRangeConsidered.
  ///
  /// In en, this message translates to:
  /// **'Altitude considered: {min}–{max} m AGL'**
  String altitudeRangeConsidered(String min, String max);

  /// No description provided for @altitudeMeters.
  ///
  /// In en, this message translates to:
  /// **'{meters} m AGL'**
  String altitudeMeters(String meters);

  /// No description provided for @altitudeConsidered.
  ///
  /// In en, this message translates to:
  /// **'Altitude considered: {meters} m AGL'**
  String altitudeConsidered(String meters);

  /// No description provided for @zoneVerticalUnknown.
  ///
  /// In en, this message translates to:
  /// **'Active at all altitudes (vertical limits unknown)'**
  String get zoneVerticalUnknown;

  /// No description provided for @zoneVerticalRangeAgl.
  ///
  /// In en, this message translates to:
  /// **'{lower}–{upper} m AGL'**
  String zoneVerticalRangeAgl(Object lower, Object upper);

  /// No description provided for @zoneVerticalFloorAgl.
  ///
  /// In en, this message translates to:
  /// **'Floor: {lower} m AGL'**
  String zoneVerticalFloorAgl(Object lower);

  /// No description provided for @zoneVerticalCeilingAgl.
  ///
  /// In en, this message translates to:
  /// **'Ceiling: {upper} m AGL'**
  String zoneVerticalCeilingAgl(Object upper);

  /// No description provided for @zoneVerticalFloorMsl.
  ///
  /// In en, this message translates to:
  /// **'Floor: {lower} m MSL (approx.)'**
  String zoneVerticalFloorMsl(Object lower);

  /// No description provided for @zoneVerticalCeilingMsl.
  ///
  /// In en, this message translates to:
  /// **'Ceiling: {upper} m MSL (approx.)'**
  String zoneVerticalCeilingMsl(Object upper);

  /// No description provided for @zonesSkippedByAltitude.
  ///
  /// In en, this message translates to:
  /// **'Not active at your altitude (for reference)'**
  String get zonesSkippedByAltitude;

  /// No description provided for @zoneSkippedAltitude.
  ///
  /// In en, this message translates to:
  /// **'Inactive at your planned altitude'**
  String get zoneSkippedAltitude;

  /// No description provided for @mslGroundElevationDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'MSL altitude limits assume sea-level ground nearby. In mountains, vertical checks may be approximate.'**
  String get mslGroundElevationDisclaimer;

  /// No description provided for @minimumFlightRequirement.
  ///
  /// In en, this message translates to:
  /// **'Minimum required: {label} ({category})'**
  String minimumFlightRequirement(Object label, Object category);

  /// No description provided for @flightNotPossibleHere.
  ///
  /// In en, this message translates to:
  /// **'Flight is not possible here with any standard authorization.'**
  String get flightNotPossibleHere;

  /// No description provided for @controlledAirspaceCoordination.
  ///
  /// In en, this message translates to:
  /// **'Controlled airspace nearby — coordinate with ATC before flying. Your authorization does not replace tower clearance.'**
  String get controlledAirspaceCoordination;

  /// No description provided for @permCommercialConfigHint.
  ///
  /// In en, this message translates to:
  /// **'National ANAC Specific Category authorization. Does not replace local ATC or site clearance.'**
  String get permCommercialConfigHint;

  /// No description provided for @permSpecialConfigHint.
  ///
  /// In en, this message translates to:
  /// **'You already have case-by-case approval for this location (ATC, APN, facility).'**
  String get permSpecialConfigHint;

  /// No description provided for @authLoginTitle.
  ///
  /// In en, this message translates to:
  /// **'Log in'**
  String get authLoginTitle;

  /// No description provided for @authSignUpTitle.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get authSignUpTitle;

  /// No description provided for @authSignUpPrompt.
  ///
  /// In en, this message translates to:
  /// **'Need an account? Sign up'**
  String get authSignUpPrompt;

  /// No description provided for @authEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get authEmail;

  /// No description provided for @authPassword.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get authPassword;

  /// No description provided for @authHandle.
  ///
  /// In en, this message translates to:
  /// **'Handle'**
  String get authHandle;

  /// No description provided for @authDisplayName.
  ///
  /// In en, this message translates to:
  /// **'Display name'**
  String get authDisplayName;

  /// No description provided for @authAccount.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get authAccount;

  /// No description provided for @authLogOut.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get authLogOut;

  /// No description provided for @authLogIn.
  ///
  /// In en, this message translates to:
  /// **'Log in'**
  String get authLogIn;

  /// No description provided for @authLoginFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not log in. Check your credentials and connection.'**
  String get authLoginFailed;

  /// No description provided for @authContinueWithoutAccount.
  ///
  /// In en, this message translates to:
  /// **'Continue without account'**
  String get authContinueWithoutAccount;

  /// No description provided for @splashLoading.
  ///
  /// In en, this message translates to:
  /// **'Checking your session…'**
  String get splashLoading;

  /// No description provided for @weatherAdvisoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Weather advisory'**
  String get weatherAdvisoryTitle;

  /// No description provided for @weatherWind.
  ///
  /// In en, this message translates to:
  /// **'Wind {speed} m/s · gusts {gust} m/s'**
  String weatherWind(Object speed, Object gust);

  /// No description provided for @weatherDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'Advisory only — pilot responsibility under RAAC 100.'**
  String get weatherDisclaimer;

  /// No description provided for @weatherReasonSmnAlert.
  ///
  /// In en, this message translates to:
  /// **'Active weather alert (SMN)'**
  String get weatherReasonSmnAlert;

  /// No description provided for @weatherReasonWindHigh.
  ///
  /// In en, this message translates to:
  /// **'Wind too strong for safe flight'**
  String get weatherReasonWindHigh;

  /// No description provided for @weatherReasonWindElevated.
  ///
  /// In en, this message translates to:
  /// **'Wind elevated for light drones'**
  String get weatherReasonWindElevated;

  /// No description provided for @weatherReasonWindModerate.
  ///
  /// In en, this message translates to:
  /// **'Caution: moderate wind'**
  String get weatherReasonWindModerate;

  /// No description provided for @weatherReasonFavorable.
  ///
  /// In en, this message translates to:
  /// **'Favorable conditions'**
  String get weatherReasonFavorable;

  /// No description provided for @mapLayerZones.
  ///
  /// In en, this message translates to:
  /// **'Zones'**
  String get mapLayerZones;

  /// No description provided for @mapLayerWind.
  ///
  /// In en, this message translates to:
  /// **'Wind'**
  String get mapLayerWind;

  /// No description provided for @mapWindOverlayToggle.
  ///
  /// In en, this message translates to:
  /// **'Show wind gusts'**
  String get mapWindOverlayToggle;

  /// No description provided for @mapWindLegendTitle.
  ///
  /// In en, this message translates to:
  /// **'Wind gusts (10 m)'**
  String get mapWindLegendTitle;

  /// No description provided for @mapWindLegendUnit.
  ///
  /// In en, this message translates to:
  /// **'m/s'**
  String get mapWindLegendUnit;

  /// No description provided for @openMeteoAttribution.
  ///
  /// In en, this message translates to:
  /// **'© Open-Meteo · DWD ICON'**
  String get openMeteoAttribution;

  /// No description provided for @weatherLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading weather…'**
  String get weatherLoading;

  /// No description provided for @weatherRequiresAuth.
  ///
  /// In en, this message translates to:
  /// **'Sign in to see weather for this point.'**
  String get weatherRequiresAuth;

  /// No description provided for @weatherFetchFailed.
  ///
  /// In en, this message translates to:
  /// **'Weather unavailable. Zone check still applies.'**
  String get weatherFetchFailed;

  /// No description provided for @zoneFeedStale.
  ///
  /// In en, this message translates to:
  /// **'Zone data may be outdated (version {version}).'**
  String zoneFeedStale(Object version);

  /// No description provided for @weatherAlertsTitle.
  ///
  /// In en, this message translates to:
  /// **'Weather alerts'**
  String get weatherAlertsTitle;

  /// No description provided for @weatherAlertSave.
  ///
  /// In en, this message translates to:
  /// **'Alert me here'**
  String get weatherAlertSave;

  /// No description provided for @weatherAlertSaved.
  ///
  /// In en, this message translates to:
  /// **'Weather alert saved.'**
  String get weatherAlertSaved;

  /// No description provided for @weatherAlertLabel.
  ///
  /// In en, this message translates to:
  /// **'Location name'**
  String get weatherAlertLabel;

  /// No description provided for @weatherAlertEmpty.
  ///
  /// In en, this message translates to:
  /// **'No saved weather alerts.'**
  String get weatherAlertEmpty;

  /// No description provided for @weatherAlertWindThreshold.
  ///
  /// In en, this message translates to:
  /// **'Wind alert at {speed} m/s'**
  String weatherAlertWindThreshold(Object speed);

  /// No description provided for @socialFeedTitle.
  ///
  /// In en, this message translates to:
  /// **'Community feed'**
  String get socialFeedTitle;

  /// No description provided for @socialFeedEmpty.
  ///
  /// In en, this message translates to:
  /// **'No reels yet. Follow pilots to see their fly-check photos and videos here.'**
  String get socialFeedEmpty;

  /// No description provided for @socialCreatePostMediaHint.
  ///
  /// In en, this message translates to:
  /// **'A snapshot from your fly check will be attached when you publish.'**
  String get socialCreatePostMediaHint;

  /// No description provided for @socialFeedLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load the feed.'**
  String get socialFeedLoadFailed;

  /// No description provided for @socialFeedOffline.
  ///
  /// In en, this message translates to:
  /// **'Offline — showing saved posts'**
  String get socialFeedOffline;

  /// No description provided for @socialShareFlyCheck.
  ///
  /// In en, this message translates to:
  /// **'Share fly check'**
  String get socialShareFlyCheck;

  /// No description provided for @socialCreatePostTitle.
  ///
  /// In en, this message translates to:
  /// **'Share fly check'**
  String get socialCreatePostTitle;

  /// No description provided for @socialCreatePostHint.
  ///
  /// In en, this message translates to:
  /// **'Add a caption for your followers (optional).'**
  String get socialCreatePostHint;

  /// No description provided for @socialCaptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Caption'**
  String get socialCaptionLabel;

  /// No description provided for @socialPublish.
  ///
  /// In en, this message translates to:
  /// **'Publish'**
  String get socialPublish;

  /// No description provided for @socialPostTitle.
  ///
  /// In en, this message translates to:
  /// **'Post'**
  String get socialPostTitle;

  /// No description provided for @socialPostLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load this post.'**
  String get socialPostLoadFailed;

  /// No description provided for @socialComments.
  ///
  /// In en, this message translates to:
  /// **'Comments'**
  String get socialComments;

  /// No description provided for @socialCommentsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No comments yet.'**
  String get socialCommentsEmpty;

  /// No description provided for @socialCommentHint.
  ///
  /// In en, this message translates to:
  /// **'Write a comment…'**
  String get socialCommentHint;

  /// No description provided for @socialFollow.
  ///
  /// In en, this message translates to:
  /// **'Follow'**
  String get socialFollow;

  /// No description provided for @socialFollowRequest.
  ///
  /// In en, this message translates to:
  /// **'Request follow'**
  String get socialFollowRequest;

  /// No description provided for @socialPosts.
  ///
  /// In en, this message translates to:
  /// **'Posts'**
  String get socialPosts;

  /// No description provided for @socialProfileLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load this profile.'**
  String get socialProfileLoadFailed;

  /// No description provided for @socialProfilePostsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No posts yet.'**
  String get socialProfilePostsEmpty;

  /// No description provided for @navFeed.
  ///
  /// In en, this message translates to:
  /// **'Feed'**
  String get navFeed;

  /// No description provided for @navExplore.
  ///
  /// In en, this message translates to:
  /// **'Explore'**
  String get navExplore;

  /// No description provided for @navMap.
  ///
  /// In en, this message translates to:
  /// **'Map'**
  String get navMap;

  /// No description provided for @navMessages.
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get navMessages;

  /// No description provided for @navProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get navProfile;

  /// No description provided for @exploreSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search pilots by @handle'**
  String get exploreSearchHint;

  /// No description provided for @exploreShortcuts.
  ///
  /// In en, this message translates to:
  /// **'Shortcuts'**
  String get exploreShortcuts;

  /// No description provided for @exploreResourcesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Permits, guides, and official links'**
  String get exploreResourcesSubtitle;

  /// No description provided for @exploreMapSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Check where you can fly'**
  String get exploreMapSubtitle;

  /// No description provided for @messagesRequiresAuth.
  ///
  /// In en, this message translates to:
  /// **'Sign in to view your messages.'**
  String get messagesRequiresAuth;

  /// No description provided for @messagesEmpty.
  ///
  /// In en, this message translates to:
  /// **'No conversations yet'**
  String get messagesEmpty;

  /// No description provided for @messagesEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Direct messages with other pilots will appear here.'**
  String get messagesEmptySubtitle;

  /// No description provided for @messagesLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load your messages.'**
  String get messagesLoadFailed;

  /// No description provided for @chatLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load this conversation.'**
  String get chatLoadFailed;

  /// No description provided for @chatEmpty.
  ///
  /// In en, this message translates to:
  /// **'No messages yet. Say hello!'**
  String get chatEmpty;

  /// No description provided for @chatInputHint.
  ///
  /// In en, this message translates to:
  /// **'Message…'**
  String get chatInputHint;

  /// No description provided for @socialMessage.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get socialMessage;

  /// No description provided for @socialMessageOpenFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not start this conversation.'**
  String get socialMessageOpenFailed;

  /// No description provided for @notificationPrefsTitle.
  ///
  /// In en, this message translates to:
  /// **'Push notifications'**
  String get notificationPrefsTitle;

  /// No description provided for @notificationPrefsFollows.
  ///
  /// In en, this message translates to:
  /// **'New followers'**
  String get notificationPrefsFollows;

  /// No description provided for @notificationPrefsMessages.
  ///
  /// In en, this message translates to:
  /// **'Direct messages'**
  String get notificationPrefsMessages;

  /// No description provided for @notificationPrefsComments.
  ///
  /// In en, this message translates to:
  /// **'Comments on your posts'**
  String get notificationPrefsComments;

  /// No description provided for @notificationPrefsWeather.
  ///
  /// In en, this message translates to:
  /// **'Weather alerts'**
  String get notificationPrefsWeather;

  /// No description provided for @notificationPrefsLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load notification settings.'**
  String get notificationPrefsLoadFailed;

  /// No description provided for @profileSignInPrompt.
  ///
  /// In en, this message translates to:
  /// **'Sign in to see your profile, posts, and saved alerts.'**
  String get profileSignInPrompt;

  /// No description provided for @socialFlyCheckMissing.
  ///
  /// In en, this message translates to:
  /// **'Missing fly-check data.'**
  String get socialFlyCheckMissing;

  /// No description provided for @socialReelBadge.
  ///
  /// In en, this message translates to:
  /// **'REEL'**
  String get socialReelBadge;

  /// No description provided for @socialReelRetryVideo.
  ///
  /// In en, this message translates to:
  /// **'Retry video'**
  String get socialReelRetryVideo;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
