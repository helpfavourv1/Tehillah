import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:tehillah/providers/ad_provider.dart' show AdState;
import 'package:tehillah/theme/app_theme.dart';
import 'package:tehillah/theme/tokens.dart';

/// The banner embed. Its spec: the slot has height only while a banner is
/// ready and allowed; then it is the banner's height with 8 above, 8 below and
/// a hairline on top. In every other case (loading, failed, consent missing,
/// purchased, keyboard open) it is zero height with no gap, no border and no
/// fill. Nothing is ever drawn as a placeholder.
///
/// The banner itself is a native view built by the caller through
/// [bannerBuilder], so this widget has no plugin dependency.
class AdSlot extends StatefulWidget {
  const AdSlot({
    required this.state,
    required this.onMetrics,
    required this.bannerBuilder,
    super.key,
  });

  /// The ad provider's state.
  final ValueListenable<AdState> state;

  /// Reports the slot's available width in dp and whether the keyboard is
  /// open, once per change. Screens forward it to the ad provider's
  /// `requestBanner` and `setKeyboardOpen`.
  final void Function(int widthDp, bool keyboardOpen) onMetrics;

  /// Builds the banner view for the given width in dp.
  final Widget Function(BuildContext context, int widthDp) bannerBuilder;

  @override
  State<AdSlot> createState() => _AdSlotState();
}

class _AdSlotState extends State<AdSlot> {
  int? _reportedWidth;
  bool? _reportedKeyboard;

  void _report(int width, bool keyboard) {
    if (width == _reportedWidth && keyboard == _reportedKeyboard) {
      return;
    }
    _reportedWidth = width;
    _reportedKeyboard = keyboard;
    WidgetsBinding.instance.addPostFrameCallback((Duration _) {
      if (!mounted) {
        return;
      }
      widget.onMetrics(width, keyboard);
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool keyboard = MediaQuery.viewInsetsOf(context).bottom > 0;
    final AppPalette palette = AppTheme.of(context).palette;
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final int width = constraints.maxWidth.isFinite ? constraints.maxWidth.floor() : 0;
        _report(width, keyboard);
        return ListenableBuilder(
          listenable: widget.state,
          builder: (BuildContext context, Widget? _) {
            final AdState state = widget.state.value;
            if (!state.bannerVisible || state.bannerHeightDp <= 0 || keyboard || width <= 0) {
              return const SizedBox.shrink();
            }
            return DecoratedBox(
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: palette.borderSubtle, width: Metrics.hairline),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: Sp.sm),
                child: SizedBox(
                  height: state.bannerHeightDp,
                  width: double.infinity,
                  child: widget.bannerBuilder(context, width),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
