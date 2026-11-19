import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'package:tehillah/core/errors/app_error.dart';

/// Receives every error that reaches the global handler, for the local log.
typedef ErrorSink = void Function(AppError error, StackTrace? stack);

/// Installs the app's global error hooks and routes everything through the
/// error taxonomy. Instance based, so tests can create and dispose their own.
class GlobalErrorHandler {
  GlobalErrorHandler({required this.sink});

  final ErrorSink sink;

  /// Set when an error needs the full-screen fallback. The app shell listens
  /// to this and shows the fallback with a retry and a report link.
  final ValueNotifier<AppError?> fatalError = ValueNotifier<AppError?>(null);

  FlutterExceptionHandler? _previousFlutterHandler;
  ErrorCallback? _previousPlatformHandler;
  ErrorWidgetBuilder? _previousWidgetBuilder;
  bool _installed = false;

  /// Hooks framework errors, uncaught asynchronous errors and, when given,
  /// the widget shown in place of a widget that failed to build.
  void install({ErrorWidgetBuilder? widgetBuilder}) {
    if (_installed) {
      return;
    }
    _installed = true;
    _previousFlutterHandler = FlutterError.onError;
    _previousPlatformHandler = PlatformDispatcher.instance.onError;
    _previousWidgetBuilder = ErrorWidget.builder;

    FlutterError.onError = (FlutterErrorDetails details) {
      handle(details.exception, details.stack, silent: details.silent);
    };
    PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
      handle(error, stack);
      return true;
    };
    if (widgetBuilder != null) {
      ErrorWidget.builder = widgetBuilder;
    }
  }

  /// Restores the hooks that were in place before [install].
  void uninstall() {
    if (!_installed) {
      return;
    }
    _installed = false;
    FlutterError.onError = _previousFlutterHandler;
    PlatformDispatcher.instance.onError = _previousPlatformHandler;
    ErrorWidget.builder = _previousWidgetBuilder ?? ErrorWidget.builder;
  }

  /// Classifies and records an error. Silent framework errors are only logged;
  /// anything classified as fatal also raises [fatalError].
  void handle(Object error, StackTrace? stack, {bool silent = false}) {
    final AppError classified = AppError.classify(error);
    sink(classified, stack);
    if (!silent && classified.treatment == ErrorTreatment.fullScreenFallback) {
      fatalError.value = classified;
    }
  }

  /// Clears the fatal state after the user pressed Retry.
  void clearFatal() {
    fatalError.value = null;
  }

  void dispose() {
    uninstall();
    fatalError.dispose();
  }
}
