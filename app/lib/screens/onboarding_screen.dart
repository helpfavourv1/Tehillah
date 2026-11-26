import 'package:flutter/widgets.dart';
import 'package:tehillah/theme/app_theme.dart';
import 'package:tehillah/theme/icon_aliases.dart';
import 'package:tehillah/theme/tokens.dart';
import 'package:tehillah/widgets/app_card.dart';
import 'package:tehillah/widgets/app_row.dart';
import 'package:tehillah/widgets/nav_bar.dart';
import 'package:tehillah/widgets/primary_button.dart';
import 'package:tehillah/widgets/screen_frame.dart';
import 'package:tehillah/widgets/section_header.dart';

/// One choosable interface language, named in its own language.
final class OnboardingLanguage {
  const OnboardingLanguage({required this.code, required this.name});

  final String code;
  final String name;
}

final class OnboardingLabels {
  const OnboardingLabels({
    required this.appName,
    required this.promise,
    required this.languageHeader,
    required this.play,
    required this.selected,
  });

  final String appName;

  /// One line about the game.
  final String promise;
  final String languageHeader;
  final String play;

  /// Said after the chosen language.
  final String selected;
}

/// First run: the brand once, one promise line, the language choice and one
/// fixed Play button. Picking a language changes the app language at once, so
/// the labels the caller passes in change under the player's finger. Only the
/// language list scrolls. The consent form, where required, is shown by the
/// platform after Play, not drawn here.
class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({
    required this.labels,
    required this.languages,
    required this.selectedCode,
    required this.onLanguage,
    required this.onPlay,
    super.key,
  });

  final OnboardingLabels labels;
  final List<OnboardingLanguage> languages;
  final String selectedCode;
  final ValueChanged<String> onLanguage;
  final VoidCallback onPlay;

  @override
  Widget build(BuildContext context) {
    final AppThemeData theme = AppTheme.of(context);
    return ScreenFrame(
      navBar: NavBar.brand(name: labels.appName),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(Sp.md, Sp.md, Sp.md, 0),
            child: Text(
              labels.promise,
              style: theme.text.headline.copyWith(color: theme.palette.textPrimary),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(Sp.md, Sp.sm, Sp.md, Sp.md),
              children: <Widget>[
                SectionHeader(
                  labels.languageHeader,
                  padding: const EdgeInsets.only(top: Sp.sm, bottom: Sp.sm),
                ),
                CardSurface(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: <Widget>[
                      for (final OnboardingLanguage l in languages)
                        AppRow(
                          label: l.name,
                          leading: l.code == selectedCode ? AppIcons.check : null,
                          chevron: false,
                          semanticLabel:
                              l.code == selectedCode ? '${l.name}. ${labels.selected}' : l.name,
                          onTap: () => onLanguage(l.code),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(Sp.md, Sp.sm, Sp.md, Sp.md),
            child: PrimaryButton(label: labels.play, icon: AppIcons.play, onPressed: onPlay),
          ),
        ],
      ),
    );
  }
}
