import 'package:flutter/material.dart';

import 'auth_service.dart';

class AccesoPage extends StatefulWidget {
  const AccesoPage({
    super.key,
    required this.onOpenMaps,
    required this.onAuthenticated,
    this.authService,
  });

  final VoidCallback onOpenMaps;
  final VoidCallback onAuthenticated;
  final AuthService? authService;

  @override
  State<AccesoPage> createState() => _AccesoPageState();
}

class _AccesoPageState extends State<AccesoPage> {
  final _usuarioController = TextEditingController();
  final _contrasenaController = TextEditingController();
  bool _esRegistro = true;
  bool _enviando = false;
  String? _error;

  @override
  void dispose() {
    _usuarioController.dispose();
    _contrasenaController.dispose();
    super.dispose();
  }

  Future<void> _enviarCredenciales() async {
    if (_enviando) return;

    setState(() {
      _enviando = true;
      _error = null;
    });

    try {
      final authService = widget.authService ?? AuthService();
      if (_esRegistro) {
        await authService.register(
          _usuarioController.text.trim(),
          _contrasenaController.text,
        );
      } else {
        await authService.login(
          _usuarioController.text.trim(),
          _contrasenaController.text,
        );
      }

      if (!mounted) return;
      _contrasenaController.clear();
      widget.onAuthenticated();
    } on AuthServiceException catch (error) {
      if (!mounted) return;
      setState(() => _error = error.toString());
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = 'No se pudo completar la solicitud: $error');
    } finally {
      if (mounted) {
        setState(() => _enviando = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
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
                              key: const ValueKey('nombre-usuario'),
                              controller: _usuarioController,
                              textInputAction: TextInputAction.next,
                              autocorrect: false,
                              decoration: InputDecoration(
                                labelText: 'Nombre de usuario',
                                helperText: '3 a 15 letras, números o guion bajo',
                                prefixIcon: const Icon(Icons.person_outline),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextField(
                              key: const ValueKey('contrasena'),
                              controller: _contrasenaController,
                              obscureText: true,
                              enableSuggestions: false,
                              autocorrect: false,
                              textInputAction: TextInputAction.done,
                              onSubmitted: (_) => _enviarCredenciales(),
                              decoration: InputDecoration(
                                labelText: 'Contraseña',
                                helperText: 'Entre 8 y 72 bytes UTF-8',
                                prefixIcon: const Icon(Icons.lock_outline),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            FilledButton(
                              key: const ValueKey('enviar-credenciales'),
                              onPressed: _enviando
                                  ? null
                                  : _enviarCredenciales,
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFF286B5C),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: _enviando
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : Text(
                                      _esRegistro
                                          ? 'Crear cuenta'
                                          : 'Iniciar sesión',
                                    ),
                            ),
                            if (_error != null) ...[
                              const SizedBox(height: 12),
                              Text(
                                _error!,
                                key: const ValueKey('error-autenticacion'),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.error,
                                ),
                              ),
                            ],
                            const SizedBox(height: 12),
                            TextButton(
                              onPressed: _enviando
                                  ? null
                                  : () => setState(() {
                                      _esRegistro = !_esRegistro;
                                      _error = null;
                                      _contrasenaController.clear();
                                    }),
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
