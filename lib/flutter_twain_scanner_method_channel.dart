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
    final version =
        await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }

  @override
  Future<List<String>?> getDataSources() async {
    List? results =
        await methodChannel.invokeMethod<List<dynamic>>('getDataSources');
    List<String> dsNames = [];
    if (results != null) {
      for (var item in results) {
        dsNames.add(item.toString());
      }
    }
    return dsNames;
  }

  @override
  Future<String?> scanDocument(int sourceIndex) async {
    return await methodChannel
        .invokeMethod<String>('scanDocument', {'index': sourceIndex});
  }
}
