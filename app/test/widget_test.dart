import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chalk_lens/core/model/gemma_model_installer.dart';
import 'package:chalk_lens/features/model_setup/presentation/providers/model_setup_provider.dart';
import 'package:chalk_lens/main.dart';

void main() {
  testWidgets('App boots through splash and renders home', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [modelSetupProvider.overrideWith(_ReadySetup.new)],
        child: const ChalkLensApp(),
      ),
    );

    expect(find.text('Clear lessons for every classroom.'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 1500));
    await tester.pumpAndSettle();

    expect(find.text('Start with\nthe page.'), findsOneWidget);
  });

  testWidgets('MaterialApp.router is wired', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [modelSetupProvider.overrideWith(_ReadySetup.new)],
        child: const ChalkLensApp(),
      ),
    );

    expect(find.byType(MaterialApp), findsOneWidget);
  });
}

class _ReadySetup extends ModelSetupNotifier {
  @override
  Future<ModelSetupState> build() async {
    return const ModelSetupState(
      check: ModelFileCheck(
        status: ModelFileStatus.ready,
        path: 'test-model',
        expectedSizeBytes: 1,
        expectedSha256: 'test',
        sizeBytes: 1,
        sha256Digest: 'test',
      ),
      runtimeReady: true,
    );
  }
}
