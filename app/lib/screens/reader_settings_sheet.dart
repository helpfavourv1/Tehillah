import 'package:flutter/widgets.dart';
import 'package:tehillah/theme/app_theme.dart';
import 'package:tehillah/theme/icon_aliases.dart';
import 'package:tehillah/theme/tokens.dart';
import 'package:tehillah/utils/text_direction.dart';
import 'package:tehillah/widgets/app_card.dart';
import 'package:tehillah/widgets/app_chip.dart';
import 'package:tehillah/widgets/app_row.dart';

final class ReaderSettingsLabels {
  const ReaderSettingsLabels({
    required this.textSize,
    required this.smaller,
    required this.larger,
    required this.sizeValue,
    required this.preview,
    required this.bookmarks,
  });

  final String textSize;
  final String smaller;
  final String larger;

  /// "120%".
  final String Function(double scale) sizeValue;

  /// A sample line in the Bible's language, shown at the chosen size.
  final String preview;
  final String bookmarks;
}

/// The content of the reading settings sheet (shown with `showAppBottomSheet`):
/// text size with a live preview, and a way into the bookmarks.
class ReaderSettingsSheet extends StatelessWidget {
  const ReaderSettingsSheet({
    required this.labels,
    required this.textScale,
    required this.language,
    required this.onTextScale,
    required this.onOpenBookmarks,
    super.key,
  });

  static const double minScale = 0.8;
  static const double maxScale = 2;
  static const double step = 0.1;

  final ReaderSettingsLabels labels;
  final double textScale;
  final String language;
  final ValueChanged<double> onTextScale;
  final VoidCallback onOpenBookmarks;

  double _snap(double v) => (v * 10).round() / 10;

  @override
  Widget build(BuildContext context) {
    final AppThemeData theme = AppTheme.of(context);
    final double scale = textScale.clamp(minScale, maxScale).toDouble();
    final bool canShrink = scale > minScale + 0.001;
    final bool canGrow = scale < maxScale - 0.001;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(child: Text(labels.textSize, style: theme.text.title2)),
            Text(
              labels.sizeValue(scale),
              style: theme.text.callout.copyWith(color: theme.palette.textSecondary),
            ),
          ],
        ),
        const SizedBox(height: Sp.sm),
        Row(
          children: <Widget>[
            Expanded(
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: AppChip(
                  label: labels.smaller,
                  icon: AppIcons.textSize,
                  onTap: canShrink ? () => onTextScale(_snap(scale - step)) : null,
                ),
              ),
            ),
            Expanded(
              child: Align(
                alignment: AlignmentDirectional.centerEnd,
                child: AppChip(
                  label: labels.larger,
                  icon: AppIcons.textSize,
                  onTap: canGrow ? () => onTextScale(_snap(scale + step)) : null,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: Sp.md),
        CardSurface(
          child: Directionality(
            textDirection: directionForLanguage(language),
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: Text(
                labels.preview,
                style: theme.text.readerBody(scale).copyWith(color: theme.palette.textPrimary),
              ),
            ),
          ),
        ),
        const SizedBox(height: Sp.md),
        CardSurface(
          padding: EdgeInsets.zero,
          child: AppRow(
            label: labels.bookmarks,
            leading: AppIcons.bookmark,
            onTap: onOpenBookmarks,
          ),
        ),
      ],
    );
  }
}
