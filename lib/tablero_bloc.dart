import 'package:flutter_bloc/flutter_bloc.dart';

import 'tipo.dart';

sealed class TableroEvent {
  const TableroEvent();
}

class SeleccionarCasilla extends TableroEvent {
  const SeleccionarCasilla(this.fila, this.columna);

  final int fila;
  final int columna;
}

class TableroState {
  const TableroState({
    required this.matriz,
    required this.coordenadaSeleccionada,
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

  final List<List<Tipo>> matriz;
  final (int, int) coordenadaSeleccionada;

  factory TableroState.inicial() =>
      const TableroState(matriz: matrizInicial, coordenadaSeleccionada: (0, 0));

  TableroState conSeleccion((int, int) coordenada) =>
      TableroState(matriz: matriz, coordenadaSeleccionada: coordenada);
}

class TableroBloc extends Bloc<TableroEvent, TableroState> {
  TableroBloc() : super(TableroState.inicial()) {
    on<SeleccionarCasilla>((event, emit) {
      if (event.fila < 0 ||
          event.fila >= state.matriz.length ||
          event.columna < 0 ||
          event.columna >= state.matriz[event.fila].length) {
        return;
      }

      emit(state.conSeleccion((event.fila, event.columna)));
    });
  }
}
