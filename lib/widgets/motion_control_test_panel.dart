import 'package:material_ui/material_ui.dart';

import '../calibration/calibration_profile.dart';
import '../calibration/comfortable_movement_calibration.dart';
import '../input_controller/calibrated_motion_controller.dart';
import '../input_controller/motion_input_controller.dart';
import '../l10n/app_localizations.dart';
import '../l10n/localization_extensions.dart';
import '../movement/movement_measurement.dart';
import '../theme/arcade_theme.dart';

class MotionControlTestPanel extends StatefulWidget {
  const MotionControlTestPanel({
    required this.profile,
    required this.reading,
    required this.onRecalibrate,
    this.onPlayGameRequested,
    this.enableSyntheticInput = false,
    this.framesPerSecond = 0,
    this.processingLatency,
    this.droppedFrames = 0,
    super.key,
  });

  final CalibrationProfile profile;
  final MovementMeasurement reading;
  final VoidCallback onRecalibrate;
  final VoidCallback? onPlayGameRequested;
  final bool enableSyntheticInput;
  final double framesPerSecond;
  final Duration? processingLatency;
  final int droppedFrames;

  @override
  State<MotionControlTestPanel> createState() => _MotionControlTestPanelState();
}

class _MotionControlTestPanelState extends State<MotionControlTestPanel> {
  late CalibratedMotionController _controller;
  double? _signal;
  int _actionCount = 0;
  int _readingCount = 0;
  int _validReadingCount = 0;
  MotionInputEventType? _lastEvent;
  Duration? _lastSyntheticTimestamp;
  Duration? _movementOnsetTimestamp;
  final List<Duration> _signalToActionTimes = [];
  final List<Duration> _processingLatencies = [];

  @override
  void initState() {
    super.initState();
    _createController();
    _accept(widget.reading);
  }

  @override
  void didUpdateWidget(MotionControlTestPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.profile, widget.profile)) {
      _createController();
      _accept(widget.reading);
    } else if (!identical(oldWidget.reading, widget.reading)) {
      _accept(widget.reading);
    }
  }

  void _createController() {
    _controller = CalibratedMotionController(profile: widget.profile);
    _signal = null;
    _actionCount = 0;
    _readingCount = 0;
    _validReadingCount = 0;
    _lastEvent = null;
    _lastSyntheticTimestamp = null;
    _movementOnsetTimestamp = null;
    _signalToActionTimes.clear();
    _processingLatencies.clear();
  }

  void _accept(MovementMeasurement reading) {
    _signal = _controller.signalFor(reading);
    _readingCount += 1;
    if (_signal != null) {
      _validReadingCount += 1;
    }
    final processingLatency = widget.processingLatency;
    if (processingLatency != null && !processingLatency.isNegative) {
      _processingLatencies.add(processingLatency);
    }
    final signal = _signal;
    if (signal == null) {
      _movementOnsetTimestamp = null;
    } else if (signal < widget.profile.noiseFloorDegrees) {
      _movementOnsetTimestamp = null;
    } else if (_movementOnsetTimestamp == null &&
        _controller.actionState == MotionActionState.released) {
      _movementOnsetTimestamp = reading.timestamp;
    }

    final events = _controller.accept(reading);
    for (final event in events) {
      if (event.type == MotionInputEventType.primaryAction) {
        _actionCount += 1;
        final movementOnset = _movementOnsetTimestamp;
        if (movementOnset != null && event.timestamp >= movementOnset) {
          _signalToActionTimes.add(event.timestamp - movementOnset);
        }
      } else if (event.type == MotionInputEventType.trackingLost) {
        _movementOnsetTimestamp = null;
      }
      _lastEvent = event.type;
    }
  }

  void _injectSignal(double signal) {
    final direction = widget.profile.direction;
    final rawValue = direction == CalibrationDirection.increasingFlexion
        ? widget.profile.baselineDegrees + signal
        : widget.profile.baselineDegrees - signal;
    final reading = _SyntheticMovementReading(
      timestamp: _nextSyntheticTimestamp(),
      valueDegrees: rawValue,
    );
    setState(() => _accept(reading));
  }

  Duration _nextSyntheticTimestamp() {
    final readingTimestamp = widget.reading.timestamp;
    final previous = _lastSyntheticTimestamp;
    final base = previous != null && previous > readingTimestamp
        ? previous
        : readingTimestamp;
    final next = base + const Duration(milliseconds: 1);
    _lastSyntheticTimestamp = next;
    return next;
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final trackingLost = _controller.trackingState == MotionTrackingState.lost;
    final pressed = _controller.actionState == MotionActionState.pressed;
    final armed = _controller.isArmed;
    final (status, instruction, accent) = trackingLost
        ? (
            localizations.controlStatusTrackingPaused,
            localizations.controlInstructionReposition(
              localizations.movementTrackingSubjectFor(
                widget.profile.movementType,
              ),
            ),
            ArcadeColors.softPink,
          )
        : pressed
            ? (
                localizations.controlStatusActionPressed,
                localizations.controlInstructionReturnComfortably,
                ArcadeColors.arcadeYellow,
              )
            : !armed
                ? (
                    localizations.controlStatusReturnToRest,
                    localizations.controlInstructionWillArm,
                    ArcadeColors.lavender,
                  )
                : (
                    localizations.controlStatusReady,
                    localizations.movementReadyInstructionFor(
                      widget.profile.movementType,
                    ),
                    ArcadeColors.electricCyan,
                  );

    return Semantics(
      container: true,
      liveRegion: true,
      label: localizations.controlTestSemantics(
        status,
        _actionCount,
        instruction,
      ),
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                localizations.controlTestTitle,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 6),
              Text(localizations.controlTestDescription),
              const SizedBox(height: 20),
              LayoutBuilder(
                builder: (context, constraints) {
                  final target = _ControlTarget(
                    status: status,
                    accent: accent,
                    pressed: pressed,
                  );
                  final details = _ControlDetails(
                    instruction: instruction,
                    signal: _signal,
                    activationThreshold: _controller.activationThreshold,
                    releaseThreshold: _controller.releaseThreshold,
                    actionCount: _actionCount,
                    trackingLost: trackingLost,
                    lastEvent: _lastEvent,
                  );
                  if (constraints.maxWidth >= 680) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(child: target),
                        const SizedBox(width: 24),
                        Expanded(child: details),
                      ],
                    );
                  }
                  return Column(
                    children: [target, const SizedBox(height: 20), details],
                  );
                },
              ),
              if (widget.enableSyntheticInput) ...[
                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 8),
                Text(
                  localizations.developerTestInput,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilledButton.tonalIcon(
                      onPressed: () =>
                          _injectSignal(_controller.activationThreshold + 1),
                      icon: const Icon(Icons.arrow_upward),
                      label: Text(localizations.testPress),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => _injectSignal(0),
                      icon: const Icon(Icons.arrow_downward),
                      label: Text(localizations.testRelease),
                    ),
                  ],
                ),
              ],
              if (widget.onPlayGameRequested != null) ...[
                const SizedBox(height: 20),
                FilledButton.icon(
                  key: const Key('play-game-with-motion-control'),
                  onPressed: widget.onPlayGameRequested,
                  icon: const Icon(Icons.rocket_launch_rounded),
                  label: Text(localizations.chooseGamesWithControl),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(64),
                    textStyle: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              ExpansionTile(
                tilePadding: EdgeInsets.zero,
                childrenPadding: const EdgeInsets.only(bottom: 8),
                title: Text(
                  localizations.validationDetails,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(localizations.caregiverEngineeringChecks),
                children: [
                  _ValidationDetails(
                    validReadingCount: _validReadingCount,
                    readingCount: _readingCount,
                    framesPerSecond: widget.framesPerSecond,
                    processingLatency: _medianDuration(_processingLatencies),
                    droppedFrames: widget.droppedFrames,
                    signalToActionTime: _medianSignalToActionTime,
                    signalToNoiseRatio: _signalToNoiseRatio,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: widget.onRecalibrate,
                icon: const Icon(Icons.restart_alt),
                label: Text(localizations.recalibrate),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Duration? get _medianSignalToActionTime {
    return _medianDuration(_signalToActionTimes);
  }

  Duration? _medianDuration(List<Duration> values) {
    if (values.isEmpty) {
      return null;
    }
    final microseconds =
        values.map((duration) => duration.inMicroseconds).toList()..sort();
    final middle = microseconds.length ~/ 2;
    if (microseconds.length.isOdd) {
      return Duration(microseconds: microseconds[middle]);
    }
    return Duration(
      microseconds: (microseconds[middle - 1] + microseconds[middle]) ~/ 2,
    );
  }

  double? get _signalToNoiseRatio {
    final noise = widget.profile.noiseEstimateDegrees;
    if (!noise.isFinite || noise <= 0) {
      return null;
    }
    return widget.profile.comfortableAmplitudeDegrees / noise;
  }
}

class _ControlTarget extends StatelessWidget {
  const _ControlTarget({
    required this.status,
    required this.accent,
    required this.pressed,
  });

  final String status;
  final Color accent;
  final bool pressed;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 230,
        height: 230,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: pressed ? accent : ArcadeColors.background,
          border: Border.all(color: accent, width: 8),
        ),
        alignment: Alignment.center,
        child: Text(
          status,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: pressed ? ArcadeColors.background : accent,
                fontWeight: FontWeight.w900,
              ),
        ),
      ),
    );
  }
}

class _ControlDetails extends StatelessWidget {
  const _ControlDetails({
    required this.instruction,
    required this.signal,
    required this.activationThreshold,
    required this.releaseThreshold,
    required this.actionCount,
    required this.trackingLost,
    required this.lastEvent,
  });

  final String instruction;
  final double? signal;
  final double activationThreshold;
  final double releaseThreshold;
  final int actionCount;
  final bool trackingLost;
  final MotionInputEventType? lastEvent;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final measurement = signal == null
        ? localizations.unavailable
        : localizations.movementTowardAction(
            localizations.formatNumber(signal!),
          );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          instruction,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        _DetailRow(
          label: localizations.trackingLabel,
          value: trackingLost
              ? localizations.trackingLost
              : localizations.trackingReady,
        ),
        _DetailRow(label: localizations.movementLabel, value: measurement),
        _DetailRow(
          label: localizations.pressThreshold,
          value: '${localizations.formatNumber(activationThreshold)}°',
        ),
        _DetailRow(
          label: localizations.releaseThreshold,
          value: '${localizations.formatNumber(releaseThreshold)}°',
        ),
        _DetailRow(
          label: localizations.actionsLabel,
          value: '$actionCount',
        ),
        if (lastEvent != null)
          _DetailRow(
            label: localizations.lastEvent,
            value: localizations.motionEventLabelFor(lastEvent!),
          ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Text(label)),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

class _ValidationDetails extends StatelessWidget {
  const _ValidationDetails({
    required this.validReadingCount,
    required this.readingCount,
    required this.framesPerSecond,
    required this.processingLatency,
    required this.droppedFrames,
    required this.signalToActionTime,
    required this.signalToNoiseRatio,
  });

  final int validReadingCount;
  final int readingCount;
  final double framesPerSecond;
  final Duration? processingLatency;
  final int droppedFrames;
  final Duration? signalToActionTime;
  final double? signalToNoiseRatio;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final validPercent = readingCount == 0
        ? 0
        : (validReadingCount * 100 / readingCount).round();
    final latency = processingLatency;
    final actionTime = signalToActionTime;
    final ratio = signalToNoiseRatio;
    return Semantics(
      container: true,
      label: localizations.caregiverValidationSemantics,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _DetailRow(
            label: localizations.validTrackingSamples,
            value: localizations.validTrackingSamplesValue(
              validReadingCount,
              readingCount,
              validPercent,
            ),
          ),
          _DetailRow(
            label: localizations.detectionRate,
            value: localizations.framesPerSecondValue(
              localizations.formatNumber(framesPerSecond),
            ),
          ),
          _DetailRow(
            label: localizations.processingDelayMedian,
            value: latency == null
                ? localizations.notAvailable
                : localizations.millisecondsValue(latency.inMilliseconds),
          ),
          _DetailRow(
            label: localizations.droppedFrames,
            value: '$droppedFrames',
          ),
          _DetailRow(
            label: localizations.observedSignalNoise,
            value: ratio == null
                ? localizations.notAvailable
                : localizations.ratioValue(
                    localizations.formatNumber(ratio),
                  ),
          ),
          _DetailRow(
            label: localizations.signalRiseToAction,
            value: actionTime == null
                ? localizations.completeAnAction
                : localizations.millisecondsMedianValue(
                    actionTime.inMilliseconds,
                  ),
          ),
          const SizedBox(height: 8),
          Text(localizations.engineeringDiagnosticsNote),
        ],
      ),
    );
  }
}

class _SyntheticMovementReading implements MovementMeasurement {
  const _SyntheticMovementReading({
    required this.timestamp,
    required this.valueDegrees,
  });

  @override
  final Duration timestamp;
  @override
  final double valueDegrees;

  @override
  bool get isValid => true;
}
