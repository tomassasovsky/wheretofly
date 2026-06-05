// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'Dónde Volar · Argentina';

  @override
  String get yourPermission => 'Tu permiso';

  @override
  String get tapHint =>
      'Tocá un punto del mapa para ver si podés volar. Datos orientativos — verificá siempre con ANAC antes de operar.';

  @override
  String get permissionsAndResources => 'Permisos y recursos';

  @override
  String get verdictAllowed => 'Podés volar aquí';

  @override
  String get verdictAllowedWithPermission => 'Podés volar con tu permiso';

  @override
  String get verdictNotAllowed => 'No podés volar aquí';

  @override
  String permissionConsidered(Object label, Object category) {
    return 'Permiso considerado: $label ($category)';
  }

  @override
  String get noZones =>
      'No hay zonas restringidas registradas en este punto. Aplican las reglas generales de la Categoría Abierta: VLOS, de día, hasta 122 m y lejos de personas.';

  @override
  String get coversZone => '✓ Tu permiso cubre esta zona';

  @override
  String get notCoversZone => '✗ Tu permiso no cubre esta zona';

  @override
  String get howToRequest => 'Cómo solicitar permiso';

  @override
  String get recommendedPermitGuide => 'Recomendado para este punto';

  @override
  String get resourcesTitle => 'Permisos y recursos';

  @override
  String get resourcesIntro =>
      'Cómo solicitar cada nivel de permiso en Argentina. Los enlaces abren páginas oficiales de ANAC y del Estado. Esta guía es orientativa: la fuente válida es ANAC.';

  @override
  String get locateMe => 'Usar mi ubicación';

  @override
  String couldNotOpen(Object url) {
    return 'No se pudo abrir $url';
  }

  @override
  String get locationServiceDisabled =>
      'El servicio de ubicación está desactivado. Activalo e intentá de nuevo.';

  @override
  String get locationPermissionDenied => 'Permiso de ubicación denegado.';

  @override
  String get locationPermissionDeniedForever =>
      'Permiso de ubicación denegado permanentemente. Habilitalo en la configuración del sistema.';

  @override
  String get locationUnavailable => 'No se pudo obtener tu ubicación.';

  @override
  String get outsideArgentina =>
      'Este punto puede estar fuera de Argentina. Los datos de zonas pueden estar incompletos o no estar disponibles.';

  @override
  String get searchHint => 'Ciudad o dirección';

  @override
  String get searchNoResults => 'No se encontraron resultados.';

  @override
  String get searchNetworkError => 'No se pudo buscar. Revisá tu conexión.';

  @override
  String get language => 'Idioma';

  @override
  String get languageSystem => 'Predeterminado del sistema';

  @override
  String get languageSpanish => 'Español';

  @override
  String get languageEnglish => 'English';

  @override
  String get settings => 'Ajustes';

  @override
  String get attributions => 'Licencias y atribuciones';

  @override
  String get attributionsSubtitle => 'Mapa, clima y paquetes de código abierto';

  @override
  String get theme => 'Apariencia';

  @override
  String get themeSystem => 'Sistema';

  @override
  String get themeLight => 'Claro';

  @override
  String get themeDark => 'Oscuro';

  @override
  String get cancel => 'Cancelar';

  @override
  String get flightModality => 'Modalidad de vuelo';

  @override
  String modalityRequires(Object modality, Object category) {
    return '$modality requiere $category.';
  }

  @override
  String get tapToCheck => 'Tocá el mapa para consultar un punto';

  @override
  String get done => 'Listo';

  @override
  String get sponsorMe => 'Invitame un cafecito';

  @override
  String get sponsorMeDescription => 'Apoyá el desarrollo en Cafecito.';

  @override
  String get creditsDevelopedBy => 'Desarrollado por Tomás Sasovsky';

  @override
  String get creditsWebsite => 'Sitio web';

  @override
  String get creditsGithub => 'GitHub';

  @override
  String get permRecreational => 'Recreativo / sin licencia';

  @override
  String get permRegistered => 'Piloto registrado ANAC';

  @override
  String get permCommercial => 'Autorizado / comercial';

  @override
  String get permSpecial => 'Permiso especial por zona';

  @override
  String get permRecreationalShort => 'Recreativo';

  @override
  String get permRegisteredShort => 'Registrado';

  @override
  String get permCommercialShort => 'Comercial';

  @override
  String get permSpecialShort => 'Permiso';

  @override
  String get anacAbierta => 'Categoría Abierta';

  @override
  String get anacAbiertaReg => 'Categoría Abierta (registrado)';

  @override
  String get anacEspecifica => 'Categoría Específica';

  @override
  String get anacCaseByCase => 'Autorización caso por caso';

  @override
  String get modVlos => 'Vuelo visual (VLOS)';

  @override
  String get modVlosDesc =>
      'Dentro del alcance visual del piloto, de día. Es la operación base de la Categoría Abierta.';

  @override
  String get modEvlos => 'Visual extendido (EVLOS)';

  @override
  String get modEvlosDesc =>
      'Alcance visual asistido por observadores. Requiere operador registrado.';

  @override
  String get modBvlos => 'BVLOS / FPV';

  @override
  String get modBvlosDesc =>
      'Más allá del alcance visual (incluye FPV inmersivo sin observador). Requiere autorización operacional (Categoría Específica).';

  @override
  String get modNight => 'Vuelo nocturno';

  @override
  String get modNightDesc =>
      'Operación de noche. Requiere autorización operacional (Categoría Específica).';

  @override
  String get modOverPeople => 'Sobre personas';

  @override
  String get modOverPeopleDesc =>
      'Vuelo sobre personas o aglomeraciones. Requiere autorización operacional (Categoría Específica).';

  @override
  String get zcControlled => 'Espacio aéreo controlado (CTR)';

  @override
  String get zcProhibited => 'Zona prohibida';

  @override
  String get zcRestricted => 'Zona restringida';

  @override
  String get zcPark => 'Área natural protegida';

  @override
  String get zcInfra => 'Infraestructura crítica';

  @override
  String get zcOpen => 'Zona abierta';

  @override
  String get resRecSummary =>
      'Para vuelo recreativo en Categoría Abierta no necesitás licencia. Los drones de menos de 250 g están prácticamente desregulados. Respetá VLOS, día, máximo 122 m y lejos de personas.';

  @override
  String get resRegSummary =>
      'Inscribite como operador en ANAC. El registro habilita la operación plena en Categoría Abierta y es el primer paso para pedir autorizaciones de la Categoría Específica.';

  @override
  String get resComSummary =>
      'Para operaciones comerciales o de mayor riesgo (Categoría Específica) necesitás una autorización operacional de ANAC: evaluación de riesgo (SORA) y manual de operaciones.';

  @override
  String get resSpecSummary =>
      'Para volar en espacio aéreo controlado o áreas restringidas necesitás un permiso caso por caso: coordinación con la torre (ATC), con la Administración de Parques Nacionales o con la autoridad de la instalación.';

  @override
  String get r1Title => 'Marco normativo de drones (ANAC)';

  @override
  String get r1Desc =>
      'Resumen oficial de la Resolución 550/2025 y la RAAC 100.';

  @override
  String get r2Title => 'Reglas básicas de operación';

  @override
  String get r2Desc =>
      'VLOS, de día, hasta 122 m sobre el terreno, sin sobrevolar personas ni aglomeraciones.';

  @override
  String get r3Title => 'RPA / RPAS — trámites ANAC';

  @override
  String get r3Desc =>
      'Página oficial de aeronaves pilotadas a distancia: registro y requisitos.';

  @override
  String get r4Title => 'Trámites a Distancia (TAD)';

  @override
  String get r4Desc =>
      'Plataforma del Estado para iniciar trámites de registro y habilitación en línea.';

  @override
  String get r5Title => 'Autorización operacional (Categoría Específica)';

  @override
  String get r5Desc =>
      'Requisitos para vuelo nocturno, urbano o BVLOS. Se gestiona ante ANAC.';

  @override
  String get r6Title => 'Contactar a ANAC';

  @override
  String get r6Desc =>
      'Consultas sobre habilitaciones y autorizaciones operacionales.';

  @override
  String get r7Title => 'Espacio aéreo controlado (ATC)';

  @override
  String get r7Desc =>
      'Coordinación con la dependencia de control de tránsito aéreo del aeropuerto involucrado.';

  @override
  String get r8Title => 'Áreas naturales protegidas (APN)';

  @override
  String get r8Desc =>
      'Permiso de la Administración de Parques Nacionales para volar en parques nacionales.';

  @override
  String get r9Title => 'NOTAM / AIP';

  @override
  String get r9Desc =>
      'Consultá avisos a aviadores y la publicación de información aeronáutica antes de cada vuelo.';

  @override
  String get plannedAltitude => 'Altitud prevista (AGL)';

  @override
  String get plannedAltitudeHintOpen =>
      'Configurá despegue (suele ser 0 m) hasta tu altura máxima. La Categoría Abierta suele ser hasta 122 m AGL. Se incluyen espacios en la subida.';

  @override
  String get plannedAltitudeHintExtended =>
      'Configurá despegue hasta altura máxima. Por encima de 122 m necesitás Categoría Específica de ANAC o permiso escrito con tu techo.';

  @override
  String altitudeRangeMeters(String min, String max) {
    return '$min–$max m AGL';
  }

  @override
  String altitudeRangeConsidered(String min, String max) {
    return 'Altitud considerada: $min–$max m AGL';
  }

  @override
  String altitudeMeters(String meters) {
    return '$meters m AGL';
  }

  @override
  String altitudeConsidered(String meters) {
    return 'Altitud considerada: $meters m AGL';
  }

  @override
  String get zoneVerticalUnknown =>
      'Activo a todas las altitudes (límites verticales desconocidos)';

  @override
  String zoneVerticalRangeAgl(Object lower, Object upper) {
    return '$lower–$upper m AGL';
  }

  @override
  String zoneVerticalFloorAgl(Object lower) {
    return 'Piso: $lower m AGL';
  }

  @override
  String zoneVerticalCeilingAgl(Object upper) {
    return 'Techo: $upper m AGL';
  }

  @override
  String zoneVerticalFloorMsl(Object lower) {
    return 'Piso: $lower m MSL (aprox.)';
  }

  @override
  String zoneVerticalCeilingMsl(Object upper) {
    return 'Techo: $upper m MSL (aprox.)';
  }

  @override
  String get zonesSkippedByAltitude => 'No activas a tu altitud (referencia)';

  @override
  String get zoneSkippedAltitude => 'Inactiva a tu altitud prevista';

  @override
  String get mslGroundElevationDisclaimer =>
      'Los límites en MSL asumen suelo a nivel del mar cerca. En montaña, las comprobaciones verticales pueden ser aproximadas.';

  @override
  String minimumFlightRequirement(Object label, Object category) {
    return 'Requisito mínimo: $label ($category)';
  }

  @override
  String get flightNotPossibleHere =>
      'No es posible volar aquí con ninguna autorización estándar.';

  @override
  String get controlledAirspaceCoordination =>
      'Espacio aéreo controlado cerca — coordiná con ATC antes de volar. Tu autorización no reemplaza el clearance de torre.';

  @override
  String get permCommercialConfigHint =>
      'Autorización nacional ANAC de Categoría Específica. No reemplaza coordinación con ATC ni permisos locales.';

  @override
  String get permSpecialConfigHint =>
      'Ya tenés aprobación caso por caso para este lugar (ATC, APN, instalación).';

  @override
  String get authLoginTitle => 'Iniciar sesión';

  @override
  String get authSignUpTitle => 'Crear cuenta';

  @override
  String get authSignUpPrompt => '¿No tenés cuenta? Registrate';

  @override
  String get authEmail => 'Correo';

  @override
  String get authPassword => 'Contraseña';

  @override
  String get authHandle => 'Usuario';

  @override
  String get authDisplayName => 'Nombre visible';

  @override
  String get authAccount => 'Cuenta';

  @override
  String get authLogOut => 'Cerrar sesión';

  @override
  String get authLogIn => 'Iniciar sesión';

  @override
  String get authLoginFailed =>
      'No se pudo iniciar sesión. Revisá tus datos y la conexión.';

  @override
  String get authContinueWithoutAccount => 'Continuar sin cuenta';

  @override
  String get splashLoading => 'Comprobando tu sesión…';

  @override
  String get weatherAdvisoryTitle => 'Alerta meteorológica';

  @override
  String weatherWind(Object speed, Object gust) {
    return 'Viento $speed m/s · ráfagas $gust m/s';
  }

  @override
  String get weatherDisclaimer =>
      'Solo orientativo — responsabilidad del piloto según RAAC 100.';

  @override
  String get weatherReasonSmnAlert => 'Alerta meteorológica activa (SMN)';

  @override
  String get weatherReasonWindHigh => 'Viento demasiado fuerte para volar';

  @override
  String get weatherReasonWindElevated => 'Viento elevado para drones ligeros';

  @override
  String get weatherReasonWindModerate => 'Precaución por viento moderado';

  @override
  String get weatherReasonFavorable => 'Condiciones favorables';

  @override
  String get mapLayerZones => 'Zonas';

  @override
  String get mapLayerWind => 'Viento';

  @override
  String get mapWindOverlayToggle => 'Mostrar ráfagas de viento';

  @override
  String get mapWindLegendTitle => 'Ráfagas de viento (10 m)';

  @override
  String get mapWindLegendUnit => 'm/s';

  @override
  String get openMeteoAttribution => '© Open-Meteo · DWD ICON';

  @override
  String get weatherLoading => 'Cargando clima…';

  @override
  String get weatherRequiresAuth =>
      'Iniciá sesión para ver el clima en este punto.';

  @override
  String get weatherFetchFailed =>
      'Clima no disponible. La verificación de zona sigue vigente.';

  @override
  String get weatherNetworkTimeout =>
      'El clima tardó demasiado. Probá de nuevo en un momento.';

  @override
  String get weatherRateLimited =>
      'El servicio de clima está saturado. Esperá un minuto y probá de nuevo.';

  @override
  String get weatherUpstreamUnavailable =>
      'El servicio de clima no responde. La verificación de zona sigue vigente.';

  @override
  String zoneFeedStale(Object version) {
    return 'Los datos de zonas pueden estar desactualizados (versión $version).';
  }

  @override
  String get weatherAlertsTitle => 'Alertas meteorológicas';

  @override
  String get weatherAlertSave => 'Alertarme aquí';

  @override
  String get weatherAlertSaved => 'Alerta meteorológica guardada.';

  @override
  String get weatherAlertLabel => 'Nombre del lugar';

  @override
  String get weatherAlertEmpty => 'No hay alertas meteorológicas guardadas.';

  @override
  String weatherAlertWindThreshold(Object speed) {
    return 'Alerta de viento a $speed m/s';
  }

  @override
  String get socialFeedTitle => 'Comunidad';

  @override
  String get socialFeedEmpty =>
      'Todavía no hay reels. Seguí pilotos para ver sus fotos y videos de consultas de vuelo.';

  @override
  String get socialCreatePostMediaHint =>
      'Se adjuntará una imagen de tu consulta de vuelo al publicar.';

  @override
  String get socialFeedLoadFailed => 'No se pudo cargar el feed.';

  @override
  String get socialFeedOffline =>
      'Sin conexión — mostrando publicaciones guardadas';

  @override
  String get socialShareFlyCheck => 'Compartir consulta';

  @override
  String get socialCreatePostTitle => 'Compartir consulta';

  @override
  String get socialCreatePostHint =>
      'Agregá un comentario para tus seguidores (opcional).';

  @override
  String get socialCaptionLabel => 'Comentario';

  @override
  String get socialPublish => 'Publicar';

  @override
  String get socialPostTitle => 'Publicación';

  @override
  String get socialPostLoadFailed => 'No se pudo cargar esta publicación.';

  @override
  String get socialComments => 'Comentarios';

  @override
  String get socialCommentsEmpty => 'Todavía no hay comentarios.';

  @override
  String get socialCommentHint => 'Escribí un comentario…';

  @override
  String get socialFollow => 'Seguir';

  @override
  String get socialFollowRequest => 'Solicitar seguimiento';

  @override
  String get socialPosts => 'Publicaciones';

  @override
  String get socialProfileLoadFailed => 'No se pudo cargar este perfil.';

  @override
  String get socialProfilePostsEmpty => 'Todavía no hay publicaciones.';

  @override
  String get navFeed => 'Inicio';

  @override
  String get navExplore => 'Explorar';

  @override
  String get navMap => 'Mapa';

  @override
  String get navMessages => 'Mensajes';

  @override
  String get navProfile => 'Perfil';

  @override
  String get exploreSearchHint => 'Buscar pilotos por @usuario';

  @override
  String get exploreShortcuts => 'Accesos directos';

  @override
  String get exploreResourcesSubtitle => 'Permisos, guías y enlaces oficiales';

  @override
  String get exploreMapSubtitle => 'Consultá dónde podés volar';

  @override
  String get messagesRequiresAuth => 'Iniciá sesión para ver tus mensajes.';

  @override
  String get messagesEmpty => 'Todavía no hay conversaciones';

  @override
  String get messagesEmptySubtitle =>
      'Los mensajes directos con otros pilotos aparecerán aquí.';

  @override
  String get messagesLoadFailed => 'No se pudieron cargar tus mensajes.';

  @override
  String get chatLoadFailed => 'No se pudo cargar esta conversación.';

  @override
  String get chatEmpty => 'Todavía no hay mensajes. ¡Saludá!';

  @override
  String get chatInputHint => 'Mensaje…';

  @override
  String get socialMessage => 'Mensaje';

  @override
  String get socialMessageOpenFailed => 'No se pudo iniciar esta conversación.';

  @override
  String get notificationPrefsTitle => 'Notificaciones push';

  @override
  String get notificationPrefsFollows => 'Nuevos seguidores';

  @override
  String get notificationPrefsMessages => 'Mensajes directos';

  @override
  String get notificationPrefsComments => 'Comentarios en tus publicaciones';

  @override
  String get notificationPrefsWeather => 'Alertas meteorológicas';

  @override
  String get notificationPrefsLoadFailed =>
      'No se pudieron cargar las preferencias de notificación.';

  @override
  String get profileSignInPrompt =>
      'Iniciá sesión para ver tu perfil, publicaciones y alertas.';

  @override
  String get socialFlyCheckMissing => 'Faltan datos de la consulta de vuelo.';

  @override
  String get socialReelBadge => 'REEL';

  @override
  String get socialReelRetryVideo => 'Reintentar video';

  @override
  String get flightDataSourcesTitle => 'De dónde salen los datos';

  @override
  String get flightDataSourcesIntro =>
      'Esta app te ayuda a explorar dónde podés volar según la normativa argentina de drones. Combina datos públicos, zonas curadas y el nivel de permiso que elijas. Solo orientativo: confirmá siempre con ANAC, NOTAM y el AIP oficial antes de operar.';

  @override
  String get flightDataSourcesHowWeDecideTitle =>
      'Cómo decidimos si podés volar';

  @override
  String get flightDataSourcesHowWeDecideBody =>
      'Al tocar el mapa, verificamos si algún círculo de restricción cubre ese punto y si tu nivel de permiso y modalidad de vuelo (recreativo, comercial, etc.) están permitidos. Las reglas de altitud y VLOS de la Res. ANAC 550/2025 y el RAAC 100 se resumen en el veredicto.';

  @override
  String get flightDataSourcesPermissionsTitle => 'Tu permiso y modalidad';

  @override
  String get flightDataSourcesPermissionsBody =>
      'Las categorías de permiso (categoría abierta recreativa, categoría específica, operador certificado, etc.) siguen el marco de ANAC (Res. 550/2025 y RAAC 100). Las elegís en la app; no se descargan de una API gubernamental. En Permisos y recursos está cómo obtener cada autorización.';

  @override
  String get flightDataSourcesZonesTitle => 'Zonas de restricción en el mapa';

  @override
  String get flightDataSourcesZoneMadhelTitle => 'ANAC MADHEL';

  @override
  String get flightDataSourcesZoneMadhelBody =>
      'Aeródromos y helipuertos del conjunto abierto MADHEL (ANAC). Se muestran como círculos de protección alrededor de las coordenadas publicadas. La app también guarda una copia empaquetada para uso sin conexión.';

  @override
  String get flightDataSourcesZoneOpenAipTitle => 'OpenAIP';

  @override
  String get flightDataSourcesZoneOpenAipBody =>
      'Espacio aéreo mantenido por la comunidad (áreas controladas, restricciones, etc.) desde exportaciones de OpenAIP, fusionadas en el servidor cuando está configurado. Las zonas se aproximan como círculos por rendimiento.';

  @override
  String get flightDataSourcesZoneCuratedTitle => 'Zonas curadas';

  @override
  String get flightDataSourcesZoneCuratedBody =>
      'Círculos adicionales para parques, infraestructura crítica y otras áreas del proyecto. No son polígonos oficiales en vivo.';

  @override
  String get flightDataSourcesZoneFeedTitle => 'Feed de zonas de Dónde Volar';

  @override
  String get flightDataSourcesZoneFeedBody =>
      'El backend fusiona MADHEL, OpenAIP y fuentes curadas en un feed GeoJSON publicado. La app descarga actualizaciones por API cuando hay red y usa la última copia en caché o empaquetada si no.';

  @override
  String get flightDataSourcesSearchTitle => 'Búsqueda de lugares';

  @override
  String get flightDataSourcesSearchBody =>
      'La búsqueda de ciudad o dirección pasa por la API de Dónde Volar, que consulta un Photon autoalojado con datos de OpenStreetMap (índice Argentina). Contiene datos © colaboradores OSM bajo ODbL.';

  @override
  String get flightDataSourcesWeatherTitle => 'Advisory meteorológico';

  @override
  String get flightDataSourcesWeatherBody =>
      'Viento y temperatura en el punto tocado provienen de Open-Meteo (DWD ICON). Las alertas cortas activas usan el feed CAP RSS del SMN. El clima no cambia la geometría de zonas; solo agrega una capa de aviso.';

  @override
  String get flightDataSourcesWeatherOpenMeteoTitle => 'Open-Meteo';

  @override
  String get flightDataSourcesWeatherOpenMeteoBody =>
      'Ráfagas horarias y campos relacionados para la capa de viento y la tarjeta de consulta.';

  @override
  String get flightDataSourcesWeatherSmnTitle =>
      'SMN (Servicio Meteorológico Nacional)';

  @override
  String get flightDataSourcesWeatherSmnBody =>
      'Alertas meteorológicas oficiales de Argentina (CAP RSS) cuando hay un aviso activo en la zona.';

  @override
  String get flightDataSourcesDisclaimer =>
      'Los límites de zona son círculos simplificados y pueden estar incompletos o desactualizados. ANAC, operadores de aeródromo, NOTAM y el AIP oficial son la fuente autoritativa. No operes basándote solo en esta app.';

  @override
  String get flightDataSourcesSettingsSubtitle =>
      'Zonas, marco de permisos, búsqueda y clima';

  @override
  String get flightDataSourcesOpenLink => 'Abrir sitio oficial';

  @override
  String get flightDataSourcesMapLink => '¿De dónde salen estos datos?';

  @override
  String get flightDataSourcesResourcesLink => 'Cómo armamos el mapa';

  @override
  String get privacyPolicy => 'Política de privacidad';

  @override
  String get privacyPolicySubtitle => 'Cómo manejamos tus datos';
}
