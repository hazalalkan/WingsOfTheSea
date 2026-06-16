// Mouse-controlled gameplay camera for rotation and zoom in the 3D scene.
class CameraController {

  float camDist = 900;
  float camAngX = 0;
  float camAngY = 0;

  float minCamDist = 760;
  float maxCamDist = 980;

  float minCamAngX = -0.055;
  float maxCamAngX =  0.065;

  float minCamAngY = -0.070;
  float maxCamAngY =  0.070;

  float prevMX, prevMY;
  boolean dragging = false;

  CameraController() {
  }

  void apply() {
    perspective(PI / 3.0, (float) width / height, 5, 5000);

    float ex = width / 2.0  + camDist * sin(camAngY) * cos(camAngX);
    float ey = height / 2.0 - camDist * sin(camAngX);
    float ez = camDist      * cos(camAngY) * cos(camAngX);

    camera(
      ex, ey, ez,
      width / 2.0, height / 2.0, 0,
      0, 1, 0
    );
  }

  void handleMousePressed(int mx, int my) {
    dragging = true;
    prevMX = mx;
    prevMY = my;
  }

  void handleMouseDragged(int mx, int my) {
    if (!dragging) return;

    camAngY += (mx - prevMX) * 0.0016;
    camAngX += (my - prevMY) * 0.0016;

    camAngX = constrain(camAngX, minCamAngX, maxCamAngX);
    camAngY = constrain(camAngY, minCamAngY, maxCamAngY);

    prevMX = mx;
    prevMY = my;
  }

  void handleMouseReleased() {
    dragging = false;
  }

  void handleMouseWheel(float delta) {
    camDist = constrain(camDist + delta * 18, minCamDist, maxCamDist);
  }

}
