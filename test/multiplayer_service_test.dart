import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/multiplayer_service.dart';

void main() {
  test('uses the deployed multiplayer server by default', () {
    expect(MultiplayerService().serverUrl, 'wss://server-41zd.onrender.com');
  });

  test(
    'ignores a premature roll and accepts it after everyone confirms',
    () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      late WebSocket socket;
      Map<String, dynamic>? createPayload;
      Map<String, dynamic>? joinPayload;
      server.transform(WebSocketTransformer()).listen((connection) {
        socket = connection;
        connection.listen((message) {
          final request = jsonDecode(message as String) as Map<String, dynamic>;
          if (request['type'] == 'create_room') {
            createPayload = request['payload'] as Map<String, dynamic>;
          } else if (request['type'] == 'join_room') {
            joinPayload = request['payload'] as Map<String, dynamic>;
          }
          final responsePlayers = request['type'] == 'set_ready'
              ? [
                  {'id': 'player-1', 'name': 'Ana', 'ready': true},
                  {'id': 'player-2', 'name': 'Luis', 'ready': true},
                ]
              : [
                  {'id': 'player-1', 'name': 'Ana', 'ready': false},
                  {'id': 'player-2', 'name': 'Luis', 'ready': false},
                ];
          connection.add(
            jsonEncode({
              'type': 'response',
              'requestId': request['requestId'],
              'ok': true,
              'data': {
                'code': 'ABC123',
                'playerId': 'player-1',
                'mapId': 3,
                'players': responsePlayers,
                'gameStarted': false,
              },
            }),
          );
        });
      });

      final service = MultiplayerService(
        serverUrl: 'ws://127.0.0.1:${server.port}',
      );
      addTearDown(() async {
        service.dispose();
        await server.close(force: true);
      });
      await service.createRoom(mapId: 3, playerName: 'Ana');
      expect(createPayload?['maxPlayers'], MultiplayerService.maxPlayers);
      await service.joinRoom(code: 'abc123', playerName: 'Ana');
      expect(joinPayload?['maxPlayers'], MultiplayerService.maxPlayers);

      await service.setReady(true);
      expect(service.players.first.ready, isTrue);
      expect(service.players.last.ready, isFalse);
      expect(service.allPlayersReady, isFalse);

      final initialRoll = _waitForDiceRoll(service, 1);
      socket.add(jsonEncode({'type': 'game_started', 'data': {}}));
      final roomUpdate = _waitForPlayerName(service, 'Luis listo');
      socket.add(
        jsonEncode({
          'type': 'dice_rolled',
          'data': {
            'values': [2, 5],
          },
        }),
      );
      await initialRoll;
      expect(service.dice, [2, 5]);
      expect(service.errorMessage, isNull);

      socket.add(
        jsonEncode({
          'type': 'dice_rolled',
          'data': {
            'values': [1, 4],
            'confirmedPlayerIds': ['player-1'],
          },
        }),
      );
      socket.add(
        jsonEncode({
          'type': 'room_state',
          'data': {
            'players': [
              {'id': 'player-1', 'name': 'Ana', 'ready': true},
              {'id': 'player-2', 'name': 'Luis listo', 'ready': false},
            ],
          },
        }),
      );
      await roomUpdate;
      expect(service.diceRollId, 1);
      expect(service.dice, [2, 5]);
      expect(service.errorMessage, isNull);

      final nextRoll = _waitForDiceRoll(service, 2);
      socket.add(
        jsonEncode({
          'type': 'dice_rolled',
          'data': {
            'values': [1, 4],
            'confirmedPlayerIds': ['player-1', 'player-2'],
          },
        }),
      );
      await nextRoll;
      expect(service.diceRollId, 2);
      expect(service.dice, [1, 4]);
      expect(service.errorMessage, isNull);
    },
  );

  test(
    'applies own board states and handles a winner after another player leaves',
    () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      late WebSocket socket;
      server.transform(WebSocketTransformer()).listen((connection) {
        socket = connection;
        connection.listen((message) {
          final request = jsonDecode(message as String) as Map<String, dynamic>;
          connection.add(
            jsonEncode({
              'type': 'response',
              'requestId': request['requestId'],
              'ok': true,
              'data': {
                'code': 'ABC123',
                'playerId': 'player-1',
                'mapId': 0,
                'players': [
                  {'id': 'player-1', 'name': 'Ana', 'ready': true},
                  {'id': 'player-2', 'name': 'Luis', 'ready': true},
                ],
                'gameStarted': true,
              },
            }),
          );
        });
      });

      final service = MultiplayerService(
        serverUrl: 'ws://127.0.0.1:${server.port}',
      );
      addTearDown(() async {
        service.dispose();
        await server.close(force: true);
      });
      await service.createRoom(mapId: 0, playerName: 'Ana');

      final otherPlayerBoard = _waitForNextNotification(service);
      socket.add(
        jsonEncode({
          'type': 'board_state',
          'data': {
            'playerId': 'player-2',
            'assignments': [
              {'row': 3, 'column': 2, 'value': 1},
            ],
          },
        }),
      );
      await otherPlayerBoard;
      expect(service.assignments, isEmpty);

      final ownAssignments = {(3, 2): 2};
      final ownBoard = _waitForAssignments(service, ownAssignments);
      socket.add(
        jsonEncode({
          'type': 'board_state',
          'data': {
            'playerId': 'player-1',
            'assignments': [
              {'row': 3, 'column': 2, 'value': 2},
            ],
          },
        }),
      );
      await ownBoard;
      expect(service.assignments, ownAssignments);

      final completedGame = _waitForNextNotification(service);
      socket.add(
        jsonEncode({
          'type': 'game_over',
          'data': {
            'scores': [
              {'playerId': 'player-1', 'playerName': 'Ana', 'total': 21},
              {'playerId': 'player-2', 'playerName': 'Luis', 'total': 17},
            ],
          },
        }),
      );
      await completedGame;
      expect(service.winnerName, 'Ana');
      expect(service.winnerPlayerId, 'player-1');
      expect(service.scores.map((score) => score.total), [21, 17]);

      final nextGame = _waitForNextNotification(service);
      socket.add(jsonEncode({'type': 'game_started', 'data': {}}));
      await nextGame;
      expect(service.winnerName, isNull);

      final leaveNotice = _waitForNextNotification(service);
      socket.add(
        jsonEncode({
          'type': 'player_left',
          'data': {
            'playerId': 'player-2',
            'playerName': 'Luis',
            'winnerPlayerId': 'player-1',
          },
        }),
      );
      await leaveNotice;
      expect(
        service.roomNotice,
        'Luis se salió de la partida. ¡Ganaste la partida!',
      );
      expect(service.winnerName, 'Ana');
      expect(service.winnerPlayerId, 'player-1');
      expect(service.gameStarted, isFalse);
      expect(service.assignments, isEmpty);
      expect(service.dice, isEmpty);
      expect(service.scores.map((score) => score.total), [21, 17]);
    },
  );
}

Future<void> _waitForNextNotification(MultiplayerService service) {
  final completer = Completer<void>();
  late void Function() listener;
  listener = () {
    service.removeListener(listener);
    if (!completer.isCompleted) completer.complete();
  };
  service.addListener(listener);
  return completer.future.timeout(const Duration(seconds: 5));
}

Future<void> _waitForAssignments(
  MultiplayerService service,
  Map<(int, int), int> expected,
) {
  bool matches() =>
      service.assignments.length == expected.length &&
      expected.entries.every(
        (entry) => service.assignments[entry.key] == entry.value,
      );

  if (matches()) return Future<void>.value();

  final completer = Completer<void>();
  late void Function() listener;
  listener = () {
    if (matches() && !completer.isCompleted) {
      service.removeListener(listener);
      completer.complete();
    }
  };
  service.addListener(listener);
  return completer.future.timeout(const Duration(seconds: 5));
}

Future<void> _waitForDiceRoll(MultiplayerService service, int rollId) {
  if (service.diceRollId >= rollId) return Future<void>.value();
  final completer = Completer<void>();
  late void Function() listener;
  listener = () {
    if (service.diceRollId >= rollId && !completer.isCompleted) {
      service.removeListener(listener);
      completer.complete();
    }
  };
  service.addListener(listener);
  return completer.future.timeout(const Duration(seconds: 5));
}

Future<void> _waitForPlayerName(MultiplayerService service, String playerName) {
  if (service.players.any((player) => player.name == playerName)) {
    return Future<void>.value();
  }
  final completer = Completer<void>();
  late void Function() listener;
  listener = () {
    if (service.players.any((player) => player.name == playerName) &&
        !completer.isCompleted) {
      service.removeListener(listener);
      completer.complete();
    }
  };
  service.addListener(listener);
  return completer.future.timeout(const Duration(seconds: 5));
}
