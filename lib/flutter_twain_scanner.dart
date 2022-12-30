import 'flutter_twain_scanner_platform_interface.dart';

class FlutterTwainScanner {
  Future<String?> getPlatformVersion() {
    return FlutterTwainScannerPlatform.instance.getPlatformVersion();
  }

  Future<List<String>?> getDataSources() {
    return FlutterTwainScannerPlatform.instance.getDataSources();
  }
}
