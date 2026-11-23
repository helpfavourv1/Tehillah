import 'package:flutter/widgets.dart';
import 'package:tehillah/theme/app_theme.dart';
import 'package:tehillah/theme/icon_aliases.dart';
import 'package:tehillah/widgets/banner_surface.dart';

/// A persistent notice for conditions that last until fixed: saving failed and
/// progress is only in memory, or saved data was damaged and recovered. It is
/// not announced as a live region (it is already on screen when read) and has
/// an optional Retry and an optional dismiss.
class WarningBanner extends StatelessWidget {
  const WarningBanner({
    required this.message,
    super.key,
    this.actionLabel,
    this.onAction,
    this.dismissLabel,
    this.onDismiss,
  });

  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final String? dismissLabel;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    return BannerSurface(
      icon: AppIcons.warning,
      message: message,
      accent: AppTheme.of(context).palette.warning,
      actionLabel: actionLabel,
      onAction: onAction,
      dismissLabel: dismissLabel,
      onDismiss: onDismiss,
    );
  }
}
