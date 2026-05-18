import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/model/gemma_model_installer.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/adaptive_components.dart';
import '../../../../core/widgets/brand_mark.dart';
import '../providers/model_setup_provider.dart';

class ModelSetupPage extends ConsumerStatefulWidget {
  const ModelSetupPage({super.key});

  @override
  ConsumerState<ModelSetupPage> createState() => _ModelSetupPageState();
}

class _ModelSetupPageState extends ConsumerState<ModelSetupPage> {
  final TextEditingController _urlController = TextEditingController();

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final setup = ref.watch(modelSetupProvider);
    final configuredDownloadUrl = GemmaModelInstaller.defaultDownloadUrl.trim();

    // Empty title removes duplication with the in-body brand row, giving
    // the splash gate a quiet single-column feel rather than chrome+hero.
    return AdaptivePageScaffold(
      title: '',
      body: setup.when(
        loading: () => const _SetupShell(children: [_SetupCheckingPanel()]),
        error: (error, _) => _SetupShell(
          children: [
            _MessagePanel(
              tone: _PanelTone.error,
              title: 'Could not inspect model',
              body: error.toString(),
            ),
            const SizedBox(height: 16),
            AdaptiveSecondaryButton(
              onPressed: () => ref.invalidate(modelSetupProvider),
              label: 'Try again',
              icon: AppIcons.refresh(context),
            ),
          ],
        ),
        data: (state) => _SetupShell(
          children: [
            _StatusPanel(state: state),
            if (state.notice != null) ...[
              const SizedBox(height: 12),
              _MessagePanel(
                tone: state.isReady
                    ? _PanelTone.success
                    : state.check.isReady
                    ? _PanelTone.error
                    : _PanelTone.note,
                title: state.isReady ? 'Ready' : 'Notice',
                body: state.notice!,
              ),
            ],
            const SizedBox(height: 24),
            if (state.canContinue) ...[
              AdaptivePrimaryButton(
                onPressed: () => context.goNamed(AppRoute.home),
                label: 'Start teaching',
                icon: AppIcons.check(context),
              ),
              const SizedBox(height: 10),
              AdaptiveSecondaryButton(
                onPressed: state.isBusy
                    ? null
                    : () => ref.read(modelSetupProvider.notifier).refresh(),
                label: 'Check again',
                icon: AppIcons.refresh(context),
              ),
            ] else ...[
              _DownloadPanel(
                controller: _urlController,
                configuredUrl: configuredDownloadUrl,
                enabled: !state.isBusy,
                onDownload: () => ref
                    .read(modelSetupProvider.notifier)
                    .downloadFromUrl(
                      configuredDownloadUrl.isEmpty
                          ? _urlController.text
                          : configuredDownloadUrl,
                    ),
              ),
              const SizedBox(height: 12),
              _ImportFallback(
                enabled: !state.isBusy,
                onImport: () =>
                    ref.read(modelSetupProvider.notifier).importFromFiles(),
              ),
              const SizedBox(height: 8),
              Center(
                child: AdaptiveTextAction(
                  onPressed: state.isBusy
                      ? null
                      : () => ref.read(modelSetupProvider.notifier).refresh(),
                  label: 'Check again',
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SetupShell extends StatelessWidget {
  const _SetupShell({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
      children: [
        const BrandMark(size: 24, subtitle: 'Offline lessons'),
        const SizedBox(height: 28),
        Text(
          'Get offline AI ready.',
          style: TextStyle(
            color: tokens.ink,
            fontSize: 28,
            height: 1.06,
            fontWeight: FontWeight.w700,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Install the model for this app, then make lessons without internet.',
          style: TextStyle(
            color: tokens.inkMuted,
            fontSize: 15,
            height: 1.45,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: 20),
        ...children,
      ],
    );
  }
}

class _SetupCheckingPanel extends StatelessWidget {
  const _SetupCheckingPanel();

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: tokens.oat)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: tokens.washBlue,
                borderRadius: BorderRadius.circular(7),
              ),
              child: Icon(
                AppIcons.download(context),
                color: tokens.washBlueInk,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Checking offline AI',
                    style: TextStyle(
                      color: tokens.ink,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      height: 1.25,
                      letterSpacing: 0,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Making sure the lesson helper is ready.',
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
      ),
    );
  }
}

class _StatusPanel extends StatelessWidget {
  const _StatusPanel({required this.state});

  final ModelSetupState state;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final check = state.check;
    final tone = state.isReady
        ? _PanelTone.success
        : check.status == ModelFileStatus.missing || state.isBusy
        ? _PanelTone.note
        : _PanelTone.error;

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: tokens.oat)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _StatusIcon(tone: tone),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _statusTitle(state),
                        style: TextStyle(
                          color: tokens.ink,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        _statusBody(state),
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
            if (state.isBusy) ...[
              const SizedBox(height: 16),
              _ProgressLine(state: state),
            ],
            const SizedBox(height: 16),
            _MetaRow(
              label: 'File',
              value: GemmaModelInstaller.defaultModelFileName,
            ),
            const SizedBox(height: 8),
            _MetaRow(
              label: 'Size',
              value:
                  '${_formatBytes(check.sizeBytes)} / '
                  '${_formatBytes(check.expectedSizeBytes)}',
            ),
          ],
        ),
      ),
    );
  }

  String _statusTitle(ModelSetupState state) {
    if (state.activity == ModelSetupActivity.verifying && state.check.isReady) {
      return 'Checking offline AI';
    }
    if (state.isReady) return 'Offline AI ready';
    if (state.check.isReady) return 'Offline AI needs repair';
    return switch (state.check.status) {
      ModelFileStatus.ready => 'AI file verified',
      ModelFileStatus.missing => 'Offline AI missing',
      ModelFileStatus.incomplete => 'Download is not finished',
      ModelFileStatus.checksumMismatch => 'AI file needs replacement',
    };
  }

  String _statusBody(ModelSetupState state) {
    final check = state.check;
    if (check.message != null) return check.message!;
    return switch (check.status) {
      ModelFileStatus.ready =>
        state.runtimeReady
            ? 'Ready on this device. You can make lessons offline.'
            : 'The file is here, but the local AI engine did not start.',
      ModelFileStatus.missing =>
        'Fresh installs need the model again. If you deleted the app, the phone removed the installed copy.',
      ModelFileStatus.incomplete =>
        'The file is here, but the copy is partial.',
      ModelFileStatus.checksumMismatch =>
        'The file is complete, but it is not valid.',
    };
  }
}

class _ProgressLine extends StatelessWidget {
  const _ProgressLine({required this.state});

  final ModelSetupState state;

  @override
  Widget build(BuildContext context) {
    final progress = state.progress;
    final label = switch (state.activity) {
      ModelSetupActivity.importing => 'Importing',
      ModelSetupActivity.downloading => 'Downloading',
      ModelSetupActivity.verifying => 'Verifying',
      ModelSetupActivity.idle => 'Working',
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const AdaptiveProgressIndicator(),
            const SizedBox(width: 10),
            Text(
              progress == null
                  ? label
                  : '$label ${(progress * 100).clamp(0, 100).round()}%',
              style: TextStyle(
                color: context.tokens.inkMuted,
                fontSize: 13,
                fontWeight: FontWeight.w500,
                letterSpacing: 0,
              ),
            ),
          ],
        ),
        if (progress != null) ...[
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 5,
              color: context.tokens.ink,
              backgroundColor: context.tokens.surfaceMuted,
            ),
          ),
        ],
      ],
    );
  }
}

class _DownloadPanel extends StatelessWidget {
  const _DownloadPanel({
    required this.controller,
    required this.configuredUrl,
    required this.enabled,
    required this.onDownload,
  });

  final TextEditingController controller;
  final String configuredUrl;
  final bool enabled;
  final VoidCallback onDownload;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: tokens.oat)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Download offline AI',
              style: TextStyle(
                color: tokens.ink,
                fontSize: 15,
                fontWeight: FontWeight.w600,
                letterSpacing: 0,
              ),
            ),
            const SizedBox(height: 4),
            if (configuredUrl.isEmpty) ...[
              Text(
                'Paste a direct download link for the '
                '${GemmaModelInstaller.defaultModelDisplayName} LiteRT-LM '
                'file, or import it from Files.',
                style: TextStyle(
                  color: tokens.inkMuted,
                  fontSize: 13,
                  height: 1.35,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(height: 14),
              AdaptiveTextField(
                controller: controller,
                label: 'Download link',
                placeholder:
                    'https://huggingface.co/.../'
                    '${GemmaModelInstaller.defaultModelFileName}',
                textInputAction: TextInputAction.done,
              ),
              const SizedBox(height: 12),
            ] else ...[
              Text(
                '${GemmaModelInstaller.defaultModelDisplayName} · '
                '${_formatBytes(GemmaModelInstaller.defaultModelSizeBytes)} · '
                'one-time setup. ChalkLens runs fully offline after this — '
                'no internet needed to teach.',
                style: TextStyle(
                  color: tokens.inkMuted,
                  fontSize: 13,
                  height: 1.35,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(height: 14),
            ],
            AdaptivePrimaryButton(
              onPressed: enabled ? onDownload : null,
              label: 'Download offline AI',
              icon: AppIcons.download(context),
            ),
          ],
        ),
      ),
    );
  }
}

class _ImportFallback extends StatelessWidget {
  const _ImportFallback({required this.enabled, required this.onImport});

  final bool enabled;
  final VoidCallback onImport;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 2,
      children: [
        Text(
          'Already have the AI file saved in Files or Downloads?',
          style: TextStyle(
            color: tokens.inkMuted,
            fontSize: 13,
            height: 1.3,
            letterSpacing: 0,
          ),
        ),
        AdaptiveTextAction(
          onPressed: enabled ? onImport : null,
          label: 'Import',
        ),
      ],
    );
  }
}

enum _PanelTone { note, success, error }

class _MessagePanel extends StatelessWidget {
  const _MessagePanel({
    required this.tone,
    required this.title,
    required this.body,
  });

  final _PanelTone tone;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final colors = _toneColors(context, tone);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.$1.withValues(alpha: 0.72),
        border: Border(left: BorderSide(color: colors.$2, width: 2)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _StatusIcon(tone: tone),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: colors.$2,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    body,
                    style: TextStyle(
                      color: colors.$2,
                      fontSize: 13,
                      height: 1.35,
                      letterSpacing: 0,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusIcon extends StatelessWidget {
  const _StatusIcon({required this.tone});

  final _PanelTone tone;

  @override
  Widget build(BuildContext context) {
    final colors = _toneColors(context, tone);
    final icon = switch (tone) {
      _PanelTone.success => AppIcons.check(context),
      _PanelTone.error => AppIcons.error(context),
      _PanelTone.note => AppIcons.download(context),
    };

    return Container(
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        color: colors.$1,
        borderRadius: BorderRadius.circular(5),
      ),
      child: Icon(icon, color: colors.$2, size: 15),
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Row(
      children: [
        SizedBox(
          width: 56,
          child: Text(
            label,
            style: TextStyle(
              color: tokens.inkSubtle,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              color: tokens.inkMuted,
              fontSize: 12,
              height: 1.25,
              letterSpacing: 0,
            ),
          ),
        ),
      ],
    );
  }
}

(Color, Color) _toneColors(BuildContext context, _PanelTone tone) {
  final tokens = context.tokens;
  return switch (tone) {
    _PanelTone.success => (tokens.washGreen, tokens.washGreenInk),
    _PanelTone.error => (tokens.washRed, tokens.washRedInk),
    _PanelTone.note => (tokens.washBlue, tokens.washBlueInk),
  };
}

String _formatBytes(int? bytes) {
  if (bytes == null) return 'None';
  const units = ['B', 'KB', 'MB', 'GB'];
  var size = bytes.toDouble();
  var unit = 0;
  while (size >= 1024 && unit < units.length - 1) {
    size /= 1024;
    unit++;
  }
  final decimals = unit == 0 ? 0 : 2;
  return '${size.toStringAsFixed(decimals)} ${units[unit]}';
}
