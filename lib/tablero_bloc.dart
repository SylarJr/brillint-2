import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'mapas.dart';
import 'multiplayer_service.dart';
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

class BoardMapSelected extends BoardEvent {
  const BoardMapSelected(this.index);

  final int index;
}

class BoardMapStarted extends BoardEvent {
  const BoardMapStarted(this.index);

  final int index;
}

class BoardMapExited extends BoardEvent {
  const BoardMapExited();
}

class PlaceNumberEvent extends BoardEvent {
  const PlaceNumberEvent(this.row, this.col, this.number);

  final int row;
  final int col;
  final int number;
}

class UndoLastPlacementEvent extends BoardEvent {
  const UndoLastPlacementEvent();
}

class UndoPendingMoveEvent extends BoardEvent {
  const UndoPendingMoveEvent();
}

class ConfirmMoveEvent extends BoardEvent {
  const ConfirmMoveEvent();
}

class BoardReadyPressed extends BoardEvent {
  const BoardReadyPressed();
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
    this.historialAsignaciones = const [],
    this.movimientoPendiente = const {},
    this.dados = const [],
    this.validPositions = const {},
    this.isDiceRolled = false,
    this.enviandoListo = false,
    this.enviandoJugada = false,
    this.turnoConfirmado = false,
    this.selectedDiceValue,
    this.mapaSeleccionado = 0,
    this.mapaAbierto = false,
  });

  static const mapas = mapasTablero;
  static final List<List<Tipo>> matrizInicial = mapaInicial.matriz;

  static const Set<(int, int)> casillasObjetivo =
      puntosInicialesPredeterminados;

  static const List<int> numerosPermitidos = [1, 2, 3, 4, 5, 6];

  final List<List<Tipo>> matriz;
  final Set<(int, int)> casillasMarcadas;
  final Map<(int, int), int> asignaciones;
  final (int, int)? casillaSeleccionada;
  final bool listoParaJugar;
  final (int, int)? casillaOrigenMovimiento;
  final List<Map<(int, int), int>> historialAsignaciones;
  final Map<(int, int), int> movimientoPendiente;
  final List<int> dados;
  final Set<Point<int>> validPositions;
  final bool isDiceRolled;
  final bool enviandoListo;
  final bool enviandoJugada;
  final bool turnoConfirmado;
  final int? selectedDiceValue;
  final int mapaSeleccionado;
  final bool mapaAbierto;

  List<int> get dice => dados;

  List<int> get numerosDisponibles => numerosPermitidos
      .where((numero) => !asignaciones.values.contains(numero))
      .toList(growable: false);

  bool get completo => asignaciones.length == casillasMarcadas.length;

  bool get preparacionCompleta =>
      completo &&
      asignaciones.length == numerosPermitidos.length &&
      asignaciones.values.toSet().containsAll(numerosPermitidos);

  bool esCasillaMarcada(int fila, int columna) =>
      casillasMarcadas.contains((fila, columna));

  int? numeroEn(int fila, int columna) => asignaciones[(fila, columna)];

  int? numeroVisibleEn(int fila, int columna) =>
      movimientoPendiente[(fila, columna)] ?? numeroEn(fila, columna);

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

  bool puedeAsignarNumero(
    int fila,
    int columna,
    int numero, {
    Set<(int, int)> excluir = const {},
  }) {
    if (fila < 0 ||
        fila >= matriz.length ||
        columna < 0 ||
        columna >= matriz[fila].length) {
      return false;
    }
    return _cumpleReglaDeRegion(fila, columna, numero, excluir: excluir);
  }

  Set<Point<int>> calcularPosicionesValidas(int numero) => {
    for (var fila = 0; fila < matriz.length; fila++)
      for (var columna = 0; columna < matriz[fila].length; columna++)
        if (numerosColocablesEn(fila, columna).contains(numero))
          Point<int>(fila, columna),
  };

  bool _cumpleReglaDeRegion(
    int fila,
    int columna,
    int numero, {
    Set<(int, int)> excluir = const {},
  }) {
    final tipo = matriz[fila][columna];
    if (tipo is TipoBlanco) {
      final valoresBlancos = [
        for (var filaBlanca = 0; filaBlanca < matriz.length; filaBlanca++)
          for (
            var columnaBlanca = 0;
            columnaBlanca < matriz[filaBlanca].length;
            columnaBlanca++
          )
            if (matriz[filaBlanca][columnaBlanca] is TipoBlanco &&
                !excluir.contains((filaBlanca, columnaBlanca)) &&
                asignaciones[(filaBlanca, columnaBlanca)] != null)
              asignaciones[(filaBlanca, columnaBlanca)]!,
      ];
      return tipo.puedeAgregarValor(valoresBlancos, numero);
    }

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

      final valor = excluir.contains(actual) ? null : asignaciones[actual];
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

  factory BoardState.inicial({
    int mapaSeleccionado = 0,
    bool mapaAbierto = false,
  }) => BoardState(
    matriz: mapas[mapaSeleccionado].matriz,
    casillasMarcadas: mapas[mapaSeleccionado].puntosIniciales,
    asignaciones: const {},
    casillaSeleccionada: null,
    listoParaJugar: false,
    mapaSeleccionado: mapaSeleccionado,
    casillaOrigenMovimiento: null,
    dados: const [],
    validPositions: const {},
    isDiceRolled: false,
    mapaAbierto: mapaAbierto,
  );

  BoardState copyWith({
    Map<(int, int), int>? asignaciones,
    (int, int)? casillaSeleccionada,
    (int, int)? casillaOrigenMovimiento,
    bool? listoParaJugar,
    List<int>? dados,
    Set<Point<int>>? validPositions,
    bool? isDiceRolled,
    bool? enviandoListo,
    bool? enviandoJugada,
    bool? turnoConfirmado,
    List<Map<(int, int), int>>? historialAsignaciones,
    Map<(int, int), int>? movimientoPendiente,
    int? selectedDiceValue,
    int? mapaSeleccionado,
    bool? mapaAbierto,
    bool clearSelection = false,
    bool clearMoveSource = false,
    bool clearMovimientoPendiente = false,
    bool clearSelectedDiceValue = false,
  }) => BoardState(
    matriz: matriz,
    mapaSeleccionado: mapaSeleccionado ?? this.mapaSeleccionado,
    mapaAbierto: mapaAbierto ?? this.mapaAbierto,
    casillasMarcadas: casillasMarcadas,
    asignaciones: asignaciones ?? this.asignaciones,
    casillaSeleccionada: clearSelection
        ? null
        : casillaSeleccionada ?? this.casillaSeleccionada,
    listoParaJugar: listoParaJugar ?? this.listoParaJugar,
    casillaOrigenMovimiento: clearMoveSource
        ? null
        : casillaOrigenMovimiento ?? this.casillaOrigenMovimiento,
    historialAsignaciones: historialAsignaciones ?? this.historialAsignaciones,
    movimientoPendiente: clearMovimientoPendiente
        ? const {}
        : movimientoPendiente ?? this.movimientoPendiente,
    dados: dados ?? this.dados,
    validPositions: validPositions ?? this.validPositions,
    isDiceRolled: isDiceRolled ?? this.isDiceRolled,
    enviandoListo: enviandoListo ?? this.enviandoListo,
    enviandoJugada: enviandoJugada ?? this.enviandoJugada,
    turnoConfirmado: turnoConfirmado ?? this.turnoConfirmado,
    selectedDiceValue: clearSelectedDiceValue
        ? null
        : selectedDiceValue ?? this.selectedDiceValue,
  );
}

class BoardBloc extends Bloc<BoardEvent, BoardState> {
  BoardBloc({MultiplayerService? multiplayer})
    : _multiplayer = multiplayer,
      _lastServerAssignments = multiplayer?.assignments ?? const {},
      _lastServerDice = multiplayer?.dice ?? const [],
      _lastServerDiceRoll = multiplayer?.diceRollId ?? 0,
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

    on<BoardMapSelected>((event, emit) {
      if (state.listoParaJugar ||
          event.index < 0 ||
          event.index >= BoardState.mapas.length ||
          event.index == state.mapaSeleccionado) {
        return;
      }
      emit(BoardState.inicial(mapaSeleccionado: event.index));
    });

    on<BoardMapStarted>((event, emit) {
      if (event.index < 0 || event.index >= BoardState.mapas.length) return;
      emit(
        BoardState.inicial(mapaSeleccionado: event.index, mapaAbierto: true),
      );
    });

    on<BoardMapExited>((event, emit) {
      if (!state.mapaAbierto ||
          state.asignaciones.isNotEmpty ||
          state.listoParaJugar) {
        return;
      }
      emit(state.copyWith(mapaAbierto: false, clearSelection: true));
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
        final posicionesExcluidas = {origen, casilla};
        if (!state.puedeAsignarNumero(
              casilla.$1,
              casilla.$2,
              event.numero,
              excluir: posicionesExcluidas,
            ) ||
            (valorDestino != null &&
                !state.puedeAsignarNumero(
                  origen.$1,
                  origen.$2,
                  valorDestino,
                  excluir: posicionesExcluidas,
                ))) {
          return;
        }

        final nuevasAsignaciones = Map<(int, int), int>.of(state.asignaciones)
          ..remove(origen);
        nuevasAsignaciones[casilla] = event.numero;
        if (valorDestino != null) nuevasAsignaciones[origen] = valorDestino;
        emit(
          state.copyWith(
            asignaciones: Map.unmodifiable(nuevasAsignaciones),
            historialAsignaciones: [
              ...state.historialAsignaciones,
              Map.unmodifiable(state.asignaciones),
            ],
            clearSelection: true,
            clearMoveSource: true,
          ),
        );
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
        if (!state.puedeAsignarNumero(
          casilla.$1,
          casilla.$2,
          event.numero,
          excluir: {origenExistente},
        )) {
          return;
        }
        final nuevasAsignaciones = Map<(int, int), int>.of(state.asignaciones)
          ..remove(origenExistente);
        nuevasAsignaciones[casilla] = event.numero;
        emit(
          state.copyWith(
            asignaciones: Map.unmodifiable(nuevasAsignaciones),
            historialAsignaciones: [
              ...state.historialAsignaciones,
              Map.unmodifiable(state.asignaciones),
            ],
            clearSelection: true,
          ),
        );
        return;
      }

      if (!state.puedeAsignarNumero(casilla.$1, casilla.$2, event.numero)) {
        return;
      }

      emit(
        state.copyWith(
          asignaciones: Map.unmodifiable({
            ...state.asignaciones,
            casilla: event.numero,
          }),
          historialAsignaciones: [
            ...state.historialAsignaciones,
            Map.unmodifiable(state.asignaciones),
          ],
          clearSelection: true,
        ),
      );
    });

    on<UndoLastPlacementEvent>((event, emit) {
      if (_multiplayer?.gameStarted == true ||
          state.listoParaJugar ||
          state.historialAsignaciones.isEmpty) {
        return;
      }
      emit(
        state.copyWith(
          asignaciones: state.historialAsignaciones.last,
          historialAsignaciones: state.historialAsignaciones
              .take(state.historialAsignaciones.length - 1)
              .toList(growable: false),
          clearSelection: true,
          clearMoveSource: true,
        ),
      );
    });

    on<BoardReadyPressed>((event, emit) async {
      if (!state.preparacionCompleta ||
          state.listoParaJugar ||
          state.enviandoListo) {
        return;
      }

      emit(state.copyWith(enviandoListo: true, clearSelection: true));
      try {
        await _multiplayer?.submitInitialBoard(state.asignaciones);
        emit(
          state.copyWith(
            listoParaJugar: true,
            enviandoListo: false,
            historialAsignaciones: const [],
          ),
        );
      } catch (_) {
        emit(state.copyWith(enviandoListo: false));
      }
    });

    on<UndoPendingMoveEvent>((event, emit) {
      if (state.movimientoPendiente.isEmpty ||
          state.turnoConfirmado ||
          state.enviandoJugada) {
        return;
      }
      emit(
        state.copyWith(
          clearMovimientoPendiente: true,
          validPositions: state.selectedDiceValue == null
              ? const {}
              : state.calcularPosicionesValidas(state.selectedDiceValue!),
        ),
      );
    });

    on<SelectDiceValueEvent>((event, emit) {
      if (_multiplayer?.gameStarted != true ||
          !state.isDiceRolled ||
          !state.dados.contains(event.number)) {
        return;
      }
      emit(
        state.copyWith(
          selectedDiceValue: event.number,
          validPositions: state.calcularPosicionesValidas(event.number),
        ),
      );
    });

    on<PlaceNumberEvent>((event, emit) {
      if (!state.listoParaJugar ||
          _multiplayer?.gameStarted != true ||
          !state.isDiceRolled ||
          state.selectedDiceValue != event.number ||
          !state
              .numerosColocablesEn(event.row, event.col)
              .contains(event.number) ||
          state.movimientoPendiente.isNotEmpty ||
          state.turnoConfirmado) {
        return;
      }

      emit(
        state.copyWith(
          movimientoPendiente: {(event.row, event.col): event.number},
          validPositions: const {},
        ),
      );
    });

    on<ConfirmMoveEvent>((event, emit) async {
      final multiplayer = _multiplayer;
      if (state.movimientoPendiente.isEmpty ||
          state.turnoConfirmado ||
          state.enviandoJugada ||
          multiplayer?.gameStarted != true) {
        return;
      }

      final entry = state.movimientoPendiente.entries.single;
      final rollId = multiplayer!.diceRollId;
      emit(state.copyWith(enviandoJugada: true));
      try {
        await multiplayer.placeNumber(entry.key.$1, entry.key.$2, entry.value);
        final roundAlreadyAdvanced = multiplayer.diceRollId != rollId;
        emit(
          state.copyWith(
            enviandoJugada: false,
            turnoConfirmado: !roundAlreadyAdvanced,
            clearMovimientoPendiente: roundAlreadyAdvanced,
          ),
        );
      } catch (_) {
        // The service exposes the server error to the player.
        emit(state.copyWith(enviandoJugada: false));
      }
    });

    on<_ServerBoardUpdated>((event, emit) {
      final pending = state.movimientoPendiente;
      final pendingMoveApplied =
          event.assignments != null &&
          pending.isNotEmpty &&
          event.assignments![pending.keys.single] == pending.values.single;
      emit(
        state.copyWith(
          asignaciones: event.assignments == null
              ? null
              : Map.unmodifiable(event.assignments!),
          dados: event.dice,
          isDiceRolled: event.dice.isNotEmpty,
          turnoConfirmado: event.newDiceRoll ? false : null,
          clearMovimientoPendiente: pendingMoveApplied || event.newDiceRoll,
          validPositions: const {},
          clearSelectedDiceValue: true,
        ),
      );
    });

    if (_multiplayer != null) {
      _multiplayer.addListener(_onMultiplayerChanged);
    }
  }

  void _onMultiplayerChanged() {
    if (_multiplayer == null || isClosed) return;
    if (!_multiplayer.gameStarted) return;
    final assignmentsChanged = !mapEquals(
      _lastServerAssignments,
      _multiplayer.assignments,
    );
    final diceChanged = !listEquals(_lastServerDice, _multiplayer.dice);
    final diceRollChanged = _lastServerDiceRoll != _multiplayer.diceRollId;
    if (!assignmentsChanged && !diceChanged && !diceRollChanged) {
      return;
    }
    _lastServerAssignments = Map.unmodifiable(_multiplayer.assignments);
    _lastServerDice = List.unmodifiable(_multiplayer.dice);
    _lastServerDiceRoll = _multiplayer.diceRollId;
    add(
      _ServerBoardUpdated(
        assignmentsChanged ? _multiplayer.assignments : null,
        _multiplayer.dice,
        diceRollChanged,
      ),
    );
  }

  final MultiplayerService? _multiplayer;
  Map<(int, int), int> _lastServerAssignments;
  List<int> _lastServerDice;
  int _lastServerDiceRoll;

  @override
  Future<void> close() {
    _multiplayer?.removeListener(_onMultiplayerChanged);
    return super.close();
  }
}

class _ServerBoardUpdated extends BoardEvent {
  const _ServerBoardUpdated(this.assignments, this.dice, this.newDiceRoll);

  final Map<(int, int), int>? assignments;
  final List<int> dice;
  final bool newDiceRoll;
}
