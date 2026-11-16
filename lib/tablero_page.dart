import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'multiplayer_service.dart';
import 'room_notice_banner.dart';
import 'tablero_bloc.dart';
import 'tipo.dart';

class TableroPage extends StatelessWidget {
  const TableroPage({super.key, this.onBackToLobby});

  final VoidCallback? onBackToLobby;

  @override
  Widget build(BuildContext context) {
    final multiplayer = context.watch<MultiplayerService>();
    final viewportWidth = MediaQuery.sizeOf(context).width;
    final compact = viewportWidth < 360;
    final horizontalPadding = compact
        ? 10.0
        : viewportWidth < 600
        ? 16.0
        : 22.0;
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            compact ? 12 : 18,
            horizontalPadding,
            24,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1000),
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
                      if (!compact) ...[
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
                      ],
                      const Spacer(),
                      BlocBuilder<BoardBloc, BoardState>(
                        builder: (context, state) {
                          if (onBackToLobby != null &&
                              !multiplayer.gameStarted &&
                              !state.listoParaJugar) {
                            return _buildExitButton(
                              compact: compact || viewportWidth < 600,
                              key: const ValueKey('volver-lobby'),
                              label: 'Volver al lobby',
                              onPressed: onBackToLobby!,
                            );
                          }
                          if (multiplayer.gameStarted) {
                            return _buildExitButton(
                              compact: compact || viewportWidth < 600,
                              key: const ValueKey('salir-partida'),
                              label: 'Salir de la partida',
                              onPressed: () => _confirmLeaveGame(context),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ],
                  ),
                  SizedBox(height: compact ? 18 : 30),
                  if (multiplayer.gameStarted)
                    _PanelPuntuacion(compact: viewportWidth < 800),
                  if (multiplayer.roomNotice case final message?) ...[
                    const SizedBox(height: 12),
                    RoomNoticeBanner(message: message),
                  ],
                  const SizedBox(height: 20),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      const tablero = _ContenidoTablero();
                      const panelLateral = _PanelLateral();
                      if (constraints.maxWidth >= 800) {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Expanded(child: tablero),
                            const SizedBox(width: 24),
                            const SizedBox(width: 270, child: panelLateral),
                          ],
                        );
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const _MultiplayerErrorBanner(),
                          const _PanelTurno(),
                          const SizedBox(height: 18),
                          tablero,
                          if (multiplayer.gameStarted) ...[
                            const SizedBox(height: 24),
                            const _PanelReglasMapa(collapsible: true),
                          ],
                        ],
                      );
                    },
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

Future<void> _confirmLeaveGame(BuildContext context) async {
  final service = context.read<MultiplayerService>();
  final shouldLeave = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Salir de la partida'),
      content: const Text('Si sales, el otro jugador podría ganar la partida.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Seguir jugando'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Salir'),
        ),
      ],
    ),
  );
  if (shouldLeave != true || !context.mounted) return;
  try {
    await service.leaveRoom();
  } catch (error) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('No se pudo salir de la partida: $error')),
    );
  }
}

Widget _buildExitButton({
  required bool compact,
  required Key key,
  required String label,
  required VoidCallback onPressed,
}) {
  if (compact) {
    return IconButton(
      key: key,
      tooltip: label,
      onPressed: onPressed,
      icon: const Icon(Icons.arrow_back_rounded),
    );
  }
  return OutlinedButton.icon(
    key: key,
    onPressed: onPressed,
    icon: const Icon(Icons.arrow_back_rounded),
    label: Text(label),
  );
}

String _nombreTipo(Tipo tipo) => switch (tipo) {
  TipoBlanco() => 'BLANCO',
  TipoNaranjaSuperior() => 'NARANJA 4-6',
  TipoNaranjaInferior() => 'NARANJA 1-3',
  _ => tipo.runtimeType.toString().replaceFirst('Tipo', '').toUpperCase(),
};

class _ContenidoTablero extends StatelessWidget {
  const _ContenidoTablero();

  @override
  Widget build(BuildContext context) {
    final service = context.watch<MultiplayerService>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        BlocBuilder<BoardBloc, BoardState>(
          builder: (context, state) => _ReadyConfirmationBanner(
            visible: state.listoParaJugar && !service.gameStarted,
          ),
        ),
        if (service.roomCode != null && !service.gameStarted)
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Text(
              'Sala ${service.roomCode} · ${service.players.where((player) => player.ready).length} de ${service.players.length} jugadores listos',
              key: const ValueKey('estado-preparacion-sala'),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF52635D),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        const SizedBox(height: 20),
        const _MatrizTablero(),
        const SizedBox(height: 16),
        const _PanelNumeros(),
        BlocBuilder<BoardBloc, BoardState>(
          builder: (context, state) {
            if (!state.preparacionCompleta || state.listoParaJugar) {
              return const SizedBox.shrink();
            }
            final readyButton = FilledButton.icon(
              key: const ValueKey('boton-estoy-listo'),
              onPressed: state.enviandoListo
                  ? null
                  : () => context.read<BoardBloc>().add(
                      const BoardReadyPressed(),
                    ),
              icon: state.enviandoListo
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.check_circle_outline),
              label: Text(
                state.enviandoListo ? 'Enviando...' : 'Estoy listo para jugar',
              ),
            );
            final undoButton = OutlinedButton.icon(
              key: const ValueKey('boton-deshacer-inicial'),
              onPressed: state.enviandoListo
                  ? null
                  : () => context.read<BoardBloc>().add(
                      const UndoLastPlacementEvent(),
                    ),
              icon: const Icon(Icons.undo),
              label: const Text('Deshacer'),
            );
            return Padding(
              padding: const EdgeInsets.only(top: 18),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth < 380) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        readyButton,
                        const SizedBox(height: 8),
                        undoButton,
                      ],
                    );
                  }
                  return Row(
                    children: [
                      Expanded(child: readyButton),
                      const SizedBox(width: 8),
                      undoButton,
                    ],
                  );
                },
              ),
            );
          },
        ),
        BlocBuilder<BoardBloc, BoardState>(
          builder: (context, state) {
            if (state.listoParaJugar || state.completo) {
              return const SizedBox.shrink();
            }

            final casilla = state.casillaSeleccionada;
            final tipo = casilla == null
                ? null
                : state.matriz[casilla.$1][casilla.$2];
            return Padding(
              padding: const EdgeInsets.only(top: 18),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final information = Row(
                    mainAxisSize: MainAxisSize.min,
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
                      Flexible(
                        child: Text(
                          casilla == null
                              ? '${state.asignaciones.length} DE 6 NÚMEROS COLOCADOS'
                              : 'FILA ${casilla.$1 + 1} / COLUMNA ${casilla.$2 + 1}',
                          style: const TextStyle(
                            color: Color(0xFF52635D),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  );
                  final type = Text(
                    tipo == null ? '' : _nombreTipo(tipo),
                    style: const TextStyle(
                      color: Color(0xFF18332D),
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  );
                  if (constraints.maxWidth < 380) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [information, if (tipo != null) type],
                    );
                  }
                  return Row(
                    children: [
                      Expanded(child: information),
                      if (tipo != null) type,
                    ],
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }
}

class _MatrizTablero extends StatelessWidget {
  const _MatrizTablero();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final spacing = (constraints.maxWidth / 42).clamp(3.0, 7.0);
        final numberFontSize = (constraints.maxWidth / 14).clamp(12.0, 18.0);
        return AspectRatio(
          aspectRatio: 1,
          child: BlocBuilder<BoardBloc, BoardState>(
            builder: (context, state) => GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 49,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                crossAxisSpacing: spacing,
                mainAxisSpacing: spacing,
              ),
              itemBuilder: (context, index) {
                final fila = index ~/ 7;
                final columna = index % 7;
                final tipo = state.matriz[fila][columna];
                final marcada = state.esCasillaMarcada(fila, columna);
                final numero = state.numeroVisibleEn(fila, columna);
                final seleccionada =
                    state.casillaSeleccionada == (fila, columna);
                final origenMovimiento =
                    state.casillaOrigenMovimiento == (fila, columna);
                final numeroInicialSeleccionado =
                    !state.listoParaJugar && marcada && numero != null;
                final valida = state.validPositions.contains(
                  Point<int>(fila, columna),
                );

                return Semantics(
                  label:
                      'Fila ${fila + 1}, columna ${columna + 1}, ${tipo.descripcion}',
                  button: true,
                  hint: valida ? 'Casilla válida para colocar un dado' : null,
                  child: AnimatedContainer(
                    duration: Duration.zero,
                    decoration: BoxDecoration(
                      color: valida
                          ? Color.lerp(
                              tipo.color,
                              const Color(0xFF00E676),
                              0.42,
                            )
                          : seleccionada || origenMovimiento
                          ? Color.lerp(tipo.color, const Color(0xFF35C979), 0.3)
                          : tipo.color,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: valida
                            ? const Color(0xFF00A844)
                            : seleccionada || origenMovimiento
                            ? const Color(0xFF087A45)
                            : marcada
                            ? const Color(0xFF183F38)
                            : Colors.white,
                        width: valida || seleccionada || origenMovimiento
                            ? 3
                            : marcada
                            ? 2
                            : 1.5,
                      ),
                      boxShadow: valida
                          ? const [
                              BoxShadow(
                                color: Color(0xAA00D863),
                                blurRadius: 14,
                                spreadRadius: 1,
                              ),
                              BoxShadow(
                                color: Color(0x4400A844),
                                blurRadius: 20,
                                spreadRadius: 2,
                              ),
                            ]
                          : seleccionada || origenMovimiento
                          ? const [
                              BoxShadow(
                                color: Color(0x7735C979),
                                blurRadius: 12,
                                spreadRadius: 1,
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
                        onTap: state.listoParaJugar
                            ? valida &&
                                      state.isDiceRolled &&
                                      state.movimientoPendiente.isEmpty &&
                                      !state.turnoConfirmado
                                  ? () {
                                      final opciones = state
                                          .numerosColocablesEn(fila, columna);
                                      final elegido = state.selectedDiceValue;
                                      if (elegido != null &&
                                          opciones.contains(elegido)) {
                                        context.read<BoardBloc>().add(
                                          PlaceNumberEvent(
                                            fila,
                                            columna,
                                            elegido,
                                          ),
                                        );
                                      }
                                    }
                                  : null
                            : marcada
                            ? () => context.read<BoardBloc>().add(
                                BoardCellSelected(fila, columna),
                              )
                            : null,
                        child: Center(
                          child: numero == null
                              ? marcada
                                    ? _MarcadorPendiente(
                                        fontSize: numberFontSize * 1.4,
                                      )
                                    : const SizedBox.shrink()
                              : Text(
                                  '$numero',
                                  key: ValueKey(
                                    'numero-celda-$fila-$columna-$numero',
                                  ),
                                  style: TextStyle(
                                    color: numeroInicialSeleccionado
                                        ? Color(0xFF2563EB)
                                        : Color(0xFF18332D),
                                    fontSize: numberFontSize,
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
      },
    );
  }
}

class _MarcadorPendiente extends StatelessWidget {
  const _MarcadorPendiente({required this.fontSize});

  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Stack(
      key: const ValueKey('marcador-pendiente'),
      alignment: Alignment.center,
      children: [
        Text(
          '*',
          style: TextStyle(
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2.4
              ..color = const Color(0xFF183F38),
            fontSize: fontSize,
            fontWeight: FontWeight.w900,
            height: 1,
          ),
        ),
        Text(
          '*',
          style: TextStyle(
            color: Color(0xFF183F38),
            fontSize: fontSize,
            fontWeight: FontWeight.w900,
            height: 1,
          ),
        ),
      ],
    );
  }
}

class _ReadyConfirmationBanner extends StatefulWidget {
  const _ReadyConfirmationBanner({required this.visible});

  final bool visible;

  @override
  State<_ReadyConfirmationBanner> createState() =>
      _ReadyConfirmationBannerState();
}

class _ReadyConfirmationBannerState extends State<_ReadyConfirmationBanner> {
  Timer? _timer;
  late bool _showBanner;

  @override
  void initState() {
    super.initState();
    _showBanner = widget.visible;
    if (_showBanner) _startTimer();
  }

  @override
  void didUpdateWidget(covariant _ReadyConfirmationBanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.visible == widget.visible) return;

    _timer?.cancel();
    _showBanner = widget.visible;
    if (_showBanner) _startTimer();
  }

  void _startTimer() {
    _timer = Timer(const Duration(seconds: 20), () {
      if (mounted) setState(() => _showBanner = false);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _showBanner
      ? Container(
          key: const ValueKey('banner-listo'),
          margin: const EdgeInsets.only(top: 16),
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFE0F0E8),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Text(
            'Confirmaste que estás listo. La partida comenzará cuando todos estén listos.',
            style: TextStyle(
              color: Color(0xFF183F38),
              fontWeight: FontWeight.w800,
            ),
          ),
        )
      : const SizedBox.shrink();
}

class _PanelNumeros extends StatelessWidget {
  const _PanelNumeros();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BoardBloc, BoardState>(
      builder: (context, state) {
        final casilla = state.casillaSeleccionada;
        final origenMovimiento = state.casillaOrigenMovimiento;
        if (casilla == null ||
            (origenMovimiento == null &&
                state.numeroEn(casilla.$1, casilla.$2) != null)) {
          return const SizedBox.shrink();
        }

        final numeroMovimiento = origenMovimiento == null
            ? null
            : state.numeroEn(origenMovimiento.$1, origenMovimiento.$2);
        final numeros = numeroMovimiento == null
            ? BoardState.numerosPermitidos
            : [numeroMovimiento];

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
            LayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.maxWidth < 480 ? 3 : 6;
                final buttonWidth =
                    (constraints.maxWidth - 8 * (columns - 1)) / columns;
                final buttons = BoardState.numerosPermitidos
                    .where(numeros.contains)
                    .map((numero) {
                      final disponible = origenMovimiento == null
                          ? state.numeroEn(casilla.$1, casilla.$2) == null
                          : numero == numeroMovimiento &&
                                casilla != origenMovimiento;
                      final yaSeleccionado = state.asignaciones.values.contains(
                        numero,
                      );
                      final posicionOrigen =
                          origenMovimiento ??
                          state.asignaciones.entries
                              .where((entrada) => entrada.value == numero)
                              .firstOrNull
                              ?.key;
                      final posicionesExcluidas = {
                        ?posicionOrigen,
                        if (origenMovimiento != null) casilla,
                      };
                      final puedeAsignarse =
                          disponible &&
                          state.puedeAsignarNumero(
                            casilla.$1,
                            casilla.$2,
                            numero,
                            excluir: posicionesExcluidas,
                          );
                      return SizedBox(
                        width: buttonWidth,
                        child: OutlinedButton(
                          key: ValueKey('numero-$numero'),
                          onPressed: puedeAsignarse
                              ? () => context.read<BoardBloc>().add(
                                  BoardNumberAssigned(numero),
                                )
                              : null,
                          style: OutlinedButton.styleFrom(
                            backgroundColor: yaSeleccionado
                                ? const Color(0xFFDBEAFE)
                                : null,
                            foregroundColor: yaSeleccionado
                                ? const Color(0xFF1D4ED8)
                                : null,
                            side: BorderSide(
                              color: yaSeleccionado
                                  ? const Color(0xFF2563EB)
                                  : const Color(0xFFBCC9C3),
                              width: yaSeleccionado ? 2 : 1,
                            ),
                            minimumSize: const Size(0, 44),
                            padding: EdgeInsets.zero,
                          ),
                          child: Text('$numero'),
                        ),
                      );
                    })
                    .toList();
                return Wrap(spacing: 8, runSpacing: 8, children: buttons);
              },
            ),
          ],
        );
      },
    );
  }
}

class _PanelLateral extends StatelessWidget {
  const _PanelLateral();

  @override
  Widget build(BuildContext context) {
    final gameStarted = context.watch<MultiplayerService>().gameStarted;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _MultiplayerErrorBanner(),
        if (gameStarted) ...[
          const _PanelReglasMapa(),
          const SizedBox(height: 18),
        ],
        const _PanelTurno(),
      ],
    );
  }
}

class _PanelReglasMapa extends StatelessWidget {
  const _PanelReglasMapa({this.collapsible = false});

  final bool collapsible;

  @override
  Widget build(BuildContext context) => BlocBuilder<BoardBloc, BoardState>(
    builder: (context, state) {
      final seenTypes = <Type>{};
      final rules = <Tipo>[];
      for (final row in state.matriz) {
        for (final tipo in row) {
          if (seenTypes.add(tipo.runtimeType)) rules.add(tipo);
        }
      }

      return Container(
        key: const ValueKey('panel-reglas-colores'),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE1E9E4)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x10183F38),
              blurRadius: 18,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: collapsible
            ? Material(
                color: Colors.transparent,
                child: ExpansionTile(
                  key: const ValueKey('reglas-colores-expandible'),
                  initiallyExpanded: false,
                  tilePadding: EdgeInsets.zero,
                  childrenPadding: EdgeInsets.zero,
                  title: const Text(
                    'REGLAS DE LOS COLORES',
                    style: TextStyle(
                      color: Color(0xFF52635D),
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1,
                    ),
                  ),
                  children: [_listaReglas(rules)],
                ),
              )
            : _listaReglas(rules, incluirTitulo: true),
      );
    },
  );

  Widget _listaReglas(List<Tipo> rules, {bool incluirTitulo = false}) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      if (incluirTitulo) ...[
        const Text(
          'REGLAS DE LOS COLORES',
          style: TextStyle(
            color: Color(0xFF52635D),
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 12),
      ],
      for (var index = 0; index < rules.length; index++) ...[
        if (index > 0) const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 14,
              height: 14,
              margin: const EdgeInsets.only(top: 2),
              decoration: BoxDecoration(
                color: rules[index].color,
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFBCC9C3)),
              ),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _nombreTipo(rules[index]),
                    style: const TextStyle(
                      color: Color(0xFF18332D),
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    rules[index].descripcion,
                    style: const TextStyle(
                      color: Color(0xFF61726C),
                      fontSize: 11,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    ],
  );
}

class _MultiplayerErrorBanner extends StatelessWidget {
  const _MultiplayerErrorBanner();

  @override
  Widget build(BuildContext context) {
    final service = context.read<MultiplayerService>();
    return AnimatedBuilder(
      animation: service,
      builder: (context, _) => service.errorMessage == null
          ? const SizedBox.shrink()
          : Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Text(
                service.errorMessage!,
                key: const ValueKey('error-multijugador'),
                style: const TextStyle(color: Colors.red),
              ),
            ),
    );
  }
}

class _PanelTurno extends StatelessWidget {
  const _PanelTurno();

  @override
  Widget build(BuildContext context) {
    final gameStarted = context.watch<MultiplayerService>().gameStarted;
    return BlocBuilder<BoardBloc, BoardState>(
      builder: (context, state) {
        return Container(
          key: const ValueKey('panel-dados'),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE1E9E4)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x10183F38),
                blurRadius: 18,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'DADOS DEL SERVIDOR',
                style: TextStyle(
                  color: Color(0xFF52635D),
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 12),
              if (!state.listoParaJugar)
                const Text(
                  'Prepara el tablero para empezar.',
                  style: TextStyle(
                    color: Color(0xFF61726C),
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              if (!state.isDiceRolled) ...[
                if (state.listoParaJugar)
                  Row(
                    children: [
                      const SizedBox(
                        width: 15,
                        height: 15,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      const SizedBox(width: 9),
                      Text(
                        gameStarted
                            ? 'Esperando los dados del servidor...'
                            : 'Esperando a que todos estén listos...',
                        style: const TextStyle(
                          color: Color(0xFF52635D),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                if (state.listoParaJugar) const SizedBox(height: 8),
              ],
              if (state.isDiceRolled) ...[
                Row(
                  children: [
                    for (
                      var index = 0;
                      index < state.dados.length;
                      index++
                    ) ...[
                      if (index > 0) const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton(
                          key: ValueKey('dado-$index'),
                          onPressed:
                              state.movimientoPendiente.isNotEmpty ||
                                  state.turnoConfirmado
                              ? null
                              : () => context.read<BoardBloc>().add(
                                  SelectDiceValueEvent(state.dados[index]),
                                ),
                          style: OutlinedButton.styleFrom(
                            backgroundColor:
                                state.selectedDiceValue == state.dados[index]
                                ? const Color(0xFFE0F0E8)
                                : null,
                            side: BorderSide(
                              color:
                                  state.selectedDiceValue == state.dados[index]
                                  ? const Color(0xFF183F38)
                                  : const Color(0xFFBCC9C3),
                            ),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'DADO ${index + 1}',
                                style: const TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.6,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${state.dados[index]}',
                                key: ValueKey(
                                  'valor-dado-$index-${state.dados[index]}',
                                ),
                                style: const TextStyle(
                                  color: Color(0xFF183F38),
                                  fontSize: 28,
                                  height: 1,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                if (state.validPositions.isEmpty &&
                    state.movimientoPendiente.isEmpty &&
                    !state.turnoConfirmado)
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text(
                      'No hay casillas válidas para los dados actuales.',
                      style: TextStyle(color: Color(0xFF52635D), fontSize: 12),
                    ),
                  ),
                const SizedBox(height: 8),
              ],
              if (state.movimientoPendiente.isNotEmpty || state.turnoConfirmado)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: state.turnoConfirmado
                      ? const Text(
                          'Ya confirmaste tu número. Esperando al otro jugador...',
                          key: ValueKey('esperando-jugador'),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Color(0xFF52635D),
                            fontWeight: FontWeight.w700,
                          ),
                        )
                      : Row(
                          children: [
                            Expanded(
                              child: FilledButton.icon(
                                key: const ValueKey('boton-ya-puse-numero'),
                                onPressed: state.enviandoJugada
                                    ? null
                                    : () => context.read<BoardBloc>().add(
                                        const ConfirmMoveEvent(),
                                      ),
                                icon: state.enviandoJugada
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Icon(Icons.check_circle_outline),
                                label: Text(
                                  state.enviandoJugada
                                      ? 'Enviando...'
                                      : 'Ya puse mi número',
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            OutlinedButton.icon(
                              key: const ValueKey('boton-deshacer-jugada'),
                              onPressed: state.enviandoJugada
                                  ? null
                                  : () => context.read<BoardBloc>().add(
                                      const UndoPendingMoveEvent(),
                                    ),
                              icon: const Icon(Icons.undo),
                              label: const Text('Deshacer'),
                            ),
                          ],
                        ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _PanelPuntuacion extends StatelessWidget {
  const _PanelPuntuacion({this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final service = context.read<MultiplayerService>();
    return AnimatedBuilder(
      animation: service,
      builder: (context, _) {
        return Container(
          key: const ValueKey('panel-puntuacion'),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE1E9E4)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x10183F38),
                blurRadius: 18,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'PUNTUACIÓN DE LA PARTIDA',
                style: TextStyle(
                  color: Color(0xFF52635D),
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 12),
              if (service.scores.isEmpty)
                const Text(
                  'El servidor actualizará la puntuación durante la partida.',
                  style: TextStyle(
                    color: Color(0xFF61726C),
                    fontSize: 12,
                    height: 1.4,
                  ),
                )
              else
                for (final score in service.scores)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        Expanded(child: Text(score.playerName)),
                        Text(
                          '${score.total}',
                          style: const TextStyle(
                            color: Color(0xFF183F38),
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
              if (!compact && service.zoneWinners.isNotEmpty) ...[
                const Divider(height: 24),
                const Text(
                  'PRIMEROS EN CADA ZONA',
                  style: TextStyle(
                    color: Color(0xFF52635D),
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 10),
                for (final winner in service.zoneWinners)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      '${winner.zoneId}: ${winner.playerName} · ${winner.points} pts.',
                      style: const TextStyle(
                        color: Color(0xFF18332D),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ],
          ),
        );
      },
    );
  }
}
