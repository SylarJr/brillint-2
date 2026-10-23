import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_application_1/mapas.dart';
import 'package:flutter_application_1/tablero_bloc.dart';
import 'package:flutter_application_1/tipo.dart';

String _simbolo(Tipo tipo) {
  if (tipo is TipoNaranjaSuperior || tipo is TipoNaranjaInferior) return 'O';
  if (tipo is TipoMorado) return 'P';
  if (tipo is TipoVerde) return 'G';
  if (tipo is TipoAmarillo) return 'Y';
  if (tipo is TipoAzul) return 'B';
  if (tipo is TipoRojo) return 'R';
  if (tipo is TipoBlanco) return 'W';
  throw StateError('Tipo de color no esperado: ${tipo.runtimeType}');
}

void main() {
  test('los mapas corresponden a las matrices indicadas', () {
    const mapasEsperados = [
      [
        'YGBPPPY',
        'GGBBPPG',
        'GRRBPGG',
        'GRPYGGG',
        'GRPPRRB',
        'RRPRRBB',
        'YPPRRBY',
      ],
      [
        'PPPWGGG',
        'PYBBBYG',
        'PRRBBRG',
        'RRRYRRR',
        'GRBBRRP',
        'GYBBBYP',
        'GGGWPPP',
      ],
      [
        'YYPWPYY',
        'YYPPPYW',
        'RRRPRRR',
        'RRRWRRR',
        'GBBBBBG',
        'GGGGGGG',
        'PPPWPPP',
      ],
      [
        'OOOOOOO',
        'YRBGBRY',
        'RRPPPRR',
        'YGBPBGY',
        'RRPPPRR',
        'YRBGBRY',
        'OOOOOOO',
      ],
    ];
    const mapas = [mapaInicial, mapa1, mapa2, mapa3];

    expect(mapas, hasLength(4));
    for (var mapaIndex = 0; mapaIndex < mapas.length; mapaIndex++) {
      final mapa = mapas[mapaIndex];
      expect(mapa.matriz, hasLength(7), reason: mapa.nombre);
      expect(
        mapa.matriz.map((fila) => fila.length),
        everyElement(7),
        reason: mapa.nombre,
      );
      expect(
        mapa.matriz.map((fila) => fila.map(_simbolo).join()).toList(),
        mapasEsperados[mapaIndex],
        reason: mapa.nombre,
      );
    }
  });

  test('el mapa inicial es la primera opción y se carga al empezar', () {
    expect(BoardState.mapas.first, mapaInicial);
    final estadoInicial = BoardState.inicial();
    expect(estadoInicial.mapaSeleccionado, 0);
    expect(estadoInicial.matriz, mapaInicial.matriz);
  });

  test('el mapa 1 usa sus puntos iniciales sin cambiar los otros mapas', () {
    final estadoMapa1 = BoardState.inicial(mapaSeleccionado: 1);

    expect(estadoMapa1.matriz, mapa1.matriz);
    expect(estadoMapa1.casillasMarcadas, {
      (0, 4),
      (2, 0),
      (3, 2),
      (4, 5),
      (5, 1),
      (6, 4),
    });
    expect(BoardState.inicial().casillasMarcadas, BoardState.casillasObjetivo);
    expect(
      BoardState.inicial(mapaSeleccionado: 2).casillasMarcadas,
      BoardState.casillasObjetivo,
    );
  });

  test('el tercer mapa separa las restricciones naranja por filas', () {
    expect(
      mapa3.matriz.first.every((tipo) => tipo is TipoNaranjaSuperior),
      isTrue,
    );
    expect(
      mapa3.matriz.last.every((tipo) => tipo is TipoNaranjaInferior),
      isTrue,
    );
    expect(mapa3.matriz.first.first.puedeAgregarValor([], 4), isTrue);
    expect(mapa3.matriz.first.first.puedeAgregarValor([], 3), isFalse);
    expect(mapa3.matriz.last.first.puedeAgregarValor([], 3), isTrue);
    expect(mapa3.matriz.last.first.puedeAgregarValor([], 4), isFalse);
  });
}
