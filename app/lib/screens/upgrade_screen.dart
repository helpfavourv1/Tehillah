import 'package:flutter/widgets.dart';
import 'package:tehillah/core/ports/billing_port.dart';
import 'package:tehillah/theme/app_icon.dart';
import 'package:tehillah/theme/app_theme.dart';
import 'package:tehillah/theme/icon_aliases.dart';
import 'package:tehillah/theme/tokens.dart';
import 'package:tehillah/widgets/app_card.dart';
import 'package:tehillah/widgets/nav_bar.dart';
import 'package:tehillah/widgets/primary_button.dart';
import 'package:tehillah/widgets/screen_frame.dart';
import 'package:tehillah/widgets/scroll_body.dart';

final class UpgradeLabels {
  const UpgradeLabels({
    required this.title,
    required this.back,
    required this.headline,
    required this.benefits,
    required this.notSold,
    required this.buy,
    required this.buyWithPrice,
    required this.restore,
    required this.restoring,
    required this.owned,
    required this.ownedDetail,
    required this.pending,
    required this.unavailable,
  });

  final String title;
  final String back;

  /// "Remove ads for good".
  final String headline;

  /// What the purchase does, one line each.
  final List<String> benefits;

  /// States that nothing in the game is sold and that rewarded ads stay
  /// optional.
  final String notSold;
  final String buy;

  /// "Remove ads, $2.99".
  final String Function(String price) buyWithPrice;
  final String restore;
  final String restoring;
  final String owned;
  final String ownedDetail;
  final String pending;

  /// The store did not answer, so there is no price to show.
  final String unavailable;
}

/// The optional Remove Ads page, reached from Settings; never a blocking
/// modal. Buy is hidden once owned; Restore is always visible. Nothing here
/// promises more than the build does: the purchase removes the banner and the
/// between-match ads, and nothing in the game is sold.
class UpgradeScreen extends StatelessWidget {
  const UpgradeScreen({
    required this.labels,
    required this.status,
    required this.restoring,
    required this.onBuy,
    required this.onRestore,
    required this.onBack,
    super.key,
    this.priceLabel,
  });

  final UpgradeLabels labels;
  final EntitlementStatus status;
  final bool restoring;

  /// The store's localized price, or null before the store has answered.
  final String? priceLabel;
  final VoidCallback onBuy;
  final VoidCallback onRestore;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final AppThemeData theme = AppTheme.of(context);
    final AppPalette p = theme.palette;
    final bool owned = status == EntitlementStatus.owned;
    final bool pending = status == EntitlementStatus.pending;
    final String? price = priceLabel;
    final bool canBuy = !owned && !pending && price != null && !restoring;
    return ScreenFrame(
      navBar: NavBar.back(onBack: onBack, backLabel: labels.back, title: labels.title),
      child: ScrollBody(
        children: <Widget>[
          CardSurface(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                AppIcon(AppIcons.removeAds, size: IconSizes.hero, color: p.accent),
                const SizedBox(height: Sp.md),
                Text(labels.headline, style: theme.text.title1),
                const SizedBox(height: Sp.md),
                for (final String b in labels.benefits)
                  Padding(
                    padding: const EdgeInsets.only(bottom: Sp.sm),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        AppIcon(AppIcons.check, size: IconSizes.rowLeading, color: p.success),
                        const SizedBox(width: Sp.sm),
                        Expanded(child: Text(b, style: theme.text.body)),
                      ],
                    ),
                  ),
                Text(
                  labels.notSold,
                  style: theme.text.footnote.copyWith(color: p.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(height: Sp.lg),
          if (owned)
            CardSurface(
              child: Row(
                children: <Widget>[
                  AppIcon(AppIcons.check, size: IconSizes.hero, color: p.success),
                  const SizedBox(width: Sp.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(labels.owned, style: theme.text.title2),
                        const SizedBox(height: Sp.xxs),
                        Text(
                          labels.ownedDetail,
                          style: theme.text.callout.copyWith(color: p.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )
          else ...<Widget>[
            PrimaryButton(
              label: price == null ? labels.buy : labels.buyWithPrice(price),
              icon: AppIcons.removeAds,
              onPressed: canBuy ? onBuy : null,
            ),
            if (pending || price == null) ...<Widget>[
              const SizedBox(height: Sp.sm),
              Semantics(
                liveRegion: true,
                child: Text(
                  pending ? labels.pending : labels.unavailable,
                  style: theme.text.footnote.copyWith(color: p.textSecondary),
                ),
              ),
            ],
          ],
          const SizedBox(height: Sp.md),
          SecondaryButton(
            label: restoring ? labels.restoring : labels.restore,
            icon: AppIcons.restore,
            onPressed: restoring ? null : onRestore,
          ),
        ],
      ),
    );
  }
}
