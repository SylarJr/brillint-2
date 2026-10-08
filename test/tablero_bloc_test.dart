import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import '../lib/tablero_bloc.dart';

class _FixedRandom implements Random {
  _FixedRandom(this.values);

  final List<int> values;
  var _index = 0;

  @override
  int nextInt(int max) => values[_index++] % max;

  @override
  bool nextBool() => false;

  @override
  double nextDouble() => 0;
}

Future<void> _startGame(
  BoardBloc bloc, {
  bool ready = true,
  int count = 6,
}) async {
  for (var index = 0; index < count; index++) {
    final position = BoardState.casillasObjetivo.elementAt(index);
    final selection = bloc.stream.firstWhere(
      (state) => state.casillaSeleccionada == position,
    );
    bloc.add(BoardCellSelected(position.$1, position.$2));
    await selection;

    final assignment = bloc.stream.firstWhere(
      (state) => state.numeroEn(position.$1, position.$2) == index + 1,
    );
    bloc.add(BoardNumberAssigned(index + 1));
    await assignment;
  }

  if (!ready || !bloc.state.completo) return;
  if (!bloc.state.listoParaJugar) {
    await bloc.stream.firstWhere((state) => state.listoParaJugar);
  }
  if (!bloc.state.isDiceRolled) {
    await bloc.stream.firstWhere((state) => state.isDiceRolled);
  }
}

void main() {
  group('BoardBloc - turnos con dados', () {
    test('resalta y coloca solo una jugada válida, sin sobrescribir', () async {
      final bloc = BoardBloc(random: _FixedRandom([0, 3]));
      addTearDown(bloc.close);
      await _startGame(bloc);

      final state = bloc.state;

      expect(state.listoParaJugar, isTrue);
      expect(state.isDiceRolled, isTrue);
      expect(state.dados, [1, 4]);
      expect(state.validPositions, contains(const Point<int>(0, 1)));
      expect(state.numerosColocablesEn(0, 1), contains(4));
      expect(state.numerosColocablesEn(1, 2), isNot(contains(4)));

      bloc.add(const PlaceNumberEvent(0, 2, 4));
      await Future<void>.delayed(Duration.zero);
      expect(bloc.state.numeroEn(0, 2), 1);
      expect(bloc.state.isDiceRolled, isTrue);

      final placed = bloc.stream.firstWhere((next) => next.numeroEn(0, 1) == 4);
      bloc.add(const PlaceNumberEvent(0, 1, 4));
      final afterPlacement = await placed;

      expect(afterPlacement.isDiceRolled, isFalse);
      expect(afterPlacement.validPositions, isEmpty);
      expect(afterPlacement.dados, isEmpty);
    });

    test('rechaza números iniciales en casillas no marcadas', () async {
      final bloc = BoardBloc(random: _FixedRandom([0, 3]));
      addTearDown(bloc.close);
      await _startGame(bloc, ready: false, count: 5);

      bloc.add(const BoardCellSelected(0, 0));
      await Future<void>.delayed(Duration.zero);
      expect(bloc.state.casillaSeleccionada, isNull);
      bloc.add(const BoardNumberAssigned(1));
      await Future<void>.delayed(Duration.zero);
      expect(bloc.state.numeroEn(0, 0), isNull);
      expect(bloc.state.asignaciones.length, 5);
      expect(bloc.state.isDiceRolled, isFalse);

      final sourceSelected = bloc.stream.firstWhere(
        (state) => state.casillaOrigenMovimiento == (0, 2),
      );
      bloc.add(const BoardCellSelected(0, 2));
      await sourceSelected;
      bloc.add(const BoardCellSelected(0, 0));
      await Future<void>.delayed(Duration.zero);
      bloc.add(const BoardNumberAssigned(1));
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state.numeroEn(0, 2), 1);
      expect(bloc.state.numeroEn(0, 0), isNull);
      expect(bloc.state.asignaciones.length, 5);
    });

    test('reseleccionar un número lo mueve a la casilla vacía', () async {
      final bloc = BoardBloc(random: _FixedRandom([0, 3]));
      addTearDown(bloc.close);
      await _startGame(bloc, ready: false, count: 5);

      final destino = BoardState.casillasObjetivo.elementAt(5);
      final selected = bloc.stream.firstWhere(
        (state) => state.casillaSeleccionada == destino,
      );
      bloc.add(BoardCellSelected(destino.$1, destino.$2));
      await selected;

      final moved = bloc.stream.firstWhere(
        (state) => state.numeroEn(destino.$1, destino.$2) == 1,
      );
      bloc.add(const BoardNumberAssigned(1));
      final afterMove = await moved;

      expect(afterMove.numeroEn(0, 2), isNull);
      expect(afterMove.asignaciones.length, 5);
      expect(afterMove.asignaciones.values.toSet(), {1, 2, 3, 4, 5});

      final sourceSelected = bloc.stream.firstWhere(
        (state) => state.casillaSeleccionada == (0, 2),
      );
      bloc.add(const BoardCellSelected(0, 2));
      await sourceSelected;
      final completed = bloc.stream.firstWhere((state) => state.completo);
      bloc.add(const BoardNumberAssigned(6));
      final completedState = await completed;

      expect(completedState.asignaciones.length, 6);
      expect(completedState.asignaciones.values.toSet(), {1, 2, 3, 4, 5, 6});
    });

    test(
      'inicia y lanza los dados al completar los números iniciales',
      () async {
        final bloc = BoardBloc(random: _FixedRandom([0, 3]));
        addTearDown(bloc.close);
        await _startGame(bloc);

        expect(bloc.state.asignaciones.length, 6);
        expect(bloc.state.asignaciones.values.toSet(), {1, 2, 3, 4, 5, 6});
        expect(bloc.state.completo, isTrue);
        expect(bloc.state.listoParaJugar, isTrue);
        expect(bloc.state.isDiceRolled, isTrue);
      },
    );

    test(
      'pasar turno conserva el tablero y habilita otro lanzamiento',
      () async {
        final bloc = BoardBloc(random: _FixedRandom([0, 3, 1, 2]));
        addTearDown(bloc.close);
        await _startGame(bloc);

        final assignmentsBeforeSkip = Map.of(bloc.state.asignaciones);

        final skipped = bloc.stream.firstWhere((state) => !state.isDiceRolled);
        bloc.add(const SkipTurnEvent());
        final afterSkip = await skipped;

        expect(afterSkip.asignaciones, assignmentsBeforeSkip);
        expect(afterSkip.validPositions, isEmpty);
        expect(afterSkip.dados, isEmpty);

        final rolledAgain = bloc.stream.firstWhere(
          (state) => state.isDiceRolled,
        );
        await Future<void>.delayed(const Duration(seconds: 2));
        await rolledAgain;
        expect(bloc.state.dados, [2, 3]);
      },
    );
  });
}
