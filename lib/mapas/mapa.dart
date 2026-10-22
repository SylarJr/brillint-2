import '../tipo.dart';

class MapaTablero {
  const MapaTablero({required this.nombre, required this.matriz});

  final String nombre;
  final List<List<Tipo>> matriz;
}
