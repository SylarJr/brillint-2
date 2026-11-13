import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class RoomPlayer {
  const RoomPlayer({required this.id, required this.name, required this.ready});

  final String id;
  final String name;
  final bool ready;

  factory RoomPlayer.fromJson(Map<String, Object?> json) => RoomPlayer(
    id: json['id'] as String,
    name: json['name'] as String,
    ready: json['ready'] as bool? ?? false,
  );
}

class PlayerScore {
  const PlayerScore({
    required this.playerId,
    required this.playerName,
    required this.total,
  });

  final String playerId;
  final String playerName;
  final int total;

  factory PlayerScore.fromJson(Map<String, Object?> json) => PlayerScore(
    playerId: json['playerId'] as String,
    playerName: json['playerName'] as String,
    total: json['total'] as int,
  );
}

class ZoneWinner {
  const ZoneWinner({
    required this.zoneId,
    required this.playerName,
    required this.place,
    required this.points,
  });

  final String zoneId;
  final String playerName;
  final int place;
  final int points;

  factory ZoneWinner.fromJson(Map<String, Object?> json) => ZoneWinner(
    zoneId: json['zoneId'] as String,
    playerName: json['playerName'] as String,
    place: json['place'] as int,
    points: json['points'] as int,
  );
}

class MultiplayerService extends ChangeNotifier {
  MultiplayerService({
    this.serverUrl = const String.fromEnvironment(
      'MULTIPLAYER_SERVER_URL',
      defaultValue: 'ws://localhost:3000',
    ),
  });

  static const _requestTimeout = Duration(seconds: 12);

  final String serverUrl;
  final Map<String, Completer<Map<String, Object?>>> _pendingRequests = {};
  WebSocketChannel? _channel;
  StreamSubscription<Object?>? _subscription;
  int _nextRequestId = 0;
  bool connected = false;
  String? errorMessage;
  String? roomCode;
  String? playerId;
  int? mapId;
  bool gameStarted = false;
  int diceRollId = 0;
  List<RoomPlayer> players = const [];
  List<int> dice = const [];
  Map<(int, int), int> assignments = const {};
  List<PlayerScore> scores = const [];
  List<ZoneWinner> zoneWinners = const [];

  bool get allPlayersReady =>
      players.length >= 2 && players.every((player) => player.ready);

  Future<void> createRoom({
    required int mapId,
    required String playerName,
  }) async {
    final data = await _request('create_room', {
      'mapId': mapId,
      'playerName': playerName,
    });
    this.mapId = mapId;
    _applyRoomData(data);
  }

  Future<void> setReady(bool ready) async {
    final response = await _request('set_ready', {'ready': ready});
    if (response['players'] is List) {
      _applyRoomData(response);
    }
  }

  Future<void> joinRoom({
    required String code,
    required String playerName,
  }) async {
    final data = await _request('join_room', {
      'code': code.trim().toUpperCase(),
      'playerName': playerName,
    });
    _applyRoomData(data);
  }

  Future<void> submitInitialBoard(
    Map<(int, int), int> initialAssignments,
  ) async {
    final response = await _request('submit_initial_board', {
      'assignments': _serializeAssignments(initialAssignments),
      'ready': true,
    });
    if (response['assignments'] is List) {
      _applyOptionalBoard(response);
    }
    notifyListeners();
  }

  Future<void> placeNumber(int row, int column, int number) async {
    await _request('place_number', {
      'row': row,
      'column': column,
      'number': number,
      'ready': true,
    });
  }

  Future<void> leaveRoom() async {
    if (connected && roomCode != null) {
      await _request('leave_room', const {});
    }
    _clearRoom();
  }

  Future<Map<String, Object?>> _request(
    String action,
    Map<String, Object?> payload,
  ) async {
    String? requestId;
    errorMessage = null;
    notifyListeners();
    try {
      await _connect();
      requestId =
          '${DateTime.now().microsecondsSinceEpoch}-${_nextRequestId++}';
      final completer = Completer<Map<String, Object?>>();
      _pendingRequests[requestId] = completer;
      _channel!.sink.add(
        jsonEncode({
          'type': action,
          'requestId': requestId,
          'payload': payload,
        }),
      );
      final response = await completer.future.timeout(_requestTimeout);
      return response;
    } catch (error) {
      errorMessage = 'No se pudo completar "$action": $error';
      notifyListeners();
      rethrow;
    } finally {
      if (requestId != null) _pendingRequests.remove(requestId);
    }
  }

  Future<void> _connect() async {
    if (connected) return;
    if (_channel != null) {
      await _subscription?.cancel();
      _channel = null;
    }

    final channel = WebSocketChannel.connect(Uri.parse(serverUrl));
    _channel = channel;
    await channel.ready.timeout(_requestTimeout);
    connected = true;
    errorMessage = null;
    _subscription = channel.stream.listen(
      _handleMessage,
      onError: (Object error, StackTrace stackTrace) {
        connected = false;
        errorMessage = 'Se perdió la conexión con el servidor: $error';
        _failPending(error);
        notifyListeners();
      },
      onDone: () {
        connected = false;
        const error = 'Se cerró la conexión con el servidor.';
        errorMessage = roomCode == null ? null : error;
        _failPending(StateError(error));
        notifyListeners();
      },
    );
    notifyListeners();
  }

  void _handleMessage(Object? rawMessage) {
    try {
      final decoded = jsonDecode(rawMessage as String);
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException(
          'El mensaje del servidor no es un objeto JSON.',
        );
      }

      final type = decoded['type'];
      final data = decoded['data'] == null
          ? <String, Object?>{}
          : _objectMap(decoded['data']);
      if (type == 'response') {
        final requestId = decoded['requestId'] as String?;
        final completer = requestId == null
            ? null
            : _pendingRequests.remove(requestId);
        if (completer == null) return;
        if (decoded['ok'] == true) {
          completer.complete(data);
        } else {
          final message = decoded['error'] as String? ?? 'Solicitud rechazada.';
          completer.completeError(StateError(message));
        }
        return;
      }

      switch (type) {
        case 'room_state':
          _applyRoomData(data);
        case 'game_started':
          gameStarted = true;
          _applyOptionalBoard(data);
          notifyListeners();
        case 'dice_rolled':
          if (diceRollId > 0 &&
              !_allPlayersConfirmed(data['confirmedPlayerIds'])) {
            return;
          }
          errorMessage = null;
          dice = _diceValues(data['values']);
          diceRollId++;
          _applyOptionalBoard(data);
          notifyListeners();
        case 'board_state':
          _applyOptionalBoard(data);
          notifyListeners();
        case 'score_update':
          _applyScores(data);
        case 'game_over':
          gameStarted = true;
          _applyScores(data);
        case 'error':
          errorMessage = data['message'] as String? ?? 'Error del servidor.';
          notifyListeners();
        default:
          throw FormatException('Evento de servidor desconocido: $type');
      }
    } catch (error) {
      errorMessage = 'No se pudo interpretar un mensaje del servidor: $error';
      notifyListeners();
    }
  }

  bool _allPlayersConfirmed(Object? value) {
    if (players.isEmpty ||
        value is! List ||
        value.any((playerId) => playerId is! String)) {
      return false;
    }
    final confirmedIds = value.cast<String>().toSet();
    return confirmedIds.length == players.length &&
        confirmedIds.containsAll(players.map((player) => player.id));
  }

  void _applyRoomData(Map<String, Object?> data) {
    roomCode = data['code'] as String? ?? roomCode;
    playerId = data['playerId'] as String? ?? playerId;
    mapId = data['mapId'] as int? ?? mapId;
    if (data['players'] is List) {
      players = [
        for (final player in data['players'] as List)
          RoomPlayer.fromJson(_objectMap(player)),
      ];
    }
    if (data['gameStarted'] is bool) {
      gameStarted = data['gameStarted'] as bool;
    }
    notifyListeners();
  }

  void _applyOptionalBoard(Map<String, Object?> data) {
    if (data['assignments'] is List) {
      final entries = (data['assignments'] as List)
          .map(_objectMap)
          .toList(growable: false);
      assignments = {
        for (final entry in entries)
          (entry['row'] as int, entry['column'] as int): entry['value'] as int,
      };
    }
    if (data['values'] is List) {
      dice = _diceValues(data['values']);
    }
  }

  void _applyScores(Map<String, Object?> data) {
    if (data['scores'] is List) {
      scores = [
        for (final item in data['scores'] as List)
          PlayerScore.fromJson(_objectMap(item)),
      ];
    }
    if (data['zoneWinners'] is List) {
      zoneWinners = [
        for (final item in data['zoneWinners'] as List)
          ZoneWinner.fromJson(_objectMap(item)),
      ];
    }
    notifyListeners();
  }

  void _failPending(Object error) {
    final pending = _pendingRequests.values.toList();
    _pendingRequests.clear();
    for (final completer in pending) {
      if (!completer.isCompleted) completer.completeError(error);
    }
  }

  void _clearRoom() {
    roomCode = null;
    playerId = null;
    mapId = null;
    gameStarted = false;
    diceRollId = 0;
    players = const [];
    dice = const [];
    assignments = const {};
    scores = const [];
    zoneWinners = const [];
    errorMessage = null;
    notifyListeners();
  }

  static List<Map<String, int>> _serializeAssignments(
    Map<(int, int), int> values,
  ) => [
    for (final entry in values.entries)
      {'row': entry.key.$1, 'column': entry.key.$2, 'value': entry.value},
  ];

  static List<int> _intList(Object? value, String field) {
    if (value is! List || value.any((item) => item is! int)) {
      throw FormatException('El campo "$field" debe ser una lista de enteros.');
    }
    return value.cast<int>();
  }

  static List<int> _diceValues(Object? value) {
    final values = _intList(value, 'values');
    if (values.length != 2 ||
        values.any((number) => number < 1 || number > 6)) {
      throw const FormatException(
        'Los dados del servidor deben contener dos números entre 1 y 6.',
      );
    }
    return values;
  }

  static Map<String, Object?> _objectMap(Object? value) {
    if (value is! Map) {
      throw const FormatException('Se esperaba un objeto JSON.');
    }
    return value.map((key, value) => MapEntry(key.toString(), value));
  }

  @override
  void dispose() {
    _failPending(StateError('El cliente multijugador fue cerrado.'));
    _subscription?.cancel();
    _channel?.sink.close();
    super.dispose();
  }
}
