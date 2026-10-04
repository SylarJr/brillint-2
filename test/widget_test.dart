// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_application_1/main.dart';
import 'package:flutter_application_1/tablero_bloc.dart';

void main() {
  testWidgets('asigna los seis números una vez y muestra Listo para jugar', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());

    expect(find.byKey(const ValueKey('celda-0-0')), findsOneWidget);
    expect(find.byKey(const ValueKey('celda-6-6')), findsOneWidget);
    expect(find.text('FILA 1  /  COLUMNA 3'), findsNothing);

    const objetivos = <(int, int)>[
      (0, 2),
      (1, 5),
      (3, 1),
      (3, 4),
      (5, 2),
      (6, 4),
    ];

    for (var index = 0; index < objetivos.length; index++) {
      final (fila, columna) = objetivos[index];
      final celda = find.byKey(ValueKey('celda-$fila-$columna'));
      await tester.ensureVisible(celda);
      await tester.tap(celda);
      await tester.pumpAndSettle();

      expect(
        find.text('FILA ${fila + 1}  /  COLUMNA ${columna + 1}'),
        findsOneWidget,
      );

      if (index == 1) {
        final botonUno = tester.widget<OutlinedButton>(
          find.byKey(const ValueKey('numero-1')),
        );
        expect(botonUno.onPressed, isNull);
      }

      final numero = index + 1;
      await tester.ensureVisible(find.byKey(ValueKey('numero-$numero')));
      await tester.tap(find.byKey(ValueKey('numero-$numero')));
      await tester.pumpAndSettle();

      if (index == 0) {
        final primeraCasilla = find.byKey(const ValueKey('celda-0-2'));
        await tester.ensureVisible(primeraCasilla);
        await tester.tap(primeraCasilla);
        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey('numero-2')), findsNothing);
        expect(
          find.descendant(of: primeraCasilla, matching: find.text('1')),
          findsOneWidget,
        );
      }
    }

    final botonListo = tester.widget<FilledButton>(
      find.byKey(const ValueKey('boton-listo')),
    );
    expect(botonListo.onPressed, isNotNull);

    await tester.ensureVisible(find.byKey(const ValueKey('boton-listo')));
    await tester.tap(find.byKey(const ValueKey('boton-listo')));
    await tester.pumpAndSettle();

    expect(find.text('Listo para jugar'), findsOneWidget);

    final bloc = tester
        .element(find.byKey(const ValueKey('boton-listo')))
        .read<BoardBloc>();
    final botonTirar = find.byKey(const ValueKey('boton-tirar-dados'));
    await tester.ensureVisible(botonTirar);
    await tester.tap(botonTirar);
    await tester.pumpAndSettle();

    expect(bloc.state.isDiceRolled, isTrue);
    expect(find.byKey(const ValueKey('dado-0')), findsOneWidget);
    expect(find.byKey(const ValueKey('dado-1')), findsOneWidget);
    expect(tester.widget<FilledButton>(botonTirar).onPressed, isNull);
    expect(
      tester
          .widget<OutlinedButton>(
            find.byKey(const ValueKey('boton-pasar-turno')),
          )
          .onPressed,
      isNotNull,
    );

    if (bloc.state.validPositions.isEmpty) {
      await tester.tap(find.byKey(const ValueKey('boton-pasar-turno')));
    } else {
      final position = bloc.state.validPositions.first;
      final cell = find.byKey(ValueKey('celda-${position.x}-${position.y}'));
      await tester.ensureVisible(cell);
      await tester.tap(cell);
    }
    await tester.pumpAndSettle();
    expect(bloc.state.isDiceRolled, isFalse);
  });
}
