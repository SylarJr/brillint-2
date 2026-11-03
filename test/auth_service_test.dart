import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/auth_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  group('AuthService', () {
    late _FakeInvoker invoker;
    late _MemoryTokenStorage tokenStorage;
    late AuthService service;

    setUp(() {
      invoker = _FakeInvoker();
      tokenStorage = _MemoryTokenStorage();
      service = AuthService(invoker: invoker, tokenStorage: tokenStorage);
    });

    test(
      'register sends the contract body and stores the session token',
      () async {
        invoker.responses.add(_sessionResponse());

        final session = await service.register('Jugador_1', 'password123');

        expect(invoker.bodies.single, {
          'action': 'register',
          'usuario_name': 'Jugador_1',
          'contrasena': 'password123',
        });
        expect(session.usuarioName, 'jugador_1');
        expect(session.sessionToken, 'test-session-token');
        expect(tokenStorage.token, 'test-session-token');
      },
    );

    test(
      'login sends the contract body and stores the session token',
      () async {
        invoker.responses.add(_sessionResponse());

        final session = await service.login('Usuario9', 'password123');

        expect(invoker.bodies.single, {
          'action': 'login',
          'usuario_name': 'Usuario9',
          'contrasena': 'password123',
        });
        expect(session.sessionToken, 'test-session-token');
        expect(tokenStorage.token, 'test-session-token');
      },
    );

    test('validateSession sends the token and parses the username', () async {
      invoker.responses.add(
        const AuthFunctionResponse(
          statusCode: 200,
          data: {'usuario_name': 'usuario9'},
        ),
      );

      final user = await service.validateSession(
        sessionToken: 'token-to-validate',
      );

      expect(invoker.bodies.single, {
        'action': 'session',
        'session_token': 'token-to-validate',
      });
      expect(user.usuarioName, 'usuario9');
    });

    test(
      'logout sends the token and removes the matching saved token',
      () async {
        tokenStorage.token = 'token-to-logout';
        invoker.responses.add(
          const AuthFunctionResponse(statusCode: 200, data: {'ok': true}),
        );

        await service.logout(sessionToken: 'token-to-logout');

        expect(invoker.bodies.single, {
          'action': 'logout',
          'session_token': 'token-to-logout',
        });
        expect(tokenStorage.token, isNull);
      },
    );

    test('server errors preserve HTTP status and message', () async {
      invoker.errors.add(
        const FunctionException(
          status: 401,
          details: {'error': 'Credenciales inválidas'},
        ),
      );

      await expectLater(
        service.login('Usuario9', 'password123'),
        throwsA(
          isA<AuthServiceException>()
              .having((error) => error.statusCode, 'statusCode', 401)
              .having(
                (error) => error.message,
                'message',
                'Credenciales inválidas',
              ),
        ),
      );
    });

    test('connection errors are surfaced without losing their cause', () async {
      const error = FunctionsFetchException(details: 'socket unavailable');
      invoker.errors.add(error);

      await expectLater(
        service.validateSession(sessionToken: 'token'),
        throwsA(
          isA<AuthServiceException>()
              .having((exception) => exception.statusCode, 'statusCode', 0)
              .having(
                (exception) => exception.message,
                'message',
                contains('socket unavailable'),
              )
              .having((exception) => exception.cause, 'cause', error),
        ),
      );
    });

    test('malformed success responses are rejected', () async {
      invoker.responses.add(
        const AuthFunctionResponse(statusCode: 200, data: {'ok': true}),
      );

      await expectLater(
        service.login('Usuario9', 'password123'),
        throwsA(
          isA<AuthServiceException>().having(
            (error) => error.message,
            'message',
            contains('formato esperado'),
          ),
        ),
      );
      expect(tokenStorage.token, isNull);
    });

    test('invalid credentials are rejected before invoking the function', () {
      expect(
        () => service.register('ab', 'password123'),
        throwsA(isA<AuthServiceException>()),
      );
      expect(invoker.bodies, isEmpty);
    });
  });
}

AuthFunctionResponse _sessionResponse() => const AuthFunctionResponse(
  statusCode: 200,
  data: {
    'usuario_name': 'jugador_1',
    'session_token': 'test-session-token',
    'expires_at': '2030-01-01T00:00:00Z',
  },
);

class _FakeInvoker implements AuthFunctionInvoker {
  final List<Map<String, Object?>> bodies = [];
  final List<AuthFunctionResponse> responses = [];
  final List<Object> errors = [];

  @override
  Future<AuthFunctionResponse> invoke(Map<String, Object?> body) async {
    bodies.add(Map<String, Object?>.of(body));
    if (errors.isNotEmpty) {
      throw errors.removeAt(0);
    }
    return responses.removeAt(0);
  }
}

class _MemoryTokenStorage implements SessionTokenStorage {
  String? token;

  @override
  Future<void> delete() async {
    token = null;
  }

  @override
  Future<String?> read() async => token;

  @override
  Future<void> save(String value) async {
    token = value;
  }
}
