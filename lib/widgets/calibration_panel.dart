import 'package:material_ui/material_ui.dart';

import '../calibration/baseline_calibration.dart';
import '../calibration/calibration_profile.dart';
import '../calibration/comfortable_movement_calibration.dart';
import '../l10n/app_localizations.dart';
import '../l10n/localization_extensions.dart';
import '../movement/movement_measurement.dart';
import 'joybit_companion.dart';

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
    required this.movementType,
    required this.setupContext,
    this.now,
    this.onControlTestRequested,
    super.key,
  });

  final MovementMeasurement reading;
  final CalibrationMovementType movementType;
  final CalibrationSetupContext setupContext;
  final DateTime Function()? now;
  final ValueChanged<CalibrationProfile>? onControlTestRequested;

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

  void _acceptReading(MovementMeasurement reading) {
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
      _baselineSession = BaselineCalibrationSession(
        movementType: widget.movementType,
      );
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
    final localizations = AppLocalizations.of(context);
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
                        localizations.calibrationTitle,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                    _CurrentAngle(
                      reading: widget.reading,
                      movementType: widget.movementType,
                    ),
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
    final localizations = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(localizations.calibrationIntroduction),
        const SizedBox(height: 8),
        Text(
          localizations.selectedMovement(
            localizations.movementLabelFor(widget.movementType),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          localizations.movementSelectionDescriptionFor(widget.movementType),
        ),
        if (!widget.reading.isValid) ...[
          const SizedBox(height: 8),
          Text(
            localizations.movementPositioningHintFor(widget.movementType),
          ),
        ],
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: widget.reading.isValid ? _startBaseline : null,
          icon: const Icon(Icons.play_arrow),
          label: Text(localizations.startRestMeasurement),
        ),
      ],
    );
  }

  Widget _buildBaseline() {
    final localizations = AppLocalizations.of(context);
    final assessment = _baselineAssessment;
    final needsRetry =
        assessment?.status == BaselineCalibrationStatus.signalTooVariable;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          localizations.calibrationStepOne,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        Text(
          localizations.baselineAssessmentMessage(
            widget.movementType,
            assessment,
          ),
        ),
        if (assessment != null) ...[
          const SizedBox(height: 8),
          Text(localizations.stableSamples(assessment.stableSampleCount)),
        ],
        if (needsRetry) ...[
          const SizedBox(height: 12),
          FilledButton.tonalIcon(
            onPressed: _startBaseline,
            icon: const Icon(Icons.refresh),
            label: Text(localizations.retryRestMeasurement),
          ),
        ],
      ],
    );
  }

  Widget _buildMovementReady() {
    final localizations = AppLocalizations.of(context);
    final baseline = _baseline!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          localizations.restMeasurementComplete,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        Text(
          localizations.restEstimateNext(
            localizations.formatNumber(baseline.baselineDegrees),
            localizations.movementPromptFor(widget.movementType),
          ),
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: widget.reading.isValid ? _startMovement : null,
          icon: const Icon(Icons.pan_tool_alt_outlined),
          label: Text(localizations.measureComfortableMovement),
        ),
      ],
    );
  }

  Widget _buildMovement() {
    final localizations = AppLocalizations.of(context);
    final assessment = _movementAssessment;
    final notSeparated = assessment?.status ==
        ComfortableMovementStatus.movementNotSeparatedFromNoise;
    final canUseManual = notSeparated &&
        assessment?.observedAmplitudeDegrees != null &&
        assessment?.noiseFloorDegrees != null &&
        assessment!.observedAmplitudeDegrees! > assessment.noiseFloorDegrees!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          localizations.calibrationStepTwo,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        Text(
          localizations.comfortableMovementAssessmentMessage(
            widget.movementType,
            assessment,
          ),
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
                label: Text(localizations.retryMovement),
              ),
              if (canUseManual)
                OutlinedButton.icon(
                  onPressed: _useManualFallback,
                  icon: const Icon(Icons.tune),
                  label: Text(localizations.reviewManualSetting),
                ),
            ],
          ),
          if (!canUseManual) ...[
            const SizedBox(height: 8),
            Text(localizations.manualThresholdUnavailable),
          ],
        ],
      ],
    );
  }

  Widget _buildReview(BuildContext context) {
    final localizations = AppLocalizations.of(context);
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
        Text(
          localizations.caregiverReview,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        Text(localizations.caregiverReviewInstructions),
        const SizedBox(height: 12),
        Text(localizations.movementDirection),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ChoiceChip(
              label: Text(
                localizations.movementIncreasingDirectionFor(
                  widget.movementType,
                ),
              ),
              selected: _direction == CalibrationDirection.increasingFlexion,
              onSelected: (_) {
                setState(() {
                  _direction = CalibrationDirection.increasingFlexion;
                  _validation = null;
                });
              },
            ),
            ChoiceChip(
              label: Text(
                localizations.movementDecreasingDirectionFor(
                  widget.movementType,
                ),
              ),
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
          localizations.sensitivityFromRest(
            localizations.formatNumber(_thresholdOffsetDegrees),
          ),
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
          label: '${localizations.formatNumber(_thresholdOffsetDegrees)}°',
          onChanged: (value) {
            setState(() {
              _thresholdOffsetDegrees = value;
              _validation = null;
            });
          },
        ),
        Text(
          localizations.measuredNoiseAndMovement(
            localizations.formatNumber(editor.noiseFloorDegrees),
            localizations.formatNumber(editor.comfortableAmplitudeDegrees),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          localizations.calibrationValidationMessage(
            (_validation ?? validation).status,
            noiseFloorDegrees: editor.noiseFloorDegrees,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilledButton.icon(
              onPressed: validation.isReliable ? _confirmCalibration : null,
              icon: const Icon(Icons.check),
              label: Text(localizations.useThisSetting),
            ),
            OutlinedButton.icon(
              onPressed: _startMovement,
              icon: const Icon(Icons.refresh),
              label: Text(localizations.retryMovement),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildComplete() {
    final localizations = AppLocalizations.of(context);
    final profile = _profile!;
    final directionLabel =
        profile.direction == CalibrationDirection.increasingFlexion
            ? localizations.movementIncreasingDirectionFor(widget.movementType)
            : localizations.movementDecreasingDirectionFor(widget.movementType);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          localizations.calibrationReady,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        Text(
          localizations.calibrationDirectionThreshold(
            directionLabel,
            localizations.formatNumber(profile.thresholdOffsetDegrees),
          ),
        ),
        const SizedBox(height: 6),
        Text(localizations.calibrationNotSaved),
        const SizedBox(height: 12),
        JoybitCompanion(
          compact: true,
          message: localizations.calibrationSuccessCompanion,
        ),
        const SizedBox(height: 12),
        if (widget.onControlTestRequested != null) ...[
          FilledButton.icon(
            onPressed: () => widget.onControlTestRequested!(profile),
            icon: const Icon(Icons.play_arrow),
            label: Text(localizations.testThisControl),
          ),
          const SizedBox(height: 8),
        ],
        OutlinedButton.icon(
          onPressed: _startBaseline,
          icon: const Icon(Icons.restart_alt),
          label: Text(localizations.calibrateAgain),
        ),
      ],
    );
  }

  String get _semanticStatus {
    final localizations = AppLocalizations.of(context);
    return switch (_step) {
      _CalibrationStep.ready => localizations.calibrationSemanticReady,
      _CalibrationStep.baseline => _baselineAssessment == null
          ? localizations.calibrationSemanticMeasuringRest
          : localizations.baselineAssessmentMessage(
              widget.movementType,
              _baselineAssessment,
            ),
      _CalibrationStep.movementReady =>
        localizations.calibrationSemanticRestComplete,
      _CalibrationStep.movement => _movementAssessment == null
          ? localizations.calibrationSemanticMeasuringMovement
          : localizations.comfortableMovementAssessmentMessage(
              widget.movementType,
              _movementAssessment,
            ),
      _CalibrationStep.review => localizations.calibrationSemanticReview,
      _CalibrationStep.complete => localizations.calibrationSemanticComplete,
    };
  }
}

class _CurrentAngle extends StatelessWidget {
  const _CurrentAngle({required this.reading, required this.movementType});

  final MovementMeasurement reading;
  final CalibrationMovementType movementType;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final label = reading.isValid ? '~${reading.valueDegrees!.round()}°' : '—';
    return Semantics(
      label: reading.isValid
          ? localizations.currentAngleSemantics(
              localizations.movementLabelFor(movementType),
              label,
            )
          : localizations.currentAngleUnavailableSemantics(
              localizations.movementLabelFor(movementType),
            ),
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
