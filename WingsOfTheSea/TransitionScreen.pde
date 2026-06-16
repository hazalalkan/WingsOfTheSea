// Comic-panel transition screen used for the intro, stage changes, and final result transition.
class TransitionScreen {

  PImage[] transitionPanels = new PImage[0];
  String[] imageFileNames = new String[0];
  HashMap<String, PImage> imageCache = new HashMap<String, PImage>();

  PFont font;
  MagicDots magicDots;

  float t = 0;
  int startMs = 0;

  int panelDelayMs = 950;
  int fadeMs = 650;
  int readyDelayMs = 250;

  TransitionScreen() {
    font = loadFont("Georgia-Italic-48.vlw");
    magicDots = new MagicDots(84, 10);
  }

  void preloadImages(String[] imageFileNames) {
    if (imageFileNames == null) {
      return;
    }

    for (int i = 0; i < imageFileNames.length; i++) {
      getCachedImage(imageFileNames[i]);
    }
  }

  // Each transition receives a set of panels, then reveals them in sequence.
  void setImages(String[] imageFileNames) {
    if (imageFileNames == null) {
      imageFileNames = new String[0];
    }

    this.imageFileNames = imageFileNames.clone();
    transitionPanels = new PImage[this.imageFileNames.length];

    for (int i = 0; i < this.imageFileNames.length; i++) {
      transitionPanels[i] = getCachedImage(this.imageFileNames[i]);
    }

    startMs = millis();
    t = 0;
  }

  PImage getCachedImage(String imageFileName) {
    if (imageFileName == null) {
      return null;
    }

    if (imageCache.containsKey(imageFileName)) {
      return imageCache.get(imageFileName);
    }

    PImage image = loadImage(imageFileName);
    imageCache.put(imageFileName, image);
    return image;
  }

  void display() {
    t = getElapsedMs() * 0.0018;

    pushStyle();
    pushMatrix();

    camera();
    noLights();
    hint(DISABLE_DEPTH_TEST);

    rectMode(CORNER);
    ellipseMode(CENTER);
    imageMode(CORNER);

    drawSoftPinkBackground();
    drawComicPanels();
    drawEnterHint();

    hint(ENABLE_DEPTH_TEST);

    popMatrix();
    popStyle();
  }

  int getElapsedMs() {
    return max(0, millis() - startMs);
  }

  void drawSoftPinkBackground() {
    background(255, 214, 234);

    noStroke();
    for (int y = 0; y < height; y++) {
      float a = map(y, 0, height, 0, 1);

      fill(
        lerp(255, 248, a),
        lerp(224, 190, a),
        lerp(238, 224, a)
      );

      rect(0, y, width, 1);
    }

    noStroke();
    for (int r = 0; r < 7; r++) {
      fill(255, 170, 215, 8);
      rect(r * 18, r * 18, width - r * 36, height - r * 36, 40);
    }

    if (magicDots != null) {
      magicDots.display();
    }
  }

  void drawComicPanels() {
    if (transitionPanels == null || transitionPanels.length == 0) {
      drawMissingImageFallback("No transition images were set.");
      return;
    }

    int panelCount = transitionPanels.length;
    int elapsedMs = getElapsedMs();

    float marginX = width * 0.055;
    float gap = width * 0.018;
    float availableW = width - 2 * marginX - (panelCount - 1) * gap;

    float cardW = availableW / panelCount;
    float cardH = height * 0.69;
    float cardY = height * 0.125;

    for (int i = 0; i < panelCount; i++) {
      int revealMs = i * panelDelayMs;
      float revealAmount = constrain((elapsedMs - revealMs) / (float) fadeMs, 0, 1);

      if (revealAmount <= 0) {
        continue;
      }

      float eased = easeOutCubic(revealAmount);
      float cardX = marginX + i * (cardW + gap);

      drawSingleComicPanel(i, cardX, cardY, cardW, cardH, eased);
    }
  }

  void drawSingleComicPanel(int index, float cardX, float cardY, float cardW, float cardH, float revealAmount) {
    float alpha = 255 * revealAmount;
    float lift = (1.0 - revealAmount) * 14;
    float scaleNow = 0.98 + 0.02 * revealAmount;

    float x = cardX;
    float y = cardY + lift;

    noStroke();
    fill(130, 70, 105, 42 * revealAmount);
    rect(x + 8, y + 12, cardW, cardH, 22);

    fill(255, 246, 252, alpha);
    rect(x, y, cardW, cardH, 22);

    fill(255, 215, 235, alpha);
    rect(x + 7, y + 7, cardW - 14, cardH - 14, 17);

    PImage panel = transitionPanels[index];

    if (panel == null) {
      drawMissingPanel(index, x, y, cardW, cardH, alpha);
      return;
    }

    float innerX = x + 12;
    float innerY = y + 12;
    float innerW = cardW - 24;
    float innerH = cardH - 24;

    float imageRatio = (float) panel.width / panel.height;
    float boxRatio = innerW / innerH;

    float drawW;
    float drawH;

    if (imageRatio > boxRatio) {
      drawW = innerW;
      drawH = innerW / imageRatio;
    } else {
      drawH = innerH;
      drawW = innerH * imageRatio;
    }

    float centerX = innerX + innerW * 0.5;
    float centerY = innerY + innerH * 0.5;

    pushMatrix();
    translate(centerX, centerY);
    scale(scaleNow);
    imageMode(CENTER);
    tint(255, alpha);
    image(panel, 0, 0, drawW, drawH);
    noTint();
    popMatrix();
  }

  void drawMissingPanel(int index, float x, float y, float w, float h, float alpha) {
    fill(255, 230, 242, alpha);
    rect(x + 14, y + 14, w - 28, h - 28, 16);

    textFont(font);
    textAlign(CENTER, CENTER);
    textSize(constrain(height * 0.026, 18, 28));
    fill(170, 70, 120, alpha);
    text("Missing image:\n" + imageFileNames[index], x + w * 0.5, y + h * 0.5);
  }

  void drawEnterHint() {
    boolean ready = isReadyToContinue();
    float pulse = 180 + 75 * sin(t);

    textFont(font);
    textAlign(CENTER, CENTER);
    textSize(constrain(height * 0.034, 22, 36));

    String msg;

    if (ready) {
      msg = "Press ENTER to Continue";
    } else {
      msg = "The story is unfolding...";
    }

    fill(120, 55, 95, pulse * 0.35);
    text(msg, width * 0.5 + 2, height * 0.895 + 2);

    fill(120, 45, 95, pulse);
    text(msg, width * 0.5, height * 0.895);
  }

  boolean isReadyToContinue() {
    if (transitionPanels == null || transitionPanels.length == 0) {
      return true;
    }

    int revealEndMs = max(0, transitionPanels.length - 1) * panelDelayMs + fadeMs + readyDelayMs;
    return getElapsedMs() >= revealEndMs;
  }

  void revealAllPanelsNow() {
    if (transitionPanels == null || transitionPanels.length == 0) {
      return;
    }

    startMs = millis() - max(0, transitionPanels.length - 1) * panelDelayMs - fadeMs - readyDelayMs - 20;
  }

  float easeOutCubic(float x) {
    return 1.0 - pow(1.0 - x, 3);
  }

  void drawMissingImageFallback(String message) {
    rectMode(CORNER);
    noStroke();
    fill(255, 214, 232);
    rect(0, 0, width, height);

    textFont(font);
    textAlign(CENTER, CENTER);
    textSize(constrain(height * 0.042, 26, 42));
    fill(145, 55, 105);
    text(message, width * 0.5, height * 0.45);
  }

  void handleKeyPressed(char k, int kc) {
    if (kc == ENTER || kc == RETURN) {
      if (isReadyToContinue()) {
        finishTransition();
      } else {
        revealAllPanelsNow();
      }
    }

    if (k == 'q' || k == 'Q') {
      exit();
    }
  }
}
