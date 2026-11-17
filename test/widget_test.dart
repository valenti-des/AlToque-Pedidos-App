import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app/main.dart';

void main() {
  testWidgets('customer must sign in or register before seeing the catalog', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('Identifícate para realizar tu pedido'), findsOneWidget);
    expect(find.text('Invitado'), findsNothing);
    expect(find.text('Ver menú'), findsNothing);
    expect(find.text('¿Qué se te antoja?'), findsNothing);

    await tester.tap(find.text('Registrarme'));
    await tester.pumpAndSettle();

    expect(find.byType(TextFormField), findsNWidgets(3));
    expect(find.text('Curso'), findsNothing);
    expect(find.text('Crear cuenta'), findsOneWidget);
  });

  testWidgets('customer registration rejects a short password', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());

    await tester.tap(find.text('Registrarme'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(0), 'Ana Perez');
    await tester.enterText(find.byType(TextFormField).at(1), 'ana@example.com');
    await tester.enterText(find.byType(TextFormField).at(2), 'corta');
    await tester.ensureVisible(find.text('Crear cuenta'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Crear cuenta'));
    await tester.pumpAndSettle();

    expect(find.text('Usa al menos 8 caracteres'), findsOneWidget);
    expect(find.text('Identifícate para realizar tu pedido'), findsOneWidget);
  });
}
