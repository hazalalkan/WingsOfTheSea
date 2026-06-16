// Reusable decorative particle field for menu and transition-style screens.
class MagicDots {

  int dotCount;
  int seed;

  float[] startX;
  float[] startY;
  float[] dotSize;
  float[] maxAlpha;
  float[] driftX;
  float[] driftY;
  float[] ageMs;
  float[] lifeMs;
  float[] phase;
  float[] wiggleSpeed;
  float[] wiggleAmp;

  int cachedW = -1;
  int cachedH = -1;
  int lastUpdateMs = 0;

  java.util.Random rng;

  MagicDots(int dotCount, int seed) {
    this.dotCount = max(0, dotCount);
    this.seed = seed;
    rng = new java.util.Random(seed);
  }

  void display() {
    ensureDots();

    if (startX == null) {
      return;
    }

    int now = millis();
    float dtMs = 0;

    if (lastUpdateMs > 0) {
      dtMs = constrain(now - lastUpdateMs, 0, 50);
    }

    lastUpdateMs = now;

    pushStyle();
    noStroke();
    ellipseMode(CENTER);

    for (int i = 0; i < dotCount; i++) {
      ageMs[i] += dtMs;

      if (ageMs[i] > lifeMs[i]) {
        resetDot(i, true);
      }

      if (ageMs[i] < 0) {
        continue;
      }

      drawDot(i);
    }

    popStyle();
  }

  void drawDot(int i) {
    float lifeProgress = constrain(ageMs[i] / lifeMs[i], 0, 1);
    float ageSec = ageMs[i] * 0.001;

    float fade = getFade(lifeProgress);
    float pulse = 0.82 + 0.18 * sin(ageSec * wiggleSpeed[i] + phase[i]);
    float a = maxAlpha[i] * fade * pulse;

    if (a <= 1) {
      return;
    }

    float x = startX[i] + driftX[i] * ageSec + sin(ageSec * wiggleSpeed[i] + phase[i]) * wiggleAmp[i];
    float y = startY[i] + driftY[i] * ageSec + cos(ageSec * wiggleSpeed[i] + phase[i]) * wiggleAmp[i];

    if (x < -20 || x > width + 20 || y < -20 || y > height + 20) {
      resetDot(i, true);
      return;
    }

    fill(255, 255, 255, a * 0.16);
    ellipse(x, y, dotSize[i] * 2.8, dotSize[i] * 2.8);

    fill(255, 255, 255, a);
    ellipse(x, y, dotSize[i], dotSize[i]);
  }

  float getFade(float p) {
    float fadeInEnd = 0.24;
    float fadeOutStart = 0.68;

    if (p < fadeInEnd) {
      return easeInOut(p / fadeInEnd);
    }

    if (p > fadeOutStart) {
      return easeInOut((1.0 - p) / (1.0 - fadeOutStart));
    }

    return 1.0;
  }

  float easeInOut(float v) {
    v = constrain(v, 0, 1);
    return v * v * (3.0 - 2.0 * v);
  }

  void ensureDots() {
    if (width <= 0 || height <= 0) {
      return;
    }

    if (startX != null && cachedW == width && cachedH == height) {
      return;
    }

    cachedW = width;
    cachedH = height;
    lastUpdateMs = millis();
    rng = new java.util.Random(seed + width * 31 + height * 17);

    startX = new float[dotCount];
    startY = new float[dotCount];
    dotSize = new float[dotCount];
    maxAlpha = new float[dotCount];
    driftX = new float[dotCount];
    driftY = new float[dotCount];
    ageMs = new float[dotCount];
    lifeMs = new float[dotCount];
    phase = new float[dotCount];
    wiggleSpeed = new float[dotCount];
    wiggleAmp = new float[dotCount];

    for (int i = 0; i < dotCount; i++) {
      resetDot(i, false);
      ageMs[i] = -randomRange(0, 2800);
    }
  }

  void resetDot(int i, boolean delayed) {
    startX[i] = randomRange(0, width);
    startY[i] = randomRange(0, height);
    dotSize[i] = randomRange(2.0, 5.5);
    maxAlpha[i] = randomRange(120, 230);
    driftX[i] = randomRange(-3.2, 3.2);
    driftY[i] = randomRange(-2.6, 2.6);
    lifeMs[i] = randomRange(2600, 5200);
    phase[i] = randomRange(0, TWO_PI);
    wiggleSpeed[i] = randomRange(0.9, 2.4);
    wiggleAmp[i] = randomRange(0.25, 1.15);
    ageMs[i] = delayed ? -randomRange(350, 2300) : randomRange(0, lifeMs[i]);
  }

  float randomRange(float minValue, float maxValue) {
    return minValue + rng.nextFloat() * (maxValue - minValue);
  }
}
