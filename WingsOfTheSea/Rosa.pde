// Player character: movement, dash, form changes, hit bounds, and fairy/mermaid rendering.
class Rosa {

  final int FORM_FAIRY = 0;
  final int FORM_MERMAID = 1;

  int currentForm = FORM_FAIRY;

  PImage fairyBodyImg;
  PImage fairyWingsImg;

  PImage mermaidBodyImg;
  PImage mermaidTailImg;

  float x;
  float y;
  float h;

  boolean leftHeld  = false;
  boolean rightHeld = false;
  boolean upHeld    = false;
  boolean downHeld  = false;

  int dashFramesLeft = 0;
  int dashCooldownLeft = 0;

  int dashDurationFrames = 8;     // movement dash
  int dashCooldownFrames = 60;    // about 1 second

  int dashVisualFramesLeft = 0;
  int dashVisualDurationFrames = 18;

  float dashDirX = 0;
  float dashDirY = 0;

  float lastMoveDirX = 0;
  float lastMoveDirY = 0;

  int hitShakeFramesLeft = 0;
  int hitShakeDurationFrames = 16;
  int previousHitCooldown = 0;

  Rosa(PImage fairyBodyImg, PImage fairyWingsImg) {
    this.fairyBodyImg = fairyBodyImg;
    this.fairyWingsImg = fairyWingsImg;

    this.mermaidBodyImg = null;
    this.mermaidTailImg = null;

    h = height * 0.34;

    reset();
  }

  void setMermaidImages(PImage mermaidBodyImg, PImage mermaidTailImg) {
    this.mermaidBodyImg = mermaidBodyImg;
    this.mermaidTailImg = mermaidTailImg;
  }

  void becomeFairy() {
    currentForm = FORM_FAIRY;
    h = height * 0.34;
  }

  void becomeMermaid() {
    currentForm = FORM_MERMAID;
    h = height * 0.46;
  }

  boolean isFairy() {
    return currentForm == FORM_FAIRY;
  }

  boolean isMermaid() {
    return currentForm == FORM_MERMAID;
  }

  void reset() {
    x = width  * 0.50;
    y = height * 0.55;

    becomeFairy();

    leftHeld  = false;
    rightHeld = false;
    upHeld    = false;
    downHeld  = false;

    dashFramesLeft = 0;
    dashCooldownLeft = 0;
    dashVisualFramesLeft = 0;

    hitShakeFramesLeft = 0;
    previousHitCooldown = 0;

    dashDirX = 0;
    dashDirY = 0;

    lastMoveDirX = 0;
    lastMoveDirY = 0;
  }

  void clearInputState() {
    leftHeld  = false;
    rightHeld = false;
    upHeld    = false;
    downHeld  = false;

    dashFramesLeft = 0;
    dashVisualFramesLeft = 0;

    dashDirX = 0;
    dashDirY = 0;
  }

  void centerForStageStart() {
    x = width  * 0.50;
    y = height * 0.55;

    clearInputState();
  }

  void update() {
    if (dashCooldownLeft > 0) {
      dashCooldownLeft--;
    }

    if (dashVisualFramesLeft > 0) {
      dashVisualFramesLeft--;
    }

    float dx = 0;
    float dy = 0;

    if (leftHeld)  dx -= 1;
    if (rightHeld) dx += 1;
    if (upHeld)    dy -= 1;
    if (downHeld)  dy += 1;

    if (dx != 0 || dy != 0) {
      float len = sqrt(dx * dx + dy * dy);
      dx /= len;
      dy /= len;

      lastMoveDirX = dx;
      lastMoveDirY = dy;
    }

    float moveSpeed = height * 0.009;
    float dashSpeed = height * 0.032;

    if (dashFramesLeft > 0) {
      x += dashDirX * dashSpeed;
      y += dashDirY * dashSpeed;
      dashFramesLeft--;
    } else {
      x += dx * moveSpeed;
      y += dy * moveSpeed;
    }

    x = constrain(x, width * 0.24, width * 0.76);
    y = constrain(y, height * 0.36, height * 0.78);
  }

  // Starts a short movement burst in the last movement direction, with cooldown protection.
  boolean startDash() {
    if (dashCooldownLeft > 0) return false;
    if (dashFramesLeft > 0) return false;

    float dx = 0;
    float dy = 0;

    if (leftHeld)  dx -= 1;
    if (rightHeld) dx += 1;
    if (upHeld)    dy -= 1;
    if (downHeld)  dy += 1;

    if (dx == 0 && dy == 0) {
      dx = lastMoveDirX;
      dy = lastMoveDirY;
    }

    if (dx == 0 && dy == 0) {
      return false;
    }

    float len = sqrt(dx * dx + dy * dy);
    dx /= len;
    dy /= len;

    dashDirX = dx;
    dashDirY = dy;

    dashFramesLeft = dashDurationFrames;
    dashCooldownLeft = dashCooldownFrames;
    dashVisualFramesLeft = dashVisualDurationFrames;

    return true;
  }

boolean isDashEffectActive() {
    return dashVisualFramesLeft > 0;
  }

  // Keyboard state is stored as booleans so movement remains smooth while keys are held.
  void setMoveKey(char k, int kc, boolean pressed) {
    if (kc == LEFT  || k == 'a' || k == 'A') leftHeld  = pressed;
    if (kc == RIGHT || k == 'd' || k == 'D') rightHeld = pressed;
    if (kc == UP    || k == 'w' || k == 'W') upHeld    = pressed;
    if (kc == DOWN  || k == 's' || k == 'S') downHeld  = pressed;
  }

  float getDrawY(float t) {
    return y + sin(t * 0.9) * height * 0.012;
  }

  float getScreenX(float t) {
    return screenX(x, getDrawY(t), 0);
  }

  float getScreenY(float t) {
    return screenY(x, getDrawY(t), 0);
  }

  // Starts the visual shake when a new hit cooldown begins.
  void updateHitShake(int hitCooldown) {
    if (hitCooldown > previousHitCooldown) {
      hitShakeFramesLeft = hitShakeDurationFrames;
    }

    previousHitCooldown = hitCooldown;
  }

  float getHitShakeStrength() {
    if (hitShakeFramesLeft <= 0) return 0;
    return (float) hitShakeFramesLeft / hitShakeDurationFrames;
  }

  float getHitShakeX() {
    float strength = getHitShakeStrength();
    return sin(frameCount * 2.4) * height * 0.018 * strength;
  }

  float getHitShakeY() {
    float strength = getHitShakeStrength();
    return cos(frameCount * 3.1) * height * 0.006 * strength;
  }

  void draw(float t, int hitCooldown) {
    updateHitShake(hitCooldown);

    pushMatrix();
    translate(getHitShakeX(), getHitShakeY(), 0);

    if (currentForm == FORM_MERMAID && mermaidBodyImg != null && mermaidTailImg != null) {
      drawMermaid(t);
    } else {
      drawFairy(t);
    }

    popMatrix();

    if (hitShakeFramesLeft > 0) {
      hitShakeFramesLeft--;
    }
  }

  void drawDashTrail(float bobY) {
    if (!isDashEffectActive()) return;

    if (isFairy()) {
      drawFairySparkleTrail(bobY);
    } else {
      drawMermaidBubbleTrail(bobY);
    }
  }

  void drawFairySparkleTrail(float bobY) {
    float strength = (float) dashVisualFramesLeft / dashVisualDurationFrames;

    float perpX = -dashDirY;
    float perpY = dashDirX;

    for (int i = 1; i <= 12; i++) {
      float distanceBehind = h * (0.07 * i + 0.03);

      float wave = sin(frameCount * 0.42 + i * 1.15);
      float sideOffset = wave * h * 0.055;

      float sparkleX = x - dashDirX * distanceBehind + perpX * sideOffset;
      float sparkleY = y + bobY - dashDirY * distanceBehind + perpY * sideOffset;

      float alpha = 255 * strength * (1.0 - i * 0.06);
      float sparkleSize = h * (0.020 + (i % 4) * 0.010);

      drawSparkle(sparkleX, sparkleY, sparkleSize, alpha);
    }
  }

  void drawSparkle(float sx, float sy, float size, float alpha) {
    pushStyle();

    noStroke();
    fill(255, 240, 170, alpha * 0.18);
    ellipse(sx, sy, size * 5.0, size * 5.0);

    fill(180, 230, 255, alpha * 0.12);
    ellipse(sx, sy, size * 7.0, size * 7.0);

    stroke(255, 245, 180, alpha);
    strokeWeight(max(1.2, size * 0.13));
    line(sx - size * 1.2, sy, sx + size * 1.2, sy);
    line(sx, sy - size * 1.2, sx, sy + size * 1.2);

    stroke(210, 240, 255, alpha * 0.90);
    strokeWeight(max(1.0, size * 0.09));
    line(sx - size * 0.85, sy - size * 0.85, sx + size * 0.85, sy + size * 0.85);
    line(sx - size * 0.85, sy + size * 0.85, sx + size * 0.85, sy - size * 0.85);

    noStroke();
    fill(255, 255, 255, alpha);
    ellipse(sx, sy, size * 0.55, size * 0.55);

    popStyle();
  }

  void drawMermaidBubbleTrail(float bobY) {
    float strength = (float) dashVisualFramesLeft / dashVisualDurationFrames;

    float perpX = -dashDirY;
    float perpY = dashDirX;

    pushStyle();

    for (int i = 1; i <= 12; i++) {
      float distanceBehind = h * (0.07 * i + 0.03);

      float wave = sin(frameCount * 0.42 + i * 1.15);
      float sideOffset = wave * h * 0.055;

      float bubbleX = x - dashDirX * distanceBehind + perpX * sideOffset;
      float bubbleY = y + bobY - dashDirY * distanceBehind + perpY * sideOffset;

      float alpha = 190 * strength * (1.0 - i * 0.06);
      float bubbleSize = h * (0.016 + (i % 4) * 0.006);

      noStroke();
      fill(150, 220, 255, alpha * 0.12);
      ellipse(bubbleX, bubbleY, bubbleSize * 2.8, bubbleSize * 2.8);

      noFill();
      stroke(170, 235, 255, alpha);
      strokeWeight(max(1.0, bubbleSize * 0.10));
      ellipse(bubbleX, bubbleY, bubbleSize, bubbleSize);

      noStroke();
      fill(255, 255, 255, alpha * 0.75);
      ellipse(
        bubbleX - bubbleSize * 0.18,
        bubbleY - bubbleSize * 0.18,
        bubbleSize * 0.22,
        bubbleSize * 0.22
      );

      fill(210, 245, 255, alpha * 0.18);
      ellipse(bubbleX, bubbleY, bubbleSize * 0.70, bubbleSize * 0.70);
    }

    popStyle();
  }

  void drawFairy(float t) {
    if (fairyBodyImg == null || fairyWingsImg == null) return;

    float bodyW  = h * ((float) fairyBodyImg.width  / fairyBodyImg.height);
    float wingsW = h * ((float) fairyWingsImg.width / fairyWingsImg.height);

    float wingsOffsetX = 0;
    float wingsOffsetY = h * -0.25;

    float bobY      = sin(t * 0.9) * height * 0.012;
    float flapScale = 1.0 + sin(t * 7.0) * 0.08;

    imageMode(CENTER);
    noStroke();

    drawDashTrail(bobY);

    pushMatrix();
    translate(x, y + bobY, 0);
    image(fairyBodyImg, 0, 0, bodyW, h);
    popMatrix();

    pushMatrix();
    translate(x + wingsOffsetX, y + bobY + wingsOffsetY, 0);
    scale(flapScale, 1.0);
    image(fairyWingsImg, 0, 0, wingsW, h);
    popMatrix();
  }

  void drawMermaid(float t) {
    if (mermaidBodyImg == null || mermaidTailImg == null) return;

    float bodyH = h * 0.60;
    float tailH = h * 0.80;

    float bodyW = bodyH * ((float) mermaidBodyImg.width / mermaidBodyImg.height);
    float tailW = tailH * ((float) mermaidTailImg.width / mermaidTailImg.height);

    float bobY = sin(t * 0.9) * height * 0.012;

    drawDashTrail(bobY);

    float tailWave = sin(t * 6.0) * 0.10;

    imageMode(CENTER);
    noStroke();

    float tailCenterY = y + bobY + h * 0.20;
    float tailPivotFromCenter = tailH * 0.35;
    float tailPivotY = tailCenterY - tailPivotFromCenter;

    pushMatrix();
    translate(x, tailPivotY, 0);
    rotate(tailWave);
    image(mermaidTailImg, 0, tailPivotFromCenter, tailW, tailH);
    popMatrix();

    pushMatrix();
    translate(x, y + bobY - h * 0.17, 0);
    image(mermaidBodyImg, 0, 0, bodyW, bodyH);
    popMatrix();
  }
}
