import 'package:flutter/material.dart';

class AccesoPage extends StatefulWidget {
  const AccesoPage({super.key, required this.onOpenMaps});

  final VoidCallback onOpenMaps;

  @override
  State<AccesoPage> createState() => _AccesoPageState();
}

class _AccesoPageState extends State<AccesoPage> {
  bool _esRegistro = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: OutlinedButton.icon(
                  key: const ValueKey('ir-a-mapas'),
                  onPressed: widget.onOpenMaps,
                  icon: const Icon(Icons.map_outlined),
                  label: const Text('Ir a selección de mapas'),
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 430),
                    child: Card(
                      elevation: 2,
                      clipBehavior: Clip.antiAlias,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: const BorderSide(color: Color(0xFFDCE5DF)),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(28),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Icon(
                              Icons.grid_view_rounded,
                              color: Color(0xFF286B5C),
                              size: 42,
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'BRILLANT',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Color(0xFF183F38),
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.8,
                              ),
                            ),
                            const SizedBox(height: 28),
                            Text(
                              _esRegistro
                                  ? 'Crear una cuenta'
                                  : 'Iniciar sesión',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Color(0xFF18332D),
                                fontSize: 25,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _esRegistro
                                  ? 'Regístrate para comenzar a jugar.'
                                  : 'Ingresa tus datos para continuar.',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Color(0xFF61726C),
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 28),
                            TextField(
                              decoration: InputDecoration(
                                labelText: 'Nombre de usuario',
                                prefixIcon: const Icon(Icons.person_outline),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextField(
                              obscureText: true,
                              decoration: InputDecoration(
                                labelText: 'Contraseña',
                                prefixIcon: const Icon(Icons.lock_outline),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            FilledButton(
                              onPressed: () {},
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFF286B5C),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                _esRegistro ? 'Crear cuenta' : 'Iniciar sesión',
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextButton(
                              onPressed: () =>
                                  setState(() => _esRegistro = !_esRegistro),
                              child: Text(
                                _esRegistro
                                    ? '¿Ya tienes una cuenta? Inicia sesión'
                                    : '¿No tienes una cuenta? Crear cuenta',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
