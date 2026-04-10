import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Smoke test da estrutura base da UI', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          appBar: AppBar(title: const Text('AppFit')),
          body: const Center(child: Text('Bem-vindo')),
        ),
      ),
    );

    expect(find.text('AppFit'), findsOneWidget);
    expect(find.text('Bem-vindo'), findsOneWidget);
    expect(find.byType(Scaffold), findsOneWidget);
  });
}
