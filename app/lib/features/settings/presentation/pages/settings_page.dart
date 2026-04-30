import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/languages.dart';
import '../../../../core/model/gemma_generation_settings.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/adaptive_components.dart';
import '../../../../core/widgets/soft_reveal.dart';
import '../providers/settings_provider.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);

    return AdaptivePageScaffold(
      title: 'Settings',
      onBack: () => context.goNamed(AppRoute.home),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 760;
          return ListView(
            padding: EdgeInsets.fromLTRB(
              isWide ? 40 : 20,
              14,
              isWide ? 40 : 20,
              44,
            ),
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 920),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SoftReveal(child: _SettingsIntro()),
                      const SizedBox(height: 30),
                      SoftReveal(
                        delay: const Duration(milliseconds: 80),
                        child: _SettingsGroup(
                          isWide: isWide,
                          title: 'Lesson defaults',
                          summary: 'Used when a new lesson starts.',
                          children: [
                            AdaptiveSelectField<AppLanguage>(
                              label: 'Output language',
                              value: settings.defaultLanguage,
                              items: AppLanguage.primaryTeachingLanguages,
                              labelOf: (l) => '${l.label}  ·  ${l.native}',
                              onChanged: (v) {
                                if (v != null) notifier.setLanguage(v);
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      SoftReveal(
                        delay: const Duration(milliseconds: 140),
                        child: _SettingsGroup(
                          isWide: isWide,
                          title: 'Model',
                          summary: 'Local inference and model storage.',
                          children: [
                            const _Row(
                              label: 'Inference',
                              value: 'On-device Gemma 4 E2B · LiteRT-LM',
                            ),
                            const _Divider(),
                            const _Row(
                              label: 'Model file',
                              value:
                                  'Stored in app documents; removed if app is deleted',
                            ),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(0, 10, 0, 12),
                              child: AdaptiveSecondaryButton(
                                onPressed: () =>
                                    context.goNamed(AppRoute.modelSetup),
                                label: 'Manage model',
                                icon: AppIcons.download(context),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      SoftReveal(
                        delay: const Duration(milliseconds: 200),
                        child: _SettingsGroup(
                          isWide: isWide,
                          title: 'Model behavior',
                          summary: 'Generation controls for lesson output.',
                          children: [
                            _Row(
                              label: 'Response profile',
                              value: settings.modelSettings.responseProfile,
                            ),
                            const _Divider(),
                            _ModelSlider(
                              label: 'Temperature',
                              valueLabel: settings.modelSettings.temperature
                                  .toStringAsFixed(1),
                              value: settings.modelSettings.temperature,
                              min: 0.1,
                              max: 1.5,
                              divisions: 14,
                              onChanged: notifier.setTemperature,
                            ),
                            const _Divider(),
                            _ModelSlider(
                              label: 'Top K',
                              valueLabel: settings.modelSettings.topK
                                  .toString(),
                              value: settings.modelSettings.topK.toDouble(),
                              min: 1,
                              max: 128,
                              divisions: 127,
                              onChanged: (v) => notifier.setTopK(v.round()),
                            ),
                            const _Divider(),
                            _ModelSlider(
                              label: 'Top P',
                              valueLabel: settings.modelSettings.topP
                                  .toStringAsFixed(2),
                              value: settings.modelSettings.topP,
                              min: 0.50,
                              max: 1.00,
                              divisions: 50,
                              onChanged: notifier.setTopP,
                            ),
                            const _Divider(),
                            _ModelSlider(
                              label: 'Seed',
                              valueLabel: settings.modelSettings.randomSeed
                                  .toString(),
                              value: settings.modelSettings.randomSeed
                                  .toDouble(),
                              min: 1,
                              max: 99,
                              divisions: 98,
                              onChanged: (v) =>
                                  notifier.setRandomSeed(v.round()),
                            ),
                            const _Divider(),
                            _SwitchRow(
                              label: 'Thinking mode',
                              value: settings.modelSettings.thinkingMode
                                  ? 'On'
                                  : 'Off',
                              enabled: settings.modelSettings.thinkingMode,
                              onChanged: notifier.setThinkingMode,
                            ),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(0, 10, 0, 12),
                              child: AdaptiveSecondaryButton(
                                onPressed:
                                    settings.modelSettings ==
                                        GemmaGenerationSettings.defaults
                                    ? null
                                    : notifier.resetModelSettings,
                                label: 'Reset model settings',
                                icon: AppIcons.refresh(context),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      SoftReveal(
                        delay: const Duration(milliseconds: 260),
                        child: _SettingsGroup(
                          isWide: isWide,
                          title: 'Voice',
                          summary: 'Planned audio support.',
                          children: const [
                            _Row(
                              label: 'Student voice questions',
                              value: 'Planned',
                            ),
                            _Divider(),
                            _Row(
                              label: 'Gemma 4 audio input',
                              value: 'Model-ready',
                            ),
                            _Divider(),
                            _Row(label: 'Spoken answers', value: 'Roadmap'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      SoftReveal(
                        delay: const Duration(milliseconds: 320),
                        child: _SettingsGroup(
                          isWide: isWide,
                          title: 'Appearance',
                          summary: 'Black is the default app surface.',
                          children: [
                            _Row(
                              label: 'Theme',
                              value: _themeLabel(settings.themeMode),
                            ),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(0, 12, 0, 4),
                              child: AdaptiveSegmentedControl<ThemeMode>(
                                value: settings.themeMode,
                                values: const [
                                  ThemeMode.dark,
                                  ThemeMode.system,
                                  ThemeMode.light,
                                ],
                                labelOf: _themeControlLabel,
                                onChanged: notifier.setThemeMode,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      SoftReveal(
                        delay: const Duration(milliseconds: 380),
                        child: _SettingsGroup(
                          isWide: isWide,
                          title: 'About',
                          summary: 'Build and model credits.',
                          children: const [
                            _Row(
                              label: 'ChalkLens',
                              value: 'Hackathon build · v0.1.0',
                            ),
                            _Divider(),
                            _Row(
                              label: 'Powered by',
                              value: 'Gemma 4 · LiteRT-LM · Apache 2.0',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  String _themeLabel(ThemeMode mode) => switch (mode) {
    ThemeMode.light => 'Light',
    ThemeMode.dark => 'Dark',
    ThemeMode.system => 'Follows system',
  };

  String _themeControlLabel(ThemeMode mode) => switch (mode) {
    ThemeMode.light => 'Light',
    ThemeMode.dark => 'Dark',
    ThemeMode.system => 'System',
  };
}

class _ModelSlider extends StatelessWidget {
  const _ModelSlider({
    required this.label,
    required this.valueLabel,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.onChanged,
  });

  final String label;
  final String valueLabel;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 12, 0, 8),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: tokens.ink,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0,
                  ),
                ),
              ),
              Container(
                constraints: const BoxConstraints(minWidth: 48),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: tokens.surfaceMuted,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: tokens.oat),
                ),
                alignment: Alignment.center,
                child: Text(
                  valueLabel,
                  style: TextStyle(
                    color: tokens.ink,
                    fontSize: 13,
                    fontFeatures: const [FontFeature.tabularFigures()],
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          AdaptiveSlider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.label,
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  final String label;
  final String value;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final control = useCupertino(context)
        ? CupertinoSwitch(
            value: enabled,
            activeTrackColor: tokens.ink,
            onChanged: onChanged,
          )
        : Switch(value: enabled, onChanged: onChanged);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: tokens.ink,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: TextStyle(
                    color: tokens.inkMuted,
                    fontSize: 13,
                    height: 1.4,
                    letterSpacing: 0,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          control,
        ],
      ),
    );
  }
}

class _SettingsIntro extends StatelessWidget {
  const _SettingsIntro();

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'CONTROL ROOM',
          style: TextStyle(
            color: tokens.inkSubtle,
            fontFamily: 'monospace',
            fontWeight: FontWeight.w600,
            letterSpacing: 0,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          'Keep the app quiet and predictable.',
          style: TextStyle(
            color: tokens.ink,
            fontSize: 31,
            fontWeight: FontWeight.w600,
            height: 1.06,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: 8),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Text(
            'Defaults stay close to the classroom. Advanced model controls are '
            'available, but the screen stays aligned and readable.',
            style: TextStyle(
              color: tokens.inkMuted,
              fontSize: 15,
              height: 1.45,
              letterSpacing: 0,
            ),
          ),
        ),
      ],
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({
    required this.isWide,
    required this.title,
    required this.summary,
    required this.children,
  });

  final bool isWide;
  final String title;
  final String summary;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final label = _SettingsGroupLabel(title: title, summary: summary);
    final surface = Container(
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: tokens.oat),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 5),
      child: Column(children: children),
    );

    if (isWide) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 210, child: label),
          const SizedBox(width: 24),
          Expanded(child: surface),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [label, const SizedBox(height: 12), surface],
    );
  }
}

class _SettingsGroupLabel extends StatelessWidget {
  const _SettingsGroupLabel({required this.title, required this.summary});

  final String title;
  final String summary;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Padding(
      padding: const EdgeInsets.only(top: 5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: TextStyle(
              color: tokens.inkSubtle,
              fontFamily: 'monospace',
              fontWeight: FontWeight.w600,
              letterSpacing: 0,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            summary,
            style: TextStyle(
              color: tokens.inkMuted,
              fontSize: 13,
              height: 1.4,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 430;
          final labelText = Text(
            label,
            style: TextStyle(
              color: tokens.ink,
              fontSize: 15,
              fontWeight: FontWeight.w500,
              letterSpacing: 0,
            ),
          );
          final valueText = Text(
            value,
            textAlign: isWide ? TextAlign.right : TextAlign.left,
            style: TextStyle(
              color: tokens.inkMuted,
              fontSize: 13,
              height: 1.4,
              letterSpacing: 0,
            ),
          );

          if (!isWide) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [labelText, const SizedBox(height: 3), valueText],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(width: 170, child: labelText),
              const SizedBox(width: 18),
              Expanded(child: valueText),
            ],
          );
        },
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Divider(height: 1, color: tokens.oat);
  }
}
