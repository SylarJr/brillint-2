// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_application_1/main.dart';

void main() {
  testWidgets('muestra el tablero 7x7 y selecciona una casilla', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());

    expect(find.byType(InkWell), findsNWidgets(49));
    expect(find.byKey(const ValueKey('celda-0-0')), findsOneWidget);
    expect(find.byKey(const ValueKey('celda-6-6')), findsOneWidget);
    expect(find.text('FILA 1  /  COLUMNA 1'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('celda-1-2')));
    await tester.pumpAndSettle();

    expect(find.text('FILA 2  /  COLUMNA 3'), findsOneWidget);
  });
}
