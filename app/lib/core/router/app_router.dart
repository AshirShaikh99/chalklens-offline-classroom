import 'package:go_router/go_router.dart';

import '../../features/home/presentation/pages/home_page.dart';
import '../../features/lesson_kit/presentation/pages/lesson_kit_page.dart';
import '../../features/lesson_kit/presentation/pages/scan_page.dart';
import '../../features/model_setup/presentation/pages/model_setup_page.dart';
import '../../features/saved_lessons/presentation/pages/saved_lessons_page.dart';
import '../../features/splash/presentation/pages/splash_page.dart';
import '../../features/settings/presentation/pages/settings_page.dart';
import '../../features/student_help/presentation/pages/student_help_page.dart';

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

final GoRouter appRouter = GoRouter(
  initialLocation: '/splash',
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
