import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'tablero_bloc.dart';
import 'tipo.dart';

class TableroPage extends StatelessWidget {
  const TableroPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 18, 22, 24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 540),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: const Color(0xFF183F38),
                          borderRadius: BorderRadius.circular(11),
                        ),
                        child: const Icon(
                          Icons.grid_view_rounded,
                          color: Colors.white,
                          size: 21,
                        ),
                      ),
                      const SizedBox(width: 11),
                      const Text(
                        'BRILLANT',
                        style: TextStyle(
                          color: Color(0xFF183F38),
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const Spacer(),
                      const Text(
                        '7 × 7',
                        style: TextStyle(
                          color: Color(0xFF61726C),
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  const Text(
                    'Mapa de colores',
                    style: TextStyle(
                      color: Color(0xFF18332D),
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      height: 1.1,
                    ),
                  ),
                  BlocBuilder<BoardBloc, BoardState>(
                    builder: (context, state) => state.listoParaJugar
                        ? Container(
                            key: const ValueKey('banner-listo'),
                            margin: const EdgeInsets.only(top: 16),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 15,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE0F0E8),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'Listo para jugar',
                              style: TextStyle(
                                color: Color(0xFF183F38),
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                  const SizedBox(height: 20),
                  const _MatrizTablero(),
                  const SizedBox(height: 16),
                  const _PanelNumeros(),
                  const SizedBox(height: 18),
                  BlocBuilder<BoardBloc, BoardState>(
                    builder: (context, state) {
                      final casilla = state.casillaSeleccionada;
                      final tipo = casilla == null
                          ? null
                          : state.matriz[casilla.$1][casilla.$2];
                      return Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: tipo?.color ?? const Color(0xFF61726C),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 9),
                          Text(
                            casilla == null
                                ? '${state.asignaciones.length} DE 6 NÚMEROS COLOCADOS'
                                : 'FILA ${casilla.$1 + 1}  /  COLUMNA ${casilla.$2 + 1}',
                            style: const TextStyle(
                              color: Color(0xFF52635D),
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            tipo == null ? '' : _nombreTipo(tipo),
                            style: const TextStyle(
                              color: Color(0xFF18332D),
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 27),
                  const _Leyenda(),
                  const SizedBox(height: 22),
                  BlocBuilder<BoardBloc, BoardState>(
                    builder: (context, state) => FilledButton(
                      key: const ValueKey('boton-listo'),
                      onPressed: state.completo && !state.listoParaJugar
                          ? () => context.read<BoardBloc>().add(
                              const BoardReadyPressed(),
                            )
                          : null,
                      child: const Text('Listo'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MatrizTablero extends StatelessWidget {
  const _MatrizTablero();

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: BlocBuilder<BoardBloc, BoardState>(
        builder: (context, state) => GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 49,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            crossAxisSpacing: 7,
            mainAxisSpacing: 7,
          ),
          itemBuilder: (context, index) {
            final fila = index ~/ 7;
            final columna = index % 7;
            final tipo = state.matriz[fila][columna];
            final marcada = state.esCasillaMarcada(fila, columna);
            final numero = state.numeroEn(fila, columna);
            final seleccionada = state.casillaSeleccionada == (fila, columna);

            return Semantics(
              label:
                  'Fila ${fila + 1}, columna ${columna + 1}, ${tipo.descripcion}',
              button: true,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                decoration: BoxDecoration(
                  color: tipo.color,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: seleccionada
                        ? const Color(0xFF183F38)
                        : marcada
                        ? const Color(0xFF183F38)
                        : Colors.white,
                    width: seleccionada
                        ? 3
                        : marcada
                        ? 2
                        : 1.5,
                  ),
                  boxShadow: seleccionada
                      ? const [
                          BoxShadow(
                            color: Color(0x33183F38),
                            blurRadius: 8,
                            offset: Offset(0, 3),
                          ),
                        ]
                      : null,
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    key: ValueKey('celda-$fila-$columna'),
                    borderRadius: BorderRadius.circular(8),
                    onTap: marcada
                        ? () => context.read<BoardBloc>().add(
                            BoardCellSelected(fila, columna),
                          )
                        : null,
                    child: Center(
                      child: numero == null
                          ? marcada
                                ? const Icon(
                                    Icons.add_rounded,
                                    color: Color(0x99183F38),
                                    size: 17,
                                  )
                                : const SizedBox.shrink()
                          : Text(
                              '$numero',
                              style: const TextStyle(
                                color: Color(0xFF18332D),
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                    ),
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

class _PanelNumeros extends StatelessWidget {
  const _PanelNumeros();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BoardBloc, BoardState>(
      builder: (context, state) {
        final casilla = state.casillaSeleccionada;
        if (casilla == null || state.numeroEn(casilla.$1, casilla.$2) != null) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'ELIGE UN NÚMERO',
              style: TextStyle(
                color: Color(0xFF52635D),
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.9,
              ),
            ),
            const SizedBox(height: 9),
            Row(
              children: BoardState.numerosPermitidos.map((numero) {
                final disponible = state.numerosDisponibles.contains(numero);
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: OutlinedButton(
                      key: ValueKey('numero-$numero'),
                      onPressed: disponible
                          ? () => context.read<BoardBloc>().add(
                              BoardNumberAssigned(numero),
                            )
                          : null,
                      child: Text('$numero'),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        );
      },
    );
  }
}

class _Leyenda extends StatelessWidget {
  const _Leyenda();

  @override
  Widget build(BuildContext context) {
    const tipos = [
      TipoAmarillo(),
      TipoVerde(),
      TipoAzul(),
      TipoMorado(),
      TipoNaranja(),
    ];

    return Wrap(
      spacing: 16,
      runSpacing: 12,
      children: tipos.map((tipo) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 9,
              height: 9,
              decoration: BoxDecoration(
                color: tipo.color,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              _nombreTipo(tipo),
              style: const TextStyle(
                color: Color(0xFF52635D),
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
              ),
            ),
          ],
        );
      }).toList(),
    );
  }
}

String _nombreTipo(Tipo tipo) =>
    tipo.runtimeType.toString().replaceFirst('Tipo', '').toUpperCase();
