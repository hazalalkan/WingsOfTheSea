// Stage-aware obstacle controller that creates obstacle sets and reports collision types.
final int HIT_NONE    = 0;
final int HIT_GREMLIN = 1;
final int HIT_GEYSER  = 2;
final int HIT_SEAWEED = 3;

class ObstacleManager {

  final int MODE_FAIRY = 0;
  final int MODE_MERMAID = 1;
  final int MODE_FINAL_FAIRY = 2;

  int currentMode = MODE_FAIRY;

  Gremlin[] gremlins = new Gremlin[3];

  PImage gremlinBody;
  PImage gremlinWings;
  PImage finalGremlinBody;
  PImage finalGremlinWings;

  final float FINAL_GREMLIN_START_Z = -1500;
  final float FINAL_GREMLIN_SPACING_Z = 375;
  final float FINAL_GREMLIN_JITTER_Z = 50;
  final float FINAL_GREMLIN_MIN_SPEED_Z = 4.4;
  final float FINAL_GREMLIN_MAX_SPEED_Z = 4.8;

  Geyser[] geysers = new Geyser[1];
  Seaweed[] seaweeds = new Seaweed[1];

  // Load shared obstacle assets once and reuse them across obstacle instances.
  ObstacleManager() {
    loadGremlinTextures();

    for (int i = 0; i < gremlins.length; i++) {
      gremlins[i] = new Gremlin(gremlinBody, gremlinWings, i);
    }

    PImage[] mermaidTextures = loadMermaidTextures();
    createMermaidObstacles(mermaidTextures[0], mermaidTextures[1], mermaidTextures[2]);
  }

  void loadGremlinTextures() {
    gremlinBody  = loadImage("gremlin_body.png");
    gremlinWings = loadImage("gremlin_wings.png");

    finalGremlinBody  = loadImage("gremlin_body_alt.png");
    finalGremlinWings = loadImage("gremlin_wings_alt.png");

    if (finalGremlinBody == null) {
      finalGremlinBody = gremlinBody;
    }

    if (finalGremlinWings == null) {
      finalGremlinWings = gremlinWings;
    }
  }

  void applyGremlinImages(PImage bodyImage, PImage wingsImage) {
    for (int i = 0; i < gremlins.length; i++) {
      gremlins[i].setImages(bodyImage, wingsImage);
    }
  }

  boolean isGremlinMode() {
    return currentMode == MODE_FAIRY || currentMode == MODE_FINAL_FAIRY;
  }

  PImage[] loadMermaidTextures() {
    PImage lakeFallbackTexture = loadImage("lake_background.png");

    PImage seaweedTexture = loadImage("seaweed_texture.png");
    PImage geyserCraterTexture = loadImage("geyser_crater_texture.png");
    PImage geyserEruptionTexture = loadImage("geyser_eruption_texture.png");

    if (seaweedTexture == null) {
      seaweedTexture = lakeFallbackTexture;
    }

    if (geyserCraterTexture == null) {
      geyserCraterTexture = lakeFallbackTexture;
    }

    if (geyserEruptionTexture == null) {
      geyserEruptionTexture = lakeFallbackTexture;
    }

    if (lakeFallbackTexture != null) {
      lakeFallbackTexture.resize(512, 0);
    }

    if (seaweedTexture != null) {
      seaweedTexture.resize(512, 0);
    }

    if (geyserCraterTexture != null) {
      geyserCraterTexture.resize(512, 0);
    }

    if (geyserEruptionTexture != null) {
      geyserEruptionTexture.resize(512, 0);
    }

    return new PImage[] { seaweedTexture, geyserCraterTexture, geyserEruptionTexture };
  }

  void createMermaidObstacles(PImage seaweedTexture, PImage geyserCraterTexture, PImage geyserEruptionTexture) {
    for (int i = 0; i < geysers.length; i++) {
      geysers[i] = new Geyser(geyserCraterTexture, geyserEruptionTexture, i);
    }

    for (int i = 0; i < seaweeds.length; i++) {
      seaweeds[i] = new Seaweed(seaweedTexture, i + geysers.length);
    }
  }

  void reset() {
    currentMode = MODE_FAIRY;

    applyGremlinImages(gremlinBody, gremlinWings);
    resetFairyObstacles(true);

    resetMermaidObstacles(true);
  }

  // Switches active obstacle behavior when the player changes form/stage.
  void applyStage(StageManager stageManager) {
    if (stageManager.isMermaidStage()) {
      currentMode = MODE_MERMAID;
    } else if (stageManager.isFinalFairyStage()) {
      currentMode = MODE_FINAL_FAIRY;
    } else {
      currentMode = MODE_FAIRY;
    }

    resetForCurrentMode();
  }

  void resetForCurrentMode() {
    if (currentMode == MODE_FAIRY) {
      applyGremlinImages(gremlinBody, gremlinWings);
      resetFairyObstacles(true);
      return;
    }

    if (currentMode == MODE_FINAL_FAIRY) {
      resetFinalFairyObstacles();
      return;
    }

    if (currentMode == MODE_MERMAID) {
      resetMermaidObstacles(true);
    }
  }

  void resetFairyObstacles(boolean spreadAtStart) {
    for (int i = 0; i < gremlins.length; i++) {
      gremlins[i].reset(spreadAtStart);
    }
  }

  void resetFinalFairyObstacles() {
    applyGremlinImages(finalGremlinBody, finalGremlinWings);

    for (int i = 0; i < gremlins.length; i++) {
      gremlins[i].resetOneShotWave(FINAL_GREMLIN_START_Z,
                                   FINAL_GREMLIN_SPACING_Z,
                                   FINAL_GREMLIN_JITTER_Z,
                                   FINAL_GREMLIN_MIN_SPEED_Z,
                                   FINAL_GREMLIN_MAX_SPEED_Z);
    }
  }

  void resetMermaidObstacles(boolean spreadAtStart) {
    for (int i = 0; i < geysers.length; i++) {
      geysers[i].reset(spreadAtStart);
    }

    for (int i = 0; i < seaweeds.length; i++) {
      seaweeds[i].reset(spreadAtStart);
    }
  }

  void update() {
    if (isGremlinMode()) {
      updateFairyObstacles();
      return;
    }

    if (currentMode == MODE_MERMAID) {
      updateMermaidObstacles();
    }
  }

  void draw() {
    if (isGremlinMode()) {
      drawFairyObstacles();
      return;
    }

    if (currentMode == MODE_MERMAID) {
      drawMermaidObstacles();
    }
  }

  // Returns the specific obstacle type so the game can play the matching hit sound.
  int checkCollisionTypeWithRosa(Rosa rosa, float t) {
    if (isGremlinMode()) {
      return checkFairyCollisionTypeWithRosa(rosa, t);
    }

    if (currentMode == MODE_MERMAID) {
      return checkMermaidCollisionTypeWithRosa(rosa, t);
    }

    return HIT_NONE;
  }

  void updateFairyObstacles() {
    for (int i = 0; i < gremlins.length; i++) {
      gremlins[i].update();
    }
  }

  void drawFairyObstacles() {
    for (int i = 0; i < gremlins.length; i++) {
      gremlins[i].draw();
    }
  }

  int checkFairyCollisionTypeWithRosa(Rosa rosa, float t) {
    float rosaSX = rosa.getScreenX(t);
    float rosaSY = rosa.getScreenY(t);

    for (int i = 0; i < gremlins.length; i++) {
      Gremlin g = gremlins[i];

      if (!g.isActive()) {
        continue;
      }

      if (g.z < -90 || g.z > 125) {
        continue;
      }

      if (g.alpha < 80) {
        continue;
      }

      float gSX = screenX(g.x, g.y, g.z);
      float gSY = screenY(g.x, g.y, g.z);

      float hitW = rosa.h * 0.20 + g.gH * 0.28;
      float hitH = rosa.h * 0.18 + g.gH * 0.28;

      if (abs(gSX - rosaSX) < hitW && abs(gSY - rosaSY) < hitH) {
        g.forceExit();
        return HIT_GREMLIN;
      }
    }

    return HIT_NONE;
  }

  // Recycles mermaid obstacles after they leave the screen so pressure stays continuous.
  void updateMermaidObstacles() {
    for (int i = 0; i < geysers.length; i++) {
      geysers[i].update();
    }

    for (int i = 0; i < seaweeds.length; i++) {
      seaweeds[i].update();
    }
  }

  void drawMermaidObstacles() {
    for (int i = 0; i < geysers.length; i++) {
      geysers[i].draw();
    }

    for (int i = 0; i < seaweeds.length; i++) {
      seaweeds[i].draw();
    }
  }

  int checkMermaidCollisionTypeWithRosa(Rosa rosa, float t) {
    for (int i = 0; i < geysers.length; i++) {
      if (geysers[i].hitsRosa(rosa, t)) {
        geysers[i].forceExit();
        return HIT_GEYSER;
      }
    }

    for (int i = 0; i < seaweeds.length; i++) {
      if (seaweeds[i].hitsRosa(rosa, t)) {
        seaweeds[i].forceExit();
        return HIT_SEAWEED;
      }
    }

    return HIT_NONE;
  }
}
