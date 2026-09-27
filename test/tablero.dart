import 'package:flutter_test/flutter_test.dart';

import '../lib/tablero.dart';

void printBoardTestResult(String testName, BrilliantBoard board) {
  print('\n=== $testName ===');
  print(board);
  print('Progreso: ${(board.completionProgress * 100).toStringAsFixed(0)}%');
  print('Estado: ${board.statusMessage}');
}

void main() {
  group('BrilliantBoard - Pruebas de casillas marcadas', () {
    late List<List<RegionColor>> sampleLayout;
    late Set<(int, int)> markedCoordinates;

    setUp(() {
      sampleLayout = List.generate(
        7,
        (_) => List.generate(7, (_) => RegionColor.verde),
      );

      sampleLayout[0][2] = RegionColor.azulClaro;
      sampleLayout[1][4] = RegionColor.morado;
      sampleLayout[3][1] = RegionColor.rojo;
      sampleLayout[3][4] = RegionColor.verde;
      sampleLayout[5][2] = RegionColor.morado;
      sampleLayout[6][4] = RegionColor.rojo;
      markedCoordinates = BrilliantBoard.requiredMarkedPositions;
    });

    test('Permite ingresar números en casillas marcadas', () {
      final board = BrilliantBoard(
        regionLayout: sampleLayout,
        markedPositions: markedCoordinates,
      );

      expect(() => board.setCellValue(0, 2, 8), returnsNormally);
      expect(board.getCell(0, 2).value, equals(8));
      expect(board.getCell(0, 2).isFilled, isTrue);
      printBoardTestResult('Casilla marcada editable', board);
    });

    test(
      'Lanza StateError si se intenta escribir en una casilla no marcada',
      () {
        final board = BrilliantBoard(
          regionLayout: sampleLayout,
          markedPositions: markedCoordinates,
        );

        expect(board.isCellEditable(0, 0), isFalse);
        expect(() => board.setCellValue(0, 0, 5), throwsA(isA<StateError>()));
        expect(board.getCell(0, 0).value, isNull);
        printBoardTestResult('Casilla no marcada protegida', board);
      },
    );

    test('Calcula el progreso y valida que no esté completado al inicio', () {
      final board = BrilliantBoard(
        regionLayout: sampleLayout,
        markedPositions: markedCoordinates,
      );

      expect(board.isCompleted, isFalse);
      expect(board.completionProgress, equals(0.0));

      // Asignar 3 de las 6 casillas marcadas (50%)
      board.setCellValue(0, 2, 4);
      board.setCellValue(1, 4, 7);
      board.setCellValue(3, 1, 1);

      expect(board.completionProgress, equals(0.5));
      expect(board.isCompleted, isFalse);
      printBoardTestResult('Progreso parcial', board);
    });

    test('Indica la casilla faltante y no permite iniciar el juego', () {
      final board = BrilliantBoard(
        regionLayout: sampleLayout,
        markedPositions: markedCoordinates,
      );

      for (final (r, c) in markedCoordinates) {
        if ((r, c) != (6, 4)) board.setCellValue(r, c, 9);
      }

      expect(board.missingMarkedCells, hasLength(1));
      expect(board.statusMessage, 'Faltan casillas: Fila 7, Columna 5');
      expect(board.isCompleted, isFalse);
      printBoardTestResult('Una casilla faltante', board);
    });

    test(
      'Imprime las siete filas y muestra solo los puntos requeridos vacíos',
      () {
        final board = BrilliantBoard(
          regionLayout: sampleLayout,
          markedPositions: markedCoordinates,
        );
        final printedBoard = board.toString();

        expect(printedBoard.split('\n'), hasLength(7));
        expect(printedBoard, contains('AC'));
        expect(printedBoard, contains('MO'));
        expect(printedBoard, contains('RO'));
        expect(printedBoard, contains('VE'));
        printBoardTestResult('Tablero vacío de siete filas', board);
      },
    );

    test('El tablero pasa a isCompleted = true al rellenar todas las casillas marcadas', () {
      final board = BrilliantBoard(
        regionLayout: sampleLayout,
        markedPositions: markedCoordinates,
      );

      for (final (r, c) in markedCoordinates) {
        board.setCellValue(r, c, 9);
      }

      expect(board.completionProgress, equals(1.0));
      expect(board.isCompleted, isTrue);
      expect(board.statusMessage, 'Iniciar juego');
      printBoardTestResult('Todas las casillas completas', board);
    });
  });
}
