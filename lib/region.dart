import 'tipo.dart';

abstract class Region {
  const Region({required this.tipo});

  final Tipo tipo;
}

class Coordenada {
  final int x;
  final int y;

  const Coordenada(this.x, this.y);
}
