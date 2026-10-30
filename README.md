# LITTLE BOT

> *A tiny robot. A big adventure.*

A 2D cyberpunk pixel-art platform runner built with **Godot 4.x** and **GDScript** using the **Compatibility** renderer (`480 × 270` internal viewport) for **Web (HTML5 / WebGL2)** and **Android**.

---

## Controls

| Action | Desktop / Web Keyboard | Mobile / Touchscreen |
| :--- | :--- | :--- |
| **Jump** | `Spacebar` or `Up Arrow` | Tap anywhere on the gameplay area |
| **Pause / Resume** | `Escape` or `P` | Tap top-right `II` button or Android Back gesture |
| **Mute / Unmute SFX** | `M` | Tap top-right `SFX` / `MUTE` button |
| **Menu Navigation** | Mouse click or `Arrow Keys` + `Space` / `Enter` | Tap buttons |

---

## Architecture Overview

```text
res://
├── core/
│   ├── game_manager.gd          # Root coordinator (level lifecycle, pause, state, audio & UI wiring)
│   ├── game_state.gd            # Pure RefCounted state machine with guarded transitions
│   ├── input_actions.gd         # Centralized InputMap StringName constants & startup check
│   └── score_manager.gd         # Pure RefCounted score & collectible counter
├── scenes/
│   ├── main/
│   │   ├── game.tscn            # Application entry scene (SoundController + WorldContainer + UILayer)
│   │   └── main_menu.tscn       # Title screen with animated showcase Little Bot, Mute & parallax
│   ├── levels/
│   │   ├── level_01.tscn        # Handcrafted ~36s 4-zone obstacle & collectible course
│   │   ├── ground_segment.tscn  # Configurable @tool neon ground & one-way platform
│   │   └── finish_line.tscn     # Glowing level-completion portal trigger
│   ├── player/
│   │   └── player.tscn          # Composed CharacterBody2D player + forward-looking Camera2D
│   ├── obstacles/
│   │   ├── spike.tscn           # Static lethal spike (composes HazardComponent)
│   │   └── moving_obstacle.tscn # Configurable patrolling drone (Hazard + PatrolMovement)
│   ├── collectibles/
│   │   └── energy_orb.tscn      # Animated glowing energy orb collectible
│   ├── environment/
│   │   ├── cyberpunk_parallax_bg.tscn # 4-layer seamless cyberpunk parallax + twinkling stars
│   │   └── neon_lamp.tscn       # Trackside decorative streetlight pylon
│   └── ui/
│       ├── game_hud.tscn        # Touch-safe HUD (score chip, progress bar, SFX mute, II pause)
│       ├── pause_menu.tscn      # Pause modal (Resume, Restart, Main Menu)
│       ├── game_over.tscn       # Game Over modal (Final Score, Distance %, Restart, Menu)
│       └── level_completed.tscn # Completion modal (Final Score, Orbs count, Play Again, Menu)
├── scripts/
│   ├── audio/                   # Procedural 16-bit PCM retro synthesizer, cue cache & pooled player
│   ├── collectibles/
│   ├── components/
│   ├── environment/
│   ├── levels/
│   ├── obstacles/
│   ├── player/
│   └── ui/
└── tests/                       # Self-contained automated verification suites (Phases 1–6)
```

### Core Engineering Principles
- **Zero Global Singletons**: `GameManager` coordinates from the root scene; leaf entities (`Player`, `Spike`, `MovingObstacle`, `EnergyOrb`, `FinishLine`) emit local signals without referencing global managers, audio buses, or UI.
- **Zero External Asset Dependencies**: `RetroWaveSynthesizer` pre-synthesizes crisp 16-bit PCM `AudioStreamWAV` chiptune buffers once at boot (< 50 KB RAM, zero per-frame CPU cost, zero WebAudio ring-buffer underruns).
- **Composition over Inheritance**: `Player` composes `PlayerInputComponent`, `RunnerMovementComponent`, `HurtboxComponent`, and `PlayerVisualController`. Obstacles compose `HazardComponent` and optional `PatrolMovementComponent` without rigid inheritance trees.
- **Clean Extending (OCP)**:
  - *New Obstacle Type*: Create a `Node2D` scene with visuals + `HazardComponent` (layer 3 `hazards`), plus `PatrolMovementComponent` or a new behavior node. Zero changes to `Player` or `GameManager`.
  - *New Level*: Duplicate or create a `Node2D` extending `GameLevel` with `SpawnPoint`, `FinishPoint`/`FinishLine`, `Player`, `Track`, `Obstacles`, and `Collectibles`.

---

## Automated Verification Suites

Open any test scene in Godot 4 Editor and press **F6** (*Run Current Scene*):
1. `res://tests/foundation_tests.tscn` — InputMap, `GameState` transitions, progress clamping.
2. `res://tests/phase2_gameplay_tests.tscn` — Auto-run, grounded jump, airborne jump guard, moving patrol, spike & gap deaths.
3. `res://tests/phase3_systems_tests.tscn` — `ScoreManager`, orb collection, mid-run & Game Over restarts, pre/post-death orb edge cases, FinishLine race guard.
4. `res://tests/phase4_ui_tests.tscn` — Main Menu boot, HUD live updates, Pause/Resume, Game Over & Level Completed navigation.
5. `res://tests/phase5_platform_tests.tscn` — Keyboard & touchscreen input routing, multi-aspect-ratio (`16:9`, `20:9`, `4:3`) UI bounds, Android Back navigation, Web/Android export settings.
6. `res://tests/phase6_audio_tests.tscn` — Procedural 16-bit PCM synthesis, zero-click envelopes, polyphonic pooling, mute suppression, and UI/keyboard mute sync.

---

## Exporting to Web & Android

### Web (HTML5 / WebGL2)
1. In Godot Editor, install Export Templates (**Editor → Manage Export Templates**).
2. Open **Project → Export → Add… → Web**.
3. Keep **Variant → Thread Support** disabled (*Single-Threaded* default in Godot 4.3+) for universal hosting without special `SharedArrayBuffer` headers.
4. Click **Export Project** and output as `index.html`.

### Android (APK / AAB)
1. Configure Android SDK & OpenJDK 17 paths under **Editor → Editor Settings → Export → Android**.
2. Open **Project → Export → Add… → Android**.
3. Verify **Screen → Immersive Mode** is enabled (`Sensor Landscape` and `ETC2/ASTC` VRAM compression are pre-configured in `project.godot`).
4. Click **Export Project** to build a debug `.apk` or signed `.aab`.
