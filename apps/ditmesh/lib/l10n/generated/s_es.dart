// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 's.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class SEs extends S {
  SEs([String locale = 'es']) : super(locale);

  @override
  String get appName => 'DitMesh';

  @override
  String get navLearn => 'Aprender';

  @override
  String get navChat => 'Chat';

  @override
  String get navGroups => 'Grupos';

  @override
  String get navMe => 'Yo';

  @override
  String get navReference => 'Referencia';

  @override
  String get navLearnDescription => 'Lecciones del método Koch, ejercicios de transmisión y práctica de recepción.';

  @override
  String get navChatDescription => 'Conversaciones Morse individuales sin servidor a través de Tox P2P.';

  @override
  String get navGroupsDescription => 'Redes de grupo: varios operadores transmiten en un canal compartido.';

  @override
  String get navReferenceDescription => 'Alfabeto, señales de procedimiento, códigos Q, abreviaturas y un traductor bidireccional.';

  @override
  String get navMeDescription => 'Tu indicativo, identidad Tox, progreso y ajustes.';

  @override
  String get shellOfflineBanner => 'Sin conexión a la red Tox. Los mensajes se enviarán cuando vuelvas a conectarte.';

  @override
  String get actionOk => 'Aceptar';

  @override
  String get actionCancel => 'Cancelar';

  @override
  String get actionSave => 'Guardar';

  @override
  String get actionDelete => 'Eliminar';

  @override
  String get actionCopy => 'Copiar';

  @override
  String get actionShare => 'Compartir';

  @override
  String get actionRetry => 'Reintentar';

  @override
  String get actionClose => 'Cerrar';

  @override
  String get actionSearch => 'Buscar';

  @override
  String get actionSettings => 'Ajustes';

  @override
  String get connectionConnecting => 'Conectando…';

  @override
  String get connectionOnline => 'En línea';

  @override
  String get connectionOffline => 'Sin conexión';

  @override
  String get messageStatusPending => 'En cola: el contacto está desconectado';

  @override
  String get messageStatusPendingDetail => 'Tox no tiene servidor: el mensaje se entrega cuando el contacto se conecta.';

  @override
  String get messageStatusSending => 'Enviando';

  @override
  String get messageStatusSent => 'Enviado';

  @override
  String get messageStatusFailed => 'Error al enviar';

  @override
  String get errorWrongPassword => 'Contraseña incorrecta. Inténtalo de nuevo.';

  @override
  String get errorPeerOffline => 'Este contacto está desconectado. Tox no tiene servidor, así que el mensaje espera hasta que vuelva a conectarse.';

  @override
  String get errorInvalidToxId => 'El Tox ID no es válido (debe tener 76 caracteres hexadecimales).';

  @override
  String get errorAlreadyFriend => 'Este Tox ID ya está en tu lista de amigos.';

  @override
  String get errorOwnId => 'Ese es tu propio Tox ID.';

  @override
  String get errorGroupNotFound => 'No se encontró el grupo.';

  @override
  String get errorMessageTooLong => 'El texto supera el límite de un mensaje de Tox.';

  @override
  String get errorUnknown => 'Se ha producido un error';

  @override
  String get languageTitle => 'Idioma';

  @override
  String get languageSystemDefault => 'Predeterminado del sistema';

  @override
  String get languageSaveFailed => 'No se pudo guardar el idioma. Inténtalo de nuevo.';

  @override
  String learnLessonOf(int lesson, int total) {
    return 'Lección $lesson de $total';
  }

  @override
  String learnCharsLearned(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count caracteres aprendidos',
      one: '$count carácter aprendido',
    );
    return '$_temp0';
  }

  @override
  String learnDailyGoalProgress(int done, int goal) {
    return '$done / $goal caracteres';
  }

  @override
  String learnStreakDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days días seguidos',
      one: '$days día seguido',
    );
    return '$_temp0';
  }

  @override
  String learnReviewDueCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pendientes',
      one: '$count pendiente',
      zero: 'Nada pendiente',
    );
    return '$_temp0';
  }

  @override
  String learnRoundScore(int correct, int total) {
    return '$correct de $total correctos';
  }

  @override
  String learnRoundOf(int round) {
    return 'Ronda $round';
  }

  @override
  String learnAccuracyPercent(int percent) {
    return '$percent%';
  }

  @override
  String learnCharsSent(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count caracteres transmitidos',
      one: '$count carácter transmitido',
    );
    return '$_temp0';
  }

  @override
  String learnLessonUnlocked(String char) {
    return 'Nuevo carácter desbloqueado: $char';
  }

  @override
  String learnConfusedMissed(String target) {
    return '$target omitido';
  }

  @override
  String learnConfusedAs(String target, String answered) {
    return '$target oído como $answered';
  }

  @override
  String learnWpmValue(String wpm) {
    return '$wpm WPM';
  }

  @override
  String learnHzValue(String hz) {
    return '$hz Hz';
  }

  @override
  String learnCharsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count caracteres',
      one: '$count carácter',
    );
    return '$_temp0';
  }

  @override
  String statsLessonOf(int lesson, int total) {
    return '$lesson / $total';
  }

  @override
  String statsCharsLearned(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count caracteres aprendidos',
      one: '$count carácter aprendido',
    );
    return '$_temp0';
  }

  @override
  String statsPercent(String percent) {
    return '$percent%';
  }

  @override
  String statsCharsCopied(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count caracteres recibidos',
      one: '$count carácter recibido',
    );
    return '$_temp0';
  }

  @override
  String statsSessions(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sesiones',
      one: '$count sesión',
    );
    return '$_temp0';
  }

  @override
  String statsDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count días',
      one: '$count día',
    );
    return '$_temp0';
  }

  @override
  String statsBestStreak(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Récord: $count días',
      one: 'Récord: $count día',
    );
    return '$_temp0';
  }

  @override
  String statsGoalProgress(int done, int goal) {
    return '$done / $goal caracteres';
  }

  @override
  String statsGoalRemaining(int remaining) {
    String _temp0 = intl.Intl.pluralLogic(
      remaining,
      locale: localeName,
      other: 'Faltan $remaining caracteres',
      one: 'Falta $remaining carácter',
    );
    return '$_temp0';
  }

  @override
  String statsTrendSubtitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Últimas $count sesiones',
      one: 'Última sesión',
    );
    return '$_temp0';
  }

  @override
  String statsTooltipSession(int index, int total) {
    return 'Sesión $index de $total';
  }

  @override
  String statsTooltipCopied(int correct, int total) {
    return '$correct / $total correctos';
  }

  @override
  String statsTooltipLesson(int lesson) {
    return 'Lección $lesson';
  }

  @override
  String statsAttempts(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count intentos',
      one: '$count intento',
    );
    return '$_temp0';
  }

  @override
  String statsCorrectOf(int correct, int attempts) {
    return '$correct de $attempts correctos';
  }

  @override
  String statsLessonIntroduced(int lesson) {
    return 'Introducido en la lección $lesson';
  }

  @override
  String statsSrsBox(int box, int maxBox) {
    return 'Caja $box de $maxBox';
  }

  @override
  String statsSrsDueIn(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Repasar en $days días',
      one: 'Repasar en $days día',
    );
    return '$_temp0';
  }

  @override
  String statsTimes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count veces',
      one: '$count vez',
    );
    return '$_temp0';
  }

  @override
  String statsHeatmapCell(String target, String answered, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count veces',
      one: '$count vez',
    );
    return '$target respondido como $answered, $_temp0';
  }

  @override
  String statsCalendarDay(String date, int chars) {
    String _temp0 = intl.Intl.pluralLogic(
      chars,
      locale: localeName,
      other: '$chars caracteres',
      one: '$chars carácter',
      zero: 'sin práctica',
    );
    return '$date: $_temp0';
  }

  @override
  String statsActiveDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count días activos',
      one: '$count día activo',
    );
    return '$_temp0';
  }

  @override
  String referenceEntryCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count entradas',
      one: '$count entrada',
    );
    return '$_temp0';
  }

  @override
  String referenceWpmValue(String wpm) {
    return '$wpm WPM';
  }

  @override
  String referenceHzValue(String hz) {
    return '$hz Hz';
  }

  @override
  String referenceSkippedChars(String chars) {
    return 'Omitidos (sin código Morse): $chars';
  }

  @override
  String referenceKochPositionValue(int position) {
    return 'Posición Koch: $position';
  }

  @override
  String referenceEstimatedSpeed(String wpm) {
    return 'Aproximadamente $wpm WPM';
  }

  @override
  String get accountCopied => 'Tox ID copiado al portapapeles';

  @override
  String get accountShowQr => 'Mostrar código QR';

  @override
  String get accountToxId => 'Tox ID';

  @override
  String get accountDisplayName => 'Nombre visible';

  @override
  String get accountDisplayNameHint => 'Tu indicativo o apodo';

  @override
  String get accountDisplayNameRequired => 'Introduce un nombre visible';

  @override
  String get accountStatusMessage => 'Mensaje de estado';

  @override
  String get accountPassword => 'Contraseña';

  @override
  String get accountPasswordOptional => 'Contraseña (opcional)';

  @override
  String get accountConfirmPassword => 'Confirmar contraseña';

  @override
  String get accountPasswordsDoNotMatch => 'Las contraseñas no coinciden';

  @override
  String get accountShowPassword => 'Mostrar contraseña';

  @override
  String get accountHidePassword => 'Ocultar contraseña';

  @override
  String get accountStrengthWeak => 'Débil: usa al menos 8 caracteres';

  @override
  String get accountStrengthFair => 'Aceptable: mejor 12 o más caracteres de varios tipos';

  @override
  String get accountStrengthStrong => 'Fuerte';

  @override
  String get accountStartupInspecting => 'Comprobando tu identidad…';

  @override
  String get accountStartupOpening => 'Abriendo tu identidad…';

  @override
  String get accountStartupFailedTitle => 'No se pudo iniciar';

  @override
  String get accountStartupFailedBody => 'DitMesh no pudo leer tu identidad. No se ha cambiado nada; puedes intentarlo de nuevo.';

  @override
  String get accountConnectionTapToReconnect => 'Toca para volver a conectar';

  @override
  String get accountWelcomeTitle => 'Tu identidad reside en este dispositivo';

  @override
  String get accountWelcomeIntro => 'DitMesh usa la red entre pares Tox. No hay servidor ni cuenta que registrar: tu identidad es un par de claves guardado únicamente aquí.';

  @override
  String get accountWelcomePointNoServer => 'Sin servidor, número de teléfono ni correo electrónico. Los operadores hablan directamente en Morse.';

  @override
  String get accountWelcomePointTraining => 'Chatea con una persona o en grupo usando código Morse, con una llave recta o paletas iámbicas.';

  @override
  String get accountWelcomePointBackup => 'Nadie puede recuperar tu identidad por ti. Crea una copia de seguridad al terminar o la perderás junto con el dispositivo.';

  @override
  String get accountCreateIdentity => 'Crear identidad';

  @override
  String get accountRestoreFromBackup => 'Restaurar desde copia de seguridad';

  @override
  String get accountCreateTitle => 'Crea tu identidad';

  @override
  String get accountCreateBody => 'Elige un nombre que verán los demás. La contraseña cifra el archivo de identidad de este dispositivo; déjala vacía si prefieres abrir la aplicación sin ella.';

  @override
  String get accountCreateButton => 'Crear';

  @override
  String get accountCreating => 'Creando…';

  @override
  String get accountBackupTitle => 'Crea ahora una copia de tu identidad';

  @override
  String get accountBackupBody => 'Tu identidad solo existe en este dispositivo. Si lo pierdes, lo restableces o te lo roban, no podrás recuperarla: tus contactos no reconocerán una identidad nueva y perderás tu progreso.';

  @override
  String get accountBackupWhatIsInside => 'La copia contiene tu clave de identidad, cifrada con tu contraseña, y tu progreso. Guárdala en un lugar seguro fuera de este dispositivo.';

  @override
  String get accountBackupWhatIsInsidePlain => 'La copia contiene tu clave de identidad sin cifrar y tu progreso. Cualquiera que obtenga este archivo puede usar tu identidad: establece primero una contraseña si quieres cifrar la clave y guarda el archivo en un lugar seguro.';

  @override
  String get accountPasswordScope => 'Tu contraseña cifra tu clave de identidad. El historial de mensajes queda sin cifrar en el disco; el cifrado del dispositivo puede protegerlo.';

  @override
  String get accountSectionNotifications => 'Notificaciones';

  @override
  String get accountNotificationsEnable => 'Mostrar notificaciones';

  @override
  String get accountNotificationsEnableSubtitle => 'Mensajes nuevos, solicitudes de amistad e invitaciones a grupos';

  @override
  String get accountNotificationsContent => 'Mostrar el contenido de los mensajes';

  @override
  String get accountNotificationsContentSubtitle => 'Texto y Morse en los avisos y en la pantalla de bloqueo. Desactivado: solo que llegó un mensaje.';

  @override
  String get accountNotificationsAllow => 'Permitir notificaciones';

  @override
  String get accountNotificationsAllowSubtitle => 'Pedir permiso al sistema';

  @override
  String get accountNotificationsDenied => 'Las notificaciones de DitMesh están desactivadas en los ajustes del sistema.';

  @override
  String get accountBackupSaveFile => 'Guardar copia de seguridad';

  @override
  String get accountBackupShareFile => 'Compartir copia de seguridad';

  @override
  String get accountBackupSaved => 'Copia de seguridad guardada';

  @override
  String get accountBackupNotSaved => 'No se guardó la copia de seguridad';

  @override
  String get accountBackupFailed => 'No se pudo escribir la copia de seguridad';

  @override
  String get accountBackupAcknowledge => 'Entiendo que sin esta copia no podré recuperar mi identidad.';

  @override
  String get accountBackupContinue => 'Continuar a DitMesh';

  @override
  String get accountBackupShowQrHint => 'Tus amigos te añaden con tu Tox ID. Compártelo como texto o como código QR.';

  @override
  String get accountRestoreTitle => 'Restaurar desde copia de seguridad';

  @override
  String get accountRestoreBody => 'Elige una copia de seguridad exportada desde DitMesh. Si la identidad tenía contraseña, tendrás que introducirla aquí.';

  @override
  String get accountRestoreChooseFile => 'Elegir copia de seguridad';

  @override
  String get accountRestoreNoFile => 'Elige primero una copia de seguridad';

  @override
  String get accountRestoreButton => 'Restaurar';

  @override
  String get accountRestoring => 'Restaurando…';

  @override
  String get accountRestoreInvalidFile => 'Este archivo no es una copia de DitMesh.';

  @override
  String get accountRestoreReplacesWarning => 'La restauración sustituye la identidad actual de este dispositivo.';

  @override
  String get accountUnlockTitle => 'Desbloquea tu identidad';

  @override
  String get accountUnlockBody => 'Tu archivo de identidad está cifrado. Introduce la contraseña para continuar.';

  @override
  String get accountUnlockButton => 'Desbloquear';

  @override
  String get accountUnlocking => 'Desbloqueando…';

  @override
  String get accountUnlockRestoreInstead => 'Restaurar desde copia de seguridad en su lugar';

  @override
  String get accountMeNoIdentity => 'No hay identidad cargada';

  @override
  String get accountSectionAccount => 'Cuenta';

  @override
  String get accountSectionTraining => 'Entrenamiento';

  @override
  String get accountSectionAbout => 'Acerca de';

  @override
  String get accountSectionDanger => 'Zona de peligro';

  @override
  String get accountEditProfile => 'Editar perfil';

  @override
  String get accountEditProfileBody => 'Visible para tus contactos de la red Tox.';

  @override
  String get accountSetPassword => 'Establecer contraseña';

  @override
  String get accountChangePassword => 'Cambiar contraseña';

  @override
  String get accountRemovePassword => 'Quitar contraseña';

  @override
  String get accountCurrentPassword => 'Contraseña actual';

  @override
  String get accountNewPassword => 'Nueva contraseña';

  @override
  String get accountPasswordUpdated => 'Contraseña actualizada';

  @override
  String get accountPasswordRemoved => 'Contraseña eliminada';

  @override
  String get accountProfileUpdated => 'Perfil actualizado';

  @override
  String get accountExportBackup => 'Exportar copia de seguridad';

  @override
  String get accountExportBackupSubtitle => 'Guarda tu identidad y progreso en un archivo';

  @override
  String get accountTrainingDefaults => 'Valores de reproducción y entrenamiento';

  @override
  String get accountTrainingDefaultsSubtitle => 'Velocidad, tono y espaciado Farnsworth';

  @override
  String get accountTrainingDefaultsPlaceholder => 'Aquí estarán los valores de velocidad, tono y Farnsworth.';

  @override
  String get accountAboutLicence => 'Licencia';

  @override
  String get accountAboutLicenceValue => 'GPL-3.0';

  @override
  String get accountAboutSource => 'Código fuente';

  @override
  String get accountAboutSourceCopied => 'Enlace al código copiado';

  @override
  String get accountAboutBackend => 'Motor interno';

  @override
  String get accountDeleteIdentity => 'Eliminar identidad';

  @override
  String get accountDeleteIdentitySubtitle => 'Borra la identidad, el historial y el progreso de este dispositivo';

  @override
  String get accountDeleteDialogTitle => '¿Eliminar esta identidad?';

  @override
  String get accountDeleteDialogBody => 'Se eliminarán tu identidad, historial de chat y progreso de este dispositivo. No podrás recuperarlos sin una copia de seguridad. Escribe DELETE para confirmar.';

  @override
  String get accountDeleteConfirmWord => 'DELETE';

  @override
  String get accountDeleteConfirmHint => 'Escribe DELETE';

  @override
  String get accountDeleteButton => 'Eliminar';

  @override
  String accountRestoreFileChosenSize(int bytes) {
    return 'Copia seleccionada ($bytes bytes)';
  }

  @override
  String get chatSearchConversations => 'Buscar conversaciones';

  @override
  String get chatNoConversations => 'Aún no hay conversaciones';

  @override
  String get chatNoSearchResults => 'No hay conversaciones que coincidan';

  @override
  String get chatPin => 'Fijar';

  @override
  String get chatUnpin => 'Desfijar';

  @override
  String get chatMarkRead => 'Marcar como leído';

  @override
  String get chatDelete => 'Eliminar';

  @override
  String get chatDeleteConversationTitle => '¿Eliminar conversación?';

  @override
  String get chatDeleteConversationBody => 'Se eliminará el historial local de esta conversación. Tox no conserva ninguna copia.';

  @override
  String get chatDraftPrefix => 'Borrador: ';

  @override
  String get chatSelectConversation => 'Selecciona una conversación';

  @override
  String get chatContacts => 'Contactos';

  @override
  String get chatNoMessages => 'Aún no hay mensajes: envía CQ para empezar.';

  @override
  String get chatTrainingMode => 'Modo de entrenamiento';

  @override
  String get chatTrainingModeOn => 'Entrenamiento activado: texto oculto';

  @override
  String get chatTrainingModeOff => 'Entrenamiento desactivado';

  @override
  String get chatAutoPlay => 'Reproducir automáticamente el Morse recibido';

  @override
  String get chatAutoPlayOn => 'Reproducción automática activada: los mensajes nuevos suenan al llegar';

  @override
  String get chatAutoPlayOff => 'Reproducción automática desactivada';

  @override
  String get chatReveal => 'Mostrar';

  @override
  String get chatHiddenText => 'Escucha primero y luego muestra el texto';

  @override
  String get chatPlay => 'Reproducir Morse';

  @override
  String get chatStop => 'Detener';

  @override
  String get chatPlaybackSettings => 'Ajustes de reproducción';

  @override
  String get chatCharacterSpeed => 'Velocidad de los caracteres';

  @override
  String get chatFarnsworthSpeed => 'Velocidad Farnsworth';

  @override
  String get chatTone => 'Tono';

  @override
  String get chatWpm => 'WPM';

  @override
  String get chatHz => 'Hz';

  @override
  String get chatMembers => 'Miembros';

  @override
  String get chatLeaveGroup => 'Salir del grupo';

  @override
  String get chatLeaveGroupTitle => '¿Salir de este grupo?';

  @override
  String get chatLeaveGroupBody => 'Dejarás de recibir mensajes. Puedes volver a entrar con el ID del chat.';

  @override
  String get chatLeave => 'Salir';

  @override
  String get chatConferenceNote => 'Conferencia antigua: aquí no están disponibles los metadatos de transmisión Morse (v2). El texto sigue funcionando.';

  @override
  String get chatClearHistory => 'Borrar historial';

  @override
  String get chatModeStraightKey => 'Llave vertical';

  @override
  String get chatModePaddles => 'Paletas';

  @override
  String get chatKeyMessage => 'Transmite tu mensaje en Morse';

  @override
  String get chatSend => 'Enviar';

  @override
  String get chatTooLong => 'Supera el límite de un mensaje de Tox';

  @override
  String get chatKeyHint => 'Usa la zona de llave o pulsa Espacio';

  @override
  String get chatPaddleHint => 'Toca las paletas o mantén Ctrl (izquierdo: punto; derecho: raya)';

  @override
  String get chatDeleteLast => 'Eliminar último carácter';

  @override
  String get chatNoFriends => 'Aún no hay amigos. Añade uno con su Tox ID.';

  @override
  String get chatNoRequests => 'No hay solicitudes pendientes';

  @override
  String get chatAddFriend => 'Añadir amigo';

  @override
  String get chatMyToxId => 'Mi Tox ID';

  @override
  String get chatToxIdLabel => 'Tox ID (76 caracteres hexadecimales)';

  @override
  String get chatToxIdInvalid => 'El Tox ID debe tener exactamente 76 caracteres hexadecimales';

  @override
  String get chatToxIdOwn => 'Ese es tu propio Tox ID';

  @override
  String get chatToxIdAlreadyFriend => 'Ya está en tu lista de amigos';

  @override
  String get chatRequestMessage => 'Mensaje';

  @override
  String get chatDefaultRequestMessage => 'DitMesh CQ';

  @override
  String get chatSendRequest => 'Enviar solicitud';

  @override
  String get chatRequestSent => 'Solicitud de amistad enviada';

  @override
  String get chatScanQr => 'Escanear QR';

  @override
  String get chatScanQrDesktopHint => 'Para escanear QR se necesita la cámara de un teléfono';

  @override
  String get chatScanQrTitle => 'Escanear un Tox ID';

  @override
  String get chatScanQrNotToxId => 'Este código QR no es un Tox ID';

  @override
  String get chatAccept => 'Aceptar';

  @override
  String get chatReject => 'Rechazar';

  @override
  String get chatCopied => 'Copiado al portapapeles';

  @override
  String get chatNoIdentity => 'No hay identidad cargada';

  @override
  String get chatRemoveFriend => 'Eliminar amigo';

  @override
  String get chatRemoveFriendTitle => '¿Eliminar a este amigo?';

  @override
  String get chatRemoveFriendBody => 'Ya no podrá enviarte mensajes.';

  @override
  String get chatRemove => 'Eliminar';

  @override
  String get chatNoGroups => 'Aún no hay grupos. Crea uno o entra con el ID del chat.';

  @override
  String get chatCreateGroup => 'Crear grupo';

  @override
  String get chatJoinGroup => 'Unirse a grupo';

  @override
  String get chatGroupName => 'Nombre del grupo';

  @override
  String get chatGroupNameRequired => 'Dale un nombre al grupo';

  @override
  String get chatAdvanced => 'Avanzado';

  @override
  String get chatLegacyConference => 'Conferencia antigua (clientes anteriores)';

  @override
  String get chatLegacyConferenceHint => 'No recomendado: sin ID permanente ni metadatos Morse.';

  @override
  String get chatCreate => 'Crear';

  @override
  String get chatChatIdLabel => 'ID del chat (64 caracteres hexadecimales)';

  @override
  String get chatChatIdInvalid => 'El ID del chat debe tener exactamente 64 caracteres hexadecimales';

  @override
  String get chatPassword => 'Contraseña (opcional)';

  @override
  String get chatJoin => 'Unirse';

  @override
  String get chatJoinRequested => 'Uniéndote: el grupo aparecerá cuando se encuentre un miembro.';

  @override
  String get chatConferenceBadge => 'Conferencia';

  @override
  String get chatCopyChatId => 'Copiar ID del chat';

  @override
  String get learnLessonCardTitle => 'Lección Koch';

  @override
  String get learnCourseComplete => 'Curso completado: ¡sigue perfeccionándote!';

  @override
  String get learnDailyGoalTitle => 'Hoy';

  @override
  String get learnDailyGoalMet => 'Objetivo diario alcanzado';

  @override
  String get learnNoStreak => 'Empieza hoy una racha';

  @override
  String get learnContinueLesson => 'Continuar lección';

  @override
  String get learnReceivePractice => 'Práctica de recepción';

  @override
  String get learnSendPractice => 'Práctica de transmisión';

  @override
  String get learnReviewDue => 'Repasar caracteres pendientes';

  @override
  String get learnSettings => 'Ajustes de entrenamiento';

  @override
  String get learnLoading => 'Cargando tu progreso...';

  @override
  String get learnIdentityRequired => 'Crea o desbloquea tu identidad para entrenar. El progreso se guarda con ella y se incluye en la copia de seguridad.';

  @override
  String get learnLoadFailed => 'No se pudo leer tu progreso. Empezarás de nuevo; el archivo anterior se conservó como .corrupt.';

  @override
  String get learnProgressSaveFailed => 'No se pudo guardar tu progreso. El resultado cuenta mientras DitMesh siga abierto.';

  @override
  String get learnChooseDrill => 'Elige un ejercicio';

  @override
  String get learnDrillGroups => 'Grupos aleatorios';

  @override
  String get learnDrillWords => 'Palabras';

  @override
  String get learnDrillCallsigns => 'Indicativos';

  @override
  String get learnDrillQso => 'QSO';

  @override
  String get learnDrillCharacters => 'Caracteres sueltos';

  @override
  String get learnDrillAbbreviations => 'Abreviaturas y códigos Q';

  @override
  String get learnDrillNumbers => 'Grupos de números';

  @override
  String get learnDrillConfusables => 'Caracteres similares';

  @override
  String get learnDrillContest => 'Intercambio de concurso';

  @override
  String get learnDrillGroupsHint => 'Grupos aleatorios con todos los caracteres que conoces';

  @override
  String get learnDrillCharactersHint => 'Un carácter cada vez: reconócelo al instante';

  @override
  String get learnDrillWordsHint => 'Palabras habituales en inglés';

  @override
  String get learnDrillAbbreviationsHint => 'TNX, FB, QTH, QSL: abreviaturas usadas en radio';

  @override
  String get learnDrillNumbersHint => 'Grupos de cinco dígitos, como en mensajes y números de serie';

  @override
  String get learnDrillCallsignsHint => 'Indicativos de radioaficionados de todo el mundo';

  @override
  String get learnDrillConfusablesHint => 'Pares que confundes, como S/H o U/V, uno junto al otro';

  @override
  String get learnDrillQsoHint => 'Frases de un contacto completo';

  @override
  String get learnDrillContestHint => 'Indicativo, 5NN y número de serie o zona, al ritmo de un concurso';

  @override
  String get learnDrillReviewHint => 'Caracteres pendientes de repaso';

  @override
  String get toolsTitle => 'Herramientas de radio';

  @override
  String get toolsGridTitle => 'Localizador';

  @override
  String get toolsGridHint => 'Localizador por coordenadas, distancia y rumbo de antena';

  @override
  String get toolsBandsTitle => 'Bandas y antenas';

  @override
  String get toolsBandsHint => 'Banda de una frecuencia, longitud de onda y longitud del dipolo';

  @override
  String get toolsSpeedTitle => 'Velocidad CW';

  @override
  String get toolsSpeedHint => 'De WPM a duración del punto, intervalos y caracteres por minuto';

  @override
  String get toolsRstTitle => 'Reporte RST';

  @override
  String get toolsRstHint => 'Crea un reporte de señal y consulta el significado de cada dígito';

  @override
  String get toolsClockTitle => 'Reloj UTC';

  @override
  String get toolsClockHint => 'Hora UTC para el registro, junto a tu hora local';

  @override
  String get toolsGridFromCoordinates => 'Desde coordenadas';

  @override
  String get toolsGridLatitude => 'Latitud';

  @override
  String get toolsGridLongitude => 'Longitud';

  @override
  String get toolsGridCoordinatesHelp => 'Grados decimales; sur y oeste son negativos';

  @override
  String get toolsGridInvalidCoordinates => 'Latitud de -90 a 90, longitud de -180 a 180';

  @override
  String get toolsGridLocator => 'Localizador';

  @override
  String get toolsGridDistanceSection => 'Distancia y rumbo';

  @override
  String get toolsGridMine => 'Mi localizador';

  @override
  String get toolsGridTheirs => 'Localizador remoto';

  @override
  String get toolsGridInvalidLocator => 'Usa 2, 4, 6 u 8 caracteres, p. ej., OM89ex';

  @override
  String get toolsGridCenter => 'Centro de la cuadrícula';

  @override
  String get toolsGridDistance => 'Distancia';

  @override
  String get toolsGridShortPath => 'Rumbo por vía corta';

  @override
  String get toolsGridLongPath => 'Rumbo por vía larga';

  @override
  String get toolsBandsFrequency => 'Frecuencia (MHz)';

  @override
  String get toolsBandsInvalidFrequency => 'Introduce una frecuencia mayor que 0';

  @override
  String toolsBandsRegionLabel(int number) {
    return 'Región $number';
  }

  @override
  String get toolsBandsRegionHelp => '1: Europa, África, Oriente Medio · 2: América · 3: Asia-Pacífico';

  @override
  String toolsBandsInBand(String band) {
    return 'En la banda de radioaficionados de $band';
  }

  @override
  String get toolsBandsOutOfBand => 'Fuera de las bandas de radioaficionados';

  @override
  String get toolsBandsWavelength => 'Longitud de onda';

  @override
  String get toolsBandsDipole => 'Dipolo de media onda (total)';

  @override
  String get toolsBandsQuarterWave => 'Vertical de cuarto de onda';

  @override
  String get toolsBandsAntennaNote => 'Las longitudes incluyen un factor de acortamiento de 0,95; recorta hasta la resonancia.';

  @override
  String get toolsBandsTable => 'Límites de banda';

  @override
  String toolsBandsQrp(String frequency) {
    return 'QRP CW $frequency';
  }

  @override
  String get toolsBandsDisclaimer => 'Asignaciones de la ITU. Tu licencia y el plan nacional de bandas pueden ser más restrictivos.';

  @override
  String get toolsSpeedCharacter => 'Velocidad de los caracteres';

  @override
  String get toolsSpeedFarnsworth => 'Espaciado Farnsworth';

  @override
  String get toolsSpeedOverall => 'Velocidad global';

  @override
  String get toolsSpeedDit => 'Punto';

  @override
  String get toolsSpeedDah => 'Raya';

  @override
  String get toolsSpeedCharGap => 'Intervalo entre caracteres';

  @override
  String get toolsSpeedWordGap => 'Intervalo entre palabras';

  @override
  String get toolsSpeedCpm => 'Caracteres por minuto';

  @override
  String get toolsSpeedParis => 'Una palabra PARIS';

  @override
  String get toolsRstReadability => 'Legibilidad (R)';

  @override
  String get toolsRstStrength => 'Intensidad (S)';

  @override
  String get toolsRstTone => 'Tono (T)';

  @override
  String get toolsRstReport => 'Reporte';

  @override
  String get toolsRstCut => 'Forma de concurso';

  @override
  String get toolsRstPhone => 'En voz (sin tono)';

  @override
  String get toolsRstR1 => 'Ilegible';

  @override
  String get toolsRstR2 => 'Apenas legible, palabras sueltas';

  @override
  String get toolsRstR3 => 'Legible con mucha dificultad';

  @override
  String get toolsRstR4 => 'Legible casi sin dificultad';

  @override
  String get toolsRstR5 => 'Perfectamente legible';

  @override
  String get toolsRstS1 => 'Tenue, apenas perceptible';

  @override
  String get toolsRstS2 => 'Muy débil';

  @override
  String get toolsRstS3 => 'Débil';

  @override
  String get toolsRstS4 => 'Aceptable';

  @override
  String get toolsRstS5 => 'Bastante buena';

  @override
  String get toolsRstS6 => 'Buena';

  @override
  String get toolsRstS7 => 'Moderadamente fuerte';

  @override
  String get toolsRstS8 => 'Fuerte';

  @override
  String get toolsRstS9 => 'Extremadamente fuerte';

  @override
  String get toolsRstT1 => 'Muy áspero y ancho, AC sin rectificar';

  @override
  String get toolsRstT2 => 'AC muy áspera, estridente y ancha';

  @override
  String get toolsRstT3 => 'Áspero, rectificado sin filtrar';

  @override
  String get toolsRstT4 => 'Áspero, con algo de filtrado';

  @override
  String get toolsRstT5 => 'Filtrado, con fuerte modulación de rizado';

  @override
  String get toolsRstT6 => 'Filtrado, con rizado evidente';

  @override
  String get toolsRstT7 => 'Casi puro, con algo de rizado';

  @override
  String get toolsRstT8 => 'Casi perfecto, con leve modulación';

  @override
  String get toolsRstT9 => 'Tono perfecto, sin rizado';

  @override
  String get toolsClockUtc => 'UTC';

  @override
  String get toolsClockLocal => 'Hora local';

  @override
  String get toolsClockNote => 'Los registros de contactos y las tarjetas QSL usan UTC.';

  @override
  String get learnReceiveTitle => 'Recepción';

  @override
  String get learnReviewTitle => 'Repaso';

  @override
  String get learnListen => 'Escucha...';

  @override
  String get learnReady => 'Listo';

  @override
  String get learnReplay => 'Repetir audio';

  @override
  String get learnAnswerHint => 'Escribe lo que has oído';

  @override
  String get learnSubmit => 'Comprobar';

  @override
  String get learnNext => 'Siguiente';

  @override
  String get learnFinish => 'Finalizar';

  @override
  String get learnDone => 'Hecho';

  @override
  String get learnBackspace => 'Eliminar';

  @override
  String get learnSpace => 'Espacio';

  @override
  String get learnSent => 'Transmitido';

  @override
  String get learnYourCopy => 'Tu recepción';

  @override
  String get learnRoundPerfect => '¡Recepción perfecta!';

  @override
  String get learnSessionSummary => 'Resumen de la sesión';

  @override
  String get learnLessonPassed => 'Lección superada';

  @override
  String get learnLessonNotPassed => 'Sigue practicando: el 90% desbloquea el siguiente carácter';

  @override
  String get learnReviewRecorded => 'Repaso registrado';

  @override
  String get learnWeakChars => 'Por mejorar';

  @override
  String get learnConfusions => 'Confusiones';

  @override
  String get learnNoFeedbackWarning => 'Sonido, destellos y vibración desactivados: la pantalla parpadeará en su lugar.';

  @override
  String get learnSendTitle => 'Transmisión';

  @override
  String get learnSendThis => 'Transmite esto';

  @override
  String get learnCopyFromMemory => 'De memoria';

  @override
  String get learnHiddenTarget => 'Oculto: transmítelo de memoria';

  @override
  String get learnDecoded => 'Decodificado';

  @override
  String get learnWaitingForKey => 'Empieza a transmitir cuando estés listo';

  @override
  String get learnRestart => 'Reiniciar';

  @override
  String get learnTryAnother => 'Probar otro';

  @override
  String get learnKeyerStraight => 'Vertical';

  @override
  String get learnKeyerIambicA => 'Yámbico A';

  @override
  String get learnKeyerIambicB => 'Yámbico B';

  @override
  String get learnLegendStraight => 'Espacio = llave';

  @override
  String get learnLegendPaddles => 'Ctrl izquierdo = punto; Ctrl derecho = raya';

  @override
  String get learnSendClean => 'Transmisión limpia: no hay nada que corregir.';

  @override
  String get learnSendIssues => 'Consejos de ritmo';

  @override
  String get learnYourSending => 'Decodificado como';

  @override
  String get learnStraightKeyLabel => 'LLAVE';

  @override
  String get learnDitLabel => 'PUNTO';

  @override
  String get learnDahLabel => 'RAYA';

  @override
  String get learnSettingsTitle => 'Ajustes de entrenamiento';

  @override
  String get learnCharacterSpeed => 'Velocidad de los caracteres';

  @override
  String get learnFarnsworth => 'Espaciado Farnsworth';

  @override
  String get learnFarnsworthHelp => 'Los caracteres siguen siendo rápidos; sus intervalos se alargan hasta esta velocidad.';

  @override
  String get learnEffectiveSpeed => 'Velocidad efectiva';

  @override
  String get learnTone => 'Tono';

  @override
  String get learnPlaySample => 'Reproducir ejemplo';

  @override
  String get learnSessionLength => 'Caracteres por sesión';

  @override
  String get learnFeedback => 'Respuesta sensorial';

  @override
  String get learnSound => 'Sonido';

  @override
  String get learnFlash => 'Destello de pantalla';

  @override
  String get learnHaptic => 'Vibración';

  @override
  String get learnKeyer => 'Manipulador';

  @override
  String get learnDailyGoal => 'Objetivo diario';

  @override
  String get referenceReferenceTitle => 'Referencia de Morse';

  @override
  String get referenceTranslatorTitle => 'Traductor';

  @override
  String get referencePlay => 'Reproducir';

  @override
  String get referenceStop => 'Detener';

  @override
  String get referenceClear => 'Borrar';

  @override
  String get referenceClose => 'Cerrar';

  @override
  String get referenceEmptyOutput => '—';

  @override
  String get referenceSearchHint => 'Buscar caracteres, señales de procedimiento, códigos Q…';

  @override
  String get referenceClearSearch => 'Borrar búsqueda';

  @override
  String get referenceNoResults => 'No hay resultados para tu búsqueda.';

  @override
  String get referenceSectionAlphabet => 'Alfabeto';

  @override
  String get referenceSectionPunctuation => 'Puntuación';

  @override
  String get referenceSectionProsigns => 'Señales de procedimiento';

  @override
  String get referenceSectionQCodes => 'Códigos Q';

  @override
  String get referenceSectionAbbreviations => 'Abreviaturas CW';

  @override
  String get referenceSectionKoch => 'Orden Koch';

  @override
  String get referenceAlphabetHint => 'Toca una tarjeta para escucharla. Mantenla pulsada para ver una regla mnemotécnica.';

  @override
  String get referenceKochHint => 'Orden de introducción de caracteres del método Koch (secuencia LCWO). Empieza con K y M; añade uno al alcanzar un 90% de recepción correcta.';

  @override
  String get referenceMnemonicTitle => 'Regla mnemotécnica';

  @override
  String get referenceMeaningLabel => 'Significado';

  @override
  String get referencePlaybackSettings => 'Ajustes de reproducción';

  @override
  String get referenceCharacterSpeed => 'Velocidad de los caracteres';

  @override
  String get referenceFarnsworth => 'Espaciado Farnsworth';

  @override
  String get referenceFarnsworthHelp => 'Los caracteres mantienen su velocidad; los intervalos se alargan hasta la velocidad efectiva.';

  @override
  String get referenceEffectiveSpeed => 'Velocidad efectiva';

  @override
  String get referenceTone => 'Tono';

  @override
  String get referenceModeTextToMorse => 'Texto → Morse';

  @override
  String get referenceModeMorseToText => 'Morse → Texto';

  @override
  String get referenceModeKey => 'Transmitir';

  @override
  String get referenceTextInputLabel => 'Texto';

  @override
  String get referenceTextInputHint => 'Escribe el texto que quieres codificar…';

  @override
  String get referencePatternOutputLabel => 'Morse';

  @override
  String get referenceCopyPattern => 'Copiar código';

  @override
  String get referencePatternCopied => 'Código copiado';

  @override
  String get referencePatternInputLabel => 'Morse';

  @override
  String get referencePatternInputHint => 'Escribe . y -, un espacio entre letras y / entre palabras';

  @override
  String get referenceTextOutputLabel => 'Texto';

  @override
  String get referenceCopyText => 'Copiar texto';

  @override
  String get referenceTextCopied => 'Texto copiado';

  @override
  String get referenceUnknownPatternHelp => 'Los códigos sin carácter correspondiente se muestran como <código>.';

  @override
  String get referenceKeypadDit => 'Punto';

  @override
  String get referenceKeypadDah => 'Raya';

  @override
  String get referenceKeypadCharGap => 'Intervalo entre letras';

  @override
  String get referenceKeypadWordGap => 'Intervalo entre palabras';

  @override
  String get referenceKeypadBackspace => 'Retroceso';

  @override
  String get referenceKeyHint => 'Mantén pulsada la llave para transmitir. Con un teclado, mantén Espacio.';

  @override
  String get referenceKeyLabel => 'LLAVE';

  @override
  String get referenceKeyDecodedLabel => 'Decodificado';

  @override
  String get referenceKeyPendingLabel => 'Transmitiendo';

  @override
  String get statsTitle => 'Estadísticas';

  @override
  String get statsLoading => 'Cargando tus estadísticas...';

  @override
  String get statsLoadFailed => 'No se pudo cargar tu progreso. Desliza hacia abajo o vuelve a abrir para reintentar.';

  @override
  String get statsRetry => 'Reintentar';

  @override
  String get statsEmptyTitle => 'Aún no hay sesiones';

  @override
  String get statsEmptyBody => 'Termina tu primera sesión de recepción o transmisión y aquí aparecerán la evolución de precisión, el dominio de cada carácter y un calendario de práctica.';

  @override
  String get statsEmptyCallToAction => 'Ve a Aprender y pulsa «Continuar lección» para empezar.';

  @override
  String get statsOverviewTitle => 'Vista general';

  @override
  String get statsTileLesson => 'Lección Koch';

  @override
  String get statsTileAccuracy => 'Precisión';

  @override
  String get statsNoData => '--';

  @override
  String get statsTilePractice => 'Práctica';

  @override
  String get statsTileStreak => 'Racha';

  @override
  String get statsTileDailyGoal => 'Objetivo diario';

  @override
  String get statsGoalMet => 'Alcanzado hoy';

  @override
  String get statsSummaryTitle => 'Tus estadísticas';

  @override
  String get statsSummaryOpen => 'Ver estadísticas';

  @override
  String get statsTrendTitle => 'Evolución de precisión';

  @override
  String get statsTrendHint => 'Toca un punto para consultar la sesión.';

  @override
  String get statsSeriesReceive => 'Recepción';

  @override
  String get statsSeriesSend => 'Transmisión';

  @override
  String get statsAxisSessions => 'Sesión';

  @override
  String get statsCharsTitle => 'Caracteres';

  @override
  String get statsCharsSubtitle => 'Orden Koch. Toca un carácter para ver los detalles.';

  @override
  String get statsCharsNotStarted => 'Aún sin practicar';

  @override
  String get statsNotInCourse => 'No forma parte del curso Koch';

  @override
  String get statsSrsTitle => 'Repetición espaciada';

  @override
  String get statsSrsNotTracked => 'Aún sin programar';

  @override
  String get statsSrsDueNow => 'Repasar ahora';

  @override
  String get statsConfusionsTitle => 'Se confunde más con';

  @override
  String get statsConfusionsNone => 'No hay confusiones registradas';

  @override
  String get statsConfusionMissed => 'omitido';

  @override
  String get statsBucketLegendTitle => 'Precisión';

  @override
  String get statsBucketNone => 'Ninguna';

  @override
  String get statsBucketWeak => '< 70%';

  @override
  String get statsBucketFair => '70-89%';

  @override
  String get statsBucketGood => '90-97%';

  @override
  String get statsBucketStrong => '>= 98%';

  @override
  String get statsHeatmapTitle => 'Confusiones';

  @override
  String get statsHeatmapSubtitle => 'Las filas muestran el carácter transmitido y las columnas tu respuesta. Cuanto más oscuro, más frecuente.';

  @override
  String get statsHeatmapEmpty => 'Aún no hay confusiones. Las respuestas incorrectas aparecerán aquí.';

  @override
  String get statsHeatmapLegendLow => 'Poco frecuente';

  @override
  String get statsHeatmapLegendHigh => 'Frecuente';

  @override
  String get statsHeatmapAxisTarget => 'Transmitido';

  @override
  String get statsHeatmapAxisAnswered => 'Respondido';

  @override
  String get statsCalendarTitle => 'Calendario de práctica';

  @override
  String get statsCalendarSubtitle => 'Últimas 12 semanas';

  @override
  String get statsCalendarLegendLess => 'Menos';

  @override
  String get statsCalendarLegendMore => 'Más';

  @override
  String get statsStreakExplanation => 'Una racha cuenta los días consecutivos con al menos una sesión. Saltarse un día completo la reinicia; practicar dos veces en un día solo cuenta como un día.';

  @override
  String get learnStatistics => 'Estadísticas';

  @override
  String get listenTitle => 'Escuchar';

  @override
  String get listenStart => 'Iniciar';

  @override
  String get listenStop => 'Detener';

  @override
  String get listenStarting => 'Iniciando micrófono...';

  @override
  String get listenClear => 'Borrar texto';

  @override
  String get listenCopy => 'Copiar texto';

  @override
  String get listenCopied => 'Texto decodificado copiado';

  @override
  String get listenSettings => 'Ajustes de escucha';

  @override
  String get listenDecoded => 'Decodificado';

  @override
  String get listenEmptyHint => 'Acerca el micrófono a un tono Morse. El texto decodificado aparecerá aquí.';

  @override
  String get listenIdleHint => 'Toca Iniciar para escuchar un tono Morse.';

  @override
  String get listenPending => 'Recibiendo';

  @override
  String get listenSpeed => 'Velocidad';

  @override
  String get listenSpeedUnknown => '-- WPM';

  @override
  String get listenLevel => 'Señal';

  @override
  String get listenToneOn => 'Tono';

  @override
  String get listenTone => 'Frecuencia del tono';

  @override
  String get listenToneLocked => 'Fijada';

  @override
  String get listenToneSearching => 'Buscando';

  @override
  String get listenToneManual => 'Manual';

  @override
  String get listenAutoTune => 'Sintonización automática';

  @override
  String get listenAutoTuneHelp => 'Sigue el tono más fuerte entre 400 y 1000 Hz. Arrastra el control para sintonizar manualmente.';

  @override
  String get listenRetune => 'Automático';

  @override
  String get listenBlockSize => 'Bloque de análisis';

  @override
  String get listenBlockSizeHelp => 'Los bloques pequeños sitúan los bordes de los elementos con más precisión, pero captan más ruido. 256 muestras (5,3 ms) sirven para 5–40 WPM.';

  @override
  String get listenMinElement => 'Elemento más corto';

  @override
  String get listenMinElementHelp => 'Los tonos y pausas más cortos se ignoran como chasquidos y cortes de señal.';

  @override
  String get listenPermissionDenied => 'Se denegó el acceso al micrófono. Permítelo en los ajustes del sistema e inténtalo de nuevo.';

  @override
  String get listenPermissionRetry => 'Intentar de nuevo';

  @override
  String get listenStartFailed => 'No se pudo iniciar el micrófono.';

  @override
  String get listenNoInput => 'No se encontró ningún micrófono. Conecta uno e inténtalo de nuevo.';

  @override
  String get listenStreamFailed => 'El micrófono se detuvo inesperadamente. Inténtalo de nuevo.';

  @override
  String listenWpmValue(int wpm) {
    return '$wpm WPM';
  }

  @override
  String listenHzValue(int hz) {
    return '$hz Hz';
  }

  @override
  String listenBlockSamples(int samples, String ms) {
    return '$samples muestras ($ms ms)';
  }

  @override
  String listenMsValue(int ms) {
    return '$ms ms';
  }

  @override
  String get listenStoppedInBackground => 'La escucha se detuvo mientras la aplicación estaba en segundo plano.';

  @override
  String get learnWpmUnknown => '-- WPM';

  @override
  String get learnTipDitTooLongTitle => 'Puntos demasiado largos';

  @override
  String get learnTipDahTooShortTitle => 'Rayas demasiado cortas';

  @override
  String get learnTipIntraGapTooLongTitle => 'Elementos muy separados';

  @override
  String get learnTipCharGapTooShortTitle => 'Caracteres muy juntos';

  @override
  String get learnTipWordGapTooShortTitle => 'Palabras muy juntas';

  @override
  String get learnTipSpeedUnsteadyTitle => 'Velocidad irregular';

  @override
  String get learnSeverityMinor => 'leve';

  @override
  String get learnSeverityModerate => 'perceptible';

  @override
  String get learnSeveritySevere => 'grave';

  @override
  String get notificationOpen => 'Abrir';

  @override
  String get notificationChannelMessages => 'Mensajes';

  @override
  String get notificationChannelMessagesDescription => 'Nuevos mensajes Morse de amigos y grupos';

  @override
  String get notificationChannelFriendRequests => 'Solicitudes de amistad';

  @override
  String get notificationChannelFriendRequestsDescription => 'Alguien quiere añadirte como amigo';

  @override
  String get notificationChannelGroupInvites => 'Invitaciones a grupos';

  @override
  String get notificationChannelGroupInvitesDescription => 'Un amigo te ha invitado a un grupo';

  @override
  String get notificationNewMessage => 'Nuevo mensaje';

  @override
  String get notificationFriendRequestTitle => 'Nueva solicitud de amistad';

  @override
  String learnNewestCharIs(String char) {
    return 'Nuevo en esta lección: $char';
  }

  @override
  String learnCharNewSemantics(String char) {
    return '$char, nuevo';
  }

  @override
  String learnPendingPattern(String pattern) {
    return 'Transmitiendo: $pattern';
  }

  @override
  String learnIssueHeadline(String title, String severity) {
    return '$title ($severity)';
  }

  @override
  String learnRatioTimes(String ratio) {
    return '$ratio×';
  }

  @override
  String learnTipDitTooLong(String ratio) {
    return 'Tus puntos son largos (aproximadamente $ratio de un punto). Piensa «di», no «daah»: un punto es un toque, no una pulsación prolongada.';
  }

  @override
  String learnTipDahTooShort(String ratio) {
    return 'Tus rayas son cortas (aproximadamente $ratio de un punto; el objetivo es 3). Mantén la raya durante tres puntos.';
  }

  @override
  String learnTipIntraGapTooLong(String ratio) {
    return 'Los intervalos dentro de los caracteres son amplios (aproximadamente $ratio de un punto). Mantén juntos los elementos de cada carácter.';
  }

  @override
  String learnTipCharGapTooShort(String ratio) {
    return 'Los caracteres se juntan (intervalos de aproximadamente $ratio de un punto; el objetivo es 3). Deja una pausa clara después de cada carácter.';
  }

  @override
  String learnTipWordGapTooShort(String ratio) {
    return 'Las palabras están muy juntas (intervalos de aproximadamente $ratio de un punto; el objetivo es 7). Cuenta una pausa larga entre palabras.';
  }

  @override
  String learnTipSpeedUnsteady(int percent) {
    return 'Tu velocidad varía (variación del $percent%). Elige un ritmo y mantenlo durante toda la línea.';
  }

  @override
  String learnIssueDetailDitTooLong(int offending, int total, String ratio) {
    return '$offending de $total puntos demasiado largos (media: $ratio puntos)';
  }

  @override
  String learnIssueDetailDahTooShort(int offending, int total, String ratio) {
    return '$offending de $total rayas demasiado cortas (media: $ratio puntos)';
  }

  @override
  String learnIssueDetailIntraGapTooLong(int offending, int total, String ratio) {
    return '$offending de $total intervalos dentro de caracteres demasiado largos (media: $ratio puntos)';
  }

  @override
  String learnIssueDetailCharGapTooShort(int offending, int total, String ratio) {
    return '$offending de $total intervalos entre caracteres demasiado cortos (media: $ratio puntos)';
  }

  @override
  String learnIssueDetailWordGapTooShort(int offending, int total, String ratio) {
    return '$offending de $total intervalos entre palabras demasiado cortos (media: $ratio puntos)';
  }

  @override
  String learnIssueDetailSpeedUnsteady(String cv) {
    return 'Velocidad de transmisión irregular (coef. de variación: $cv)';
  }

  @override
  String statsAccuracyDetail(String allTime) {
    return 'Últimos 7 días / total: $allTime';
  }

  @override
  String statsDurationHoursMinutes(int hours, int minutes) {
    return '$hours h $minutes min';
  }

  @override
  String statsDurationMinutes(int minutes) {
    return '$minutes min';
  }

  @override
  String statsDurationSeconds(int seconds) {
    return '$seconds s';
  }

  @override
  String get accountNewPasswordRequired => 'Introduce una nueva contraseña';

  @override
  String get accountToxIdQrSemantics => 'Código QR del Tox ID';

  @override
  String get accountBackupSaveDialogTitle => 'Guardar copia de DitMesh';

  @override
  String get accountBackupShareSubject => 'Copia de seguridad de identidad DitMesh';

  @override
  String get accountBackupChooseDialogTitle => 'Elegir copia de DitMesh';

  @override
  String notificationNewMessages(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count mensajes nuevos',
      one: '$count mensaje nuevo',
    );
    return '$_temp0';
  }

  @override
  String notificationFriendRequestFrom(String name) {
    return 'Solicitud de amistad de $name';
  }

  @override
  String notificationFriendRequestBody(String name, String message) {
    return '$name: $message';
  }

  @override
  String notificationGroupInviteTitle(String group) {
    return 'Invitación a $group';
  }

  @override
  String notificationGroupInviteBody(String name) {
    return '$name te ha invitado';
  }

  @override
  String desktopTrayShow(String app) {
    return 'Mostrar $app';
  }

  @override
  String desktopTrayHide(String app) {
    return 'Ocultar $app';
  }

  @override
  String get desktopTraySoundOn => 'Sonido activado';

  @override
  String get desktopTraySoundOff => 'Sonido desactivado';

  @override
  String desktopTrayQuit(String app) {
    return 'Salir de $app';
  }

  @override
  String desktopTrayTooltipUnread(String app, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count mensajes sin leer',
      one: '$count mensaje sin leer',
    );
    return '$app — $_temp0';
  }

  @override
  String desktopWindowTitleUnread(String badge, String app) {
    return '($badge) $app';
  }

  @override
  String get listenStateOn => 'Activado';

  @override
  String get listenStateOff => 'Desactivado';

  @override
  String chatBytesLeftCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Quedan $count bytes',
      one: 'Queda $count byte',
    );
    return '$_temp0';
  }

  @override
  String chatMemberCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count miembros',
      one: '$count miembro',
    );
    return '$_temp0';
  }

  @override
  String chatFriendsCount(int count) {
    return 'Amigos ($count)';
  }

  @override
  String chatFriendRequestsCount(int count) {
    return 'Solicitudes de amistad ($count)';
  }

  @override
  String chatGroupInvitesCount(int count) {
    return 'Invitaciones a grupos ($count)';
  }

  @override
  String chatMembersTitleCount(int count) {
    return 'Miembros · $count';
  }

  @override
  String chatInvitedByName(String name) {
    return 'Invitado por $name';
  }

  @override
  String chatMemberSelf(String name) {
    return '$name (tú)';
  }

  @override
  String chatSliderValue(String label, int value, String unit) {
    return '$label: $value $unit';
  }

  @override
  String referenceTelegraphCodes(String codes) {
    return 'Código telegráfico chino: $codes';
  }

  @override
  String get referenceTelegraphMainland => 'China continental 1983';

  @override
  String get referenceTelegraphTaiwan => 'Taiwán / Hong Kong';

  @override
  String get referenceTelegraphNone => 'No figura en este código';

  @override
  String get appearanceTitle => 'Apariencia';

  @override
  String get appearanceStyles => 'Estilo de interfaz';

  @override
  String get appearanceChoose => 'Elige un estilo, previsualízalo y aplícalo';

  @override
  String get appearanceMode => 'Brillo';

  @override
  String get appearancePreview => 'Vista previa';

  @override
  String get appearanceApply => 'Aplicar estilo';

  @override
  String get appearanceRestore => 'Restaurar valores predeterminados';

  @override
  String get appearanceApplied => 'Apariencia guardada';

  @override
  String get appearanceSaveFailed => 'No se pudo guardar la apariencia. Inténtalo de nuevo.';

  @override
  String get appearanceClassic => 'Latón clásico';

  @override
  String get appearanceModern => 'Calma moderna';

  @override
  String get appearanceRadio => 'Radio nocturna';

  @override
  String get appearancePaper => 'Manual de papel';

  @override
  String get appearanceCartoon => 'Dibujos frescos';

  @override
  String get appearanceLight => 'Claro';

  @override
  String get appearanceDark => 'Oscuro';

  @override
  String get appearanceSubtitle => 'Cinco estilos con modos claro y oscuro';

  @override
  String get chatClearHistoryBody => '¿Eliminar el historial de esta conversación de este dispositivo? Las copias de otros dispositivos no se verán afectadas. No se puede deshacer.';

  @override
  String get chatLoadEarlier => 'Cargar mensajes anteriores';

  @override
  String get chatHistoryLoadFailed => 'No se pudieron cargar los mensajes anteriores. Toca para reintentar.';

  @override
  String get chatRetryHistory => 'Reintentar';

  @override
  String chatNewMessages(int count) {
    return '$count mensajes nuevos';
  }

  @override
  String learnShowAllChars(int count) {
    return 'Mostrar los $count caracteres';
  }

  @override
  String get chatSelfMe => 'Yo';

  @override
  String get chatSelfLocalOnly => 'Guardado solo en este dispositivo';

  @override
  String get chatSelfContactSubtitle => 'Borradores, práctica y notas · nunca se envían';

  @override
  String get learnShowFewerChars => 'Mostrar menos caracteres';

  @override
  String get learnLeaveDrillTitle => '¿Salir de esta sesión?';

  @override
  String get learnLeaveDrillBody => 'Las rondas de esta sesión no se guardarán.';

  @override
  String get learnLeaveDrillConfirm => 'Salir';

  @override
  String get chatScanQrPermissionDenied => 'DitMesh necesita acceso a la cámara para escanear un código QR. Permítelo en los ajustes del sistema.';

  @override
  String get chatScanQrCameraUnavailable => 'La cámara no está disponible en este dispositivo.';

  @override
  String get learnReplayAssistedNote => 'Repetido: esta sesión cuenta como práctica, pero no desbloquea lecciones ni actualiza repasos.';

  @override
  String get learnPlanTitle => 'Plan de hoy';

  @override
  String learnPlanSummary(int minutes, int done, int total) {
    return 'Unos $minutes min · $done de $total pasos';
  }

  @override
  String get learnPlanBudget => 'Duración del plan';

  @override
  String learnPlanBudgetMinutes(int minutes) {
    return '$minutes min';
  }

  @override
  String get learnPlanStart => 'Empezar el plan';

  @override
  String get learnPlanContinue => 'Continuar el plan';

  @override
  String get learnPlanStepReview => 'Repasar símbolos pendientes';

  @override
  String get learnPlanStepFocus => 'Práctica enfocada';

  @override
  String learnPlanStepCourse(int lesson) {
    return 'Lección $lesson';
  }

  @override
  String get learnPlanStepSend => 'Práctica de transmisión';

  @override
  String learnPlanReasonDueReview(String symbols) {
    return 'Toca repasar: $symbols';
  }

  @override
  String learnPlanReasonConfusions(String symbols) {
    return 'Se confunden a menudo: $symbols';
  }

  @override
  String learnPlanReasonWeak(String symbols) {
    return 'Por debajo del 90 %: $symbols';
  }

  @override
  String learnPlanReasonChallenge(int count) {
    return '$count símbolos: puede desbloquear la siguiente lección';
  }

  @override
  String learnPlanReasonExtended(int count) {
    return 'Ampliado a $count símbolos para poder desbloquear la siguiente lección';
  }

  @override
  String get learnPlanReasonConsolidate => 'Sesión corta: consolida la lección, no desbloquea la siguiente';

  @override
  String learnPlanReasonOutdated(int lesson) {
    return 'Tu curso avanzó: practica la lección $lesson sin desbloquear';
  }

  @override
  String learnPlanReasonSend(int count) {
    return '$count objetivos cortos para manipular';
  }

  @override
  String learnPlanStepDonePercent(int percent) {
    return 'Hecho · $percent %';
  }

  @override
  String get learnPlanStepDone => 'Hecho';

  @override
  String learnPlanSendProgress(int done, int total) {
    return '$done de $total enviados';
  }

  @override
  String get learnPlanStale => 'Cambió tu lección o velocidad. ¿Actualizar los pasos sin empezar?';

  @override
  String get learnPlanUpdate => 'Actualizar pasos';

  @override
  String get learnPlanComplete => 'Plan de hoy completado';

  @override
  String learnPlanNeedsWork(String symbols) {
    return 'A reforzar: $symbols';
  }

  @override
  String get learnPlanAllGood => 'Hoy no hay símbolos flojos.';

  @override
  String get learnPlanTomorrow => 'Mañana llega un plan nuevo. La práctica libre siempre está disponible.';

  @override
  String learnPlanNext(String step) {
    return 'Siguiente: $step';
  }

  @override
  String learnPlanEarlier(int done, int total) {
    return 'El plan anterior quedó en $done de $total pasos; ya no cuenta para hoy.';
  }

  @override
  String learnSpeedAdviceRaise(int wpm) {
    return 'Listo para $wpm PPM de velocidad efectiva';
  }

  @override
  String learnSpeedAdviceRaiseBoth(int wpm) {
    return 'Listo para $wpm PPM';
  }

  @override
  String learnSpeedAdviceLower(int wpm) {
    return 'Copiar a esta velocidad cuesta. Prueba $wpm PPM efectivas o una práctica enfocada.';
  }

  @override
  String learnSpeedAdviceBody(int count, int percent) {
    return 'Según tus últimas $count sesiones sin ayuda ($percent %). Nada cambia hasta que lo apliques.';
  }

  @override
  String get learnSpeedAdviceApply => 'Aplicar';

  @override
  String get learnSpeedAdviceDismiss => 'Ahora no';

  @override
  String get learnSpeedAdviceInsufficient => 'El consejo de velocidad necesita 3 sesiones sin ayuda de 50+ símbolos a tu velocidad actual.';

  @override
  String get learnQsoAction => 'Simulador de QSO';

  @override
  String learnQsoLocked(int lesson) {
    return 'Desde la lección $lesson';
  }

  @override
  String get learnQsoTitle => 'Simulador de QSO';

  @override
  String get learnQsoRespond => 'Responder a un CQ';

  @override
  String get learnQsoRespondHint => 'Una estación llama CQ. Respóndele e intercambiad reportes.';

  @override
  String get learnQsoCall => 'Llamar CQ';

  @override
  String get learnQsoCallHint => 'Llamas CQ y una estación responde.';

  @override
  String get learnQsoYourCall => 'Tu indicativo';

  @override
  String get learnQsoYourName => 'Tu nombre';

  @override
  String get learnQsoYourQth => 'Tu QTH';

  @override
  String get learnQsoInvalidCall => 'Introduce un indicativo como BD1XYZ';

  @override
  String get learnQsoInvalidWord => 'Una palabra, solo letras A–Z';

  @override
  String get learnQsoOffline => 'Funciona por completo en este dispositivo. No se envía nada.';

  @override
  String get learnQsoStart => 'Empezar QSO';

  @override
  String get learnQsoResume => 'Reanudar el QSO sin terminar';

  @override
  String get learnQsoStageCallCq => 'Llama CQ con tu indicativo';

  @override
  String get learnQsoStageCallConfirm => 'Responde: su indicativo, DE, el tuyo';

  @override
  String get learnQsoStageExchange => 'Envía reporte, nombre y QTH';

  @override
  String get learnQsoStageConfirmInfo => 'Confirma su información';

  @override
  String get learnQsoStageClosing => 'Cierra con 73 y <SK>';

  @override
  String get learnQsoStageDone => 'QSO completado';

  @override
  String learnQsoSpeed(int wpm) {
    return 'El corresponsal transmite a $wpm PPM efectivas';
  }

  @override
  String learnQsoRemote(String call) {
    return '$call transmite';
  }

  @override
  String get learnQsoRemoteHidden => 'Copia de oído: el texto está oculto.';

  @override
  String get learnQsoShowText => 'Mostrar texto';

  @override
  String get learnQsoListen => 'Escuchar';

  @override
  String get learnQsoAccepted => 'Aceptado';

  @override
  String get learnQsoRejected => 'No aceptado';

  @override
  String get learnQsoRemoteSending => 'La otra estación está transmitiendo…';

  @override
  String get learnQsoYourTurn => 'Tu turno: manipula tu respuesta y pulsa Enviar.';

  @override
  String get learnQsoDecoded => 'Tu transmisión';

  @override
  String get learnQsoNothingKeyed => 'Aún no has manipulado nada';

  @override
  String get learnQsoPlayAgain => 'Pedir repetición (AGN)';

  @override
  String get learnQsoSlower => 'Pedir más despacio (QRS)';

  @override
  String get learnQsoHint => 'Pista';

  @override
  String learnQsoHintLabel(String example) {
    return 'Ejemplo: $example';
  }

  @override
  String get learnQsoPause => 'Pausa';

  @override
  String get learnQsoSend => 'Enviar';

  @override
  String get learnQsoClear => 'Borrar';

  @override
  String get learnQsoIssueEmpty => 'No se manipuló nada.';

  @override
  String get learnQsoIssueMissingCq => 'Empieza con CQ.';

  @override
  String get learnQsoIssueMissingDe => 'Pon DE entre los indicativos.';

  @override
  String get learnQsoIssueWrongLocalCall => 'Tu indicativo falta o es incorrecto.';

  @override
  String get learnQsoIssueWrongRemoteCall => 'El indicativo de la otra estación es incorrecto.';

  @override
  String get learnQsoIssueReversedCalls => 'Indicativos al revés: primero el suyo, luego DE y el tuyo.';

  @override
  String get learnQsoIssueMissingEnding => 'Termina con K o KN.';

  @override
  String get learnQsoIssueMissingRst => 'Da un reporte, p. ej. UR RST 599.';

  @override
  String get learnQsoIssueInvalidRst => 'Ese RST está fuera de rango (R 1–5, S 1–9, T 1–9).';

  @override
  String get learnQsoIssueMissingName => 'Envía NAME y tu nombre.';

  @override
  String get learnQsoIssueWrongName => 'Ese no es tu nombre en este QSO.';

  @override
  String get learnQsoIssueMissingQth => 'Envía QTH y tu ubicación.';

  @override
  String get learnQsoIssueWrongQth => 'Ese no es tu QTH en este QSO.';

  @override
  String get learnQsoIssueMissingAck => 'Confirma con R o QSL.';

  @override
  String get learnQsoIssueWrongRemoteName => 'Confirma el nombre del otro operador.';

  @override
  String get learnQsoIssueMissing73 => 'Incluye 73.';

  @override
  String get learnQsoIssueMissingSk => 'Termina el contacto con <SK>.';

  @override
  String learnQsoSummaryFields(int count, int total) {
    return 'Bien a la primera: $count de $total pasos';
  }

  @override
  String learnQsoSummaryRepeats(int count) {
    return 'Repeticiones: $count';
  }

  @override
  String learnQsoSummaryHints(int count) {
    return 'Pistas: $count';
  }

  @override
  String learnQsoSummaryRhythm(int wpm) {
    return 'Tu transmisión: unas $wpm PPM';
  }

  @override
  String get learnQsoSummaryNote => 'Los resultados de QSO van aparte de la precisión de copia y nunca desbloquean lecciones.';

  @override
  String get messageStatusCancelled => 'Cancelado: nunca se envió';

  @override
  String get chatMessageLearnActions => 'Acciones del mensaje';

  @override
  String get chatPracticeMessage => 'Practicar este mensaje';

  @override
  String get chatSaveAsMaterial => 'Guardar como material de práctica';

  @override
  String get chatSavedAsMaterial => 'Guardado en Mis materiales';

  @override
  String get chatSaveMaterialFailed => 'No se pudo guardar el material. Inténtalo de nuevo.';

  @override
  String get chatListenOnly => 'Entrenamiento solo de escucha';

  @override
  String get chatListenOnlyHidden => 'Solo escucha: pulsa reproducir';

  @override
  String chatClearHistoryMaterials(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count mensajes de este chat se guardaron como material. Esas copias se conservan hasta que las borres en Aprender › Mis materiales.',
      one: '1 mensaje de este chat se guardó como material. Esa copia se conserva hasta que la borres en Aprender › Mis materiales.',
    );
    return '$_temp0';
  }

  @override
  String get chatPracticeTitle => 'Práctica de copia';

  @override
  String chatPracticeUnsupported(String chars) {
    return 'Este mensaje tiene caracteres sin código Morse: $chars. Se omitirán.';
  }

  @override
  String chatPracticeTrainableCount(int count) {
    return 'Se pueden practicar $count símbolos.';
  }

  @override
  String get chatPracticeNothingTrainable => 'Nada en este mensaje se puede practicar en Morse.';

  @override
  String get chatPracticeConfirm => 'Practicar el resto';

  @override
  String get chatPracticeHint => 'Pista';

  @override
  String chatPracticeHintShown(String symbols) {
    return 'Pista: $symbols …';
  }

  @override
  String get chatPracticeAssisted => 'Con ayuda: cuenta como práctica, no para repasos ni consejo de velocidad.';

  @override
  String chatPracticeErrors(int wrong, int missed, int extra) {
    return '$wrong incorrectos · $missed omitidos · $extra de más';
  }

  @override
  String chatPracticeErrorsAction(String symbols) {
    return 'Practicar errores: $symbols';
  }

  @override
  String get learnTipDahTooLongTitle => 'Rayas demasiado largas';

  @override
  String learnTipDahTooLong(String ratio) {
    return 'Tus rayas se alargan (unas $ratio de un punto; objetivo 3). Suelta al cumplir tres puntos.';
  }

  @override
  String learnIssueDetailDahTooLong(int offending, int total, String ratio) {
    return '$offending de $total rayas demasiado largas (media $ratio punto)';
  }

  @override
  String get learnRhythmTitle => 'Ritmo';

  @override
  String get learnRhythmMine => 'Mi ritmo';

  @override
  String get learnRhythmStandard => 'Ritmo estándar (velocidad objetivo)';

  @override
  String learnRhythmNormalizedNote(int ms) {
    return 'Los problemas se juzgan con tu propio punto ($ms ms); un ritmo parejo pero lento está bien. La pista estándar es la velocidad objetivo.';
  }

  @override
  String get learnRhythmNotLocated => 'No se pudieron asignar tus marcas a símbolos concretos. Practica el objetivo completo.';

  @override
  String get learnRhythmPlayMine => 'Reproducir el mío';

  @override
  String get learnRhythmPlayStandard => 'Reproducir estándar';

  @override
  String learnRhythmPracticePart(int count) {
    return 'Practicar esto ($count intentos)';
  }

  @override
  String get learnRhythmPracticeWhole => 'Practicar el objetivo completo';

  @override
  String get learnRhythmSymbolOk => 'Bien';

  @override
  String get learnRhythmZoomIn => 'Acercar';

  @override
  String get learnRhythmZoomOut => 'Alejar';

  @override
  String get chatSearchMessages => 'Buscar mensajes';

  @override
  String get chatSearchHint => 'Buscar en esta conversación';

  @override
  String get chatSearchAnyone => 'Todos';

  @override
  String get chatSearchMe => 'Yo';

  @override
  String get chatSearchThem => 'La otra persona';

  @override
  String get chatSearchAnyDate => 'Cualquier fecha';

  @override
  String chatSearchDateRange(String from, String to) {
    return '$from – $to';
  }

  @override
  String get chatSearchBookmarked => 'Guardados';

  @override
  String get chatSearchNoResults => 'No hay mensajes que coincidan.';

  @override
  String get chatSearchMore => 'Cargar más';

  @override
  String get chatAddBookmark => 'Guardar';

  @override
  String get chatRemoveBookmark => 'Quitar de guardados';

  @override
  String get chatBookmarked => 'Guardado';

  @override
  String get chatBookmarkFailed => 'No se pudo guardar.';

  @override
  String get chatRetrySend => 'Reintentar envío';

  @override
  String get chatCancelSend => 'Cancelar envío';

  @override
  String get chatRetryQueued => 'En cola de nuevo. Se enviará cuando tu contacto esté en línea.';

  @override
  String get chatSendCancelled => 'Cancelado. El mensaje no se envió.';

  @override
  String get chatRetryNotNeeded => 'Este mensaje ya no está fallido.';

  @override
  String get chatCancelTooLate => 'Demasiado tarde: el mensaje ya salió y puede llegar.';

  @override
  String get chatSendControlUnavailable => 'No disponible para este mensaje.';

  @override
  String get chatSendControlFailed => 'No funcionó. El mensaje mantiene su estado; inténtalo de nuevo.';

  @override
  String get workbenchTitle => 'Banco de grabaciones';

  @override
  String get workbenchOpen => 'Grabaciones';

  @override
  String get workbenchImport => 'Importar grabación';

  @override
  String get workbenchEmpty => 'Importa una grabación WAV para repetirla, decodificarla y copiarla. No hace falta micrófono.';

  @override
  String get workbenchFormats => 'WAV, PCM de 16 bits, mono o estéreo, 8/16/44,1/48 kHz; hasta 50 MB y 20 minutos.';

  @override
  String get workbenchBackupNote => 'Las grabaciones se quedan en este dispositivo y no entran en la copia de la identidad salvo que elijas incluirlas al exportar. Los títulos, notas y posiciones de las selecciones guardadas siempre se copian.';

  @override
  String workbenchInfo(String rate, String channels, String duration) {
    return '$rate kHz · $channels · $duration';
  }

  @override
  String get workbenchMono => 'mono';

  @override
  String get workbenchStereo => 'estéreo';

  @override
  String get workbenchTruncated => 'El archivo termina antes de tiempo; solo se usa el audio presente.';

  @override
  String get workbenchErrorNotWav => 'No es un archivo WAV.';

  @override
  String get workbenchErrorFormat => 'Por ahora solo se admite WAV PCM de 16 bits (no MP3, AAC ni WAV en coma flotante).';

  @override
  String get workbenchErrorChannels => 'Solo se admiten grabaciones mono o estéreo.';

  @override
  String get workbenchErrorRate => 'Frecuencia de muestreo no admitida. Usa 8, 16, 44,1 o 48 kHz.';

  @override
  String get workbenchErrorDamaged => 'El archivo está dañado o incompleto.';

  @override
  String get workbenchErrorTooLarge => 'El archivo supera los 50 MB.';

  @override
  String get workbenchErrorTooLong => 'La grabación dura más de 20 minutos.';

  @override
  String get workbenchErrorIo => 'No se pudo leer el archivo.';

  @override
  String get workbenchErrorMissing => 'Falta el archivo de la grabación.';

  @override
  String get workbenchStart => 'Inicio (s)';

  @override
  String get workbenchEnd => 'Fin (s)';

  @override
  String get workbenchSelectAll => 'Seleccionar todo';

  @override
  String get workbenchPlay => 'Reproducir selección';

  @override
  String get workbenchStop => 'Detener';

  @override
  String get workbenchLoop => 'Repetir';

  @override
  String get workbenchPlayLimit => 'De una selección más larga solo se reproducen los primeros 5 minutos.';

  @override
  String get workbenchAutoTune => 'Buscar el tono automáticamente';

  @override
  String workbenchManualTone(int hz) {
    return 'Tono: $hz Hz';
  }

  @override
  String get workbenchDecode => 'Decodificar selección';

  @override
  String get workbenchCancel => 'Cancelar';

  @override
  String workbenchDecoding(int percent) {
    return 'Decodificando… $percent %';
  }

  @override
  String workbenchResultStats(int hz, int wpm) {
    return 'Tono $hz Hz · unas $wpm PPM';
  }

  @override
  String get workbenchToneNotLocked => 'No se encontró un tono estable; prueba el ajuste manual.';

  @override
  String get workbenchNoText => 'No se decodificó nada en esta selección.';

  @override
  String workbenchUnknown(String patterns) {
    return 'Patrones desconocidos: $patterns';
  }

  @override
  String get workbenchEdgeCut => 'Un símbolo en el borde de la selección está cortado y puede ser erróneo.';

  @override
  String get workbenchToneNote => 'Fijar el tono no es una medida de confianza; comprueba el texto de oído.';

  @override
  String get workbenchModeDecoder => 'Decodificador';

  @override
  String get workbenchModeCopy => 'Copiarlo yo';

  @override
  String get workbenchDecoderHidden => 'El texto del decodificador está oculto mientras copias.';

  @override
  String get workbenchShowDecoder => 'Mostrar texto del decodificador';

  @override
  String get workbenchReference => 'Texto de referencia (opcional)';

  @override
  String get workbenchReferenceHelp => 'Pega el texto enviado; si no, tu copia se compara con la salida del decodificador.';

  @override
  String get workbenchAgainstDecoder => 'Comparado con la salida del decodificador, que también puede fallar.';

  @override
  String get workbenchSave => 'Guardar selección';

  @override
  String get workbenchSaveTitle => 'Título';

  @override
  String get workbenchSaveNote => 'Nota';

  @override
  String get workbenchSaved => 'Selección guardada';

  @override
  String get workbenchSaveFailed => 'No se pudo guardar la selección.';

  @override
  String get workbenchLibrary => 'Selecciones guardadas';

  @override
  String get workbenchLibraryEmpty => 'Aún no hay selecciones guardadas.';

  @override
  String get workbenchMissing => 'Falta el archivo: vuelve a elegirlo o borra la entrada.';

  @override
  String get workbenchRelink => 'Elegir el archivo de nuevo';

  @override
  String get workbenchDelete => 'Eliminar';

  @override
  String get materialsTitle => 'Mis materiales';

  @override
  String get materialsNew => 'Nuevo material';

  @override
  String get materialsEdit => 'Editar';

  @override
  String get materialsSave => 'Guardar';

  @override
  String get materialsSaveFailed => 'No se pudo guardar el material.';

  @override
  String get materialsTitleField => 'Título';

  @override
  String get materialsTagsField => 'Etiquetas (separadas por comas)';

  @override
  String get materialsTextField => 'Texto';

  @override
  String get materialsListField => 'Una entrada por línea';

  @override
  String get materialsKindText => 'Texto';

  @override
  String get materialsKindWords => 'Lista de palabras';

  @override
  String get materialsKindCallsigns => 'Indicativos';

  @override
  String get materialsPreview => 'Vista previa';

  @override
  String materialsPreviewCounts(int items, int symbols, int prosigns) {
    return '$items elementos · $symbols símbolos · $prosigns prosignos';
  }

  @override
  String materialsPreviewUnsupported(String chars) {
    return 'Sin código Morse, se omiten en la práctica: $chars';
  }

  @override
  String materialsPreviewDuplicates(int count) {
    return '$count entradas duplicadas se conservan una vez';
  }

  @override
  String get materialsProblemEmpty => 'Escribe algo de texto primero.';

  @override
  String get materialsProblemTooLarge => 'Demasiado grande: el límite es 1 MiB.';

  @override
  String materialsProblemTooManyEntries(int count) {
    return 'Demasiadas entradas: máximo $count.';
  }

  @override
  String materialsProblemEntryTooLong(int count) {
    return 'Una entrada es demasiado larga: máximo $count símbolos.';
  }

  @override
  String get materialsProblemNothingTrainable => 'Aquí no hay nada que practicar en Morse.';

  @override
  String get materialsSearch => 'Buscar materiales';

  @override
  String get materialsFavoritesOnly => 'Favoritos';

  @override
  String get materialsFavorite => 'Añadir a favoritos';

  @override
  String get materialsUnfavorite => 'Quitar de favoritos';

  @override
  String get materialsEmpty => 'Aún no hay materiales. Añade tus textos, listas o indicativos, o guarda un mensaje del chat.';

  @override
  String materialsItems(int count) {
    return '$count elementos';
  }

  @override
  String get materialsFromChat => 'Del chat';

  @override
  String get materialsActions => 'Acciones';

  @override
  String get materialsPractise => 'Practicar';

  @override
  String get materialsDelete => 'Eliminar';

  @override
  String get materialsDeleteTitle => '¿Eliminar material?';

  @override
  String materialsDeleteBody(String title) {
    return '«$title» se eliminará de este dispositivo. Tu historial se conserva.';
  }

  @override
  String get materialsImport => 'Importar TXT o JSON';

  @override
  String get materialsImportDialogTitle => 'Elige un archivo';

  @override
  String get materialsSaveDialogTitle => 'Guardar material';

  @override
  String get materialsImportFailed => 'Error al importar. Tu biblioteca no cambió.';

  @override
  String get materialsImportNotUtf8 => 'Solo se pueden importar archivos de texto UTF-8.';

  @override
  String get materialsImportInvalid => 'No es un archivo de materiales de DitMesh válido. No se importó nada.';

  @override
  String materialsImported(int count) {
    return 'Se importaron $count materiales.';
  }

  @override
  String get materialsDuplicateTitle => 'Algunos materiales ya existen';

  @override
  String get materialsDuplicateOverwrite => 'Reemplazarlos';

  @override
  String get materialsDuplicateKeepCopy => 'Conservar ambos (como copia)';

  @override
  String get materialsDuplicateSkip => 'Omitirlos';

  @override
  String get materialsExportJson => 'Exportar como JSON';

  @override
  String materialsExported(int count) {
    return 'Se exportaron $count materiales.';
  }

  @override
  String get materialsExportFailed => 'Error al exportar.';

  @override
  String get materialsExportWav => 'Exportar audio (WAV)';

  @override
  String materialsWavCharSpeed(int wpm) {
    return 'Velocidad de carácter: $wpm PPM';
  }

  @override
  String materialsWavEffSpeed(int wpm) {
    return 'Velocidad efectiva: $wpm PPM';
  }

  @override
  String materialsWavTone(int hz) {
    return 'Tono: $hz Hz';
  }

  @override
  String get materialsWavWithAnswer => 'Incluir el texto de respuesta (.txt)';

  @override
  String get materialsWavFormat => 'WAV mono de 16 bits, 48 kHz.';

  @override
  String materialsWavParts(int count) {
    return 'Más de 10 minutos: se exporta en $count archivos.';
  }

  @override
  String materialsWavExported(int count) {
    return 'Se guardaron $count archivos de audio.';
  }

  @override
  String get materialsPracticeMode => 'Practicar con';

  @override
  String get materialsPracticeLearned => 'Solo símbolos aprendidos';

  @override
  String materialsPracticeLearnedPartial(int count) {
    return 'Solo símbolos aprendidos ($count entradas no disponibles: usan símbolos aún no aprendidos)';
  }

  @override
  String get materialsPracticeAll => 'Todos los símbolos Morse';

  @override
  String get materialsPracticeNothing => 'No hay entradas para practicar en este modo.';

  @override
  String get guestTryLearning => 'Probar a aprender primero';

  @override
  String get guestBanner => 'Modo invitado: el progreso queda en este dispositivo. El chat necesita una identidad.';

  @override
  String get guestGetIdentity => 'Configurar identidad';

  @override
  String get guestIdentityTitle => 'Se necesita una identidad';

  @override
  String get guestIdentityBody => 'Chatear por Tox necesita tu propia identidad. Crea una nueva, restaura una copia o desbloquea la de este dispositivo. Tu progreso como invitado pasa automáticamente a una identidad nueva.';

  @override
  String get guestClearData => 'Borrar datos de invitado';

  @override
  String get guestClearDataBody => 'Borra el progreso, los planes y los materiales que creaste como invitado en este dispositivo. No afecta a ninguna identidad.';

  @override
  String get guestClearConfirm => 'Borrar';

  @override
  String get guestCleared => 'Datos de invitado borrados.';

  @override
  String get guestClearFailed => 'No se pudieron borrar los datos.';

  @override
  String get guestMigrationFailed => 'Tu identidad está lista, pero tu progreso de invitado aún no se ha movido. Sigue seguro en este dispositivo.';

  @override
  String get guestChoiceBody => 'También tienes progreso de invitado. Se usa el progreso de la identidad restaurada; no se combinó nada.';

  @override
  String get guestChoiceKeep => 'Mantener el restaurado';

  @override
  String get guestChoiceUseGuest => 'Usar el progreso de invitado';

  @override
  String get placementTitle => 'Comprobar mi nivel';

  @override
  String get placementCheckLevel => 'Comprobar mi nivel actual';

  @override
  String get placementFromZero => 'Empezar desde cero';

  @override
  String get placementOfferTitle => '¿Nuevo en Morse o ya copias?';

  @override
  String get placementOfferBody => 'Una prueba breve puede sugerir dónde empezar. Es opcional y no cambia nada hasta que elijas.';

  @override
  String get placementIntro => 'Unos 3–5 minutos de copia en cinco pasos: símbolos Koch en grupos a velocidad creciente y luego palabras cortas. Es una guía aproximada con pocas muestras, no un certificado. Para cuando quieras.';

  @override
  String get placementStart => 'Empezar';

  @override
  String get placementSkip => 'Omitir';

  @override
  String get placementStop => 'Parar';

  @override
  String placementTierProgress(int step, int total, int wpm) {
    return 'Paso $step de $total · $wpm PPM efectivas';
  }

  @override
  String get placementTierPassed => 'Bien copiado. El siguiente paso es más rápido.';

  @override
  String get placementTierStopped => 'Ese paso quedó por debajo del 90 %, la prueba termina aquí.';

  @override
  String get placementNextTier => 'Siguiente paso';

  @override
  String placementSuggestion(int lesson) {
    return 'Inicio sugerido: lección $lesson';
  }

  @override
  String placementVerified(int count, int total) {
    return '$count de $total símbolos Koch confirmados en orden.';
  }

  @override
  String get placementLimits => 'Basado en una muestra corta: los símbolos no probados siguen sin probar y nada se marca como aprendido. Puedes cambiar la lección cuando quieras.';

  @override
  String placementAdopt(int lesson) {
    return 'Empezar en la lección $lesson';
  }

  @override
  String get chatJumpToLatest => 'Mensajes más recientes';

  @override
  String get chatMessageGone => 'Ese mensaje ya no está en esta conversación.';

  @override
  String get chatListenOnlyPreview => 'Mensaje nuevo: escúchalo para copiarlo';

  @override
  String get chatSaveMaterialConfirm => 'Guardar el resto';

  @override
  String materialsImportConfirm(int count) {
    return '¿Importar $count materiales?';
  }

  @override
  String get materialsExportTxt => 'Exportar como texto (TXT)';

  @override
  String get accountBackupMediaTitle => '¿Incluir las grabaciones guardadas?';

  @override
  String accountBackupMediaBody(int count, String size) {
    return '$count grabaciones guardadas ($size MB). Sus títulos, notas y posiciones siempre están en la copia; el audio solo si lo incluyes.';
  }

  @override
  String accountBackupMediaTooLarge(String size) {
    return 'Las grabaciones guardadas ($size MB) son demasiado grandes para la copia; solo se incluyen títulos, notas y posiciones.';
  }

  @override
  String get accountBackupMediaInclude => 'Incluir grabaciones';

  @override
  String get accountBackupMediaSkip => 'Sin grabaciones';

  @override
  String get diagTitle => 'Diagnóstico de conexión';

  @override
  String get diagOpenSubtitle => 'Por qué hay mensajes en espera y cómo reconectar';

  @override
  String get diagBannerDetails => 'Detalles';

  @override
  String get diagSummaryNoIdentity => 'No hay ninguna identidad abierta, así que no hay conexión que revisar.';

  @override
  String get diagSummaryOnlinePeerOnline => 'Estás conectado a la red Tox y este contacto está en línea. Los mensajes le llegan directamente.';

  @override
  String get diagSummaryOnlinePeerOffline => 'Estás conectado, pero este contacto está desconectado. Los mensajes esperan en la bandeja de salida de este dispositivo y se envían cuando el contacto se conecte.';

  @override
  String get diagSummaryOnline => 'Estás conectado a la red Tox.';

  @override
  String get diagSummaryConnecting => 'Conectando a la red Tox. Puede tardar un minuto tras iniciar la app o cambiar de red.';

  @override
  String get diagSummaryOffline => 'No estás conectado a la red Tox. No se puede enviar ni recibir nada hasta que vuelva la conexión.';

  @override
  String get diagLocalLabel => 'Tu conexión';

  @override
  String diagSinceChanged(String time) {
    return 'Desde $time';
  }

  @override
  String diagSinceFirst(String time) {
    return 'Observado desde $time';
  }

  @override
  String diagSinceResumed(String time) {
    return 'Observado desde que volviste a la app a las $time';
  }

  @override
  String get diagLastOnlineLabel => 'Última conexión observada';

  @override
  String get diagLastOnlineNow => 'Conectado ahora';

  @override
  String get diagLastOnlineNone => 'Aún no se ha observado ninguna conexión.';

  @override
  String get diagLastOnlineHint => 'Cuándo vio este dispositivo su propia conexión por última vez. No indica cuándo un mensaje llegó a alguien.';

  @override
  String get diagPeerLabel => 'Contacto';

  @override
  String get diagUnknown => 'Desconocido';

  @override
  String get diagPeerUnknownHint => 'La presencia de un contacto solo se ve mientras estás conectado.';

  @override
  String get diagPeerGroupHint => 'La presencia de los miembros se muestra en la lista de miembros.';

  @override
  String get diagPendingLabel => 'Pendiente de envío';

  @override
  String get diagPendingNone => 'Nada pendiente';

  @override
  String diagPendingCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count mensajes',
      one: '1 mensaje',
    );
    return '$_temp0';
  }

  @override
  String diagPendingOldest(String time) {
    return 'La más antigua, en cola desde $time';
  }

  @override
  String get diagPendingUnknown => 'Desconocido hasta que el chat se conecte';

  @override
  String get diagPendingHint => 'Los mensajes en cola permanecen en este dispositivo y se envían solos cuando el contacto está disponible. El diagnóstico nunca los descarta ni los reenvía.';

  @override
  String get diagReconnect => 'Reconectar';

  @override
  String get diagReconnecting => 'Reconectando…';

  @override
  String diagReconnectFailed(String reason) {
    return 'No se pudo reconectar: $reason';
  }

  @override
  String get diagReconnectNote => 'Reconectar reinicia el intento de conexión. Aun así puede tardar en conectarse; esta página se actualiza cuando ocurra.';

  @override
  String get diagAboutTitle => 'Cómo se conecta DitMesh';

  @override
  String get diagAboutBody => 'DitMesh no tiene servidor. Tu dispositivo habla directamente con tus contactos por la red entre pares Tox, así que ambos deben estar conectados a la vez para que llegue un mensaje. Los teléfonos pausan las apps en segundo plano: allí DitMesh no puede seguir conectado y se reconecta al volver.';

  @override
  String get diagDetailsTitle => 'Detalles técnicos';

  @override
  String get diagDetailIdentity => 'Identidad';

  @override
  String get diagDetailStatus => 'Estado';

  @override
  String get diagDetailObserved => 'Observado a las';

  @override
  String get diagDetailQueued => 'Entradas en cola';

  @override
  String get diagDetailError => 'Último código de error';

  @override
  String get backupXTitle => 'Copia cifrada';

  @override
  String get backupXIntro => 'Elige qué llevar a otro dispositivo. Todo el archivo se cifra con una frase de contraseña que defines aquí.';

  @override
  String get backupXCategoryIdentity => 'Identidad y perfil Tox';

  @override
  String get backupXCategoryTraining => 'Progreso y materiales de práctica';

  @override
  String get backupXCategoryChat => 'Historial de chat, incluidas las notas para mí';

  @override
  String get backupXCategoryMeta => 'Borradores, fijados y marcadores';

  @override
  String get backupXCategoryPrefs => 'Preferencias de la app';

  @override
  String get backupXPrefsHint => 'Reproducción, notificaciones, apariencia e idioma. Nunca posiciones de ventana ni asignaciones de teclas.';

  @override
  String get backupXCategoryMedia => 'Grabaciones guardadas';

  @override
  String get backupXMediaHint => 'Desactivado por defecto: las grabaciones pueden ser grandes. Sin ellas solo se llevan títulos y notas.';

  @override
  String get backupXCategoryPending => 'Mensajes sin enviar';

  @override
  String get backupXPendingHint => 'Vuelven solo para revisarlos y nunca se envían automáticamente.';

  @override
  String get backupXRequired => 'Obligatorio';

  @override
  String backupXSizeLine(int count, String size) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count elementos',
      one: '1 elemento',
    );
    return '$_temp0 · $size';
  }

  @override
  String backupXSizeKb(String size) {
    return '$size KB';
  }

  @override
  String backupXSizeMb(String size) {
    return '$size MB';
  }

  @override
  String backupXMediaTooLarge(String size) {
    return 'Demasiado grande para incluir ($size)';
  }

  @override
  String backupXInvitesNote(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count invitaciones de grupo pendientes para amigos desconectados no se trasladan.',
      one: '1 invitación de grupo pendiente para un amigo desconectado no se traslada.',
    );
    return '$_temp0';
  }

  @override
  String get backupXIdentityPasswordNote => 'La contraseña de tu identidad se mantiene en el perfil: el nuevo dispositivo la pedirá además de la frase de la copia.';

  @override
  String backupXTotal(String size) {
    return 'Unos $size en total';
  }

  @override
  String get backupXPassphrase => 'Frase de la copia';

  @override
  String get backupXPassphraseConfirm => 'Repite la frase';

  @override
  String get backupXPassphraseHint => 'Al menos 8 caracteres. Es distinta de la contraseña de tu identidad y no se puede recuperar.';

  @override
  String get backupXPassphraseTooShort => 'Usa al menos 8 caracteres';

  @override
  String get backupXPassphraseMismatch => 'Las frases no coinciden';

  @override
  String get backupXExport => 'Crear copia cifrada';

  @override
  String get backupXExporting => 'Creando copia…';

  @override
  String get backupXMigrationNote => '¿Cambias de dispositivo? Tras restaurar allí, deja de usar esta identidad aquí: dos dispositivos con una identidad pueden enviar el mismo mensaje dos veces.';

  @override
  String get backupXBusy => 'Tus datos cambiaron mientras se hacía la copia. Inténtalo de nuevo.';

  @override
  String get backupXTooLarge => 'La copia es demasiado grande. Excluye las grabaciones e inténtalo de nuevo.';

  @override
  String get restoreXWrongPassphrase => 'Frase incorrecta, o el archivo se modificó o está incompleto.';

  @override
  String get restoreXUnsupported => 'Esta copia se hizo con una versión más reciente de DitMesh.';

  @override
  String get restoreXCheck => 'Abrir copia';

  @override
  String get restoreXPreviewTitle => 'Contenido de la copia';

  @override
  String restoreXCreated(String date) {
    return 'Creada el $date';
  }

  @override
  String get restoreXIncluded => 'Incluido';

  @override
  String get restoreXExcluded => 'No está en esta copia';

  @override
  String restoreXPendingIncluded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count mensajes sin enviar vuelven para revisarlos. No se enviarán automáticamente.',
      one: '1 mensaje sin enviar vuelve para revisarlo. No se enviará automáticamente.',
    );
    return '$_temp0';
  }

  @override
  String restoreXPendingExcluded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count mensajes sin enviar del dispositivo anterior no están en esta copia.',
      one: '1 mensaje sin enviar del dispositivo anterior no está en esta copia.',
    );
    return '$_temp0';
  }

  @override
  String get restoreXIdentityPassword => 'Contraseña de la identidad';

  @override
  String get restoreXIdentityPasswordNote => 'La identidad de esta copia tiene su propia contraseña. Introdúcela también.';

  @override
  String get restoreXConfirmTitle => '¿Reemplazar la identidad de este dispositivo?';

  @override
  String get restoreXConfirmBody => 'La identidad y los datos de este dispositivo se reemplazan por la copia. Deja de usar la identidad en el dispositivo anterior antes de conectarte aquí.';

  @override
  String get restoreXConfirm => 'Reemplazar y restaurar';

  @override
  String get restoreXReportTitle => 'Restauración completada';

  @override
  String get restoreXReportRestored => 'Restaurado';

  @override
  String get restoreXReportNotIncluded => 'No restaurado';

  @override
  String get restoreXReportPrefsFailed => 'No se pudieron aplicar las preferencias; se mantuvieron las anteriores.';

  @override
  String restoreXReportPendingReview(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count mensajes sin enviar esperan tu revisión en Chat.',
      one: '1 mensaje sin enviar espera tu revisión en Chat.',
    );
    return '$_temp0';
  }

  @override
  String restoreXReportPendingNotResumed(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count mensajes sin enviar del dispositivo anterior no se trasladaron.',
      one: '1 mensaje sin enviar del dispositivo anterior no se trasladó.',
    );
    return '$_temp0';
  }

  @override
  String restoreXReportInvites(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count invitaciones de grupo en cola no se reenviaron.',
      one: '1 invitación de grupo en cola no se reenvió.',
    );
    return '$_temp0';
  }

  @override
  String get restoreXReportStopOld => 'Deja de usar esta identidad en el dispositivo anterior.';

  @override
  String get restoreXReportDone => 'Listo';

  @override
  String pendingReviewBanner(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count mensajes sin enviar de tu dispositivo anterior',
      one: '1 mensaje sin enviar de tu dispositivo anterior',
    );
    return '$_temp0';
  }

  @override
  String get pendingReviewTitle => 'Mensajes sin enviar';

  @override
  String get pendingReviewBody => 'Estaban pendientes de envío en tu dispositivo anterior. DitMesh nunca los envía automáticamente; vuelve a manipular uno si aún importa.';

  @override
  String pendingReviewQueuedAt(String time) {
    return 'En cola desde $time en el dispositivo anterior';
  }

  @override
  String get pendingReviewDismiss => 'Descartar';

  @override
  String get pendingReviewDismissAll => 'Descartar todo';

  @override
  String get pendingReviewEmpty => 'No queda nada por revisar.';

  @override
  String get backupXWizardInside => 'El archivo de copia se cifra entero con una frase que eliges y contiene la clave de tu identidad y tu progreso. Guarda el archivo y la frase en un lugar seguro, fuera de este dispositivo.';

  @override
  String get backupXMeSubtitle => 'Un archivo cifrado con tu identidad, chats y progreso, para guardarlo o llevarlo a otro dispositivo';

  @override
  String get conditionsTitle => 'Condiciones';

  @override
  String get conditionsClear => 'Limpio';

  @override
  String get conditionsLight => 'Interferencia leve';

  @override
  String get conditionsRadio => 'Práctica de radio';

  @override
  String get conditionsClearHint => 'Un tono limpio y estable: práctica normal.';

  @override
  String get conditionsLightHint => 'Ruido de fondo suave y desvanecimiento ligero. Los resultados se guardan aparte de la práctica limpia.';

  @override
  String get conditionsRadioHint => 'Ruido, desvanecimiento profundo, una estación cercana y ritmo algo irregular. Los resultados se guardan aparte de la práctica limpia.';

  @override
  String get conditionsPreview => 'Escuchar';

  @override
  String conditionsActive(String name) {
    return 'Condiciones: $name';
  }

  @override
  String get conditionsNeedSound => 'Las condiciones de radio se oyen, no se ven: activa el sonido en los ajustes de práctica o practica con condiciones limpias.';

  @override
  String get conditionsCleanReplay => 'Reproducir sin efectos';

  @override
  String conditionsComparable(int count, int accuracy) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count intentos con estas condiciones y velocidad: $accuracy % de media',
      one: '1 intento con estas condiciones y velocidad: $accuracy %',
    );
    return '$_temp0';
  }

  @override
  String get conditionsSeparateNote => 'La práctica con condiciones de radio cuenta como actividad, pero no cambia tus lecciones, tu repaso ni la recomendación de velocidad.';

  @override
  String get keysTitle => 'Teclas y manipuladores externos';

  @override
  String get keysMeSubtitle => 'Asignación de teclas, paletas y adaptadores USB';

  @override
  String get keysIntro => 'Elige qué teclas manipulan Morse. Los adaptadores USB de manipulador y paletas que emulan un teclado funcionan como tal: define aquí sus teclas. La app no sabe qué dispositivo envió una tecla, así que un perfil es un conjunto de asignaciones.';

  @override
  String get keysStandardProfile => 'Estándar';

  @override
  String get keysUnnamed => 'Perfil sin nombre';

  @override
  String get keysEdit => 'Editar';

  @override
  String get keysNewProfile => 'Nuevo perfil';

  @override
  String get keysLimitations => 'No se admiten manipuladores MIDI, serie ni Bluetooth, ajustes de firmware del adaptador ni control del transmisor. Los adaptadores probados figuran en la documentación.';

  @override
  String get keysEditTitle => 'Perfil de teclas';

  @override
  String get keysName => 'Nombre del perfil';

  @override
  String get keysActionStraight => 'Manipulador vertical';

  @override
  String get keysActionDit => 'Paleta de punto';

  @override
  String get keysActionDah => 'Paleta de raya';

  @override
  String get keysPressKey => 'Pulsa una tecla…';

  @override
  String get keysNone => 'Sin definir';

  @override
  String get keysSet => 'Definir';

  @override
  String keysReserved(String key) {
    return '$key está reservada por el sistema o la app; elige otra tecla.';
  }

  @override
  String keysConflict(String key, String action) {
    return '$key ya se usa para $action.';
  }

  @override
  String keysConflictSave(String keys) {
    return 'Cada tecla solo puede hacer una cosa: $keys está asignada dos veces.';
  }

  @override
  String get keysMissing => 'Define las teclas que necesita este modo (ambas paletas en yámbico).';

  @override
  String get keysSwapPaddles => 'Invertir paletas (zurdos)';

  @override
  String get keysKeyerMode => 'Modo del manipulador';

  @override
  String get keysIambicA => 'Yámbico A';

  @override
  String get keysIambicB => 'Yámbico B';

  @override
  String get keysAdapterKeyer => 'El adaptador genera sus propios elementos';

  @override
  String get keysAdapterKeyerHint => 'Para un adaptador con manipulador propio: sus pulsaciones temporizadas se usan tal cual, sin un segundo manipulador yámbico en la app.';

  @override
  String get keysAppSidetone => 'Tono local de la app al manipular';

  @override
  String get keysAppSidetoneHint => 'Desactívalo si el adaptador genera su propio tono. La decodificación no cambia.';

  @override
  String get keysTestTitle => 'Prueba';

  @override
  String get keysTestNote => 'Solo prueba: no se envía nada ni cuenta para tu práctica.';

  @override
  String get keysTestRelease => 'Soltar teclas';

  @override
  String get keysAdapterActive => 'Se usa el manipulador del adaptador: las teclas de paleta actúan como manipulador vertical.';

  @override
  String keysHintCustom(String keys) {
    return 'Teclas: $keys';
  }

  @override
  String get telegraphTitle => 'Código telegráfico chino';

  @override
  String get telegraphIntro => 'Cada carácter chino se envía como un código de cuatro cifras. Practica oír las cifras y, por separado, recordar qué código corresponde a cada carácter.';

  @override
  String get telegraphCodebook => 'Libro de códigos';

  @override
  String get telegraphCodebookMainland => 'China continental';

  @override
  String get telegraphCodebookTaiwan => 'Taiwán';

  @override
  String get telegraphDigitsTitle => 'Copiar grupos de código';

  @override
  String get telegraphDigitsHint => 'Escucha grupos de cuatro cifras de códigos reales y escribe las cifras.';

  @override
  String telegraphDigitsResults(int count, int accuracy) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sesiones: $accuracy % de cifras',
      one: '1 sesión: $accuracy % de cifras',
    );
    return '$_temp0';
  }

  @override
  String get telegraphRecallTitle => 'Recordar códigos';

  @override
  String get telegraphRecallHint => 'De carácter a código y de código a carácter. Separado del progreso en Morse.';

  @override
  String telegraphRecallResults(int count, int accuracy) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tarjetas respondidas: $accuracy % sabido',
      one: '1 tarjeta respondida: $accuracy % sabido',
    );
    return '$_temp0';
  }

  @override
  String get telegraphSeparateNote => 'Recordar códigos nunca desbloquea lecciones de Morse ni cambia la recomendación de velocidad; copiar cifras cuenta como cualquier otra copia en Morse.';

  @override
  String get telegraphRecallCharPrompt => 'Escribe el código de este carácter';

  @override
  String get telegraphRecallCodePrompt => 'Elige el carácter de este código';

  @override
  String get telegraphReveal => 'Ver respuesta';

  @override
  String get telegraphRevealAssisted => 'Mostrada: esta tarjeta cuenta como asistida.';

  @override
  String get telegraphCorrect => 'Correcto';

  @override
  String get telegraphIncorrect => 'No del todo';

  @override
  String telegraphRecallSummary(int correct, int total) {
    return '$correct de $total sabidas';
  }

  @override
  String telegraphRecallAssisted(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tarjetas con la respuesta mostrada',
      one: '1 tarjeta con la respuesta mostrada',
    );
    return '$_temp0';
  }

  @override
  String get telegraphInterpretAction => 'Interpretar como código telegráfico chino';

  @override
  String get telegraphInterpretTitle => 'Interpretación del código telegráfico';

  @override
  String get telegraphInterpretNote => 'Solo se muestra aquí: el mensaje no cambia y no se envía nada.';

  @override
  String get telegraphUnresolved => 'Sin resolver: ningún carácter tiene este código';

  @override
  String get telegraphMalformed => 'No es un grupo de cuatro cifras';

  @override
  String get telegraphNotCode => 'Texto, tal como está';

  @override
  String get telegraphAmbiguous => 'Varios caracteres comparten este código';

  @override
  String get groupPracticeTitle => 'Práctica en grupo';

  @override
  String get groupPracticeIntro => 'El instructor manipula los ejercicios en el chat del grupo como siempre. Cada miembro elige aquí un mensaje de ejercicio y lo copia a su propia velocidad. Las respuestas y puntuaciones se quedan en tu dispositivo; no se envía nada al grupo.';

  @override
  String get groupPracticeNew => 'Nueva sesión';

  @override
  String get groupPracticeTitleField => 'Título';

  @override
  String get groupPracticeCreate => 'Crear';

  @override
  String get groupPracticeInstructor => 'Instructor';

  @override
  String get groupPracticeParticipant => 'Participante';

  @override
  String get groupPracticeInstructorHint => 'Manipula cada ejercicio en el chat del grupo, añádelo aquí como ronda y márcalo; anuncia los turnos en el chat.';

  @override
  String get groupPracticeParticipantHint => 'Añade los mensajes de ejercicio del instructor como rondas y cópialos aquí.';

  @override
  String get groupPracticeLocalNote => 'Solo local: rondas, roles y resultados no se sincronizan con otros miembros, y los mensajes perdidos quizá no lleguen a todos.';

  @override
  String get groupPracticeAddRound => 'Añadir ejercicio';

  @override
  String get groupPracticeNoMessages => 'No hay mensajes adecuados en el historial reciente.';

  @override
  String get groupPracticeNotConnected => 'El historial del grupo no está disponible hasta que el chat se conecte.';

  @override
  String get groupPracticeRoundOpen => 'Pendiente';

  @override
  String get groupPracticeRoundDone => 'Hecho';

  @override
  String get groupPracticeRoundUnavailable => 'No disponible';

  @override
  String get groupPracticeSourceGone => 'El mensaje de ejercicio ya no está en el historial.';

  @override
  String get groupPracticeSourceLoading => 'Buscando el mensaje…';

  @override
  String groupPracticeAttemptResult(int accuracy, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Copiado: $accuracy % ($count intentos)',
      one: 'Copiado: $accuracy %',
    );
    return '$_temp0';
  }

  @override
  String get groupPracticeCopy => 'Copiar';

  @override
  String get groupPracticeRemoveRound => 'Quitar ronda';

  @override
  String get groupPracticeSummary => 'Resumen';

  @override
  String groupPracticeRoundsDone(int done, int total) {
    return '$done de $total rondas hechas';
  }

  @override
  String groupPracticeUnavailableCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count rondas no disponibles',
      one: '1 ronda no disponible',
    );
    return '$_temp0';
  }

  @override
  String groupPracticeAccuracy(int accuracy) {
    return 'Precisión de copia: $accuracy %';
  }

  @override
  String groupPracticeAssisted(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count intentos con ayuda',
      one: '1 intento con ayuda',
    );
    return '$_temp0';
  }

  @override
  String groupPracticeShareHint(int done, int total, int accuracy) {
    return 'Para compartir, manipula tú mismo el resultado en el chat del grupo, p. ej. $done/$total $accuracy%. No se envía nada automáticamente.';
  }

  @override
  String get groupPracticeComplete => 'Terminar sesión';

  @override
  String get groupPracticeDeleteTitle => '¿Eliminar esta sesión?';

  @override
  String get groupPracticeDeleteBody => 'Sus rondas y resultados locales se eliminan de este dispositivo. Tu historial de práctica y los mensajes del grupo se conservan.';

  @override
  String get conditionsAudioFailed => 'No se pudo iniciar el audio en este dispositivo. Practica con condiciones limpias.';

  @override
  String get moderationBlock => 'Bloquear';

  @override
  String moderationBlockTitle(String name) {
    return '¿Bloquear a $name?';
  }

  @override
  String get moderationBlockFriendBody => 'Se eliminará de tus amigos y se borrará la conversación. Sus mensajes, solicitudes de amistad e invitaciones a grupos dejarán de aparecer en este dispositivo. No se le avisará.';

  @override
  String get moderationBlockMemberBody => 'Sus mensajes en este grupo dejarán de aparecer en este dispositivo. No se le avisará. Tox da a cada miembro una clave distinta en cada grupo, así que solo se aplica a este grupo.';

  @override
  String get moderationBlocked => 'Bloqueado';

  @override
  String get moderationUnblock => 'Desbloquear';

  @override
  String get moderationUnblocked => 'Desbloqueado';

  @override
  String get moderationBlockedTitle => 'Personas bloqueadas';

  @override
  String get moderationBlockedSubtitle => 'Sus mensajes, solicitudes e invitaciones están ocultos';

  @override
  String get moderationBlockedEmpty => 'No has bloqueado a nadie.';

  @override
  String get moderationBlockedNote => 'El bloqueo funciona en este dispositivo: Tox no tiene servidor central, así que las personas bloqueadas pueden seguir intentándolo, pero aquí no se muestra nada suyo.';

  @override
  String get termsGateTitle => 'Normas de la comunidad';

  @override
  String get termsGateIntro => 'El chat de DitMesh te conecta directamente con otras personas, sin servidor. Antes de empezar, acepta estas normas:';

  @override
  String get termsGateRuleZero => 'Tolerancia cero: nada de acoso, odio, amenazas, contenido sexual con menores, spam ni nada ilegal.';

  @override
  String get termsGateRuleContacts => 'Solo las personas que aceptes pueden escribirte; a los grupos se entra por invitación o con su ID.';

  @override
  String get termsGateRuleBlock => 'Bloquea a cualquiera desde una conversación, la lista de miembros de un grupo, una solicitud de amistad o una invitación.';

  @override
  String get termsGateAgree => 'Aceptar y continuar';

  @override
  String get termsGateReadFull => 'Leer las condiciones de uso completas';

  @override
  String get termsGateSaveFailed => 'No se pudo guardar tu respuesta. Inténtalo de nuevo.';

  @override
  String get aboutPrivacyPolicy => 'Política de privacidad';

  @override
  String get aboutTermsOfUse => 'Condiciones de uso';

  @override
  String get aboutSupport => 'Ayuda y contacto';

  @override
  String get aboutLinkFailed => 'No se pudo abrir el enlace, así que se copió.';

  @override
  String get errorPeerBlocked => 'Has bloqueado a esta persona. Desbloquéala primero en Yo → Personas bloqueadas.';

  @override
  String get offlineClearData => 'Borrar los datos de aprendizaje';

  @override
  String get offlineClearDataBody => 'Borra tu progreso, tus planes y tus materiales de este dispositivo.';

  @override
  String get offlineCleared => 'Datos de aprendizaje borrados.';

  @override
  String get offlineClearFailed => 'No se pudieron borrar los datos de aprendizaje.';

  @override
  String get learnStorageUnavailable => 'No se pudieron abrir tus datos de entrenamiento en este dispositivo. Inténtalo de nuevo.';

  @override
  String get backendStartupFailedTitle => 'Servicio de chat no disponible';

  @override
  String get backendStartupFailedBody => 'DitMesh no pudo iniciar el servicio de red Tox. Comprueba que las bibliotecas nativas estén instaladas y vuelve a intentarlo.';

  @override
  String get bootstrapTitle => 'Red y nodos de arranque';

  @override
  String get bootstrapDescription => 'Elige los nodos públicos para entrar en la red Tox.';

  @override
  String get bootstrapModeAuto => 'Automático';

  @override
  String get bootstrapModeManual => 'Manual';

  @override
  String get bootstrapModeLan => 'Servidor LAN';

  @override
  String get bootstrapAutoDescription => 'Iniciar con nodos integrados y actualizar la lista oficial en segundo plano.';

  @override
  String get bootstrapManualDescription => 'Usar solo el nodo elegido. También puedes introducir un nodo LAN aquí.';

  @override
  String get bootstrapLanDescription => 'Ejecutar un nodo UDP/DHT local en este ordenador para otros dispositivos LAN.';

  @override
  String get bootstrapCurrentNode => 'Nodo actual';

  @override
  String get bootstrapHost => 'Host o dirección IP';

  @override
  String get bootstrapPort => 'Puerto UDP';

  @override
  String get bootstrapPublicKey => 'Clave pública DHT';

  @override
  String get bootstrapTestNode => 'Probar nodo';

  @override
  String get bootstrapSaveNode => 'Usar nodo probado';

  @override
  String get bootstrapChooseNode => 'Elegir nodo público';

  @override
  String get bootstrapReachable => 'Respuesta DHT recibida';

  @override
  String get bootstrapUnreachable => 'Sin respuesta DHT';

  @override
  String get bootstrapInvalid => 'Host, puerto o clave pública no válidos';

  @override
  String get bootstrapUdpUnavailable => 'Este dispositivo no puede realizar la prueba UDP. No se ha probado TCP.';

  @override
  String get bootstrapProbeUnavailable => 'No se pudo iniciar la prueba. Esto no indica si el nodo es accesible.';

  @override
  String get bootstrapFallback => 'No se pudo cargar la lista oficial. Se muestran los nodos de reserva integrados.';

  @override
  String get bootstrapMaintainer => 'Responsable';

  @override
  String get bootstrapLocation => 'Ubicación';

  @override
  String get bootstrapLastPing => 'Última comprobación pública';

  @override
  String get bootstrapSwitchTitle => 'Cambiar nodo de arranque';

  @override
  String get bootstrapSwitchQuestion => '¿Usar este nodo?';

  @override
  String get bootstrapNotTestedWarning => 'Este nodo aún no se ha probado en tu dispositivo.';

  @override
  String get bootstrapFailedWarning => 'Este nodo no respondió a la prueba UDP. Puedes elegirlo de todos modos.';

  @override
  String get bootstrapInconclusiveWarning => 'La prueba no fue concluyente. No se ha probado TCP.';

  @override
  String get bootstrapSwitchConfirm => 'Usar nodo';

  @override
  String get bootstrapRefresh => 'Actualizar lista';

  @override
  String get bootstrapStartLan => 'Iniciar nodo LAN';

  @override
  String get bootstrapStopLan => 'Detener nodo LAN';

  @override
  String get bootstrapLanStopped => 'Nodo LAN detenido';

  @override
  String get bootstrapLanRunning => 'Nodo LAN activo';

  @override
  String get bootstrapLanKeyChanges => 'La clave DHT cambia al reiniciar el nodo. Comparte la clave completa actual.';

  @override
  String get bootstrapLanFirewallHint => 'Otros dispositivos deben poder acceder a este puerto UDP a través del cortafuegos local.';

  @override
  String get bootstrapCopyNode => 'Copiar datos del nodo';

  @override
  String get bootstrapShareNode => 'Compartir datos del nodo';

  @override
  String get bootstrapOperationFailed => 'No se pudo aplicar la configuración de red.';

  @override
  String get bootstrapServiceUnavailable => 'La configuración de red no está disponible para este motor.';

  @override
  String get bootstrapSource => 'Lista oficial de nodos públicos';

  @override
  String get bootstrapOnline => 'En línea';

  @override
  String get bootstrapOffline => 'Sin conexión';

  @override
  String bootstrapProtocolStatus(String udp, String tcp) {
    return 'UDP: $udp · TCP: $tcp';
  }
}
