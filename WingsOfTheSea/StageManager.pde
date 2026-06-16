// Central source of truth for the timed fairy -> mermaid -> final fairy stage sequence.
class StageManager {

  final int STAGE_FAIRY_START = 0;
  final int STAGE_MERMAID = 1;
  final int STAGE_FAIRY_FINAL = 2;

  int currentStage = STAGE_FAIRY_START;
  int previousStage = STAGE_FAIRY_START;
  
  // Active gameplay duration is currently set to 60 seconds for testing and presentation purposes.
  // These stage durations can be extended later without changing the core stage-management logic.
  // Total gameplay time is calculated automatically in getTotalDurationMs().

  int fairyStartDurationMs = 20000;
  int mermaidDurationMs    = 30000;
  int fairyFinalDurationMs = 10000;

  void reset() {
    currentStage = STAGE_FAIRY_START;
    previousStage = STAGE_FAIRY_START;
  }

  // Derives the current stage from elapsed time instead of storing separate stage timers.
  void update(GameTimer gameTimer) {
    previousStage = currentStage;

    int elapsed = gameTimer.getElapsedMs();

    if (elapsed < fairyStartDurationMs) {
      currentStage = STAGE_FAIRY_START;
    } else if (elapsed < fairyStartDurationMs + mermaidDurationMs) {
      currentStage = STAGE_MERMAID;
    } else {
      currentStage = STAGE_FAIRY_FINAL;
    }
  }

  boolean stageJustChanged() {
    return currentStage != previousStage;
  }

  boolean isMermaidStage() {
    return currentStage == STAGE_MERMAID;
  }

  boolean isFinalFairyStage() {
    return currentStage == STAGE_FAIRY_FINAL;
  }

  int getFinalStageElapsedMs(GameTimer gameTimer) {
    int finalStageStartMs = fairyStartDurationMs + mermaidDurationMs;
    return max(0, gameTimer.getElapsedMs() - finalStageStartMs);
  }

  int getTotalDurationMs() {
    return fairyStartDurationMs + mermaidDurationMs + fairyFinalDurationMs;
  }
}
