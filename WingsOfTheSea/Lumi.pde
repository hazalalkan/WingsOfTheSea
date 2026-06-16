// Final-stage companion/collectible with movement, animation, and collision detection.
class Lumi {

  PImage body;
  PImage wing;

  float x, y, z;
  float baseX, baseY;

  float speedZ;
  float t;
  float lumiH;

  float farZ  = -1350;
  float nearZ = 360;

  float alpha = 255;
  boolean exiting = false;
  boolean collected = false;
  boolean gone = false;

  float collectTimer = 0;
  float collectDuration = 44;

  final int COLLECT_PARTICLE_COUNT = 22;
  float[] particleAngle = new float[COLLECT_PARTICLE_COUNT];
  float[] particleDistance = new float[COLLECT_PARTICLE_COUNT];
  float[] particleSize = new float[COLLECT_PARTICLE_COUNT];
  float[] particleDepth = new float[COLLECT_PARTICLE_COUNT];
  float[] particleSpeed = new float[COLLECT_PARTICLE_COUNT];
  float[] particlePhase = new float[COLLECT_PARTICLE_COUNT];

  Lumi(PImage bodyImg, PImage wingImg) {
    body = bodyImg;
    wing = wingImg;

    lumiH = height * 0.15;

    reset();
  }

  void reset() {
    exiting = false;
    collected = false;
    gone = false;
    collectTimer = 0;
    alpha = 255;

    baseX = width * 0.50;
    baseY = height * 0.40;

    x = baseX;
    y = baseY;
    z = farZ;

    speedZ = 2.85;
    t = 0;
  }

  void resetForFinalCue() {
    reset();
    z = -520;
    speedZ = 2.1;
  }

  // Lumi only affects gameplay in the final stage, but keeps its own animation state here.
  void update() {
    t += 1.0;

    if (gone) {
      return;
    }

    if (collected) {
      updateCollectedEffect();
      return;
    }

    if (!exiting) {
      z += speedZ;

      x = baseX + sin(t * 0.030) * width * 0.018;
      y = baseY + sin(t * 0.040) * height * 0.010;

      if (z > 130) {
        exiting = true;
      }
    } else {
      z += speedZ * 1.10;

      x = baseX + sin(t * 0.030) * width * 0.018;
      y = baseY + sin(t * 0.040) * height * 0.010;

      alpha = lerp(alpha, 0, 0.040);

      if (alpha < 6 || z > nearZ + 180) {
        gone = true;
        alpha = 0;
      }
    }
  }

  void updateCollectedEffect() {
    collectTimer++;

    z += speedZ * 0.25;

    float progress = constrain(collectTimer / collectDuration, 0, 1);
    alpha = 255 * (1.0 - progress);

    if (collectTimer >= collectDuration) {
      collected = false;
      gone = true;
      alpha = 0;
    }
  }

  boolean hitsRosa(Rosa rosa, float sceneT) {
    if (exiting || collected || gone) {
      return false;
    }

    if (z < -90 || z > 125) {
      return false;
    }

    if (alpha < 80) {
      return false;
    }

    float lumiSX = screenX(x, getVisualY(), z);
    float lumiSY = screenY(x, getVisualY(), z);

    float rosaSX = rosa.getScreenX(sceneT);
    float rosaSY = rosa.getScreenY(sceneT);

    float hitW = rosa.h * 0.19 + lumiH * 0.36;
    float hitH = rosa.h * 0.20 + lumiH * 0.44;

    return abs(lumiSX - rosaSX) < hitW &&
           abs(lumiSY - rosaSY) < hitH;
  }

  boolean collect() {
    if (collected || exiting || gone) {
      return false;
    }

    collected = true;
    exiting = false;
    collectTimer = 0;
    alpha = 255;

    setupCollectParticles();
    return true;
  }

  void setupCollectParticles() {
    for (int i = 0; i < COLLECT_PARTICLE_COUNT; i++) {
      particleAngle[i] = random(TWO_PI);
      particleDistance[i] = random(lumiH * 0.18, lumiH * 0.82);
      particleSize[i] = random(lumiH * 0.080, lumiH * 0.175);
      particleDepth[i] = random(-lumiH * 0.12, lumiH * 0.12);
      particleSpeed[i] = random(0.75, 1.35);
      particlePhase[i] = random(TWO_PI);
    }
  }

  float getVisualY() {
    float animT = t * 0.035;
    float bob = sin(animT * 1.65) * lumiH * 0.018;
    return y + bob;
  }

  void draw() {
    if (body == null || wing == null || body.width <= 0 || body.height <= 0 || wing.width <= 0 || wing.height <= 0 || gone) {
      return;
    }

    if (collected) {
      drawCollectedEffect();
      return;
    }

    imageMode(CENTER);

    pushMatrix();
    translate(x, getVisualY(), z);

    drawLumiImages(lumiH, alpha);

    popMatrix();
  }

  void drawLumiImages(float bodyH, float drawAlpha) {
    float bodyW = bodyH * ((float) body.width / body.height);

    float animT = t * 0.035;
    float flap = sin(animT * 3.3);
    float wingBaseW = bodyW * 1.18;
    float wingW = wingBaseW * (1.0 - flap * 0.035);
    float wingH = wingBaseW * ((float) wing.height / wing.width);
    float wingY = bodyH * 0.10;

    tint(255, drawAlpha);

    pushMatrix();
    translate(0, wingY, -1);
    image(wing, 0, 0, wingW, wingH);
    popMatrix();

    image(body, 0, 0, bodyW, bodyH);

    noTint();
  }

  void drawCollectedEffect() {
    float progress = constrain(collectTimer / collectDuration, 0, 1);
    float easeOut = 1.0 - pow(1.0 - progress, 2.0);
    float fade = 1.0 - progress;

    pushMatrix();

    translate(x, y, z);

    drawCollectedLumiShrink(progress);
    drawSparkleBurst(progress, easeOut, fade);

    popMatrix();
  }

  void drawCollectedLumiShrink(float progress) {
    if (progress > 0.70) {
      return;
    }

    float shrink = 1.0 - progress * 0.70;
    float itemAlpha = 255 * (1.0 - progress / 0.70);

    imageMode(CENTER);
    drawLumiImages(lumiH * shrink, itemAlpha);
  }

  void drawSparkleBurst(float progress, float easeOut, float fade) {
    noFill();

    for (int i = 0; i < COLLECT_PARTICLE_COUNT; i++) {
      float localEase = constrain(easeOut * particleSpeed[i], 0, 1.25);
      float sparkleAlpha = 235 * fade * (0.70 + 0.30 * sin(t * 0.28 + particlePhase[i]));
      float spread = particleDistance[i] * (0.35 + localEase * 1.25);
      float px = cos(particleAngle[i]) * spread;
      float py = sin(particleAngle[i]) * spread - lumiH * 0.18 * easeOut;
      float pz = particleDepth[i] * easeOut;
      float sparkleSize = particleSize[i] * (1.15 - progress * 0.55);

      pushMatrix();
      translate(px, py, pz);
      rotateZ(t * 0.070 + particlePhase[i]);

      stroke(255, 212, 244, sparkleAlpha);

      strokeWeight(max(1.2, sparkleSize * 0.10));
      line(-sparkleSize * 0.55, 0, sparkleSize * 0.55, 0);
      line(0, -sparkleSize * 0.55, 0, sparkleSize * 0.55);
      line(-sparkleSize * 0.34, -sparkleSize * 0.34, sparkleSize * 0.34, sparkleSize * 0.34);
      line(-sparkleSize * 0.34, sparkleSize * 0.34, sparkleSize * 0.34, -sparkleSize * 0.34);

      popMatrix();
    }

    noStroke();
  }
}
