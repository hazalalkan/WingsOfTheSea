// Single collectible object, including movement, 3D drawing, collision, and collection feedback.
class Collectible {

  PImage normalImg;
  PImage goldenImg;

  int slotIndex;

  float x, y, z;
  float baseX, baseY;

  float farZ  = -1550;
  float nearZ = 260;

  float speedZ;
  float alpha = 255;

  float size;
  float phase;
  float spinSpeed;
  float driftAmpX;
  float driftSpeedX;

  boolean golden = false;
  boolean exiting = false;
  boolean collected = false;

  final int COLLECT_SPARKLES = 0;
  final int COLLECT_BUBBLES = 1;
  int collectEffectType = COLLECT_SPARKLES;

  float collectTimer = 0;
  float collectDuration = 44;

  final int COLLECT_PARTICLE_COUNT = 22;
  float[] particleAngle = new float[COLLECT_PARTICLE_COUNT];
  float[] particleDistance = new float[COLLECT_PARTICLE_COUNT];
  float[] particleSize = new float[COLLECT_PARTICLE_COUNT];
  float[] particleDepth = new float[COLLECT_PARTICLE_COUNT];
  float[] particleSpeed = new float[COLLECT_PARTICLE_COUNT];
  float[] particlePhase = new float[COLLECT_PARTICLE_COUNT];

  Collectible(PImage normalImg, PImage goldenImg, int slotIndex) {
    this.normalImg = normalImg;
    this.goldenImg = goldenImg;
    this.slotIndex = slotIndex;

    reset(true);
  }

  void setImages(PImage normalImg, PImage goldenImg) {
    this.normalImg = normalImg;
    this.goldenImg = goldenImg;
  }

  void reset(boolean spreadAtStart) {
    exiting = false;
    collected = false;
    collectTimer = 0;
    alpha = 255;

    golden = random(1) < 0.20;

    int laneIndex = (int) random(5);

    float leftLimit  = width * 0.30;
    float rightLimit = width * 0.70;

    baseX = map(laneIndex, 0, 4, leftLimit, rightLimit);
    baseX += random(-width * 0.025, width * 0.025);

    baseY = random(height * 0.43, height * 0.67);

    if (spreadAtStart) {
      z = farZ + slotIndex * 420 + random(-120, 120);
    } else {
      z = farZ - random(0, 520);
    }

    if (z > -420) {
      z = -420;
    }

    speedZ = random(3.6, 5.2);

    size = height * 0.105;

    phase = random(TWO_PI);
    spinSpeed = random(0.030, 0.055);

    driftAmpX = random(width * 0.010, width * 0.030);
    driftSpeedX = random(0.025, 0.045);

    x = baseX;
    y = baseY;
  }

  void update() {
    phase += spinSpeed;

    if (collected) {
      updateCollectedEffect();
      return;
    }

    if (!exiting) {
      z += speedZ;

      x = baseX + sin(phase * driftSpeedX * 35.0) * driftAmpX;
      y = baseY + sin(phase * 1.4) * height * 0.010;

      if (z > 135) {
        startExit();
      }

    } else {
      z += speedZ * 1.35;
      alpha = lerp(alpha, 0, 0.075);

      if (alpha < 6 || z > nearZ + 130) {
        reset(false);
      }
    }
  }

  void updateCollectedEffect() {
    collectTimer++;

    z += speedZ * 0.25;

    float progress = constrain(collectTimer / collectDuration, 0, 1);
    alpha = 255 * (1.0 - progress);

    if (collectTimer >= collectDuration) {
      reset(false);
    }
  }

  void startExit() {
    if (collected) {
      return;
    }

    exiting = true;
  }

  void collect(boolean pearlMode) {
    if (collected || exiting) {
      return;
    }

    collected = true;
    exiting = false;
    collectTimer = 0;
    alpha = 255;
    collectEffectType = pearlMode ? COLLECT_BUBBLES : COLLECT_SPARKLES;

    setupCollectParticles();
  }

  void setupCollectParticles() {
    for (int i = 0; i < COLLECT_PARTICLE_COUNT; i++) {
      particleAngle[i] = random(TWO_PI);
      particleDistance[i] = random(size * 0.18, size * 0.82);
      particleSize[i] = random(size * 0.080, size * 0.175);
      particleDepth[i] = random(-size * 0.12, size * 0.12);
      particleSpeed[i] = random(0.75, 1.35);
      particlePhase[i] = random(TWO_PI);
    }
  }

  boolean isGolden() {
    return golden;
  }

  boolean hitsRosa(Rosa rosa, float t) {
    if (exiting || collected) {
      return false;
    }

    if (z < -90 || z > 125) {
      return false;
    }

    if (alpha < 80) {
      return false;
    }

    float collectibleSX = screenX(x, y, z);
    float collectibleSY = screenY(x, y, z);

    float rosaSX = rosa.getScreenX(t);
    float rosaSY = rosa.getScreenY(t);

    float hitW = rosa.h * 0.19 + size * 0.42;
    float hitH = rosa.h * 0.20 + size * 0.42;

    return abs(collectibleSX - rosaSX) < hitW &&
           abs(collectibleSY - rosaSY) < hitH;
  }

  void draw() {
    if (collected) {
      drawCollectedEffect();
      return;
    }

    PImage img = golden ? goldenImg : normalImg;

    if (img == null) {
      drawFallbackCollectible();
      return;
    }

    float imgW = size * ((float) img.width / img.height);
    float imgH = size;

    float pulse = 1.0 + sin(phase * 4.0) * 0.06;

    imageMode(CENTER);

    pushMatrix();

    translate(x, y, z);
    rotateZ(sin(phase * 2.0) * 0.16);

    tint(255, alpha);
    image(img, 0, 0, imgW * pulse, imgH * pulse);
    noTint();

    popMatrix();
  }

  void drawCollectedEffect() {
    float progress = constrain(collectTimer / collectDuration, 0, 1);
    float easeOut = 1.0 - pow(1.0 - progress, 2.0);
    float fade = 1.0 - progress;

    pushMatrix();

    translate(x, y, z);

    drawCollectedItemShrink(progress);

    if (collectEffectType == COLLECT_BUBBLES) {
      drawBubbleBurst(progress, easeOut, fade);
    } else {
      drawSparkleBurst(progress, easeOut, fade);
    }

    popMatrix();
  }

  // After collection, the object stays briefly visible and shrinks/fades for feedback.
  void drawCollectedItemShrink(float progress) {
    PImage img = golden ? goldenImg : normalImg;

    if (img == null || progress > 0.70) {
      return;
    }

    float shrink = 1.0 - progress * 0.70;
    float itemAlpha = 255 * (1.0 - progress / 0.70);
    float imgW = size * ((float) img.width / img.height);
    float imgH = size;

    imageMode(CENTER);
    tint(255, itemAlpha);
    image(img, 0, 0, imgW * shrink, imgH * shrink);
    noTint();
  }

  void drawSparkleBurst(float progress, float easeOut, float fade) {
    noFill();

    for (int i = 0; i < COLLECT_PARTICLE_COUNT; i++) {
      float localEase = constrain(easeOut * particleSpeed[i], 0, 1.25);
      float sparkleAlpha = 235 * fade * (0.70 + 0.30 * sin(phase * 8.0 + particlePhase[i]));
      float spread = particleDistance[i] * (0.35 + localEase * 1.25);
      float px = cos(particleAngle[i]) * spread;
      float py = sin(particleAngle[i]) * spread - size * 0.18 * easeOut;
      float pz = particleDepth[i] * easeOut;
      float sparkleSize = particleSize[i] * (1.15 - progress * 0.55);

      pushMatrix();
      translate(px, py, pz);
      rotateZ(phase * 2.0 + particlePhase[i]);

      if (golden) {
        stroke(255, 228, 105, sparkleAlpha);
      } else {
        stroke(255, 212, 244, sparkleAlpha);
      }

      strokeWeight(max(1.2, sparkleSize * 0.10));
      line(-sparkleSize * 0.55, 0, sparkleSize * 0.55, 0);
      line(0, -sparkleSize * 0.55, 0, sparkleSize * 0.55);
      line(-sparkleSize * 0.34, -sparkleSize * 0.34, sparkleSize * 0.34, sparkleSize * 0.34);
      line(-sparkleSize * 0.34, sparkleSize * 0.34, sparkleSize * 0.34, -sparkleSize * 0.34);

      popMatrix();
    }

    noStroke();
  }

  void drawBubbleBurst(float progress, float easeOut, float fade) {
    for (int i = 0; i < COLLECT_PARTICLE_COUNT; i++) {
      float localEase = constrain(easeOut * particleSpeed[i], 0, 1.15);
      float bubbleAlpha = 210 * fade;
      float spread = particleDistance[i] * localEase * 0.78;
      float px = cos(particleAngle[i]) * spread * 0.62;
      float py = sin(particleAngle[i]) * spread * 0.26 - size * 0.72 * localEase;
      float pz = particleDepth[i] * easeOut;
      float bubbleSize = particleSize[i] * (0.45 + progress * 0.75);

      pushMatrix();
      translate(px, py, pz);

      noFill();
      strokeWeight(max(1.1, bubbleSize * 0.060));

      if (golden) {
        stroke(255, 230, 128, bubbleAlpha);
      } else {
        stroke(190, 235, 255, bubbleAlpha);
      }

      ellipse(0, 0, bubbleSize, bubbleSize);

      noStroke();
      if (golden) {
        fill(255, 245, 180, bubbleAlpha * 0.65);
      } else {
        fill(235, 255, 255, bubbleAlpha * 0.65);
      }
      ellipse(-bubbleSize * 0.22, -bubbleSize * 0.22, bubbleSize * 0.20, bubbleSize * 0.20);

      popMatrix();
    }

    noStroke();
  }

  void drawFallbackCollectible() {
    float pulse = 1.0 + sin(phase * 4.0) * 0.08;

    pushMatrix();

    translate(x, y, z);

    noStroke();

    if (golden) {
      fill(255, 220, 80, alpha);
    } else {
      fill(255, 180, 240, alpha);
    }

    ellipse(0, 0, size * pulse, size * pulse);

    popMatrix();
  }
}
