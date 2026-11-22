import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:tehillah/core/errors/app_error.dart';
import 'package:tehillah/core/models/language_codes.dart';
import 'package:tehillah/core/models/pack_manifest.dart';
import 'package:tehillah/core/models/remote_flags.dart';
import 'package:tehillah/core/ports/connectivity_port.dart';
import 'package:tehillah/core/ports/log_port.dart';
import 'package:tehillah/core/ports/pack_port.dart';
import 'package:tehillah/providers/safe_notifier.dart';

enum PackPhase { notInstalled, downloading, installed, failed, blocked }

/// One language's Bible pack.
@immutable
final class PackStatus {
  const PackStatus(this.phase, {this.progress = 0, this.error});

  static const PackStatus notInstalled = PackStatus(PackPhase.notInstalled);
  static const PackStatus installed = PackStatus(PackPhase.installed, progress: 1);

  final PackPhase phase;

  /// 0 to 1 while downloading.
  final double progress;

  /// Why it failed or is blocked. The UI picks its text from [AppError.code].
  final AppError? error;

  @override
  bool operator ==(Object other) =>
      other is PackStatus &&
      other.phase == phase &&
      other.progress == progress &&
      other.error?.code == error?.code;

  @override
  int get hashCode => Object.hash(phase, progress, error?.code);
}

@immutable
final class PackState {
  const PackState(this.statuses);

  final Map<String, PackStatus> statuses;

  PackStatus of(String language) => statuses[language] ?? PackStatus.notInstalled;

  bool isInstalled(String language) => of(language).phase == PackPhase.installed;

  /// The language being downloaded now, if any.
  String? get busyLanguage {
    for (final MapEntry<String, PackStatus> e in statuses.entries) {
      if (e.value.phase == PackPhase.downloading) {
        return e.key;
      }
    }
    return null;
  }

  @override
  bool operator ==(Object other) => other is PackState && mapEquals(other.statuses, statuses);

  @override
  int get hashCode => Object.hashAllUnordered(
        statuses.entries.map((MapEntry<String, PackStatus> e) => Object.hash(e.key, e.value)),
      );
}

/// The download lifecycle of the full-Bible packs. Nothing here runs until the
/// player asks; a failure is a state, never a crash, and play is never
/// blocked.
final class PackProvider extends SafeNotifier<PackState> {
  PackProvider({
    required PackPort packs,
    required ConnectivityPort connectivity,
    required ValueListenable<RemoteFlags> flags,
    required LogPort log,
  })  : _packs = packs,
        _connectivity = connectivity,
        _flags = flags,
        _log = log,
        super(PackState(<String, PackStatus>{
          for (final String l in LanguageCodes.all) l: PackStatus.notInstalled,
        }));

  final PackPort _packs;
  final ConnectivityPort _connectivity;
  final ValueListenable<RemoteFlags> _flags;
  final LogPort _log;
  bool _cancelRequested = false;

  void _set(String language, PackStatus status) {
    value = PackState(<String, PackStatus>{...value.statuses, language: status});
  }

  /// Reads which Bibles are installed. A language that is mid-download or has
  /// a failure keeps that status unless it turns out to be installed.
  Future<void> refresh() async {
    Set<String> installed;
    try {
      installed = await _packs.installedLanguages();
    } on Object catch (error) {
      _log.log(LogLevel.warning, 'packs', 'could not list installed packs: $error');
      return;
    }
    final Map<String, PackStatus> next = <String, PackStatus>{};
    for (final String l in LanguageCodes.all) {
      final PackStatus current = value.of(l);
      if (installed.contains(l)) {
        next[l] = PackStatus.installed;
      } else if (current.phase == PackPhase.downloading || current.phase == PackPhase.failed) {
        next[l] = current;
      } else {
        next[l] = PackStatus.notInstalled;
      }
    }
    value = PackState(next);
  }

  /// Downloads a language's Bible. [wifiOnly] follows the player's choice in
  /// the download prompt. One download runs at a time.
  Future<void> download(String language, {required bool wifiOnly}) async {
    if (!LanguageCodes.isSupported(language) ||
        value.busyLanguage != null ||
        value.isInstalled(language)) {
      return;
    }
    if (!_flags.value.readerDownloadEnabled) {
      _set(
        language,
        const PackStatus(
          PackPhase.blocked,
          error: UserRecoverableError('pack.disabled', 'downloads are switched off'),
        ),
      );
      return;
    }
    _cancelRequested = false;
    _set(language, const PackStatus(PackPhase.downloading));
    try {
      final ConnectionKind kind = await _connectivity.current();
      if (kind == ConnectionKind.none) {
        throw const UserRecoverableError('pack.offline', 'no connection');
      }
      if (wifiOnly && kind != ConnectionKind.wifi) {
        throw const UserRecoverableError('pack.needs_wifi', 'Wi-Fi only is chosen');
      }
      final PackManifest manifest = await _packs.fetchManifest();
      final PackManifestEntry? entry = manifest.forLanguage(language);
      if (entry == null) {
        throw const SystemRecoverableError('pack.not_listed', 'this Bible is not listed');
      }
      await for (final PackProgress p in _packs.download(entry)) {
        if (_cancelRequested) {
          _set(language, PackStatus.notInstalled);
          return;
        }
        _set(language, PackStatus(PackPhase.downloading, progress: p.fraction));
      }
      if (_cancelRequested) {
        _set(language, PackStatus.notInstalled);
        return;
      }
      _set(language, PackStatus.installed);
    } on Object catch (error) {
      final AppError classified = AppError.classify(error, code: 'pack.unexpected');
      _log.log(LogLevel.warning, 'packs', 'download of $language failed: $classified');
      _set(language, PackStatus(PackPhase.failed, error: classified));
    }
  }

  /// Stops the running download. A resumable partial file is kept.
  void cancel() => _cancelRequested = true;

  /// Removes an installed Bible.
  Future<void> delete(String language) async {
    try {
      await _packs.delete(language);
    } on Object catch (error) {
      _log.log(LogLevel.warning, 'packs', 'delete of $language failed: $error');
    }
    await refresh();
    if (value.isInstalled(language)) {
      return;
    }
    _set(language, PackStatus.notInstalled);
  }
}
