// Final result screen with win/lose text, animated Lumi, score, and post-game actions.
class ScoreScreen {

  final int BUTTON_NONE      = -1;
  final int BUTTON_RESTART   = 0;
  final int BUTTON_MAIN_MENU = 1;
  final int BUTTON_QUIT      = 2;

  final int RESULT_WIN  = 0;
  final int RESULT_LOSE = 1;

  final String[] BUTTON_LABELS = { "Restart", "Main Menu", "Quit" };

  PImage infoBoxImg;
  PImage lumiBodyImg;
  PImage lumiHappyBodyImg;
  PImage lumiWingImg;
  PFont font;

  int finalScore = 0;
  int resultMode = RESULT_WIN;
  float t = 0;
  int lastAnimMs = 0;

  PGraphics softPinkBackground;
  int softPinkBackgroundW = -1;
  int softPinkBackgroundH = -1;

  float boxX, boxY, boxW, boxH;
  float contentX, contentW, contentH, contentTop;
  float buttonW, buttonH, buttonGap, buttonY;
  float buttonDrawW, buttonDrawH;

  ScoreScreen() {
    infoBoxImg = loadImage("info.png");
    lumiBodyImg = loadImage("lumi_body.png");
    lumiHappyBodyImg = loadImage("lumi_happy_body.png");
    lumiWingImg = loadImage("lumi_wings.png");
    font = loadFont("Georgia-Italic-48.vlw");
  }

  void setResult(boolean playerWon, int newScore) {
    applyResult(playerWon ? RESULT_WIN : RESULT_LOSE, newScore);
  }

  void applyResult(int mode, int newScore) {
    finalScore = newScore;
    resultMode = mode;
    t = 0;
    lastAnimMs = millis();
  }

  void updateAnimationClock() {
    int now = millis();

    if (lastAnimMs == 0) {
      lastAnimMs = now;
    }

    float elapsedMs = constrain(now - lastAnimMs, 0, 80);
    t += elapsedMs * 0.0021;
    lastAnimMs = now;
  }

  // Uses a frame-time-based animation clock so Lumi stays smooth even on the score screen.
  void display() {
    updateAnimationClock();

    beginOverlay();
    drawSoftPinkBackground();
    calculateLayout();
    drawInfoBox();
    drawLumi();
    drawTextContent();
    drawButtons();
    endOverlay();
  }

  void beginOverlay() {
    camera();
    ortho();
    noLights();
    hint(DISABLE_DEPTH_TEST);
  }

  void endOverlay() {
    hint(ENABLE_DEPTH_TEST);
  }

  void calculateLayout() {
    float maxBoxW = min(width * 0.99, 1500);
    float maxBoxH = min(height * 0.97, 1100);

    if (width < 900) {
      maxBoxW = width * 0.97;
    }
    if (height < 720) {
      maxBoxH = height * 0.94;
    }

    if (infoBoxImg != null && infoBoxImg.width > 0 && infoBoxImg.height > 0) {
      float imgRatio = (float) infoBoxImg.width / (float) infoBoxImg.height;
      float maxRatio = maxBoxW / maxBoxH;

      if (imgRatio > maxRatio) {
        boxW = maxBoxW;
        boxH = maxBoxW / imgRatio;
      } else {
        boxH = maxBoxH;
        boxW = maxBoxH * imgRatio;
      }
    } else {
      boxW = maxBoxW;
      boxH = maxBoxH;
    }

    boxX = width * 0.5;
    boxY = height * 0.5;

    float marginX = boxW * 0.23;
    float marginTop = boxH * 0.22;
    float marginBottom = boxH * 0.19;

    contentX = boxX;
    contentW = boxW - marginX * 2.0;
    contentH = boxH - marginTop - marginBottom;

    float contentY = boxY - boxH * 0.5 + marginTop + contentH * 0.5;
    contentTop = contentY - contentH * 0.5;

    buttonGap = max(8, contentW * 0.035);
    buttonW = min(155, (contentW - buttonGap * 2.0) / 3.0);
    buttonH = constrain(contentH * 0.090, 34, 46);

    buttonDrawW = min(buttonW * 1.16, buttonW + buttonGap * 0.70);
    buttonDrawH = buttonH * 1.18;

    buttonY = contentTop + contentH * 0.78;
  }

  void drawSoftPinkBackground() {
    updateSoftPinkBackground();

    imageMode(CORNER);
    noTint();
    image(softPinkBackground, 0, 0);

    rectMode(CORNER);
    noStroke();

    randomSeed(10);
    for (int i = 0; i < 42; i++) {
      float x = random(width);
      float y = random(height);
      float s = random(2.0, 5.5);
      float pulse = 180 + 75 * sin(t);

      fill(255, 255, 255, pulse);
      ellipse(x, y, s, s);
    }
  }

  void updateSoftPinkBackground() {
    if (softPinkBackground != null &&
        softPinkBackgroundW == width &&
        softPinkBackgroundH == height) {
      return;
    }

    softPinkBackgroundW = width;
    softPinkBackgroundH = height;

    softPinkBackground = createGraphics(width, height);
    softPinkBackground.beginDraw();
    softPinkBackground.background(255, 214, 234);
    softPinkBackground.rectMode(CORNER);
    softPinkBackground.noStroke();

    for (int y = 0; y < height; y++) {
      float a = map(y, 0, height, 0, 1);

      softPinkBackground.fill(
        lerp(255, 248, a),
        lerp(224, 190, a),
        lerp(238, 224, a)
      );

      softPinkBackground.rect(0, y, width, 1);
    }

    softPinkBackground.endDraw();
  }

  void drawInfoBox() {
    imageMode(CENTER);
    rectMode(CENTER);
    noStroke();

    if (infoBoxImg != null) {
      tint(255, 245);
      image(infoBoxImg, boxX, boxY, boxW, boxH);
      noTint();
      return;
    }

    fill(255, 246, 252, 238);
    rect(boxX, boxY, boxW, boxH, 34);

    stroke(218, 125, 186, 175);
    strokeWeight(2);
    noFill();
    rect(boxX, boxY, boxW, boxH, 34);
    noStroke();
  }


  void drawLumi() {
    PImage bodyImg = resultMode == RESULT_LOSE ? lumiBodyImg : lumiHappyBodyImg;

    if (bodyImg == null || lumiWingImg == null || bodyImg.width <= 0 || bodyImg.height <= 0 || lumiWingImg.width <= 0 || lumiWingImg.height <= 0) {
      return;
    }

    boolean onRight = resultMode == RESULT_LOSE;
    float side = onRight ? 1 : -1;

    float bodyH = constrain(boxH * 0.56, 230, 470);
    float bodyW = bodyH * (float) bodyImg.width / (float) bodyImg.height;

    if (bodyW > boxW * 0.28) {
      bodyW = boxW * 0.28;
      bodyH = bodyW * (float) bodyImg.height / (float) bodyImg.width;
    }

    float bodyX = boxX + side * boxW * 0.35;
    float baseBodyY = boxY + boxH * 0.035;

    if (onRight) {
      bodyX = min(bodyX, width - bodyW * 0.45);
    } else {
      bodyX = max(bodyX, bodyW * 0.45);
    }

    // Shared bob keeps body and wings moving together.
    float bob = sin(t * 1.65) * bodyH * 0.018;
    float bodyY = baseBodyY + bob;

    float flap = sin(t * 3.3);
    float wingBaseW = bodyW * 1.18;
    float wingW = wingBaseW * (1.0 - flap * 0.035);
    float wingH = wingBaseW * (float) lumiWingImg.height / (float) lumiWingImg.width;
    float wingY = bodyY - bodyH * -0.10;

    pushMatrix();
    translate(bodyX, wingY);
    imageMode(CENTER);
    tint(255, 238);
    image(lumiWingImg, 0, 0, wingW, wingH);
    noTint();
    popMatrix();

    imageMode(CENTER);
    image(bodyImg, bodyX, bodyY, bodyW, bodyH);
  }

  void drawTextContent() {
    textFont(font);
    textAlign(CENTER, CENTER);
    noStroke();

    float titleSize = constrain(contentH * 0.075, 28, 44);
    float subSize = constrain(contentH * 0.050, 19, 30);
    float bodySize = constrain(contentH * 0.030, 13, 18);
    float scoreSize = constrain(contentH * 0.050, 20, 32);

    float titleY = contentTop + contentH * 0.075;
    float subtitleY = contentTop + contentH * 0.165;
    float scoreY = boxY;
    float storyY = (subtitleY + scoreY) * 0.5;
    float thanksY = scoreY + (scoreY - storyY);

    drawCenteredText(getTitleText(), contentX, titleY, titleSize, color(118, 36, 82));
    drawCenteredText(getSubtitleText(), contentX, subtitleY, subSize, color(150, 54, 110));
    drawCenteredText(getStoryText(), contentX, storyY, bodySize, color(150, 54, 110));

    drawScoreBadge(boxX, scoreY, scoreSize);

    String thanksLine = "Thanks for playing Wings of the Sea.\nChoose your next adventure:";
    drawCenteredText(thanksLine, contentX, thanksY, bodySize, color(150, 54, 110));
  }

  String getTitleText() {
    if (resultMode == RESULT_LOSE) {
      return "Oh no, magic faded!";
    }

    return "Congratulations!";
  }

  String getSubtitleText() {
    if (resultMode == RESULT_LOSE) {
      return "Lumi is still waiting.";
    }

    return "You found Lumi!";
  }

  String getStoryText() {
    if (resultMode == RESULT_LOSE) {
      return "Rosa is not ready to give up yet.\nSome adventures need one more brave attempt.";
    }

    return "Rosa's magic is whole again, and Lumi is safely by her side.\n" +
           "The forest, the lake, and the sky can shine once more.";
  }

  void drawCenteredText(String message, float x, float y, float size, color c) {
    fill(c);
    textSize(size);
    textAlign(CENTER, CENTER);
    text(message, x, y);
  }

  void drawScoreBadge(float cx, float cy, float scoreSize) {
    rectMode(CENTER);

    float badgeW = contentW * 0.66;
    float badgeH = contentH * 0.105;

    noStroke();
    fill(155, 78, 128, 36);
    rect(cx + 4, cy + 5, badgeW, badgeH, 24);

    stroke(205, 118, 178, 170);
    strokeWeight(1.8);
    fill(255, 238, 250, 222);
    rect(cx, cy, badgeW, badgeH, 24);

    textAlign(CENTER, BASELINE);
    textFont(font);
    textSize(scoreSize);

    float scoreTextY = cy + (textAscent() - textDescent()) * 0.5;

    fill(0, 0, 0, 42);
    text("Score: " + finalScore, cx, scoreTextY + 1.5);

    fill(122, 39, 90);
    text("Score: " + finalScore, cx, scoreTextY);
  }

  void drawButtons() {
    for (int i = BUTTON_RESTART; i <= BUTTON_QUIT; i++) {
      drawButton(i, BUTTON_LABELS[i]);
    }
  }

  void drawButton(int buttonIndex, String label) {
    float buttonX = getButtonX(buttonIndex);
    boolean hovered = isMouseOverButton(buttonIndex);

    pushStyle();
    rectMode(CENTER);
    textAlign(CENTER, CENTER);
    textFont(font);

    noStroke();
    fill(125, 55, 105, hovered ? 52 : 30);
    rect(buttonX + 4, buttonY + 5, buttonDrawW, buttonDrawH, 24);

    strokeWeight(2.0);
    stroke(185, 95, 170, hovered ? 235 : 165);

    if (hovered) {
      fill(255, 250, 255, 245);
    } else {
      fill(255, 226, 246, 210);
    }

    rect(buttonX, buttonY, buttonDrawW, buttonDrawH, 24);

    fill(98, 45, 130);
    textSize(constrain(buttonDrawH * 0.40, 15, 20));
    text(label, buttonX, buttonY - 2);

    popStyle();
  }

  float getButtonX(int buttonIndex) {
    float totalW = buttonW * 3.0 + buttonGap * 2.0;
    float firstX = contentX - totalW / 2.0 + buttonW / 2.0;
    return firstX + buttonIndex * (buttonW + buttonGap);
  }

  boolean isMouseOverButton(int buttonIndex) {
    return isPointOverButton(buttonIndex, mouseX, mouseY);
  }

  boolean isPointOverButton(int buttonIndex, float mx, float my) {
    float buttonX = getButtonX(buttonIndex);

    return mx > buttonX - buttonDrawW / 2.0 &&
           mx < buttonX + buttonDrawW / 2.0 &&
           my > buttonY - buttonDrawH / 2.0 &&
           my < buttonY + buttonDrawH / 2.0;
  }

  int handleMousePressed(int mx, int my) {
    for (int i = BUTTON_RESTART; i <= BUTTON_QUIT; i++) {
      if (isPointOverButton(i, mx, my)) {
        return i;
      }
    }

    return BUTTON_NONE;
  }

  int handleKeyPressed(char k, int kc) {
    if (kc == ENTER || kc == RETURN || k == 'r' || k == 'R') {
      return BUTTON_RESTART;
    }

    if (k == 'm' || k == 'M' || kc == BACKSPACE) {
      return BUTTON_MAIN_MENU;
    }

    if (k == 'q' || k == 'Q') {
      return BUTTON_QUIT;
    }

    return BUTTON_NONE;
  }
}
