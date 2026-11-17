import 'package:material_ui/material_ui.dart';

import '../l10n/app_localizations.dart';
import '../movement/finger_movement_analyzer.dart';

class FingerMovementDiagnostic extends StatelessWidget {
  const FingerMovementDiagnostic({required this.reading, super.key});

  final FingerMovementReading reading;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final valueLabel =
        reading.isValid ? '~${reading.flexionDegrees!.round()}°' : '—';
    final stateLabel = _stateLabel(localizations, reading);
    final detailLabel = reading.isValid
        ? localizations.fingerAngleExplanation
        : _invalidDetail(localizations, reading.validity);
    final colorScheme = Theme.of(context).colorScheme;

    return Semantics(
      container: true,
      label: localizations.fingerDiagnosticSemantics(
        valueLabel,
        stateLabel,
        detailLabel,
      ),
      child: ExcludeSemantics(
        child: Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(Icons.show_chart, color: colorScheme.primary, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        localizations.fingerFlexionTitle,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 2),
                      Text(detailLabel, maxLines: 2),
                      if (reading.isValid) ...[
                        const SizedBox(height: 2),
                        Text(
                          _qualityLabel(
                            localizations,
                            reading.quality.quality,
                          ),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      valueLabel,
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                color: colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                    ),
                    Text(
                      stateLabel,
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _stateLabel(
    AppLocalizations localizations,
    FingerMovementReading reading,
  ) {
    if (!reading.isValid) {
      return localizations.unavailable;
    }
    return switch (reading.state) {
      FingerMotionState.stationary => localizations.fingerStateSteady,
      FingerMotionState.flexing => localizations.fingerStateBending,
      FingerMotionState.extending => localizations.fingerStateStraightening,
      FingerMotionState.unavailable => localizations.unavailable,
    };
  }

  String _invalidDetail(
    AppLocalizations localizations,
    FingerMovementValidity validity,
  ) {
    return switch (validity) {
      FingerMovementValidity.trackingUnavailable =>
        localizations.fingerWaitingTracking,
      FingerMovementValidity.missingObservation => localizations.fingerShowHand,
      FingerMovementValidity.outOfOrderTimestamp =>
        localizations.fingerWaitingCurrentFrame,
      FingerMovementValidity.nonFiniteLandmarks ||
      FingerMovementValidity.degenerateGeometry =>
        localizations.fingerMoveFullyIntoView,
      FingerMovementValidity.valid => localizations.fingerWaitingMeasurement,
    };
  }

  String _qualityLabel(
    AppLocalizations localizations,
    MovementSignalQuality quality,
  ) {
    return switch (quality) {
      MovementSignalQuality.good => localizations.signalGeometryUsable,
      MovementSignalQuality.caution => localizations.signalGeometrySettling,
      MovementSignalQuality.invalid => localizations.signalGeometryUnavailable,
    };
  }
}
