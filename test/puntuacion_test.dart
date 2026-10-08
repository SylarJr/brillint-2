import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_application_1/tablero_bloc.dart';
import 'package:flutter_application_1/tipo.dart';

void main() {
  test('todos los cuadros amarillos forman una sola zona puntuable', () {
    final zonasAmarillas = BoardState.zonas
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
    final zonaAzul = BoardState.zonas.firstWhere(
      (zona) => zona.tipo is TipoAzul,
    );
    expect(zonasAmarillas, hasLength(1));
    expect(zonasAmarillas.single.casillas, casillasAmarillas);

    final estado = BoardState.inicial().copyWith(
      zonasCompletadas: [
        zonasAmarillas.single.id,
        zonaAzul.id,
      ],
    );

    expect(estado.historialPuntuacion.map((entrada) => entrada.puesto), [
      1,
      1,
    ]);
    expect(estado.historialPuntuacion.map((entrada) => entrada.puntos), [
      8,
      7,
    ]);
    expect(estado.puntuacionTotal, 15);
  });
}
