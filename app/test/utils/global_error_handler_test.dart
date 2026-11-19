import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tehillah/core/errors/app_error.dart';
import 'package:tehillah/utils/global_error_handler.dart';

void main() {
  late List<AppError> logged;
  late GlobalErrorHandler handler;

  setUp(() {
    logged = <AppError>[];
    handler = GlobalErrorHandler(
      sink: (AppError error, StackTrace? stack) => logged.add(error),
    );
  });

  tearDown(() {
    handler.dispose();
  });

  test('an unexpected exception is logged and raises the fatal state', () {
    handler.handle(StateError('boom'), StackTrace.current);
    expect(logged, hasLength(1));
    expect(logged.single, isA<FatalError>());
    expect(handler.fatalError.value, isA<FatalError>());
  });

  test('a degraded error is logged but does not raise the fatal state', () {
    handler.handle(
      const ThirdPartyDegradedError('ads.init_failed', 'failed'),
      null,
    );
    expect(logged, hasLength(1));
    expect(handler.fatalError.value, isNull);
  });

  test('a silent error is logged but does not raise the fatal state', () {
    handler.handle(StateError('quiet'), null, silent: true);
    expect(logged, hasLength(1));
    expect(handler.fatalError.value, isNull);
  });

  test('clearFatal resets the state', () {
    handler.handle(StateError('boom'), null);
    expect(handler.fatalError.value, isNotNull);
    handler.clearFatal();
    expect(handler.fatalError.value, isNull);
  });

  test('install hooks framework errors and uninstall restores them', () {
    final FlutterExceptionHandler? before = FlutterError.onError;
    handler.install();
    expect(identical(FlutterError.onError, before), isFalse);
    FlutterError.onError!(FlutterErrorDetails(exception: Exception('framework')));
    expect(logged, hasLength(1));
    expect(handler.fatalError.value, isNotNull);
    handler.uninstall();
    expect(identical(FlutterError.onError, before), isTrue);
  });

  test('install is idempotent', () {
    final FlutterExceptionHandler? before = FlutterError.onError;
    handler.install();
    final FlutterExceptionHandler? hooked = FlutterError.onError;
    handler.install();
    expect(identical(FlutterError.onError, hooked), isTrue);
    handler.uninstall();
    expect(identical(FlutterError.onError, before), isTrue);
  });

  test('install can replace the widget shown for a failed build', () {
    final ErrorWidgetBuilder before = ErrorWidget.builder;
    handler.install(
      widgetBuilder: (FlutterErrorDetails details) => const SizedBox(),
    );
    expect(identical(ErrorWidget.builder, before), isFalse);
    handler.uninstall();
    expect(identical(ErrorWidget.builder, before), isTrue);
  });
}
