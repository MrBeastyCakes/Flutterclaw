import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutterclaw/main.dart';

void main() {
  testWidgets('App renders without errors', (WidgetTester tester) async {
    await tester.pumpWidget(const FlutterclawApp());
    
    // Just verify the app builds without throwing
    expect(find.byType(MaterialApp), findsOneWidget);
    
    // Clean up any pending timers from WebSocket connections
    await tester.pumpAndSettle();
  });
}
