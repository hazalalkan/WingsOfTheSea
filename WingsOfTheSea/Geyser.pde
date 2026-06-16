// Mermaid-stage erupting obstacle with crater drawing, eruption animation, and collision timing.
class Geyser {

  int slotIndex;

  PImage craterTexture;
  PImage eruptionTexture;

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

  float eruptionPhase;
  float eruptionSpeed;

  float pulsePhase;
  float pulseSpeed;

  float craterRadius;

  int rimSides = 40;
  float[] rimNoise = new float[rimSides];
  float[] rimLift  = new float[rimSides];

  int plumeCount = 5;

  float[] plumeOffsetX = new float[plumeCount];
  float[] plumeOffsetZ = new float[plumeCount];
  float[] plumePhase   = new float[plumeCount];
  float[] plumeScale   = new float[plumeCount];

  int bubbleCount = 18;

  float[] bubbleAngle  = new float[bubbleCount];
  float[] bubbleRadius = new float[bubbleCount];
  float[] bubbleHeight = new float[bubbleCount];
  float[] bubblePhase  = new float[bubbleCount];
  float[] bubbleSize   = new float[bubbleCount];

  Geyser(PImage craterTexture, PImage eruptionTexture, int slotIndex) {
    this.craterTexture = craterTexture;
    this.eruptionTexture = eruptionTexture;
    this.slotIndex = slotIndex;

    reset(true);
  }

  void reset(boolean spreadAtStart) {
    exiting = false;
    alpha = 255;

    chooseLanePosition();
    resetDepth(spreadAtStart);
    resetAnimationValues();
    resetOrganicShape();

    x = baseX;
    y = baseY;
  }

  void chooseLanePosition() {
    int laneIndex = (int) random(5);

    float leftLimit  = width * 0.30;
    float rightLimit = width * 0.70;

    baseX = map(laneIndex, 0, 4, leftLimit, rightLimit);
    baseX += random(-width * 0.025, width * 0.025);

    baseY = random(height * 0.70, height * 0.77);
  }

  void resetDepth(boolean spreadAtStart) {
    if (spreadAtStart) {
      z = farZ + slotIndex * 760 + random(-120, 120);
    } else {
      z = farZ - random(0, 450);
    }

    if (z > -500) {
      z = -500;
    }
  }

  void resetAnimationValues() {
    speedZ = random(3.0, 4.4);

    wavePhase = random(TWO_PI);
    waveSpeed = random(0.025, 0.045);

    eruptionPhase = random(TWO_PI);
    eruptionSpeed = random(0.020, 0.035);

    pulsePhase = random(TWO_PI);
    pulseSpeed = random(0.045, 0.075);
  }

  // Randomized arrays are generated once per reset so the geyser looks organic but stable while moving.
  void resetOrganicShape() {
    craterRadius = random(height * 0.062, height * 0.086);

    buildOrganicCraterShape();
    buildOrganicPlumeShape();
    buildOrganicBubbleField();
  }

  void buildOrganicCraterShape() {
    for (int i = 0; i < rimSides; i++) {
      rimNoise[i] = random(0.80, 1.22);
      rimLift[i]  = random(-0.10, 0.14);
    }
  }

  void buildOrganicPlumeShape() {
    for (int i = 0; i < plumeCount; i++) {
      plumeOffsetX[i] = random(-craterRadius * 0.16, craterRadius * 0.16);
      plumeOffsetZ[i] = random(-craterRadius * 0.10, craterRadius * 0.10);
      plumePhase[i]   = random(TWO_PI);
      plumeScale[i]   = random(0.82, 1.18);
    }
  }

  void buildOrganicBubbleField() {
    for (int i = 0; i < bubbleCount; i++) {
      bubbleAngle[i]  = random(TWO_PI);
      bubbleRadius[i] = random(craterRadius * 0.10, craterRadius * 0.78);
      bubbleHeight[i] = random(0.0, 1.0);
      bubblePhase[i]  = random(TWO_PI);
      bubbleSize[i]   = random(craterRadius * 0.045, craterRadius * 0.120);
    }
  }

  void update() {
    updateAnimationPhases();

    if (!exiting) {
      updateApproachMovement();
    } else {
      updateExitMovement();
    }
  }

  void updateAnimationPhases() {
    wavePhase += waveSpeed;
    eruptionPhase += eruptionSpeed;
    pulsePhase += pulseSpeed;
  }

  void updateApproachMovement() {
    z += speedZ;

    float slowCurrent = sin(wavePhase * 0.72) * width * 0.006;
    float microDrift  = sin(wavePhase * 1.63 + slotIndex) * width * 0.0025;
    x = baseX + slowCurrent + microDrift;

    if (z > 140) {
      startExit();
    }
  }

  void updateExitMovement() {
    z += speedZ * 1.5;
    alpha = lerp(alpha, 0, 0.055);

    if (alpha < 6 || z > nearZ + 130) {
      reset(false);
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
    drawCrater();
    drawEruption();
  }

  void drawCrater() {
    drawCraterShadow();
    drawCraterBody();
    drawCraterOpening();
    drawMineralGlowDots();
  }

  void drawCraterShadow() {
    pushMatrix();

    translate(x, y + craterRadius * 0.21, z - craterRadius * 0.02);
    rotateX(HALF_PI);

    noStroke();
    fill(18, 18, 68, alpha * 0.19);
    ellipse(0, 0, craterRadius * 2.25, craterRadius * 0.85);

    popMatrix();
  }

  void drawCraterBody() {
    noStroke();

    pushMatrix();

    translate(x, y + craterRadius * 0.09, z);

    scale(1.06, 0.42, 0.56);

    tint(165, 105, 235, alpha * solidTextureAlpha);
    drawTexturedIrregularCylinder(craterRadius, craterRadius * 1.08, craterTexture);
    noTint();

    popMatrix();
  }

  void drawCraterOpening() {
    pushMatrix();

    translate(x, y - craterRadius * 0.18, z);
    rotateX(HALF_PI);

    noStroke();

    drawDarkCraterMouth();
    drawInnerCraterGlow();
    drawOuterSteamHalo();

    popMatrix();
  }

  void drawDarkCraterMouth() {
    fill(10, 8, 45, alpha * 0.84);

    beginShape();

    for (int i = 0; i < rimSides; i++) {
      float a = TWO_PI * i / rimSides;
      float noisyR = rimNoise[i] * 0.84;

      float px = cos(a) * craterRadius * 0.82 * noisyR;
      float py = sin(a) * craterRadius * 0.46 * noisyR;

      vertex(px, py);
    }

    endShape(CLOSE);
  }

  void drawInnerCraterGlow() {
    float power = getEruptionPower();
    float breath = getCraterBreath();

    fill(255, 168, 62, alpha * (0.12 + power * 0.26 + breath * 0.10));

    beginShape();

    for (int i = 0; i < rimSides; i++) {
      float a = TWO_PI * i / rimSides;
      float noisyR = rimNoise[i] * 0.55;

      float px = cos(a) * craterRadius * 0.62 * noisyR;
      float py = sin(a) * craterRadius * 0.32 * noisyR;

      vertex(px, py);
    }

    endShape(CLOSE);

    fill(145, 235, 255, alpha * (0.04 + power * 0.08));
    ellipse(0, 0, craterRadius * 0.46, craterRadius * 0.22);
  }

  void drawOuterSteamHalo() {
    float power = getEruptionPower();
    float breath = getCraterBreath();

    fill(125, 230, 255, alpha * (0.035 + power * 0.075 + breath * 0.045));
    ellipse(0, 0, craterRadius * 1.85, craterRadius * 0.82);

    fill(255, 210, 110, alpha * (0.025 + power * 0.060));
    ellipse(0, 0, craterRadius * 1.22, craterRadius * 0.52);
  }

  void drawMineralGlowDots() {
    pushMatrix();
    translate(x, y - craterRadius * 0.10, z);

    noStroke();

    for (int i = 0; i < rimSides; i += 5) {
      float a = TWO_PI * i / rimSides;
      float twinkle = 0.55 + 0.45 * sin(pulsePhase * 1.7 + i * 0.8);

      float px = cos(a) * craterRadius * 0.86 * rimNoise[i];
      float py = sin(a) * craterRadius * 0.18;
      float pz = sin(a) * craterRadius * 0.45 * rimNoise[i];

      pushMatrix();
      translate(px, py, pz);
      fill(150, 235, 255, alpha * 0.16 * twinkle);
      ellipse(0, 0, craterRadius * 0.070, craterRadius * 0.045);
      popMatrix();
    }

    popMatrix();
  }

  // Builds the eruption from glow, steam, plume layers, and bubbles.
  void drawEruption() {
    float power = getEruptionPower();

    if (power <= 0.08 || exiting) {
      return;
    }

    float flicker = getEruptionFlicker();

    float basePlumeH = height * (0.19 + 0.32 * power) * flicker;
    float basePlumeR = craterRadius * (0.30 + 0.38 * power);

    drawPreheatedWaterGlow(power);
    drawSteamColumnBehind(power, basePlumeH, basePlumeR);

    for (int i = 0; i < plumeCount; i++) {
      drawSinglePlumeLayer(i, power, basePlumeH, basePlumeR);
    }

    drawSoftSteamPuffs(power, basePlumeH);
    drawRisingBubbles(power, basePlumeH);
  }

  float getEruptionFlicker() {
    float f1 = sin(eruptionPhase * 5.4) * 0.065;
    float f2 = sin(eruptionPhase * 11.7 + slotIndex) * 0.035;
    return 0.91 + f1 + f2;
  }

  void drawPreheatedWaterGlow(float power) {
    pushMatrix();

    translate(x, y - craterRadius * 0.25, z);

    noStroke();
    float breath = getCraterBreath();

    fill(125, 230, 255, alpha * (0.035 + power * 0.055 + breath * 0.025));
    ellipse(0, 0, craterRadius * (1.30 + power * 0.35), craterRadius * (0.48 + power * 0.16));

    fill(255, 175, 70, alpha * (0.040 + power * 0.080));
    ellipse(0, 0, craterRadius * (0.88 + power * 0.25), craterRadius * (0.30 + power * 0.10));

    popMatrix();
  }

  void drawSteamColumnBehind(float power, float basePlumeH, float basePlumeR) {
    pushMatrix();
    translate(x, y - craterRadius * 0.32, z - craterRadius * 0.06);

    noStroke();

    for (int i = 0; i < 7; i++) {
      float t = (float) i / 6.0;
      float phase = eruptionPhase * (1.3 + t * 0.6) + i * 0.92;

      float px = sin(phase) * basePlumeR * (0.30 + t * 0.80);
      float py = -basePlumeH * t * (0.32 + 0.35 * power);
      float s  = basePlumeR * (1.05 + t * 1.10) * (0.80 + power * 0.45);

      float localAlpha = alpha * power * softTextureAlpha * (0.120 + 0.080 * (1.0 - t));

      if (i % 2 == 0) {
        fill(135, 230, 255, localAlpha);
      } else {
        fill(255, 218, 150, localAlpha * 0.85);
      }

      ellipse(px, py, s, s * 0.62);
    }

    popMatrix();
  }

  void drawSinglePlumeLayer(int i, float power, float basePlumeH, float basePlumeR) {
    float layer = (float) i / max(1, plumeCount - 1);

    float localPhase = eruptionPhase + plumePhase[i];

    float swayX = sin(localPhase * 1.85) * craterRadius * 0.11 * (1.0 + layer * 1.5);
    float swayZ = cos(localPhase * 1.55) * craterRadius * 0.07 * (1.0 + layer);

    float plumeH = basePlumeH * plumeScale[i] * (1.00 - layer * 0.15 + sin(localPhase * 2.4) * 0.045);
    float plumeR = basePlumeR * (1.03 - layer * 0.14 + sin(localPhase * 1.8) * 0.035);

    float layerAlpha = min(alpha, 46 + 112 * power) * (1.0 - layer * 0.18);

    pushMatrix();

    translate(
      x + plumeOffsetX[i] + swayX,
      y - craterRadius * 0.22,
      z + plumeOffsetZ[i] + swayZ
    );

    rotateZ(sin(localPhase) * 0.085);
    rotateX(cos(localPhase * 0.7) * 0.035);

    applyPlumeTint(layerAlpha);
    drawTexturedCone(plumeR, plumeH, eruptionTexture);
    noTint();

    popMatrix();
  }

  void applyPlumeTint(float layerAlpha) {
  tint(255, layerAlpha * softTextureAlpha);
  }

  void drawSoftSteamPuffs(float power, float basePlumeH) {
    pushMatrix();

    translate(x, y - craterRadius * 0.58, z);

    noStroke();

    for (int i = 0; i < 9; i++) {
      float t = (float) i / 8.0;
      float a = eruptionPhase * (1.6 + t * 1.1) + i * TWO_PI / 4.5;

      float px = cos(a) * craterRadius * (0.18 + 0.52 * t);
      float py = -basePlumeH * (0.06 + 0.50 * t) - sin(a * 1.2) * height * 0.006;
      float s  = craterRadius * (0.34 + 0.22 * i) * (0.85 + power * 0.36);

      float puffAlpha = alpha * power * softTextureAlpha * (0.180 - t * 0.090);

      if (i % 3 == 0) {
        fill(130, 235, 255, puffAlpha);
      } else if (i % 3 == 1) {
        fill(255, 226, 165, puffAlpha * 0.76);
      } else {
        fill(235, 245, 255, puffAlpha * 0.66);
      }

      ellipse(px, py, s, s * 0.72);
    }

    popMatrix();
  }

  void drawRisingBubbles(float power, float basePlumeH) {
    pushMatrix();
    translate(x, y - craterRadius * 0.20, z + craterRadius * 0.02);

    noStroke();

    for (int i = 0; i < bubbleCount; i++) {
      float travel = (bubbleHeight[i] + eruptionPhase * 0.075 + i * 0.017) % 1.0;
      float spiral = bubbleAngle[i] + eruptionPhase * (0.65 + i * 0.015);

      float px = cos(spiral) * bubbleRadius[i] * (0.55 + travel * 0.85);
      float py = -basePlumeH * travel * (0.78 + power * 0.22);
      float pz = sin(spiral) * bubbleRadius[i] * 0.48;

      float fade = sin(travel * PI);
      float s = bubbleSize[i] * (0.70 + travel * 0.85);

      pushMatrix();
      translate(px, py, pz);

      fill(165, 238, 255, alpha * power * softTextureAlpha * 0.22 * fade);
      ellipse(0, 0, s, s);

      fill(255, 255, 255, alpha * power * softTextureAlpha * 0.11 * fade);
      ellipse(-s * 0.16, -s * 0.18, s * 0.28, s * 0.22);

      popMatrix();
    }

    popMatrix();
  }

  float getCraterBreath() {
    return 0.5 + 0.5 * sin(pulsePhase);
  }

  float getEruptionPower() {
    float raw = sin(eruptionPhase);

    if (raw < 0) {
      return 0;
    }

    float p = raw * raw;
    return constrain(p, 0, 1);
  }

  boolean isDangerous() {
    return getEruptionPower() > 0.35;
  }

  // Uses a simplified screen-space danger area instead of matching every decorative plume shape.
  boolean hitsRosa(Rosa rosa, float t) {
    if (z < -90 || z > 125) {
      return false;
    }

    if (alpha < 80) {
      return false;
    }

    if (!isDangerous()) {
      return false;
    }

    float plumeH = height * (0.22 + 0.34 * getEruptionPower());

    float hitCenterY = y - plumeH * 0.42;
    float hitW = rosa.h * 0.18 + height * 0.045;
    float hitH = rosa.h * 0.30 + height * 0.145;

    float geyserSX = screenX(x, hitCenterY, z);
    float geyserSY = screenY(x, hitCenterY, z);

    float rosaSX = rosa.getScreenX(t);
    float rosaSY = rosa.getScreenY(t);

    return abs(geyserSX - rosaSX) < hitW &&
           abs(geyserSY - rosaSY) < hitH;
  }

  // Texture-mapped geometry used only for the mermaid-stage geyser body.
  void drawTexturedIrregularCylinder(float radius, float cylinderHeight, PImage tex) {
    if (tex != null) {
      drawIrregularCylinderWithTexture(radius, cylinderHeight, tex);
    } else {
      drawIrregularCylinderFallback(radius, cylinderHeight);
    }
  }

  void drawIrregularCylinderWithTexture(float radius, float cylinderHeight, PImage tex) {
    textureMode(NORMAL);

    beginShape(QUAD_STRIP);
    texture(tex);

    for (int i = 0; i <= rimSides; i++) {
      int idx = i % rimSides;

      float a = TWO_PI * i / rimSides;
      float localRadius = radius * rimNoise[idx];

      float px = cos(a) * localRadius;
      float pz = sin(a) * localRadius;

      float upperLift = rimLift[idx] * radius * 0.18;
      float lowerLift = rimLift[idx] * radius * 0.06;

      float u = (float) i / rimSides;

      vertex(px, -cylinderHeight / 2 + upperLift, pz, u, 0);
      vertex(px * 0.96,  cylinderHeight / 2 + lowerLift, pz * 0.96, u, 1);
    }

    endShape();
  }

  void drawIrregularCylinderFallback(float radius, float cylinderHeight) {
    fill(120, 155, 215, alpha);

    beginShape(QUAD_STRIP);

    for (int i = 0; i <= rimSides; i++) {
      int idx = i % rimSides;

      float a = TWO_PI * i / rimSides;
      float localRadius = radius * rimNoise[idx];

      float px = cos(a) * localRadius;
      float pz = sin(a) * localRadius;

      float upperLift = rimLift[idx] * radius * 0.18;
      float lowerLift = rimLift[idx] * radius * 0.06;

      vertex(px, -cylinderHeight / 2 + upperLift, pz);
      vertex(px * 0.96, cylinderHeight / 2 + lowerLift, pz * 0.96);
    }

    endShape();
  }

  // Texture-mapped geometry used only for the mermaid-stage steam plume.
  void drawTexturedCone(float radius, float coneHeight, PImage tex) {
    if (tex != null) {
      drawConeWithTexture(radius, coneHeight, tex);
    } else {
      drawConeFallback(radius, coneHeight);
    }
  }

  void drawConeWithTexture(float radius, float coneHeight, PImage tex) {
    int sides = 34;

    textureMode(NORMAL);

    beginShape(TRIANGLES);
    texture(tex);

    for (int i = 0; i < sides; i++) {
      float a1 = TWO_PI * i / sides;
      float a2 = TWO_PI * (i + 1) / sides;

      float organic1 = 0.94 + 0.06 * sin(a1 * 3.0 + eruptionPhase * 0.7);
      float organic2 = 0.94 + 0.06 * sin(a2 * 3.0 + eruptionPhase * 0.7);

      float x1 = cos(a1) * radius * organic1;
      float z1 = sin(a1) * radius * organic1;

      float x2 = cos(a2) * radius * organic2;
      float z2 = sin(a2) * radius * organic2;

      float u1 = (float) i / sides;
      float u2 = (float) (i + 1) / sides;

      float tipX = sin(eruptionPhase * 1.3) * radius * 0.06;
      float tipZ = cos(eruptionPhase * 1.1) * radius * 0.04;

      vertex(x1, 0, z1, u1, 1);
      vertex(x2, 0, z2, u2, 1);
      vertex(tipX, -coneHeight, tipZ, (u1 + u2) * 0.5, 0);
    }

    endShape();
  }

  void drawConeFallback(float radius, float coneHeight) {
    int sides = 34;

    fill(170, 225, 255, alpha * 0.46);

    beginShape(TRIANGLES);

    for (int i = 0; i < sides; i++) {
      float a1 = TWO_PI * i / sides;
      float a2 = TWO_PI * (i + 1) / sides;

      float organic1 = 0.94 + 0.06 * sin(a1 * 3.0 + eruptionPhase * 0.7);
      float organic2 = 0.94 + 0.06 * sin(a2 * 3.0 + eruptionPhase * 0.7);

      float tipX = sin(eruptionPhase * 1.3) * radius * 0.06;
      float tipZ = cos(eruptionPhase * 1.1) * radius * 0.04;

      vertex(cos(a1) * radius * organic1, 0, sin(a1) * radius * organic1);
      vertex(cos(a2) * radius * organic2, 0, sin(a2) * radius * organic2);
      vertex(tipX, -coneHeight, tipZ);
    }

    endShape();
  }
}
