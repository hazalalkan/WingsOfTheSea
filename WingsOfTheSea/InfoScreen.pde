// Instruction screen shown between the main menu and gameplay.
class InfoScreen {

  PImage bgImg;
  PImage infoBoxImg;
  PFont  font;

  float t = 0;

  float boxX, boxY, boxW, boxH;
  float contentX, contentY, contentW;

  InfoScreen() {
    bgImg      = loadImage("InfoScreen.png");
    infoBoxImg = loadImage("info.png");
    font       = loadFont("Georgia-Italic-48.vlw");
  }

  void display() {
    t += 0.03;
  
    pushStyle();
    pushMatrix();
  
    background(0);
  
    camera();
    ortho();
    noLights();
    hint(DISABLE_DEPTH_TEST);
  
    rectMode(CORNER);
    ellipseMode(CENTER);
    imageMode(CORNER);
  
    drawBackground();
  
    computeInfoBoxLayout();
    drawInfoBox();
    drawFrameText();
    drawEnterHint();
  
    hint(ENABLE_DEPTH_TEST);
  
    popMatrix();
    popStyle();
  }

  void drawBackground() {
    if (bgImg == null) return;

    imageMode(CORNER);

    float screenRatio = (float) width / height;
    float imageRatio  = (float) bgImg.width / bgImg.height;

    float drawW;
    float drawH;

    if (imageRatio > screenRatio) {
      drawH = height;
      drawW = height * imageRatio;
    } else {
      drawW = width;
      drawH = width / imageRatio;
    }

    float drawX = (width - drawW) / 2.0;
    float drawY = (height - drawH) / 2.0;

    image(bgImg, drawX, drawY, drawW, drawH);
  }

  void computeInfoBoxLayout() {
    float boxRatio = 1.25;

    if (infoBoxImg != null && infoBoxImg.height > 0) {
      boxRatio = (float) infoBoxImg.width / infoBoxImg.height;
    }

    boxW = min(width * 0.725, height * 0.965 * boxRatio);
    boxH = boxW / boxRatio;

    if (boxH > height * 0.965) {
      boxH = height * 0.965;
      boxW = boxH * boxRatio;
    }

    boxX = width - boxW / 2.0 - width * 0.010;
    boxY = height * 0.515;

    if (boxY - boxH / 2.0 < height * 0.025) {
      boxY = height * 0.025 + boxH / 2.0;
    }

    if (boxY + boxH / 2.0 > height * 0.975) {
      boxY = height * 0.975 - boxH / 2.0;
    }

    float boxLeft = boxX - boxW / 2.0;
    float boxTop  = boxY - boxH / 2.0;

    contentX = boxLeft + boxW * 0.200;
    contentY = boxTop  + boxH * 0.240;
    contentW = boxW * 0.600;
  }

  void drawInfoBox() {
    if (infoBoxImg != null) {
      imageMode(CENTER);
      tint(255, 248);
      image(infoBoxImg, boxX, boxY, boxW, boxH);
      noTint();
    } else {
      rectMode(CENTER);
      noStroke();
      fill(255, 225, 235, 220);
      rect(boxX, boxY, boxW, boxH, 35);

      stroke(225, 120, 190, 220);
      strokeWeight(2);
      noFill();
      rect(boxX, boxY, boxW, boxH, 35);
      noStroke();
    }
  }

  void drawFrameText() {
    textFont(font);
    noStroke();

    float boxTop = boxY - boxH / 2.0;

    float leftEdge   = contentX;
    float rightEdge  = contentX + contentW;
    float centerX    = contentX + contentW / 2.0;
    float topEdge    = contentY;

    float textScale = 0.90;
    float titleSize = constrain(boxH * 0.038 * textScale, 24, 34);
    float bodySize  = constrain(boxH * 0.0215 * textScale, 14, 19);
    float smallSize = constrain(boxH * 0.0205 * textScale, 13, 17);

    float sectionTitleSize = titleSize * 0.82;
    float storyLeading    = bodySize * 1.36;
    float smallLeading    = smallSize * 1.44;

    textAlign(LEFT, TOP);
    textSize(titleSize);
    fill(132, 39, 78);
    text("Story", leftEdge, topEdge);

    textSize(bodySize);
    textLeading(storyLeading);
    fill(73, 43, 44);

    String story =
      "Rosa has lost her bunny, Lumi. Help her follow Lumi's trail through the enchanted forest and across the magical lake.\n\n" +
      "Gather magical petals to unlock Rosa's mermaid spell. At the lake, transform and dive beneath the waves. Collect magical pearls to restore Rosa's fairy form.\n\n" +
      "Watch out! Dangerous Gremlins, sneaky seaweeds, and unpredictable geysers stand in your way. Help Rosa find Lumi before time runs out!";

    float storyY = topEdge + titleSize * 1.25;
    float storyH = boxH * 0.238;
    text(story, leftEdge, storyY, contentW, storyH);

    float storyBottom = storyY + storyH;
    float dividerY    = snapToPixel(storyBottom + boxH * 0.001);

    stroke(210, 120, 175, 145);
    strokeWeight(1.2);
    line(snapToPixel(leftEdge), dividerY, snapToPixel(rightEdge), dividerY);
    noStroke();

    float lowerTop = storyBottom + boxH * 0.036;
    float colGap   = contentW * 0.105;
    float colW     = (contentW - colGap) / 2.0;

    float rulesX    = leftEdge;
    float controlsX = leftEdge + colW + colGap;

    textAlign(LEFT, TOP);
    textSize(sectionTitleSize);
    fill(132, 39, 78);
    text("Rules", rulesX, lowerTop);
    text("Controls", controlsX, lowerTop);

    float listTop = lowerTop + sectionTitleSize * 1.28;
    drawRuleRows(rulesX, listTop, colW, smallSize, smallLeading);
    drawControlRows(controlsX, listTop, colW, smallSize, smallLeading);

    textAlign(CENTER, CENTER);
    textSize(constrain(boxH * 0.026 * textScale, 17, 22));
    fill(155, 52, 95);
    text("Time to fly, fairy!", centerX, boxTop + boxH * 0.760);
  }

  void drawRuleRows(float x, float y, float w, float size, float rowH) {
    String[] rules = {
      "Find Lumi before time runs out.",
      "Rosa has 5 lives.",
      "Avoid gremlins, seaweed, and geysers.",
      "Collect petals and pearls for points.",
      "Golden items give bonus points."
    };

    textAlign(LEFT, TOP);
    textSize(size);
    textLeading(rowH);
    fill(73, 43, 44);

    float bulletW = size * 0.95;
    for (int i = 0; i < rules.length; i++) {
      float rowY = y + i * rowH;
      text("•", x, rowY);
      text(rules[i], x + bulletW, rowY, w - bulletW, rowH * 1.15);
    }
  }

  void drawControlRows(float x, float y, float w, float size, float rowH) {
    String[] keys = {
      "WASD / Arrows",
      "SPACE",
      "P",
      "Q / ESC",
      "Mouse"
    };

    String[] actions = {
      "Move",
      "Dash",
      "Pause / Resume",
      "Quit",
      "Rotate / Zoom"
    };

    textAlign(LEFT, TOP);
    textSize(size);
    textLeading(rowH);

    float keyW = w * 0.53;
    for (int i = 0; i < keys.length; i++) {
      float rowY = y + i * rowH;

      fill(132, 39, 78);
      text(keys[i], x, rowY, keyW, rowH * 1.15);

      fill(73, 43, 44);
      text(actions[i], x + keyW, rowY, w - keyW, rowH * 1.15);
    }
  }

  void drawEnterHint() {
    float pulse = 180 + 75 * sin(t);
    float boxTop = boxY - boxH / 2.0;
    float centerX = contentX + contentW / 2.0;

    textFont(font);
    textAlign(CENTER, CENTER);
    textSize(constrain(boxH * 0.024, 17, 22));

    fill(132, 39, 78, pulse);
    text("Press ENTER to Start", centerX, boxTop + boxH * 0.795);
  }

  float snapToPixel(float value) {
    return round(value) + 0.5;
  }

  void handleKeyPressed(char k, int kc) {
    if (kc == ENTER || kc == RETURN) {
      startGameplayIntroTransition();
    }

    if (kc == BACKSPACE) {
      goToStartScreen();
    }

    if (k == 'q' || k == 'Q') {
      exit();
    }
  }
}
