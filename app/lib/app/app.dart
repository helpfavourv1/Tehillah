import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:tehillah/app/boot.dart';
import 'package:tehillah/app/labels_of.dart';
import 'package:tehillah/app/locale_codes.dart';
import 'package:tehillah/app/router.dart';
import 'package:tehillah/app/theme_fade.dart';
import 'package:tehillah/core/config/app_config.dart';
import 'package:tehillah/core/errors/app_error.dart';
import 'package:tehillah/core/ports/log_port.dart';
import 'package:tehillah/l10n/gen/app_localizations.dart';
import 'package:tehillah/l10n/labels.dart';
import 'package:tehillah/providers/app_scope.dart';
import 'package:tehillah/theme/tokens.dart';
import 'package:tehillah/utils/global_error_handler.dart';
import 'package:tehillah/widgets/error_state_view.dart';
import 'package:tehillah/widgets/feedback_banner.dart';

/// The app shell: localization, theme, app-wide feedback, the fatal-error
/// fallback and the navigator. No Material, no Cupertino.
class TehillahApp extends StatefulWidget {
  const TehillahApp({required this.services, required this.errors, super.key});

  final AppServices services;
  final GlobalErrorHandler errors;

  @override
  State<TehillahApp> createState() => _TehillahAppState();
}

class _TehillahAppState extends State<TehillahApp> {
  late final String _initialRoute =
      widget.services.settings.value.onboardingDone ? AppRoutes.home : AppRoutes.onboarding;

  @override
  void initState() {
    super.initState();
    widget.errors.install(widgetBuilder: _widgetError);
    startBackgroundWork(widget.services);
  }

  Widget _widgetError(FlutterErrorDetails details) => const SizedBox.shrink();

  Locale _locale() =>
      localeForCode(widget.services.locale.value.appLanguage(deviceLanguages()));

  @override
  Widget build(BuildContext context) {
    final AppServices s = widget.services;
    return AppScope(
      services: s,
      child: ListenableBuilder(
        listenable: s.locale,
        builder: (BuildContext context, Widget? child) {
          return WidgetsApp(
            color: AppPalette.forMode(PaletteMode.light).accent,
            locale: _locale(),
            localizationsDelegates: const <LocalizationsDelegate<Object?>>[
              AppLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            initialRoute: _initialRoute,
            onGenerateRoute: onGenerateRoute,
            onUnknownRoute: onUnknownRoute,
            pageRouteBuilder: <T>(RouteSettings settings, WidgetBuilder builder) =>
                appRoute<T>(settings, builder),
            builder: (BuildContext context, Widget? navigator) => _Shell(
              services: s,
              errors: widget.errors,
              child: navigator ?? const SizedBox.shrink(),
            ),
          );
        },
      ),
    );
  }
}

/// Theme, feedback and the fatal fallback around the navigator.
class _Shell extends StatelessWidget {
  const _Shell({required this.services, required this.errors, required this.child});

  final AppServices services;
  final GlobalErrorHandler errors;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final bool platformDark = MediaQuery.platformBrightnessOf(context) == Brightness.dark;
    final Locale locale = Localizations.localeOf(context);
    return ListenableBuilder(
      listenable: services.theme,
      builder: (BuildContext context, Widget? _) {
        final PaletteMode mode =
            services.theme.value.isDark(platformIsDark: platformDark) ? PaletteMode.dark : PaletteMode.light;
        return ThemeFade(
          mode: mode,
          locale: locale,
          child: DefaultTextStyleHost(
            child: ValueListenableBuilder<AppError?>(
              valueListenable: errors.fatalError,
              builder: (BuildContext context, AppError? fatal, Widget? _) {
                if (fatal != null) {
                  return _Fallback(services: services, errors: errors, error: fatal);
                }
                return FeedbackHost(
                  feedback: services.feedback,
                  dismissLabel: labelsOf(context).l.commonDismiss,
                  child: child,
                );
              },
            ),
          ),
        );
      },
    );
  }
}

/// Gives plain Text a sane default style under the app theme.
class DefaultTextStyleHost extends StatelessWidget {
  const DefaultTextStyleHost({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DefaultTextStyle(
      style: const TextStyle(fontFamily: 'Inter', fontSize: 17),
      child: child,
    );
  }
}

class _Fallback extends StatelessWidget {
  const _Fallback({required this.services, required this.errors, required this.error});

  final AppServices services;
  final GlobalErrorHandler errors;
  final AppError error;

  Future<void> _report(Labels labels) async {
    final String lines = await services.log.exportText();
    await services.url.openMail(
      to: AppConfig.supportEmail,
      subject: labels.l.errorMailSubject,
      body: '${error.code}\n\n$lines',
    );
  }

  @override
  Widget build(BuildContext context) {
    final Labels labels = labelsOf(context);
    return ErrorStateView(
      title: labels.l.errorTitle,
      message: labels.l.errorMessage,
      retryLabel: labels.l.errorRetry,
      onRetry: errors.clearFatal,
      reportLabel: labels.l.errorReport,
      onReport: () {
        services.log.log(LogLevel.info, 'app', 'report requested for ${error.code}');
        unawaited(_report(labels));
      },
      detail: error.code,
    );
  }
}
