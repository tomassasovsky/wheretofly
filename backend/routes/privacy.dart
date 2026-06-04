import 'package:dart_frog/dart_frog.dart';

Response onRequest(RequestContext context) {
  if (context.request.method != HttpMethod.get) {
    return Response(statusCode: 405);
  }

  final lang = context.request.headers['Accept-Language'] ?? '';
  final isSpanish = lang.toLowerCase().startsWith('es');

  return isSpanish ? _spanish() : _english();
}

Response _english() => Response(
  headers: {'Content-Type': 'text/html; charset=utf-8'},
  body: '''
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Privacy Policy — Where To Fly</title>
  <style>
    body { font-family: system-ui, sans-serif; max-width: 720px; margin: 2rem auto; padding: 0 1.5rem; line-height: 1.6; color: #1a1a1a; }
    h1 { font-size: 1.75rem; margin-bottom: 0.25rem; }
    h2 { font-size: 1.15rem; margin-top: 2rem; }
    p, li { font-size: 0.97rem; }
    a { color: #0057b8; }
    .updated { color: #666; font-size: 0.875rem; margin-bottom: 2rem; }
  </style>
</head>
<body>
  <h1>Privacy Policy</h1>
  <p class="updated">Last updated: June 4, 2025</p>

  <p><strong>Where To Fly</strong> ("the app") is developed by Tomás Sasovsky. This policy explains what data we collect, how we use it, and your rights over it.</p>

  <h2>1. Data We Collect</h2>
  <ul>
    <li><strong>Account information</strong> — email address and password hash (if you register), or your name and profile picture via Google / Apple Sign-In.</li>
    <li><strong>Location</strong> — only when you tap "locate me". Location is used on-device to center the map and is never stored on our servers.</li>
    <li><strong>Usage data</strong> — anonymous crash reports and performance metrics via Flutter diagnostics. No personally identifiable information is included.</li>
    <li><strong>Device push token</strong> — if you enable weather alerts, your device token is stored to deliver notifications.</li>
  </ul>

  <h2>2. How We Use Your Data</h2>
  <ul>
    <li>To authenticate you and maintain your session.</li>
    <li>To send weather alerts and notifications you have subscribed to.</li>
    <li>To improve app stability via anonymous diagnostics.</li>
  </ul>

  <h2>3. Data Sharing</h2>
  <p>We do not sell your data. We share it only with:</p>
  <ul>
    <li><strong>Google / Apple</strong> — when you use social sign-in (subject to their own privacy policies).</li>
    <li><strong>Our infrastructure providers</strong> — for hosting and storage, under data-processing agreements.</li>
  </ul>

  <h2>4. Data Retention</h2>
  <p>Your account data is kept for as long as your account is active. You may request deletion at any time (see Section 6).</p>

  <h2>5. Security</h2>
  <p>Passwords are hashed with bcrypt and never stored in plain text. All traffic between the app and our servers uses HTTPS/TLS.</p>

  <h2>6. Your Rights</h2>
  <p>You may request access to, correction of, or deletion of your personal data by emailing <a href="mailto:tomas@aquiles.dev">tomas@aquiles.dev</a>. We will respond within 30 days.</p>

  <h2>7. Children</h2>
  <p>The app is not directed at children under 13. We do not knowingly collect data from children.</p>

  <h2>8. Changes to This Policy</h2>
  <p>We may update this policy. The current version is always available at <a href="https://dondevolar.aquiles.dev/privacy">dondevolar.aquiles.dev/privacy</a>. Continued use of the app after changes constitutes acceptance.</p>

  <h2>9. Contact</h2>
  <p><a href="mailto:tomas@aquiles.dev">tomas@aquiles.dev</a></p>
</body>
</html>''',
);

Response _spanish() => Response(
  headers: {'Content-Type': 'text/html; charset=utf-8'},
  body: '''
<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Política de Privacidad — Dónde Vuelo</title>
  <style>
    body { font-family: system-ui, sans-serif; max-width: 720px; margin: 2rem auto; padding: 0 1.5rem; line-height: 1.6; color: #1a1a1a; }
    h1 { font-size: 1.75rem; margin-bottom: 0.25rem; }
    h2 { font-size: 1.15rem; margin-top: 2rem; }
    p, li { font-size: 0.97rem; }
    a { color: #0057b8; }
    .updated { color: #666; font-size: 0.875rem; margin-bottom: 2rem; }
  </style>
</head>
<body>
  <h1>Política de Privacidad</h1>
  <p class="updated">Última actualización: 4 de junio de 2025</p>

  <p><strong>Dónde Vuelo</strong> ("la app") es desarrollada por Tomás Sasovsky. Esta política explica qué datos recopilamos, cómo los usamos y tus derechos sobre ellos.</p>

  <h2>1. Datos que recopilamos</h2>
  <ul>
    <li><strong>Información de cuenta</strong> — correo electrónico y contraseña hasheada (si te registrás), o tu nombre y foto de perfil mediante Google / Apple Sign-In.</li>
    <li><strong>Ubicación</strong> — solo cuando tocás "ubicarme". La ubicación se usa en el dispositivo para centrar el mapa y nunca se almacena en nuestros servidores.</li>
    <li><strong>Datos de uso</strong> — reportes de errores y métricas de rendimiento anónimos. No incluyen información de identificación personal.</li>
    <li><strong>Token de notificaciones</strong> — si activás alertas meteorológicas, tu token de dispositivo se almacena para enviar notificaciones.</li>
  </ul>

  <h2>2. Cómo usamos tus datos</h2>
  <ul>
    <li>Para autenticarte y mantener tu sesión.</li>
    <li>Para enviarte alertas meteorológicas y notificaciones a las que te suscribiste.</li>
    <li>Para mejorar la estabilidad de la app mediante diagnósticos anónimos.</li>
  </ul>

  <h2>3. Compartir datos</h2>
  <p>No vendemos tus datos. Solo los compartimos con:</p>
  <ul>
    <li><strong>Google / Apple</strong> — cuando usás inicio de sesión social (sujeto a sus propias políticas de privacidad).</li>
    <li><strong>Nuestros proveedores de infraestructura</strong> — para alojamiento y almacenamiento, bajo acuerdos de procesamiento de datos.</li>
  </ul>

  <h2>4. Retención de datos</h2>
  <p>Tus datos de cuenta se conservan mientras la cuenta esté activa. Podés solicitar su eliminación en cualquier momento (ver Sección 6).</p>

  <h2>5. Seguridad</h2>
  <p>Las contraseñas se hashean con bcrypt y nunca se almacenan en texto plano. Todo el tráfico entre la app y nuestros servidores usa HTTPS/TLS.</p>

  <h2>6. Tus derechos</h2>
  <p>Podés solicitar acceso, corrección o eliminación de tus datos personales escribiendo a <a href="mailto:tomas@aquiles.dev">tomas@aquiles.dev</a>. Respondemos en un plazo de 30 días.</p>

  <h2>7. Menores de edad</h2>
  <p>La app no está dirigida a menores de 13 años. No recopilamos datos de menores de manera intencional.</p>

  <h2>8. Cambios en esta política</h2>
  <p>Podemos actualizar esta política. La versión vigente siempre estará disponible en <a href="https://dondevolar.aquiles.dev/privacy">dondevolar.aquiles.dev/privacy</a>. El uso continuado de la app implica la aceptación de los cambios.</p>

  <h2>9. Contacto</h2>
  <p><a href="mailto:tomas@aquiles.dev">tomas@aquiles.dev</a></p>
</body>
</html>''',
);
