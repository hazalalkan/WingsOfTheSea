// SETUP NOTE
// See README.txt for required libraries, asset placement, and run instructions.

// Main Processing sketch for Wings of the Sea.
// Owns global screen routing, fade transitions, audio state, and Processing input callbacks.

import java.util.HashMap;
import processing.sound.*;
import processing.event.*;

// -------- Global screen objects --------
StartScreen startScreen;
InfoScreen  infoScreen;
GameScreen  gameScreen;
PauseScreen pauseScreen;
TransitionScreen transitionScreen;
ScoreScreen scoreScreen;
PImage transitionFrozenFrame;

// -------- Fade, screen, and transition constants --------
final int FADE_NONE = 0;
final int FADE_COVER = 1;
final int FADE_REVEAL = 2;
final int FADE_DURATION_MS = 1500;

boolean transitionFadeActive = false;
int transitionFadeMode = FADE_NONE;
int transitionFadeStartMs = 0;

final int SCREEN_START      = 0;
final int SCREEN_INFO       = 1;
final int SCREEN_GAME       = 2;
final int SCREEN_TRANSITION = 3;
final int SCREEN_SCORE      = 4;

final int TRANSITION_NONE           = 0;
final int TRANSITION_STAGE_CHANGE   = 1;
final int TRANSITION_FINAL_GAME_END = 2;
final int TRANSITION_GAME_START     = 3;

final String[] GAME_START_TRANSITION_IMAGES = {
  "transition0_01.png", "transition0_02.png", "transition0_03.png", "transition0_04.png"
};

int activeTransitionType = TRANSITION_NONE;
boolean transitionWaitingForCurtain = false;
String[] pendingTransitionImages = new String[0];
int pendingTransitionType = TRANSITION_NONE;

// -------- Global audio state --------
SoundFile bgMusic;
SoundManager sounds;

boolean musicOn = true;
boolean soundOn = true;

float musicVolume = 0.8;
float soundVolume = 0.85;

boolean musicStarted = false;
boolean musicFailed = false;

boolean gamePaused = false;

int currentScreen = SCREEN_START;  // Start -> Info -> Intro Transition -> Game -> Transition -> Score

String soundtrackFileName = "soundtrack.mp3";

// -------- Processing setup and main draw loop --------
void setup() {
  fullScreen(P3D);
  surface.setTitle("Wings of the Sea");
  smooth(4);
  frameRate(60);

  sounds = new SoundManager(this);
  setSoundEffectsEnabled(soundOn);
  setSoundEffectsVolume(soundVolume);

  startScreen = new StartScreen();
  infoScreen  = new InfoScreen();

  gameScreen  = null;
  pauseScreen = null;
  transitionScreen = new TransitionScreen();
  scoreScreen = new ScoreScreen();
  }

void draw() {
  startBackgroundMusicSafely();

  if (transitionWaitingForCurtain) {
    drawFrozenTransitionFrame();
  } else {
    switch (currentScreen) {
      case SCREEN_START:
        startScreen.display();
        break;

      case SCREEN_INFO:
        infoScreen.display();
        break;

      case SCREEN_GAME:
        ensureGameplayScreensReady();

        if (!gamePaused) {
          gameScreen.display();

          if (currentScreen == SCREEN_GAME) {
            showScoreScreenIfGameEnded();
          }
        } else {
          pauseScreen.display(isLakePauseBoxNeeded());
        }
        break;

      case SCREEN_TRANSITION:
        transitionScreen.display();
        break;

      case SCREEN_SCORE:
        scoreScreen.display();
        break;
    }
  }

  drawTransitionFade();
  finishPendingTransitionSwitchIfCovered();
}

// -------- Transition fade rendering --------
boolean isLakePauseBoxNeeded() {
  if (gameScreen == null) {
    return false;
  }

  return gameScreen.isLakeStageForPause();
}

void drawFrozenTransitionFrame() {
  pushStyle();
  pushMatrix();

  camera();
  noLights();
  hint(DISABLE_DEPTH_TEST);

  imageMode(CORNER);

  if (transitionFrozenFrame != null) {
    image(transitionFrozenFrame, 0, 0, width, height);
  } else {
    background(255, 214, 234);
  }

  hint(ENABLE_DEPTH_TEST);

  popMatrix();
  popStyle();
}

void startTransitionFadeCover() {
  transitionFadeMode = FADE_COVER;
  transitionFadeStartMs = millis();
  transitionFadeActive = true;
}

void startTransitionFadeReveal() {
  transitionFadeMode = FADE_REVEAL;
  transitionFadeStartMs = millis();
  transitionFadeActive = true;
}

boolean isTransitionFadeReadyForScreenSwitch() {
  return transitionFadeActive &&
         transitionFadeMode == FADE_COVER &&
         getTransitionFadeProgress() >= 1.0;
}

void drawTransitionFade() {
  if (!transitionFadeActive) {
    return;
  }

  float progress = getTransitionFadeProgress();

  if (transitionFadeMode == FADE_REVEAL && progress >= 1.0) {
    transitionFadeActive = false;
    transitionFadeMode = FADE_NONE;
    return;
  }

  float coverage = getTransitionFadeCoverage(progress);

  pushStyle();
  pushMatrix();

  camera();
  noLights();
  hint(DISABLE_DEPTH_TEST);

  drawTransitionFadeBackground(coverage);

  hint(ENABLE_DEPTH_TEST);

  popMatrix();
  popStyle();
}

void drawTransitionFadeBackground(float coverage) {
  rectMode(CORNER);
  noStroke();

  float alpha = 255 * constrain(coverage, 0, 1);

  for (int y = 0; y < height; y++) {
    float a = map(y, 0, height, 0, 1);

    fill(
      lerp(255, 248, a),
      lerp(224, 190, a),
      lerp(238, 224, a),
      alpha
    );

    rect(0, y, width, 1);
  }
}

float getTransitionFadeProgress() {
  return constrain((millis() - transitionFadeStartMs) / (float) FADE_DURATION_MS, 0, 1);
}

float getTransitionFadeCoverage(float progress) {
  float eased = easeInOutCubic(progress);

  if (transitionFadeMode == FADE_COVER) {
    return eased;
  }

  if (transitionFadeMode == FADE_REVEAL) {
    return 1.0 - eased;
  }

  return 0;
}

float easeInOutCubic(float x) {
  return x * x * (3.0 - 2.0 * x);
}

void finishPendingTransitionSwitchIfCovered() {
  if (!transitionWaitingForCurtain) {
    return;
  }

  if (!isTransitionFadeReadyForScreenSwitch()) {
    return;
  }

  if (transitionScreen == null) {
    transitionScreen = new TransitionScreen();
  }

  activeTransitionType = pendingTransitionType;
  transitionScreen.setImages(pendingTransitionImages);

  currentScreen = SCREEN_TRANSITION;
  transitionWaitingForCurtain = false;
  transitionFrozenFrame = null;

  startTransitionFadeReveal();
}

// -------- Screen construction and navigation --------
// Creates gameplay-only screens lazily so menu screens do not reload a run unnecessarily.
void ensureGameplayScreensReady() {
  if (gameScreen == null) {
    gameScreen = new GameScreen();
  }

  if (pauseScreen == null) {
    pauseScreen = new PauseScreen();
  }
}

// Small navigation helpers keep screen classes from depending on numeric screen IDs.
void goToInfoScreen() {
  currentScreen = SCREEN_INFO;
}

void goToStartScreen() {
  currentScreen = SCREEN_START;
}

// Discards the current 60-second run. A fresh GameScreen is created only when gameplay starts again.
void discardCurrentRun() {
  if (gameScreen != null) {
    gameScreen.pauseGameTimer();
    gameScreen.clearPlayerInput();
  }

  gameScreen = null;
  pauseScreen = null;
  gamePaused = false;
}

// Starts music after a short delay to avoid sound loading issues during the first frames.
void startBackgroundMusicSafely() {
  if (!musicOn) return;
  if (musicStarted) return;
  if (musicFailed) return;

  if (frameCount < 45) return;

  try {
    bgMusic = new SoundFile(this, soundtrackFileName);
    bgMusic.amp(musicVolume);
    bgMusic.loop();

    musicStarted = true;

    println("Background music started: " + soundtrackFileName);
  }
  catch (Exception e) {
    musicFailed = true;

    println("Background music could not start.");
    println(e.getMessage());
  }
}

// -------- Music and sound-effect controls --------
void setMusicEnabled(boolean value) {
  musicOn = value;

  if (bgMusic != null) {
    if (musicOn) {
      bgMusic.amp(musicVolume);
      bgMusic.loop();
    } else {
      bgMusic.stop();
    }
  }
}

void toggleMusic() {
  setMusicEnabled(!musicOn);
}

void setMusicVolume(float value) {
  musicVolume = constrain(value, 0, 1);

  if (bgMusic != null) {
    bgMusic.amp(musicVolume);
  }
}

void setSoundEffectsEnabled(boolean value) {
  soundOn = value;

  if (sounds != null) {
    sounds.setEnabled(soundOn);
    soundVolume = sounds.getSoundVolume();
  }
}

void toggleSoundEffects() {
  setSoundEffectsEnabled(!soundOn);
}

void setSoundEffectsVolume(float value) {
  soundVolume = constrain(value, 0, 1);

  if (sounds != null) {
    sounds.setSoundVolume(soundVolume);
    soundVolume = sounds.getSoundVolume();
  }
}

boolean areSoundEffectsEnabled() {
  if (sounds != null) {
    soundOn = sounds.isEnabled();
  }

  return soundOn;
}

float getSoundEffectsVolume() {
  if (sounds != null) {
    soundVolume = sounds.getSoundVolume();
  }

  return soundVolume;
}

// -------- Gameplay lifecycle helpers --------
void pauseGame() {
  ensureGameplayScreensReady();

  if (gameScreen != null) {
    gameScreen.pauseGameTimer();
  }

  if (pauseScreen != null) {
    pauseScreen.captureCurrentFrame();
    pauseScreen.visible = true;
  }

  gamePaused = true;
}

void resumeGame() {
  if (gameScreen != null) {
    gameScreen.resumeGameTimer();
  }

  gamePaused = false;

  if (pauseScreen != null) {
    pauseScreen.visible = false;
  }
}

void restartGame() {
  if (sounds != null) {
    sounds.resetEndSounds();
  }

  gameScreen = new GameScreen();
  resumeGame();
  currentScreen = SCREEN_GAME;
}

void goToMainMenu() {
  if (sounds != null) {
    sounds.resetEndSounds();
  }

  discardCurrentRun();
  goToStartScreen();
}

// -------- Screen transition and result flow --------
void startGameplayIntroTransition() {
  discardCurrentRun();
  showTransition(GAME_START_TRANSITION_IMAGES, TRANSITION_GAME_START);
}

void showTransition(String[] imageFileNames, int transitionType) {
  if (imageFileNames == null) {
    imageFileNames = new String[0];
  }

  if (gameScreen != null) {
    gameScreen.pauseGameTimer();
    gameScreen.clearPlayerInput();
  }

  pendingTransitionImages = imageFileNames.clone();
  pendingTransitionType = transitionType;
  activeTransitionType = transitionType;

  transitionFrozenFrame = get();
  transitionWaitingForCurtain = true;

  startTransitionFadeCover();
}

// Applies the result of the current transition: intro, stage change, or final score flow.
void finishTransition() {
  boolean goToScoreScreen = false;

  if (activeTransitionType == TRANSITION_GAME_START) {
    gamePaused = false;

    if (pauseScreen != null) {
      pauseScreen.visible = false;
    }
  }

  if (gameScreen != null) {
    if (activeTransitionType == TRANSITION_STAGE_CHANGE) {
      gameScreen.finishStageTransitionFromScreen();
    } else if (activeTransitionType == TRANSITION_FINAL_GAME_END) {
      gameScreen.finishFinalTransitionFromScreen();
      goToScoreScreen = true;
    }

    gameScreen.clearPlayerInput();
  }

  activeTransitionType = TRANSITION_NONE;

  if (goToScoreScreen) {
    openScoreScreen(true);
  } else {
    currentScreen = SCREEN_GAME;
  }

  startTransitionFadeReveal();
}

void showScoreScreenIfGameEnded() {
  if (gameScreen == null) {
    return;
  }

  if (!gameScreen.gameOver) {
    return;
  }

  openScoreScreen(gameScreen.playerWon);
}

void openScoreScreen(boolean playerWon) {
  if (scoreScreen == null) {
    scoreScreen = new ScoreScreen();
  }

  int finalScore = 0;

  if (gameScreen != null) {
    finalScore = gameScreen.getFinalScore();
    gameScreen.pauseGameTimer();
    gameScreen.clearPlayerInput();
  }

  if (sounds != null) {
    if (playerWon) {
      sounds.playWin();
    } else {
      sounds.playLose();
    }
  }

  scoreScreen.setResult(playerWon, finalScore);

  gamePaused = false;

  if (pauseScreen != null) {
    pauseScreen.visible = false;
  }

  currentScreen = SCREEN_SCORE;
}

// -------- Keyboard input routing --------
void keyPressed() {
  if (transitionWaitingForCurtain) {
    return;
  }

  boolean enterPressed = (keyCode == ENTER || keyCode == RETURN);
  boolean pPressed = (key == 'p' || key == 'P');
  boolean rPressed = (key == 'r' || key == 'R');

  if (shouldPlayKeyboardButtonClick(enterPressed, pPressed, rPressed)) {
    if (sounds != null) sounds.playButtonClick();
  }

  if (currentScreen == SCREEN_GAME && pPressed) {
    if (gamePaused) {
      resumeGame();
    } else {
      pauseGame();
    }

    return;
  }

  if ((currentScreen == SCREEN_GAME || currentScreen == SCREEN_SCORE) && rPressed) {
    restartGame();
    return;
  }

  if (gamePaused) {
    return;
  }

  switch (currentScreen) {
    case SCREEN_START:
      startScreen.handleKeyPressed(key, keyCode);
      break;

    case SCREEN_INFO:
      infoScreen.handleKeyPressed(key, keyCode);
      break;

    case SCREEN_GAME:
      ensureGameplayScreensReady();
      gameScreen.handleKeyPressed(key, keyCode);
      break;

    case SCREEN_TRANSITION:
      transitionScreen.handleKeyPressed(key, keyCode);
      break;

    case SCREEN_SCORE:
      handleScoreScreenAction(scoreScreen.handleKeyPressed(key, keyCode));
      break;
  }
}

boolean shouldPlayKeyboardButtonClick(boolean enterPressed, boolean pPressed, boolean rPressed) {
  if (enterPressed) {
    return currentScreen == SCREEN_START ||
           currentScreen == SCREEN_INFO ||
           currentScreen == SCREEN_TRANSITION ||
           currentScreen == SCREEN_SCORE;
  }

  if (pPressed) {
    return currentScreen == SCREEN_GAME;
  }

  if (rPressed) {
    return currentScreen == SCREEN_GAME || currentScreen == SCREEN_SCORE;
  }

  return false;
}

void keyReleased() {
  if (transitionWaitingForCurtain) {
    return;
  }

  if (gamePaused) {
    return;
  }

  if (currentScreen == SCREEN_GAME) {
    ensureGameplayScreensReady();
    gameScreen.handleKeyReleased(key, keyCode);
  } else if (currentScreen == SCREEN_TRANSITION && gameScreen != null) {
    gameScreen.clearPlayerInput();
  }
}

void handleScoreScreenAction(int clickedButton) {
  if (scoreScreen == null) {
    return;
  }

  if ((clickedButton == scoreScreen.BUTTON_RESTART ||
       clickedButton == scoreScreen.BUTTON_MAIN_MENU ||
       clickedButton == scoreScreen.BUTTON_QUIT) &&
      sounds != null) {
    sounds.playButtonClick();
  }

  if (clickedButton == scoreScreen.BUTTON_RESTART) {
    restartGame();
  } else if (clickedButton == scoreScreen.BUTTON_MAIN_MENU) {
    goToMainMenu();
  } else if (clickedButton == scoreScreen.BUTTON_QUIT) {
    exit();
  }
}

// -------- Mouse input routing --------
void mousePressed() {
  if (transitionWaitingForCurtain) {
    return;
  }

  if (currentScreen == SCREEN_GAME && gamePaused) {
    ensureGameplayScreensReady();
    int clickedButton = pauseScreen.handleMousePressed();

    if (clickedButton != pauseScreen.BUTTON_NONE && sounds != null) {
      sounds.playButtonClick();
    }

    if (clickedButton == pauseScreen.BUTTON_RESUME) {
      resumeGame();
    } else if (clickedButton == pauseScreen.BUTTON_RESTART) {
      restartGame();
    } else if (clickedButton == pauseScreen.BUTTON_MAIN_MENU) {
      goToMainMenu();
    } else if (clickedButton == pauseScreen.BUTTON_QUIT) {
      exit();
    }

    return;
  }

  if (currentScreen == SCREEN_SCORE) {
    handleScoreScreenAction(scoreScreen.handleMousePressed(mouseX, mouseY));
    return;
  }

  if (currentScreen == SCREEN_START) {
    startScreen.handleMousePressed(mouseX, mouseY);
  }

  if (currentScreen == SCREEN_GAME) {
    ensureGameplayScreensReady();
    gameScreen.handleMousePressed(mouseX, mouseY);
  }
}

void mouseDragged() {
  if (transitionWaitingForCurtain) {
    return;
  }

  if (currentScreen == SCREEN_GAME && gamePaused) {
    ensureGameplayScreensReady();
    if (pauseScreen != null) {
      pauseScreen.handleMouseDragged(mouseX);
    }

    return;
  }

  if (gamePaused) {
    return;
  }

  if (currentScreen == SCREEN_START) {
    startScreen.handleMouseDragged(mouseY);
  }

  if (currentScreen == SCREEN_GAME) {
    ensureGameplayScreensReady();
    gameScreen.handleMouseDragged(mouseX, mouseY);
  }
}

void mouseReleased() {
  if (transitionWaitingForCurtain) {
    return;
  }

  if (currentScreen == SCREEN_GAME && gamePaused) {
    ensureGameplayScreensReady();
    if (pauseScreen != null) {
      pauseScreen.handleMouseReleased();
    }

    return;
  }

  if (gamePaused) {
    return;
  }

  if (currentScreen == SCREEN_START) {
    startScreen.handleMouseReleased();
  }

  if (currentScreen == SCREEN_GAME) {
    ensureGameplayScreensReady();
    gameScreen.handleMouseReleased();
  }
}

void mouseWheel(MouseEvent e) {
  if (transitionWaitingForCurtain) {
    return;
  }

  if (gamePaused) {
    return;
  }

  if (currentScreen == SCREEN_GAME) {
    ensureGameplayScreensReady();
    gameScreen.handleMouseWheel(e.getCount());
  }
}
