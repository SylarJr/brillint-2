import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_application_1/tipo.dart';

void main() {
  group('Tipos de región', () {
    test('azul solo permite repetir el mismo número', () {
      const tipo = TipoAzul();

      expect(tipo.puedeAgregarValor([], 3), isTrue);
      expect(tipo.puedeAgregarValor([3, 3], 3), isTrue);
      expect(tipo.puedeAgregarValor([3, 3], 4), isFalse);
    });

    test('rojo y amarillo no permiten repetir números', () {
      const tipoRojo = TipoRojo();
      const tipoAmarillo = TipoAmarillo();

      expect(tipoRojo.puedeAgregarValor([1, 2], 3), isTrue);
      expect(tipoRojo.puedeAgregarValor([1, 2], 2), isFalse);
      expect(tipoAmarillo.puedeAgregarValor([1, 2], 3), isTrue);
      expect(tipoAmarillo.puedeAgregarValor([1, 2], 1), isFalse);
    });

    test('morado permite como máximo dos números distintos', () {
      const tipo = TipoMorado();

      expect(tipo.puedeAgregarValor([], 1), isTrue);
      expect(tipo.puedeAgregarValor([1, 1], 2), isTrue);
      expect(tipo.puedeAgregarValor([1, 2, 1], 2), isTrue);
      expect(tipo.puedeAgregarValor([1, 2], 3), isFalse);
    });

    test('verde permite cualquier número', () {
      const tipo = TipoVerde();

      expect(tipo.puedeAgregarValor([1, 2, 3], 1), isTrue);
      expect(tipo.puedeAgregarValor([1, 2, 3], 9), isTrue);
    });

    test('cada tipo expone sus puntuaciones por puesto', () {
      const tipos = <Tipo, Map<int, int>>{
        TipoAzul(): {1: 7, 2: 5, 3: 3},
        TipoVerde(): {1: 4, 2: 3, 3: 2},
        TipoRojo(): {1: 6, 2: 4, 3: 2},
        TipoMorado(): {1: 6, 2: 4, 3: 2},
        TipoAmarillo(): {1: 8, 2: 6, 3: 4},
      };

      for (final entry in tipos.entries) {
        expect(entry.key.puntuaciones, entry.value);
        expect(entry.key.descripcion, isNotEmpty);
      }

      expect(const TipoAzul().color, Colors.blue);
    });
  });
}