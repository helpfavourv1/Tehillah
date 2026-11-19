import 'package:flutter/widgets.dart';

import 'package:tehillah/theme/app_theme.dart';
import 'package:tehillah/theme/icon_aliases.dart';
import 'package:tehillah/theme/tokens.dart';

/// The one icon widget. The icon set is a bold weight whose stroke is
/// 24/256 of the icon size (2.25 px at 24 px, about 2.06 px at 22 px), so
/// icons carry the same visual mass as 16 to 17 pt text.
class AppIcon extends StatelessWidget {
  const AppIcon(
    this.symbol, {
    super.key,
    this.size = IconSizes.rowLeading,
    this.color,
    this.semanticLabel,
  });

  final AppSymbol symbol;
  final double size;

  /// Defaults to the primary text color of the current theme.
  final Color? color;

  /// Read by screen readers. Leave null for decorative icons next to a label.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Icon(
      symbol.data,
      size: size,
      color: color ?? AppTheme.of(context).palette.textPrimary,
      semanticLabel: semanticLabel,
      textDirection: symbol.mirrorsInRtl ? null : TextDirection.ltr,
    );
  }
}
