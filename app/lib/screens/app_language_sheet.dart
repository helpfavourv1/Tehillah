import 'package:flutter/widgets.dart';
import 'package:tehillah/screens/onboarding_screen.dart';
import 'package:tehillah/theme/icon_aliases.dart';
import 'package:tehillah/widgets/app_card.dart';
import 'package:tehillah/widgets/app_row.dart';

final class AppLanguageLabels {
  const AppLanguageLabels({
    required this.followDevice,
    required this.followDeviceDetail,
    required this.selected,
  });

  /// "Same as device".
  final String followDevice;

  /// Names the language it resolves to now, for example "Currently English".
  final String followDeviceDetail;

  /// Said after the chosen row.
  final String selected;
}

/// The content of the app language sheet: "Same as device" first, then the
/// eleven languages in their own names. [selectedCode] null means the device
/// language is followed. The sheet scrolls inside `showAppBottomSheet`.
class AppLanguageSheet extends StatelessWidget {
  const AppLanguageSheet({
    required this.labels,
    required this.languages,
    required this.selectedCode,
    required this.onPick,
    super.key,
  });

  final AppLanguageLabels labels;
  final List<OnboardingLanguage> languages;
  final String? selectedCode;

  /// Null means follow the device.
  final ValueChanged<String?> onPick;

  @override
  Widget build(BuildContext context) {
    return CardSurface(
      padding: EdgeInsets.zero,
      child: Column(
        children: <Widget>[
          AppRow(
            label: labels.followDevice,
            subtitle: labels.followDeviceDetail,
            leading: selectedCode == null ? AppIcons.check : AppIcons.language,
            chevron: false,
            semanticLabel:
                selectedCode == null ? '${labels.followDevice}. ${labels.selected}' : labels.followDevice,
            onTap: () => onPick(null),
          ),
          for (final OnboardingLanguage l in languages)
            AppRow(
              label: l.name,
              leading: l.code == selectedCode ? AppIcons.check : null,
              chevron: false,
              semanticLabel: l.code == selectedCode ? '${l.name}. ${labels.selected}' : l.name,
              onTap: () => onPick(l.code),
            ),
        ],
      ),
    );
  }
}
