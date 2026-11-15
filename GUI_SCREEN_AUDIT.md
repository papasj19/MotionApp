# Adaptive Motion Arcade — GUI Audit and Screen Plan

## Visual direction adopted

The starting direction is a calm neon arcade: dark violet backgrounds, cream
text, cyan primary controls, and limited pink/yellow accents. Joybit is a
supportive guide, not a constant animated distraction. Standard readable type
is retained; pixel styling belongs in artwork, borders, icons, and later game
surfaces rather than body copy.

## Current screen audit

### Home

- Now introduces Joybit and the new palette.
- Keep one obvious action: start comfortable calibration.
- Still needs a final decision on whether this becomes a child-facing welcome
  screen or a caregiver dashboard once profiles and games exist.

### Movement choice

- Finger, wrist, and head are large separate choices with distinct accents.
- The safety explanation is clear but text-heavy.
- Before Phase 6, add a short visual example for each movement only after real
  device testing confirms the examples cannot mislead users.

### Camera and calibration

- Functionally complete, but still reads like a technical setup screen.
- Keep the camera preview visually quiet and never place arcade decoration over
  the tracked body area.
- The next GUI pass should replace sample counts and dense calibration wording
  with a clear progress model: **Position → Rest → Move → Review**. Technical
  details should move behind a caregiver “More details” control.
- Joybit should appear only at the beginning, completion, and recoverable error
  states—not continuously beside the live camera.

## Required before Phase 6

1. Approve the primary flow:
   **Welcome → Movement choice → Position camera → Rest → Comfortable movement
   → Caregiver review → Control test**.
2. Decide which screens are child-facing and which controls are caregiver-only.
3. Design the four-step calibration progress indicator and the tracking-quality
   states: ready, searching, tracking lost, retry, and camera unavailable.
4. Test palette contrast, text scaling, screen-reader order, landscape layout,
   and color-blind comprehension on real devices.
5. Choose the permanent Joybit asset format. The current welcome illustration
   is suitable for onboarding, but transparent 32/64/128 px sprites are still
   needed for compact prompts and future animation.

## Phase 6 screen plan

Phase 6 should add one game-independent **Control Test** screen after
calibration. It should show a large single target and unambiguous states:

- Ready / tracking available
- Action pressed
- Action released
- Tracking lost / safely paused
- Recalibrate or use this control

This screen validates hysteresis and one-action-per-movement behavior before a
game is introduced. It should use the same shared buttons, panels, status
language, and Joybit completion treatment established here.

## After Phase 6

- Game selection with no more than a few large choices per screen
- Game HUD and pause screen
- Caregiver profile/session setup
- Results and progress screens, with physical movement metrics kept separate
  from arcade scores
- Reduced-motion and sound controls

No game, profile, or progress UI should be implemented until the calibration
and Control Test flow has been approved as one coherent screen sequence.
