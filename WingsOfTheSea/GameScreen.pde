// Active gameplay coordinator for player, camera, timer, stages, obstacles, collectibles, HUD, and Lumi.
class GameScreen {

  // Core gameplay systems owned by this screen.
  ScrollingBackground scrollingBackground;

  Rosa rosa;
  Lumi lumi;

  ObstacleManager obstacleManager;
  CollectibleManager collectibleManager;

  CameraController cameraController;
  GameTimer gameTimer;
  GameHUD gameHUD;
  StageManager stageManager;
  ScoreManager scoreManager;

  // Runtime state for animation, lives, hit cooldown, and end-game status.
  float t = 0;

  int maxLives = 5;
  int lives = maxLives;
  int hitCooldown = 0;

  boolean gameOver = false;
  boolean playerWon = false;
  boolean finalTransitionAlreadyShown = false;
  boolean lumiCueStarted = false;

  final int LUMI_APPEAR_DELAY_MS = 5000;

  // Loads assets and creates the gameplay objects once for a new run.
  GameScreen() {
    scrollingBackground = new ScrollingBackground("land_background.png");

    PImage rosaBody  = loadImage("rosa_body.png");
    PImage rosaWings = loadImage("rosa_wings.png");

    PImage mermaidBody = loadImage("mermaid_body.png");
    PImage mermaidTail = loadImage("mermaid_tail.png");

    PImage lumiBody = loadImage("lumi_body.png");
    PImage lumiWing = loadImage("lumi_wings.png");

    rosa = new Rosa(rosaBody, rosaWings);
    rosa.setMermaidImages(mermaidBody, mermaidTail);

    lumi = new Lumi(lumiBody, lumiWing);

    obstacleManager = new ObstacleManager();
    collectibleManager = new CollectibleManager();

    cameraController = new CameraController();
    stageManager = new StageManager();
    gameTimer = new GameTimer(stageManager.getTotalDurationMs());
    gameHUD = new GameHUD();
    scoreManager = new ScoreManager();
  }

  // Main gameplay frame: update world, draw scene, draw HUD, then evaluate stage/end transitions.
  void display() {
    if (!gameTimer.hasStarted()) {
      startNewRun();
    }
  
    t += 0.04;
  
    if (hitCooldown > 0) {
      hitCooldown--;
    }
  
    boolean timeFinished = !gameOver && gameTimer.isFinished();
  
    if (!gameOver && currentScreen == SCREEN_TRANSITION) {
      return;
    }
  
    background(20, 10, 40);
  
    cameraController.apply();
    scrollingBackground.draw();
  
    if (!gameOver && !timeFinished) {
      rosa.update();
  
      obstacleManager.update();
      updateGameplayLumi();
      collectibleManager.update();
  
      checkObstacleCollisions();
      checkCollectibleCollisions();
      checkGameplayLumiCollision();
    }
  
    hint(DISABLE_DEPTH_TEST);
  
    obstacleManager.draw();
    drawGameplayLumi();
    collectibleManager.draw();
    rosa.draw(t, hitCooldown);
  
    hint(ENABLE_DEPTH_TEST);
  
    gameHUD.display(gameTimer, lives, stageManager, scoreManager);
  
    updateTimer();
  
    if (!finalTransitionAlreadyShown) {
      updateStageTransitionAfterFrame();
    }
  }

  // Resets all gameplay systems to their initial state when a run starts or restarts.
  void startNewRun() {
    if (sounds != null) {
      sounds.resetEndSounds();
    }

    gameTimer.start();
    stageManager.reset();
    scoreManager.reset();

    lives = maxLives;
    hitCooldown = 0;

    gameOver = false;
    playerWon = false;
    finalTransitionAlreadyShown = false;
    lumiCueStarted = false;

    rosa.reset();
    rosa.becomeFairy();

    if (lumi != null) {
      lumi.reset();
    }

    scrollingBackground.reset();
    scrollingBackground.applyStage(stageManager);

    obstacleManager.reset();
    obstacleManager.applyStage(stageManager);

    collectibleManager.reset();
    collectibleManager.applyStage(stageManager);
  }

  void pauseGameTimer() {
    gameTimer.pauseTimer();
  }

  void resumeGameTimer() {
    gameTimer.resumeTimer();
  }

  void clearPlayerInput() {
    if (rosa != null) {
      rosa.clearInputState();
    }
  }

  // Checks timed stage changes after drawing so the frozen fade frame shows the exact timer boundary.
  void updateStageTransitionAfterFrame() {
    if (gameOver) {
      return;
    }

    stageManager.update(gameTimer);

    if (stageManager.stageJustChanged()) {
      requestStageTransitionScreen();
    }
  }

  // Opens the correct transition panel when the timed stage changes.
  void requestStageTransitionScreen() {
    if (stageManager.isMermaidStage()) {
      showTransition(new String[] { "transition1_01.png", "transition1_02.png", "transition1_03.png", "transition1_04.png" }, TRANSITION_STAGE_CHANGE);
    } else if (stageManager.isFinalFairyStage()) {
      showTransition(new String[] { "transition2_01.png", "transition2_02.png", "transition2_03.png", "transition2_04.png" }, TRANSITION_STAGE_CHANGE);
    } else {
      applyStageChange();
    }
  }

  void finishStageTransitionFromScreen() {
    applyStageChange();
    resumeGameTimer();
  }

  void finishFinalTransitionFromScreen() {
    if (!gameOver) {
      scoreManager.addFinishBonus();
      gameOver = true;
      playerWon = true;
    }
  }

  int getFinalScore() {
    return scoreManager.getScore();
  }

  // Applies the new stage to Rosa, background, obstacles, collectibles, and Lumi.
  void applyStageChange() {
    if (stageManager.isMermaidStage()) {
      rosa.becomeMermaid();
      println("Stage changed: Mermaid");
    } else {
      rosa.becomeFairy();

      if (stageManager.isFinalFairyStage()) {
        println("Stage changed: Final Fairy");
      } else {
        println("Stage changed: Fairy");
      }
    }

    rosa.centerForStageStart();

    if (stageManager.isFinalFairyStage() && lumi != null) {
      lumi.reset();
      lumiCueStarted = false;
    }

    scrollingBackground.applyStage(stageManager);
    obstacleManager.applyStage(stageManager);
    collectibleManager.applyStage(stageManager);
  }

  // Shows the final transition once before ending the run and opening the score screen.
  void updateTimer() {
    if (gameTimer.isFinished()) {
      if (!finalTransitionAlreadyShown) {
        finalTransitionAlreadyShown = true;
        showTransition(new String[] { "transition3_01.png", "transition3_02.png", "transition3_03.png", "transition3_04.png" }, TRANSITION_FINAL_GAME_END);
        return;
      }

      scoreManager.addFinishBonus();

      gameOver = true;
      playerWon = true;
    }
  }

  boolean shouldStartLumiCue() {
    return stageManager.isFinalFairyStage() &&
           stageManager.getFinalStageElapsedMs(gameTimer) >= LUMI_APPEAR_DELAY_MS;
  }

  void updateGameplayLumi() {
    if (!stageManager.isFinalFairyStage() || lumi == null) {
      return;
    }

    if (!lumiCueStarted) {
      if (!shouldStartLumiCue()) {
        return;
      }

      lumi.resetForFinalCue();
      lumiCueStarted = true;
    }

    lumi.update();
  }

  void drawGameplayLumi() {
    if (stageManager.isFinalFairyStage() && lumi != null && lumiCueStarted) {
      lumi.draw();
    }
  }

  // Collision checks are kept here because they affect lives, score flow, and sounds.
  void checkObstacleCollisions() {
    if (hitCooldown > 0) return;

    int hitType = obstacleManager.checkCollisionTypeWithRosa(rosa, t);

    if (hitType != HIT_NONE) {
      if (sounds != null) {
        sounds.playObstacleHit(hitType);
      }

      lives--;
      lives = max(0, lives);

      hitCooldown = 60;

      println("Rosa was hit! Lives left: " + lives);

      if (lives <= 0) {
        gameOver = true;
        playerWon = false;
      }
    }
  }

  void checkCollectibleCollisions() {
    boolean collectedSomething = collectibleManager.checkCollectionWithRosa(rosa, t, scoreManager);

    if (collectedSomething && sounds != null) {
      sounds.playCollectible();
    }
  }

  void checkGameplayLumiCollision() {
    if (!stageManager.isFinalFairyStage() || lumi == null || !lumiCueStarted) {
      return;
    }

    if (lumi.hitsRosa(rosa, t) && lumi.collect() && sounds != null) {
      sounds.playCollectible();
    }
  }

  // Input is routed from the main sketch and delegated to the camera/player systems.
  void handleMousePressed(int mx, int my) {
    cameraController.handleMousePressed(mx, my);
  }

  void handleMouseDragged(int mx, int my) {
    cameraController.handleMouseDragged(mx, my);
  }

  void handleMouseReleased() {
    cameraController.handleMouseReleased();
  }

  void handleMouseWheel(float delta) {
    cameraController.handleMouseWheel(delta);
  }

  void handleKeyPressed(char k, int kc) {
    rosa.setMoveKey(k, kc, true);

    if (k == ' ') {
      boolean dashStarted = rosa.startDash();

      if (dashStarted && sounds != null) {
        if (rosa.isMermaid()) {
          sounds.playMermaidDash();
        } else {
          sounds.playFairyDash();
        }
      }
    }

    if (k == 'q' || k == 'Q') {
      exit();
    }

  }

  void handleKeyReleased(char k, int kc) {
    rosa.setMoveKey(k, kc, false);
  }

  boolean isLakeStageForPause() {
    return stageManager.isMermaidStage();
  }
}
