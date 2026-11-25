import 'package:flutter_test/flutter_test.dart';
import 'package:tehillah/core/storage/progress_store.dart';
import 'package:tehillah/providers/progress_provider.dart';

import '../fakes/fake_storage.dart';

void main() {
  late ProgressProvider progress;

  setUp(() async {
    final FakeLog log = FakeLog();
    progress = ProgressProvider(ProgressStore(FakeStorage(), log), log);
    await progress.load();
  });

  tearDown(() => progress.dispose());

  test('applyJericho records and notifies', () {
    int calls = 0;
    progress.addListener(() => calls++);
    progress.applyJericho(round: 1, won: true);
    expect(progress.progress.jerichoCleared, 1);
    expect(calls, greaterThan(0));
  });

  test('applySling records plays and best', () {
    progress.applySling(stars: 3);
    progress.applySling(stars: 1);
    expect(progress.progress.slingPlays, 2);
    expect(progress.progress.slingBest, 3);
  });
}
