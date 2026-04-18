import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders placeholder app shell', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Text('CD Manager'),
        ),
      ),
    );

    expect(find.text('CD Manager'), findsOneWidget);
  });
}
