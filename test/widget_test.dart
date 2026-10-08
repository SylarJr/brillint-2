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
  testWidgets('muestra el panel de puntuación a la derecha en escritorio', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MyApp());

    final tablero = tester.getRect(find.byType(AspectRatio).first);
    final dados = tester.getRect(find.byKey(const ValueKey('panel-dados')));
    final puntuacion = tester.getRect(
      find.byKey(const ValueKey('panel-puntuacion')),
    );
    expect(dados.left, greaterThan(tablero.right));
    expect(puntuacion.left, greaterThan(tablero.right));
  });

  testWidgets('asigna los seis números una vez y muestra Listo para jugar', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());

    expect(find.byKey(const ValueKey('panel-puntuacion')), findsOneWidget);
    expect(find.byKey(const ValueKey('panel-dados')), findsOneWidget);
    expect(find.byKey(const ValueKey('puntuacion-total')), findsOneWidget);
    expect(find.byKey(const ValueKey('marcador-pendiente')), findsNWidgets(6));
    expect(find.text('0'), findsOneWidget);
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
        expect(botonUno.onPressed, isNotNull);
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
        await tester.tap(primeraCasilla);
        await tester.pumpAndSettle();
      }
    }

    final bloc = tester
        .element(find.byKey(const ValueKey('celda-0-0')))
        .read<BoardBloc>();
    expect(bloc.state.asignaciones.values.toSet(), {1, 2, 3, 4, 5, 6});
    expect(bloc.state.completo, isTrue);
    expect(bloc.state.listoParaJugar, isTrue);

    expect(find.text('Listo para jugar'), findsOneWidget);
    await tester.pumpAndSettle();

    expect(bloc.state.isDiceRolled, isTrue);
    expect(find.byKey(const ValueKey('dado-0')), findsOneWidget);
    expect(find.byKey(const ValueKey('dado-1')), findsOneWidget);
    expect(find.byType(AnimatedSwitcher), findsNWidgets(2));
    expect(find.byKey(const ValueKey('boton-tirar-dados')), findsNothing);
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
      final tile = tester.widget<AnimatedContainer>(
        find.ancestor(of: cell, matching: find.byType(AnimatedContainer)).first,
      );
      final decoration = tile.decoration! as BoxDecoration;
      expect(decoration.boxShadow!.first.color, const Color(0xAA00D863));
      await tester.ensureVisible(cell);
      await tester.tap(cell);
    }
    await tester.pump();
    expect(bloc.state.isDiceRolled, isFalse);
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    expect(bloc.state.isDiceRolled, isTrue);
  });
}
