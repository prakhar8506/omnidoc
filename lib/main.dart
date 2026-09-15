import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/app_colors.dart';
import 'core/state/app_state.dart';
import 'core/widgets/glass_app_bar.dart';
import 'core/widgets/floating_bottom_nav.dart';
import 'core/widgets/quick_action_sheet.dart';
import 'features/home/screens/home_screen.dart';
import 'features/journal/screens/journal_feeling_screen.dart';
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
      systemNavigationBarIconBrightness: Brightness.dark,
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
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFFBF6FC),
              Color(0xFFFDE8EF),
              Color(0xFFEDEAFE),
            ],
          ),
        ),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.spa_rounded, size: 52, color: AppColors.primaryContainer),
              SizedBox(height: 16),
              Text(
                'Health Companion',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.3,
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
        return 'Daily Balance';
      case 1:
        return "Feeling Journal";
      case 2:
        return 'Symptom Triage';
      case 3:
        return 'Appointments & Fitness';
      case 4:
        return 'Biology & Labs';
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
          JournalFeelingScreen(appState: appState),
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
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFFAF6FC),
                  Color(0xFFFDF1F5),
                  Color(0xFFF1EEFE),
                  Color(0xFFFAF7FD),
                ],
              ),
            ),
            child: Stack(
              children: [
                IndexedStack(
                  index: currentTab.clamp(0, screens.length - 1),
                  children: screens,
                ),
                if (currentTab != 1) // Hidden on feeling journal screen for serene feeling dial focus
                  Positioned(
                    right: 18,
                    bottom: 96,
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
                      onCenterAction: () => QuickActionSheet.show(context, appState),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
