import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart' show TextInputAction;
import 'package:tehillah/theme/app_icon.dart';
import 'package:tehillah/theme/app_theme.dart';
import 'package:tehillah/theme/icon_aliases.dart';
import 'package:tehillah/theme/tokens.dart';
import 'package:tehillah/widgets/icon_chip.dart';

/// The one text field. A filled tertiary pill with a search icon, the hint
/// while empty, and a clear button once there is text. The border moves to the
/// focus colour on focus. There is no Material text field underneath.
class AppSearchField extends StatefulWidget {
  const AppSearchField({
    required this.controller,
    required this.hint,
    required this.clearLabel,
    required this.onChanged,
    super.key,
    this.focusNode,
    this.onSubmitted,
    this.autofocus = false,
    this.textDirection,
  });

  final TextEditingController controller;
  final String hint;

  /// Announced on the clear button.
  final String clearLabel;
  final ValueChanged<String> onChanged;
  final ValueChanged<String>? onSubmitted;
  final FocusNode? focusNode;
  final bool autofocus;

  /// Set when the text being searched is in a different direction from the app.
  final TextDirection? textDirection;

  @override
  State<AppSearchField> createState() => _AppSearchFieldState();
}

class _AppSearchFieldState extends State<AppSearchField> {
  FocusNode? _ownNode;

  FocusNode get _node => widget.focusNode ?? (_ownNode ??= FocusNode());

  @override
  void dispose() {
    _ownNode?.dispose();
    super.dispose();
  }

  void _clear() {
    widget.controller.clear();
    widget.onChanged('');
    _node.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final AppThemeData theme = AppTheme.of(context);
    final AppPalette p = theme.palette;
    final TextStyle style = theme.text.body.copyWith(color: p.textPrimary);
    return ListenableBuilder(
      listenable: Listenable.merge(<Listenable>[widget.controller, _node]),
      builder: (BuildContext context, Widget? child) {
        final bool empty = widget.controller.text.isEmpty;
        return DecoratedBox(
          decoration: BoxDecoration(
            color: p.bgTertiary,
            borderRadius: BorderRadius.circular(Radii.chip),
            border: Border.all(
              color: _node.hasFocus ? p.borderFocus : const Color(0x00000000),
              width: _node.hasFocus ? 1.5 : 0.5,
            ),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: Metrics.touchTarget),
            child: Row(
              children: <Widget>[
                const SizedBox(width: Sp.md),
                AppIcon(AppIcons.search, size: IconSizes.rowLeading, color: p.textTertiary),
                const SizedBox(width: Sp.sm),
                Expanded(
                  child: Stack(
                    alignment: AlignmentDirectional.centerStart,
                    children: <Widget>[
                      if (empty)
                        ExcludeSemantics(
                          child: Text(
                            widget.hint,
                            style: style.copyWith(color: p.textTertiary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      Semantics(
                        textField: true,
                        label: widget.hint,
                        child: EditableText(
                          controller: widget.controller,
                          focusNode: _node,
                          style: style,
                          cursorColor: p.accent,
                          backgroundCursorColor: p.borderSubtle,
                          selectionColor: p.accent.withValues(alpha: 0.3),
                          autofocus: widget.autofocus,
                          textDirection: widget.textDirection,
                          textInputAction: TextInputAction.search,
                          onChanged: widget.onChanged,
                          onSubmitted: widget.onSubmitted,
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!empty) ...<Widget>[
                  const SizedBox(width: Sp.xs),
                  IconChip(icon: AppIcons.close, semanticLabel: widget.clearLabel, onTap: _clear),
                  const SizedBox(width: Sp.xs),
                ] else
                  const SizedBox(width: Sp.md),
              ],
            ),
          ),
        );
      },
    );
  }
}
