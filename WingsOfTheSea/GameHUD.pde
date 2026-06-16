// Gameplay overlay for lives, score, timer, stage information, and end-state messages.
class GameHUD {

  PImage timerLandBox;
  PImage timerLakeBox;

  PImage heartImg;
  PImage bubbleImg;

  PFont hudFont;

  GameHUD() {
    timerLandBox = loadImage("timer_land.png");
    timerLakeBox = loadImage("timer_lake.png");

    heartImg = loadImage("heart.png");
    bubbleImg = loadImage("bubble.png");

    hudFont = loadFont("Georgia-Italic-48.vlw");
  }

  void display(GameTimer gameTimer, int lives,
               StageManager stageManager, ScoreManager scoreManager) {
    beginOverlay();

    drawTimer(gameTimer, stageManager);
    drawLives(lives, stageManager);
    drawScore(scoreManager, stageManager);

    endOverlay();
  }

  void beginOverlay() {
    hint(DISABLE_DEPTH_TEST);
    camera();
    ortho();

    imageMode(CENTER);
    textAlign(CENTER, CENTER);
    noStroke();
  }

  void endOverlay() {
    hint(ENABLE_DEPTH_TEST);
  }

  void drawTimer(GameTimer gameTimer, StageManager stageManager) {
    PImage currentTimerBox;

    if (stageManager.isMermaidStage()) {
      currentTimerBox = timerLakeBox;
    } else {
      currentTimerBox = timerLandBox;
    }

    float boxW = width * 0.18;
    float boxH;

    if (currentTimerBox != null) {
      boxH = boxW * ((float) currentTimerBox.height / currentTimerBox.width);
    } else {
      boxH = height * 0.075;
    }

    float boxX = width * 0.50;
    float boxY = height * 0.075;

    if (currentTimerBox != null) {
      image(currentTimerBox, boxX, boxY, boxW, boxH);
    } else {
      fill(255, 230, 255, 215);
      rectMode(CENTER);
      rect(boxX, boxY, boxW, boxH, 24);
    }

    textFont(hudFont);
    textSize(height * 0.040);

    fill(0, 0, 0, 90);
    text(gameTimer.getFormattedTime(), boxX + 2, boxY + boxH * 0.02 + 2);

    fill(255);
    text(gameTimer.getFormattedTime(), boxX, boxY + boxH * 0.02);
  }

  void drawLives(int lives, StageManager stageManager) {
    PImage currentLifeImg;

    if (stageManager.isMermaidStage()) {
      currentLifeImg = bubbleImg;
    } else {
      currentLifeImg = heartImg;
    }

    float iconSize = height * 0.065;
    float gap = iconSize * 0.90;

    float startX = width * 0.065;
    float y = height * 0.075;

    for (int i = 0; i < lives; i++) {
      float x = startX + i * gap;

      if (currentLifeImg != null) {
        image(currentLifeImg, x, y, iconSize, iconSize);
      } else {
        textFont(hudFont);
        textSize(iconSize * 0.8);

        if (stageManager.isMermaidStage()) {
          fill(180, 230, 255);
          text("○", x, y);
        } else {
          fill(255, 90, 150);
          text("♥", x, y);
        }
      }
    }
  }

  void drawScore(ScoreManager scoreManager, StageManager stageManager) {
    PImage currentScoreBox;

    if (stageManager.isMermaidStage()) {
      currentScoreBox = timerLakeBox;
    } else {
      currentScoreBox = timerLandBox;
    }

    float boxW = width * 0.18;
    float boxH;

    if (currentScoreBox != null) {
      boxH = boxW * ((float) currentScoreBox.height / currentScoreBox.width);
    } else {
      boxH = height * 0.075;
    }

    float boxX = width * 0.88;
    float boxY = height * 0.075;

    imageMode(CENTER);

    if (currentScoreBox != null) {
      image(currentScoreBox, boxX, boxY, boxW, boxH);
    } else {
      fill(255, 230, 255, 215);
      rectMode(CENTER);
      rect(boxX, boxY, boxW, boxH, 24);
    }

    textFont(hudFont);
    textSize(height * 0.034);
    textAlign(CENTER, CENTER);

    fill(0, 0, 0, 90);
    text("Score: " + scoreManager.getScore(), boxX + 2, boxY + boxH * 0.02 + 2);

    fill(255);
    text("Score: " + scoreManager.getScore(), boxX, boxY + boxH * 0.02);
  }

}
