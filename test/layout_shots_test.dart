import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:health_companion/core/state/app_state.dart';
import 'package:health_companion/core/theme/app_theme.dart';
import 'package:health_companion/features/consent/screens/permission_center_screen.dart';
import 'package:health_companion/features/journal/screens/journal_feeling_screen.dart';
import 'package:health_companion/features/onboarding/screens/health_intake_screen.dart';
import 'package:health_companion/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _shoot(WidgetTester tester, String name) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 200));
  final boundary = tester.renderObject<RenderRepaintBoundary>(find.byKey(const Key('shot')));
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 2);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    await File('/tmp/cura_$name.png').writeAsBytes(data!.buffer.asUint8List());
  });
}

void main() {
  setUp(() {
    HttpOverrides.global = null;
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('capture home fitness biology intake', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);

    final appState = AppState();
    await appState.register(
      fullName: 'Ramakrishnan Menon',
      email: 'rama@gmail.com',
      password: 'pass1234',
    );
    appState.healthIntakeCompleted = true;

    Future<void> pumpShell() async {
      await tester.pumpWidget(
        RepaintBoundary(
          key: const Key('shot'),
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: appState.useDarkMode ? ThemeMode.dark : ThemeMode.light,
            home: HealthCompanionShell(appState: appState),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
    }

    await pumpShell();
    await _shoot(tester, 'home_top');

    final scroll = find.byType(Scrollable).first;
    await tester.drag(scroll, const Offset(0, -900));
    await tester.pump(const Duration(milliseconds: 200));
    await _shoot(tester, 'home_mid');

    await tester.drag(scroll, const Offset(0, -1400));
    await tester.pump(const Duration(milliseconds: 200));
    await _shoot(tester, 'home_bottom');

    appState.setTabIndex(3);
    await tester.pump(const Duration(milliseconds: 300));
    await _shoot(tester, 'fitness');

    appState.setTabIndex(4);
    await tester.pump(const Duration(milliseconds: 300));
    await _shoot(tester, 'biology');

    appState.setBiologySegment(1);
    await tester.pump(const Duration(milliseconds: 300));
    await _shoot(tester, 'visits');

    appState.useDarkMode = true;
    appState.setTabIndex(0);
    await pumpShell();
    await _shoot(tester, 'dark_home');

    await tester.pumpWidget(
      RepaintBoundary(
        key: const Key('shot'),
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          home: HealthIntakeScreen(appState: appState),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 200));
    await _shoot(tester, 'intake');

    await tester.pumpWidget(
      RepaintBoundary(
        key: const Key('shot'),
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          home: PermissionCenterScreen(appState: appState),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 200));
    await _shoot(tester, 'permissions');

    await tester.pumpWidget(
      RepaintBoundary(
        key: const Key('shot'),
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          home: JournalFeelingScreen(appState: appState),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 200));
    await _shoot(tester, 'journal');
  });
}
