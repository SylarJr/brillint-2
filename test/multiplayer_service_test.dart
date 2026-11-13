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
                'mapId': 3,
                'players': [
                  {'id': 'player-1', 'name': 'Ana', 'ready': false},
                  {'id': 'player-2', 'name': 'Luis', 'ready': false},
                ],
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
