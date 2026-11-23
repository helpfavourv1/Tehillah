import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:tehillah/providers/feedback_provider.dart';
import 'package:tehillah/theme/app_theme.dart';
import 'package:tehillah/theme/icon_aliases.dart';
import 'package:tehillah/theme/tokens.dart';
import 'package:tehillah/widgets/banner_surface.dart';

/// The banner for one [FeedbackMessage]. Success and failure use different
/// icons as well as different colours, and it is announced when it appears.
class FeedbackBanner extends StatelessWidget {
  const FeedbackBanner({
    required this.message,
    required this.dismissLabel,
    required this.onDismiss,
    super.key,
  });

  final FeedbackMessage message;
  final String dismissLabel;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final AppPalette p = AppTheme.of(context).palette;
    final (IconData icon, Color accent) = switch (message.tone) {
      FeedbackTone.success => (AppIcons.check, p.success),
      FeedbackTone.failure => (AppIcons.warning, p.error),
      FeedbackTone.info => (AppIcons.info, p.accent),
    };
    return BannerSurface(
      icon: icon,
      message: message.text,
      accent: accent,
      dismissLabel: dismissLabel,
      onDismiss: onDismiss,
      live: true,
    );
  }
}

/// Shows the current feedback message over [child], near the top, and removes
/// it after a while: three seconds for success and info, six for failures,
/// which a person needs longer to read. Dismissing is always possible.
class FeedbackHost extends StatefulWidget {
  const FeedbackHost({
    required this.feedback,
    required this.dismissLabel,
    required this.child,
    super.key,
    this.successFor = const Duration(seconds: 3),
    this.failureFor = const Duration(seconds: 6),
  });

  final FeedbackProvider feedback;
  final String dismissLabel;
  final Widget child;
  final Duration successFor;
  final Duration failureFor;

  @override
  State<FeedbackHost> createState() => _FeedbackHostState();
}

class _FeedbackHostState extends State<FeedbackHost> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    widget.feedback.addListener(_changed);
    _changed();
  }

  @override
  void didUpdateWidget(FeedbackHost oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.feedback != widget.feedback) {
      oldWidget.feedback.removeListener(_changed);
      widget.feedback.addListener(_changed);
      _changed();
    }
  }

  void _changed() {
    _timer?.cancel();
    _timer = null;
    final FeedbackMessage? m = widget.feedback.value;
    if (m == null) {
      return;
    }
    final Duration d = m.tone == FeedbackTone.failure ? widget.failureFor : widget.successFor;
    _timer = Timer(d, () => widget.feedback.clearIf(m.id));
  }

  @override
  void dispose() {
    _timer?.cancel();
    widget.feedback.removeListener(_changed);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        widget.child,
        PositionedDirectional(
          top: 0,
          start: 0,
          end: 0,
          child: ListenableBuilder(
            listenable: widget.feedback,
            builder: (BuildContext context, Widget? _) {
              final FeedbackMessage? m = widget.feedback.value;
              if (m == null) {
                return const SizedBox.shrink();
              }
              return Padding(
                padding: EdgeInsets.fromLTRB(
                  Sp.md,
                  MediaQuery.paddingOf(context).top + Sp.sm,
                  Sp.md,
                  0,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: Metrics.contentMaxWidth),
                    child: FeedbackBanner(
                      key: ValueKey<int>(m.id),
                      message: m,
                      dismissLabel: widget.dismissLabel,
                      onDismiss: widget.feedback.clear,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
