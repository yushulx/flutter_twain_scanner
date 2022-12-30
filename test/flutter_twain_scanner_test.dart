import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_twain_scanner/flutter_twain_scanner.dart';
import 'package:flutter_twain_scanner/flutter_twain_scanner_platform_interface.dart';
import 'package:flutter_twain_scanner/flutter_twain_scanner_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockFlutterTwainScannerPlatform
    with MockPlatformInterfaceMixin
    implements FlutterTwainScannerPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final FlutterTwainScannerPlatform initialPlatform = FlutterTwainScannerPlatform.instance;

  test('$MethodChannelFlutterTwainScanner is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelFlutterTwainScanner>());
  });

  test('getPlatformVersion', () async {
    FlutterTwainScanner flutterTwainScannerPlugin = FlutterTwainScanner();
    MockFlutterTwainScannerPlatform fakePlatform = MockFlutterTwainScannerPlatform();
    FlutterTwainScannerPlatform.instance = fakePlatform;

    expect(await flutterTwainScannerPlugin.getPlatformVersion(), '42');
  });
}
