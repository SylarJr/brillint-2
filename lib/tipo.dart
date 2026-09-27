import 'package:flutter/material.dart';

abstract class Tipo {
	const Tipo({
		required this.color,
		required this.descripcion,
		this.puntuaciones = const {},
	});

	final Color color;
	final String descripcion;
	final Map<int, int> puntuaciones;

	bool puedeAgregarValor(List<int> actuales, int posible);
}


class TipoAzul extends Tipo {
	const TipoAzul({super.puntuaciones = const {1: 7, 2: 5, 3: 3}})
			: super(
					color: Colors.blue,
					descripcion: 'Todos los números de la zona deben ser iguales.',
				);

	@override
	bool puedeAgregarValor(List<int> actuales, int posible) =>
			actuales.isEmpty || actuales.every((valor) => valor == posible);
}

class TipoRojo extends Tipo {
	const TipoRojo({super.puntuaciones = const {1: 6, 2: 4, 3: 2}})
			: super(
					color: Colors.red,
					descripcion: 'Todos los números de la zona deben ser distintos.',
				);

	@override
	bool puedeAgregarValor(List<int> actuales, int posible) =>
			!actuales.contains(posible);
}

class TipoMorado extends Tipo {
	const TipoMorado({super.puntuaciones = const {1: 6, 2: 4, 3: 2}})
			: super(
					color: Colors.purple,
					descripcion: 'La zona puede usar como máximo dos números distintos.',
				);

	@override
	bool puedeAgregarValor(List<int> actuales, int posible) =>
			{...actuales, posible}.length <= 2;
}

class TipoAmarillo extends Tipo {
	const TipoAmarillo({super.puntuaciones = const {1: 8, 2: 6, 3: 4}})
			: super(
					color: Colors.yellow,
					descripcion: 'Todos los números de la zona deben ser distintos.',
				);

	@override
	bool puedeAgregarValor(List<int> actuales, int posible) =>
			!actuales.contains(posible);
}

class TipoVerde extends Tipo {
	const TipoVerde({super.puntuaciones = const {1: 4, 2: 3, 3: 2}})
			: super(
					color: Colors.green,
					descripcion: 'Se puede usar cualquier número.',
				);

	@override
	bool puedeAgregarValor(List<int> actuales, int posible) => true;

	
}



