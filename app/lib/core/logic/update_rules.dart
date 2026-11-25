/// When to suggest an update. The store's newest build comes from the remote
/// flags; the prompt is soft (never blocks play), and a "not now" holds for
/// that build, so it returns only when a newer one is out.
abstract final class UpdateRules {
  static bool shouldPrompt({
    required int currentBuild,
    required int latestBuild,
    required int dismissedBuild,
  }) =>
      latestBuild > currentBuild && latestBuild > dismissedBuild;
}
