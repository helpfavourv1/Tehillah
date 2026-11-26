import 'package:flutter/widgets.dart';
import 'package:tehillah/core/models/license_notice.dart';
import 'package:tehillah/theme/app_theme.dart';
import 'package:tehillah/theme/icon_aliases.dart';
import 'package:tehillah/theme/tokens.dart';
import 'package:tehillah/widgets/app_card.dart';
import 'package:tehillah/widgets/app_chip.dart';
import 'package:tehillah/widgets/empty_state.dart';
import 'package:tehillah/widgets/nav_bar.dart';
import 'package:tehillah/widgets/screen_frame.dart';

final class LicensesLabels {
  const LicensesLabels({
    required this.title,
    required this.back,
    required this.intro,
    required this.openLink,
    required this.emptyTitle,
    required this.emptySubtitle,
  });

  final String title;
  final String back;

  /// One line on why these notices are shown.
  final String intro;

  /// The link chip: "Read the license".
  final String openLink;
  final String emptyTitle;
  final String emptySubtitle;
}

/// Every source's notice, exactly as its license requires: the translation
/// credit lines, the Hindi and Portuguese attributions, Hebrew's two notices,
/// the Korean Bible Society credit, and the fonts and icons. The attribution
/// text is shown verbatim and selectable by the platform's semantics. Notices
/// come in as data; the list is built lazily.
class LicensesScreen extends StatelessWidget {
  const LicensesScreen({
    required this.labels,
    required this.notices,
    required this.onOpenLink,
    required this.onBack,
    super.key,
  });

  final LicensesLabels labels;
  final List<LicenseNotice> notices;
  final void Function(String url) onOpenLink;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final AppThemeData theme = AppTheme.of(context);
    final AppPalette p = theme.palette;
    return ScreenFrame(
      navBar: NavBar.back(onBack: onBack, backLabel: labels.back, title: labels.title),
      child: notices.isEmpty
          ? EmptyState(
              icon: AppIcons.license,
              title: labels.emptyTitle,
              subtitle: labels.emptySubtitle,
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(Sp.md, Sp.sm, Sp.md, Sp.lg),
              itemCount: notices.length + 1,
              separatorBuilder: (BuildContext c, int i) => const SizedBox(height: Sp.md),
              itemBuilder: (BuildContext c, int i) {
                if (i == 0) {
                  return Text(
                    labels.intro,
                    style: theme.text.callout.copyWith(color: p.textSecondary),
                  );
                }
                final LicenseNotice n = notices[i - 1];
                final String? link = n.link;
                return CardSurface(
                  key: ValueKey<String>(n.id),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(n.title, style: theme.text.title2),
                      const SizedBox(height: Sp.xs),
                      AppChip(label: n.license, icon: AppIcons.license),
                      const SizedBox(height: Sp.sm),
                      Text(n.attribution, style: theme.text.callout),
                      if (link != null) ...<Widget>[
                        const SizedBox(height: Sp.sm),
                        AppChip(
                          label: labels.openLink,
                          icon: AppIcons.forward,
                          onTap: () => onOpenLink(link),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
    );
  }
}
