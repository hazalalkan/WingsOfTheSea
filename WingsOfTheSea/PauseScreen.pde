// Pause overlay that freezes gameplay and shows resume/restart/menu/quit plus audio controls.
class PauseScreen {

  final int BUTTON_NONE      = -1;
  final int BUTTON_RESUME    = 0;
  final int BUTTON_RESTART   = 1;
  final int BUTTON_MAIN_MENU = 2;
  final int BUTTON_QUIT      = 3;

  final int VOLUME_NONE  = 0;
  final int VOLUME_MUSIC = 1;
  final int VOLUME_SOUND = 2;

  PImage pauseLandBox;
  PImage pauseLakeBox;

  PImage frozenGameFrame;

  PImage iconMusic;
  PImage iconSound;

  boolean visible = false;

  float boxX, boxY;
  float boxW, boxH;

  float buttonW, buttonH;
  float firstButtonY;
  float buttonGap;

  float controlButtonSize;
  float controlButtonX;
  float controlBarX;
  float controlBarW;
  float controlBarH;
  float controlMusicY;
  float controlSoundY;

  int draggingVolumeBar = VOLUME_NONE;

  PFont pauseFont;

  PauseScreen() {
    PImage pauseLandSource = loadImage("pause_land.png");
    PImage pauseLakeSource = loadImage("pause_lake.png");

    pauseLandBox = trimTransparentEdges(pauseLandSource, 10, 30);
    pauseLakeBox = trimTransparentEdges(pauseLakeSource, 10, 30);

    iconMusic = loadImage("icon_music.png");
    iconSound = loadImage("icon_sound.png");

    pauseFont = createFont("Georgia", 28);

    calculateLayout();
  }

  // Crops transparent margins from the decorative pause-box images.
  PImage trimTransparentEdges(PImage source, int alphaThreshold, int padding) {
    if (source == null) {
      return null;
    }

    source.loadPixels();

    int minX = source.width;
    int minY = source.height;
    int maxX = 0;
    int maxY = 0;

    for (int y = 0; y < source.height; y++) {
      for (int x = 0; x < source.width; x++) {
        color c = source.pixels[y * source.width + x];

        if (alpha(c) > alphaThreshold) {
          if (x < minX) minX = x;
          if (x > maxX) maxX = x;
          if (y < minY) minY = y;
          if (y > maxY) maxY = y;
        }
      }
    }

    if (minX > maxX || minY > maxY) {
      return source;
    }

    minX = max(0, minX - padding);
    minY = max(0, minY - padding);
    maxX = min(source.width - 1, maxX + padding);
    maxY = min(source.height - 1, maxY + padding);

    return source.get(minX, minY, maxX - minX + 1, maxY - minY + 1);
  }

  // Freezes the current gameplay frame so the pause overlay can be drawn cleanly on top.
  void captureCurrentFrame() {
    loadPixels();

    frozenGameFrame = createImage(pixelWidth, pixelHeight, ARGB);
    frozenGameFrame.loadPixels();

    arrayCopy(pixels, frozenGameFrame.pixels);

    frozenGameFrame.updatePixels();

    if (frozenGameFrame.width != width || frozenGameFrame.height != height) {
      frozenGameFrame.resize(width, height);
    }
  }

  // Recalculates positions from width/height so the pause menu stays centered on different displays.
  void calculateLayout() {
    boxH = height * 0.82;

    PImage referenceBox = pauseLandBox;

    if (referenceBox != null) {
      boxW = boxH * ((float) referenceBox.width / referenceBox.height);
    } else {
      boxW = width * 0.42;
    }

    if (boxW > width * 0.56) {
      boxW = width * 0.56;

      if (referenceBox != null) {
        boxH = boxW * ((float) referenceBox.height / referenceBox.width);
      }
    }

    boxX = width / 2;
    boxY = height / 2;

    buttonW = boxW * 0.54;
    buttonH = boxH * 0.058;

    float rowStep = boxH * 0.086;
    float buttonGroupOffsetY = boxH * 0.05;
    buttonGap = rowStep - buttonH;
    firstButtonY = boxY - rowStep * 2.5 - boxH * 0.040 + buttonGroupOffsetY;

    controlButtonSize = boxH * 0.060;
    controlBarH       = max(8, boxH * 0.016);

    float buttonLeft  = boxX - buttonW / 2;
    float buttonRight = boxX + buttonW / 2;
    float controlGapX = max(12, boxW * 0.024);
    float barLeft     = buttonLeft + controlButtonSize + controlGapX;

    controlButtonX = buttonLeft + controlButtonSize / 2;
    controlBarW    = max(40, buttonRight - barLeft);
    controlBarX    = barLeft + controlBarW / 2;

    controlMusicY = getButtonY(4);
    controlSoundY = getButtonY(5);
  }

  // Draws over a captured frame so pausing feels like freezing the current game moment.
  void display(boolean lakeStage) {
    calculateLayout();

    hint(DISABLE_DEPTH_TEST);

    drawFrozenGameBackground();
    drawDimOverlay();
    drawPauseBox(lakeStage);
    drawButtons(lakeStage);
    drawSoundControls(lakeStage);

    hint(ENABLE_DEPTH_TEST);
  }

  void drawFrozenGameBackground() {
    pushStyle();
    imageMode(CORNER);

    background(0);

    if (frozenGameFrame != null) {
      image(frozenGameFrame, 0, 0, width, height);
    }

    popStyle();
  }

  void drawDimOverlay() {
    pushStyle();
    rectMode(CORNER);
    noStroke();
    fill(0, 125);
    rect(0, 0, width, height);
    popStyle();
  }

  void drawPauseBox(boolean lakeStage) {
    pushStyle();
    imageMode(CENTER);

    PImage selectedBox;

    if (lakeStage) {
      selectedBox = pauseLakeBox;
    } else {
      selectedBox = pauseLandBox;
    }

    if (selectedBox != null) {
      image(selectedBox, boxX, boxY, boxW, boxH);
    }

    popStyle();
  }

  void drawButtons(boolean lakeStage) {
    drawButton(BUTTON_RESUME, "Resume", lakeStage);
    drawButton(BUTTON_RESTART, "Restart", lakeStage);
    drawButton(BUTTON_MAIN_MENU, "Main Menu", lakeStage);
    drawButton(BUTTON_QUIT, "Quit", lakeStage);
  }

  void drawButton(int buttonIndex, String label, boolean lakeStage) {
    float buttonY = getButtonY(buttonIndex);
    boolean hovered = isMouseOverButton(buttonIndex);

    pushStyle();

    rectMode(CENTER);
    textAlign(CENTER, CENTER);
    textFont(pauseFont);

    strokeWeight(2.2);

    if (lakeStage) {
      stroke(105, 130, 220);
    } else {
      stroke(185, 95, 200);
    }

    if (hovered) {
      fill(255, 242, 255, 235);
    } else {
      fill(255, 222, 246, 175);
    }

    rect(boxX, buttonY, buttonW, buttonH, 18);

    fill(105, 55, 140);
    textSize(max(20, buttonH * 0.52));
    text(label, boxX, buttonY - 1);

    popStyle();
  }

  void drawSoundControls(boolean lakeStage) {
    drawControlRow(VOLUME_MUSIC, controlMusicY, iconMusic, musicOn, musicVolume, lakeStage);
    drawControlRow(VOLUME_SOUND, controlSoundY, iconSound, areSoundEffectsEnabled(), getSoundEffectsVolume(), lakeStage);
  }

  void drawControlRow(int controlType, float cy, PImage icon, boolean active, float value, boolean lakeStage) {
    drawControlRoundButton(controlType, cy, icon, active, lakeStage);
    drawHorizontalVolumeBar(controlType, cy, value, active, lakeStage);
  }

  void drawControlRoundButton(int controlType, float cy, PImage icon, boolean active, boolean lakeStage) {
    boolean hovered = isMouseOverControlButton(controlType);

    pushStyle();
    pushMatrix();
    translate(controlButtonX, cy);

    noStroke();
    fill(0, 0, 0, 38);
    ellipse(0, controlButtonSize * 0.06, controlButtonSize * 1.05, controlButtonSize * 1.05);

    noStroke();
    if (lakeStage) {
      fill(222, 244, 255, active ? (hovered ? 245 : 218) : (hovered ? 205 : 165));
    } else {
      fill(255, 222, 246, active ? (hovered ? 245 : 218) : (hovered ? 205 : 165));
    }
    ellipse(0, 0, controlButtonSize, controlButtonSize);

    strokeWeight(hovered ? 2.3 : 1.7);
    if (lakeStage) {
      stroke(105, 130, 220, hovered ? 245 : 220);
    } else {
      stroke(185, 95, 200, hovered ? 245 : 220);
    }
    noFill();
    ellipse(0, 0, controlButtonSize, controlButtonSize);
    noStroke();

    if (icon != null) {
      if (active) {
        tint(105, 55, 140, hovered ? 245 : 225);
      } else {
        tint(105, 55, 140, hovered ? 175 : 120);
      }
      imageMode(CENTER);
      image(icon, 0, 0, controlButtonSize * 0.58, controlButtonSize * 0.58);
      noTint();
    } else {
      textAlign(CENTER, CENTER);
      textFont(pauseFont);
      textSize(controlButtonSize * 0.34);
      fill(105, 55, 140, active ? 230 : 125);
      text(controlType == VOLUME_MUSIC ? "M" : "S", 0, -1);
    }

    popMatrix();
    popStyle();
  }

  void drawHorizontalVolumeBar(int controlType, float cy, float value, boolean active, boolean lakeStage) {
    float x = getVolumeBarLeft();
    float y = cy - controlBarH / 2;
    float filledW = controlBarW * constrain(value, 0, 1);
    float handleX = constrain(x + filledW, x, x + controlBarW);
    float handleSize = controlBarH * 1.95;
    float r = controlBarH / 2;
    boolean hovered = isMouseOverVolumeBar(controlType);

    pushStyle();

    colorMode(RGB, 255, 255, 255, 255);
    ellipseMode(CENTER);
    rectMode(CORNER);
    blendMode(BLEND);

    color trackColor;
    color fillColor;
    color outlineColor;
    color knobColor;

    if (lakeStage) {
      trackColor   = color(222, 244, 255, hovered ? 230 : 195);
      fillColor    = color(142, 204, 238, active ? 240 : 135);
      outlineColor = color(105, 130, 220, hovered ? 255 : 225);
      knobColor    = color(222, 244, 255, 255);
    } else {
      trackColor   = color(255, 222, 246, hovered ? 230 : 195);
      fillColor    = color(218, 126, 220, active ? 240 : 135);
      outlineColor = color(185, 95, 200, hovered ? 255 : 225);
      knobColor    = color(255, 222, 246, 255);
    }

    // Simple full-width slider: draw track, draw fill, then draw knob last.
    noStroke();
    fill(trackColor);
    rect(x, y, controlBarW, controlBarH, r);

    fill(fillColor);
    rect(x, y, filledW, controlBarH, r);

    noFill();
    stroke(outlineColor);
    strokeWeight(hovered ? 1.8 : 1.3);
    rect(x, y, controlBarW, controlBarH, r);

    noStroke();
    fill(knobColor);
    ellipse(handleX, cy, handleSize, handleSize);

    stroke(outlineColor);
    strokeWeight(1.45);
    noFill();
    ellipse(handleX, cy, handleSize, handleSize);

    popStyle();
  }

  float getButtonY(int buttonIndex) {
    return firstButtonY + buttonIndex * (buttonH + buttonGap);
  }

  boolean isMouseOverButton(int buttonIndex) {
    float buttonY = getButtonY(buttonIndex);

    return mouseX > boxX - buttonW / 2 &&
           mouseX < boxX + buttonW / 2 &&
           mouseY > buttonY - buttonH / 2 &&
           mouseY < buttonY + buttonH / 2;
  }

  boolean isMouseOverControlButton(int controlType) {
    float cy = getControlY(controlType);

    return dist(mouseX, mouseY, controlButtonX, cy) <= controlButtonSize / 2;
  }

  boolean isMouseOverVolumeBar(int controlType) {
    float cy = getControlY(controlType);
    float x = getVolumeBarLeft();

    float handleRadius = controlBarH * 0.78;

    return mouseX >= x - handleRadius &&
           mouseX <= x + controlBarW + handleRadius &&
           mouseY >= cy - handleRadius &&
           mouseY <= cy + handleRadius;
  }

  float getControlY(int controlType) {
    if (controlType == VOLUME_MUSIC) {
      return controlMusicY;
    }

    return controlSoundY;
  }

  float getVolumeBarLeft() {
    return controlBarX - controlBarW / 2;
  }

  int handleMousePressed() {
    if (!visible) {
      return BUTTON_NONE;
    }

    calculateLayout();

    if (isMouseOverControlButton(VOLUME_MUSIC)) {
      if (sounds != null) sounds.playButtonClick();
      toggleMusic();
      return BUTTON_NONE;
    }

    if (isMouseOverControlButton(VOLUME_SOUND)) {
      toggleSoundEffects();

      if (areSoundEffectsEnabled() && sounds != null) {
        sounds.playButtonClick();
      }

      return BUTTON_NONE;
    }

    if (isMouseOverVolumeBar(VOLUME_MUSIC)) {
      draggingVolumeBar = VOLUME_MUSIC;
      updateVolumeFromMouse(VOLUME_MUSIC, mouseX);
      return BUTTON_NONE;
    }

    if (isMouseOverVolumeBar(VOLUME_SOUND)) {
      draggingVolumeBar = VOLUME_SOUND;
      updateVolumeFromMouse(VOLUME_SOUND, mouseX);
      return BUTTON_NONE;
    }

    for (int i = 0; i <= BUTTON_QUIT; i++) {
      if (isMouseOverButton(i)) {
        return i;
      }
    }

    return BUTTON_NONE;
  }

  void handleMouseDragged(int mx) {
    if (!visible) {
      return;
    }

    if (draggingVolumeBar == VOLUME_NONE) {
      return;
    }

    updateVolumeFromMouse(draggingVolumeBar, mx);
  }

  void handleMouseReleased() {
    draggingVolumeBar = VOLUME_NONE;
  }

  // Converts mouse position on a horizontal slider into a 0..1 volume value.
  void updateVolumeFromMouse(int controlType, float mx) {
    float value = constrain((mx - getVolumeBarLeft()) / controlBarW, 0.0, 1.0);

    if (controlType == VOLUME_MUSIC) {
      setMusicVolume(value);
    } else if (controlType == VOLUME_SOUND) {
      setSoundEffectsVolume(value);
    }
  }
}
