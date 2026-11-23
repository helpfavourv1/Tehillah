import 'package:flutter/widgets.dart';
import 'package:tehillah/theme/app_icon.dart';
import 'package:tehillah/theme/app_theme.dart';
import 'package:tehillah/theme/tokens.dart';
import 'package:tehillah/widgets/primary_button.dart';

/// A dialog: 16 radius on all corners, an optional icon, a title, an optional
/// message and stacked full-width actions. The caller supplies the buttons so
/// the safe choice can be the filled primary one.
class AppDialog extends StatelessWidget {
  const AppDialog({required this.title, required this.actions, super.key, this.message, this.icon});

  final String title;
  final String? message;
  final IconData? icon;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final AppThemeData theme = AppTheme.of(context);
    final AppPalette p = theme.palette;
    final double maxHeight = MediaQuery.sizeOf(context).height * 0.9;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Sp.lg),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: Metrics.dialogMaxWidth, maxHeight: maxHeight),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: p.bgSecondary,
              borderRadius: BorderRadius.circular(Radii.dialog),
              border: Border.all(color: p.borderSubtle, width: Metrics.hairline),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(Sp.lg),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  if (icon != null) ...<Widget>[
                    Center(child: AppIcon(icon!, size: IconSizes.hero, color: p.accent)),
                    const SizedBox(height: Sp.md),
                  ],
                  Semantics(
                    header: true,
                    child: Text(title, textAlign: TextAlign.center, style: theme.text.title2),
                  ),
                  if (message != null) ...<Widget>[
                    const SizedBox(height: Sp.sm),
                    Text(message!, textAlign: TextAlign.center, style: theme.text.footnote),
                  ],
                  const SizedBox(height: Sp.lg),
                  for (int i = 0; i < actions.length; i++) ...<Widget>[
                    if (i > 0) const SizedBox(height: Sp.sm),
                    actions[i],
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DialogRoute<T> extends PopupRoute<T> {
  _DialogRoute({
    required this.builder,
    required this.label,
    required this.scrim,
    required this.instant,
    required this.dismissible,
  });

  final WidgetBuilder builder;
  final String label;
  final Color scrim;
  final bool instant;
  final bool dismissible;

  @override
  Color? get barrierColor => scrim;

  @override
  bool get barrierDismissible => dismissible;

  @override
  String? get barrierLabel => label;

  @override
  Duration get transitionDuration => instant ? Duration.zero : Motion.pop;

  @override
  Widget buildPage(BuildContext context, Animation<double> animation, Animation<double> secondary) {
    return builder(context);
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondary,
    Widget child,
  ) {
    if (instant) {
      return child;
    }
    return FadeTransition(
      opacity: CurvedAnimation(parent: animation, curve: Motion.out),
      child: child,
    );
  }
}

/// Presents a dialog built by [builder] and completes with whatever is passed
/// to `Navigator.pop`, or null if it was dismissed.
Future<T?> showAppDialog<T>({
  required BuildContext context,
  required String barrierLabel,
  required WidgetBuilder builder,
  bool dismissible = true,
}) {
  final bool instant = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
  return Navigator.of(context, rootNavigator: true).push<T>(
    _DialogRoute<T>(
      builder: builder,
      label: barrierLabel,
      scrim: AppTheme.of(context).palette.scrim,
      instant: instant,
      dismissible: dismissible,
    ),
  );
}

/// A yes or no question. Completes true on confirm and false on cancel or
/// dismissal. A [destructive] confirm is drawn in the error colour.
Future<bool> showConfirmDialog({
  required BuildContext context,
  required String barrierLabel,
  required String title,
  required String confirmLabel,
  required String cancelLabel,
  String? message,
  IconData? icon,
  bool destructive = false,
}) async {
  final bool? result = await showAppDialog<bool>(
    context: context,
    barrierLabel: barrierLabel,
    builder: (BuildContext c) => AppDialog(
      title: title,
      message: message,
      icon: icon,
      actions: <Widget>[
        if (destructive)
          DestructiveButton(label: confirmLabel, onPressed: () => Navigator.of(c).pop(true))
        else
          PrimaryButton(label: confirmLabel, onPressed: () => Navigator.of(c).pop(true)),
        SecondaryButton(label: cancelLabel, onPressed: () => Navigator.of(c).pop(false)),
      ],
    ),
  );
  return result ?? false;
}
