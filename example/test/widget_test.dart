import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_twain_scanner_example/main.dart';

void main() {
  testWidgets('renders the scanner page', (WidgetTester tester) async {
    await tester.pumpWidget(const ScannerApp());

    expect(find.text('TWAIN Scanner'), findsOneWidget);
    expect(find.text('Scan Document'), findsOneWidget);
    expect(find.text('Save PDF'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
    expect(find.byIcon(Icons.refresh), findsOneWidget);
  });
}
