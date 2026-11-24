import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';

/// Makes the test window [size] logical pixels (pixel ratio 1), so a tap at a
/// widget that the harness lays out inside that size really lands on it. The
/// default test window is 800x600 and taps outside it miss.
void useSurface(WidgetTester tester, [Size size = const Size(360, 720)]) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}
