import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:tehillah/app/labels_of.dart';
import 'package:tehillah/app/router.dart';
import 'package:tehillah/core/catalog/achievement_catalog.dart';
import 'package:tehillah/core/catalog/stage_catalog.dart';
import 'package:tehillah/core/logic/progression_rules.dart';
import 'package:tehillah/core/models/progress.dart';
import 'package:tehillah/core/models/stage_def.dart';
import 'package:tehillah/l10n/labels.dart';
import 'package:tehillah/providers/app_scope.dart';
import 'package:tehillah/screens/home_screen.dart';
import 'package:tehillah/widgets/ad_slot.dart';

/// Home, wired to progress, achievements, the daily challenge and the ad slot.
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  void _open(String route) => unawaited(Navigator.of(context).pushNamed(route));

  @override
  Widget build(BuildContext context) {
    final AppServices s = AppScope.of(context);
    return ListenableBuilder(
      listenable: Listenable.merge(<Listenable>[s.progress, s.achievements, s.daily]),
      builder: (BuildContext context, Widget? child) {
        final Labels labels = labelsOf(context);
        final Progress progress = s.progress.progress;
        final StageDef? next = ProgressionRules.nextJourneyMatch(progress)?.stage;
        return HomeScreen(
          labels: labels.home(),
          nextStageName: next == null ? null : labels.stageName(next.nameKey),
          lamps: progress.lamps.length,
          totalStages: StageCatalog.stages.length,
          totalStars: progress.totalStars,
          achievementsUnlocked: s.achievements.value.unlocked.length,
          achievementsTotal: AchievementCatalog.all.length,
          dailyDone: s.daily.value.completed,
          dailyStreak: s.daily.value.streak,
          onPlay: () => _open(AppRoutes.journey),
          onJourney: () => _open(AppRoutes.journey),
          onModes: () => _open(AppRoutes.modes),
          onDaily: () => _open(AppRoutes.daily),
          onVerses: () => _open(AppRoutes.verses),
          onAchievements: () => _open(AppRoutes.achievements),
          onSettings: () => _open(AppRoutes.settings),
          bottom: AdSlot(
            state: s.ads,
            onMetrics: (int widthDp, bool keyboardOpen) {
              s.ads.requestBanner(widthDp);
              s.ads.setKeyboardOpen(keyboardOpen);
            },
            bannerBuilder: s.bannerBuilder,
          ),
        );
      },
    );
  }
}
