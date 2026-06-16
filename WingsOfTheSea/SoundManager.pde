// Sound-effects layer for short gameplay/UI sounds, mute, volume, cooldowns, and end-sound guards.
class SoundManager {

  PApplet app;

  SoundFile buttonClick;
  SoundFile collectibleCollected;
  SoundFile fairyDash;
  SoundFile mermaidDash;
  SoundFile geyserHit;
  SoundFile seaweedHit;
  SoundFile gremlinHit;
  SoundFile win;
  SoundFile lose;

  boolean enabled = true;
  float soundVolume = 0.85;

  final float BUTTON_CLICK_VOLUME = 0.65;
  final float COLLECTIBLE_VOLUME  = 0.75;
  final float DASH_VOLUME         = 0.75;
  final float OBSTACLE_VOLUME     = 0.85;
  final float END_SOUND_VOLUME    = 0.95;

  boolean winAlreadyPlayed = false;
  boolean loseAlreadyPlayed = false;

  HashMap<String, Integer> lastPlayed = new HashMap<String, Integer>();

  SoundManager(PApplet app) {
    this.app = app;
    loadSounds();
  }

  // Loads each sound safely so a missing asset does not stop the sketch from running.
  void loadSounds() {
    buttonClick = loadSound("button_click.wav");
    collectibleCollected = loadSound("collectible_collected.wav");
    fairyDash = loadSound("fairy_dash.wav");
    mermaidDash = loadSound("mermaid_dash.wav");
    geyserHit = loadSound("geyser_hit.wav");
    seaweedHit = loadSound("seaweed_hit.wav");
    gremlinHit = loadSound("gremlin_hit.wav");
    win = loadSound("win.wav");
    lose = loadSound("lose.wav");
  }

  SoundFile loadSound(String fileName) {
    try {
      return new SoundFile(app, fileName);
    }
    catch (Exception e) {
      app.println("[SoundManager] Could not load sound: " + fileName);
      return null;
    }
  }

  void playButtonClick() {
    play("buttonClick", buttonClick, BUTTON_CLICK_VOLUME, 80, true);
  }

  void playCollectible() {
    play("collectibleCollected", collectibleCollected, COLLECTIBLE_VOLUME, 80, true);
  }

  void playFairyDash() {
    play("fairyDash", fairyDash, DASH_VOLUME, 250, true);
  }

  void playMermaidDash() {
    play("mermaidDash", mermaidDash, DASH_VOLUME, 250, true);
  }

  void playGeyserHit() {
    play("geyserHit", geyserHit, OBSTACLE_VOLUME, 550, true);
  }

  void playSeaweedHit() {
    play("seaweedHit", seaweedHit, OBSTACLE_VOLUME, 550, true);
  }

  void playGremlinHit() {
    play("gremlinHit", gremlinHit, OBSTACLE_VOLUME, 650, true);
  }

  void playWin() {
    if (winAlreadyPlayed) {
      return;
    }

    winAlreadyPlayed = true;
    play("win", win, END_SOUND_VOLUME, 0, true);
  }

  void playLose() {
    if (loseAlreadyPlayed) {
      return;
    }

    loseAlreadyPlayed = true;
    play("lose", lose, END_SOUND_VOLUME, 0, true);
  }

  // GameScreen sends a collision type; SoundManager maps it to the correct sound.
  void playObstacleHit(int hitType) {
    if (hitType == HIT_GREMLIN) {
      playGremlinHit();
    } else if (hitType == HIT_GEYSER) {
      playGeyserHit();
    } else if (hitType == HIT_SEAWEED) {
      playSeaweedHit();
    }
  }

  void resetEndSounds() {
    winAlreadyPlayed = false;
    loseAlreadyPlayed = false;
  }

  boolean isEnabled() {
    return enabled;
  }

  float getSoundVolume() {
    return soundVolume;
  }

  void setEnabled(boolean value) {
    enabled = value;
    applyCurrentVolumeToAllSounds();

    if (!enabled) {
      stopAll();
    }
  }

  void setSoundVolume(float value) {
    soundVolume = constrain(value, 0, 1);
    applyCurrentVolumeToAllSounds();
  }

  void applyCurrentVolumeToAllSounds() {
    applyVolume(buttonClick, BUTTON_CLICK_VOLUME);
    applyVolume(collectibleCollected, COLLECTIBLE_VOLUME);
    applyVolume(fairyDash, DASH_VOLUME);
    applyVolume(mermaidDash, DASH_VOLUME);
    applyVolume(geyserHit, OBSTACLE_VOLUME);
    applyVolume(seaweedHit, OBSTACLE_VOLUME);
    applyVolume(gremlinHit, OBSTACLE_VOLUME);
    applyVolume(win, END_SOUND_VOLUME);
    applyVolume(lose, END_SOUND_VOLUME);
  }

  void applyVolume(SoundFile sound, float baseVolume) {
    if (sound != null) {
      float effectiveVolume = enabled ? soundVolume : 0;
      sound.amp(constrain(effectiveVolume * baseVolume, 0, 1));
    }
  }

  void stopAll() {
    stopSound(buttonClick);
    stopSound(collectibleCollected);
    stopSound(fairyDash);
    stopSound(mermaidDash);
    stopSound(geyserHit);
    stopSound(seaweedHit);
    stopSound(gremlinHit);
    stopSound(win);
    stopSound(lose);
  }

  void stopSound(SoundFile sound) {
    if (sound != null) {
      sound.stop();
    }
  }

  // Applies mute, volume, cooldown, and optional restart rules for one sound effect.
  void play(String key, SoundFile sound, float volume, int cooldownMillis, boolean restartFromBeginning) {
    if (!enabled || soundVolume <= 0) {
      return;
    }

    if (sound == null) {
      return;
    }

    int now = app.millis();

    if (lastPlayed.containsKey(key)) {
      int elapsed = now - lastPlayed.get(key);

      if (elapsed < cooldownMillis) {
        return;
      }
    }

    lastPlayed.put(key, now);

    if (restartFromBeginning) {
      sound.stop();
    }

    applyVolume(sound, volume);
    sound.play();
  }
}
