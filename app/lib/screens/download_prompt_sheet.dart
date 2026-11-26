import 'package:flutter/widgets.dart';
import 'package:tehillah/theme/app_theme.dart';
import 'package:tehillah/theme/icon_aliases.dart';
import 'package:tehillah/theme/tokens.dart';
import 'package:tehillah/widgets/primary_button.dart';
import 'package:tehillah/widgets/progress_bar.dart';
import 'package:tehillah/widgets/segmented_control.dart';

/// Where the download prompt is.
enum DownloadPhase { ask, downloading, failed, blocked }

final class DownloadPromptLabels {
  const DownloadPromptLabels({
    required this.title,
    required this.explain,
    required this.networkLabel,
    required this.wifiOnly,
    required this.wifiAndData,
    required this.download,
    required this.notNow,
    required this.downloading,
    required this.cancel,
    required this.retry,
    required this.percent,
  });

  /// "Download the English Bible" is built by the caller into [title]; the
  /// language name is not assembled here.
  final String title;

  /// Why a download is needed and that nothing else in the game needs it.
  final String explain;

  /// What a screen reader says about the Wi-Fi choice.
  final String networkLabel;
  final String wifiOnly;
  final String wifiAndData;
  final String download;
  final String notNow;
  final String downloading;
  final String cancel;
  final String retry;

  /// "42%".
  final String Function(double fraction) percent;
}

/// The content of the first-use download sheet (shown with `showAppBottomSheet`).
/// Asks for Wi-Fi only or Wi-Fi and mobile data, then shows one progress bar
/// with Cancel; a failure shows its message with Retry. Declining never
/// blocks play. The caller closes the sheet when the Bible is installed.
class DownloadPromptSheet extends StatelessWidget {
  const DownloadPromptSheet({
    required this.labels,
    required this.phase,
    required this.wifiOnly,
    required this.onWifiOnlyChanged,
    required this.onDownload,
    required this.onCancel,
    required this.onClose,
    super.key,
    this.fraction = 0,
    this.sizeLabel,
    this.message,
  });

  final DownloadPromptLabels labels;
  final DownloadPhase phase;
  final bool wifiOnly;
  final ValueChanged<bool> onWifiOnlyChanged;

  /// Starts (or restarts) the download.
  final VoidCallback onDownload;

  /// Stops a running download.
  final VoidCallback onCancel;

  /// Closes the sheet without downloading.
  final VoidCallback onClose;

  /// 0 to 1 while downloading.
  final double fraction;

  /// "About 4 MB"; shown while asking.
  final String? sizeLabel;

  /// Why it failed or is blocked, in words.
  final String? message;

  @override
  Widget build(BuildContext context) {
    final AppThemeData theme = AppTheme.of(context);
    final TextStyle secondary = theme.text.callout.copyWith(color: theme.palette.textSecondary);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(labels.explain, style: secondary),
        if (phase == DownloadPhase.ask && sizeLabel != null) ...<Widget>[
          const SizedBox(height: Sp.xs),
          Text(sizeLabel!, style: theme.text.footnote),
        ],
        if (phase == DownloadPhase.failed || phase == DownloadPhase.blocked) ...<Widget>[
          const SizedBox(height: Sp.md),
          Semantics(
            liveRegion: true,
            child: Text(
              message ?? '',
              style: theme.text.callout.copyWith(color: theme.palette.error),
            ),
          ),
        ],
        const SizedBox(height: Sp.md),
        if (phase == DownloadPhase.ask || phase == DownloadPhase.failed) ...<Widget>[
          SegmentedControl<bool>(
            semanticLabel: labels.networkLabel,
            options: <SegmentOption<bool>>[
              SegmentOption<bool>(value: true, label: labels.wifiOnly, icon: AppIcons.wifi),
              SegmentOption<bool>(value: false, label: labels.wifiAndData, icon: AppIcons.download),
            ],
            selected: wifiOnly,
            onChanged: onWifiOnlyChanged,
          ),
          const SizedBox(height: Sp.md),
        ],
        if (phase == DownloadPhase.downloading) ...<Widget>[
          AppProgressBar(
            fraction: fraction.clamp(0.0, 1.0).toDouble(),
            valueLabel: labels.percent(fraction.clamp(0.0, 1.0).toDouble()),
            label: labels.downloading,
          ),
          const SizedBox(height: Sp.md),
          SecondaryButton(label: labels.cancel, icon: AppIcons.close, onPressed: onCancel),
        ] else if (phase == DownloadPhase.blocked) ...<Widget>[
          SecondaryButton(label: labels.notNow, icon: AppIcons.close, onPressed: onClose),
        ] else ...<Widget>[
          PrimaryButton(
            label: phase == DownloadPhase.failed ? labels.retry : labels.download,
            icon: phase == DownloadPhase.failed ? AppIcons.retry : AppIcons.download,
            onPressed: onDownload,
          ),
          const SizedBox(height: Sp.sm),
          SecondaryButton(label: labels.notNow, icon: AppIcons.close, onPressed: onClose),
        ],
      ],
    );
  }
}
