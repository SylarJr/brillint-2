import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_application_1/tablero_bloc.dart';
import 'package:flutter_application_1/tipo.dart';

void main() {
  test('puntúa las zonas por orden de finalización de cada color', () {
    final zonasAmarillas = BoardState.zonas
        .where((zona) => zona.tipo is TipoAmarillo)
        .take(4)
        .toList();
    final zonaAzul = BoardState.zonas.firstWhere(
      (zona) => zona.tipo is TipoAzul,
    );
    expect(zonasAmarillas, hasLength(4));

    final estado = BoardState.inicial().copyWith(
      zonasCompletadas: [
        zonasAmarillas[0].id,
        zonaAzul.id,
        zonasAmarillas[1].id,
        zonasAmarillas[2].id,
        zonasAmarillas[3].id,
      ],
    );

    expect(estado.historialPuntuacion.map((entrada) => entrada.puesto), [
      1,
      1,
      2,
      3,
      4,
    ]);
    expect(estado.historialPuntuacion.map((entrada) => entrada.puntos), [
      8,
      7,
      6,
      4,
      0,
    ]);
    expect(estado.puntuacionTotal, 25);
  });
}
