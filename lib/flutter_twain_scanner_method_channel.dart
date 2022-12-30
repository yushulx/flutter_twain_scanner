import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'flutter_twain_scanner_platform_interface.dart';

/// An implementation of [FlutterTwainScannerPlatform] that uses method channels.
class MethodChannelFlutterTwainScanner extends FlutterTwainScannerPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('flutter_twain_scanner');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
