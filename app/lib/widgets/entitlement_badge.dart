import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:tehillah/providers/entitlement_provider.dart';
import 'package:tehillah/theme/icon_aliases.dart';
import 'package:tehillah/widgets/app_chip.dart';

/// A small "Ads removed" badge, drawn only while the purchase is owned. It
/// reads [Entitlement.adsRemoved]; it never infers ownership.
class EntitlementBadge extends StatelessWidget {
  const EntitlementBadge({required this.entitlement, required this.label, super.key});

  final ValueListenable<Entitlement> entitlement;

  /// The localized text, for example "Ads removed".
  final String label;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: entitlement,
      builder: (BuildContext context, Widget? _) {
        if (!entitlement.value.adsRemoved) {
          return const SizedBox.shrink();
        }
        return AppChip(label: label, icon: AppIcons.check, tone: ChipTone.success);
      },
    );
  }
}
