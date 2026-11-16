# Stage 7 — Real-device validation protocol and worksheet

Status: **device observations pending**. No phone or tablet measurements were
performed on 2026-11-16. Automated analysis and synthetic controller checks do
not prove real-camera reliability.

## Observed results

None yet. Hardware was unavailable for this stage pass, so every device,
lighting, distance, orientation and occlusion result remains **pending**.

This is an engineering quality gate, not a clinical assessment. Angles are
camera estimates in degrees, not millimetres or medical measurements. Never ask
a tester to move beyond what is comfortable.

## Provisional POC targets

These targets decide whether the controller is ready for the first game. They
can be revised after the first device evidence, but must not be relaxed merely
to make a failing run pass.

| Check | Provisional pass target |
|---|---|
| Stillness | 0 actions during 30 seconds of comfortable stillness |
| Deliberate movement | 10 actions from 10 comfortable attempts |
| Duplicate prevention | 0 extra actions; a five-second hold still produces one action |
| Tracking recovery | 0 actions caused only by losing or regaining tracking |
| Valid tracking samples | At least 90% in an unobstructed, fixed-camera run |
| Processing delay | Median at or below 150 ms; note spikes above 250 ms |
| Signal rise to action | Median at or below 250 ms |
| Observed signal/noise | At least 3× when the noise estimate is non-zero |
| Orientation | Correct preview and fresh calibration after every rotation |

`Signal rise to action` begins when the direction-normalized camera estimate
first rises above the measured noise floor and ends at the controller action.
It is not the child's physical reaction time or the full movement-to-screen
delay. Measuring physical onset needs an independent, consented timing source;
do not record a child's camera preview merely to obtain this number.

Dropped frames are recorded but do not yet have a fixed pass threshold. The
pipeline intentionally discards replaced frames to avoid latency, so the count
must be interpreted alongside detection rate and processing delay.

## Before each run

1. Use an adult tester for initial engineering checks.
2. Fix the device in place; do not hand-hold it during a trial.
3. Record device model, OS version, app commit, orientation, movement, distance,
   lighting, mount and camera position.
4. Keep the whole required body area visible. Do not record or save camera
   imagery.
5. Complete a new comfortable calibration whenever the device, orientation,
   distance, lighting or movement changes.
6. Open **Control Test → Validation details** and reset the action count by
   recalibrating before a new condition.

## Core run

Perform this run separately for Finger, Hand/Wrist and Head when supported by
the tester.

1. **Stillness:** remain comfortably still for 30 seconds. Record actions,
   valid tracking samples, FPS, processing delay and dropped frames.
2. **Comfortable actions:** perform 10 clear movements, returning fully to rest
   between them. Record detected, missed and extra actions.
3. **Long holds:** hold three movements for five seconds each. Each hold should
   produce only one action.
4. **Tracking loss:** five times, leave or cover the tracked area, return while
   holding the movement, then return to rest. Recovery must not trigger an
   action until a new deliberate movement.
5. **Orientation:** rotate portrait → landscape → portrait. Confirm the preview
   is upright and calibration restarts rather than reusing stale measurements.
6. **Navigation:** use Change, choose another movement, and return to the lobby.
   Confirm no prior action count or calibration follows the new session.

## Condition matrix

Run the core test first in normal indoor light at a comfortable middle
distance. Then change one condition at a time and recalibrate.

| Condition | Variations to compare |
|---|---|
| Device | At least one supported Android phone/tablet and one iPhone/iPad |
| Orientation | Portrait, landscape left, landscape right |
| Distance | Near, normal and far; record the actual centimetres |
| Mount | Stable stand; optionally compare a carefully hand-held device |
| Lighting | Even indoor light, dim light, bright side light, backlight |
| Movement size | Slight, usual comfortable and larger comfortable—never maximum |
| Hand/head angle | Front-facing and two comfortable rotated positions |
| Occlusion | Clear view, partial finger/hand obstruction, temporary full loss |

If a variation is uncomfortable or unsafe, mark it **not attempted**. That is
not a failed result.

## Worksheet — one row per condition

Device model: __________  OS/version: __________  App commit: __________

Tester: adult / caregiver / other: __________  Date/time: __________

| Field | Result |
|---|---|
| Movement | |
| Orientation | |
| Device distance (cm) | |
| Mount/camera position | |
| Lighting | |
| Occlusion/angle condition | |
| Calibration completed? | |
| Noise estimate (°) | |
| Comfortable amplitude (°) | |
| Observed signal/noise | |
| Stillness duration | |
| False actions during stillness | |
| Intentional attempts | |
| Correct actions | |
| Missed actions | |
| Extra/duplicate actions | |
| Long holds producing more than one action | |
| Recovery phantom actions | |
| Valid tracking samples | |
| Detection rate (FPS) | |
| Processing delay (ms) | |
| Signal rise to action (ms median) | |
| Dropped frames | |
| Preview/orientation correct? | |
| Overall pass/fail/not attempted | |
| Notes | |

## Interpreting a failure

- **False actions:** repeat calibration, inspect stillness noise, threshold and
  camera stability before changing controller hysteresis.
- **Missed actions with good tracking:** review the threshold only within the
  measured noise-to-comfort range; never require more effort to rescue a test.
- **Low tracking availability:** improve framing, distance, light and occlusion
  before tuning the controller.
- **High processing delay or low FPS:** compare devices, close background apps,
  and investigate capture resolution or model runtime. Do not queue old frames.
- **Movement cannot separate from noise:** try a closer stable camera, another
  comfortable movement, optical-flow research, or an accessible switch or
  wearable fallback.
- **Orientation failure:** stop the run and fix preview/tracking transforms
  before collecting more movement results.

Do not begin game integration while the core fixed-camera run produces false,
missed, duplicate or recovery-generated actions. Record failures as evidence;
do not erase them by repeating only the successful cases.
