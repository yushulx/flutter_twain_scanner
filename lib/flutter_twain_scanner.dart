/// A cross-platform Dart/Flutter package for digitizing documents from TWAIN,
/// WIA, SANE, ICA and eSCL compatible scanners.
///
/// The package is a pure Dart client for the [Dynamic Web TWAIN Service REST
/// API](https://www.dynamsoft.com/web-twain/restfulapi/). The Dynamsoft service
/// runs on the machine that is physically connected to the scanners, while your
/// Dart/Flutter app can talk to it over HTTP from Android, iOS, web, Windows,
/// macOS and Linux.
///
/// A minimal scanning workflow looks like this:
///
/// ```dart
/// final service = DynamsoftService();
///
/// // 1. List the scanners registered with the service.
/// final scanners = await service.getDevices(
///     'http://127.0.0.1:18625', ScannerType.twainX64);
///
/// // 2. Create a scan job for the first scanner.
/// final job = await service.createJob('http://127.0.0.1:18625', {
///   'license': 'YOUR-LICENSE-KEY',
///   'device': scanners.first['device'],
///   'config': {'IfShowUI': false, 'Resolution': 200},
/// });
///
/// // 3. Fetch the scanned pages as JPEG/PNG byte streams.
/// final images = await service.getImageStreams(
///     'http://127.0.0.1:18625', job['jobuid']);
/// ```
library;

export 'src/dynamsoft_service.dart';
