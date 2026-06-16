// Stage-aware textured background plane for the 3D gameplay scene.
class ScrollingBackground {

  PImage bgImg;

  String currentImageFileName = "";

  String fairyStartImageFileName = "land_background.png";
  String mermaidImageFileName    = "lake_background.png";
  String fairyFinalImageFileName = "final_background.png";

  float zStart = -1350;
  float zEnd   = -520;
  float z      = zStart;

  float progress = 0;
  float speed    = 0.0005;  // lower = slower zoom

  float startScale = 2.85;
  float endScale   = 3.10;

  ScrollingBackground(String imageFileName) {
    setImage(imageFileName, true);
  }

  void setImage(String imageFileName, boolean resetMotion) {
    if (imageFileName == null) return;

    if (imageFileName.equals(currentImageFileName)) {
      if (resetMotion) {
        reset();
      }
      return;
    }

    currentImageFileName = imageFileName;
    bgImg = loadImage(currentImageFileName);

    if (resetMotion) {
      reset();
    }
  }

  void applyStage(StageManager stageManager) {
    String desiredImage;

    if (stageManager.isMermaidStage()) {
      desiredImage = mermaidImageFileName;
    } else if (stageManager.isFinalFairyStage()) {
      desiredImage = fairyFinalImageFileName;
    } else {
      desiredImage = fairyStartImageFileName;
    }

    setImage(desiredImage, true);
  }

  void reset() {
    progress = 0;
    z = zStart;
  }

  void update() {
    progress += speed;
    progress = constrain(progress, 0, 1);

    float eased = getEasedProgress();
    z = lerp(zStart, zEnd, eased);
  }

  float getEasedProgress() {
    return progress * progress * (3 - 2 * progress);
  }


  void draw() {
    if (bgImg == null) return;

    update();

    float eased = getEasedProgress();

    pushMatrix();
    translate(width / 2.0, height / 2.0, z);

    noStroke();
    textureMode(NORMAL);

    beginShape();
    texture(bgImg);

    float bgScale = lerp(startScale, endScale, eased);

    float pw = width  * bgScale;
    float ph = height * bgScale;

    vertex(-pw/2, -ph/2, 0, 0, 0);
    vertex( pw/2, -ph/2, 0, 1, 0);
    vertex( pw/2,  ph/2, 0, 1, 1);
    vertex(-pw/2,  ph/2, 0, 0, 1);

    endShape(CLOSE);
    popMatrix();
  }
}
