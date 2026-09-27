/// Colores asignados a las regiones del tablero
enum RegionColor { rojo, morado, verde, azul, azulClaro, amarillo }

/// Representa una celda individual dentro del tablero 7x7
class BoardCell {
  final int row;
  final int col;
  final RegionColor region;
  final bool isMarked;
  int? value;

  BoardCell({
    required this.row,
    required this.col,
    required this.region,
    this.isMarked = false,
    this.value,
  });

  bool get isFilled => value != null;

  void clear() => value = null;
}

/// Tablero de 7x7 con restricción de edición por casillas marcadas
class BrilliantBoard {
  static const int boardSize = 7;
  static const Set<(int row, int col)> requiredMarkedPositions = {
    (0, 2),
    (1, 4),
    (3, 1),
    (3, 4),
    (5, 2),
    (6, 4),
  };

  late final List<List<BoardCell>> _grid;

  BrilliantBoard({
    required List<List<RegionColor>> regionLayout,
    Set<(int row, int col)> markedPositions = requiredMarkedPositions,
  }) {
    if (regionLayout.length != boardSize ||
        regionLayout.any((row) => row.length != boardSize)) {
      throw ArgumentError(
        'El diseño de regiones debe ser una matriz estricta de ${boardSize}x$boardSize.',
      );
    }

    _grid = List.generate(
      boardSize,
      (r) => List.generate(boardSize, (c) {
        final isMarked = markedPositions.contains((r, c));
        return BoardCell(
          row: r,
          col: c,
          region: regionLayout[r][c],
          isMarked: isMarked,
        );
      }, growable: false),
      growable: false,
    );
  }

  BoardCell getCell(int row, int col) {
    _validateCoordinates(row, col);
    return _grid[row][col];
  }

  bool isCellEditable(int row, int col) {
    _validateCoordinates(row, col);
    return _grid[row][col].isMarked;
  }

  void setCellValue(int row, int col, int? value) {
    _validateCoordinates(row, col);
    final cell = _grid[row][col];

    if (!cell.isMarked) {
      throw StateError(
        'Acción no permitida: La casilla ($row, $col) no está marcada para ingresar números.',
      );
    }

    cell.value = value;
  }

  List<BoardCell> get markedCells =>
      _grid.expand((row) => row).where((cell) => cell.isMarked).toList();

  List<BoardCell> get missingMarkedCells =>
      markedCells.where((cell) => !cell.isFilled).toList();

  bool get isCompleted {
    final marked = markedCells;
    if (marked.isEmpty) return false;
    return marked.every((cell) => cell.isFilled);
  }

  double get completionProgress {
    final marked = markedCells;
    if (marked.isEmpty) return 0.0;
    final filled = marked.where((c) => c.isFilled).length;
    return filled / marked.length;
  }

  String get statusMessage {
    if (isCompleted) return 'Iniciar juego';

    final missing = missingMarkedCells
        .map((cell) => 'Fila ${cell.row + 1}, Columna ${cell.col + 1}')
        .join('; ');
    return 'Faltan casillas: $missing';
  }

  @override
  String toString() {
    return List.generate(boardSize, (row) {
      final cells = _grid[row].map((cell) {
        final content = cell.isFilled
            ? cell.value.toString()
            : cell.isMarked
            ? _regionLabel(cell.region)
            : '';
        return '|${content.padLeft(2).padRight(2)}';
      }).join();
      return '${row + 1} $cells|';
    }).join('\n');
  }

  String _regionLabel(RegionColor region) => switch (region) {
    RegionColor.rojo => 'RO',
    RegionColor.morado => 'MO',
    RegionColor.verde => 'VE',
    RegionColor.azul => 'AZ',
    RegionColor.azulClaro => 'AC',
    RegionColor.amarillo => 'AM',
  };

  void _validateCoordinates(int row, int col) {
    if (row < 0 || row >= boardSize || col < 0 || col >= boardSize) {
      throw RangeError('Coordenadas fuera de rango: ($row, $col).');
    }
  }
}
