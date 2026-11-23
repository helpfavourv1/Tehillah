import 'package:flutter/widgets.dart';
import 'package:tehillah/theme/app_icon.dart';
import 'package:tehillah/theme/app_theme.dart';
import 'package:tehillah/theme/icon_aliases.dart';
import 'package:tehillah/theme/tokens.dart';
import 'package:tehillah/widgets/primary_button.dart';

/// The full-screen fallback for a fatal error: never a grey screen. An icon, a
/// plain-words title and message, a filled Retry, and a quieter report button
/// that opens a prepared email. The optional [detail] is a short technical
/// code to quote in the report.
class ErrorStateView extends StatelessWidget {
  const ErrorStateView({
    required this.title,
    required this.message,
    required this.retryLabel,
    required this.onRetry,
    required this.reportLabel,
    required this.onReport,
    super.key,
    this.detail,
  });

  final String title;
  final String message;
  final String retryLabel;
  final VoidCallback onRetry;
  final String reportLabel;
  final VoidCallback onReport;
  final String? detail;

  @override
  Widget build(BuildContext context) {
    final AppThemeData theme = AppTheme.of(context);
    final AppPalette p = theme.palette;
    final EdgeInsets safe = MediaQuery.paddingOf(context);
    return ColoredBox(
      color: p.bgPrimary,
      child: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            Sp.lg + safe.left,
            Sp.lg + safe.top,
            Sp.lg + safe.right,
            Sp.lg + safe.bottom,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: Metrics.dialogMaxWidth),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Center(child: AppIcon(AppIcons.warning, size: IconSizes.hero, color: p.error)),
                const SizedBox(height: Sp.md),
                Semantics(
                  header: true,
                  child: Text(title, textAlign: TextAlign.center, style: theme.text.headline),
                ),
                const SizedBox(height: Sp.sm),
                Text(message, textAlign: TextAlign.center, style: theme.text.body),
                if (detail != null) ...<Widget>[
                  const SizedBox(height: Sp.sm),
                  Text(
                    detail!,
                    textAlign: TextAlign.center,
                    style: theme.text.caption.copyWith(color: p.textTertiary),
                  ),
                ],
                const SizedBox(height: Sp.lg),
                PrimaryButton(label: retryLabel, icon: AppIcons.retry, onPressed: onRetry),
                const SizedBox(height: Sp.sm),
                SecondaryButton(label: reportLabel, icon: AppIcons.email, onPressed: onReport),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
