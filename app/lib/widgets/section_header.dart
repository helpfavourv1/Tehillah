import 'package:flutter/widgets.dart';
import 'package:tehillah/theme/app_theme.dart';
import 'package:tehillah/theme/tokens.dart';

/// A small uppercase, letter-spaced group title in the tertiary colour.
class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {super.key, this.padding});

  final String title;

  /// Defaults to a small inset from the start edge and space above and below.
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final AppThemeData theme = AppTheme.of(context);
    return Semantics(
      header: true,
      child: Padding(
        padding: padding ??
            const EdgeInsetsDirectional.only(start: Sp.md, top: Sp.lg, bottom: Sp.sm, end: Sp.md),
        child: Text(
          title.toUpperCase(),
          style: theme.text.sectionHeader,
        ),
      ),
    );
  }
}
