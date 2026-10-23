import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_application_1/mapas.dart';
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
        'PPPWGGG',
        'PYBBBYG',
        'PRRBRRG',
        'RRRYRRR',
        'GRRBRRP',
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
      [
        'YGBPPPY',
        'GGBBPPG',
        'GRRBPGG',
        'GRPYGGG',
        'GRPPRRB',
        'RRPRRBB',
        'YPPRRBY',
      ],
    ];
    const mapas = [mapa1, mapa2, mapa3, mapaInicial];

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
