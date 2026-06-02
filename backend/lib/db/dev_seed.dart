import 'dart:convert';
import 'dart:math';

import 'package:backend/config/app_config.dart';
import 'package:backend/db/database.dart';
import 'package:backend/services/password_hasher.dart';
import 'package:postgres/postgres.dart';
import 'package:uuid/uuid.dart';

/// Populates the dev database with pilots, posts, follows, DMs, and comments.
class DevSeed {
  DevSeed({
    required Database database,
    PasswordHasher? passwordHasher,
    Uuid? uuid,
    Random? random,
  }) : _db = database,
       _passwordHasher = passwordHasher ?? const PasswordHasher(),
       _uuid = uuid ?? const Uuid(),
       _random = random ?? Random(42);

  static const demoEmail = 'pilot@dev.local';
  static const demoPassword = 'password123';
  static const demoHandle = 'pilot';

  final Database _db;
  final PasswordHasher _passwordHasher;
  final Uuid _uuid;
  final Random _random;

  static const _pilots = [
    (
      handle: 'pilot',
      name: 'Tomas Dev',
      bio: 'Demo account for local testing.',
    ),
    (
      handle: 'anavolar',
      name: 'Ana García',
      bio: 'FPV en CABA · Recreativo ANAC',
    ),
    (
      handle: 'carlos_drone',
      name: 'Carlos Mendoza',
      bio: 'Fotografía aérea · Mendoza',
    ),
    (handle: 'lucia_cba', name: 'Lucía Fernández', bio: 'Mapping en Córdoba'),
    (handle: 'miguel_fpv', name: 'Miguel Torres', bio: 'Freestyle · Palermo'),
    (
      handle: 'sofia_aero',
      name: 'Sofía Ruiz',
      bio: 'Inspecciones industriales',
    ),
    (handle: 'diego_sur', name: 'Diego Herrera', bio: 'Patagonia aerial shots'),
    (
      handle: 'marta_private',
      name: 'Marta López',
      bio: 'Perfil privado · approval only',
    ),
    (
      handle: 'juan_rec',
      name: 'Juan Pérez',
      bio: 'Vuelos recreativos los fines de semana',
    ),
    (
      handle: 'vale_mapping',
      name: 'Valentina Díaz',
      bio: 'Topografía con drone',
    ),
    (handle: 'nico_ba', name: 'Nicolás Castro', bio: 'Buenos Aires · eventos'),
    (
      handle: 'paula_ros',
      name: 'Paula Romero',
      bio: 'Rosario · agricultura de precisión',
    ),
    (handle: 'facu_tandil', name: 'Facundo Álvarez', bio: 'Sierras de Tandil'),
    (handle: 'camila_mza', name: 'Camila Soto', bio: 'Viñedos · Mendoza'),
    (
      handle: 'leo_mar',
      name: 'Leo Martínez',
      bio: 'Costa atlántica · surf spots',
    ),
    (handle: 'elena_uba', name: 'Elena Vargas', bio: 'Investigación · UBA'),
    (handle: 'gus_film', name: 'Gustavo Ríos', bio: 'Cine aéreo'),
    (handle: 'rita_agro', name: 'Rita Morales', bio: 'Pulverización · NEA'),
    (handle: 'bruno_fpv', name: 'Bruno Navarro', bio: 'FPV racing'),
    (
      handle: 'clara_safe',
      name: 'Clara Ibáñez',
      bio: 'Safety first · instructora',
    ),
    (handle: 'hugo_zona', name: 'Hugo Salinas', bio: 'Consultor de zonas RAAC'),
    (handle: 'ines_tuc', name: 'Inés Acosta', bio: 'Tucumán · cañaverales'),
    (handle: 'marcos_lr', name: 'Marcos Delgado', bio: 'La Rioja · minería'),
    (handle: 'dani_salta', name: 'Daniela Ortiz', bio: 'Salta · paisajes'),
    (handle: 'pablo_neu', name: 'Pablo Giménez', bio: 'Neuquén · oil & gas'),
  ];

  static const _locations = [
    (-34.6037, -58.3816, 'Microcentro, CABA'),
    (-34.5875, -58.3974, 'Palermo, CABA'),
    (-34.6158, -58.4333, 'Villa Crespo, CABA'),
    (-31.4201, -64.1888, 'Córdoba capital'),
    (-32.8908, -68.8272, 'Mendoza ciudad'),
    (-32.9442, -60.6505, 'Rosario'),
    (-38.0055, -57.5426, 'Mar del Plata'),
    (-34.9215, -57.9545, 'La Plata'),
    (-26.8083, -65.2176, 'San Miguel de Tucumán'),
    (-24.7821, -65.4232, 'Salta capital'),
  ];

  static const _captions = [
    'Mañana perfecta para volar en Palermo 🌤️',
    'Consulta ANAC OK — vuelo recreativo a 50m AGL',
    'Ojo con el viento de la tarde, ráfagas fuertes',
    'Spot nuevo cerca del río, zona verde confirmada',
    'Compartiendo fly check antes del vuelo de mapping',
    'Permiso comercial vigente · vuelo de inspección',
    'No volar acá — zona roja cerca del aeródromo',
    'Golden hour en Mendoza, viento < 5 m/s',
    'Primer vuelo del año, todo en orden ✅',
    '¿Alguien conoce restricciones en esta zona?',
    'Fly check: allowedWithPermission — pedí autorización',
    'Domingo de práctica FPV en el campo',
    'Alerta de viento guardada para este punto',
    'Compartiendo ubicación aproximada (500m fuzz)',
    'Vuelo nocturno cancelado por RAAC 100',
  ];

  static const _commentBodies = [
    'Buen dato, gracias!',
    '¿A qué hora fuiste?',
    'Ahí también volé el mes pasado.',
    'Cuidado con las ráfagas al atardecer.',
    'Zona confirmada, volé ayer sin drama.',
    'Necesitás permiso especial ahí.',
    'Hermosa toma 👏',
    'Te escribo por DM',
  ];

  static const _messageBodies = [
    'Hola! Vi tu fly check en Palermo',
    '¿Volamos juntos el sábado?',
    'Gracias por el tip de la zona',
    'Te paso el contacto del ATC',
    'Confirmado, nos vemos a las 10',
    'El viento estaba heavy ayer',
    'Mandame la ubicación exacta por favor',
    'Listo, ya te seguí',
    '¿Tenés permiso comercial vigente?',
    'Perfecto, quedamos en contacto',
  ];

  Future<void> run({required bool reset}) async {
    if (reset) {
      await _clearDevData();
    } else if (await _demoUserExists()) {
      throw StateError(
        'Dev seed already applied ($demoEmail exists). '
        'Run with --reset to wipe and re-seed.',
      );
    }

    final passwordHash = _passwordHasher.hash(demoPassword);
    final userIds = <String, String>{}; // handle -> id

    for (final pilot in _pilots) {
      final id = _uuid.v4();
      userIds[pilot.handle] = id;
      final followMode = pilot.handle == 'marta_private' ? 'approval' : 'open';
      await _db.connection.execute(
        Sql.named('''
          INSERT INTO users (
            id, email, password_hash, handle, display_name, bio,
            email_verified_at, follow_mode, created_at
          ) VALUES (
            @id, @email, @passwordHash, @handle, @displayName, @bio,
            NOW(), @followMode, @createdAt
          )
        '''),
        parameters: {
          'id': id,
          'email': '${pilot.handle}@dev.local',
          'passwordHash': passwordHash,
          'handle': pilot.handle,
          'displayName': pilot.name,
          'bio': pilot.bio,
          'followMode': followMode,
          'createdAt': _daysAgo(_random.nextInt(180) + 30),
        },
      );
    }

    final pilotId = userIds[demoHandle]!;
    final others = userIds.entries.where((e) => e.key != demoHandle).toList();

    // Pilot follows everyone → full feed for demo account.
    for (final entry in others) {
      await _insertFollow(followerId: pilotId, followingId: entry.value);
    }

    // Random follow graph among other pilots.
    for (final entry in others) {
      final targets = [...others]..remove(entry);
      targets.shuffle(_random);
      for (final target in targets.take(_random.nextInt(6) + 3)) {
        await _insertFollow(
          followerId: entry.value,
          followingId: target.value,
        );
      }
    }

    // Posts — 3–6 per user, staggered over 45 days.
    final postIds = <String>[];
    for (final entry in userIds.entries) {
      final count = _random.nextInt(4) + 3;
      for (var i = 0; i < count; i++) {
        final postId = await _insertPost(
          authorId: entry.value,
          daysAgo: _random.nextInt(45),
        );
        postIds.add(postId);
      }
    }

    // Comments on ~40% of posts.
    for (final postId in postIds) {
      if (_random.nextDouble() > 0.4) continue;
      final commentCount = _random.nextInt(3) + 1;
      final authors = userIds.values.toList()..shuffle(_random);
      for (var i = 0; i < commentCount; i++) {
        await _insertComment(
          postId: postId,
          authorId: authors[i % authors.length],
        );
      }
    }

    // DM threads: pilot ↔ 10 other pilots.
    final dmPartners = [...others]..shuffle(_random);
    for (final partner in dmPartners.take(10)) {
      await _insertDirectThread(
        userA: pilotId,
        userB: partner.value,
        messageCount: _random.nextInt(10) + 5,
      );
    }

    // Extra threads between random pairs (not involving pilot).
    for (var i = 0; i < 8; i++) {
      final a = others[_random.nextInt(others.length)];
      var b = others[_random.nextInt(others.length)];
      if (a.key == b.key) continue;
      await _insertDirectThread(
        userA: a.value,
        userB: b.value,
        messageCount: _random.nextInt(8) + 3,
      );
    }

    // Weather alerts for demo pilot.
    for (final (lat, lon, label) in _locations.take(4)) {
      await _db.connection.execute(
        Sql.named('''
          INSERT INTO weather_alert_subscriptions (
            id, user_id, label, lat, lon, wind_threshold_ms
          ) VALUES (@id, @userId, @label, @lat, @lon, @threshold)
        '''),
        parameters: {
          'id': _uuid.v4(),
          'userId': pilotId,
          'label': label,
          'lat': lat,
          'lon': lon,
          'threshold': 6.0 + _random.nextInt(4),
        },
      );
    }

    // Pending follow request to private profile.
    final martaId = userIds['marta_private'];
    if (martaId != null) {
      await _db.connection.execute(
        Sql.named('''
          INSERT INTO follow_requests (id, requester_id, target_id, status)
          VALUES (@id, @requester, @target, 'pending')
          ON CONFLICT (requester_id, target_id) DO NOTHING
        '''),
        parameters: {
          'id': _uuid.v4(),
          'requester': pilotId,
          'target': martaId,
        },
      );
    }
  }

  Future<bool> _demoUserExists() async {
    final result = await _db.connection.execute(
      Sql.named('SELECT 1 FROM users WHERE email = @email LIMIT 1'),
      parameters: {'email': demoEmail},
    );
    return result.isNotEmpty;
  }

  Future<void> _clearDevData() async {
    await _db.connection.execute(
      Sql.named('DELETE FROM users WHERE email LIKE @pattern'),
      parameters: {'pattern': '%@dev.local'},
    );
  }

  Future<void> _insertFollow({
    required String followerId,
    required String followingId,
  }) async {
    if (followerId == followingId) return;
    await _db.connection.execute(
      Sql.named('''
        INSERT INTO follows (follower_id, following_id)
        VALUES (@follower, @following)
        ON CONFLICT DO NOTHING
      '''),
      parameters: {'follower': followerId, 'following': followingId},
    );
  }

  Future<String> _insertPost({
    required String authorId,
    required int daysAgo,
  }) async {
    final id = _uuid.v4();
    final loc = _locations[_random.nextInt(_locations.length)];
    final verdicts = ['allowed', 'allowedWithPermission', 'notAllowed'];
    final verdict = verdicts[_random.nextInt(verdicts.length)];
    final snapshot = jsonEncode({
      'verdict': verdict,
      'summary': 'Seeded fly check',
      'permissions': ['recreativo'],
    });

    await _db.connection.execute(
      Sql.named('''
        INSERT INTO posts (
          id, author_id, caption, location_lat, location_lon,
          location_fuzz_meters, verdict_snapshot, zone_version, created_at
        ) VALUES (
          @id, @authorId, @caption, @lat, @lon, 500, @verdict, 'bundled-v1', @createdAt
        )
      '''),
      parameters: {
        'id': id,
        'authorId': authorId,
        'caption': _captions[_random.nextInt(_captions.length)],
        'lat': loc.$1 + (_random.nextDouble() - 0.5) * 0.01,
        'lon': loc.$2 + (_random.nextDouble() - 0.5) * 0.01,
        'verdict': snapshot,
        'createdAt': _daysAgo(daysAgo),
      },
    );
    await _insertPostMedia(postId: id);
    return id;
  }

  // Public sample clips that return HTTP 200 (Google gtv-videos bucket is 403).
  static const _sampleVideos = [
    'https://www.w3schools.com/html/mov_bbb.mp4',
    'https://interactive-examples.mdn.mozilla.net/media/cc0-videos/flower.mp4',
    'https://test-videos.co.uk/vids/bigbuckbunny/mp4/h264/360/Big_Buck_Bunny_360_10s_1MB.mp4',
    'https://test-videos.co.uk/vids/bigbuckbunny/mp4/h264/720/Big_Buck_Bunny_720_10s_1MB.mp4',
  ];

  Future<void> _insertPostMedia({required String postId}) async {
    final isVideo = _random.nextInt(100) < 35;
    if (isVideo) {
      final url = _sampleVideos[_random.nextInt(_sampleVideos.length)];
      await _db.connection.execute(
        Sql.named('''
          INSERT INTO post_media (id, post_id, media_type, storage_key, mime_type, size_bytes)
          VALUES (@id, @postId, 'video', @url, 'video/mp4', 0)
        '''),
        parameters: {'id': _uuid.v4(), 'postId': postId, 'url': url},
      );
      return;
    }
    final url = 'https://picsum.photos/seed/$postId/1080/1920';
    await _db.connection.execute(
      Sql.named('''
        INSERT INTO post_media (id, post_id, media_type, storage_key, mime_type, size_bytes)
        VALUES (@id, @postId, 'photo', @url, 'image/jpeg', 0)
      '''),
      parameters: {'id': _uuid.v4(), 'postId': postId, 'url': url},
    );
  }

  Future<void> _insertComment({
    required String postId,
    required String authorId,
  }) async {
    await _db.connection.execute(
      Sql.named('''
        INSERT INTO comments (id, post_id, author_id, body, created_at)
        VALUES (@id, @postId, @authorId, @body, @createdAt)
      '''),
      parameters: {
        'id': _uuid.v4(),
        'postId': postId,
        'authorId': authorId,
        'body': _commentBodies[_random.nextInt(_commentBodies.length)],
        'createdAt': _daysAgo(_random.nextInt(20)),
      },
    );
  }

  Future<void> _insertDirectThread({
    required String userA,
    required String userB,
    required int messageCount,
  }) async {
    final threadId = _uuid.v4();
    await _db.connection.execute(
      Sql.named('''
        INSERT INTO threads (id, is_group, created_by, created_at)
        VALUES (@id, FALSE, @creator, @createdAt)
      '''),
      parameters: {
        'id': threadId,
        'creator': userA,
        'createdAt': _daysAgo(_random.nextInt(30) + 5),
      },
    );
    for (final member in [userA, userB]) {
      await _db.connection.execute(
        Sql.named('''
          INSERT INTO thread_members (thread_id, user_id, role)
          VALUES (@threadId, @userId, 'member')
        '''),
        parameters: {'threadId': threadId, 'userId': member},
      );
    }
    for (var i = 0; i < messageCount; i++) {
      final senderId = i.isEven ? userA : userB;
      await _db.connection.execute(
        Sql.named('''
          INSERT INTO messages (id, thread_id, sender_id, body, created_at)
          VALUES (@id, @threadId, @senderId, @body, @createdAt)
        '''),
        parameters: {
          'id': _uuid.v4(),
          'threadId': threadId,
          'senderId': senderId,
          'body': _messageBodies[_random.nextInt(_messageBodies.length)],
          'createdAt': _daysAgo(_random.nextInt(14) + 1),
        },
      );
    }
  }

  DateTime _daysAgo(int days) {
    return DateTime.now().toUtc().subtract(
      Duration(
        days: days,
        hours: _random.nextInt(24),
        minutes: _random.nextInt(60),
      ),
    );
  }

  static Future<void> fromEnvironment({required bool reset}) async {
    final config = AppConfig.fromEnvironment();
    final database = await Database.connect(config);
    try {
      await database.runMigrations();
      final seed = DevSeed(database: database);
      await seed.run(reset: reset);
    } finally {
      await database.close();
    }
  }
}
