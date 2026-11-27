import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:tehillah/app/boot.dart';
import 'package:tehillah/app/labels_of.dart';
import 'package:tehillah/app/router.dart';
import 'package:tehillah/core/models/language_names.dart';
import 'package:tehillah/core/models/settings_model.dart';
import 'package:tehillah/providers/app_scope.dart';
import 'package:tehillah/screens/onboarding_screen.dart';

/// First run: pick a language, press Play. The consent form, where the law
/// requires one, is shown by the platform right after Play.
class OnboardingPage extends StatelessWidget {
  const OnboardingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final AppServices s = AppScope.of(context);
    return ListenableBuilder(
      listenable: s.locale,
      builder: (BuildContext context, Widget? child) {
        return OnboardingScreen(
          labels: labelsOf(context).onboarding(),
          languages: <OnboardingLanguage>[
            for (final ({String code, String name}) l in LanguageNames.all)
              OnboardingLanguage(code: l.code, name: l.name),
          ],
          selectedCode: s.locale.value.appLanguage(deviceLanguages()),
          onLanguage: s.locale.setAppLanguage,
          onPlay: () {
            s.settings.update((SettingsModel m) => m.copyWith(onboardingDone: true));
            unawaited(s.consent.refreshOnLaunch());
            unawaited(Navigator.of(context).pushReplacementNamed(AppRoutes.home));
          },
        );
      },
    );
  }
}
