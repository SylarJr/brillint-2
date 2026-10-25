import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'tablero_bloc.dart';

class MapaSelectorPage extends StatelessWidget {
  const MapaSelectorPage({super.key});

  static const _imagenes = [
    'img/mapa inicio.jpg',
    'img/mapa 1.jpg',
    'img/mapa 2.jpg',
    'img/mapa 3.jpg',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final columnas = constraints.maxWidth >= 1000
                ? 4
                : constraints.maxWidth >= 600
                ? 2
                : 1;
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(22, 24, 22, 32),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Row(
                        children: [
                          Icon(
                            Icons.grid_view_rounded,
                            color: Color(0xFF183F38),
                            size: 30,
                          ),
                          SizedBox(width: 10),
                          Text(
                            'BRILLANT',
                            style: TextStyle(
                              color: Color(0xFF183F38),
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 34),
                      const Text(
                        'Selecciona un mapa',
                        style: TextStyle(
                          color: Color(0xFF18332D),
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Elige un tablero para comenzar a jugar.',
                        style: TextStyle(
                          color: Color(0xFF61726C),
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 24),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: BoardState.mapas.length,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: columnas,
                          crossAxisSpacing: 18,
                          mainAxisSpacing: 18,
                          childAspectRatio: columnas == 1 ? 1.3 : 0.92,
                        ),
                        itemBuilder: (context, index) {
                          final mapa = BoardState.mapas[index];
                          return Card(
                            clipBehavior: Clip.antiAlias,
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                              side: const BorderSide(color: Color(0xFFDCE5DF)),
                            ),
                            child: InkWell(
                              key: ValueKey('mapa-card-$index'),
                              onTap: () => context.read<BoardBloc>().add(
                                BoardMapStarted(index),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Expanded(
                                    child: Image.asset(
                                      _imagenes[index],
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 13,
                                    ),
                                    child: Text(
                                      mapa.nombre,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        color: Color(0xFF183F38),
                                        fontSize: 15,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
