import 'package:flutter/widgets.dart';
import 'package:tehillah/l10n/gen/app_localizations.dart';
import 'package:tehillah/l10n/labels.dart';

/// The labels for the language in force at [context]. Rebuilds with the
/// language because it depends on the localizations scope.
Labels labelsOf(BuildContext context) =>
    Labels(AppLocalizations.of(context), Localizations.localeOf(context));
