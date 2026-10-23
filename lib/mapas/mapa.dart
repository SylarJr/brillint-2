import '../tipo.dart';

const puntosInicialesPredeterminados = <(int, int)>{
  (0, 2),
  (1, 5),
  (3, 1),
  (3, 4),
  (5, 2),
  (6, 4),
};

class MapaTablero {
  const MapaTablero({
    required this.nombre,
    required this.matriz,
    this.puntosIniciales = puntosInicialesPredeterminados,
  });

  final String nombre;
  final List<List<Tipo>> matriz;
  final Set<(int, int)> puntosIniciales;
}
