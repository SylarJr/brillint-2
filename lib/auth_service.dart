import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const String supabaseProjectUrl = 'https://ugsokviyojezfpbsdxyu.supabase.co';
const String supabasePublishableKey =
    'sb_publishable_58OIQdapcUTY03u9FXbO_A_plTZGVuo';
const String usuarioAuthFunctionName = 'usuario-auth';

Future<void> initializeSupabase() async {
  await Supabase.initialize(
    url: supabaseProjectUrl,
    publishableKey: supabasePublishableKey,
  );
}

class AuthSession {
  const AuthSession({
    required this.usuarioName,
    required this.sessionToken,
    required this.expiresAt,
  });

  final String usuarioName;
  final String sessionToken;
  final DateTime expiresAt;
}

class AuthenticatedUser {
  const AuthenticatedUser({required this.usuarioName});

  final String usuarioName;
}

class AuthServiceException implements Exception {
  const AuthServiceException({
    required this.message,
    this.statusCode,
    this.cause,
  });

  final String message;
  final int? statusCode;
  final Object? cause;

  @override
  String toString() => statusCode != null && statusCode != 0
      ? '$message (HTTP $statusCode)'
      : message;
}

class AuthFunctionResponse {
  const AuthFunctionResponse({required this.statusCode, required this.data});

  final int statusCode;
  final Object? data;
}

abstract interface class AuthFunctionInvoker {
  Future<AuthFunctionResponse> invoke(Map<String, Object?> body);
}

abstract interface class SessionTokenStorage {
  Future<void> save(String token);
  Future<String?> read();
  Future<void> delete();
}

class SecureSessionTokenStorage implements SessionTokenStorage {
  SecureSessionTokenStorage({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  static const String _key = 'usuario_auth_session_token';
  final FlutterSecureStorage _storage;

  @override
  Future<void> save(String token) =>
      _storage.write(key: _key, value: token);

  @override
  Future<String?> read() => _storage.read(key: _key);

  @override
  Future<void> delete() => _storage.delete(key: _key);
}

class AuthService {
  AuthService({
    AuthFunctionInvoker? invoker,
    SessionTokenStorage? tokenStorage,
  }) : _invoker = invoker ?? _SupabaseAuthFunctionInvoker(Supabase.instance.client),
       _tokenStorage = tokenStorage ?? SecureSessionTokenStorage();

  final AuthFunctionInvoker _invoker;
  final SessionTokenStorage _tokenStorage;

  Future<AuthSession> register(String usuarioName, String contrasena) async {
    _validateCredentials(usuarioName, contrasena);
    final response = await _request({
      'action': 'register',
      'usuario_name': usuarioName,
      'contrasena': contrasena,
    });
    final session = _parseSession(response);
    await _tokenStorage.save(session.sessionToken);
    return session;
  }

  Future<AuthSession> login(String usuarioName, String contrasena) async {
    _validateCredentials(usuarioName, contrasena);
    final response = await _request({
      'action': 'login',
      'usuario_name': usuarioName,
      'contrasena': contrasena,
    });
    final session = _parseSession(response);
    await _tokenStorage.save(session.sessionToken);
    return session;
  }

  Future<AuthenticatedUser> validateSession({String? sessionToken}) async {
    final token = await _resolveToken(sessionToken);
    final response = await _request({
      'action': 'session',
      'session_token': token,
    });
    final body = _parseObject(response);
    final usuarioName = body['usuario_name'];
    if (usuarioName is! String || usuarioName.isEmpty) {
      throw _invalidResponse(response.statusCode);
    }
    return AuthenticatedUser(usuarioName: usuarioName);
  }

  Future<void> logout({String? sessionToken}) async {
    final token = await _resolveToken(sessionToken);
    final response = await _request({
      'action': 'logout',
      'session_token': token,
    });
    final body = _parseObject(response);
    if (body['ok'] != true) {
      throw _invalidResponse(response.statusCode);
    }

    final savedToken = await _tokenStorage.read();
    if (savedToken == token) {
      await _tokenStorage.delete();
    }
  }

  Future<AuthFunctionResponse> _request(Map<String, Object?> body) async {
    try {
      final response = await _invoker.invoke(body);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw AuthServiceException(
          statusCode: response.statusCode,
          message: _messageFromData(response.data, 'La solicitud fue rechazada.'),
        );
      }
      return response;
    } on FunctionException catch (error) {
      final detail = _messageFromData(
        error.details,
        error.reasonPhrase ?? 'La función usuario-auth devolvió un error.',
      );
      throw AuthServiceException(
        statusCode: error.status,
        message: error.status == 0
            ? 'No se pudo conectar con usuario-auth: $detail'
            : detail,
        cause: error,
      );
    }
  }

  Future<String> _resolveToken(String? providedToken) async {
    if (providedToken != null) {
      if (providedToken.isEmpty) {
        throw const AuthServiceException(
          message: 'El token de sesión no puede estar vacío.',
        );
      }
      return providedToken;
    }

    final storedToken = await _tokenStorage.read();
    if (storedToken == null || storedToken.isEmpty) {
      throw const AuthServiceException(
        message: 'No hay una sesión guardada en este dispositivo.',
      );
    }
    return storedToken;
  }

  static void _validateCredentials(String usuarioName, String contrasena) {
    if (!RegExp(r'^[A-Za-z0-9_]{3,15}$').hasMatch(usuarioName)) {
      throw const AuthServiceException(
        message:
            'El nombre debe tener entre 3 y 15 caracteres: letras ASCII, números o guion bajo.',
      );
    }

    final passwordLength = utf8.encode(contrasena).length;
    if (passwordLength < 8 || passwordLength > 72) {
      throw const AuthServiceException(
        message: 'La contraseña debe tener entre 8 y 72 bytes UTF-8.',
      );
    }
  }

  static AuthSession _parseSession(AuthFunctionResponse response) {
    final body = _parseObject(response);
    final usuarioName = body['usuario_name'];
    final sessionToken = body['session_token'];
    final expiresAtValue = body['expires_at'];

    if (usuarioName is! String ||
        usuarioName.isEmpty ||
        sessionToken is! String ||
        sessionToken.isEmpty ||
        expiresAtValue is! String) {
      throw _invalidResponse(response.statusCode);
    }

    final expiresAt = DateTime.tryParse(expiresAtValue);
    if (expiresAt == null) {
      throw _invalidResponse(response.statusCode);
    }

    return AuthSession(
      usuarioName: usuarioName,
      sessionToken: sessionToken,
      expiresAt: expiresAt,
    );
  }

  static Map<String, Object?> _parseObject(AuthFunctionResponse response) {
    final data = response.data;
    if (data is Map) {
      final result = <String, Object?>{};
      for (final entry in data.entries) {
        if (entry.key is! String) {
          throw _invalidResponse(response.statusCode);
        }
        result[entry.key as String] = entry.value;
      }
      return result;
    }
    throw _invalidResponse(response.statusCode);
  }

  static AuthServiceException _invalidResponse(int statusCode) =>
      AuthServiceException(
        statusCode: statusCode,
        message: 'La respuesta de usuario-auth no tiene el formato esperado.',
      );

  static String _messageFromData(Object? data, String fallback) {
    Object? decoded = data;
    if (data is String) {
      try {
        decoded = jsonDecode(data);
      } on FormatException {
        if (data.trim().isNotEmpty) {
          return data;
        }
      }
    }

    if (decoded is Map) {
      final error = decoded['error'];
      if (error is String && error.trim().isNotEmpty) {
        return error;
      }
    }
    if (data is String && data.trim().isNotEmpty) {
      return data;
    }
    if (data != null && data is! Map) {
      return data.toString();
    }
    return fallback;
  }
}

class _SupabaseAuthFunctionInvoker implements AuthFunctionInvoker {
  const _SupabaseAuthFunctionInvoker(this._client);

  final SupabaseClient _client;

  @override
  Future<AuthFunctionResponse> invoke(Map<String, Object?> body) async {
    final response = await _client.functions.invoke(
      usuarioAuthFunctionName,
      body: body,
    );
    final Object? data = response.data;
    return AuthFunctionResponse(statusCode: response.status, data: data);
  }
}
