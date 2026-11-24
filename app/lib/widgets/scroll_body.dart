import 'package:flutter/widgets.dart';
import 'package:tehillah/theme/tokens.dart';

/// The scrolling content area of a screen: padded at the sides, children
/// stretched to full width, gaps chosen by the caller. Scrolling is a
/// fallback for large text and small windows; a screen whose content fits
/// does not move.
class ScrollBody extends StatelessWidget {
  const ScrollBody({
    required this.children,
    super.key,
    this.padding = const EdgeInsets.fromLTRB(Sp.md, Sp.sm, Sp.md, Sp.md),
    this.controller,
  });

  final List<Widget> children;
  final EdgeInsetsGeometry padding;
  final ScrollController? controller;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      controller: controller,
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }
}
