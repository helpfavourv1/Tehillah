import 'package:flutter/widgets.dart';
import 'package:tehillah/theme/app_icon.dart';
import 'package:tehillah/theme/app_theme.dart';
import 'package:tehillah/theme/tokens.dart';

/// What a list or screen shows when there is nothing to show: an icon, a
/// title, an optional line of explanation and an optional action, centred.
class EmptyState extends StatelessWidget {
  const EmptyState({
    required this.icon,
    required this.title,
    super.key,
    this.subtitle,
    this.action,
  });

  final IconData icon;
  final String title;
  final String? subtitle;

  /// For example a Retry or Download button.
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final AppThemeData theme = AppTheme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Sp.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            AppIcon(icon, size: IconSizes.hero, color: theme.palette.textTertiary),
            const SizedBox(height: Sp.md),
            Text(title, textAlign: TextAlign.center, style: theme.text.title2),
            if (subtitle != null) ...<Widget>[
              const SizedBox(height: Sp.sm),
              Text(subtitle!, textAlign: TextAlign.center, style: theme.text.footnote),
            ],
            if (action != null) ...<Widget>[
              const SizedBox(height: Sp.lg),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
