// ignore_for_file: deprecated_member_use

// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'Adaptive Motion Arcade';

  @override
  String get languageSelectionLabel => 'Idioma de la aplicación';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageSpanish => 'Español';

  @override
  String get homeTitleLineOne => 'ADAPTIVE MOTION';

  @override
  String get homeTitleLineTwo => 'ARCADE';

  @override
  String get homeCompactWelcome => '¿Listo para jugar a tu manera?';

  @override
  String get homeWelcome =>
      '¡Te damos la bienvenida! Elige cómo quieres jugar hoy.';

  @override
  String get homeQuickPlay => 'Juego rápido';

  @override
  String get homeQuickPlayDescription => 'Juega sin perfil';

  @override
  String get homeSchool => 'Escuela';

  @override
  String get homeSchoolDescription =>
      'Se definirá tras hablar con el profesorado';

  @override
  String optionSemantics(String label, String description) {
    return '$label. $description.';
  }

  @override
  String get arcadeLobbyTooltip => 'Inicio del arcade';

  @override
  String get quickPlayTitle => 'Juego rápido';

  @override
  String get quickPlayChooseMovementStep => 'PASO 1 • ELIGE EL MOVIMIENTO';

  @override
  String get quickPlayComfortQuestion =>
      '¿Qué movimiento te resulta cómodo hoy?';

  @override
  String get quickPlayCompanionPrompt =>
      'Elige un movimiento. Mediremos qué te resulta cómodo hoy.';

  @override
  String get movementHeadLabel => 'Cabeza';

  @override
  String get movementHeadDescription =>
      'Inclínala a la izquierda o a la derecha';

  @override
  String get movementWristLabel => 'Mano / Muñeca';

  @override
  String get movementWristDescription => 'Dobla la muñeca';

  @override
  String get movementFingerLabel => 'Dedo';

  @override
  String get movementFingerDescription => 'Dobla el dedo índice';

  @override
  String get movementLegLabel => 'Pierna';

  @override
  String get movementLegDescription => 'Disponible en una versión futura';

  @override
  String movementTileSemantics(String label, String description) {
    return '$label. $description.';
  }

  @override
  String get comingLater => 'PRÓXIMAMENTE';

  @override
  String get quickPlayComfortNote =>
      'Elige lo que te resulte cómodo ahora. El siguiente paso mide tu movimiento; nunca te pedirá que te estires más.';

  @override
  String movementShortLabel(String movement) {
    String _temp0 = intl.Intl.selectLogic(movement, {
      'finger': 'Dedo',
      'wrist': 'Muñeca',
      'head': 'Cabeza',
      'other': 'Movimiento',
    });
    return '$_temp0';
  }

  @override
  String movementSelectionDescription(String movement) {
    String _temp0 = intl.Intl.selectLogic(movement, {
      'finger': 'Dobla y estira el dedo índice con comodidad.',
      'wrist': 'Dobla la muñeca cómodamente en cualquier dirección.',
      'head': 'Inclina la cabeza cómodamente hacia la izquierda o la derecha.',
      'other': 'Muévete con comodidad.',
    });
    return '$_temp0';
  }

  @override
  String movementPositioningHint(String movement) {
    String _temp0 = intl.Intl.selectLogic(movement, {
      'finger': 'Muestra claramente una mano, incluido todo el dedo índice.',
      'wrist': 'Muestra una mano, la muñeca y el antebrazo hasta el codo.',
      'head': 'Centra la cara y mantén visibles ambos ojos.',
      'other': 'Coloca toda la zona que se seguirá dentro de la imagen.',
    });
    return '$_temp0';
  }

  @override
  String movementRestPrompt(String movement) {
    String _temp0 = intl.Intl.selectLogic(movement, {
      'finger':
          'Mantén la mano en una posición de reposo cómoda mientras se mide la referencia.',
      'wrist':
          'Mantén la muñeca en una posición de reposo cómoda mientras se mide la referencia.',
      'head':
          'Mantén la cabeza en una posición de reposo cómoda mientras se mide la referencia.',
      'other': 'Descansa cómodamente mientras se mide la referencia.',
    });
    return '$_temp0';
  }

  @override
  String movementPrompt(String movement) {
    String _temp0 = intl.Intl.selectLogic(movement, {
      'finger': 'Dobla o estira el dedo una vez, con comodidad.',
      'wrist': 'Dobla la muñeca una vez en cualquier dirección, con comodidad.',
      'head':
          'Inclina la cabeza una vez hacia la izquierda o la derecha, con comodidad.',
      'other': 'Haz un movimiento cómodo.',
    });
    return '$_temp0';
  }

  @override
  String movementIncreasingDirection(String movement) {
    String _temp0 = intl.Intl.selectLogic(movement, {
      'finger': 'Doblar más',
      'wrist': 'Doblar más la muñeca',
      'head': 'Inclinar a la izquierda',
      'other': 'Primera dirección',
    });
    return '$_temp0';
  }

  @override
  String movementDecreasingDirection(String movement) {
    String _temp0 = intl.Intl.selectLogic(movement, {
      'finger': 'Estirar más',
      'wrist': 'Enderezar más',
      'head': 'Inclinar a la derecha',
      'other': 'Otra dirección',
    });
    return '$_temp0';
  }

  @override
  String movementTrackingSubject(String movement) {
    String _temp0 = intl.Intl.selectLogic(movement, {
      'finger': 'mano',
      'wrist': 'mano',
      'head': 'cara',
      'other': 'zona seguida',
    });
    return '$_temp0';
  }

  @override
  String movementReadyInstruction(String movement) {
    String _temp0 = intl.Intl.selectLogic(movement, {
      'finger': 'Haz un movimiento cómodo con el dedo.',
      'wrist': 'Haz un movimiento cómodo con la muñeca.',
      'head': 'Haz un movimiento cómodo con la cabeza.',
      'other': 'Haz un movimiento cómodo.',
    });
    return '$_temp0';
  }

  @override
  String calibrationScreenTitle(String movement) {
    return 'Calibración: $movement';
  }

  @override
  String controlTestScreenTitle(String movement) {
    return 'Prueba de control: $movement';
  }

  @override
  String get changeMovement => 'Cambiar';

  @override
  String get livePreviewPrivacy =>
      'Solo se muestra la imagen en directo. No se graba ni se guarda nada.';

  @override
  String get chooseMovementTitle => 'Elige un movimiento';

  @override
  String get chooseMovementQuestion =>
      '¿Qué movimiento cómodo controlará el juego?';

  @override
  String get chooseMovementHelp =>
      'Una persona adulta puede elegir la opción más clara. La calibración mide el movimiento cómodo actual de quien juega y nunca pide el rango máximo. El control con la cabeza solo usa la inclinación a izquierda o derecha; no utiliza parpadeos ni expresiones faciales.';

  @override
  String get preparingMovementTracking =>
      'Preparando el seguimiento del movimiento';

  @override
  String get trackingPaused => 'Seguimiento en pausa';

  @override
  String get startingTracking => 'Iniciando el seguimiento…';

  @override
  String get trackingUnavailable => 'Seguimiento no disponible';

  @override
  String get movementTrackingPausedSemantics =>
      'El seguimiento del movimiento está en pausa.';

  @override
  String get movementTrackingStartingSemantics =>
      'Se está iniciando el seguimiento del movimiento.';

  @override
  String movementTrackingActiveSemantics(String movement) {
    return 'Se está siguiendo el movimiento de $movement.';
  }

  @override
  String get movementTrackingUnavailableSemantics =>
      'El seguimiento del movimiento no está disponible.';

  @override
  String trackingDetected(String movement, int fps) {
    return 'Movimiento detectado: $movement • $fps FPS';
  }

  @override
  String trackingDetectedWithLatency(String movement, int fps, int latency) {
    return 'Movimiento detectado: $movement • $fps FPS • $latency ms';
  }

  @override
  String get cameraPreviewLoading => 'Cargando la imagen de la cámara';

  @override
  String get cameraPreviewUnavailable =>
      'La imagen de la cámara no está disponible';

  @override
  String get cameraTitleStarting => 'Iniciando la cámara';

  @override
  String get cameraTitleReady => 'Cámara lista';

  @override
  String get cameraTitleNoFrontCamera => 'Cámara frontal no disponible';

  @override
  String get cameraTitlePermissionNeeded =>
      'Se necesita permiso para usar la cámara';

  @override
  String get cameraTitleAccessRestricted => 'Acceso a la cámara restringido';

  @override
  String get cameraTitlePaused => 'Cámara en pausa';

  @override
  String get cameraTitleUnavailable => 'Cámara no disponible';

  @override
  String get cameraMessageStarting => 'Iniciando la cámara frontal…';

  @override
  String get cameraMessageAdjustingOrientation =>
      'Ajustando la orientación de la cámara…';

  @override
  String get cameraMessageReady => 'La imagen de la cámara frontal está lista.';

  @override
  String get cameraMessageNoFrontCamera =>
      'No se encontró una cámara frontal en este dispositivo.';

  @override
  String get cameraMessagePermissionDenied =>
      'Se denegó el acceso a la cámara. Permite el acceso en los ajustes del dispositivo y vuelve a intentarlo.';

  @override
  String get cameraMessagePermissionRestricted =>
      'El acceso a la cámara está restringido en este dispositivo.';

  @override
  String get cameraMessagePaused =>
      'La cámara está en pausa mientras la aplicación no está activa.';

  @override
  String get cameraMessageFailure =>
      'No se pudo iniciar la cámara. Vuelve a intentarlo.';

  @override
  String cameraStatusSemantics(String title, String message) {
    return 'Estado de la cámara. $title. $message';
  }

  @override
  String get tryAgain => 'Volver a intentarlo';

  @override
  String get calibrationTitle => 'Calibración del movimiento cómodo';

  @override
  String get calibrationIntroduction =>
      'Una persona adulta puede guiar dos pasos cortos. Mantén todos los movimientos cómodos; nunca fuerces el rango máximo.';

  @override
  String selectedMovement(String movement) {
    return 'Movimiento elegido: $movement.';
  }

  @override
  String get startRestMeasurement => 'Iniciar la medición en reposo';

  @override
  String get calibrationStepOne => 'Paso 1 de 2 • Descansa cómodamente';

  @override
  String stableSamples(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Muestras estables: $count',
      one: 'Muestra estable: 1',
      zero: 'Muestras estables: 0',
    );
    return '$_temp0';
  }

  @override
  String get retryRestMeasurement => 'Repetir la medición en reposo';

  @override
  String get restMeasurementComplete => 'Medición en reposo completada';

  @override
  String restEstimateNext(String value, String prompt) {
    return 'Posición de reposo: ~$value°. A continuación, $prompt';
  }

  @override
  String get measureComfortableMovement => 'Medir el movimiento cómodo';

  @override
  String get calibrationStepTwo => 'Paso 2 de 2 • Muévete cómodamente';

  @override
  String movementPromptSafety(String prompt) {
    return '$prompt No fuerces más el movimiento.';
  }

  @override
  String get retryMovement => 'Repetir el movimiento';

  @override
  String get reviewManualSetting => 'Revisar el ajuste manual';

  @override
  String get manualThresholdUnavailable =>
      'No hay un umbral manual fiable porque el movimiento se confunde con el ruido medido. Lo más seguro es repetirlo.';

  @override
  String get caregiverReview => 'Revisión de la persona adulta';

  @override
  String get caregiverReviewInstructions =>
      'Elige la dirección y la sensibilidad. El umbral no puede estar por debajo del ruido medido ni superar el movimiento cómodo observado.';

  @override
  String get movementDirection => 'Dirección del movimiento';

  @override
  String sensitivityFromRest(String value) {
    return 'Sensibilidad: ~$value° desde el reposo';
  }

  @override
  String measuredNoiseAndMovement(String noise, String movement) {
    return 'Nivel de ruido medido: ~$noise°. Movimiento cómodo observado: ~$movement°.';
  }

  @override
  String get useThisSetting => 'Usar este ajuste';

  @override
  String get calibrationReady => 'Calibración lista';

  @override
  String calibrationDirectionThreshold(String direction, String value) {
    return 'Dirección: $direction. Umbral: ~$value° desde el reposo.';
  }

  @override
  String get calibrationNotSaved =>
      'Esta calibración no se guarda y se borra al salir de esta pantalla.';

  @override
  String get calibrationSuccessCompanion =>
      '¡Muy bien! Este ajuste se mantiene dentro del movimiento medido hoy.';

  @override
  String get testThisControl => 'Probar este control';

  @override
  String get calibrateAgain => 'Volver a calibrar';

  @override
  String get calibrationSemanticReady =>
      'La calibración está lista para comenzar.';

  @override
  String get calibrationSemanticMeasuringRest =>
      'Midiendo la posición de reposo cómoda.';

  @override
  String get calibrationSemanticRestComplete =>
      'La medición en reposo ha terminado. A continuación se medirá el movimiento cómodo.';

  @override
  String get calibrationSemanticMeasuringMovement =>
      'Midiendo un movimiento cómodo.';

  @override
  String get calibrationSemanticReview =>
      'La calibración está lista para que la revise una persona adulta.';

  @override
  String get calibrationSemanticComplete =>
      'Calibración completada. No se ha guardado.';

  @override
  String currentAngleSemantics(String movement, String value) {
    return 'Ángulo estimado actual de $movement: $value';
  }

  @override
  String currentAngleUnavailableSemantics(String movement) {
    return 'El ángulo actual de $movement no está disponible';
  }

  @override
  String baselineTrackingPaused(String hint) {
    return 'Seguimiento en pausa. $hint';
  }

  @override
  String get delayedTrackingSample =>
      'Se ignoró una muestra de seguimiento retrasada.';

  @override
  String get restSignalTooVariable =>
      'La señal en reposo varía demasiado para crear un ajuste automático. Vuelve a intentarlo o usa un ajuste de una persona adulta.';

  @override
  String get restSignalStable =>
      'La señal en reposo es lo bastante estable para continuar.';

  @override
  String get movementNotSeparated =>
      'Este movimiento cómodo no se distinguió con claridad de la variación normal de la señal. Vuelve a intentarlo o usa un ajuste de una persona adulta.';

  @override
  String get movementRecommendationReady =>
      'Hay un umbral inicial disponible para que lo revise una persona adulta. No requiere un movimiento mayor.';

  @override
  String get validationChooseSensitivity =>
      'Elige un ajuste de sensibilidad válido.';

  @override
  String validationBelowNoise(String value) {
    return 'Este ajuste está por debajo del nivel de ruido medido de $value°. Aumenta el umbral o repite la calibración.';
  }

  @override
  String get validationBeyondComfort =>
      'Este ajuste supera el movimiento cómodo observado. Reduce el umbral o repite la calibración.';

  @override
  String get validationOutsideRange =>
      'Esta dirección y sensibilidad están fuera del rango de señal medido. Cambia el ajuste o repite la calibración.';

  @override
  String get validationReliable =>
      'Este ajuste está por encima del ruido y dentro del movimiento cómodo observado.';

  @override
  String get controlStatusTrackingPaused => 'SEGUIMIENTO EN PAUSA';

  @override
  String get controlStatusActionPressed => 'ACCIÓN ACTIVADA';

  @override
  String get controlStatusReturnToRest => 'VUELVE AL REPOSO';

  @override
  String get controlStatusReady => 'LISTO';

  @override
  String controlInstructionReposition(String subject) {
    return 'Vuelve a colocar la $subject para continuar.';
  }

  @override
  String get controlInstructionReturnComfortably =>
      'Vuelve cómodamente al reposo antes de moverte otra vez.';

  @override
  String get controlInstructionWillArm =>
      'El control estará listo cuando el movimiento vuelva al reposo.';

  @override
  String controlTestSemantics(String status, int count, String instruction) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Se han detectado $count acciones',
      one: 'Se ha detectado una acción',
      zero: 'No se ha detectado ninguna acción',
    );
    return 'Prueba de control. $status. $_temp0. $instruction';
  }

  @override
  String get controlTestTitle => 'Prueba de control';

  @override
  String get controlTestDescription =>
      'Un movimiento cómodo debe crear una sola acción.';

  @override
  String get developerTestInput => 'Entrada de prueba para desarrollo';

  @override
  String get testPress => 'Probar activación';

  @override
  String get testRelease => 'Probar liberación';

  @override
  String get validationDetails => 'Detalles de validación';

  @override
  String get caregiverEngineeringChecks =>
      'Comprobaciones técnicas para la persona adulta';

  @override
  String get recalibrate => 'Volver a calibrar';

  @override
  String get unavailable => 'No disponible';

  @override
  String get notAvailable => 'No disponible';

  @override
  String movementTowardAction(String value) {
    return '$value° hacia la acción';
  }

  @override
  String get trackingLabel => 'Seguimiento';

  @override
  String get movementLabel => 'Movimiento';

  @override
  String get pressThreshold => 'Umbral de activación';

  @override
  String get releaseThreshold => 'Umbral de liberación';

  @override
  String get actionsLabel => 'Acciones';

  @override
  String get lastEvent => 'Último evento';

  @override
  String get trackingLost => 'Perdido';

  @override
  String get trackingReady => 'Listo';

  @override
  String motionEventLabel(String event) {
    String _temp0 = intl.Intl.selectLogic(event, {
      'primaryAction': 'Acción principal',
      'actionDown': 'Acción activada',
      'actionUp': 'Acción liberada',
      'trackingLost': 'Seguimiento perdido',
      'trackingRecovered': 'Seguimiento recuperado',
      'other': 'Evento desconocido',
    });
    return '$_temp0';
  }

  @override
  String get caregiverValidationSemantics =>
      'Detalles de validación para la persona adulta.';

  @override
  String get validTrackingSamples => 'Muestras de seguimiento válidas';

  @override
  String validTrackingSamplesValue(int valid, int total, int percent) {
    return '$valid/$total ($percent %)';
  }

  @override
  String get detectionRate => 'Frecuencia de detección';

  @override
  String framesPerSecondValue(String value) {
    return '$value FPS';
  }

  @override
  String get processingDelayMedian => 'Mediana del retardo de procesamiento';

  @override
  String millisecondsValue(int value) {
    return '$value ms';
  }

  @override
  String get droppedFrames => 'Fotogramas descartados';

  @override
  String get observedSignalNoise => 'Relación señal/ruido observada';

  @override
  String ratioValue(String value) {
    return '$value×';
  }

  @override
  String get signalRiseToAction => 'De señal a acción';

  @override
  String get completeAnAction => 'Completa una acción';

  @override
  String millisecondsMedianValue(int value) {
    return 'Mediana: $value ms';
  }

  @override
  String get engineeringDiagnosticsNote =>
      'Estos son diagnósticos técnicos, no mediciones clínicas. El tiempo de señal comienza cuando la estimación de la cámara supera el nivel de ruido medido; no mide el tiempo de reacción física.';

  @override
  String fingerDiagnosticSemantics(String value, String state, String detail) {
    return 'Diagnóstico de flexión del dedo índice. $value. $state. $detail';
  }

  @override
  String get fingerFlexionTitle => 'Flexión del dedo índice';

  @override
  String get fingerAngleExplanation =>
      '0° indica que está recto; un ángulo mayor significa más flexión.';

  @override
  String get fingerStateSteady => 'Estable';

  @override
  String get fingerStateBending => 'Flexionando';

  @override
  String get fingerStateStraightening => 'Estirando';

  @override
  String get fingerWaitingTracking =>
      'Esperando a que esté disponible el seguimiento de la mano.';

  @override
  String get fingerShowHand => 'Muestra una mano para medir el dedo índice.';

  @override
  String get fingerWaitingCurrentFrame =>
      'Esperando una imagen de seguimiento actual.';

  @override
  String get fingerMoveFullyIntoView =>
      'Coloca toda la mano dentro de la imagen para obtener una medición estable.';

  @override
  String get fingerWaitingMeasurement => 'Esperando una medición.';

  @override
  String get signalGeometryUsable => 'Geometría de señal: utilizable';

  @override
  String get signalGeometrySettling => 'Geometría de señal: estabilizándose';

  @override
  String get signalGeometryUnavailable => 'Geometría de señal: no disponible';

  @override
  String get firstGameSectionLabel => 'PRIMER JUEGO';

  @override
  String get firstGameTitle => 'Carrera Celeste';

  @override
  String get firstGameDescription =>
      'Ayuda a Joybit a volar con seguridad entre las puertas. Usa el botón grande o el teclado; el movimiento calibrado se conectará en la próxima fase.';

  @override
  String get openGamePreview => 'Jugar a Carrera Celeste';

  @override
  String get gameTitle => 'Carrera Celeste';

  @override
  String get gamePrimaryAction => 'VOLAR';

  @override
  String get gamePrimaryActionSemantics => 'Hacer que Joybit vuele';

  @override
  String gameScore(int score) {
    return 'Puntos: $score';
  }

  @override
  String gameStatusSemantics(String status, int score, String instruction) {
    return 'Carrera Celeste. $status. Puntos: $score. $instruction';
  }

  @override
  String get gameReady => 'Listo';

  @override
  String get gameFlying => 'Volando';

  @override
  String get gameOver => 'Fin del juego';

  @override
  String get gameReadyInstruction =>
      'Pulsa VOLAR para comenzar. En un ordenador también puedes usar Espacio o Intro.';

  @override
  String get gameFlyingInstruction => 'Mantén a Joybit entre las puertas.';

  @override
  String get gameOverInstruction =>
      'Reinicia para volver a intentar el mismo recorrido.';

  @override
  String get gameRestartAction => 'JUGAR DE NUEVO';

  @override
  String gameOverSemantics(int score) {
    return 'Fin del juego. Puntos: $score. Juega de nuevo para reiniciar el mismo recorrido.';
  }

  @override
  String get gamePaused => 'En pausa';

  @override
  String get gamePauseTooltip => 'Pausar el juego';

  @override
  String get gameResumeTooltip => 'Reanudar el juego';

  @override
  String get gameRestartTooltip => 'Reiniciar el juego';

  @override
  String get gameExitTooltip => 'Volver a Juego rápido';

  @override
  String get joybitDescription =>
      'Joybit, un simpático erizo lavanda con auriculares de arcade.';
}
