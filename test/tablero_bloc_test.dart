import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_application_1/tablero_bloc.dart';
import 'package:flutter_application_1/tipo.dart';

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
}

void main() {
  group('BoardBloc - preparación del tablero', () {
    test(
      'seleccionar un mapa nuevo lo carga y reinicia la preparación',
      () async {
        final bloc = BoardBloc();
        addTearDown(bloc.close);

        final selected = bloc.stream.firstWhere(
          (state) => state.mapaSeleccionado == 1,
        );
        bloc.add(const BoardMapSelected(1));
        final state = await selected;

        expect(state.matriz, BoardState.mapas[1].matriz);
        expect(state.asignaciones, isEmpty);
        expect(state.casillaSeleccionada, isNull);
        expect(state.listoParaJugar, isFalse);
      },
    );

    test('no permite cambiar el mapa después de iniciar la partida', () async {
      final bloc = BoardBloc();
      addTearDown(bloc.close);
      await _startGame(bloc);

      bloc.add(const BoardMapSelected(1));
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state.mapaSeleccionado, 0);
    });

    test('valida los números naranja al preparar el mapa 3', () async {
      final bloc = BoardBloc();
      addTearDown(bloc.close);

      final mapSelected = bloc.stream.firstWhere(
        (state) => state.mapaSeleccionado == 3,
      );
      bloc.add(const BoardMapSelected(3));
      await mapSelected;

      bloc.add(const BoardCellSelected(0, 4));
      await bloc.stream.firstWhere(
        (state) => state.casillaSeleccionada == (0, 4),
      );
      bloc.add(const BoardNumberAssigned(3));
      await Future<void>.delayed(Duration.zero);
      expect(bloc.state.numeroEn(0, 4), isNull);

      final upperNumberAssigned = bloc.stream.firstWhere(
        (state) => state.numeroEn(0, 4) == 4,
      );
      bloc.add(const BoardNumberAssigned(4));
      await upperNumberAssigned;

      final lowerCellSelected = bloc.stream.firstWhere(
        (state) => state.casillaSeleccionada == (6, 1),
      );
      bloc.add(const BoardCellSelected(6, 1));
      await lowerCellSelected;
      final lowerNumberAssigned = bloc.stream.firstWhere(
        (state) => state.numeroEn(6, 1) == 1,
      );
      bloc.add(const BoardNumberAssigned(1));
      await lowerNumberAssigned;
    });

    test(
      'blanco comparte la restricción aunque sus casillas estén separadas',
      () {
        final matriz = List.generate(
          7,
          (_) => List<Tipo>.filled(7, const TipoVerde()),
        );
        matriz[0][1] = const TipoBlanco();
        matriz[6][6] = const TipoBlanco();
        final state = BoardState(
          matriz: matriz,
          casillasMarcadas: const {},
          asignaciones: const {(0, 0): 2, (6, 6): 3},
          casillaSeleccionada: null,
          listoParaJugar: true,
        );
        expect(state.puedeAsignarNumero(0, 1, 4), isFalse);
      },
    );

    test('rechaza números iniciales en casillas no marcadas', () async {
      final bloc = BoardBloc();
      addTearDown(bloc.close);
      await _startGame(bloc, ready: false, count: 5);

      bloc.add(const BoardCellSelected(0, 0));
      await Future<void>.delayed(Duration.zero);
      expect(bloc.state.casillaSeleccionada, isNull);
      bloc.add(const BoardNumberAssigned(1));
      await Future<void>.delayed(Duration.zero);
      expect(bloc.state.numeroEn(0, 0), isNull);
      expect(bloc.state.asignaciones.length, 5);

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
      final bloc = BoardBloc();
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

    test('completar la preparación no genera dados localmente', () async {
      final bloc = BoardBloc();
      addTearDown(bloc.close);
      await _startGame(bloc);

      expect(bloc.state.asignaciones.length, 6);
      expect(bloc.state.asignaciones.values.toSet(), {1, 2, 3, 4, 5, 6});
      expect(bloc.state.completo, isTrue);
      expect(bloc.state.listoParaJugar, isTrue);
      expect(bloc.state.isDiceRolled, isFalse);
    });
  });
}
