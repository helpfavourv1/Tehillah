import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tehillah/providers/app_scope.dart';

void main() {
  testWidgets('maybeOf is null without a scope', (WidgetTester tester) async {
    AppServices? found = const _Marker().services;
    await tester.pumpWidget(Builder(builder: (BuildContext context) {
      found = AppScope.maybeOf(context);
      return const SizedBox();
    }));
    expect(found, isNull);
  });
}

final class _Marker {
  const _Marker();

  AppServices? get services => null;
}
