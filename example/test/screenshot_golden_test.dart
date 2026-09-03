// Regenerates the README screenshots by rendering the example app with real
// fonts and the scanner names reported by the local Dynamic Web TWAIN Service.
//
// Run with:
//   flutter test test/screenshot_golden_test.dart --update-goldens
//
// The test is skipped in normal test runs because it only produces the
// documentation screenshots.
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_twain_scanner/flutter_twain_scanner.dart';
import 'package:flutter_twain_scanner_example/main.dart';

/// Returns the data reported by the local Dynamic Web TWAIN Service so that
/// the screenshots show a realistic, deterministic UI.
class _LocalServiceFixture extends DynamsoftService {
  @override
  Future<Map<String, dynamic>> getServerInfo(String host) async {
    return {
      'version': '20260331',
      'compatible': true,
      'moduleVersions': {
        'core': ['18.6.0.0410', '19.4.2.0728'],
      },
    };
  }

  @override
  Future<List<Map<String, dynamic>>> getDevices(
    String host, [
    int? scannerType,
  ]) async {
    return const [
      {
        'name': 'Virtual Scanner (3)',
        'type': ScannerType.ica,
        'device': '{"deviceType":128}',
      },
      {
        'name': 'Virtual Scanner EX/AF',
        'type': ScannerType.ica,
        'device': '{"deviceType":128}',
      },
    ];
  }
}

Future<void> _loadRealFonts() async {
  final flutterRoot = Platform.environment['FLUTTER_ROOT'];
  if (flutterRoot == null) return;
  final fontsDir = Directory('$flutterRoot/bin/cache/artifacts/material_fonts');
  if (!fontsDir.existsSync()) return;

  final loaders = <String, FontLoader>{};
  await for (final entity in fontsDir.list()) {
    if (entity is! File) continue;
    final name = entity.uri.pathSegments.last;
    final family =
        name.startsWith('MaterialIcons') ? 'MaterialIcons' : 'Roboto';
    final loader = loaders.putIfAbsent(family, () => FontLoader(family));
    final Uint8List bytes = entity.readAsBytesSync();
    loader.addFont(Future.value(bytes.buffer.asByteData()));
  }
  for (final loader in loaders.values) {
    await loader.load();
  }
}

void main() {
  testWidgets('capture the app screenshots', (WidgetTester tester) async {
    if (!autoUpdateGoldenFiles) {
      // Only regenerate the screenshots with --update-goldens.
      return;
    }

    tester.view.devicePixelRatio = 2.0;
    tester.view.physicalSize = const Size(2560, 1600);
    addTearDown(tester.view.reset);

    await tester.runAsync(_loadRealFonts);

    await tester.pumpWidget(
      ScannerApp(service: _LocalServiceFixture()),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('List scanners'));
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(ScannerApp),
      matchesGoldenFile('../../screenshots/macos_scanner_list.png'),
    );

    tester.view.devicePixelRatio = 3.0;
    tester.view.physicalSize = const Size(1080, 2400);
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(ScannerApp),
      matchesGoldenFile('../../screenshots/android_scanner_list.png'),
    );
  });
}
