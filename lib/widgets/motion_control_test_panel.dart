import 'package:material_ui/material_ui.dart';

import '../calibration/calibration_profile.dart';
import '../calibration/comfortable_movement_calibration.dart';
import '../input_controller/calibrated_motion_controller.dart';
import '../input_controller/motion_input_controller.dart';
import '../movement/movement_measurement.dart';
import '../theme/arcade_theme.dart';

class MotionControlTestPanel extends StatefulWidget {
  const MotionControlTestPanel({
    required this.profile,
    required this.reading,
    required this.onRecalibrate,
    this.enableSyntheticInput = false,
    super.key,
  });

  final CalibrationProfile profile;
  final MovementMeasurement reading;
  final VoidCallback onRecalibrate;
  final bool enableSyntheticInput;

  @override
  State<MotionControlTestPanel> createState() => _MotionControlTestPanelState();
}

class _MotionControlTestPanelState extends State<MotionControlTestPanel> {
  late CalibratedMotionController _controller;
  double? _signal;
  int _actionCount = 0;
  MotionInputEventType? _lastEvent;
  Duration? _lastSyntheticTimestamp;

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
    _lastEvent = null;
    _lastSyntheticTimestamp = null;
  }

  void _accept(MovementMeasurement reading) {
    _signal = _controller.signalFor(reading);
    final events = _controller.accept(reading);
    for (final event in events) {
      if (event.type == MotionInputEventType.primaryAction) {
        _actionCount += 1;
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
    final trackingLost = _controller.trackingState == MotionTrackingState.lost;
    final pressed = _controller.actionState == MotionActionState.pressed;
    final armed = _controller.isArmed;
    final (status, instruction, accent) = trackingLost
        ? (
            'TRACKING PAUSED',
            'Reposition the ${widget.profile.movementType.trackingSubject} to continue.',
            ArcadeColors.softPink,
          )
        : pressed
        ? (
            'ACTION PRESSED',
            'Return comfortably to rest before moving again.',
            ArcadeColors.arcadeYellow,
          )
        : !armed
        ? (
            'RETURN TO REST',
            'The control will arm after the movement returns to rest.',
            ArcadeColors.lavender,
          )
        : (
            'READY',
            'Make one comfortable ${widget.profile.movementType.shortLabel.toLowerCase()} movement.',
            ArcadeColors.electricCyan,
          );

    return Semantics(
      container: true,
      liveRegion: true,
      label:
          'Control test. $status. Actions detected $_actionCount. $instruction',
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Control Test',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              const Text('One comfortable movement should create one action.'),
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
                const Text(
                  'Developer test input',
                  style: TextStyle(fontWeight: FontWeight.bold),
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
                      label: const Text('Test press'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => _injectSignal(0),
                      icon: const Icon(Icons.arrow_downward),
                      label: const Text('Test release'),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: widget.onRecalibrate,
                icon: const Icon(Icons.restart_alt),
                label: const Text('Recalibrate'),
              ),
            ],
          ),
        ),
      ),
    );
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
    final measurement = signal == null
        ? 'Unavailable'
        : '${signal!.toStringAsFixed(1)}° toward action';
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
        _DetailRow(label: 'Tracking', value: trackingLost ? 'Lost' : 'Ready'),
        _DetailRow(label: 'Movement', value: measurement),
        _DetailRow(
          label: 'Press threshold',
          value: '${activationThreshold.toStringAsFixed(1)}°',
        ),
        _DetailRow(
          label: 'Release threshold',
          value: '${releaseThreshold.toStringAsFixed(1)}°',
        ),
        _DetailRow(label: 'Actions', value: '$actionCount'),
        if (lastEvent != null)
          _DetailRow(label: 'Last event', value: lastEvent!.name),
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
