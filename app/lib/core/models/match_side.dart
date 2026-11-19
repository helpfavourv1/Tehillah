/// Which side of a match. In every mode except Watchman the player takes the
/// kicks; in Watchman the player is the goalkeeper and the opponent kicks.
enum MatchSide {
  player,
  opponent;

  MatchSide get other => this == player ? opponent : player;
}
