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
          home: PaginaPrincipal(onLogout: onLogout ?? () async {}),
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
  await _abrirSeleccionMapas(tester, multiplayer: multiplayer);
  final tarjeta = find.byKey(ValueKey('mapa-card-$mapa'));
  await tester.ensureVisible(tarjeta);
  await tester.tap(tarjeta);
  await tester.pumpAndSettle();
  final preparar = find.byKey(const ValueKey('boton-preparar-tablero'));
  await tester.scrollUntilVisible(
    preparar,
    250,
    scrollable: find.byType(Scrollable).last,
  );
  await tester.tap(preparar);
  await tester.pumpAndSettle();
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
    var authenticated = false;

    await tester.pumpWidget(
      MaterialApp(
        home: AccesoPage(
          authService: AuthService(
            invoker: invoker,
            tokenStorage: _FakeSessionTokenStorage(),
          ),
          onOpenMaps: () {},
          onAuthenticated: () => authenticated = true,
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

    expect(authenticated, isTrue);
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
          onAuthenticated: () {},
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
    expect(find.textContaining('cada jugador preparará'), findsOneWidget);
    expect(find.byKey(const ValueKey('salir-mapa')), findsNothing);
  });

  testWidgets('el lobby permite preparar el tablero sin iniciar la partida', (
    WidgetTester tester,
  ) async {
    final service = _FakeMultiplayerService();
    await _abrirSeleccionMapas(tester, multiplayer: service);
    final tarjeta = find.byKey(const ValueKey('mapa-card-1'));
    await tester.ensureVisible(tarjeta);
    await tester.tap(tarjeta);
    await tester.pumpAndSettle();
    expect(find.text('Lobby'), findsOneWidget);

    final preparar = find.byKey(const ValueKey('boton-preparar-tablero'));
    await tester.scrollUntilVisible(
      preparar,
      250,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(preparar);
    await tester.pumpAndSettle();

    expect(service.initialAssignments, isNull);
    expect(service.gameStarted, isFalse);
    expect(find.text('Mapa de colores'), findsOneWidget);
    expect(find.byKey(const ValueKey('boton-estoy-listo')), findsNothing);
    expect(find.byKey(const ValueKey('volver-lobby')), findsOneWidget);
  });

  testWidgets('se puede volver al lobby antes de confirmar listo', (
    WidgetTester tester,
  ) async {
    final service = _FakeMultiplayerService();
    await _entrarAlMapa(tester, multiplayer: service);

    await tester.tap(find.byKey(const ValueKey('volver-lobby')));
    await tester.pumpAndSettle();

    expect(find.text('Lobby'), findsOneWidget);
    expect(service.gameStarted, isFalse);
    expect(service.initialAssignments, isNull);
  });

  testWidgets('seis números permiten enviar listo, pero no generan dados', (
    WidgetTester tester,
  ) async {
    final service = _FakeMultiplayerService();
    await _entrarAlMapa(tester, multiplayer: service);

    final bloc = tester
        .element(find.byKey(const ValueKey('celda-0-0')))
        .read<BoardBloc>();
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

    expect(bloc.state.completo, isTrue);
    expect(bloc.state.listoParaJugar, isFalse);
    expect(service.initialAssignments, isNull);
    expect(find.byKey(const ValueKey('boton-estoy-listo')), findsOneWidget);

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
    expect(bloc.state.dados, isEmpty);
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
    expect(find.byType(AnimatedSwitcher), findsNWidgets(2));
    expect(find.byKey(const ValueKey('puntuacion-total')), findsNothing);
  });
}

class _FakeMultiplayerService extends MultiplayerService {
  _FakeMultiplayerService() : super(serverUrl: 'ws://unused');

  Map<(int, int), int>? initialAssignments;

  @override
  Future<void> createRoom({
    required int mapId,
    required String playerName,
  }) async {
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
    roomCode = code.toUpperCase();
    playerId = 'player-2';
    mapId = 0;
    notifyListeners();
  }

  void startGame() {
    gameStarted = true;
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
    assignments = {...assignments, (row, column): number};
    dice = const [2, 5];
    notifyListeners();
  }

  @override
  Future<void> skipTurn() async {
    dice = const [2, 5];
    notifyListeners();
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
