import 'package:tehillah/core/models/curated_verse.dart';
import 'package:tehillah/core/models/verse.dart';
import 'package:tehillah/core/verses/verse_repository.dart';
import 'package:tehillah/providers/locale_provider.dart';
import 'package:tehillah/providers/safe_notifier.dart';

/// Serves the bundled verses in the interface language. The value is the
/// language in use (so widgets rebuild when it changes); a language with no
/// bundled text falls back to English.
final class VerseProvider extends SafeNotifier<String> {
  VerseProvider(
    this._repository,
    this._locale,
    this._deviceLanguages,
  ) : super(_pick(_repository, _locale, _deviceLanguages)) {
    _locale.addListener(_sync);
  }

  /// How many recently shown verses are avoided when picking the next one.
  static const int recentWindow = 8;

  final VerseRepository _repository;
  final LocaleProvider _locale;
  final List<String> Function() _deviceLanguages;
  final List<String> _recent = <String>[];

  static String _pick(
    VerseRepository repo,
    LocaleProvider locale,
    List<String> Function() device,
  ) {
    final String wanted = locale.value.appLanguage(device());
    return repo.hasLanguage(wanted) ? wanted : 'en';
  }

  void _sync() => value = _pick(_repository, _locale, _deviceLanguages);

  /// A verse for a game moment, different from the last few shown. Null only
  /// if nothing is bundled for that moment.
  Verse? verseFor(VerseMoment moment, {required int seed}) {
    final Verse? verse = _repository.forMoment(
      moment,
      value,
      seed: seed,
      recent: _recent.toSet(),
    );
    if (verse == null) {
      return null;
    }
    final String? id = _repository.idFor(verse.ref);
    if (id != null) {
      _recent
        ..remove(id)
        ..add(id);
      while (_recent.length > recentWindow) {
        _recent.removeAt(0);
      }
    }
    return verse;
  }

  /// The Verse library list, optionally for one moment.
  List<Verse> library({VerseMoment? moment}) => _repository.library(value, moment: moment);

  @override
  void dispose() {
    _locale.removeListener(_sync);
    super.dispose();
  }
}
