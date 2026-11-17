import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app/main.dart';

void main() {
  testWidgets('customer can enter the catalog and sign out', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());

    await tester.enterText(find.byType(TextFormField).at(0), 'Ana Perez');
    await tester.enterText(find.byType(TextFormField).at(1), '3ro A');
    await tester.tap(find.text('Ver menú'));
    await tester.pumpAndSettle();

    expect(find.text('¿Qué se te antoja?'), findsOneWidget);

    await tester.tap(find.byTooltip('Abrir menú'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cerrar sesión'));
    await tester.pumpAndSettle();

    expect(find.text('Identifícate para realizar tu pedido'), findsOneWidget);
  });

  testWidgets('customer registration rejects a short password', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());

    await tester.tap(find.text('Registrarme'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(0), 'Ana Perez');
    await tester.enterText(find.byType(TextFormField).at(1), '3ro A');
    await tester.enterText(find.byType(TextFormField).at(2), 'ana@example.com');
    await tester.enterText(find.byType(TextFormField).at(3), 'corta');
    await tester.ensureVisible(find.text('Crear cuenta'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Crear cuenta'));
    await tester.pumpAndSettle();

    expect(find.text('Usa al menos 8 caracteres'), findsOneWidget);
    expect(find.text('Identifícate para realizar tu pedido'), findsOneWidget);
  });
}
