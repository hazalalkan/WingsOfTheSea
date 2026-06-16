// Stage-aware collectible controller that spawns, updates, draws, and scores collectibles.
class CollectibleManager {

  final int MODE_FAIRY = 0;
  final int MODE_MERMAID = 1;
  final int MODE_FINAL_FAIRY = 2;

  int currentMode = MODE_FAIRY;

  PImage petalImg;
  PImage goldenPetalImg;
  PImage pearlImg;
  PImage goldenPearlImg;

  Collectible[] collectibles = new Collectible[3];

  CollectibleManager() {
    petalImg = loadImage("petal.png");
    goldenPetalImg = loadImage("golden_petal.png");

    pearlImg = loadImage("pearl.png");
    goldenPearlImg = loadImage("golden_pearl.png");

    for (int i = 0; i < collectibles.length; i++) {
      collectibles[i] = new Collectible(petalImg, goldenPetalImg, i);
    }
  }

  void reset() {
    currentMode = MODE_FAIRY;
    applyCurrentImages();
    resetCollectibles(true);
  }

  // Rebuilds the collectible set for the current stage; the final fairy stage has no regular collectibles.
  void applyStage(StageManager stageManager) {
    if (stageManager.isMermaidStage()) {
      currentMode = MODE_MERMAID;
    } else if (stageManager.isFinalFairyStage()) {
      currentMode = MODE_FINAL_FAIRY;
    } else {
      currentMode = MODE_FAIRY;
    }

    applyCurrentImages();

    if (hasCollectiblesInCurrentStage()) {
      resetCollectibles(true);
    }
  }

  void applyCurrentImages() {
    if (currentMode == MODE_MERMAID) {
      for (int i = 0; i < collectibles.length; i++) {
        collectibles[i].setImages(pearlImg, goldenPearlImg);
      }
    } else {
      for (int i = 0; i < collectibles.length; i++) {
        collectibles[i].setImages(petalImg, goldenPetalImg);
      }
    }
  }

  boolean hasCollectiblesInCurrentStage() {
    return currentMode == MODE_FAIRY || currentMode == MODE_MERMAID;
  }

  void resetCollectibles(boolean spreadAtStart) {
    for (int i = 0; i < collectibles.length; i++) {
      collectibles[i].reset(spreadAtStart);
    }
  }

  void update() {
    if (!hasCollectiblesInCurrentStage()) {
      return;
    }

    for (int i = 0; i < collectibles.length; i++) {
      collectibles[i].update();
    }
  }

  void draw() {
    if (!hasCollectiblesInCurrentStage()) {
      return;
    }

    for (int i = 0; i < collectibles.length; i++) {
      collectibles[i].draw();
    }
  }

  boolean checkCollectionWithRosa(Rosa rosa, float t, ScoreManager scoreManager) {
    if (!hasCollectiblesInCurrentStage()) {
      return false;
    }

    boolean collectedSomething = false;

    for (int i = 0; i < collectibles.length; i++) {
      Collectible c = collectibles[i];

      if (c.hitsRosa(rosa, t)) {
        if (c.isGolden()) {
          scoreManager.addGoldenCollectible();
          println("Golden collectible! Score: " + scoreManager.getScore());
        } else {
          scoreManager.addNormalCollectible();
          println("Normal collectible! Score: " + scoreManager.getScore());
        }

        c.collect(currentMode == MODE_MERMAID);
        collectedSomething = true;
      }
    }

    return collectedSomething;
  }
}
