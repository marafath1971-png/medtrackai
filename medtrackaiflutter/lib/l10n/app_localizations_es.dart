// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'MedAI';

  @override
  String get greetingHero => 'Inicio';

  @override
  String get homeTab => 'Inicio';

  @override
  String get alarmsTab => 'Alarmas';

  @override
  String get dashboardTab => 'Tendencias';

  @override
  String get familyTab => 'Círculo';

  @override
  String get scanTab => 'Escanear';

  @override
  String get countrySelectionTitle => '¿Dónde te encuentras?';

  @override
  String get countrySelectionSubtitle =>
      'Nos ayuda a identificar marcas de medicamentos locales';

  @override
  String get prnLabel => 'Según necesidad';

  @override
  String get prnUndoToast => 'Dosis PRN eliminada';

  @override
  String get dailyLogTitle => 'Registro diario';

  @override
  String get noMedicinesScheduled =>
      'No hay medicamentos programados para este día.';

  @override
  String get remaining => 'restante';

  @override
  String get refillRequired => 'Reposición necesaria';

  @override
  String get settings => 'Ajustes';

  @override
  String get profile => 'Perfil';

  @override
  String get language => 'Idioma';

  @override
  String get country => 'País';

  @override
  String get saveChanges => 'GUARDAR CAMBIOS';

  @override
  String get inventory => 'Inventario';

  @override
  String get noMedicines => 'Sin medicamentos';

  @override
  String get takeNow => 'Tomar ahora';

  @override
  String get snooze => 'Posponer';

  @override
  String get skip => 'Omitir';

  @override
  String get pharmacyLabel => 'Farmacia';

  @override
  String get pharmacyPhoneLabel => 'Teléfono de farmacia';

  @override
  String get rxNumberLabel => 'Número de receta';

  @override
  String get globalSettings => 'Ajustes globales';

  @override
  String get religiousObservance => 'Observancia religiosa';

  @override
  String get shabbatMode => 'Modo Shabat';

  @override
  String get prayerAwareReminders => 'Recordatorios según la oración';

  @override
  String get halalDetection => 'Detección de halal y gelatina';

  @override
  String get amoledMode => 'Modo AMOLED (ahorro de píxeles)';

  @override
  String get diabetesMode => 'Modo diabetes';

  @override
  String get hypertensionMode => 'Modo hipertensión';

  @override
  String get supportedMarkets => 'Mercados admitidos';

  @override
  String get halalSafe => 'Apto halal';

  @override
  String get gelatinWarning => 'Contiene gelatina';

  @override
  String get halalUncertain => 'Halal incierto';

  @override
  String get edit => 'Editar';

  @override
  String get editProfile => 'Editar perfil';

  @override
  String get cancel => 'Cancelar';

  @override
  String get globalSettingsSubtitle =>
      'Gestiona los ajustes de mercado internacional';

  @override
  String get medicationDisplay => 'Visualización de medicamentos';

  @override
  String get showGenericNames => 'Mostrar nombres genéricos (DCI)';

  @override
  String get showGenericNamesSubtitle =>
      'Mostrar denominaciones comunes internacionales en lugar de marcas comerciales';

  @override
  String get pbsSafetyNet => 'Rastreador PBS Safety Net';

  @override
  String get pbsSafetyNetSubtitle => 'Australia: registra el copago anual';

  @override
  String get pbsThreshold => 'Umbral anual: \$1.622,90';

  @override
  String pbsSpent(Object amount) {
    return 'Gastado: \$$amount';
  }

  @override
  String pbsRemaining(Object amount) {
    return '\$$amount para alcanzarlo';
  }

  @override
  String get reached => '¡Alcanzado!';

  @override
  String get medsSubsidised => '¡Medicamentos ahora subvencionados!';

  @override
  String get spentAmountSubtitle =>
      'Desliza para actualizar el importe gastado este año (copagos de todas las recetas PBS de este año natural)';

  @override
  String get clinicalModes => 'Modos clínicos';

  @override
  String get clinicalModesSubtitle => 'EE. UU. · Reino Unido · EAU · Malasia';

  @override
  String get diabetesModeSubtitle =>
      'Registra la glucemia junto con la insulina o los medicamentos para la diabetes';

  @override
  String get hypertensionModeSubtitle =>
      'Registra la presión arterial junto con los antihipertensivos';

  @override
  String get displaySettings => 'Pantalla';

  @override
  String get amoledModeSubtitle =>
      'Usa un fondo #000000 real para optimizar las pantallas AMOLED y ahorrar batería';

  @override
  String get shabbatModeSubtitle =>
      'Recordatorios suaves solo con vibración desde el atardecer del viernes hasta la noche del sábado';

  @override
  String get selectCountry => 'Seleccionar país';

  @override
  String get selectLanguage => 'Seleccionar idioma';

  @override
  String get aiSafetyProfile => 'Perfil de seguridad de IA';

  @override
  String get verified => 'Verificado';

  @override
  String get criticalWarnings => 'Advertencias críticas';

  @override
  String get drugInteractions => 'Interacciones farmacológicas';

  @override
  String get dietaryLifestyleRules => 'Reglas dietéticas y de estilo de vida';

  @override
  String get ahaInsight => '¡Revelación!';

  @override
  String get generateSafetyProfile => 'Generar perfil de seguridad';

  @override
  String get analyzingClinicalLimits => 'Analizando límites clínicos...';

  @override
  String get safetyLoadingSubtitle =>
      'Espera mientras la IA verifica interacciones, riesgos y reglas alimentarias.';

  @override
  String get safetyPromptSubtitle =>
      'Toca para analizar al instante este medicamento en busca de riesgos, interacciones farmacológicas y reglas de estilo de vida.';

  @override
  String get goodMorning => 'Buenos días';

  @override
  String get goodAfternoon => 'Buenas tardes';

  @override
  String get goodEvening => 'Buenas noches';

  @override
  String hiUser(String name) {
    return 'Hola, $name 👋';
  }

  @override
  String get startJourney => 'Comencemos tu camino hacia la salud ✨';

  @override
  String get allDosesTaken => '¡Todas las dosis tomadas hoy! 🌟';

  @override
  String dosesOverdue(int count) {
    return '$count dosis atrasadas: tómalas ahora ⚠️';
  }

  @override
  String dosesLeft(int count) {
    return '$count dosis restantes hoy';
  }

  @override
  String get healthReportTitle => 'Informe de salud MedAI';

  @override
  String get medicalSummarySubtitle =>
      'Resumen médico personal y tendencias de adherencia';

  @override
  String patientLabel(String name) {
    return 'Paciente: $name';
  }

  @override
  String reportDate(String date) {
    return 'Fecha: $date';
  }

  @override
  String get overallAdherence => 'Adherencia general';

  @override
  String get activeMedications => 'Medicamentos activos';

  @override
  String get reportPeriod => 'Período del informe';

  @override
  String get last30Days => 'Últimos 30 días';

  @override
  String get currentMedications => 'Medicamentos actuales';

  @override
  String get medicineCol => 'Medicamento';

  @override
  String get doseCol => 'Dosis';

  @override
  String get frequencyCol => 'Frecuencia';

  @override
  String get stockRemainingCol => 'Existencias restantes';

  @override
  String get recentSymptoms => 'Síntomas y bienestar recientes';

  @override
  String get symptomDateCol => 'Fecha';

  @override
  String get symptomNameCol => 'Síntoma';

  @override
  String get severityCol => 'Gravedad';

  @override
  String get notesCol => 'Notas';

  @override
  String get noSymptomsLogged => 'No se registraron síntomas en este período.';

  @override
  String get reportFooter =>
      'Generado por MedAI Pro. Este informe tiene fines meramente informativos y debe ser revisado por un profesional sanitario cualificado.';

  @override
  String get settingsStats => 'Estadísticas';

  @override
  String get settingsApp => 'Ajustes de la app';

  @override
  String get settingsData => 'Datos y privacidad';

  @override
  String get settingsGlobal => 'Ajustes globales';

  @override
  String get settingsProfile => 'Mi perfil';

  @override
  String get adherenceLabel => 'ADHERENCIA';

  @override
  String get streakLabel => 'RACHA';

  @override
  String streakDays(int count) {
    return '$count días';
  }

  @override
  String get generateClinicalReport => 'GENERAR INFORME CLÍNICO';

  @override
  String get fetchingAiInsights => 'OBTENIENDO ANÁLISIS DE IA...';

  @override
  String get aiCoachDisclaimer =>
      'Este panel usa IA para analizar patrones. Consulta siempre a tu médico para recibir consejo médico.';

  @override
  String get insightsTitle => 'Análisis';

  @override
  String get insightsSubtitle => 'Analíticas y patrones de salud';

  @override
  String get dataSummaryTitle => 'RESUMEN DE TUS DATOS';

  @override
  String get dataMedicinesLabel => 'Medicamentos';

  @override
  String get dataAlarmsLabel => 'Alarmas configuradas';

  @override
  String get dataDaysTrackedLabel => 'Días registrados';

  @override
  String get dataDosesLoggedLabel => 'Dosis registradas';

  @override
  String get exportAndBackup => 'Exportar y copia de seguridad';

  @override
  String get exportPdfReport => 'Exportar informe PDF';

  @override
  String get exportPdfSubtitle => 'Para médicos y cuidadores';

  @override
  String get exportCsv => 'Exportar historial como CSV';

  @override
  String exportCsvSubtitle(int count) {
    return '$count registros de dosis';
  }

  @override
  String get resetSection => 'Restablecer';

  @override
  String get deleteAllData => 'Eliminar todos los datos';

  @override
  String get deleteAllDataSubtitle =>
      'Elimina todos los medicamentos, el historial y los ajustes';

  @override
  String get deleteConfirmTitle => '¿Eliminar todos los datos?';

  @override
  String get deleteConfirmBody =>
      'Esto eliminará permanentemente todos tus datos. No se puede deshacer.';

  @override
  String get deleteButton => 'Eliminar todo';

  @override
  String get legalSection => 'Legal';

  @override
  String get privacyPolicy => 'Política de privacidad';

  @override
  String get privacyPolicySubtitle => 'Cómo protegemos tus datos de salud';

  @override
  String get termsOfService => 'Términos del servicio';

  @override
  String get termsOfServiceSubtitle => 'Reglas para usar MedAI';

  @override
  String get appVersionLabel => 'Versión de la app';

  @override
  String get appVersionValue => '1.0.0+1';

  @override
  String get analysisFailed => 'Error en el análisis';

  @override
  String get somethingWentWrong => 'Algo salió mal. Inténtalo de nuevo.';

  @override
  String get retry => 'Reintentar';

  @override
  String get onboardingSkip => 'Omitir';

  @override
  String get onboardingNext => 'Siguiente';

  @override
  String get onboardingContinue => 'Continuar';

  @override
  String get onboardingGetStarted => 'Comenzar';

  @override
  String get onboardingWelcomeTitle =>
      'Crea hábitos\nde medicación\ninquebrantables';

  @override
  String get onboardingWelcomeBody =>
      'Rachas, recordatorios inteligentes e IA que te mantiene al día, todos los días.';

  @override
  String get onboardingScanTitle => 'Escanea cualquier\npastilla en segundos';

  @override
  String get onboardingScanBodyDemo =>
      'Toca abajo para ver cómo la IA identifica un medicamento de muestra al instante.';

  @override
  String get onboardingScanBodyDone =>
      'Así de rápido funciona Med AI. Sin escribir, sin conjeturas.';

  @override
  String get onboardingSimulateScan => 'Simular escaneo →';

  @override
  String get onboardingPermissionTitle => 'Tu cámara,\ntu privacidad';

  @override
  String get onboardingPermissionBody =>
      'Solo usamos la cámara para leer las etiquetas de las pastillas. Las imágenes se procesan de forma segura y nunca se venden.';

  @override
  String get onboardingPermissionLink => 'Descubre cómo protegemos tus datos';

  @override
  String get onboardingPersonalizeTitle => 'Personaliza\ntu experiencia';

  @override
  String get onboardingQuizMedCount => '¿Cuántos medicamentos?';

  @override
  String get onboardingQuizRole => '¿Para quién haces el seguimiento?';

  @override
  String get onboardingQuizSchedule =>
      '¿Cuándo tomas la mayoría de los medicamentos?';

  @override
  String get onboardingRoleSelf => 'Para mí';

  @override
  String get onboardingRoleCaregiver => 'Alguien a quien cuido';

  @override
  String get onboardingScheduleMorning => 'Mañana';

  @override
  String get onboardingScheduleEvening => 'Noche';

  @override
  String get onboardingScheduleBoth => 'Ambas';

  @override
  String get onboardingSocialTitle =>
      'Únete a más de 50.000\ncampeones de la salud';

  @override
  String get onboardingSocialQuote =>
      '«Med AI cambió la forma en que mi familia gestiona los medicamentos. Solo la función de escaneo nos ahorra 10 minutos al día.»';

  @override
  String get onboardingSocialAttribution =>
      '— Reseña en App Store, 5 estrellas';

  @override
  String get onboardingAllowCamera => 'Permitir acceso a la cámara';

  @override
  String get onboardingTryDemoScan => 'Probar escaneo de demostración';

  @override
  String get loadingHealthData => 'Cargando tus datos de salud…';
}
