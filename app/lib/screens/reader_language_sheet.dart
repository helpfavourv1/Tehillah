import 'package:flutter/widgets.dart';
import 'package:tehillah/theme/app_icon.dart';
import 'package:tehillah/theme/app_theme.dart';
import 'package:tehillah/theme/icon_aliases.dart';
import 'package:tehillah/theme/tokens.dart';
import 'package:tehillah/widgets/app_card.dart';
import 'package:tehillah/widgets/app_row.dart';

/// Where one language's Bible stands.
enum LanguagePackState { notInstalled, downloading, installed, failed }

/// One Bible language.
final class ReaderLanguage {
  const ReaderLanguage({
    required this.code,
    required this.name,
    required this.state,
    this.progress = 0,
    this.detail,
  });

  final String code;

  /// The language's own name for itself.
  final String name;
  final LanguagePackState state;

  /// 0 to 1 while downloading.
  final double progress;

  /// The translation's name or licence line, shown under the name.
  final String? detail;
}

final class ReaderLanguageLabels {
  const ReaderLanguageLabels({
    required this.reading,
    required this.notDownloaded,
    required this.downloaded,
    required this.failed,
    required this.percent,
    required this.download,
  });

  /// Said after the language that is open now.
  final String reading;
  final String notDownloaded;
  final String downloaded;
  final String failed;

  /// "42%".
  final String Function(double fraction) percent;

  /// Announced on a not-yet-downloaded row, which starts the download.
  final String download;
}

/// The content of the reader language sheet: every Bible language with its
/// download state. Tapping an installed language opens it; tapping one that
/// is not installed starts its download prompt. The open language has a check.
class ReaderLanguageSheet extends StatelessWidget {
  const ReaderLanguageSheet({
    required this.labels,
    required this.languages,
    required this.current,
    required this.onPick,
    super.key,
  });

  final ReaderLanguageLabels labels;
  final List<ReaderLanguage> languages;
  final String current;
  final void Function(ReaderLanguage language) onPick;

  String _status(ReaderLanguage l) => switch (l.state) {
        LanguagePackState.installed => labels.downloaded,
        LanguagePackState.notInstalled => labels.notDownloaded,
        LanguagePackState.downloading => labels.percent(l.progress.clamp(0.0, 1.0).toDouble()),
        LanguagePackState.failed => labels.failed,
      };

  @override
  Widget build(BuildContext context) {
    final AppThemeData theme = AppTheme.of(context);
    final AppPalette p = theme.palette;
    return CardSurface(
      padding: EdgeInsets.zero,
      child: Column(
        children: <Widget>[
          for (final ReaderLanguage l in languages)
            AppRow(
              label: l.name,
              subtitle: l.detail,
              leading: l.code == current ? AppIcons.check : null,
              chevron: false,
              semanticLabel: <String>[
                l.name,
                _status(l),
                if (l.code == current) labels.reading,
              ].join('. '),
              trailing: l.state == LanguagePackState.installed
                  ? null
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        if (l.state == LanguagePackState.notInstalled ||
                            l.state == LanguagePackState.failed) ...<Widget>[
                          AppIcon(
                            l.state == LanguagePackState.failed
                                ? AppIcons.warning
                                : AppIcons.download,
                            size: IconSizes.rowTrailing,
                            color: l.state == LanguagePackState.failed ? p.error : p.textTertiary,
                          ),
                          const SizedBox(width: Sp.xs),
                        ],
                        Text(
                          _status(l),
                          style: theme.text.footnote.copyWith(
                            color: l.state == LanguagePackState.failed
                                ? p.error
                                : p.textSecondary,
                          ),
                        ),
                      ],
                    ),
              onTap: l.state == LanguagePackState.downloading ? null : () => onPick(l),
            ),
        ],
      ),
    );
  }
}
