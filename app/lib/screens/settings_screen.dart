import 'package:flutter/widgets.dart';
import 'package:tehillah/core/models/settings_model.dart';
import 'package:tehillah/theme/app_theme.dart';
import 'package:tehillah/theme/icon_aliases.dart';
import 'package:tehillah/theme/tokens.dart';
import 'package:tehillah/widgets/app_card.dart';
import 'package:tehillah/widgets/app_row.dart';
import 'package:tehillah/widgets/nav_bar.dart';
import 'package:tehillah/widgets/screen_frame.dart';
import 'package:tehillah/widgets/scroll_body.dart';
import 'package:tehillah/widgets/section_header.dart';
import 'package:tehillah/widgets/segmented_control.dart';
import 'package:tehillah/widgets/toggle_row.dart';

final class SettingsLabels {
  const SettingsLabels({
    required this.title,
    required this.back,
    required this.appearance,
    required this.theme,
    required this.themeSystem,
    required this.themeLight,
    required this.themeDark,
    required this.language,
    required this.play,
    required this.inputScheme,
    required this.inputFlick,
    required this.inputTiming,
    required this.sound,
    required this.music,
    required this.haptics,
    required this.daily,
    required this.reminders,
    required this.remindersDetail,
    required this.reminderTime,
    required this.reading,
    required this.bibleReader,
    required this.bibleReaderDetail,
    required this.purchases,
    required this.removeAds,
    required this.adsRemoved,
    required this.restore,
    required this.restoring,
    required this.privacyChoices,
    required this.data,
    required this.deleteBibles,
    required this.deleteBiblesNone,
    required this.deleteBiblesCount,
    required this.emailLog,
    required this.emailLogDetail,
    required this.about,
    required this.licenses,
    required this.privacyPolicy,
    required this.support,
    required this.version,
  });

  final String title;
  final String back;
  final String appearance;
  final String theme;
  final String themeSystem;
  final String themeLight;
  final String themeDark;
  final String language;
  final String play;
  final String inputScheme;
  final String inputFlick;
  final String inputTiming;
  final String sound;
  final String music;
  final String haptics;
  final String daily;
  final String reminders;
  final String remindersDetail;
  final String reminderTime;
  final String reading;
  final String bibleReader;
  final String bibleReaderDetail;
  final String purchases;
  final String removeAds;

  /// The value shown on the Remove Ads row once it is owned.
  final String adsRemoved;
  final String restore;
  final String restoring;
  final String privacyChoices;
  final String data;
  final String deleteBibles;

  /// The value shown when no Bible is downloaded.
  final String deleteBiblesNone;

  /// "2 downloaded".
  final String Function(int count) deleteBiblesCount;
  final String emailLog;
  final String emailLogDetail;
  final String about;
  final String licenses;
  final String privacyPolicy;
  final String support;

  /// "Version 1.0.0 (12)".
  final String version;
}

/// Every setting in one place. Sections: appearance, play, daily, reading,
/// purchases, data and about. Restore purchase is always visible. Privacy
/// choices appears only when consent says options are required. Delete
/// downloaded Bibles is disabled when there is nothing to delete. Results of
/// actions are reported through the app-wide feedback host, not drawn here.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({
    required this.labels,
    required this.themeChoice,
    required this.onTheme,
    required this.appLanguageName,
    required this.onAppLanguage,
    required this.inputScheme,
    required this.onInputScheme,
    required this.soundOn,
    required this.onSound,
    required this.musicOn,
    required this.onMusic,
    required this.hapticsOn,
    required this.onHaptics,
    required this.remindersOn,
    required this.onReminders,
    required this.reminderTimeLabel,
    required this.onReminderTime,
    required this.onOpenReader,
    required this.adsRemoved,
    required this.onUpgrade,
    required this.restoring,
    required this.onRestore,
    required this.showPrivacyChoices,
    required this.onPrivacyChoices,
    required this.downloadedBibles,
    required this.onDeleteBibles,
    required this.onEmailLog,
    required this.onLicenses,
    required this.onPrivacyPolicy,
    required this.onSupport,
    required this.onBack,
    super.key,
    this.priceLabel,
    this.bottom,
  });

  final SettingsLabels labels;
  final ThemeChoice themeChoice;
  final ValueChanged<ThemeChoice> onTheme;

  /// The app language's own name, or the "Device language" wording.
  final String appLanguageName;
  final VoidCallback onAppLanguage;
  final InputScheme inputScheme;
  final ValueChanged<InputScheme> onInputScheme;
  final bool soundOn;
  final ValueChanged<bool> onSound;
  final bool musicOn;
  final ValueChanged<bool> onMusic;
  final bool hapticsOn;
  final ValueChanged<bool> onHaptics;
  final bool remindersOn;
  final ValueChanged<bool> onReminders;

  /// "18:00" in the locale's format; shown only while reminders are on.
  final String reminderTimeLabel;
  final VoidCallback onReminderTime;
  final VoidCallback onOpenReader;
  final bool adsRemoved;
  final String? priceLabel;
  final VoidCallback onUpgrade;
  final bool restoring;
  final VoidCallback onRestore;
  final bool showPrivacyChoices;
  final VoidCallback onPrivacyChoices;
  final int downloadedBibles;
  final VoidCallback onDeleteBibles;
  final VoidCallback onEmailLog;
  final VoidCallback onLicenses;
  final VoidCallback onPrivacyPolicy;
  final VoidCallback onSupport;
  final VoidCallback onBack;
  final Widget? bottom;

  Widget _group(String header, List<Widget> rows) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        SectionHeader(header, padding: const EdgeInsets.fromLTRB(Sp.xs, Sp.lg, 0, Sp.sm)),
        CardSurface(padding: EdgeInsets.zero, child: Column(children: rows)),
      ],
    );
  }

  Widget _segment<T>(
    BuildContext context,
    String label,
    SegmentedControl<T> control,
  ) {
    final AppThemeData theme = AppTheme.of(context);
    return Padding(
      padding: const EdgeInsets.all(Sp.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(label, style: theme.text.callout),
          const SizedBox(height: Sp.sm),
          control,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ScreenFrame(
      navBar: NavBar.back(onBack: onBack, backLabel: labels.back, title: labels.title),
      bottom: bottom,
      child: ScrollBody(
        padding: const EdgeInsets.fromLTRB(Sp.md, Sp.xs, Sp.md, Sp.lg),
        children: <Widget>[
          _group(labels.appearance, <Widget>[
            _segment<ThemeChoice>(
              context,
              labels.theme,
              SegmentedControl<ThemeChoice>(
                semanticLabel: labels.theme,
                options: <SegmentOption<ThemeChoice>>[
                  SegmentOption<ThemeChoice>(value: ThemeChoice.system, label: labels.themeSystem),
                  SegmentOption<ThemeChoice>(value: ThemeChoice.light, label: labels.themeLight),
                  SegmentOption<ThemeChoice>(value: ThemeChoice.dark, label: labels.themeDark),
                ],
                selected: themeChoice,
                onChanged: onTheme,
              ),
            ),
            AppRow(
              label: labels.language,
              value: appLanguageName,
              leading: AppIcons.language,
              onTap: onAppLanguage,
            ),
          ]),
          _group(labels.play, <Widget>[
            _segment<InputScheme>(
              context,
              labels.inputScheme,
              SegmentedControl<InputScheme>(
                semanticLabel: labels.inputScheme,
                options: <SegmentOption<InputScheme>>[
                  SegmentOption<InputScheme>(value: InputScheme.flick, label: labels.inputFlick),
                  SegmentOption<InputScheme>(
                    value: InputScheme.timingBar,
                    label: labels.inputTiming,
                  ),
                ],
                selected: inputScheme,
                onChanged: onInputScheme,
              ),
            ),
            ToggleRow(
              label: labels.sound,
              leading: soundOn ? AppIcons.sound : AppIcons.soundOff,
              value: soundOn,
              onChanged: onSound,
            ),
            ToggleRow(
              label: labels.music,
              leading: AppIcons.sound,
              value: musicOn,
              onChanged: onMusic,
            ),
            ToggleRow(
              label: labels.haptics,
              leading: AppIcons.haptics,
              value: hapticsOn,
              onChanged: onHaptics,
            ),
          ]),
          _group(labels.daily, <Widget>[
            ToggleRow(
              label: labels.reminders,
              subtitle: labels.remindersDetail,
              leading: AppIcons.reminder,
              value: remindersOn,
              onChanged: onReminders,
            ),
            if (remindersOn)
              AppRow(
                label: labels.reminderTime,
                value: reminderTimeLabel,
                leading: AppIcons.timer,
                onTap: onReminderTime,
              ),
          ]),
          _group(labels.reading, <Widget>[
            AppRow(
              label: labels.bibleReader,
              subtitle: labels.bibleReaderDetail,
              leading: AppIcons.reader,
              onTap: onOpenReader,
            ),
          ]),
          _group(labels.purchases, <Widget>[
            AppRow(
              label: labels.removeAds,
              value: adsRemoved ? labels.adsRemoved : priceLabel,
              leading: AppIcons.removeAds,
              onTap: onUpgrade,
            ),
            AppRow(
              label: restoring ? labels.restoring : labels.restore,
              leading: AppIcons.restore,
              chevron: false,
              onTap: restoring ? null : onRestore,
            ),
            if (showPrivacyChoices)
              AppRow(
                label: labels.privacyChoices,
                leading: AppIcons.privacy,
                onTap: onPrivacyChoices,
              ),
          ]),
          _group(labels.data, <Widget>[
            AppRow(
              label: labels.deleteBibles,
              value: downloadedBibles == 0
                  ? labels.deleteBiblesNone
                  : labels.deleteBiblesCount(downloadedBibles),
              leading: AppIcons.delete,
              chevron: false,
              onTap: downloadedBibles == 0 ? null : onDeleteBibles,
            ),
            AppRow(
              label: labels.emailLog,
              subtitle: labels.emailLogDetail,
              leading: AppIcons.email,
              onTap: onEmailLog,
            ),
          ]),
          _group(labels.about, <Widget>[
            AppRow(label: labels.licenses, leading: AppIcons.license, onTap: onLicenses),
            AppRow(label: labels.privacyPolicy, leading: AppIcons.privacy, onTap: onPrivacyPolicy),
            AppRow(label: labels.support, leading: AppIcons.info, onTap: onSupport),
          ]),
          Padding(
            padding: const EdgeInsets.only(top: Sp.lg),
            child: Center(
              child: Text(
                labels.version,
                style: AppTheme.of(context).text.footnote.copyWith(
                      color: AppTheme.of(context).palette.textTertiary,
                    ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
