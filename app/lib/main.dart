import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'features/lesson_kit/data/datasources/gemma_lesson_kit_datasource.dart';
import 'features/lesson_kit/presentation/providers/lesson_kit_providers.dart';
import 'features/settings/presentation/providers/settings_provider.dart';
import 'features/student_help/data/gemma_student_help_service.dart';
import 'features/student_help/presentation/providers/student_help_providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // flutter_gemma needs a one-time initialization. We're loading models
  // from local file (not HuggingFace), so no token is required.
  await FlutterGemma.initialize(maxDownloadRetries: 3);

  runApp(
    ProviderScope(
      overrides: [
        lessonKitDatasourceProvider.overrideWith(
          (ref) => GemmaLessonKitDatasource(
            settingsReader: () => ref.read(settingsProvider).modelSettings,
          ),
        ),
        studentHelpServiceProvider.overrideWith(
          (ref) => GemmaStudentHelpService(
            settingsReader: () => ref.read(settingsProvider).modelSettings,
          ),
        ),
      ],
      child: const ChalkLensApp(),
    ),
  );
}

class ChalkLensApp extends ConsumerWidget {
  const ChalkLensApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(settingsProvider.select((s) => s.themeMode));

    return MaterialApp.router(
      title: 'ChalkLens',
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      routerConfig: ref.watch(appRouterProvider),
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        final platformBrightness = MediaQuery.platformBrightnessOf(context);
        final brightness = switch (themeMode) {
          ThemeMode.light => Brightness.light,
          ThemeMode.dark => Brightness.dark,
          ThemeMode.system => platformBrightness,
        };

        return CupertinoTheme(
          data: AppTheme.cupertino(brightness: brightness),
          child: DefaultTextStyle(
            style: TextStyle(
              color: AppColors.inkOf(brightness),
              fontSize: 16,
              decoration: TextDecoration.none,
            ),
            child: child ?? const SizedBox.shrink(),
          ),
        );
      },
    );
  }
}
