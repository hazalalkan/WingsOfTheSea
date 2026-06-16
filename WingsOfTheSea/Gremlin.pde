// Fairy-stage moving obstacle with drifting movement and wing animation.
class Gremlin {

  PImage body;
  PImage wings;

  int slotIndex;

  float x, y, z;
  float baseX, baseY;

  float speedZ;
  float t;
  float gH;

  float driftAmpX;
  float driftAmpY;
  float driftSpeedX;
  float driftSpeedY;

  float farZ  = -1700;
  float nearZ = 280;

  boolean exiting = false;
  boolean oneShot = false;
  boolean active = true;
  float alpha = 255;

  Gremlin(PImage b, PImage w, int slot) {
    body = b;
    wings = w;
    slotIndex = slot;

    gH = height * 0.13;

    reset(true);
  }

  void setImages(PImage b, PImage w) {
    if (b != null) {
      body = b;
    }

    if (w != null) {
      wings = w;
    }
  }

  boolean isActive() {
    return active;
  }

  void reset(boolean spreadAtStart) {
    resetConfigured(spreadAtStart, farZ, 230, 70, 4.0, 6.7, false);
  }

  void resetOneShotWave(float startZ, float spacingZ, float jitterZ, float minSpeedZ, float maxSpeedZ) {
    resetConfigured(true, startZ, spacingZ, jitterZ, minSpeedZ, maxSpeedZ, true);
  }

  void resetConfigured(boolean spreadAtStart, float startZ, float spacingZ, float jitterZ, float minSpeedZ, float maxSpeedZ, boolean shouldBeOneShot) {
    exiting = false;
    oneShot = shouldBeOneShot;
    active = true;
    alpha = 255;

    int laneIndex = (int)random(3);   // 0 left, 1 center, 2 right

    float laneGap = width * 0.18;

    baseX = width * 0.50 + (laneIndex - 1) * laneGap + random(-width * 0.025, width * 0.025);

    baseY = random(height * 0.42, height * 0.56);

    if (spreadAtStart) {
      z = startZ + slotIndex * spacingZ + random(-jitterZ, jitterZ);
    } else {
      z = farZ - slotIndex * 230 - random(0, 420);
    }

    if (z > -450) {
      z = -450;
    }

    speedZ = random(minSpeedZ, maxSpeedZ);

    t = random(TWO_PI);

    driftAmpX = random(width * 0.015, width * 0.045);
    driftAmpY = random(height * 0.006, height * 0.020);

    driftSpeedX = random(0.018, 0.038);
    driftSpeedY = random(0.022, 0.050);

    x = baseX;
    y = baseY;
  }

  void update() {
    if (!active) {
      return;
    }

    t += 1.0;

    if (!exiting) {
      z += speedZ;

      x = baseX + sin(t * driftSpeedX) * driftAmpX;
      y = baseY + sin(t * driftSpeedY) * driftAmpY;

      if (z > 95) {
        startExit();
      }

    } else {
      z += speedZ * 1.20;

      x = baseX + sin(t * driftSpeedX) * driftAmpX;
      y = baseY + sin(t * driftSpeedY) * driftAmpY;

      alpha = lerp(alpha, 0, 0.060);

      if (alpha < 6 || z > nearZ + 130) {
        if (oneShot) {
          active = false;
          alpha = 0;
        } else {
          reset(false);
        }
      }
    }
  }

  void startExit() {
    exiting = true;
  }

  void forceExit() {
    if (!active) {
      return;
    }

    if (!exiting) {
      startExit();
    }

    alpha = min(alpha, 180);
  }

  void draw() {
    if (!active || body == null || wings == null) {
      return;
    }

    float bodyW  = gH * ((float) body.width  / body.height);
    float wingsW = gH * ((float) wings.width / wings.height);

    float animT = t * 0.035;
    float flap = sin(animT * 7);
    float wingW = wingsW * (1.0 - flap * 0.07);

    float dir = (cos(t * driftSpeedX) < 0) ? -1.0 : 1.0;

    imageMode(CENTER);
    noStroke();

    pushMatrix();

    translate(x, y, z);
    scale(dir, 1);

    tint(255, alpha);

    pushMatrix();
    translate(0, -gH * 0.08, -1);
    image(wings, 0, 0, wingW, gH);
    popMatrix();

    image(body, 0, 0, bodyW, gH);

    noTint();

    popMatrix();
  }
}
