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

    test(
      'blanco solo permite repetir el mismo número en todas sus casillas',
      () {
        const tipo = TipoBlanco();

        expect(tipo.puedeAgregarValor([], 3), isTrue);
        expect(tipo.puedeAgregarValor([3, 3], 3), isTrue);
        expect(tipo.puedeAgregarValor([3], 4), isFalse);
      },
    );

    test('naranja superior solo permite números del 4 al 6', () {
      const tipo = TipoNaranjaSuperior();

      expect(tipo.puedeAgregarValor([], 3), isFalse);
      expect(tipo.puedeAgregarValor([], 4), isTrue);
      expect(tipo.puedeAgregarValor([5], 6), isTrue);
      expect(tipo.puedeAgregarValor([], 7), isFalse);
    });

    test('naranja inferior solo permite números del 1 al 3', () {
      const tipo = TipoNaranjaInferior();

      expect(tipo.puedeAgregarValor([], 0), isFalse);
      expect(tipo.puedeAgregarValor([], 1), isTrue);
      expect(tipo.puedeAgregarValor([2], 3), isTrue);
      expect(tipo.puedeAgregarValor([], 4), isFalse);
    });

    test('cada tipo expone sus puntuaciones por puesto', () {
      const tipos = <Tipo, Map<int, int>>{
        TipoAzul(): {1: 7, 2: 5, 3: 3},
        TipoVerde(): {1: 4, 2: 3, 3: 2},
        TipoRojo(): {1: 6, 2: 4, 3: 2},
        TipoMorado(): {1: 6, 2: 4, 3: 2},
        TipoAmarillo(): {1: 8, 2: 6, 3: 4},
        TipoBlanco(): {},
        TipoNaranjaSuperior(): {},
        TipoNaranjaInferior(): {},
      };

      for (final entry in tipos.entries) {
        expect(entry.key.puntuaciones, entry.value);
        expect(entry.key.descripcion, isNotEmpty);
      }

      expect(const TipoAzul().color, Colors.lightBlue);
      expect(const TipoRojo().color, Colors.red);
      expect(const TipoBlanco().color, const Color(0xFFE0E0E0));
    });
  });
}
