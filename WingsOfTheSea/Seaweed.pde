// Mermaid-stage swaying obstacle with drifting movement and collision detection.
class Seaweed {

  int slotIndex;

  PImage seaweedTexture;

  float x, y, z;
  float baseX, baseY;

  float farZ  = -1700;
  float nearZ = 260;

  float speedZ;
  float alpha = 255;
  float solidTextureAlpha = 0.92;
  float softTextureAlpha = 0.68;

  boolean exiting = false;

  float wavePhase;
  float waveSpeed;
  float currentPhase;
  float currentStrength;
  float plantLean;
  float glowSeed;

  float seaweedHeight;
  float stalkRadius;

  int leafCount;
  float[] leafAt     = new float[14];
  float[] leafSide   = new float[14];
  float[] leafLength = new float[14];
  float[] leafWidth  = new float[14];
  float[] leafAngle  = new float[14];
  float[] leafPhase  = new float[14];
  float[] leafCurve  = new float[14];
  float[] leafCurl   = new float[14];
  float[] leafDepth  = new float[14];
  float[] leafTint   = new float[14];

  Seaweed(PImage seaweedTexture, int slotIndex) {
    this.seaweedTexture = seaweedTexture;
    this.slotIndex = slotIndex;

    reset(true);
  }

  void reset(boolean spreadAtStart) {
    exiting = false;
    alpha = 255;

    int laneIndex = (int)random(5);

    float leftLimit  = width * 0.30;
    float rightLimit = width * 0.70;

    baseX = map(laneIndex, 0, 4, leftLimit, rightLimit);
    baseX += random(-width * 0.028, width * 0.028);

    baseY = random(height * 0.70, height * 0.78);

    if (spreadAtStart) {
      z = farZ + slotIndex * 760 + random(-120, 120);
    } else {
      z = farZ - random(0, 450);
    }

    if (z > -500) {
      z = -500;
    }

    speedZ = random(3.0, 4.2);

    wavePhase = random(TWO_PI);
    currentPhase = random(TWO_PI);
    waveSpeed = random(0.022, 0.038);
    currentStrength = random(0.75, 1.15);
    plantLean = random(-0.16, 0.16);
    glowSeed = random(TWO_PI);

    seaweedHeight = random(height * 0.38, height * 0.52);
    stalkRadius = random(height * 0.0055, height * 0.0090);

    setupLeaves();

    x = baseX;
    y = baseY;
  }

  // Random leaf properties are generated once per reset so the plant shape stays consistent.
  void setupLeaves() {
    leafCount = (int)random(9, 13);

    float startingSide = random(1) < 0.5 ? -1 : 1;

    for (int i = 0; i < leafCount; i++) {
      float t = map(i, 0, leafCount - 1, 0.16, 0.93);
      t += random(-0.030, 0.030);
      t = constrain(t, 0.12, 0.96);

      float side = startingSide;

      if (i % 2 == 1) {
        side *= -1;
      }

      leafAt[i] = t;
      leafSide[i] = side;

      leafLength[i] = seaweedHeight * random(0.16, 0.30) * (1.12 - t * 0.22);
      leafWidth[i]  = seaweedHeight * random(0.024, 0.050) * (1.10 - t * 0.30);

      leafAngle[i] = radians(random(17, 40)) * side;
      leafPhase[i] = random(TWO_PI);
      leafCurve[i] = random(0.22, 0.58) * side;
      leafCurl[i] = random(1.0, 5.0);

      leafDepth[i] = random(-6, 8);
      leafTint[i] = random(1);
    }
  }

  void update() {
    wavePhase += waveSpeed;
    currentPhase += waveSpeed * 0.43;

    if (!exiting) {
      z += speedZ;

      x = baseX + sin(currentPhase + slotIndex * 0.73) * width * 0.0025;

      if (z > 140) {
        startExit();
      }

    } else {
      z += speedZ * 1.5;
      alpha = lerp(alpha, 0, 0.055);

      if (alpha < 6 || z > nearZ + 130) {
        reset(false);
      }
    }
  }

  void startExit() {
    exiting = true;
  }

  void forceExit() {
    startExit();
    alpha = 150;
  }

  void draw() {
    noStroke();

    drawLeaves(false);
    drawRootBase();
    drawSegmentedStalk();
    drawStalkTip();
    drawStalkVein();
    drawLeaves(true);

    noTint();
    noStroke();
  }

  void drawRootBase() {
    pushMatrix();

    translate(x, y, z);
    rotateZ(sin(wavePhase * 0.45 + glowSeed) * 0.025);

    tint(225, 85, 205, alpha * solidTextureAlpha);
    drawTexturedTaperedCylinder(
      stalkRadius * 4.4,
      stalkRadius * 2.3,
      height * 0.038,
      seaweedTexture
    );

    popMatrix();
  }

  void drawSegmentedStalk() {
    int segments = 14;
    float segmentH = seaweedHeight / segments;

    for (int i = 0; i < segments; i++) {
      float t = (i + 0.5) / segments;

      float centerX = x + getCurveOffset(t);
      float centerY = y - t * seaweedHeight;

      float radiusBottom = lerp(stalkRadius * 1.55, stalkRadius * 0.58, t);
      float radiusTop    = lerp(stalkRadius * 1.35, stalkRadius * 0.40, t);

      float lowerT = constrain(t - 0.035, 0, 1);
      float upperT = constrain(t + 0.035, 0, 1);
      float dx = getCurveOffset(upperT) - getCurveOffset(lowerT);
      float dy = -seaweedHeight * (upperT - lowerT);
      float tangentAngle = atan2(dx, -dy);

      pushMatrix();

      translate(centerX, centerY, z);
      rotateZ(tangentAngle + plantLean * t * 0.22);

      tint(225, 85, 205, alpha * solidTextureAlpha);

      drawTexturedTaperedCylinder(
        radiusBottom,
        radiusTop,
        segmentH * 1.16,
        seaweedTexture
      );

      popMatrix();
    }
  }

  void drawStalkTip() {
    float tipH = seaweedHeight * 0.075;
    float t = 0.995;

    float anchorX = x + getCurveOffset(t);
    float anchorY = y - t * seaweedHeight;

    float lowerT = 0.94;
    float upperT = 1.0;
    float dx = getCurveOffset(upperT) - getCurveOffset(lowerT);
    float dy = -seaweedHeight * (upperT - lowerT);
    float tangentAngle = atan2(dx, -dy) + plantLean * 0.22;

    float centerX = anchorX + sin(tangentAngle) * tipH * 0.5;
    float centerY = anchorY - cos(tangentAngle) * tipH * 0.5;

    pushMatrix();

    translate(centerX, centerY, z);
    rotateZ(tangentAngle);

    tint(225, 85, 205, alpha * solidTextureAlpha);

    drawTexturedTaperedCylinder(
      stalkRadius * 0.50,
      stalkRadius * 0.05,
      tipH,
      seaweedTexture
    );

    popMatrix();
  }

  void drawStalkVein() {
    stroke(145, 235, 205, alpha * 0.15);
    strokeWeight(max(1, stalkRadius * 0.16));
    noFill();

    beginShape();
    for (int i = 0; i <= 18; i++) {
      float t = (float) i / 18.0;
      vertex(x + getCurveOffset(t), y - t * seaweedHeight, z + stalkRadius * 0.55);
    }
    endShape();

    noStroke();
  }

  void drawLeaves(boolean frontLayer) {
    for (int i = 0; i < leafCount; i++) {
      boolean isFront = leafDepth[i] >= 0;

      if (isFront != frontLayer) {
        continue;
      }

      float t = leafAt[i];

      float attachX = x + getCurveOffset(t);
      float attachY = y - t * seaweedHeight;


      float delayedPhase = wavePhase + t * 3.10 + leafPhase[i];
      float leafSway = sin(delayedPhase) * (0.075 + 0.090 * t);
      leafSway += sin(wavePhase * 0.37 + leafPhase[i]) * 0.040;

      float softLift = sin(wavePhase * 0.63 + leafPhase[i]) * height * 0.0045 * t;

      pushMatrix();

      translate(attachX, attachY + softLift, z + leafDepth[i]);
      rotateZ(leafAngle[i] + leafSway + plantLean * t * 0.24);

      tint(255, alpha * softTextureAlpha);

      drawTexturedLeaf(
        leafWidth[i],
        leafLength[i],
        leafCurve[i],
        leafCurl[i],
        seaweedTexture
      );

      popMatrix();
    }
  }

  float getCurveOffset(float t) {
    float rootLock = pow(t, 1.35);

    float mainWave = sin(wavePhase * 0.86 + t * 2.65 + glowSeed) * height * 0.018;
    float slowDrift = sin(currentPhase + t * 1.45 + slotIndex * 0.41) * height * 0.010;
    float tinyRipple = sin(wavePhase * 1.90 + t * 6.20) * height * 0.0035;

    return (mainWave + slowDrift + tinyRipple + plantLean * height * 0.050 * t) * rootLock * currentStrength;
  }

  // Uses a compact screen-space hit area instead of checking every leaf polygon.
  boolean hitsRosa(Rosa rosa, float t) {
    if (z < -90 || z > 125) {
      return false;
    }

    if (alpha < 80) {
      return false;
    }

    float hitCenterY = y - seaweedHeight * 0.45;

    float hitW = rosa.h * 0.16 + height * 0.040;
    float hitH = rosa.h * 0.30 + seaweedHeight * 0.33;

    float seaweedSX = screenX(x, hitCenterY, z);
    float seaweedSY = screenY(x, hitCenterY, z);

    float rosaSX = rosa.getScreenX(t);
    float rosaSY = rosa.getScreenY(t);

    return abs(seaweedSX - rosaSX) < hitW &&
           abs(seaweedSY - rosaSY) < hitH;
  }

  // Texture-mapped geometry used only for mermaid-stage seaweed leaves.
  void drawTexturedLeaf(float leafW, float leafH, float curveAmount, float curlAmount, PImage tex) {
    int parts = 12;

    if (tex != null) {
      textureMode(NORMAL);

      beginShape(QUAD_STRIP);
      texture(tex);

      for (int i = 0; i <= parts; i++) {
        float t = (float) i / parts;

        float taper = sin(PI * t);
        float edgePulse = 1.0 + 0.075 * sin(t * TWO_PI * 2.0);
        float halfW = leafW * taper * (1.0 - t * 0.24) * edgePulse;

        float curveX = sin(PI * t) * leafW * curveAmount;
        float edgeRipple = sin(t * TWO_PI * 1.5) * leafW * 0.045 * taper;
        float curveZ = sin(PI * t) * curlAmount;

        float py = -t * leafH;

        vertex(curveX - halfW + edgeRipple, py, curveZ, 0, t);
        vertex(curveX + halfW - edgeRipple, py, curveZ, 1, t);
      }

      endShape();

    } else {
      fill(82, 190, 170, alpha * 0.55);

      beginShape(QUAD_STRIP);

      for (int i = 0; i <= parts; i++) {
        float t = (float) i / parts;

        float taper = sin(PI * t);
        float edgePulse = 1.0 + 0.075 * sin(t * TWO_PI * 2.0);
        float halfW = leafW * taper * (1.0 - t * 0.24) * edgePulse;

        float curveX = sin(PI * t) * leafW * curveAmount;
        float edgeRipple = sin(t * TWO_PI * 1.5) * leafW * 0.045 * taper;
        float curveZ = sin(PI * t) * curlAmount;

        float py = -t * leafH;

        vertex(curveX - halfW + edgeRipple, py, curveZ);
        vertex(curveX + halfW - edgeRipple, py, curveZ);
      }

      endShape();
    }

    stroke(175, 240, 210, alpha * 0.10);
    strokeWeight(max(1, leafW * 0.030));
    noFill();

    beginShape();
    for (int i = 0; i <= parts; i++) {
      float t = (float) i / parts;
      float curveX = sin(PI * t) * leafW * curveAmount;
      float curveZ = sin(PI * t) * curlAmount + 0.15;
      vertex(curveX, -t * leafH, curveZ);
    }
    endShape();

    noStroke();
  }

  // Texture-mapped geometry used only for mermaid-stage seaweed stems.
  void drawTexturedTaperedCylinder(float bottomRadius, float topRadius, float cylinderHeight, PImage tex) {
    int sides = 22;

    if (tex != null) {
      textureMode(NORMAL);

      beginShape(QUAD_STRIP);
      texture(tex);

      for (int i = 0; i <= sides; i++) {
        float a = TWO_PI * i / sides;

        float wobble = 1.0 + 0.055 * sin(a * 3.0 + glowSeed);

        float bottomX = cos(a) * bottomRadius * wobble;
        float bottomZ = sin(a) * bottomRadius * (0.86 + 0.04 * sin(a + glowSeed));

        float topX = cos(a) * topRadius * wobble;
        float topZ = sin(a) * topRadius * (0.86 + 0.04 * sin(a + glowSeed));

        float u = (float) i / sides;

        vertex(bottomX,  cylinderHeight / 2, bottomZ, u, 1);
        vertex(topX,    -cylinderHeight / 2, topZ,    u, 0);
      }

      endShape();

    } else {
      fill(70, 180, 160, alpha * 0.70);

      beginShape(QUAD_STRIP);

      for (int i = 0; i <= sides; i++) {
        float a = TWO_PI * i / sides;
        float wobble = 1.0 + 0.055 * sin(a * 3.0 + glowSeed);

        float bottomX = cos(a) * bottomRadius * wobble;
        float bottomZ = sin(a) * bottomRadius * (0.86 + 0.04 * sin(a + glowSeed));

        float topX = cos(a) * topRadius * wobble;
        float topZ = sin(a) * topRadius * (0.86 + 0.04 * sin(a + glowSeed));

        vertex(bottomX,  cylinderHeight / 2, bottomZ);
        vertex(topX,    -cylinderHeight / 2, topZ);
      }

      endShape();
    }
  }
}
