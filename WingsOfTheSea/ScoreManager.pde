// Score rules for collectibles and the guarded one-time finish bonus.
class ScoreManager {

  final int NORMAL_COLLECTIBLE_POINTS = 10;
  final int GOLDEN_COLLECTIBLE_POINTS = 25;
  final int FINISH_GAME_POINTS = 100;

  int score = 0;
  boolean finishBonusGiven = false;

  void reset() {
    score = 0;
    finishBonusGiven = false;
  }

  int getScore() {
    return score;
  }

  void addNormalCollectible() {
    score += NORMAL_COLLECTIBLE_POINTS;
  }

  void addGoldenCollectible() {
    score += GOLDEN_COLLECTIBLE_POINTS;
  }

  // Guarded so the finish bonus cannot be added twice by transition/restart timing.
  void addFinishBonus() {
    if (finishBonusGiven) return;

    score += FINISH_GAME_POINTS;
    finishBonusGiven = true;
  }
}
