import 'package:flutter/widgets.dart';
import 'package:tehillah/core/models/settings_model.dart';
import 'package:tehillah/theme/icon_aliases.dart';
import 'package:tehillah/widgets/app_card.dart';
import 'package:tehillah/widgets/app_row.dart';

final class ReaderThemeLabels {
  const ReaderThemeLabels({
    required this.light,
    required this.dark,
    required this.sepia,
    required this.sepiaDetail,
    required this.selected,
  });

  final String light;
  final String dark;
  final String sepia;
  final String sepiaDetail;

  /// Said after the chosen theme.
  final String selected;
}

/// The content of the reader theme sheet: three rows, the chosen one carrying
/// a check as well as the announcement.
class ReaderThemeSheet extends StatelessWidget {
  const ReaderThemeSheet({
    required this.labels,
    required this.current,
    required this.onPick,
    super.key,
  });

  final ReaderThemeLabels labels;
  final ReaderTheme current;
  final ValueChanged<ReaderTheme> onPick;

  @override
  Widget build(BuildContext context) {
    final Map<ReaderTheme, String> names = <ReaderTheme, String>{
      ReaderTheme.light: labels.light,
      ReaderTheme.dark: labels.dark,
      ReaderTheme.sepia: labels.sepia,
    };
    return CardSurface(
      padding: EdgeInsets.zero,
      child: Column(
        children: <Widget>[
          for (final MapEntry<ReaderTheme, String> e in names.entries)
            AppRow(
              label: e.value,
              subtitle: e.key == ReaderTheme.sepia ? labels.sepiaDetail : null,
              leading: e.key == current ? AppIcons.check : AppIcons.theme,
              chevron: false,
              semanticLabel: e.key == current ? '${e.value}. ${labels.selected}' : e.value,
              onTap: () => onPick(e.key),
            ),
        ],
      ),
    );
  }
}
