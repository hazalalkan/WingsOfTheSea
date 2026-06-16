// Run timer that excludes paused time from elapsed gameplay duration.
class GameTimer {

  int durationMs;
  int startMs;

  boolean started = false;
  boolean paused = false;

  int pauseStartedMs = 0;
  int totalPausedMs = 0;

  GameTimer(int durationMs) {
    this.durationMs = durationMs;
  }

  void start() {
    startMs = millis();

    started = true;
    paused = false;

    pauseStartedMs = 0;
    totalPausedMs = 0;
  }

  boolean hasStarted() {
    return started;
  }

  // Pause/resume accumulates paused milliseconds so the timer remains fair.
  void pauseTimer() {
    if (!started) return;
    if (paused) return;

    paused = true;
    pauseStartedMs = millis();
  }

  void resumeTimer() {
    if (!started) return;
    if (!paused) return;

    totalPausedMs += millis() - pauseStartedMs;

    paused = false;
    pauseStartedMs = 0;
  }

  int getElapsedMs() {
    if (!started) return 0;

    int currentMs;

    if (paused) {
      currentMs = pauseStartedMs;
    } else {
      currentMs = millis();
    }

    int elapsed = currentMs - startMs - totalPausedMs;
    return constrain(elapsed, 0, durationMs);
  }

int getTimeLeftMs() {
    if (!started) return durationMs;

    return max(0, durationMs - getElapsedMs());
  }

  boolean isFinished() {
    return getTimeLeftMs() <= 0;
  }

  String getFormattedTime() {
    int totalSeconds = ceil(getTimeLeftMs() / 1000.0);
    int minutes = totalSeconds / 60;
    int seconds = totalSeconds % 60;

    return nf(minutes, 1) + ":" + nf(seconds, 2);
  }
}
