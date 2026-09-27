import 'package:flutter_bloc/flutter_bloc.dart';

import 'tipo.dart';

sealed class BoardEvent {
  const BoardEvent();
}

class BoardCellSelected extends BoardEvent {
  const BoardCellSelected(this.fila, this.columna);

  final int fila;
  final int columna;
}

class BoardNumberAssigned extends BoardEvent {
  const BoardNumberAssigned(this.numero);

  final int numero;
}

class BoardReadyPressed extends BoardEvent {
  const BoardReadyPressed();
}

class BoardState {
  BoardState({
    required this.matriz,
    required this.casillasMarcadas,
    required this.asignaciones,
    required this.casillaSeleccionada,
    required this.listoParaJugar,
  });

  static const List<List<Tipo>> matrizInicial = [
    [
      TipoAmarillo(),
      TipoVerde(),
      TipoAzul(),
      TipoMorado(),
      TipoMorado(),
      TipoMorado(),
      TipoAmarillo(),
    ],
    [
      TipoVerde(),
      TipoVerde(),
      TipoAzul(),
      TipoAzul(),
      TipoMorado(),
      TipoMorado(),
      TipoVerde(),
    ],
    [
      TipoVerde(),
      TipoNaranja(),
      TipoNaranja(),
      TipoAzul(),
      TipoMorado(),
      TipoVerde(),
      TipoVerde(),
    ],
    [
      TipoVerde(),
      TipoNaranja(),
      TipoMorado(),
      TipoAmarillo(),
      TipoVerde(),
      TipoVerde(),
      TipoVerde(),
    ],
    [
      TipoVerde(),
      TipoNaranja(),
      TipoMorado(),
      TipoMorado(),
      TipoNaranja(),
      TipoNaranja(),
      TipoAzul(),
    ],
    [
      TipoNaranja(),
      TipoNaranja(),
      TipoMorado(),
      TipoNaranja(),
      TipoNaranja(),
      TipoAzul(),
      TipoAzul(),
    ],
    [
      TipoAmarillo(),
      TipoMorado(),
      TipoMorado(),
      TipoNaranja(),
      TipoNaranja(),
      TipoAzul(),
      TipoAmarillo(),
    ],
  ];

  static const Set<(int, int)> casillasObjetivo = {
    (0, 2),
    (1, 5),
    (3, 1),
    (3, 4),
    (5, 2),
    (6, 4),
  };

  static const List<int> numerosPermitidos = [1, 2, 3, 4, 5, 6];

  final List<List<Tipo>> matriz;
  final Set<(int, int)> casillasMarcadas;
  final Map<(int, int), int> asignaciones;
  final (int, int)? casillaSeleccionada;
  final bool listoParaJugar;

  List<int> get numerosDisponibles => numerosPermitidos
      .where((numero) => !asignaciones.values.contains(numero))
      .toList(growable: false);

  bool get completo => asignaciones.length == casillasMarcadas.length;

  bool esCasillaMarcada(int fila, int columna) =>
      casillasMarcadas.contains((fila, columna));

  int? numeroEn(int fila, int columna) => asignaciones[(fila, columna)];

  factory BoardState.inicial() => BoardState(
    matriz: matrizInicial,
    casillasMarcadas: casillasObjetivo,
    asignaciones: const {},
    casillaSeleccionada: null,
    listoParaJugar: false,
  );

  BoardState copyWith({
    Map<(int, int), int>? asignaciones,
    (int, int)? casillaSeleccionada,
    bool? listoParaJugar,
  }) => BoardState(
    matriz: matriz,
    casillasMarcadas: casillasMarcadas,
    asignaciones: asignaciones ?? this.asignaciones,
    casillaSeleccionada: casillaSeleccionada ?? this.casillaSeleccionada,
    listoParaJugar: listoParaJugar ?? this.listoParaJugar,
  );
}

class BoardBloc extends Bloc<BoardEvent, BoardState> {
  BoardBloc() : super(BoardState.inicial()) {
    on<BoardCellSelected>((event, emit) {
      if (event.fila < 0 ||
          event.fila >= state.matriz.length ||
          event.columna < 0 ||
          event.columna >= state.matriz[event.fila].length ||
          !state.esCasillaMarcada(event.fila, event.columna) ||
          state.numeroEn(event.fila, event.columna) != null ||
          state.listoParaJugar) {
        return;
      }

      emit(state.copyWith(casillaSeleccionada: (event.fila, event.columna)));
    });

    on<BoardNumberAssigned>((event, emit) {
      final casilla = state.casillaSeleccionada;
      if (casilla == null ||
          !BoardState.numerosPermitidos.contains(event.numero) ||
          !state.numerosDisponibles.contains(event.numero) ||
          state.numeroEn(casilla.$1, casilla.$2) != null ||
          state.listoParaJugar) {
        return;
      }

      emit(
        state.copyWith(
          asignaciones: Map.unmodifiable({
            ...state.asignaciones,
            casilla: event.numero,
          }),
        ),
      );
    });

    on<BoardReadyPressed>((event, emit) {
      if (!state.completo || state.listoParaJugar) return;
      emit(state.copyWith(listoParaJugar: true));
    });
  }
}
