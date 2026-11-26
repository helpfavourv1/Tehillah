import 'package:flutter/widgets.dart';
import 'package:tehillah/theme/app_theme.dart';
import 'package:tehillah/theme/icon_aliases.dart';
import 'package:tehillah/theme/tokens.dart';
import 'package:tehillah/widgets/app_card.dart';
import 'package:tehillah/widgets/app_chip.dart';
import 'package:tehillah/widgets/primary_button.dart';

final class ReminderTimeLabels {
  const ReminderTimeLabels({
    required this.hour,
    required this.minute,
    required this.earlier,
    required this.later,
    required this.timeOf,
    required this.save,
  });

  final String hour;
  final String minute;
  final String earlier;
  final String later;

  /// The chosen time in the locale's format, for the large display.
  final String Function(int hour, int minute) timeOf;
  final String save;
}

/// The content of the reminder time sheet. Hours step by one and minutes by
/// five, each wrapping around, so every time of day is reachable with 48 dp
/// controls and no wheel picker. The caller saves the minute of day.
class ReminderTimeSheet extends StatefulWidget {
  const ReminderTimeSheet({
    required this.labels,
    required this.minuteOfDay,
    required this.onSave,
    super.key,
  });

  final ReminderTimeLabels labels;

  /// Minutes after midnight, 0 to 1439.
  final int minuteOfDay;
  final ValueChanged<int> onSave;

  @override
  State<ReminderTimeSheet> createState() => _ReminderTimeSheetState();
}

class _ReminderTimeSheetState extends State<ReminderTimeSheet> {
  late int _hour = (widget.minuteOfDay ~/ 60).clamp(0, 23);
  late int _minute = ((widget.minuteOfDay % 60) ~/ 5) * 5;

  void _hourBy(int d) => setState(() => _hour = (_hour + d + 24) % 24);
  void _minuteBy(int d) => setState(() => _minute = (_minute + d * 5 + 60) % 60);

  Widget _stepper(String label, VoidCallback less, VoidCallback more) {
    final ReminderTimeLabels l = widget.labels;
    return Row(
      children: <Widget>[
        Expanded(child: Text(label, style: AppTheme.of(context).text.callout)),
        AppChip(label: l.earlier, icon: AppIcons.back, onTap: less),
        const SizedBox(width: Sp.sm),
        AppChip(label: l.later, icon: AppIcons.forward, onTap: more),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppThemeData theme = AppTheme.of(context);
    final ReminderTimeLabels l = widget.labels;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        CardSurface(
          child: Center(
            child: Semantics(
              liveRegion: true,
              child: Text(l.timeOf(_hour, _minute), style: theme.text.display),
            ),
          ),
        ),
        const SizedBox(height: Sp.md),
        _stepper(l.hour, () => _hourBy(-1), () => _hourBy(1)),
        const SizedBox(height: Sp.sm),
        _stepper(l.minute, () => _minuteBy(-1), () => _minuteBy(1)),
        const SizedBox(height: Sp.lg),
        PrimaryButton(
          label: l.save,
          icon: AppIcons.check,
          onPressed: () => widget.onSave(_hour * 60 + _minute),
        ),
      ],
    );
  }
}
