import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:agri_frontend/main.dart';

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    // Construire l'application et fournir un userId factice
    await tester.pumpWidget(MyApp(userId: '0')); // ✅ Fournir un userId

    // Vérifier que le compteur commence à 0
    expect(find.text('0'), findsOneWidget);
    expect(find.text('1'), findsNothing);

    // Tap sur le bouton '+' et déclencher une frame
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();

    // Vérifier que le compteur a été incrémenté
    expect(find.text('0'), findsNothing);
    expect(find.text('1'), findsOneWidget);
  });
}
