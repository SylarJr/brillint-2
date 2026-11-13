import 'package:flutter/material.dart';

import 'multiplayer_service.dart';

class LobbyPage extends StatefulWidget {
  const LobbyPage({
    super.key,
    required this.multiplayer,
    required this.onLeave,
    required this.onPrepareBoard,
  });

  final MultiplayerService multiplayer;
  final VoidCallback onLeave;
  final VoidCallback onPrepareBoard;

  @override
  State<LobbyPage> createState() => _LobbyPageState();
}

class _LobbyPageState extends State<LobbyPage> {
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.multiplayer,
      builder: (context, _) {
        final service = widget.multiplayer;
        final readyCount = service.players
            .where((player) => player.ready)
            .length;
        return Scaffold(
          appBar: AppBar(
            leading: IconButton(
              key: const ValueKey('salir-lobby'),
              onPressed: widget.onLeave,
              icon: const Icon(Icons.arrow_back_rounded),
            ),
            title: const Text('Lobby'),
          ),
          body: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    const Icon(
                      Icons.groups_rounded,
                      size: 52,
                      color: Color(0xFF183F38),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Invita a tus amigos',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFF18332D),
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Comparte este código con tus amigos. Antes de empezar, cada jugador preparará su tablero con 6 números.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Color(0xFF61726C), height: 1.5),
                    ),
                    const SizedBox(height: 22),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            const Text('CÓDIGO DE INVITACIÓN'),
                            const SizedBox(height: 8),
                            SelectableText(
                              service.roomCode ?? 'Conectando...',
                              key: const ValueKey('codigo-invitacion'),
                              style: const TextStyle(
                                fontSize: 34,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 4,
                                color: Color(0xFF183F38),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'JUGADORES (${service.players.length})',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    for (final player in service.players)
                      Card(
                        child: ListTile(
                          leading: Icon(
                            player.ready
                                ? Icons.check_circle
                                : Icons.account_circle_outlined,
                            color: player.ready
                                ? const Color(0xFF16834A)
                                : const Color(0xFF61726C),
                          ),
                          title: Text(player.name),
                          trailing: Text(player.ready ? 'LISTO' : 'ESPERANDO'),
                        ),
                      ),
                    const SizedBox(height: 12),
                    Text(
                      '$readyCount de ${service.players.length} jugadores listos',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      key: const ValueKey('boton-preparar-tablero'),
                      onPressed: widget.onPrepareBoard,
                      child: const Text('Preparar tablero'),
                    ),
                    if (service.errorMessage case final message?) ...[
                      const SizedBox(height: 12),
                      Text(
                        message,
                        key: const ValueKey('error-multijugador'),
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
