import 'package:flutter/widgets.dart';
import 'package:tehillah/theme/icon_aliases.dart';
import 'package:tehillah/theme/tokens.dart';
import 'package:tehillah/widgets/bottom_sheet.dart';
import 'package:tehillah/widgets/primary_button.dart';

/// The pause sheet every play screen uses: Resume (filled) and Leave
/// (secondary). Returns true when the player chose to leave; closing the sheet
/// any other way counts as resume.
Future<bool> showPauseSheet({
  required BuildContext context,
  required String title,
  required String resumeLabel,
  required String leaveLabel,
}) async {
  final bool? leave = await showAppBottomSheet<bool>(
    context: context,
    barrierLabel: resumeLabel,
    title: title,
    builder: (BuildContext sheetContext) => Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        PrimaryButton(
          label: resumeLabel,
          icon: AppIcons.play,
          onPressed: () => Navigator.of(sheetContext).pop(false),
        ),
        const SizedBox(height: Sp.sm),
        SecondaryButton(
          label: leaveLabel,
          icon: AppIcons.close,
          onPressed: () => Navigator.of(sheetContext).pop(true),
        ),
      ],
    ),
  );
  return leave ?? false;
}
