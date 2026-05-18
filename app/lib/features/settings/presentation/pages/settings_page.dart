import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/model/gemma_generation_settings.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/model/gemma_model_installer.dart';
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
                        _SettingRow(
                          label: 'Runtime',
                          value:
                              '${GemmaModelInstaller.defaultModelDisplayName} · '
                              'LiteRT-LM',
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
                      title: 'Answers',
                      summary:
                          'Balanced defaults are used so teachers do not have to tune the model.',
                      children: [
                        const _SettingRow(
                          label: 'Profile',
                          value: 'Balanced classroom output',
                        ),
                        if (settings.modelSettings !=
                            GemmaGenerationSettings.defaults) ...[
                          const _Divider(),
                          AdaptiveSecondaryButton(
                            onPressed: notifier.resetModelSettings,
                            label: 'Reset answer defaults',
                            icon: AppIcons.refresh(context),
                          ),
                        ],
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
            'Keep the offline model ready and choose the app surface.',
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
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: tokens.oat)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(0, 16, 0, 16),
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

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Divider(height: 1, color: tokens.oat);
  }
}
