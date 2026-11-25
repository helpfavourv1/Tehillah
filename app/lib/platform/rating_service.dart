import 'package:in_app_review/in_app_review.dart';
import 'package:tehillah/core/ports/log_port.dart';
import 'package:tehillah/core/ports/rating_port.dart';

Future<bool> _storeIsAvailable() => InAppReview.instance.isAvailable();
Future<void> _storeRequest() => InAppReview.instance.requestReview();

/// The store's own rating dialog. Nothing here can fail loudly: if the dialog
/// is unavailable or the plugin throws, the answer is simply false.
final class RatingService implements RatingPort {
  RatingService({
    Future<bool> Function()? isAvailable,
    Future<void> Function()? request,
    LogPort? log,
  })  : _isAvailable = isAvailable ?? _storeIsAvailable,
        _request = request ?? _storeRequest,
        _log = log;

  final Future<bool> Function() _isAvailable;
  final Future<void> Function() _request;
  final LogPort? _log;

  @override
  Future<bool> requestReview() async {
    try {
      if (!await _isAvailable()) {
        return false;
      }
      await _request();
      return true;
    } on Object catch (error) {
      _log?.log(LogLevel.warning, 'rating', 'review request failed: $error');
      return false;
    }
  }
}
