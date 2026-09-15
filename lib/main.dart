import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/app_colors.dart';
import 'core/state/app_state.dart';
import 'core/widgets/glass_app_bar.dart';
import 'core/widgets/floating_bottom_nav.dart';
import 'features/home/screens/home_screen.dart';
import 'features/triage/screens/triage_screen.dart';
import 'features/appointments/screens/appointments_screen.dart';
import 'features/lab_reports/screens/lab_reports_screen.dart';
import 'features/ai_assistant/widgets/floating_ai_button.dart';
import 'features/auth/screens/sign_in_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.transparent,
    ),
  );
  runApp(const HealthCompanionApp());
}

class HealthCompanionApp extends StatefulWidget {
  const HealthCompanionApp({super.key});

  @override
  State<HealthCompanionApp> createState() => _HealthCompanionAppState();
}

class _HealthCompanionAppState extends State<HealthCompanionApp> {
  late final AppState _appState;

  @override
  void initState() {
    super.initState();
    _appState = AppState();
    _appState.hydrate();
  }

  @override
  void dispose() {
    _appState.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Health Companion',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: ListenableBuilder(
        listenable: _appState,
        builder: (context, _) {
          if (_appState.isHydrating) {
            return const _SplashGate();
          }
          if (!_appState.isSignedIn) {
            return SignInScreen(appState: _appState);
          }
          return HealthCompanionShell(appState: _appState);
        },
      ),
    );
  }
}

class _SplashGate extends StatelessWidget {
  const _SplashGate();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.surface,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add_rounded, size: 48, color: AppColors.primaryContainer),
            SizedBox(height: 16),
            Text(
              'Health Companion',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 24),
            SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: AppColors.primaryContainer,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class HealthCompanionShell extends StatelessWidget {
  final AppState appState;

  const HealthCompanionShell({
    super.key,
    required this.appState,
  });

  String _getSubTitle(int tabIndex) {
    switch (tabIndex) {
      case 0:
        return 'Home';
      case 1:
        return 'Triage & Care';
      case 2:
        return 'Appointments & Family';
      case 3:
        return 'Lab Analysis';
      default:
        return 'Health Companion';
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        final currentTab = appState.currentTabIndex;

        final screens = [
          HomeScreen(appState: appState),
          TriageScreen(appState: appState),
          AppointmentsScreen(appState: appState),
          LabReportsScreen(appState: appState),
        ];

        return Scaffold(
          extendBody: true,
          backgroundColor: AppColors.background,
          appBar: GlassAppBar(
            title: 'Health Companion',
            subtitle: _getSubTitle(currentTab),
            appState: appState,
          ),
          body: Stack(
            children: [
              IndexedStack(
                index: currentTab,
                children: screens,
              ),
              Positioned(
                right: 20,
                bottom: 100,
                child: FloatingAiButton(appState: appState),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: SafeArea(
                  child: FloatingBottomNav(
                    currentIndex: currentTab,
                    onTabSelected: (index) => appState.setTabIndex(index),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
