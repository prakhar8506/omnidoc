import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:health_companion/main.dart';
import 'package:health_companion/core/widgets/floating_bottom_nav.dart';

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
  void addAuthenticate(Uri url, String realm, HttpClientCredentials credentials) {}
  @override
  void addCredentials(Uri url, String realm, HttpClientCredentials credentials) {}
  @override
  void close({bool force = false}) {}
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
  Stream<List<int>> asBroadcastStream({
    void Function(StreamSubscription<List<int>> subscription)? onListen,
    void Function(StreamSubscription<List<int>> subscription)? onCancel,
  }) {
    return Stream<List<int>>.value(_kTransparentImage).asBroadcastStream(
      onListen: onListen,
      onCancel: onCancel,
    );
  }

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

void main() {
  setUpAll(() {
    HttpOverrides.global = _TestHttpOverrides();
  });

  testWidgets('HealthCompanionApp renders shell and initial home screen', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const HealthCompanionApp());
    await tester.pump(const Duration(milliseconds: 100));

    // Verify GlassAppBar title
    expect(find.text('Health Companion'), findsOneWidget);

    // Verify Greeting
    expect(find.text('Good morning, Sarah'), findsOneWidget);

    // Verify Omnipresent Floating AI Button
    expect(find.text('Ask Health AI'), findsOneWidget);

    // Verify Navigation Bar items
    expect(find.descendant(of: find.byType(FloatingBottomNav), matching: find.byIcon(Icons.dashboard_rounded)), findsOneWidget);
    expect(find.descendant(of: find.byType(FloatingBottomNav), matching: find.byIcon(Icons.healing_rounded)), findsOneWidget);
    expect(find.descendant(of: find.byType(FloatingBottomNav), matching: find.byIcon(Icons.calendar_month_rounded)), findsOneWidget);
    expect(find.descendant(of: find.byType(FloatingBottomNav), matching: find.byIcon(Icons.analytics_outlined)), findsOneWidget);
  });

  testWidgets('Tapping bottom navigation switches tabs cleanly', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const HealthCompanionApp());
    await tester.pump(const Duration(milliseconds: 100));

    // Tap Triage tab icon inside FloatingBottomNav
    final triageNavBtn = find.descendant(of: find.byType(FloatingBottomNav), matching: find.byIcon(Icons.healing_rounded));
    await tester.tap(triageNavBtn);
    await tester.pump(const Duration(milliseconds: 300));

    // Verify Triage Screen is active
    expect(find.text('Symptom Triage Assistant'), findsOneWidget);
    expect(find.text('Safe Home Self-Care Guidance'), findsOneWidget);

    // Tap Labs tab icon inside FloatingBottomNav
    final labsNavBtn = find.descendant(of: find.byType(FloatingBottomNav), matching: find.byIcon(Icons.analytics_outlined));
    await tester.tap(labsNavBtn);
    await tester.pump(const Duration(milliseconds: 300));

    // Verify Lab Reports Screen
    expect(find.text('Lab Report Interpreter'), findsOneWidget);
    expect(find.text('Biomarker Breakdown'), findsOneWidget);

    // Tap Visits tab icon inside FloatingBottomNav
    final visitsNavBtn = find.descendant(of: find.byType(FloatingBottomNav), matching: find.byIcon(Icons.calendar_month_rounded));
    await tester.tap(visitsNavBtn);
    await tester.pump(const Duration(milliseconds: 300));

    // Verify Appointments Screen
    expect(find.text('Upcoming Visits'), findsOneWidget);
  });
}
