# Adaptive Motion Arcade — GUI Architecture and Screen Plan

Status: approved POC direction with responsive wireframes prepared for review
on 2026-11-15. School access and the possible third Student Hub action remain
open until teacher interviews. This document does not authorize implementation
of later stages.

## Product structure from the sketch

The app opens into an arcade lobby rather than directly into calibration.
Joybit is centered, decorative arcade cabinets frame the sides, and two large
mode buttons sit at the bottom:

- **Quick Play** (house icon): a short, child-facing path with no profile
  required.
- **School** (school icon): a caregiver/teacher path with child profiles,
  sessions, and results.

Use the words **Quick Play** rather than **Home** on the mode button. This keeps
it distinct from the persistent Home control that returns to the arcade lobby.
The cabinet rows should be quiet background scenery, not another set of
buttons or a continuous animation.

## Navigation map

```text
Arcade Lobby
├── Quick Play
│   ├── Choose Movement
│   ├── Position Camera
│   ├── Calibrate: Rest → Move → Review
│   ├── Control Test                         [Stage 6]
│   ├── Choose Game                          [Stage 9]
│   ├── Play Game
│   └── Session End
│       ├── Play Again
│       ├── Choose Another Game ─────────────→ Choose Game
│       └── Home ────────────────────────────→ Arcade Lobby
└── School                                   [Stage 8 onward]
    ├── Choose Student
    └── Student Hub
        ├── Results                           [Stage 10]
        ├── Setup & Play
        │   └── movement/calibration/control-test/game flow
        └── Third action intentionally open pending teacher interviews
```

Quick Play and School must share one movement/calibration/controller pipeline.
They differ in whether the setup and session belong to a saved student. Camera
or calibration logic must not be duplicated between the modes.

## Screen contracts

### 1. Arcade Lobby

- Joybit is the clear focal point in the middle.
- Large **Quick Play** and **School** buttons remain in fixed, predictable
  positions along the bottom.
- Side cabinets establish the arcade setting but stay low contrast and outside
  the main reading/order path.
- No metrics, calibration details, or carousel controls belong here.

### 2. Quick Play — Choose Movement

- Four large, Tetris-like tiles are planned: **Head**, **Hand/Wrist**,
  **Finger**, and **Leg**.
- Each tile needs both a picture and a text label; color alone cannot identify
  it.
- Joybit artwork can demonstrate the body area without using detailed or
  blurry medical imagery.
- Current support is head tilt, wrist bend, and finger bend. **Leg must not be
  offered as an active choice until leg tracking, full-body camera placement,
  calibration, and device validation exist.** It can be designed now, but it
  should not ship as a button that appears usable.

### 3. Calibration / movement range

The bar-graph idea becomes friendly visual feedback during calibration:

- Joybit moves between bars as the app observes rest and comfortable movement.
- The animation supplements a progress label; it never replaces instructions
  or tracking status.
- The child is not ranked as low, medium, or high, and the app never asks them
  to reach a higher bar.
- The final comfortable range is measured, not selected as an effort target.
- If **Low / Medium / High** is retained, it must describe **controller/game
  sensitivity**, not the child's ability or required physical range.

Keep the underlying safe flow:
**Position → Rest → Comfortable movement → Caregiver review**. Move technical
angles, sample counts, and reliability details behind a caregiver-only
**More details** control.

### 4. Control Test

Stage 6 ends at a large, game-independent test screen. It proves that one
comfortable movement produces one action and that tracking loss pauses safely.
It is not an arcade game and does not save school metrics yet.

Required states:

- Ready / tracking available
- Action pressed
- Action released
- Tracking lost / safely paused
- Recalibrate
- Continue to games (only after game selection exists)

### 5. Game Select

- Games are presented as large cartridges or game cases with artwork and a
  readable title.
- Provide visible previous/next controls as well as swipe support; a carousel
  cannot depend on a precise swipe gesture.
- Only playable games appear selectable. Do not fill the shelf with misleading
  locked cartridges.
- A large Home control returns to the Arcade Lobby.
- After every game, the child can replay, return to the cartridge screen, or
  finish and return home.

### 6. School — Choose Student

- This is a caregiver/teacher screen, not a child arcade screen.
- Use a clear list or large profile cards with display aliases and an add/manage
  action.
- Profiles remain local-first and caregiver controlled. No raw camera frames or
  video are stored.
- Profile persistence belongs to Stage 8, after controller and device
  validation.

### 7. Student Hub

The current POC contains two understood actions:

- **Results**: physical-signal and game results kept visibly separate.
- **Setup & Play**: choose/review movement, calibrate, test, and choose a game.

The question-mark card is deliberately omitted. Teacher interviews should
establish whether a third action is useful and what it should do. If they do
not identify a real need, ship two cards rather than inventing one.

### 8. Results

Results are caregiver-facing and arrive in Stage 10. Keep two sections:

- **Physical signal:** selected movement, calibrated signal range, valid
  deliberate movement count, repeatability, tracking reliability, and setup
  context.
- **Game:** score, attempts, session duration, and game difficulty.

Never present game score as motor improvement. Do not label normalized camera
measurements as millimeters or clinical outcomes. Comparisons must warn when
camera position, calibration, device, or tracking conditions changed.

## Child-facing and caregiver-facing boundary

Child-facing:

- Arcade Lobby
- Quick Play movement tiles
- Simple positioning/calibration instructions
- Control Test
- Game Select, game, pause, and session end

Caregiver/teacher-facing:

- Student selection and profile management
- Calibration review and technical details
- Results, deletion, export, and settings

The app can share the visual style across both areas, but school screens should
prioritize information clarity over arcade decoration.

## Accessibility rules for every mockup

- One dominant decision per screen; avoid presenting lobby, movement, range,
  and games together.
- Large targets with generous spacing, text labels, and icons.
- Never depend only on color, animation, swipe, or pixel-art detail.
- Keep Joybit and decoration outside the camera tracking area.
- Avoid continuous cabinet, character, or background movement. Provide reduced
  motion before game animation is introduced.
- Preserve text scaling, screen-reader order, high contrast, responsive
  portrait/landscape layout, and a large consistent Back/Home action.
- Confirm before abandoning an in-progress game or unsaved school setup, but do
  not add confirmation to ordinary backward navigation.

## Recorded decisions and research holds

1. **Approved — responsive layouts:** every screen must adapt to phone and
   tablet widths in both portrait and landscape. Do not depend on a landscape
   lock, even though iPad use may provide more space.
2. **Approved — separate concepts:** measured comfortable range and selectable
   game/controller sensitivity remain separate in code and language.
3. **Approved — Leg later:** design the fourth tile now but hide it from the
   playable POC until leg tracking is implemented and validated.
4. **Research hold — School entry:** do not choose an adult gate, confirmation,
   or profile-access method until school interviews clarify the setting.
5. **Research hold — third Student Hub action:** show only Results and Setup &
   Play in the POC. Do not implement Quick Start or another placeholder before
   teacher feedback.
6. **Approved — session ending:** provide Play Again, Choose Another Game, and
   Home.
7. **Prepared for review — wireframes:** the initial set covers the Lobby,
   movement selection, calibration, Control Test, Game Select, student list,
   Student Hub, and Results. Later passes must add explicit loading,
   tracking-lost, camera-denied, empty, and large-text states before visual
   polish or screen implementation.

## Implementation order from this plan

### Before Stage 6

- Review the prepared navigation map and low-detail wireframes.
- Record requested changes without implementing Flutter screens.
- Extend the approved wireframes with loading, tracking-lost, camera-denied,
  empty, and large-text states.
- Define the shared Back/Home behavior and the child/caregiver boundary.
- Do not build empty School, Results, or game screens just to make navigation
  appear complete.

### Stage 6

- Build the game-independent controller and its Control Test screen only.
- Connect it to the existing safe calibration output.
- Do not implement games, profiles, persistence, or results.

### After Stage 6

1. **Stage 7:** validate controller behavior, tracking, orientation, and
   accessibility on real devices.
2. **Shared GUI foundation:** implement approved lobby/navigation and reusable
   large tiles, progress states, cartridges, and exit controls without fake
   destinations.
3. **Stage 8:** add local student profiles and sessions, then enable the School
   student list and Student Hub setup path.
4. **Stage 9:** add the first game, cartridge selection, and the
   game/session-end loop.
5. **Stage 10:** add Results using the privacy and measurement rules above.

The next step is screen planning and approval, not implementation.
