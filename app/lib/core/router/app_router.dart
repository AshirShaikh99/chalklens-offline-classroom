import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/home/presentation/pages/home_page.dart';
import '../../features/lesson_kit/presentation/pages/lesson_kit_page.dart';
import '../../features/lesson_kit/presentation/pages/scan_page.dart';
import '../../features/model_setup/presentation/pages/model_setup_page.dart';
import '../../features/model_setup/presentation/providers/model_setup_provider.dart';
import '../../features/saved_lessons/presentation/pages/saved_lessons_page.dart';
import '../../features/splash/presentation/pages/splash_page.dart';
import '../../features/settings/presentation/pages/settings_page.dart';
import '../../features/student_help/presentation/pages/student_help_page.dart';
import '../theme/app_colors.dart';

/// Centralized route names. Pages and navigation calls should refer to
/// these constants — never raw path strings — so renames are safe.
class AppRoute {
  const AppRoute._();

  static const String splash = 'splash';
  static const String home = 'home';
  static const String modelSetup = 'modelSetup';
  static const String scan = 'scan';
  static const String lessonKit = 'lessonKit';
  static const String savedLessons = 'savedLessons';
  static const String studentHelp = 'studentHelp';
  static const String settings = 'settings';
}

/// Locations that don't require a ready model — splash because that's where
/// we decide, model-setup because that's where the user fixes a missing one.
const Set<String> _modelOptionalLocations = {'/splash', '/model-setup'};

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      final loc = state.matchedLocation;
      if (_modelOptionalLocations.contains(loc)) return null;
      final setup = ref.read(modelSetupProvider);
      // Don't redirect while we're still inspecting the model file — splash
      // owns the loading screen.
      final ready = setup.maybeWhen(
        data: (s) => s.isReady,
        orElse: () => true,
      );
      if (ready) return null;
      return '/model-setup';
    },
    errorBuilder: (context, state) => _NotFoundPage(uri: state.uri.toString()),
    routes: [
      GoRoute(
        path: '/splash',
        name: AppRoute.splash,
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: '/model-setup',
        name: AppRoute.modelSetup,
        builder: (context, state) => const ModelSetupPage(),
      ),
      GoRoute(
        path: '/',
        name: AppRoute.home,
        builder: (context, state) => const HomePage(),
      ),
      GoRoute(
        path: '/scan',
        name: AppRoute.scan,
        builder: (context, state) => const ScanPage(),
      ),
      GoRoute(
        path: '/lesson',
        name: AppRoute.lessonKit,
        builder: (context, state) => const LessonKitPage(),
      ),
      GoRoute(
        path: '/saved',
        name: AppRoute.savedLessons,
        builder: (context, state) => const SavedLessonsPage(),
      ),
      GoRoute(
        path: '/help',
        name: AppRoute.studentHelp,
        builder: (context, state) => const StudentHelpPage(),
      ),
      GoRoute(
        path: '/settings',
        name: AppRoute.settings,
        builder: (context, state) => const SettingsPage(),
      ),
    ],
  );
});

class _NotFoundPage extends StatelessWidget {
  const _NotFoundPage({required this.uri});

  final String uri;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Scaffold(
      backgroundColor: tokens.canvas,
      appBar: AppBar(title: const Text('Page not found')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'No page at $uri',
                textAlign: TextAlign.center,
                style: TextStyle(color: tokens.ink, fontSize: 18),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => context.goNamed(AppRoute.home),
                child: const Text('Back to home'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
