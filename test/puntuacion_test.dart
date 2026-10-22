import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_application_1/tablero_bloc.dart';
import 'package:flutter_application_1/tipo.dart';

void main() {
  test('cada zona verde puntúa independientemente como primer puesto', () {
    final estadoInicial = BoardState.inicial();
    final zonasVerdes = estadoInicial.zonas
        .where((zona) => zona.tipo is TipoVerde)
        .take(2)
        .toList();
    final estado = estadoInicial.copyWith(
      zonasCompletadas: zonasVerdes.map((zona) => zona.id).toList(),
    );

    expect(zonasVerdes, hasLength(2));
    expect(estado.historialPuntuacion.map((entrada) => entrada.puesto), [1, 1]);
    expect(estado.historialPuntuacion.map((entrada) => entrada.puntos), [4, 4]);
    expect(estado.puntuacionTotal, 8);
  });

  test('todos los cuadros amarillos forman una sola zona puntuable', () {
    final estadoInicial = BoardState.inicial();
    final zonasAmarillas = estadoInicial.zonas
        .where((zona) => zona.tipo is TipoAmarillo)
        .toList();
    final casillasAmarillas = {
      for (var fila = 0; fila < BoardState.matrizInicial.length; fila++)
        for (
          var columna = 0;
          columna < BoardState.matrizInicial[fila].length;
          columna++
        )
          if (BoardState.matrizInicial[fila][columna] is TipoAmarillo)
            (fila, columna),
    };
    final zonaAzul = estadoInicial.zonas.firstWhere(
      (zona) => zona.tipo is TipoAzul,
    );
    expect(zonasAmarillas, hasLength(1));
    expect(zonasAmarillas.single.casillas, casillasAmarillas);

    final estado = estadoInicial.copyWith(
      zonasCompletadas: [zonasAmarillas.single.id, zonaAzul.id],
    );

    expect(estado.historialPuntuacion.map((entrada) => entrada.puesto), [1, 1]);
    expect(estado.historialPuntuacion.map((entrada) => entrada.puntos), [8, 7]);
    expect(estado.puntuacionTotal, 15);
  });
}
