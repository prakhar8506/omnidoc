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
  final AppState _appState = AppState();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Health Companion',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: ListenableBuilder(
        listenable: _appState,
        builder: (context, _) {
          // Conditional: sign in screen or main app shell
          if (!_appState.isSignedIn) {
            return SignInScreen(appState: _appState);
          }
          return HealthCompanionShell(appState: _appState);
        },
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
              // Active Tab Content
              IndexedStack(
                index: currentTab,
                children: screens,
              ),

              // Omnipresent Floating AI Button
              Positioned(
                right: 20,
                bottom: 100,
                child: FloatingAiButton(appState: appState),
              ),

              // Floating Bottom Navigation Pill
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
