import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/branding/app_brand.dart';
import 'core/env/app_env.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/app_colors.dart';
import 'core/state/app_state.dart';
import 'core/localization/app_localizations.dart';
import 'core/widgets/glass_app_bar.dart';
import 'core/widgets/floating_bottom_nav.dart';
import 'core/widgets/quick_action_sheet.dart';
import 'core/widgets/holographic_background.dart';
import 'features/splash/screens/splash_screen.dart';
import 'features/home/screens/home_screen.dart';
import 'features/journal/screens/journal_feeling_screen.dart';
import 'features/triage/screens/triage_screen.dart';
import 'features/appointments/screens/appointments_screen.dart';
import 'features/lab_reports/screens/lab_reports_screen.dart';
import 'features/ai_assistant/widgets/floating_ai_button.dart';
import 'features/auth/screens/sign_in_screen.dart';
import 'features/onboarding/screens/onboarding_baseline_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kReleaseMode) {
    AppEnv.validateRequired();
  }

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

  Future<void> start() async {
    runApp(const HealthCompanionApp());
  }

  if (AppEnv.sentryDsn.isNotEmpty) {
    await SentryFlutter.init(
      (options) {
        options.dsn = AppEnv.sentryDsn;
        options.environment = kReleaseMode ? 'production' : 'debug';
        options.tracesSampleRate = 0.2;
      },
      appRunner: start,
    );
  } else {
    await start();
  }
}

class HealthCompanionApp extends StatefulWidget {
  const HealthCompanionApp({super.key});

  @override
  State<HealthCompanionApp> createState() => _HealthCompanionAppState();
}

class _HealthCompanionAppState extends State<HealthCompanionApp> {
  late final AppState _appState;
  bool _splashCompleted = false;
  StreamSubscription<Uri>? _linkSub;

  @override
  void initState() {
    super.initState();
    _appState = AppState();
    _appState.hydrate();
    _initDeepLinks();
  }

  Future<void> _initDeepLinks() async {
    try {
      final appLinks = AppLinks();
      final initial = await appLinks.getInitialLink();
      if (initial != null) {
        await _handleAuthDeepLink(initial);
      }
      _linkSub = appLinks.uriLinkStream.listen(_handleAuthDeepLink);
    } catch (e) {
      debugPrint('[Cura] deep link init failed: $e');
    }
  }

  Future<void> _handleAuthDeepLink(Uri uri) async {
    if (uri.scheme != AppBrand.deepLinkScheme) return;
    try {
      await Supabase.instance.client.auth.getSessionFromUrl(uri);
      await _appState.hydrate();
    } catch (e) {
      debugPrint('[Cura] auth deep link failed: $e');
    }
  }

  @override
  void dispose() {
    _linkSub?.cancel();
    _appState.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _appState,
      builder: (context, _) {
        return MaterialApp(
          title: AppBrand.name,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          locale: _appState.currentLocale,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: AnimatedSwitcher(
            duration: const Duration(milliseconds: 500),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            child: (!_splashCompleted || _appState.isHydrating)
                ? SplashScreen(
                    key: const ValueKey('splash_screen'),
                    onComplete: () {
                      if (mounted) {
                        setState(() {
                          _splashCompleted = true;
                        });
                      }
                    },
                  )
                : (!_appState.isSignedIn)
                    ? SignInScreen(
                        key: const ValueKey('sign_in_screen'),
                        appState: _appState,
                      )
                    : (!_appState.isOnboardingBaselineCompleted)
                        ? OnboardingBaselineScreen(
                            key: const ValueKey('onboarding_baseline'),
                            appState: _appState,
                          )
                        : HealthCompanionShell(
                            key: const ValueKey('shell_screen'),
                            appState: _appState,
                          ),
          ),
        );
      },
    );
  }
}

class HealthCompanionShell extends StatelessWidget {
  final AppState appState;

  const HealthCompanionShell({
    super.key,
    required this.appState,
  });

  String _getSubTitle(BuildContext context, int tabIndex) {
    final loc = AppLocalizations.of(context);
    switch (tabIndex) {
      case 0:
        return loc.translate('daily_balance');
      case 1:
        return loc.translate('feeling_tracker');
      case 2:
        return 'Symptom Triage';
      case 3:
        return 'Appointments & Fitness';
      case 4:
        return 'Biology & Labs';
      default:
        return AppBrand.tagline;
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
            title: AppBrand.name,
            subtitle: _getSubTitle(context, currentTab),
            appState: appState,
          ),
          body: HolographicBackground(
            child: Stack(
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 240),
                  layoutBuilder: (Widget? currentChild, List<Widget> previousChildren) {
                    return Stack(
                      fit: StackFit.expand,
                      children: <Widget>[
                        ...previousChildren.map((w) => IgnorePointer(child: w)),
                        if (currentChild != null) currentChild,
                      ],
                    );
                  },
                  transitionBuilder: (child, animation) {
                    final keyVal = (child.key is ValueKey<int>)
                        ? (child.key as ValueKey<int>).value
                        : null;
                    final isCurrent = keyVal == currentTab;

                    if (isCurrent) {
                      final inFade = CurvedAnimation(
                        parent: animation,
                        curve: const Interval(0.25, 1.0, curve: Curves.easeOutCubic),
                      );
                      final inSlide = Tween<Offset>(
                        begin: const Offset(0.015, 0.0),
                        end: Offset.zero,
                      ).animate(inFade);

                      return FadeTransition(
                        opacity: inFade,
                        child: SlideTransition(
                          position: inSlide,
                          child: child,
                        ),
                      );
                    } else {
                      final outFade = CurvedAnimation(
                        parent: animation,
                        curve: const Interval(0.75, 1.0, curve: Curves.easeInQuad),
                      );
                      return FadeTransition(
                        opacity: outFade,
                        child: child,
                      );
                    }
                  },
                  child: KeyedSubtree(
                    key: ValueKey<int>(currentTab),
                    child: screens[currentTab.clamp(0, screens.length - 1)],
                  ),
                ),
                if (currentTab != 1)
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
