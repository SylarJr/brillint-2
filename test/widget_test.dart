// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:flutter_application_1/acceso_page.dart';
import 'package:flutter_application_1/auth_service.dart';
import 'package:flutter_application_1/main.dart';
import 'package:flutter_application_1/multiplayer_service.dart';
import 'package:flutter_application_1/tablero_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> _abrirSeleccionMapas(
  WidgetTester tester, {
  MultiplayerService? multiplayer,
  Future<void> Function()? onLogout,
}) async {
  final service = multiplayer ?? _FakeMultiplayerService();
  await tester.pumpWidget(
    BlocProvider(
      create: (_) => BoardBloc(multiplayer: service),
      child: ChangeNotifierProvider<MultiplayerService>.value(
        value: service,
        child: MaterialApp(
          home: PaginaPrincipal(
            onLogout: onLogout ?? () async {},
            playerName: 'Jugador_1',
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _entrarAlMapa(
  WidgetTester tester, {
  int mapa = 0,
  MultiplayerService? multiplayer,
}) async {
  final service = multiplayer ?? _FakeMultiplayerService();
  await _abrirSeleccionMapas(tester, multiplayer: service);
  final tarjeta = find.byKey(ValueKey('mapa-card-$mapa'));
  await tester.ensureVisible(tarjeta);
  await tester.tap(tarjeta);
  await tester.pumpAndSettle();
  final readyButton = find.byKey(const ValueKey('boton-listo-para-empezar'));
  await tester.scrollUntilVisible(
    readyButton,
    250,
    scrollable: find.byType(Scrollable).last,
  );
  await tester.tap(readyButton);
  await tester.pumpAndSettle();
  (service as _FakeMultiplayerService).markAllPlayersReady();
  await tester.pumpAndSettle();
}

Future<void> _completarTablero(WidgetTester tester) async {
  for (var index = 0; index < 6; index++) {
    final (row, column) = BoardState.casillasObjetivo.elementAt(index);
    final cell = find.byKey(ValueKey('celda-$row-$column'));
    await tester.ensureVisible(cell);
    await tester.tap(cell);
    await tester.pump();
    final number = find.byKey(ValueKey('numero-${index + 1}'));
    await tester.ensureVisible(number);
    await tester.tap(number);
    await tester.pump();
  }
}

void main() {
  testWidgets('muestra inicio de sesión y permite cambiar a registro', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('Iniciar sesión'), findsNWidgets(2));
    expect(find.text('Nombre de usuario'), findsOneWidget);
    expect(find.text('Contraseña'), findsOneWidget);
    expect(find.text('Ir a selección de mapas'), findsNothing);

    final cambiarARegistro = find.text('¿No tienes una cuenta? Crear cuenta');
    await tester.ensureVisible(cambiarARegistro);
    await tester.tap(cambiarARegistro);
    await tester.pumpAndSettle();
    expect(find.text('Crear una cuenta'), findsOneWidget);
    expect(find.text('¿Ya tienes una cuenta? Inicia sesión'), findsOneWidget);
  });

  testWidgets('registro envía las credenciales y continúa al terminar', (
    WidgetTester tester,
  ) async {
    final invoker = _FakeAuthFunctionInvoker();
    String? authenticatedAs;

    await tester.pumpWidget(
      MaterialApp(
        home: AccesoPage(
          authService: AuthService(
            invoker: invoker,
            tokenStorage: _FakeSessionTokenStorage(),
          ),
          onOpenMaps: () {},
          onAuthenticated: (playerName) => authenticatedAs = playerName,
        ),
      ),
    );

    final cambiarARegistro = find.text('¿No tienes una cuenta? Crear cuenta');
    await tester.ensureVisible(cambiarARegistro);
    await tester.tap(cambiarARegistro);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('nombre-usuario')),
      'Jugador_1',
    );
    await tester.enterText(
      find.byKey(const ValueKey('contrasena')),
      'password123',
    );
    await tester.tap(find.byKey(const ValueKey('enviar-credenciales')));
    await tester.pumpAndSettle();

    expect(invoker.bodies.single, {
      'action': 'register',
      'usuario_name': 'Jugador_1',
      'contrasena': 'password123',
    });

    expect(authenticatedAs, 'jugador_1');
    expect(find.text('password123'), findsNothing);
  });

  testWidgets('selección de mapas permite cerrar sesión', (
    WidgetTester tester,
  ) async {
    var cerrada = false;
    await _abrirSeleccionMapas(tester, onLogout: () async => cerrada = true);

    final botonCerrarSesion = find.byKey(const ValueKey('cerrar-sesion'));
    expect(botonCerrarSesion, findsOneWidget);
    await tester.tap(botonCerrarSesion);
    await tester.pumpAndSettle();

    expect(cerrada, isTrue);
  });

  testWidgets('muestra el mapa completo en tarjetas de teléfono', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await _abrirSeleccionMapas(tester);

    final images = tester.widgetList<Image>(find.byType(Image));
    expect(images, hasLength(4));
    expect(images.map((image) => image.fit), everyElement(BoxFit.contain));

    final grid = tester.widget<GridView>(find.byType(GridView));
    final gridDelegate =
        grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
    expect(gridDelegate.crossAxisCount, 1);
    expect(gridDelegate.childAspectRatio, 0.92);
  });

  testWidgets('inicio de sesión muestra el error del servidor', (
    WidgetTester tester,
  ) async {
    final invoker = _FakeAuthFunctionInvoker()
      ..error = const FunctionException(
        status: 401,
        details: {'error': 'Credenciales inválidas'},
      );

    await tester.pumpWidget(
      MaterialApp(
        home: AccesoPage(
          authService: AuthService(
            invoker: invoker,
            tokenStorage: _FakeSessionTokenStorage(),
          ),
          onOpenMaps: () {},
          onAuthenticated: (_) {},
        ),
      ),
    );

    await tester.enterText(
      find.byKey(const ValueKey('nombre-usuario')),
      'Jugador_1',
    );
    await tester.enterText(
      find.byKey(const ValueKey('contrasena')),
      'password123',
    );
    await tester.tap(find.byKey(const ValueKey('enviar-credenciales')));
    await tester.pumpAndSettle();

    expect(invoker.bodies.single['action'], 'login');
    expect(find.text('Credenciales inválidas (HTTP 401)'), findsOneWidget);
  });

  testWidgets('elegir un mapa crea una sala y muestra el lobby', (
    WidgetTester tester,
  ) async {
    final service = _FakeMultiplayerService();
    await _abrirSeleccionMapas(tester, multiplayer: service);

    expect(find.text('Juega con otras personas'), findsOneWidget);
    expect(find.byType(Image), findsNWidgets(4));
    expect(find.text('Mapa inicial'), findsOneWidget);
    expect(find.text('Mapa 1'), findsOneWidget);
    expect(find.text('Mapa 2'), findsOneWidget);
    expect(find.text('Mapa 3'), findsOneWidget);

    final tarjeta = find.byKey(const ValueKey('mapa-card-2'));
    await tester.ensureVisible(tarjeta);
    await tester.tap(tarjeta);
    await tester.pumpAndSettle();

    final bloc = tester
        .element(find.byKey(const ValueKey('codigo-invitacion')))
        .read<BoardBloc>();
    expect(bloc.state.mapaSeleccionado, 2);
    expect(bloc.state.mapaAbierto, isTrue);
    expect(bloc.state.asignaciones, isEmpty);
    expect(find.text('Lobby'), findsOneWidget);
    expect(find.text('Q7M4PX'), findsOneWidget);
    expect(find.text('Jugador_1'), findsOneWidget);
    expect(service.lastPlayerName, 'Jugador_1');
    expect(find.textContaining('Todos deben marcarse listos'), findsOneWidget);
    expect(find.byKey(const ValueKey('salir-mapa')), findsNothing);
  });

  testWidgets('el lobby espera a todos antes de abrir el tablero', (
    WidgetTester tester,
  ) async {
    final service = _FakeMultiplayerService();
    await _abrirSeleccionMapas(tester, multiplayer: service);
    final tarjeta = find.byKey(const ValueKey('mapa-card-1'));
    await tester.ensureVisible(tarjeta);
    await tester.tap(tarjeta);
    await tester.pumpAndSettle();
    expect(find.text('Lobby'), findsOneWidget);

    final listo = find.byKey(const ValueKey('boton-listo-para-empezar'));
    await tester.scrollUntilVisible(
      listo,
      250,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(listo);
    await tester.pumpAndSettle();

    expect(service.players.first.ready, isTrue);
    expect(service.players.last.ready, isFalse);
    expect(find.text('Lobby'), findsOneWidget);
    expect(find.text('Mapa de colores'), findsNothing);
    expect(service.allPlayersReady, isFalse);

    service.markAllPlayersReady();
    await tester.pumpAndSettle();
    expect(service.initialAssignments, isNull);
    expect(service.gameStarted, isFalse);
    expect(find.text('Mapa de colores'), findsOneWidget);
    expect(find.byKey(const ValueKey('boton-estoy-listo')), findsNothing);
    expect(find.byKey(const ValueKey('volver-lobby')), findsNothing);
  });

  testWidgets('un jugador puede cancelar su confirmación en el lobby', (
    WidgetTester tester,
  ) async {
    final service = _FakeMultiplayerService();
    await _abrirSeleccionMapas(tester, multiplayer: service);
    await tester.tap(find.byKey(const ValueKey('mapa-card-0')));
    await tester.pumpAndSettle();

    final readyButton = find.byKey(const ValueKey('boton-listo-para-empezar'));
    await tester.scrollUntilVisible(
      readyButton,
      250,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(readyButton);
    await tester.pumpAndSettle();
    expect(service.players.first.ready, isTrue);
    expect(find.text('Lobby'), findsOneWidget);

    await tester.tap(readyButton);
    await tester.pumpAndSettle();

    expect(find.text('Lobby'), findsOneWidget);
    expect(service.gameStarted, isFalse);
    expect(service.initialAssignments, isNull);
    expect(service.players.first.ready, isFalse);
  });

  testWidgets('seis números permiten enviar listo, pero no generan dados', (
    WidgetTester tester,
  ) async {
    final service = _FakeMultiplayerService();
    await _entrarAlMapa(tester, multiplayer: service);

    final bloc = tester
        .element(find.byKey(const ValueKey('celda-0-0')))
        .read<BoardBloc>();
    await _completarTablero(tester);

    expect(bloc.state.completo, isTrue);
    expect(bloc.state.listoParaJugar, isFalse);
    expect(service.initialAssignments, isNull);
    expect(find.byKey(const ValueKey('boton-estoy-listo')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('boton-deshacer-inicial')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('boton-deshacer-inicial')));
    await tester.pump();
    expect(bloc.state.asignaciones.length, 5);
    expect(find.byKey(const ValueKey('boton-estoy-listo')), findsNothing);
    final (lastRow, lastColumn) = BoardState.casillasObjetivo.elementAt(5);
    await tester.tap(find.byKey(ValueKey('celda-$lastRow-$lastColumn')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('numero-6')));
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('boton-estoy-listo')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(bloc.state.listoParaJugar, isTrue);
    expect(service.initialAssignments, bloc.state.asignaciones);
    expect(service.dice, isEmpty);
    expect(service.gameStarted, isFalse);
    expect(find.text('Estoy listo para jugar'), findsNothing);
    expect(find.text('Esperando a que todos estén listos...'), findsOneWidget);
  });

  testWidgets('confirma una jugada, permite deshacer y espera al servidor', (
    WidgetTester tester,
  ) async {
    final service = _FakeMultiplayerService();
    await _entrarAlMapa(tester, multiplayer: service);
    await _completarTablero(tester);

    final bloc = tester
        .element(find.byKey(const ValueKey('celda-0-0')))
        .read<BoardBloc>();
    await tester.tap(find.byKey(const ValueKey('boton-estoy-listo')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    service.startGame(
      assignments: service.initialAssignments!,
      dice: const [1, 2],
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(bloc.state.isDiceRolled, isTrue);

    await tester.tap(find.byKey(const ValueKey('dado-0')));
    await tester.pump();
    final position = bloc.state.validPositions.first;
    final cell = find.byKey(ValueKey('celda-${position.x}-${position.y}'));
    await tester.ensureVisible(cell);
    await tester.tap(cell);
    await tester.pump();

    expect(bloc.state.movimientoPendiente, hasLength(1));
    expect(find.byKey(const ValueKey('boton-ya-puse-numero')), findsOneWidget);
    final undo = find.byKey(const ValueKey('boton-deshacer-jugada'));
    await tester.ensureVisible(undo);
    await tester.tap(undo);
    await tester.pump();
    expect(bloc.state.movimientoPendiente, isEmpty);

    await tester.ensureVisible(cell);
    await tester.tap(cell);
    await tester.pump();
    final confirm = find.byKey(const ValueKey('boton-ya-puse-numero'));
    await tester.ensureVisible(confirm);
    await tester.tap(confirm);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(service.confirmedMoves, hasLength(1));
    expect(bloc.state.turnoConfirmado, isTrue);
    expect(find.byKey(const ValueKey('esperando-jugador')), findsOneWidget);
    expect(find.byKey(const ValueKey('boton-deshacer-jugada')), findsNothing);

    service
      ..assignments = {...service.assignments, (position.x, position.y): 1}
      ..diceRollId = service.diceRollId + 1
      ..notifyListeners();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(bloc.state.turnoConfirmado, isFalse);
    expect(bloc.state.movimientoPendiente, isEmpty);
    expect(bloc.state.dados, [1, 2]);
  });

  testWidgets('muestra el panel de puntuación a la derecha en escritorio', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final service = _FakeMultiplayerService();
    await _entrarAlMapa(tester, multiplayer: service);
    service.startGame();
    await tester.pumpAndSettle();

    final tablero = tester.getRect(find.byType(AspectRatio).first);
    final dados = tester.getRect(find.byKey(const ValueKey('panel-dados')));
    final puntuacion = tester.getRect(
      find.byKey(const ValueKey('panel-puntuacion')),
    );
    expect(dados.left, greaterThan(tablero.right));
    expect(puntuacion.left, greaterThan(tablero.right));
  });

  testWidgets('los dados y puntuaciones visibles provienen del servidor', (
    WidgetTester tester,
  ) async {
    final service = _FakeMultiplayerService();
    await _entrarAlMapa(tester, multiplayer: service);
    service.startGame();
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('salir-mapa')), findsOneWidget);
    expect(find.byKey(const ValueKey('panel-puntuacion')), findsOneWidget);
    expect(find.byKey(const ValueKey('panel-dados')), findsOneWidget);
    expect(find.byKey(const ValueKey('marcador-pendiente')), findsNWidgets(6));
    expect(find.byKey(const ValueKey('celda-0-0')), findsOneWidget);
    expect(find.byKey(const ValueKey('celda-6-6')), findsOneWidget);
    expect(find.text('FILA 1  /  COLUMNA 3'), findsNothing);

    final bloc = tester
        .element(find.byKey(const ValueKey('celda-0-0')))
        .read<BoardBloc>();
    expect(bloc.state.dados, [2, 5]);
    expect(find.text('Prepara el tablero para empezar.'), findsOneWidget);

    service
      ..scores = const [
        PlayerScore(playerId: 'player-1', playerName: 'Ana', total: 15),
      ]
      ..dice = const [2, 5]
      ..notifyListeners();
    await tester.pumpAndSettle();

    expect(bloc.state.isDiceRolled, isTrue);
    expect(bloc.state.dados, [2, 5]);
    expect(find.byKey(const ValueKey('dado-0')), findsOneWidget);
    expect(find.byKey(const ValueKey('dado-1')), findsOneWidget);
    expect(find.text('Ana'), findsOneWidget);
    expect(find.text('15'), findsOneWidget);
    expect(find.byType(AnimatedSwitcher), findsNothing);
    expect(find.byKey(const ValueKey('puntuacion-total')), findsNothing);
  });
}

class _FakeMultiplayerService extends MultiplayerService {
  _FakeMultiplayerService() : super(serverUrl: 'ws://unused');

  Map<(int, int), int>? initialAssignments;
  final List<(int, int, int)> confirmedMoves = [];
  String? lastPlayerName;

  @override
  Future<void> createRoom({
    required int mapId,
    required String playerName,
  }) async {
    lastPlayerName = playerName;
    roomCode = 'Q7M4PX';
    playerId = 'player-1';
    this.mapId = mapId;
    players = [
      RoomPlayer(id: playerId!, name: playerName, ready: false),
      const RoomPlayer(id: 'player-2', name: 'Invitado', ready: false),
    ];
    notifyListeners();
  }

  @override
  Future<void> joinRoom({
    required String code,
    required String playerName,
  }) async {
    lastPlayerName = playerName;
    roomCode = code.toUpperCase();
    playerId = 'player-2';
    mapId = 0;
    players = const [
      RoomPlayer(id: 'player-1', name: 'Anfitrión', ready: false),
      RoomPlayer(id: 'player-2', name: 'Invitado', ready: false),
    ];
    notifyListeners();
  }

  @override
  Future<void> setReady(bool ready) async {
    players = [
      for (final player in players)
        RoomPlayer(
          id: player.id,
          name: player.name,
          ready: player.id == playerId ? ready : player.ready,
        ),
    ];
    notifyListeners();
  }

  void markAllPlayersReady() {
    players = [
      for (final player in players)
        RoomPlayer(id: player.id, name: player.name, ready: true),
    ];
    notifyListeners();
  }

  void startGame({
    Map<(int, int), int>? assignments,
    List<int> dice = const [2, 5],
  }) {
    gameStarted = true;
    this.assignments = assignments ?? this.assignments;
    this.dice = dice;
    diceRollId++;
    notifyListeners();
  }

  @override
  Future<void> submitInitialBoard(
    Map<(int, int), int> initialAssignments,
  ) async {
    this.initialAssignments = Map.of(initialAssignments);
    notifyListeners();
  }

  @override
  Future<void> placeNumber(int row, int column, int number) async {
    confirmedMoves.add((row, column, number));
  }
}

class _FakeAuthFunctionInvoker implements AuthFunctionInvoker {
  final List<Map<String, Object?>> bodies = [];
  Object? error;

  @override
  Future<AuthFunctionResponse> invoke(Map<String, Object?> body) async {
    bodies.add(Map<String, Object?>.of(body));
    if (error case final requestError?) {
      throw requestError;
    }
    return const AuthFunctionResponse(
      statusCode: 200,
      data: {
        'usuario_name': 'jugador_1',
        'session_token': 'test-token',
        'expires_at': '2030-01-01T00:00:00Z',
      },
    );
  }
}

class _FakeSessionTokenStorage implements SessionTokenStorage {
  @override
  Future<void> delete() async {}

  @override
  Future<String?> read() async => null;

  @override
  Future<void> save(String token) async {}
}
