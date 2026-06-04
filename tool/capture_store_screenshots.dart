// Captures raw simulator/emulator screenshots and composes store marketing
// images.
//
// Usage (from project root):
//   dart run tool/capture_store_screenshots.dart [options]
//
// Run with --help for full option reference.

import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:mason_logger/mason_logger.dart';

// ── entry point ──────────────────────────────────────────────────────────────

Future<void> main(List<String> argv) async {
  final parser = ArgParser()
    ..addOption(
      'device',
      abbr: 'd',
      help: 'iOS simulator name.',
      defaultsTo: 'iPhone 16 Pro Max',
    )
    ..addOption(
      'locales',
      abbr: 'l',
      help: 'Comma-separated locales to capture.',
      defaultsTo: 'en,es',
    )
    ..addOption(
      'retries',
      abbr: 'r',
      help: 'Max flutter drive retry attempts per locale.',
      defaultsTo: '2',
    )
    ..addFlag(
      'phone',
      help: 'Capture iOS phone screenshots.',
      negatable: false,
    )
    ..addFlag(
      'tablets',
      help: 'Capture both Android tablet sizes (7-inch and 10-inch).',
      negatable: false,
    )
    ..addFlag(
      'tablet-7',
      help: 'Capture 7-inch tablet only (requires Tablet_7_API_35 AVD).',
      negatable: false,
    )
    ..addFlag(
      'tablet-10',
      help: 'Capture 10-inch tablet only (requires Pixel_Tablet_API_36 AVD).',
      negatable: false,
    )
    ..addFlag('help', abbr: 'h', negatable: false, hide: true);

  final ArgResults args;
  try {
    args = parser.parse(argv);
  } on FormatException catch (e) {
    Logger()
      ..err(e.message)
      ..info(parser.usage);
    exit(64); // EX_USAGE
  }

  if (args['help'] as bool) {
    _printUsage(parser);
    return;
  }

  final tablets = args['tablets'] as bool;
  final tablet7 = tablets || args['tablet-7'] as bool;
  final tablet10 = tablets || args['tablet-10'] as bool;
  final explicitPhone = args['phone'] as bool;
  // Default to phone when no device flag is given, so bare invocation still
  // works as before.
  final phone = explicitPhone || (!tablet7 && !tablet10);

  final tool = _CaptureTool(
    device: args['device'] as String,
    locales:
        (args['locales'] as String).split(',').map((l) => l.trim()).toList(),
    retries: int.tryParse(args['retries'] as String) ?? 2,
    phone: phone,
    tablet7: tablet7,
    tablet10: tablet10,
    logger: Logger(),
  );

  await tool.run();
}

void _printUsage(ArgParser parser) {
  // ignore: avoid_print
  print('''
dart run tool/capture_store_screenshots.dart [options]

Captures raw simulator/emulator screenshots for every locale, then
composes them into store-ready marketing images under store/marketing/.

${parser.usage}

Examples:
  # Default: EN + ES on iPhone 16 Pro Max (phone only)
  dart run tool/capture_store_screenshots.dart

  # Phone + both Android tablet sizes
  dart run tool/capture_store_screenshots.dart --phone --tablets

  # Tablets only (skip iOS)
  dart run tool/capture_store_screenshots.dart --tablets

  # Re-run only the missing 10-inch tablet
  dart run tool/capture_store_screenshots.dart --tablet-10

  # Phone, specific simulator and locale
  dart run tool/capture_store_screenshots.dart --phone -l es -d "iPhone 15 Pro"
''');
}

// ── Android tablet config ────────────────────────────────────────────────────

class _TabletConfig {
  const _TabletConfig({
    required this.bucket,
    required this.avdName,
    required this.size,
    required this.density,
  });

  final String bucket;
  final String avdName;
  final String size; // e.g. "1600x2560"
  final String density; // e.g. "320"
}

const _tablet7 = _TabletConfig(
  bucket: 'android_tablet_7',
  avdName: 'Tablet_7_API_35',
  size: '1200x1920',
  density: '213',
);

const _tablet10 = _TabletConfig(
  bucket: 'android_tablet_10',
  avdName: 'Pixel_Tablet_API_36',
  size: '1600x2560',
  density: '320',
);

// ── tool ─────────────────────────────────────────────────────────────────────

class _CaptureTool {
  _CaptureTool({
    required this.device,
    required this.locales,
    required this.retries,
    required this.phone,
    required this.tablet7,
    required this.tablet10,
    required this.logger,
  });

  final String device;
  final List<String> locales;
  final int retries;
  final bool phone;
  final bool tablet7;
  final bool tablet10;
  final Logger logger;

  late final Directory _root = File(Platform.script.toFilePath()).parent.parent;
  late final Directory _rawBase = Directory('${_root.path}/docs/screenshots');
  late final Directory _storeDir = Directory('${_root.path}/store');
  late final Directory _toolingDir =
      Directory('${_root.path}/tooling/store_assets');

  late final String _androidHome = Platform.environment['ANDROID_HOME'] ??
      '${Platform.environment['HOME']}/Library/Android/sdk';

  // ── run ────────────────────────────────────────────────────────────────────

  Future<void> run() async {
    await _preflight();

    // iOS phone
    if (phone) {
      await _bootSimulator(device);
      for (final locale in locales) {
        await _capturePhone(locale);
      }
    }

    // Android tablets — each AVD is started, used, then shut down
    if (tablet7) await _captureTablet(_tablet7);
    if (tablet10) await _captureTablet(_tablet10);

    await _ensureDeviceFrames();
    final python = await _resolvePython();
    await _compose(python);
    _printSummary();
  }

  void _printSummary() {
    logger
      ..info('')
      ..success('Done! Upload these to the stores:')
      ..info('');
    for (final locale in locales) {
      if (phone) {
        logger
          ..info('  App Store  $locale  →  store/marketing/$locale/ios_6.7/')
          ..info(
            '  Play Store $locale  →'
            ' store/marketing/$locale/android_phone/',
          );
      }
      if (tablet7) {
        logger.info(
          '  Play Store $locale (7″)  →'
          ' store/marketing/$locale/android_tablet_7/',
        );
      }
      if (tablet10) {
        logger.info(
          '  Play Store $locale (10″) →'
          ' store/marketing/$locale/android_tablet_10/',
        );
      }
    }
    logger
      ..info('  Feature graphic  →  store/play/feature_graphic_*.png')
      ..info('');
  }

  // ── pre-flight ─────────────────────────────────────────────────────────────

  Future<void> _preflight() async {
    final progress = logger.progress('Checking prerequisites');

    final required = {
      'flutter': 'https://docs.flutter.dev/get-started/install',
      'python3': 'https://www.python.org/downloads/',
    };
    final optional = {
      if (phone) 'xcrun': 'Install Xcode from the Mac App Store',
      if (tablet7 || tablet10) 'adb': 'Install Android SDK platform-tools',
    };

    final missing = <String>[];
    for (final entry in {...required, ...optional}.entries) {
      final result = await Process.run('which', [entry.key]);
      if (result.exitCode != 0) missing.add('${entry.key} — ${entry.value}');
    }

    if (missing.isNotEmpty) {
      progress.fail('Missing prerequisites');
      for (final m in missing) {
        logger.err('  ✗ $m');
      }
      exit(1);
    }

    progress.complete('Prerequisites OK');
  }

  // ── iOS simulator ──────────────────────────────────────────────────────────

  Future<List<_Sim>> _listSims() async {
    final result = await Process.run(
      'xcrun',
      ['simctl', 'list', 'devices', '--json'],
    );
    if (result.exitCode != 0) {
      logger.err('xcrun simctl failed: ${result.stderr}');
      exit(1);
    }
    final data = jsonDecode(result.stdout as String) as Map<String, dynamic>;
    final sims = <_Sim>[];
    for (final devList in (data['devices'] as Map<String, dynamic>).values) {
      for (final d in devList as List<dynamic>) {
        final m = d as Map<String, dynamic>;
        sims.add(
          _Sim(
            udid: m['udid'] as String,
            name: m['name'] as String,
            state: m['state'] as String,
            isAvailable: m['isAvailable'] as bool? ?? false,
          ),
        );
      }
    }
    return sims;
  }

  Future<void> _bootSimulator(String name) async {
    final sims = await _listSims();
    final matches = sims.where((s) => s.name == name && s.isAvailable).toList();

    if (matches.isEmpty) {
      logger
        ..err("Simulator '$name' not found.")
        ..info('')
        ..info('Available simulators:');
      final names = sims
          .where((s) => s.isAvailable)
          .map((s) => s.name)
          .toSet()
          .toList()
        ..sort();
      for (final n in names) {
        logger.info('  $n');
      }
      logger
        ..info('')
        ..info('Set --device to one of the above.');
      exit(1);
    }

    final sim = matches.first;
    if (sim.isBooted) {
      logger.success("Simulator '$name' already booted");
      return;
    }

    final progress = logger.progress("Booting '$name'");
    await Process.run('xcrun', ['simctl', 'boot', sim.udid]);

    for (var n = 0; n < 90; n++) {
      final current = (await _listSims()).firstWhere((s) => s.udid == sim.udid);
      if (current.isBooted) {
        await Future<void>.delayed(const Duration(seconds: 3));
        progress.complete("'$name' is ready");
        return;
      }
      await Future<void>.delayed(const Duration(seconds: 1));
    }

    progress.fail("'$name' did not boot within 90 s");
    exit(1);
  }

  // ── iOS phone capture ──────────────────────────────────────────────────────

  Future<void> _capturePhone(String locale) async {
    final rawDir = Directory('${_rawBase.path}/$locale');
    logger.detail('Cleaning stale phone screenshots for "$locale"');
    _deleteScreenshots(rawDir);
    rawDir.createSync(recursive: true);
    await _flutterDrive(
      locale: locale,
      rawDir: rawDir,
      targetDevice: device,
    );
  }

  // ── Android AVD management ─────────────────────────────────────────────────

  Future<String?> _serialForAvd(String avdName) async {
    final result = await Process.run('adb', ['devices']);
    final lines = (result.stdout as String).split('\n');
    for (final line in lines) {
      final parts = line.trim().split(RegExp(r'\s+'));
      if (parts.length < 2) continue;
      final serial = parts[0];
      final state = parts[1];
      if (!serial.startsWith('emulator-') || state != 'device') continue;
      final nameResult = await Process.run(
        'adb',
        ['-s', serial, 'emu', 'avd', 'name'],
      );
      final name = (nameResult.stdout as String).split('\n').first.trim();
      if (name == avdName) return serial;
    }
    return null;
  }

  Future<String> _startAvd(_TabletConfig config) async {
    final existing = await _serialForAvd(config.avdName);
    if (existing != null) {
      logger.success("Using running AVD '${config.avdName}' ($existing)");
      return existing;
    }

    final progress = logger.progress("Starting AVD '${config.avdName}'");
    await Process.start(
      '$_androidHome/emulator/emulator',
      ['-avd', config.avdName, '-no-snapshot-load'],
      mode: ProcessStartMode.detached,
    );

    String? serial;
    for (var n = 0; n < 180; n++) {
      serial = await _serialForAvd(config.avdName);
      if (serial != null) break;
      await Future<void>.delayed(const Duration(seconds: 1));
    }
    if (serial == null) {
      progress.fail(
        "'${config.avdName}' did not appear in adb devices within 180 s",
      );
      exit(1);
    }

    progress.update("Waiting for '${config.avdName}' to finish booting");
    for (var n = 0; n < 90; n++) {
      final r = await Process.run(
        'adb',
        ['-s', serial, 'shell', 'getprop', 'sys.boot_completed'],
      );
      if ((r.stdout as String).trim() == '1') {
        await Future<void>.delayed(const Duration(seconds: 2));
        progress.complete("'${config.avdName}' ready ($serial)");
        return serial;
      }
      await Future<void>.delayed(const Duration(seconds: 2));
    }

    progress.fail("'${config.avdName}' did not finish booting within 90 s");
    exit(1);
  }

  Future<void> _setTabletDisplay(String serial, _TabletConfig config) async {
    await Process.run(
      'adb',
      ['-s', serial, 'shell', 'wm', 'size', config.size],
    );
    await Process.run(
      'adb',
      ['-s', serial, 'shell', 'wm', 'density', config.density],
    );
    await Future<void>.delayed(const Duration(seconds: 2));
  }

  Future<void> _resetTabletDisplay(String serial) async {
    await Process.run('adb', ['-s', serial, 'shell', 'wm', 'size', 'reset']);
    await Process.run(
      'adb',
      ['-s', serial, 'shell', 'wm', 'density', 'reset'],
    );
  }

  // ── Android tablet capture ─────────────────────────────────────────────────

  Future<void> _captureTablet(_TabletConfig config) async {
    final serial = await _startAvd(config);
    await _setTabletDisplay(serial, config);

    for (final locale in locales) {
      final rawDir = Directory('${_rawBase.path}/$locale/${config.bucket}');
      logger.detail(
        'Cleaning stale ${config.bucket} screenshots for "$locale"',
      );
      _deleteScreenshots(rawDir);
      rawDir.createSync(recursive: true);

      // Force-stop any previous app instance before each locale.
      await Process.run(
        'adb',
        ['-s', serial, 'shell', 'am', 'force-stop', 'dev.aquiles.wheretofly'],
      );

      await _flutterDrive(
        locale: locale,
        rawDir: rawDir,
        targetDevice: serial,
        label: '${config.bucket}/$locale',
      );
    }

    await _resetTabletDisplay(serial);
    await Process.run('adb', ['-s', serial, 'emu', 'kill']);
    logger.detail("AVD '${config.avdName}' shut down");
  }

  // ── shared flutter drive ───────────────────────────────────────────────────

  Future<void> _flutterDrive({
    required String locale,
    required Directory rawDir,
    required String targetDevice,
    String? label,
  }) async {
    final displayLabel = label ?? locale;
    final env = {
      'STORE_SCREENSHOT_DIR': rawDir.path,
      'STORE_SCREENSHOT_ROOT': _root.path,
    };

    for (var attempt = 1; attempt <= retries + 1; attempt++) {
      final suffix = attempt == 1 ? '' : ' (attempt $attempt/${retries + 1})';
      logger.info('Capturing "$displayLabel"$suffix');

      final exitCode = await _stream(
        'flutter',
        [
          'drive',
          '--driver=test_driver/integration_test.dart',
          '--target=integration_test/store_screenshot_test.dart',
          '-d',
          targetDevice,
          '--dart-define=STORE_SCREENSHOT_LOCALE=$locale',
        ],
        env: env,
      );

      final count = _countPngs(rawDir);
      if (count >= 6) {
        logger.success('$count/6 screenshots captured for "$displayLabel"');
        return;
      }

      if (attempt > retries) {
        logger.err(
          '"$displayLabel": only $count/6 screenshots after '
          '$attempt attempt(s).',
        );
        exit(1);
      }

      logger.warn(
        '"$displayLabel": $count/6 screenshots'
        ' (exit $exitCode) — retrying in 5 s…',
      );
      _deleteScreenshots(rawDir);
      await Future<void>.delayed(const Duration(seconds: 5));
    }
  }

  // ── helpers ────────────────────────────────────────────────────────────────

  int _countPngs(Directory dir) {
    if (!dir.existsSync()) return 0;
    return dir.listSync().whereType<File>().where((f) {
      final name = f.uri.pathSegments.last;
      return RegExp(r'^\d').hasMatch(name) && name.endsWith('.png');
    }).length;
  }

  void _deleteScreenshots(Directory dir) {
    if (!dir.existsSync()) return;
    for (final f in dir.listSync().whereType<File>()) {
      final name = f.uri.pathSegments.last;
      if (RegExp(r'^\d').hasMatch(name) && name.endsWith('.png')) {
        f.deleteSync();
      }
    }
  }

  // ── Python / Pillow ────────────────────────────────────────────────────────

  Future<String> _resolvePython() async {
    final venvPython = '${_toolingDir.path}/.venv/bin/python';

    final sysTest = await Process.run('python3', ['-c', 'import PIL']);
    if (sysTest.exitCode == 0) return 'python3';

    if (File(venvPython).existsSync()) {
      final venvTest = await Process.run(venvPython, ['-c', 'import PIL']);
      if (venvTest.exitCode == 0) return venvPython;
    }

    final progress = logger.progress('Setting up Python venv for Pillow');
    await _stream('python3', ['-m', 'venv', '${_toolingDir.path}/.venv']);
    await _stream('${_toolingDir.path}/.venv/bin/pip', [
      'install',
      '-q',
      '-r',
      '${_toolingDir.path}/requirements.txt',
    ]);
    progress.complete('Pillow ready');
    return venvPython;
  }

  // ── composition ────────────────────────────────────────────────────────────

  Future<void> _ensureDeviceFrames() async {
    final marker = File(
      '${_toolingDir.path}/device-frames'
      '/iphone-16-pro-max-black-titanium/frame.png',
    );
    if (marker.existsSync()) return;

    final progress = logger.progress('Downloading device frame PNGs');
    await _stream('bash', ['${_toolingDir.path}/download_device_frames.sh']);
    progress.complete('Device frames ready');
  }

  Future<void> _compose(String python) async {
    final progress = logger.progress('Composing store assets (2× render)');
    await _stream(python, [
      '${_toolingDir.path}/generate_store_images.py',
      '--store-dir',
      _storeDir.path,
      '--locale',
      'all',
    ]);
    progress.complete('Store assets composed');
  }

  // ── subprocess ─────────────────────────────────────────────────────────────

  Future<int> _stream(
    String exe,
    List<String> args, {
    Map<String, String>? env,
  }) async {
    final process = await Process.start(
      exe,
      args,
      workingDirectory: _root.path,
      environment: {
        ...Platform.environment,
        if (env != null) ...env,
      },
    );
    process.stdout
        .transform(const SystemEncoding().decoder)
        .listen(stdout.write);
    process.stderr
        .transform(const SystemEncoding().decoder)
        .listen(stderr.write);
    return process.exitCode;
  }
}

// ── data ─────────────────────────────────────────────────────────────────────

class _Sim {
  _Sim({
    required this.udid,
    required this.name,
    required this.state,
    required this.isAvailable,
  });

  final String udid;
  final String name;
  final String state;
  final bool isAvailable;

  bool get isBooted => state == 'Booted';
}
