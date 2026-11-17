import 'dart:async';
import 'dart:math' as math;

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

class VictoryCelebration extends StatefulWidget {
  const VictoryCelebration({super.key, required this.winnerName});

  final String winnerName;

  @override
  State<VictoryCelebration> createState() => _VictoryCelebrationState();
}

class _VictoryCelebrationState extends State<VictoryCelebration>
    with TickerProviderStateMixin {
  late final _audioPlayer = AudioPlayer()..audioCache = AudioCache(prefix: '');
  late final AnimationController _particles = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  )..repeat();
  late final AnimationController _entrance = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 450),
  )..forward();
  Timer? _timer;
  bool _audioDisposed = false;
  bool _visible = true;

  @override
  void initState() {
    super.initState();
    unawaited(_playSound());
    _timer = Timer(const Duration(seconds: 40), () {
      if (!mounted) return;
      setState(() => _visible = false);
      _particles.stop();
      unawaited(_stopAndDisposeAudio());
    });
  }

  Future<void> _playSound() async {
    try {
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      await _audioPlayer.play(AssetSource('recursos/Ganador.m4a'));
    } catch (error) {
      debugPrint('No se pudo reproducir el sonido de victoria: $error');
    }
  }

  Future<void> _stopAndDisposeAudio() async {
    if (_audioDisposed) return;
    _audioDisposed = true;
    try {
      await _audioPlayer.stop();
    } catch (error) {
      debugPrint('No se pudo detener el sonido de victoria: $error');
    }
    try {
      await _audioPlayer.dispose();
    } catch (error) {
      debugPrint('No se pudo cerrar el reproductor de victoria: $error');
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _particles.dispose();
    _entrance.dispose();
    unawaited(_stopAndDisposeAudio());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_visible) return const SizedBox.shrink();

    return Positioned.fill(
      child: Material(
        color: const Color(0xD918332D),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedBuilder(
                  animation: _particles,
                  builder: (context, _) => CustomPaint(
                    painter: _ConfettiPainter(progress: _particles.value),
                  ),
                ),
              ),
            ),
            ScaleTransition(
              scale: CurvedAnimation(
                parent: _entrance,
                curve: Curves.elasticOut,
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.emoji_events_rounded,
                      color: Color(0xFFFFD54F),
                      size: 84,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '¡${widget.winnerName} ganó!',
                      key: const ValueKey('celebracion-victoria'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 42,
                        fontWeight: FontWeight.w900,
                        height: 1.1,
                        shadows: [
                          Shadow(color: Color(0x99000000), blurRadius: 16),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  const _ConfettiPainter({required this.progress});

  final double progress;

  static const _colors = [
    Color(0xFFFFD54F),
    Color(0xFF80DEEA),
    Color(0xFFFF8A80),
    Color(0xFFA5D6A7),
    Colors.white,
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    for (var index = 0; index < 56; index++) {
      final seed = index * 0.61803398875;
      final travel = (progress + seed) % 1;
      final x = (seed * size.width * 1.73) % size.width;
      final y = travel * size.height;
      final sway = math.sin((travel + seed) * math.pi * 4) * 24;
      paint.color = _colors[index % _colors.length].withValues(
        alpha: (1 - travel * 0.35).clamp(0, 1),
      );
      canvas.save();
      canvas.translate(x + sway, y);
      canvas.rotate(travel * math.pi * 4);
      canvas.drawRect(
        Rect.fromCenter(
          center: Offset.zero,
          width: index.isEven ? 8 : 5,
          height: index.isEven ? 13 : 8,
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
