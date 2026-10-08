import 'dart:math';

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

class RollDiceEvent extends BoardEvent {
  const RollDiceEvent();
}

class PlaceNumberEvent extends BoardEvent {
  const PlaceNumberEvent(this.row, this.col, this.number);

  final int row;
  final int col;
  final int number;
}

class SkipTurnEvent extends BoardEvent {
  const SkipTurnEvent();
}

class SelectDiceValueEvent extends BoardEvent {
  const SelectDiceValueEvent(this.number);

  final int number;
}

class BoardState {
  BoardState({
    required this.matriz,
    required this.casillasMarcadas,
    required this.asignaciones,
    required this.casillaSeleccionada,
    required this.listoParaJugar,
    this.casillaOrigenMovimiento,
    this.dados = const [],
    this.validPositions = const {},
    this.isDiceRolled = false,
    this.selectedDiceValue,
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
      TipoRojo(),
      TipoRojo(),
      TipoAzul(),
      TipoMorado(),
      TipoVerde(),
      TipoVerde(),
    ],
    [
      TipoVerde(),
      TipoRojo(),
      TipoMorado(),
      TipoAmarillo(),
      TipoVerde(),
      TipoVerde(),
      TipoVerde(),
    ],
    [
      TipoVerde(),
      TipoRojo(),
      TipoMorado(),
      TipoMorado(),
      TipoRojo(),
      TipoRojo(),
      TipoAzul(),
    ],
    [
      TipoRojo(),
      TipoRojo(),
      TipoMorado(),
      TipoRojo(),
      TipoRojo(),
      TipoAzul(),
      TipoAzul(),
    ],
    [
      TipoAmarillo(),
      TipoMorado(),
      TipoMorado(),
      TipoRojo(),
      TipoRojo(),
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
  final (int, int)? casillaOrigenMovimiento;
  final List<int> dados;
  final Set<Point<int>> validPositions;
  final bool isDiceRolled;
  final int? selectedDiceValue;

  List<int> get dice => dados;

  List<int> get numerosDisponibles => numerosPermitidos
      .where((numero) => !asignaciones.values.contains(numero))
      .toList(growable: false);

  bool get completo => asignaciones.length == casillasMarcadas.length;

  bool esCasillaMarcada(int fila, int columna) =>
      casillasMarcadas.contains((fila, columna));

  int? numeroEn(int fila, int columna) => asignaciones[(fila, columna)];

  List<int> numerosColocablesEn(int fila, int columna) {
    if (!isDiceRolled ||
        fila < 0 ||
        fila >= matriz.length ||
        columna < 0 ||
        columna >= matriz[fila].length ||
        numeroEn(fila, columna) != null) {
      return const [];
    }

    return dados
        .toSet()
        .where((numero) {
          final adyacenteAlComplementario =
              <(int, int)>[
                (fila - 1, columna),
                (fila + 1, columna),
                (fila, columna - 1),
                (fila, columna + 1),
              ].any((vecino) {
                final valorVecino = asignaciones[vecino];
                if (valorVecino == null) return false;
                return (numero == dados[0] && valorVecino == dados[1]) ||
                    (numero == dados[1] && valorVecino == dados[0]);
              });

          return adyacenteAlComplementario &&
              _cumpleReglaDeRegion(fila, columna, numero);
        })
        .toList(growable: false);
  }

  Set<Point<int>> calcularPosicionesValidas() => {
    for (var fila = 0; fila < matriz.length; fila++)
      for (var columna = 0; columna < matriz[fila].length; columna++)
        if (numerosColocablesEn(fila, columna).isNotEmpty)
          Point<int>(fila, columna),
  };

  bool _cumpleReglaDeRegion(int fila, int columna, int numero) {
    final tipo = matriz[fila][columna];
    final pendientes = <(int, int)>[(fila, columna)];
    final visitadas = <(int, int)>{};
    final valoresRegion = <int>[];

    while (pendientes.isNotEmpty) {
      final actual = pendientes.removeLast();
      if (!visitadas.add(actual)) continue;
      final (actualFila, actualColumna) = actual;
      if (matriz[actualFila][actualColumna].runtimeType != tipo.runtimeType) {
        continue;
      }

      final valor = asignaciones[actual];
      if (valor != null) valoresRegion.add(valor);
      pendientes.addAll(
        [
          (actualFila - 1, actualColumna),
          (actualFila + 1, actualColumna),
          (actualFila, actualColumna - 1),
          (actualFila, actualColumna + 1),
        ].where(
          (posicion) =>
              posicion.$1 >= 0 &&
              posicion.$1 < matriz.length &&
              posicion.$2 >= 0 &&
              posicion.$2 < matriz[posicion.$1].length &&
              !visitadas.contains(posicion),
        ),
      );
    }

    return tipo.puedeAgregarValor(valoresRegion, numero);
  }

  factory BoardState.inicial() => BoardState(
    matriz: matrizInicial,
    casillasMarcadas: casillasObjetivo,
    asignaciones: const {},
    casillaSeleccionada: null,
    listoParaJugar: false,
    casillaOrigenMovimiento: null,
    dados: const [],
    validPositions: const {},
    isDiceRolled: false,
  );

  BoardState copyWith({
    Map<(int, int), int>? asignaciones,
    (int, int)? casillaSeleccionada,
    (int, int)? casillaOrigenMovimiento,
    bool? listoParaJugar,
    List<int>? dados,
    Set<Point<int>>? validPositions,
    bool? isDiceRolled,
    int? selectedDiceValue,
    bool clearTurn = false,
    bool clearSelection = false,
    bool clearMoveSource = false,
    bool clearSelectedDiceValue = false,
  }) => BoardState(
    matriz: matriz,
    casillasMarcadas: casillasMarcadas,
    asignaciones: asignaciones ?? this.asignaciones,
    casillaSeleccionada: clearSelection
        ? null
        : casillaSeleccionada ?? this.casillaSeleccionada,
    listoParaJugar: listoParaJugar ?? this.listoParaJugar,
    casillaOrigenMovimiento: clearMoveSource
        ? null
        : casillaOrigenMovimiento ?? this.casillaOrigenMovimiento,
    dados: clearTurn ? const [] : dados ?? this.dados,
    validPositions: clearTurn
        ? const {}
        : validPositions ?? this.validPositions,
    isDiceRolled: clearTurn ? false : isDiceRolled ?? this.isDiceRolled,
    selectedDiceValue: clearTurn || clearSelectedDiceValue
        ? null
        : selectedDiceValue ?? this.selectedDiceValue,
  );
}

class BoardBloc extends Bloc<BoardEvent, BoardState> {
  BoardBloc({Random? random})
    : _random = random ?? Random(),
      super(BoardState.inicial()) {
    on<BoardCellSelected>((event, emit) {
      if (event.fila < 0 ||
          event.fila >= state.matriz.length ||
          event.columna < 0 ||
          event.columna >= state.matriz[event.fila].length ||
          !state.esCasillaMarcada(event.fila, event.columna) ||
          state.listoParaJugar) {
        return;
      }

      final posicion = (event.fila, event.columna);
      if (state.numeroEn(event.fila, event.columna) != null) {
        if (state.casillaOrigenMovimiento == posicion) {
          emit(state.copyWith(clearSelection: true, clearMoveSource: true));
        } else if (state.casillaOrigenMovimiento != null) {
          emit(state.copyWith(casillaSeleccionada: posicion));
        } else {
          emit(
            state.copyWith(
              casillaSeleccionada: posicion,
              casillaOrigenMovimiento: posicion,
            ),
          );
        }
        return;
      }

      emit(state.copyWith(casillaSeleccionada: posicion));
    });

    on<BoardNumberAssigned>((event, emit) {
      final casilla = state.casillaSeleccionada;
      if (casilla == null ||
          !state.esCasillaMarcada(casilla.$1, casilla.$2) ||
          !BoardState.numerosPermitidos.contains(event.numero) ||
          state.listoParaJugar) {
        return;
      }

      final origen = state.casillaOrigenMovimiento;
      if (origen != null) {
        final valorDestino = state.numeroEn(casilla.$1, casilla.$2);
        if (!state.esCasillaMarcada(origen.$1, origen.$2) ||
            state.asignaciones[origen] != event.numero ||
            casilla == origen) {
          return;
        }

        final nuevasAsignaciones = Map<(int, int), int>.of(state.asignaciones)
          ..remove(origen);
        nuevasAsignaciones[casilla] = event.numero;
        if (valorDestino != null) nuevasAsignaciones[origen] = valorDestino;
        emit(
          state.copyWith(
            asignaciones: Map.unmodifiable(nuevasAsignaciones),
            clearSelection: true,
            clearMoveSource: true,
          ),
        );
        _startGameIfSetupComplete(emit);
        return;
      }

      if (state.numeroEn(casilla.$1, casilla.$2) != null) {
        return;
      }

      final origenExistente = state.asignaciones.entries
          .where((entrada) => entrada.value == event.numero)
          .firstOrNull
          ?.key;
      if (origenExistente != null) {
        if (!state.esCasillaMarcada(origenExistente.$1, origenExistente.$2)) {
          return;
        }
        final nuevasAsignaciones = Map<(int, int), int>.of(state.asignaciones)
          ..remove(origenExistente);
        nuevasAsignaciones[casilla] = event.numero;
        emit(
          state.copyWith(
            asignaciones: Map.unmodifiable(nuevasAsignaciones),
            clearSelection: true,
          ),
        );
        _startGameIfSetupComplete(emit);
        return;
      }

      emit(
        state.copyWith(
          asignaciones: Map.unmodifiable({
            ...state.asignaciones,
            casilla: event.numero,
          }),
          clearSelection: true,
        ),
      );
      _startGameIfSetupComplete(emit);
    });

    on<BoardReadyPressed>((event, emit) {
      if (!state.completo || state.listoParaJugar) return;
      emit(state.copyWith(listoParaJugar: true, clearSelection: true));
    });

    on<RollDiceEvent>((event, emit) {
      if (!state.listoParaJugar || state.isDiceRolled) return;
      final conDados = state.copyWith(
        dados: [1 + _random.nextInt(6), 1 + _random.nextInt(6)],
        isDiceRolled: true,
        clearSelectedDiceValue: true,
      );
      emit(
        conDados.copyWith(validPositions: conDados.calcularPosicionesValidas()),
      );
    });

    on<SelectDiceValueEvent>((event, emit) {
      if (!state.isDiceRolled || !state.dados.contains(event.number)) return;
      emit(state.copyWith(selectedDiceValue: event.number));
    });

    on<PlaceNumberEvent>((event, emit) async {
      if (!state.listoParaJugar ||
          !state.isDiceRolled ||
          !state
              .numerosColocablesEn(event.row, event.col)
              .contains(event.number)) {
        return;
      }

      emit(
        state.copyWith(
          asignaciones: Map.unmodifiable({
            ...state.asignaciones,
            (event.row, event.col): event.number,
          }),
          clearTurn: true,
        ),
      );
      await Future<void>.delayed(const Duration(seconds: 2));
      if (!isClosed && state.listoParaJugar && !state.isDiceRolled) {
        add(const RollDiceEvent());
      }
    });

    on<SkipTurnEvent>((event, emit) async {
      if (!state.listoParaJugar || !state.isDiceRolled) return;
      emit(state.copyWith(clearTurn: true));
      await Future<void>.delayed(const Duration(seconds: 2));
      if (!isClosed && state.listoParaJugar && !state.isDiceRolled) {
        add(const RollDiceEvent());
      }
    });
  }

  void _startGameIfSetupComplete(Emitter<BoardState> emit) {
    if (!state.completo || state.listoParaJugar) return;
    emit(state.copyWith(listoParaJugar: true, clearSelection: true));
    add(const RollDiceEvent());
  }

  final Random _random;
}
