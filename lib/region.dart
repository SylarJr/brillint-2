import 'tipo.dart';

abstract class Region {
  final Tipo tipo;
}

class Coordenada{
  final int x;
  final int y;

  const Coordenada(this.x, this.y);
}
