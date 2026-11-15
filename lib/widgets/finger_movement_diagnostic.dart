import 'package:material_ui/material_ui.dart';

import '../movement/finger_movement_analyzer.dart';

class FingerMovementDiagnostic extends StatelessWidget {
  const FingerMovementDiagnostic({required this.reading, super.key});

  final FingerMovementReading reading;

  @override
  Widget build(BuildContext context) {
    final valueLabel = reading.isValid
        ? '~${reading.flexionDegrees!.round()}°'
        : '—';
    final stateLabel = _stateLabel(reading);
    final detailLabel = reading.isValid
        ? '0° is straight; a larger angle means more bend.'
        : _invalidDetail(reading.validity);
    final colorScheme = Theme.of(context).colorScheme;

    return Semantics(
      container: true,
      label:
          'Index finger flexion diagnostic. $valueLabel. $stateLabel. '
          '$detailLabel',
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
                        'Index finger flexion',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(detailLabel, maxLines: 2),
                      if (reading.isValid) ...[
                        const SizedBox(height: 2),
                        Text(
                          _qualityLabel(reading.quality.quality),
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
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
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

  String _stateLabel(FingerMovementReading reading) {
    if (!reading.isValid) {
      return 'Unavailable';
    }
    return switch (reading.state) {
      FingerMotionState.stationary => 'Steady',
      FingerMotionState.flexing => 'Bending',
      FingerMotionState.extending => 'Straightening',
      FingerMotionState.unavailable => 'Unavailable',
    };
  }

  String _invalidDetail(FingerMovementValidity validity) {
    return switch (validity) {
      FingerMovementValidity.trackingUnavailable =>
        'Waiting for hand tracking to become available.',
      FingerMovementValidity.missingObservation =>
        'Show one hand to measure the index finger.',
      FingerMovementValidity.outOfOrderTimestamp =>
        'Waiting for a current tracking frame.',
      FingerMovementValidity.nonFiniteLandmarks ||
      FingerMovementValidity.degenerateGeometry =>
        'Move the hand fully into view for a stable measurement.',
      FingerMovementValidity.valid => 'Waiting for a measurement.',
    };
  }

  String _qualityLabel(MovementSignalQuality quality) {
    return switch (quality) {
      MovementSignalQuality.good => 'Signal geometry: usable',
      MovementSignalQuality.caution => 'Signal geometry: settling',
      MovementSignalQuality.invalid => 'Signal geometry: unavailable',
    };
  }
}
