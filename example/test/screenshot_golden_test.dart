// Regenerates the README screenshots by rendering the example app with real
// fonts and a real scan performed against the local Dynamic Web TWAIN Service.
//
// The trial license is read from lib/main.dart. Run with:
//   flutter test test/screenshot_golden_test.dart --update-goldens
//
// The test is skipped in normal test runs because it only produces the
// documentation screenshots and needs a working license and scanner.
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_twain_scanner/flutter_twain_scanner.dart';
import 'package:flutter_twain_scanner_example/main.dart';

const _host = 'http://127.0.0.1:18625';

String _readTrialLicense() {
  final mainDart = File('lib/main.dart').readAsStringSync();
  return RegExp(r"_trialLicense =\s*'([^']+)'").firstMatch(mainDart)!.group(1)!;
}

/// Captures one real scan so that the screenshots show actual scanned pages.
class _RealScan {
  _RealScan({
    required this.serverInfo,
    required this.scanners,
    required this.documentId,
    required this.jobId,
    required this.pageSources,
    required this.pageImages,
  });

  final Map<String, dynamic> serverInfo;
  final List<Map<String, dynamic>> scanners;
  final String documentId;
  final String jobId;
  final List<String> pageSources;
  final List<Uint8List> pageImages;

  /// Replays the captured scan into the app UI deterministically.
  DynamsoftService asFixture() => _ReplayService(this);

  /// Deletes the storage copy of the captured scan.
  Future<void> cleanup() async {
    final service = DynamsoftService();
    await service.deleteDocument(_host, documentId);
    service.close();
  }
}

class _ReplayService extends DynamsoftService {
  _ReplayService(this._scan);

  final _RealScan _scan;
  int _infoIndex = 0;
  int _imageIndex = 0;

  @override
  Future<Map<String, dynamic>> getServerInfo(String host) async =>
      _scan.serverInfo;

  @override
  Future<List<Map<String, dynamic>>> getDevices(
    String host, [
    int? scannerType,
  ]) async =>
      _scan.scanners;

  @override
  Future<Map<String, dynamic>> createJob(
    String host,
    Map<String, dynamic> parameters,
  ) async =>
      {'jobuid': _scan.jobId, 'status': JobStatus.running};

  @override
  Future<Map<String, dynamic>> createDocument(
    String host,
    Map<String, dynamic> parameters,
  ) async =>
      {'uid': _scan.documentId, 'pages': []};

  @override
  Future<List<Map<String, dynamic>>> getImageInfo(
    String host,
    String jobId,
  ) async {
    if (_infoIndex >= _scan.pageSources.length) return [];
    return [
      {'url': _scan.pageSources[_infoIndex++]},
    ];
  }

  @override
  Future<Map<String, dynamic>> insertPage(
    String host,
    String docId,
    Map<String, dynamic> parameters,
  ) async =>
      {'uid': docId, 'pages': []};

  @override
  Future<Uint8List?> getNextPage(String host, String jobId) async {
    if (_imageIndex >= _scan.pageImages.length) return null;
    return _scan.pageImages[_imageIndex++];
  }

  @override
  Future<bool> deleteJob(String host, String jobId) async => true;
}

Future<_RealScan> _performRealScan() async {
  final service = DynamsoftService();
  try {
    final serverInfo = await service.getServerInfo(_host);
    final scanners = await service.getDevices(_host, ScannerType.ica);
    if (scanners.isEmpty) {
      throw StateError('No ICA scanner registered with the local service.');
    }

    final document = await service.createDocument(_host, {});
    final documentId = document['uid'] as String;
    final job = await service.createJob(_host, {
      'license': _readTrialLicense(),
      'device': scanners.first['device'],
      'config': {
        'IfShowUI': false,
        'PixelType': 2,
        'Resolution': 200,
        'IfFeederEnabled': false,
        'IfDuplexEnabled': false,
      },
    });
    final jobId = job['jobuid'] as String;

    final pageSources = <String>[];
    final pageImages = <Uint8List>[];
    try {
      while (pageImages.length < 5) {
        final infos = await service.getImageInfo(_host, jobId);
        if (infos.isEmpty) break;
        final source = infos.first['url'] as String;
        await service.insertPage(_host, documentId, {
          'password': '',
          'source': source,
        });
        final image = await service.getNextPage(_host, jobId);
        if (image == null) break;
        pageSources.add(source);
        pageImages.add(image);
      }
    } finally {
      await service.deleteJob(_host, jobId);
    }

    if (pageImages.isEmpty) {
      throw StateError('The scan did not produce any page.');
    }
    return _RealScan(
      serverInfo: serverInfo,
      scanners: scanners,
      documentId: documentId,
      jobId: jobId,
      pageSources: pageSources,
      pageImages: pageImages,
    );
  } finally {
    service.close();
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

Future<void> _prepareRealEnvironment() async {
  // flutter_test installs fake HTTP overrides that block real network access.
  HttpOverrides.global = null;
  await _loadRealFonts();
}

void main() {
  testWidgets('capture the app screenshots', (WidgetTester tester) async {
    if (!autoUpdateGoldenFiles) {
      // Only regenerate the screenshots with --update-goldens.
      return;
    }

    await tester.runAsync(_prepareRealEnvironment);
    final scan = (await tester.runAsync(_performRealScan))!;

    tester.view.devicePixelRatio = 2.0;
    tester.view.physicalSize = const Size(2560, 1600);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(ScannerApp(service: scan.asFixture()));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('List scanners'));
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(ScannerApp),
      matchesGoldenFile('../../screenshots/macos_scanner_list.png'),
    );

    await tester.tap(find.text('Scan Document'));
    await tester.pumpAndSettle();

    // Image decoding completes on the real event loop, so give the engine
    // time to decode the scanned pages before capturing the frame.
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 800)),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(ScannerApp),
      matchesGoldenFile('../../screenshots/macos_scanned_pages.png'),
    );

    tester.view.devicePixelRatio = 3.0;
    tester.view.physicalSize = const Size(1080, 2400);
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(ScannerApp),
      matchesGoldenFile('../../screenshots/android_scanned_pages.png'),
    );

    await tester.runAsync(scan.cleanup);
  });
}
