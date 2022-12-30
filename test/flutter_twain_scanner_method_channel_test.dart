import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_twain_scanner/flutter_twain_scanner_method_channel.dart';

void main() {
  MethodChannelFlutterTwainScanner platform = MethodChannelFlutterTwainScanner();
  const MethodChannel channel = MethodChannel('flutter_twain_scanner');

  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    channel.setMockMethodCallHandler((MethodCall methodCall) async {
      return '42';
    });
  });

  tearDown(() {
    channel.setMockMethodCallHandler(null);
  });

  test('getPlatformVersion', () async {
    expect(await platform.getPlatformVersion(), '42');
  });
}
