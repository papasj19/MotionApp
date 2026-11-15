import 'package:material_ui/material_ui.dart';

import '../calibration/baseline_calibration.dart';
import '../calibration/calibration_profile.dart';
import '../calibration/comfortable_movement_calibration.dart';
import '../movement/finger_movement_analyzer.dart';

enum _CalibrationStep {
  ready,
  baseline,
  movementReady,
  movement,
  review,
  complete,
}

class CalibrationPanel extends StatefulWidget {
  const CalibrationPanel({
    required this.reading,
    required this.setupContext,
    this.now,
    super.key,
  });

  final FingerMovementReading reading;
  final CalibrationSetupContext setupContext;
  final DateTime Function()? now;

  @override
  State<CalibrationPanel> createState() => _CalibrationPanelState();
}

class _CalibrationPanelState extends State<CalibrationPanel> {
  _CalibrationStep _step = _CalibrationStep.ready;
  BaselineCalibrationSession? _baselineSession;
  BaselineCalibrationAssessment? _baselineAssessment;
  CalibrationBaseline? _baseline;
  ComfortableMovementCalibrationSession? _movementSession;
  ComfortableMovementAssessment? _movementAssessment;
  CalibrationProfileEditor? _editor;
  CalibrationDirection _direction = CalibrationDirection.increasingFlexion;
  double _thresholdOffsetDegrees = 0;
  CalibrationValidationResult? _validation;
  CalibrationProfile? _profile;

  @override
  void didUpdateWidget(CalibrationPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.reading, widget.reading)) {
      _acceptReading(widget.reading);
    }
  }

  void _acceptReading(FingerMovementReading reading) {
    switch (_step) {
      case _CalibrationStep.baseline:
        final assessment = _baselineSession!.accept(reading);
        _baselineAssessment = assessment;
        if (assessment.isReady) {
          _baseline = assessment.baseline;
          _step = _CalibrationStep.movementReady;
        }
        return;
      case _CalibrationStep.movement:
        final assessment = _movementSession!.accept(reading);
        _movementAssessment = assessment;
        final recommendation = assessment.recommendation;
        if (assessment.hasReliableRecommendation && recommendation != null) {
          _openEditor(
            CalibrationProfileEditor.fromRecommendation(recommendation),
          );
        }
        return;
      case _CalibrationStep.ready ||
          _CalibrationStep.movementReady ||
          _CalibrationStep.review ||
          _CalibrationStep.complete:
        return;
    }
  }

  void _startBaseline() {
    setState(() {
      _baselineSession = BaselineCalibrationSession();
      _baselineAssessment = null;
      _baseline = null;
      _movementSession = null;
      _movementAssessment = null;
      _editor = null;
      _validation = null;
      _profile = null;
      _step = _CalibrationStep.baseline;
      _acceptReading(widget.reading);
    });
  }

  void _startMovement() {
    final baseline = _baseline;
    if (baseline == null) {
      return;
    }
    setState(() {
      _movementSession = ComfortableMovementCalibrationSession(
        baseline: baseline,
      );
      _movementAssessment = null;
      _editor = null;
      _validation = null;
      _step = _CalibrationStep.movement;
      _acceptReading(widget.reading);
    });
  }

  void _useManualFallback() {
    final baseline = _baseline;
    final assessment = _movementAssessment;
    final direction = assessment?.detectedDirection;
    final amplitude = assessment?.observedAmplitudeDegrees;
    final noiseFloor = assessment?.noiseFloorDegrees;
    if (baseline == null ||
        assessment == null ||
        direction == null ||
        amplitude == null ||
        noiseFloor == null ||
        amplitude <= noiseFloor) {
      return;
    }
    setState(() {
      _openEditor(
        CalibrationProfileEditor.manualFallback(
          baseline: baseline,
          direction: direction,
          comfortableAmplitudeDegrees: amplitude,
          noiseFloorDegrees: noiseFloor,
          sampleTimestamp: assessment.timestamp,
        ),
      );
    });
  }

  void _openEditor(CalibrationProfileEditor editor) {
    _editor = editor;
    _direction = editor.initialDirection;
    _thresholdOffsetDegrees = editor.initialThresholdOffsetDegrees;
    _validation = null;
    _step = _CalibrationStep.review;
  }

  void _confirmCalibration() {
    final editor = _editor;
    if (editor == null) {
      return;
    }
    final validation = editor.validate(
      direction: _direction,
      thresholdOffsetDegrees: _thresholdOffsetDegrees,
      completedAt: (widget.now ?? DateTime.now)(),
      setupContext: widget.setupContext,
    );
    setState(() {
      _validation = validation;
      if (validation.isReliable) {
        _profile = validation.profile;
        _step = _CalibrationStep.complete;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          container: true,
          liveRegion: true,
          label: _semanticStatus,
          child: const SizedBox.shrink(),
        ),
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(Icons.tune, color: colorScheme.primary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Comfortable movement calibration',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                    _CurrentAngle(reading: widget.reading),
                  ],
                ),
                const SizedBox(height: 12),
                _buildStep(context),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStep(BuildContext context) {
    return switch (_step) {
      _CalibrationStep.ready => _buildReady(),
      _CalibrationStep.baseline => _buildBaseline(),
      _CalibrationStep.movementReady => _buildMovementReady(),
      _CalibrationStep.movement => _buildMovement(),
      _CalibrationStep.review => _buildReview(context),
      _CalibrationStep.complete => _buildComplete(),
    };
  }

  Widget _buildReady() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'A caregiver can guide two short steps. Keep every movement '
          'comfortable—never push for a maximum range.',
        ),
        const SizedBox(height: 8),
        const Text('Movement available: index-finger bend and straighten.'),
        if (!widget.reading.isValid) ...[
          const SizedBox(height: 8),
          const Text('Show one hand clearly to enable calibration.'),
        ],
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: widget.reading.isValid ? _startBaseline : null,
          icon: const Icon(Icons.play_arrow),
          label: const Text('Start rest measurement'),
        ),
      ],
    );
  }

  Widget _buildBaseline() {
    final assessment = _baselineAssessment;
    final needsRetry =
        assessment?.status == BaselineCalibrationStatus.signalTooVariable;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Step 1 of 2 • Rest comfortably',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        Text(
          assessment?.message ??
              'Keep the hand comfortably at rest while the baseline is measured.',
        ),
        if (assessment != null) ...[
          const SizedBox(height: 8),
          Text('Stable samples: ${assessment.stableSampleCount}'),
        ],
        if (needsRetry) ...[
          const SizedBox(height: 12),
          FilledButton.tonalIcon(
            onPressed: _startBaseline,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry rest measurement'),
          ),
        ],
      ],
    );
  }

  Widget _buildMovementReady() {
    final baseline = _baseline!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Rest measurement complete',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        Text(
          'Rest estimate: ~${baseline.baselineDegrees.round()}°. '
          'Next, make one comfortable bend or straighten movement.',
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: widget.reading.isValid ? _startMovement : null,
          icon: const Icon(Icons.pan_tool_alt_outlined),
          label: const Text('Measure comfortable movement'),
        ),
      ],
    );
  }

  Widget _buildMovement() {
    final assessment = _movementAssessment;
    final notSeparated =
        assessment?.status ==
        ComfortableMovementStatus.movementNotSeparatedFromNoise;
    final canUseManual =
        notSeparated &&
        assessment?.observedAmplitudeDegrees != null &&
        assessment?.noiseFloorDegrees != null &&
        assessment!.observedAmplitudeDegrees! > assessment.noiseFloorDegrees!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Step 2 of 2 • Move comfortably',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        Text(
          assessment?.message ??
              'Make one comfortable movement when ready. Do not push farther.',
        ),
        if (notSeparated) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.tonalIcon(
                onPressed: _startMovement,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry movement'),
              ),
              if (canUseManual)
                OutlinedButton.icon(
                  onPressed: _useManualFallback,
                  icon: const Icon(Icons.tune),
                  label: const Text('Review manual setting'),
                ),
            ],
          ),
          if (!canUseManual) ...[
            const SizedBox(height: 8),
            const Text(
              'A reliable manual threshold is not available because the '
              'movement overlaps the measured noise. Retrying is safest.',
            ),
          ],
        ],
      ],
    );
  }

  Widget _buildReview(BuildContext context) {
    final editor = _editor!;
    final validation = editor.validate(
      direction: _direction,
      thresholdOffsetDegrees: _thresholdOffsetDegrees,
      completedAt: (widget.now ?? DateTime.now)(),
      setupContext: widget.setupContext,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Caregiver review',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        const Text(
          'Choose the direction and sensitivity. The threshold cannot go '
          'below measured noise or beyond the observed comfortable movement.',
        ),
        const SizedBox(height: 12),
        const Text('Movement direction'),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ChoiceChip(
              label: const Text('More bend'),
              selected: _direction == CalibrationDirection.increasingFlexion,
              onSelected: (_) {
                setState(() {
                  _direction = CalibrationDirection.increasingFlexion;
                  _validation = null;
                });
              },
            ),
            ChoiceChip(
              label: const Text('More straight'),
              selected: _direction == CalibrationDirection.decreasingFlexion,
              onSelected: (_) {
                setState(() {
                  _direction = CalibrationDirection.decreasingFlexion;
                  _validation = null;
                });
              },
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          'Sensitivity: ~${_thresholdOffsetDegrees.toStringAsFixed(1)}° from rest',
        ),
        Slider(
          value: _thresholdOffsetDegrees
              .clamp(
                editor.minimumThresholdOffsetDegrees,
                editor.maximumThresholdOffsetDegrees,
              )
              .toDouble(),
          min: editor.minimumThresholdOffsetDegrees,
          max: editor.maximumThresholdOffsetDegrees,
          label: '${_thresholdOffsetDegrees.toStringAsFixed(1)}°',
          onChanged: (value) {
            setState(() {
              _thresholdOffsetDegrees = value;
              _validation = null;
            });
          },
        ),
        Text(
          'Measured noise floor: ~${editor.noiseFloorDegrees.toStringAsFixed(1)}°. '
          'Observed comfortable movement: '
          '~${editor.comfortableAmplitudeDegrees.toStringAsFixed(1)}°.',
        ),
        const SizedBox(height: 8),
        Text(_validation?.message ?? validation.message),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilledButton.icon(
              onPressed: validation.isReliable ? _confirmCalibration : null,
              icon: const Icon(Icons.check),
              label: const Text('Use this setting'),
            ),
            OutlinedButton.icon(
              onPressed: _startMovement,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry movement'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildComplete() {
    final profile = _profile!;
    final directionLabel =
        profile.direction == CalibrationDirection.increasingFlexion
        ? 'more bend'
        : 'more straight';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Calibration ready',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        Text(
          'Direction: $directionLabel. Threshold: '
          '~${profile.thresholdOffsetDegrees.toStringAsFixed(1)}° from rest.',
        ),
        const SizedBox(height: 6),
        const Text(
          'This calibration is not saved and clears when you leave this screen.',
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: _startBaseline,
          icon: const Icon(Icons.restart_alt),
          label: const Text('Calibrate again'),
        ),
      ],
    );
  }

  String get _semanticStatus => switch (_step) {
    _CalibrationStep.ready => 'Calibration ready to begin.',
    _CalibrationStep.baseline =>
      _baselineAssessment?.message ?? 'Measuring comfortable rest position.',
    _CalibrationStep.movementReady =>
      'Rest measurement complete. Comfortable movement is next.',
    _CalibrationStep.movement =>
      _movementAssessment?.message ?? 'Measuring one comfortable movement.',
    _CalibrationStep.review => 'Calibration is ready for caregiver review.',
    _CalibrationStep.complete => 'Calibration complete. It is not saved.',
  };
}

class _CurrentAngle extends StatelessWidget {
  const _CurrentAngle({required this.reading});

  final FingerMovementReading reading;

  @override
  Widget build(BuildContext context) {
    final label = reading.isValid
        ? '~${reading.flexionDegrees!.round()}°'
        : '—';
    return Semantics(
      label: reading.isValid
          ? 'Current estimated finger angle $label'
          : 'Current finger angle unavailable',
      child: ExcludeSemantics(
        child: Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
