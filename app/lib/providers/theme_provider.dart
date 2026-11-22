import 'package:flutter/foundation.dart';
import 'package:tehillah/core/models/settings_model.dart';
import 'package:tehillah/providers/safe_notifier.dart';
import 'package:tehillah/providers/settings_provider.dart';

/// The theme choices as one immutable value.
@immutable
final class ThemeState {
  const ThemeState({required this.choice, required this.readerTheme});

  final ThemeChoice choice;
  final ReaderTheme readerTheme;

  /// Whether the app chrome is dark, given the device's brightness.
  bool isDark({required bool platformIsDark}) {
    switch (choice) {
      case ThemeChoice.system:
        return platformIsDark;
      case ThemeChoice.light:
        return false;
      case ThemeChoice.dark:
        return true;
    }
  }

  @override
  bool operator ==(Object other) =>
      other is ThemeState && other.choice == choice && other.readerTheme == readerTheme;

  @override
  int get hashCode => Object.hash(choice, readerTheme);
}

/// The app theme and the reader theme. It follows [SettingsProvider]; changes
/// made here are saved there.
final class ThemeProvider extends SafeNotifier<ThemeState> {
  ThemeProvider(this._settings)
      : super(ThemeState(
          choice: _settings.value.themeChoice,
          readerTheme: _settings.value.readerTheme,
        )) {
    _settings.addListener(_sync);
  }

  final SettingsProvider _settings;

  void _sync() {
    final SettingsModel s = _settings.value;
    value = ThemeState(choice: s.themeChoice, readerTheme: s.readerTheme);
  }

  void setChoice(ThemeChoice choice) =>
      _settings.update((SettingsModel s) => s.copyWith(themeChoice: choice));

  void setReaderTheme(ReaderTheme theme) =>
      _settings.update((SettingsModel s) => s.copyWith(readerTheme: theme));

  @override
  void dispose() {
    _settings.removeListener(_sync);
    super.dispose();
  }
}
