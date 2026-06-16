// Main menu screen with start/help flow and music/sound volume controls.
class StartScreen {

  PImage backgroundImg;
  PImage logoImg;
  PFont  menuFont;
  MagicDots magicDots;

  PImage iconMusic;
  PImage iconSound;

  float pulseTime = 0;

  float btnSize;
  float btnMusicX, btnSoundX, btnY;

  final int VOLUME_NONE  = 0;
  final int VOLUME_MUSIC = 1;
  final int VOLUME_SOUND = 2;

  int draggingVolumeBar = VOLUME_NONE;

  float musicPanelAlpha = 0;
  float soundPanelAlpha = 0;

  StartScreen() {
    backgroundImg = loadImage("start_background.png");
    logoImg       = loadImage("logo.png");
    menuFont      = loadFont("Georgia-Italic-48.vlw");
    magicDots     = new MagicDots(84, 10);

    iconMusic = loadImage("icon_music.png");
    iconSound = loadImage("icon_sound.png");
  }

  // Draws the animated menu, title area, action buttons, and volume controls.
  void display() {
    pushStyle();
    pushMatrix();

    background(0);
    camera();
    ortho();
    noLights();
    hint(DISABLE_DEPTH_TEST);

    rectMode(CORNER);
    ellipseMode(CENTER);
    imageMode(CENTER);
    textAlign(CENTER, CENTER);

    drawBackground();
    drawMagicDots();
    drawLogo();
    drawMenuText();

    computeButtonLayout();
    drawIconButtons();
    drawHoverVolumeBars();

    hint(ENABLE_DEPTH_TEST);

    popMatrix();
    popStyle();
  }

  void drawMagicDots() {
    if (magicDots != null) {
      magicDots.display();
    }
  }

  // Draws the menu background as a normal 2D image instead of a textured 3D plane.
  void drawBackground() {
    if (backgroundImg == null) return;

    float scaleFactor = max((float) width / backgroundImg.width,
                            (float) height / backgroundImg.height);
    float imgW = backgroundImg.width * scaleFactor;
    float imgH = backgroundImg.height * scaleFactor;

    imageMode(CENTER);
    image(backgroundImg, width / 2, height / 2, imgW, imgH);
  }

  void drawLogo() {
    if (logoImg == null) return;
    float logoW = width * 0.46;
    float logoH = logoW * ((float) logoImg.height / logoImg.width);
    noStroke();
    image(logoImg, width * 0.5, height * 0.35, logoW, logoH);
  }

  void drawMenuText() {
    pulseTime += 0.03;
    float pulse = 180 + 75 * sin(pulseTime);
    textFont(menuFont);

    fill(154, 57, 127, pulse);
    textSize(34);
    text("Press ENTER to Start", width * 0.5, height * 0.685);

    fill(154, 57, 127, pulse);
    textSize(30);
    text("Press Q to Quit", width * 0.5, height * 0.735);
  }

  void computeButtonLayout() {
    btnSize      = height * 0.062;
    float margin = width  * 0.025;
    float gap    = btnSize * 1.45;

    btnY      = height - margin - btnSize / 2;
    btnSoundX = width - margin - btnSize / 2;
    btnMusicX = btnSoundX - gap;
  }

  void drawIconButtons() {
    drawRoundButton(btnMusicX, btnY, btnSize, musicOn,  isMouseOverButton(mouseX, mouseY, btnMusicX), iconMusic);
    drawRoundButton(btnSoundX, btnY, btnSize, areSoundEffectsEnabled(),  isMouseOverButton(mouseX, mouseY, btnSoundX), iconSound);
  }

  void drawRoundButton(float cx, float cy, float d,
                       boolean active, boolean hovered, PImage icon) {
    pushMatrix();
    translate(cx, cy);

    noStroke();
    fill(0, 0, 0, 55);
    ellipse(0, d * 0.06, d * 1.05, d * 1.05);

    noStroke();
    if (active) {
      fill(244, 142, 183, hovered ? 240 : 220);
    } else if (hovered) {
      fill(118, 88, 154, 210);
    } else {
      fill(82, 60, 116, 175);
    }
    ellipse(0, 0, d, d);

    strokeWeight(hovered ? 2.3 : 1.5);
    stroke(255, hovered ? 245 : 190);
    noFill();
    ellipse(0, 0, d, d);
    noStroke();

    if (icon != null) {
      tint(255, active ? 235 : 120);
      imageMode(CENTER);
      image(icon, 0, 0, d * 0.58, d * 0.58);
      noTint();
    }

    popMatrix();
  }

  // Shows vertical volume bars only while their matching sound buttons are hovered or dragged.
  void drawHoverVolumeBars() {
    int hoveredControl = getHoveredVolumeControl(mouseX, mouseY);

    boolean showMusicBar = hoveredControl == VOLUME_MUSIC ||
                           draggingVolumeBar == VOLUME_MUSIC;
    boolean showSoundBar = hoveredControl == VOLUME_SOUND ||
                           draggingVolumeBar == VOLUME_SOUND;

    musicPanelAlpha = lerp(musicPanelAlpha, showMusicBar ? 215 : 0, 0.18);
    soundPanelAlpha = lerp(soundPanelAlpha, showSoundBar ? 215 : 0, 0.18);

    if (musicPanelAlpha > 1) {
      drawVolumeBar(btnMusicX, musicVolume, musicPanelAlpha);
    }

    if (soundPanelAlpha > 1) {
      drawVolumeBar(btnSoundX, getSoundEffectsVolume(), soundPanelAlpha);
    }
  }

  void drawVolumeBar(float cx, float value, float alphaValue) {
    float barW    = getBarWidth();
    float barH    = getBarHeight();
    float barTopY = getBarTopY();
    float filledH = barH * value;
    float r       = barW / 2;

    pushMatrix();
    translate(cx, barTopY);
    rectMode(CORNER);

    noStroke();
    fill(45, 30, 72, alphaValue * 0.95);
    rect(-barW/2, 0, barW, barH, r);

    fill(244, 142, 183, alphaValue);
    rect(-barW/2, barH - filledH, barW, filledH, r);

    strokeWeight(1.2);
    stroke(255, alphaValue * 0.9);
    noFill();
    rect(-barW/2, 0, barW, barH, r);
    noStroke();

    float handleY = barH - filledH;
    fill(255, alphaValue);
    ellipse(0, handleY, barW * 2.2, barW * 2.2);

    popMatrix();
  }

  void handleKeyPressed(char k, int kc) {
    if (kc == ENTER || kc == RETURN) {
      goToInfoScreen();
    }

    if (k == 'q' || k == 'Q') {
      if (sounds != null) sounds.playButtonClick();
      exit();
    }
  }

  void handleMousePressed(int mx, int my) {
    computeButtonLayout();

    if (isMouseOverVolumeBar(mx, my, VOLUME_MUSIC)) {
      draggingVolumeBar = VOLUME_MUSIC;
      updateVolumeFromMouse(VOLUME_MUSIC, my);
      return;
    }

    if (isMouseOverVolumeBar(mx, my, VOLUME_SOUND)) {
      draggingVolumeBar = VOLUME_SOUND;
      updateVolumeFromMouse(VOLUME_SOUND, my);
      return;
    }

    if (isMouseOverButton(mx, my, btnMusicX)) {
      if (sounds != null) sounds.playButtonClick();
      toggleMusic();
      return;
    }

    if (isMouseOverButton(mx, my, btnSoundX)) {
      toggleSoundEffects();

      if (areSoundEffectsEnabled() && sounds != null) {
        sounds.playButtonClick();
      }

      return;
    }
  }

  void handleMouseDragged(int my) {
    if (draggingVolumeBar == VOLUME_NONE) return;
    updateVolumeFromMouse(draggingVolumeBar, my);
  }

  void handleMouseReleased() {
    draggingVolumeBar = VOLUME_NONE;
  }

  // Converts mouse height on the vertical slider into a 0..1 volume value.
  void updateVolumeFromMouse(int controlType, float my) {
    float trackH = getBarHeight();
    float value  = constrain(1.0 - (my - getBarTopY()) / trackH, 0.0, 1.0);

    if (controlType == VOLUME_MUSIC) {
      setMusicVolume(value);
    } else if (controlType == VOLUME_SOUND) {
      setSoundEffectsVolume(value);
    }
  }

  int getHoveredVolumeControl(int mx, int my) {
    if (isMouseOverButton(mx, my, btnMusicX) ||
        isMouseOverVolumeBar(mx, my, VOLUME_MUSIC)) {
      return VOLUME_MUSIC;
    }

    if (isMouseOverButton(mx, my, btnSoundX) ||
        isMouseOverVolumeBar(mx, my, VOLUME_SOUND)) {
      return VOLUME_SOUND;
    }

    return VOLUME_NONE;
  }

  boolean isMouseOverButton(int mx, int my, float cx) {
    return dist(mx, my, cx, btnY) <= btnSize / 2;
  }

  boolean isMouseOverVolumeBar(int mx, int my, int controlType) {
    float cx = controlType == VOLUME_MUSIC ? btnMusicX : btnSoundX;

    return mx >= cx - btnSize * 0.45 &&
           mx <= cx + btnSize * 0.45 &&
           my >= getBarTopY() - btnSize * 0.38 &&
           my <= getBarBottomY() + btnSize * 0.25;
  }

  float getBarWidth() {
    return btnSize * 0.28;
  }

  float getBarHeight() {
    return btnSize * 3.05;
  }

  float getBarBottomY() {
    return btnY - btnSize * 0.78;
  }

  float getBarTopY() {
    return getBarBottomY() - getBarHeight();
  }
}
