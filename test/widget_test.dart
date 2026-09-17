import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:health_companion/main.dart';
import 'package:health_companion/core/state/app_state.dart';
import 'package:health_companion/core/widgets/floating_bottom_nav.dart';
import 'package:health_companion/core/services/auth_service.dart';
import 'package:health_companion/features/auth/screens/sign_in_screen.dart';
import 'package:health_companion/features/auth/screens/sign_up_screen.dart';

class _TestHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return _MockHttpClient();
  }
}

class _MockHttpClient implements HttpClient {
  @override
  bool autoUncompress = true;
  @override
  Duration? connectionTimeout;
  @override
  Duration idleTimeout = const Duration(seconds: 15);
  @override
  int? maxConnectionsPerHost;
  @override
  String? userAgent;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<HttpClientRequest> getUrl(Uri url) async {
    return _MockHttpClientRequest();
  }
}

class _MockHttpClientRequest implements HttpClientRequest {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  HttpHeaders get headers => _MockHttpHeaders();

  @override
  Future<HttpClientResponse> close() async {
    return _MockHttpClientResponse();
  }
}

class _MockHttpHeaders implements HttpHeaders {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
  @override
  void add(String name, Object value, {bool preserveHeaderCase = false}) {}
  @override
  void set(String name, Object value, {bool preserveHeaderCase = false}) {}
}

class _MockHttpClientResponse implements HttpClientResponse {
  static final List<int> _kTransparentImage = <int>[
    0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D,
    0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
    0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00,
    0x0A, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
    0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49,
    0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
  ];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  int get statusCode => 200;

  @override
  int get contentLength => _kTransparentImage.length;

  @override
  HttpClientResponseCompressionState get compressionState =>
      HttpClientResponseCompressionState.notCompressed;

  @override
  HttpHeaders get headers => _MockHttpHeaders();

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return Stream<List<int>>.value(_kTransparentImage).listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }
}

Future<void> _pumpFrames(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}

void main() {
  setUpAll(() {
    HttpOverrides.global = _TestHttpOverrides();
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('Create account lands on personal home profile', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final appState = AppState();
    await tester.pumpWidget(
      MaterialApp(
        home: ListenableBuilder(
          listenable: appState,
          builder: (context, _) {
            if (!appState.isSignedIn) {
              return SignInScreen(appState: appState);
            }
            return HealthCompanionShell(appState: appState);
          },
        ),
      ),
    );
    await _pumpFrames(tester);

    await tester.tap(find.text('Create New Account'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(SignUpScreen), findsOneWidget);
    final fields = find.descendant(
      of: find.byType(SignUpScreen),
      matching: find.byType(TextFormField),
    );
    expect(fields, findsNWidgets(4));
    await tester.enterText(fields.at(0), 'Alex Rivera');
    await tester.enterText(fields.at(1), 'alex.rivera@gmail.com');
    await tester.enterText(fields.at(2), 'secret12');
    await tester.enterText(fields.at(3), 'secret12');

    final createBtn = find.descendant(
      of: find.byType(SignUpScreen),
      matching: find.widgetWithText(ElevatedButton, 'Create Account'),
    );
    await tester.ensureVisible(createBtn);
    await tester.tap(createBtn);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 900));
    await _pumpFrames(tester);

    expect(appState.isSignedIn, isTrue);
    expect(appState.userName, 'Alex Rivera');
    expect(find.byType(SignUpScreen), findsNothing);
    expect(find.textContaining('Alex'), findsWidgets);
    expect(find.textContaining('Sarah'), findsNothing);
    expect(find.text('Ask Health AI'), findsOneWidget);
  });

  testWidgets('Sign in rejects unknown email', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final appState = AppState();
    await tester.pumpWidget(
      MaterialApp(home: SignInScreen(appState: appState)),
    );
    await _pumpFrames(tester);

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'nobody@gmail.com');
    await tester.enterText(fields.at(1), 'whatever');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Sign In'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.textContaining('No account found'), findsOneWidget);
  });

  testWidgets('Tapping bottom navigation switches tabs cleanly', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final appState = AppState();
    await appState.register(
      fullName: 'Jordan Lee',
      email: 'jordan.lee@gmail.com',
      password: 'pass1234',
    );

    await tester.pumpWidget(
      MaterialApp(home: HealthCompanionShell(appState: appState)),
    );
    await _pumpFrames(tester);

    expect(find.textContaining('Jordan'), findsWidgets);

    await tester.tap(find.descendant(
      of: find.byType(FloatingBottomNav),
      matching: find.byIcon(Icons.auto_stories_rounded),
    ));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.textContaining('feeling today'), findsOneWidget);

    await tester.tap(find.descendant(
      of: find.byType(FloatingBottomNav),
      matching: find.byIcon(Icons.favorite_rounded),
    ));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Lab Report Interpreter'), findsOneWidget);
    expect(find.text('No reports yet'), findsOneWidget);

    await tester.tap(find.descendant(
      of: find.byType(FloatingBottomNav),
      matching: find.byIcon(Icons.calendar_month_rounded),
    ));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Upcoming'), findsOneWidget);
  });

  test('AuthService isolates accounts by email', () async {
    final auth = AuthService();
    final a = await auth.register(
      fullName: 'User One',
      email: 'one@gmail.com',
      password: 'pass123',
    );
    final b = await auth.register(
      fullName: 'User Two',
      email: 'two@gmail.com',
      password: 'pass456',
    );
    expect(a.id, isNot(b.id));

    final signed = await auth.signIn(email: 'two@gmail.com', password: 'pass456');
    expect(signed.fullName, 'User Two');

    expect(
      () => auth.signIn(email: 'one@gmail.com', password: 'wrong'),
      throwsA(isA<AuthException>()),
    );
  });
}
