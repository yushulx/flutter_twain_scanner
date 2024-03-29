import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'flutter_twain_scanner_method_channel.dart';

abstract class FlutterTwainScannerPlatform extends PlatformInterface {
  /// Constructs a FlutterTwainScannerPlatform.
  FlutterTwainScannerPlatform() : super(token: _token);

  static final Object _token = Object();

  static FlutterTwainScannerPlatform _instance =
      MethodChannelFlutterTwainScanner();

  /// The default instance of [FlutterTwainScannerPlatform] to use.
  ///
  /// Defaults to [MethodChannelFlutterTwainScanner].
  static FlutterTwainScannerPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [FlutterTwainScannerPlatform] when
  /// they register themselves.
  static set instance(FlutterTwainScannerPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }

  /// Fetches the list of available scanners from a data source.
  ///
  /// Returns a `Future<List<String>>` containing the names of available scanners.
  Future<List<String>> getDataSources() {
    throw UnimplementedError('init() has not been implemented.');
  }

  /// Initiates a document scanning operation from a specified scanner.
  ///
  /// [sourceIndex] - The index of the scanner in the list of available data sources.
  ///
  /// Returns a `Future<List<String>>` containing the paths of saved images.
  Future<List<String>> scanDocument(int sourceIndex) {
    throw UnimplementedError('init() has not been implemented.');
  }
}
