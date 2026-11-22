import 'package:flutter/widgets.dart';
import 'package:tehillah/theme/app_theme.dart';
import 'package:tehillah/theme/icon_aliases.dart';
import 'package:tehillah/theme/tokens.dart';
import 'package:tehillah/theme/typography.dart';
import 'package:tehillah/widgets/icon_chip.dart';

/// The brand wordmark. It appears once per screen, in the nav bar; the name
/// comes from the caller (it is a localized string), never from this file.
class BrandWordmark extends StatelessWidget {
  const BrandWordmark(this.name, {super.key});

  final String name;

  @override
  Widget build(BuildContext context) {
    final AppThemeData theme = AppTheme.of(context);
    return Semantics(
      header: true,
      child: Text(
        name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.text.title1.copyWith(
          fontFamily: AppFonts.chrome,
          fontWeight: FontWeight.w700,
          color: theme.palette.accent,
        ),
      ),
    );
  }
}

/// The top chrome of every screen: the brand or a back chip at the start, the
/// title, and action chips at the end. Content begins below it.
class NavBar extends StatelessWidget {
  const NavBar({super.key, this.leading, this.title, this.actions = const <Widget>[]});

  /// A back button on inner screens.
  factory NavBar.back({
    required VoidCallback onBack,
    required String backLabel,
    Key? key,
    String? title,
    List<Widget> actions = const <Widget>[],
  }) {
    return NavBar(
      key: key,
      leading: IconChip(icon: AppIcons.back, semanticLabel: backLabel, onTap: onBack),
      title: title,
      actions: actions,
    );
  }

  /// The brand on the home screen.
  factory NavBar.brand({
    required String name,
    Key? key,
    List<Widget> actions = const <Widget>[],
  }) {
    return NavBar(key: key, leading: BrandWordmark(name), actions: actions);
  }

  /// A [BrandWordmark] or an [IconChip] for back.
  final Widget? leading;
  final String? title;

  /// [IconChip]s, in order from the start.
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final AppThemeData theme = AppTheme.of(context);
    final bool brandLeading = leading is BrandWordmark;
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: Metrics.navBarHeight),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: Sp.md, vertical: Sp.xs),
        child: Row(
          children: <Widget>[
            if (leading != null)
              brandLeading ? Flexible(child: leading!) : leading!,
            if (title != null) ...<Widget>[
              SizedBox(width: leading != null && !brandLeading ? Sp.sm : Sp.md),
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(
                    title!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.text.title2,
                  ),
                ),
              ),
            ] else
              const Spacer(),
            for (final Widget action in actions) ...<Widget>[
              const SizedBox(width: Sp.sm),
              action,
            ],
          ],
        ),
      ),
    );
  }
}
