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

Future<void> _startGame(BoardBloc bloc) async {
  for (var index = 0; index < BoardState.casillasObjetivo.length; index++) {
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

  final started = bloc.stream.firstWhere((state) => state.listoParaJugar);
  bloc.add(const BoardReadyPressed());
  await started;
}

void main() {
  group('BoardBloc - turnos con dados', () {
    test('resalta y coloca solo una jugada válida, sin sobrescribir', () async {
      final bloc = BoardBloc(random: _FixedRandom([0, 3]));
      addTearDown(bloc.close);
      await _startGame(bloc);

      final rolled = bloc.stream.firstWhere((state) => state.isDiceRolled);
      bloc.add(const RollDiceEvent());
      final state = await rolled;

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

    test(
      'pasar turno conserva el tablero y habilita otro lanzamiento',
      () async {
        final bloc = BoardBloc(random: _FixedRandom([0, 3, 1, 2]));
        addTearDown(bloc.close);
        await _startGame(bloc);

        final rolled = bloc.stream.firstWhere((state) => state.isDiceRolled);
        bloc.add(const RollDiceEvent());
        await rolled;
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
        bloc.add(const RollDiceEvent());
        await rolledAgain;
        expect(bloc.state.dados, [2, 3]);
      },
    );
  });
}
