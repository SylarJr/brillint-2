import 'package:flutter/material.dart';

class RoomNoticeBanner extends StatelessWidget {
  const RoomNoticeBanner({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => Container(
    key: const ValueKey('aviso-salida-jugador'),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: const Color(0xFFE0F0E8),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: const Color(0xFFB8D7C6)),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.info_outline, color: Color(0xFF183F38), size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            message,
            style: const TextStyle(
              color: Color(0xFF183F38),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    ),
  );
}
