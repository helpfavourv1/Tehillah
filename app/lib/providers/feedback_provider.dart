import 'package:flutter/foundation.dart';
import 'package:tehillah/providers/safe_notifier.dart';

/// What kind of result an action had.
enum FeedbackTone { success, failure, info }

/// One message on its way to the screen. The [id] makes two identical
/// messages in a row distinct, so the second restarts the display time.
@immutable
final class FeedbackMessage {
  const FeedbackMessage({required this.id, required this.text, required this.tone});

  final int id;
  final String text;
  final FeedbackTone tone;

  @override
  bool operator ==(Object other) =>
      other is FeedbackMessage && other.id == id && other.text == text && other.tone == tone;

  @override
  int get hashCode => Object.hash(id, text, tone);
}

/// The single place every action reports its result: saved, shared, failed.
/// The text arrives already localized.
final class FeedbackProvider extends SafeNotifier<FeedbackMessage?> {
  FeedbackProvider() : super(null);

  int _next = 0;

  void show(String text, {FeedbackTone tone = FeedbackTone.success}) {
    _next += 1;
    value = FeedbackMessage(id: _next, text: text, tone: tone);
  }

  void clear() {
    value = null;
  }

  /// Clears the message only if it is still the one with [id], so a timer for
  /// an old message never removes a newer one.
  void clearIf(int id) {
    if (value?.id == id) {
      value = null;
    }
  }
}
