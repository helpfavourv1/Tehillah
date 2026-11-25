abstract interface class RatingPort {
  /// Asks the store to show its rating dialog. True if a request was made.
  /// The store decides whether anything appears, so this is never a promise
  /// that the user saw it.
  Future<bool> requestReview();
}
