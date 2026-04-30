import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 44),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SoftReveal(child: _SettingsIntro()),
                  const SizedBox(height: 22),
                  SoftReveal(
                    delay: const Duration(milliseconds: 70),
                    child: _SettingsPanel(
                      icon: AppIcons.download(context),
                      title: 'Offline model',
                      summary:
                          'Gemma runs on this device. Open setup only when the model file needs attention.',
                      children: [
                        const _SettingRow(
                          label: 'Runtime',
                          value: 'Gemma 4 E2B · LiteRT-LM',
                        ),
                        const _Divider(),
                        const _SettingRow(
                          label: 'Storage',
                          value: 'Saved inside app documents',
                        ),
                        const SizedBox(height: 14),
                        AdaptiveSecondaryButton(
                          onPressed: () => context.goNamed(AppRoute.modelSetup),
                          label: 'Open model setup',
                          icon: AppIcons.download(context),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  SoftReveal(
                    delay: const Duration(milliseconds: 130),
                    child: _SettingsPanel(
                      icon: AppIcons.settings(context),
                      title: 'Generation',
                      summary:
                          'Used by lesson creation and student help answers.',
                      children: [
                        _SettingRow(
                          label: 'Profile',
                          value: settings.modelSettings.responseProfile,
                        ),
                        const _Divider(),
                        _SwitchRow(
                          label: 'Reasoning',
                          value: settings.modelSettings.thinkingMode
                              ? 'Shows the model trace while it plans.'
                              : 'Answers directly without the trace.',
                          enabled: settings.modelSettings.thinkingMode,
                          onChanged: notifier.setThinkingMode,
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
                          valueLabel: settings.modelSettings.topK.toString(),
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
                          value: settings.modelSettings.randomSeed.toDouble(),
                          min: 1,
                          max: 99,
                          divisions: 98,
                          onChanged: (v) => notifier.setRandomSeed(v.round()),
                        ),
                        const SizedBox(height: 14),
                        AdaptiveSecondaryButton(
                          onPressed:
                              settings.modelSettings ==
                                  GemmaGenerationSettings.defaults
                              ? null
                              : notifier.resetModelSettings,
                          label: 'Reset generation',
                          icon: AppIcons.refresh(context),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  SoftReveal(
                    delay: const Duration(milliseconds: 190),
                    child: _SettingsPanel(
                      icon: useCupertino(context)
                          ? CupertinoIcons.circle_grid_hex
                          : Icons.contrast,
                      title: 'Appearance',
                      summary: 'Choose the app surface.',
                      children: [
                        _SettingRow(
                          label: 'Theme',
                          value: _themeLabel(settings.themeMode),
                        ),
                        const SizedBox(height: 14),
                        AdaptiveSegmentedControl<ThemeMode>(
                          value: settings.themeMode,
                          values: const [
                            ThemeMode.dark,
                            ThemeMode.system,
                            ThemeMode.light,
                          ],
                          labelOf: _themeControlLabel,
                          onChanged: notifier.setThemeMode,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
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

class _SettingsIntro extends StatelessWidget {
  const _SettingsIntro();

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Settings',
          style: TextStyle(
            color: tokens.ink,
            fontSize: 30,
            fontWeight: FontWeight.w600,
            height: 1.06,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: 8),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Text(
            'Keep the offline model ready, tune generation, and choose the app surface.',
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

class _SettingsPanel extends StatelessWidget {
  const _SettingsPanel({
    required this.icon,
    required this.title,
    required this.summary,
    required this.children,
  });

  final IconData icon;
  final String title;
  final String summary;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Container(
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: tokens.oat),
      ),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: tokens.surfaceMuted,
                  borderRadius: BorderRadius.circular(7),
                  border: Border.all(color: tokens.oat),
                ),
                child: Icon(icon, size: 18, color: tokens.ink),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: tokens.ink,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        height: 1.15,
                        letterSpacing: 0,
                      ),
                    ),
                    const SizedBox(height: 4),
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
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}

class _SettingRow extends StatelessWidget {
  const _SettingRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 11),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 420;
          final labelText = Text(
            label,
            style: TextStyle(
              color: tokens.ink,
              fontSize: 14,
              fontWeight: FontWeight.w600,
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
              children: [labelText, const SizedBox(height: 4), valueText],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(width: 150, child: labelText),
              const SizedBox(width: 16),
              Expanded(child: valueText),
            ],
          );
        },
      ),
    );
  }
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
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
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
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: tokens.ink,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 4),
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

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Divider(height: 1, color: tokens.oat);
  }
}
