import 'package:flutter/material.dart';

import 'multiplayer_service.dart';
import 'room_notice_banner.dart';

class LobbyPage extends StatefulWidget {
  const LobbyPage({
    super.key,
    required this.multiplayer,
    required this.onLeave,
  });

  final MultiplayerService multiplayer;
  final VoidCallback onLeave;

  @override
  State<LobbyPage> createState() => _LobbyPageState();
}

class _LobbyPageState extends State<LobbyPage> {
  bool _sendingReady = false;

  Future<void> _toggleReady(bool ready) async {
    if (_sendingReady) return;
    setState(() => _sendingReady = true);
    try {
      await widget.multiplayer.setReady(ready);
    } catch (_) {
      // The service exposes the server error in the lobby.
    } finally {
      if (mounted) setState(() => _sendingReady = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.multiplayer,
      builder: (context, _) {
        final service = widget.multiplayer;
        final compact = MediaQuery.sizeOf(context).width < 360;
        final readyCount = service.players
            .where((player) => player.ready)
            .length;
        final isReady = service.players
            .where((player) => player.id == service.playerId)
            .any((player) => player.ready);
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
                  padding: EdgeInsets.all(compact ? 14 : 24),
                  children: [
                    const Icon(
                      Icons.groups_rounded,
                      size: 52,
                      color: Color(0xFF183F38),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Invita a tus amigos',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFF18332D),
                        fontSize: compact ? 23 : 26,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Comparte este código con tus amigos. Todos deben marcarse listos para pasar a preparar el tablero.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Color(0xFF61726C), height: 1.5),
                    ),
                    if (service.roomNotice case final message?) ...[
                      const SizedBox(height: 12),
                      RoomNoticeBanner(message: message),
                    ],
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
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                player.ready
                                    ? Icons.check_circle
                                    : Icons.account_circle_outlined,
                                color: player.ready
                                    ? const Color(0xFF16834A)
                                    : const Color(0xFF61726C),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  player.name,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                player.ready ? 'LISTO' : 'ESPERANDO',
                                style: const TextStyle(fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(height: 12),
                    Text(
                      '$readyCount de ${service.players.length} jugadores listos',
                      textAlign: TextAlign.center,
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
          bottomNavigationBar: SafeArea(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                compact ? 14 : 24,
                8,
                compact ? 14 : 24,
                compact ? 12 : 20,
              ),
              child: FilledButton(
                key: const ValueKey('boton-listo-para-empezar'),
                onPressed: _sendingReady ? null : () => _toggleReady(!isReady),
                child: Text(
                  _sendingReady
                      ? 'Actualizando...'
                      : isReady
                      ? 'Cancelar listo'
                      : 'Listo para empezar',
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
