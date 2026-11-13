import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'multiplayer_service.dart';
import 'tablero_bloc.dart';

class MapaSelectorPage extends StatefulWidget {
  const MapaSelectorPage({super.key, required this.onLogout});

  final Future<void> Function() onLogout;

  @override
  State<MapaSelectorPage> createState() => _MapaSelectorPageState();
}

class _MapaSelectorPageState extends State<MapaSelectorPage> {
  static const _imagenes = [
    'img/mapa inicio.jpg',
    'img/mapa 1.jpg',
    'img/mapa 2.jpg',
    'img/mapa 3.jpg',
  ];

  final _nombreController = TextEditingController();
  final _codigoController = TextEditingController();
  bool _enviando = false;
  bool _cerrandoSesion = false;

  @override
  void dispose() {
    _nombreController.dispose();
    _codigoController.dispose();
    super.dispose();
  }

  Future<void> _crearSala(int mapId) async {
    if (_enviando) return;
    setState(() => _enviando = true);
    final service = context.read<MultiplayerService>();
    try {
      await service.createRoom(
        mapId: mapId,
        playerName: _nombreController.text.trim().isEmpty
            ? 'Jugador'
            : _nombreController.text.trim(),
      );
      if (!mounted) return;
      context.read<BoardBloc>().add(BoardMapStarted(mapId));
    } catch (_) {
      // The service exposes the connection or server error below the form.
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  Future<void> _unirse() async {
    if (_enviando || _codigoController.text.trim().isEmpty) return;
    setState(() => _enviando = true);
    final service = context.read<MultiplayerService>();
    try {
      await service.joinRoom(
        code: _codigoController.text,
        playerName: _nombreController.text.trim().isEmpty
            ? 'Jugador'
            : _nombreController.text.trim(),
      );
      if (!mounted) return;
      context.read<BoardBloc>().add(BoardMapStarted(service.mapId ?? 0));
    } catch (_) {
      // The service exposes the connection or server error below the form.
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  Future<void> _cerrarSesion() async {
    if (_cerrandoSesion) return;
    setState(() => _cerrandoSesion = true);
    try {
      await widget.onLogout();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo cerrar sesión: $error')),
      );
    } finally {
      if (mounted) setState(() => _cerrandoSesion = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final service = context.watch<MultiplayerService>();
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
                      Row(
                        children: [
                          const Icon(
                            Icons.grid_view_rounded,
                            color: Color(0xFF183F38),
                            size: 30,
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            'BRILLANT',
                            style: TextStyle(
                              color: Color(0xFF183F38),
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.5,
                            ),
                          ),
                          const Spacer(),
                          TextButton.icon(
                            key: const ValueKey('cerrar-sesion'),
                            onPressed: _cerrandoSesion ? null : _cerrarSesion,
                            icon: _cerrandoSesion
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.logout),
                            label: const Text('Cerrar sesión'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 34),
                      const Text(
                        'Juega con otras personas',
                        style: TextStyle(
                          color: Color(0xFF18332D),
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Crea una sala al elegir un tablero o únete con un código de invitación.',
                        style: TextStyle(
                          color: Color(0xFF61726C),
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        key: const ValueKey('nombre-jugador'),
                        controller: _nombreController,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          labelText: 'Tu nombre en la partida',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              key: const ValueKey('codigo-sala'),
                              controller: _codigoController,
                              textCapitalization: TextCapitalization.characters,
                              decoration: const InputDecoration(
                                labelText: 'Código de invitación',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          FilledButton(
                            key: const ValueKey('unirse-sala'),
                            onPressed: _enviando ? null : _unirse,
                            child: const Text('Unirse'),
                          ),
                        ],
                      ),
                      if (service.errorMessage case final message?) ...[
                        const SizedBox(height: 12),
                        Text(
                          message,
                          key: const ValueKey('error-multijugador'),
                          style: const TextStyle(color: Colors.red),
                        ),
                      ],
                      const SizedBox(height: 28),
                      const Text(
                        'CREAR UNA SALA',
                        style: TextStyle(
                          color: Color(0xFF52635D),
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 14),
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
                              onTap: _enviando ? null : () => _crearSala(index),
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
                                      _enviando ? 'Conectando...' : mapa.nombre,
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
