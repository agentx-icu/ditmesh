// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 's.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class SDe extends S {
  SDe([String locale = 'de']) : super(locale);

  @override
  String get appName => 'DitMesh';

  @override
  String get navLearn => 'Lernen';

  @override
  String get navChat => 'Chat';

  @override
  String get navGroups => 'Gruppen';

  @override
  String get navMe => 'Ich';

  @override
  String get navReference => 'Nachschlagen';

  @override
  String get navLearnDescription => 'Lektionen nach der Koch-Methode, Gebeübungen und Hörtraining.';

  @override
  String get navChatDescription => 'Direkte Morsegespräche über Tox P2P ohne Server.';

  @override
  String get navGroupsDescription => 'Gruppenrunden – mehrere Funker morsen auf einem gemeinsamen Kanal.';

  @override
  String get navReferenceDescription => 'Alphabet, Verkehrszeichen, Q-Gruppen, Abkürzungen und Übersetzung in beide Richtungen.';

  @override
  String get navMeDescription => 'Dein Rufzeichen, deine Tox-Identität, Fortschritte und Einstellungen.';

  @override
  String get shellOfflineBanner => 'Offline: Keine Verbindung zum Tox-Netzwerk. Nachrichten werden gesendet, sobald du wieder online bist.';

  @override
  String get actionOk => 'OK';

  @override
  String get actionCancel => 'Abbrechen';

  @override
  String get actionSave => 'Speichern';

  @override
  String get actionDelete => 'Löschen';

  @override
  String get actionCopy => 'Kopieren';

  @override
  String get actionShare => 'Teilen';

  @override
  String get actionRetry => 'Erneut versuchen';

  @override
  String get actionClose => 'Schließen';

  @override
  String get actionSearch => 'Suchen';

  @override
  String get actionSettings => 'Einstellungen';

  @override
  String get connectionConnecting => 'Verbindung wird hergestellt…';

  @override
  String get connectionOnline => 'Online';

  @override
  String get connectionOffline => 'Offline';

  @override
  String get messageStatusPending => 'In Warteschlange – Kontakt ist offline';

  @override
  String get messageStatusPendingDetail => 'Tox hat keinen Server: Die Nachricht wird zugestellt, sobald der Kontakt online ist.';

  @override
  String get messageStatusSending => 'Wird gesendet';

  @override
  String get messageStatusSent => 'Gesendet';

  @override
  String get messageStatusFailed => 'Senden fehlgeschlagen';

  @override
  String get errorWrongPassword => 'Falsches Passwort. Versuche es erneut.';

  @override
  String get errorPeerOffline => 'Dieser Kontakt ist offline. Tox hat keinen Server, daher wartet die Nachricht, bis der Kontakt wieder online ist.';

  @override
  String get errorInvalidToxId => 'Dies ist keine gültige Tox-ID (76 Hexadezimalzeichen).';

  @override
  String get errorAlreadyFriend => 'Diese Tox-ID ist bereits in deiner Freundesliste.';

  @override
  String get errorOwnId => 'Das ist deine eigene Tox-ID.';

  @override
  String get errorGroupNotFound => 'Gruppe nicht gefunden.';

  @override
  String get errorMessageTooLong => 'Der Text ist zu lang für eine einzelne Tox-Nachricht.';

  @override
  String get errorUnknown => 'Ein Fehler ist aufgetreten';

  @override
  String get errorTeardownUnconfirmed => 'Die vorherige Tox-Sitzung wurde noch nicht vollständig beendet. Versuche es gleich noch einmal oder starte die App neu.';

  @override
  String get errorIdentityRecoveryPending => 'Eine frühere Identität wartet noch auf die Wiederherstellung. Starte die App neu, um es erneut zu versuchen, oder lösche die Identitätsdaten, um neu zu beginnen.';

  @override
  String get languageTitle => 'Sprache';

  @override
  String get languageSystemDefault => 'Systemsprache';

  @override
  String get languageSaveFailed => 'Die Spracheinstellung konnte nicht gespeichert werden. Versuche es erneut.';

  @override
  String learnLessonOf(int lesson, int total) {
    return 'Lektion $lesson von $total';
  }

  @override
  String learnCharsLearned(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Zeichen gelernt',
      one: '$count Zeichen gelernt',
    );
    return '$_temp0';
  }

  @override
  String learnDailyGoalProgress(int done, int goal) {
    return '$done / $goal Zeichen';
  }

  @override
  String learnStreakDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days Tage in Folge',
      one: '$days Tag in Folge',
    );
    return '$_temp0';
  }

  @override
  String learnReviewDueCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Wiederholungen fällig',
      one: '$count Wiederholung fällig',
      zero: 'Keine Wiederholung fällig',
    );
    return '$_temp0';
  }

  @override
  String learnRoundScore(int correct, int total) {
    return '$correct von $total richtig';
  }

  @override
  String learnRoundOf(int round) {
    return 'Runde $round';
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
      other: '$count Zeichen gesendet',
      one: '$count Zeichen gesendet',
    );
    return '$_temp0';
  }

  @override
  String learnLessonUnlocked(String char) {
    return 'Nächstes Zeichen freigeschaltet: $char';
  }

  @override
  String learnConfusedMissed(String target) {
    return '$target überhört';
  }

  @override
  String learnConfusedAs(String target, String answered) {
    return '$target als $answered gehört';
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
      other: '$count Zeichen',
      one: '$count Zeichen',
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
      other: '$count Zeichen gelernt',
      one: '$count Zeichen gelernt',
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
      other: '$count Zeichen aufgenommen',
      one: '$count Zeichen aufgenommen',
    );
    return '$_temp0';
  }

  @override
  String statsSessions(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Übungseinheiten',
      one: '$count Übungseinheit',
    );
    return '$_temp0';
  }

  @override
  String statsDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Tage',
      one: '$count Tag',
    );
    return '$_temp0';
  }

  @override
  String statsBestStreak(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Rekord: $count Tage',
      one: 'Rekord: $count Tag',
    );
    return '$_temp0';
  }

  @override
  String statsGoalProgress(int done, int goal) {
    return '$done / $goal Zeichen';
  }

  @override
  String statsGoalRemaining(int remaining) {
    String _temp0 = intl.Intl.pluralLogic(
      remaining,
      locale: localeName,
      other: 'Noch $remaining Zeichen',
      one: 'Noch $remaining Zeichen',
    );
    return '$_temp0';
  }

  @override
  String statsTrendSubtitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Letzte $count Übungseinheiten',
      one: 'Letzte Übungseinheit',
    );
    return '$_temp0';
  }

  @override
  String statsTooltipSession(int index, int total) {
    return 'Übungseinheit $index von $total';
  }

  @override
  String statsTooltipCopied(int correct, int total) {
    return '$correct / $total richtig';
  }

  @override
  String statsTooltipLesson(int lesson) {
    return 'Lektion $lesson';
  }

  @override
  String statsAttempts(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Versuche',
      one: '$count Versuch',
    );
    return '$_temp0';
  }

  @override
  String statsCorrectOf(int correct, int attempts) {
    return '$correct von $attempts richtig';
  }

  @override
  String statsLessonIntroduced(int lesson) {
    return 'In Lektion $lesson eingeführt';
  }

  @override
  String statsSrsBox(int box, int maxBox) {
    return 'Fach $box von $maxBox';
  }

  @override
  String statsSrsDueIn(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'In $days Tagen fällig',
      one: 'Morgen fällig',
    );
    return '$_temp0';
  }

  @override
  String statsTimes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count-mal',
      one: '$count-mal',
    );
    return '$_temp0';
  }

  @override
  String statsHeatmapCell(String target, String answered, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count-mal',
      one: '$count-mal',
    );
    return '$target als $answered beantwortet, $_temp0';
  }

  @override
  String statsCalendarDay(String date, int chars) {
    String _temp0 = intl.Intl.pluralLogic(
      chars,
      locale: localeName,
      other: '$chars Zeichen',
      one: '$chars Zeichen',
      zero: 'Nicht geübt',
    );
    return '$date: $_temp0';
  }

  @override
  String statsActiveDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count aktive Tage',
      one: '$count aktiver Tag',
    );
    return '$_temp0';
  }

  @override
  String referenceEntryCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Einträge',
      one: '$count Eintrag',
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
    return 'Übersprungen (kein Morsecode): $chars';
  }

  @override
  String referenceKochPositionValue(int position) {
    return 'Koch-Reihenfolge: $position';
  }

  @override
  String referenceEstimatedSpeed(String wpm) {
    return 'Geschätzt $wpm WPM';
  }

  @override
  String get accountCopied => 'Tox-ID in die Zwischenablage kopiert';

  @override
  String get accountShowQr => 'QR-Code anzeigen';

  @override
  String get accountToxId => 'Tox-ID';

  @override
  String get accountDisplayName => 'Anzeigename';

  @override
  String get accountDisplayNameHint => 'Dein Rufzeichen oder Spitzname';

  @override
  String get accountDisplayNameRequired => 'Gib einen Anzeigenamen ein';

  @override
  String get accountStatusMessage => 'Statusnachricht';

  @override
  String get accountPassword => 'Passwort';

  @override
  String get accountPasswordOptional => 'Passwort (optional)';

  @override
  String get accountConfirmPassword => 'Passwort bestätigen';

  @override
  String get accountPasswordsDoNotMatch => 'Passwörter stimmen nicht überein';

  @override
  String get accountShowPassword => 'Passwort anzeigen';

  @override
  String get accountHidePassword => 'Passwort verbergen';

  @override
  String get accountStrengthWeak => 'Schwach: Verwende mindestens 8 Zeichen';

  @override
  String get accountStrengthFair => 'Mittel: Besser sind mindestens 12 Zeichen verschiedener Arten';

  @override
  String get accountStrengthStrong => 'Stark';

  @override
  String get accountStartupInspecting => 'Deine Identität wird geprüft…';

  @override
  String get accountStartupOpening => 'Deine Identität wird geöffnet…';

  @override
  String get accountStartupFailedTitle => 'Start fehlgeschlagen';

  @override
  String get accountStartupFailedBody => 'DitMesh konnte deine Identität nicht lesen. Es wurde nichts geändert; versuche es erneut.';

  @override
  String get accountConnectionTapToReconnect => 'Tippen, um die Verbindung wiederherzustellen';

  @override
  String get accountWelcomeTitle => 'Deine Identität ist auf diesem Gerät gespeichert';

  @override
  String get accountWelcomeIntro => 'DitMesh nutzt das Peer-to-Peer-Netzwerk Tox. Es gibt keinen Server und keine Registrierung: Deine Identität ist ein Schlüsselpaar, das nur hier gespeichert wird.';

  @override
  String get accountWelcomePointNoServer => 'Kein Server, keine Telefonnummer, keine E-Mail. Kontakte kommunizieren direkt miteinander in Morse.';

  @override
  String get accountWelcomePointTraining => 'Chatte einzeln oder in Gruppen mit Morsecode, einer Handtaste oder iambischen Paddles.';

  @override
  String get accountWelcomePointBackup => 'Niemand kann deine Identität für dich wiederherstellen. Sichere sie direkt nach dem Erstellen, sonst geht sie mit dem Gerät verloren.';

  @override
  String get accountCreateIdentity => 'Identität erstellen';

  @override
  String get accountRestoreFromBackup => 'Aus Sicherung wiederherstellen';

  @override
  String get accountCreateTitle => 'Deine Identität erstellen';

  @override
  String get accountCreateBody => 'Wähle einen Namen, den andere sehen. Ein Passwort verschlüsselt die Identitätsdatei auf diesem Gerät; lass das Feld leer, wenn du die App ohne Passwort öffnen möchtest.';

  @override
  String get accountCreateButton => 'Erstellen';

  @override
  String get accountCreating => 'Wird erstellt…';

  @override
  String get accountBackupTitle => 'Sichere jetzt deine Identität';

  @override
  String get accountBackupBody => 'Deine Identität existiert nur auf diesem Gerät. Geht das Gerät verloren, wird es zurückgesetzt oder gestohlen, kannst du sie nicht wiederherstellen: Deine Kontakte erkennen eine neue Identität nicht und dein Lernfortschritt geht verloren.';

  @override
  String get accountBackupWhatIsInside => 'Die Sicherungsdatei enthält deinen mit dem Passwort verschlüsselten Identitätsschlüssel und deinen Lernfortschritt. Bewahre sie an einem sicheren Ort außerhalb dieses Geräts auf.';

  @override
  String get accountBackupWhatIsInsidePlain => 'Die Sicherungsdatei enthält deinen Identitätsschlüssel unverschlüsselt sowie deinen Lernfortschritt. Wer die Datei bekommt, kann deine Identität benutzen: Lege zuerst ein Passwort fest, wenn der Schlüssel verschlüsselt sein soll, und bewahre die Datei sicher auf.';

  @override
  String get accountPasswordScope => 'Dein Passwort verschlüsselt deinen Identitätsschlüssel. Der Nachrichtenverlauf bleibt auf dem Datenträger unverschlüsselt; eine Geräteverschlüsselung kann ihn schützen.';

  @override
  String get accountSectionNotifications => 'Benachrichtigungen';

  @override
  String get accountNotificationsEnable => 'Benachrichtigungen anzeigen';

  @override
  String get accountNotificationsEnableSubtitle => 'Neue Nachrichten, Freundschaftsanfragen und Gruppeneinladungen';

  @override
  String get accountNotificationsContent => 'Nachrichteninhalt anzeigen';

  @override
  String get accountNotificationsContentSubtitle => 'Text und Morse in Bannern und auf dem Sperrbildschirm. Aus: nur der Hinweis, dass eine Nachricht kam.';

  @override
  String get accountNotificationsAllow => 'Benachrichtigungen erlauben';

  @override
  String get accountNotificationsAllowSubtitle => 'Das System um Erlaubnis bitten';

  @override
  String get accountNotificationsDenied => 'Benachrichtigungen für DitMesh sind in den Systemeinstellungen ausgeschaltet.';

  @override
  String get accountBackupSaveFile => 'Sicherungsdatei speichern';

  @override
  String get accountBackupShareFile => 'Sicherungsdatei teilen';

  @override
  String get accountBackupSaved => 'Sicherung gespeichert';

  @override
  String get accountBackupNotSaved => 'Sicherung wurde nicht gespeichert';

  @override
  String get accountBackupFailed => 'Sicherung konnte nicht geschrieben werden';

  @override
  String get accountBackupAcknowledge => 'Ich verstehe, dass meine Identität ohne diese Sicherung nicht wiederhergestellt werden kann.';

  @override
  String get accountBackupContinue => 'Weiter zu DitMesh';

  @override
  String get accountBackupShowQrHint => 'Über deine Tox-ID können dich Freunde hinzufügen. Teile sie als Text oder QR-Code.';

  @override
  String get accountRestoreTitle => 'Aus Sicherung wiederherstellen';

  @override
  String get accountRestoreBody => 'Wähle eine aus DitMesh exportierte Sicherungsdatei. War die Identität mit einem Passwort geschützt, benötigst du es hier.';

  @override
  String get accountRestoreChooseFile => 'Sicherungsdatei wählen';

  @override
  String get accountRestoreNoFile => 'Wähle zuerst eine Sicherungsdatei';

  @override
  String get accountRestoreButton => 'Wiederherstellen';

  @override
  String get accountRestoring => 'Wird wiederhergestellt…';

  @override
  String get accountRestoreInvalidFile => 'Diese Datei ist keine DitMesh-Sicherung.';

  @override
  String get accountRestoreReplacesWarning => 'Die Wiederherstellung ersetzt die aktuelle Identität auf diesem Gerät.';

  @override
  String get accountUnlockTitle => 'Deine Identität entsperren';

  @override
  String get accountUnlockBody => 'Deine Identitätsdatei ist verschlüsselt. Gib das Passwort ein, um fortzufahren.';

  @override
  String get accountUnlockButton => 'Entsperren';

  @override
  String get accountUnlocking => 'Wird entsperrt…';

  @override
  String get accountUnlockRestoreInstead => 'Stattdessen aus Sicherung wiederherstellen';

  @override
  String get accountMeNoIdentity => 'Keine Identität geladen';

  @override
  String get accountSectionAccount => 'Konto';

  @override
  String get accountSectionTraining => 'Training';

  @override
  String get accountSectionAbout => 'Über';

  @override
  String get accountSectionDanger => 'Gefahrenbereich';

  @override
  String get accountEditProfile => 'Profil bearbeiten';

  @override
  String get accountEditProfileBody => 'Wird deinen Kontakten im Tox-Netzwerk angezeigt.';

  @override
  String get accountSetPassword => 'Passwort festlegen';

  @override
  String get accountChangePassword => 'Passwort ändern';

  @override
  String get accountRemovePassword => 'Passwort entfernen';

  @override
  String get accountCurrentPassword => 'Aktuelles Passwort';

  @override
  String get accountNewPassword => 'Neues Passwort';

  @override
  String get accountPasswordUpdated => 'Passwort aktualisiert';

  @override
  String get accountPasswordRemoved => 'Passwort entfernt';

  @override
  String get accountProfileUpdated => 'Profil aktualisiert';

  @override
  String get accountExportBackup => 'Sicherung exportieren';

  @override
  String get accountExportBackupSubtitle => 'Identität und Lernfortschritt in einer Datei speichern';

  @override
  String get accountTrainingDefaults => 'Standardwerte für Wiedergabe und Training';

  @override
  String get accountTrainingDefaultsSubtitle => 'Geschwindigkeit, Tonhöhe, Farnsworth-Abstände';

  @override
  String get accountTrainingDefaultsPlaceholder => 'Hier werden die Standardwerte für Geschwindigkeit, Tonhöhe und Farnsworth eingestellt.';

  @override
  String get accountAboutLicence => 'Lizenz';

  @override
  String get accountAboutLicenceValue => 'GPL-3.0';

  @override
  String get accountAboutSource => 'Quellcode';

  @override
  String get accountAboutSourceCopied => 'Quellcode-Link kopiert';

  @override
  String get accountAboutBackend => 'Backend';

  @override
  String get accountDeleteIdentity => 'Identität löschen';

  @override
  String get accountDeleteIdentitySubtitle => 'Diese Identität, den Verlauf und Fortschritt von diesem Gerät löschen';

  @override
  String get accountDeleteDialogTitle => 'Diese Identität löschen?';

  @override
  String get accountDeleteDialogBody => 'Dadurch werden deine Identität, dein Chatverlauf und dein Lernfortschritt von diesem Gerät gelöscht. Ohne Sicherung ist keine Wiederherstellung möglich. Gib zur Bestätigung DELETE ein.';

  @override
  String get accountDeleteConfirmWord => 'DELETE';

  @override
  String get accountDeleteConfirmHint => 'DELETE eingeben';

  @override
  String get accountDeleteButton => 'Löschen';

  @override
  String get accountRecoveryPendingDiscard => 'Wartende Identität verwerfen und neu beginnen';

  @override
  String accountRestoreFileChosenSize(int bytes) {
    return 'Sicherungsdatei ausgewählt ($bytes Bytes)';
  }

  @override
  String get chatSearchConversations => 'Gespräche durchsuchen';

  @override
  String get chatNoConversations => 'Noch keine Gespräche';

  @override
  String get chatNoSearchResults => 'Keine passenden Gespräche';

  @override
  String get chatPin => 'Anheften';

  @override
  String get chatUnpin => 'Lösen';

  @override
  String get chatMarkRead => 'Als gelesen markieren';

  @override
  String get chatDelete => 'Löschen';

  @override
  String get chatDeleteConversationTitle => 'Gespräch löschen?';

  @override
  String get chatDeleteConversationBody => 'Der lokale Verlauf dieses Gesprächs wird gelöscht. Tox speichert keine Kopie.';

  @override
  String get chatDraftPrefix => 'Entwurf: ';

  @override
  String get chatSelectConversation => 'Wähle ein Gespräch';

  @override
  String get chatContacts => 'Kontakte';

  @override
  String get chatNoMessages => 'Noch keine Nachrichten – sende CQ zum Starten.';

  @override
  String get chatTrainingMode => 'Trainingsmodus';

  @override
  String get chatTrainingModeOn => 'Trainingsmodus an: Text verborgen';

  @override
  String get chatTrainingModeOff => 'Trainingsmodus aus';

  @override
  String get chatAutoPlay => 'Empfangene Morsezeichen automatisch abspielen';

  @override
  String get chatAutoPlayOn => 'Automatische Wiedergabe an: neue Nachrichten werden beim Eintreffen abgespielt';

  @override
  String get chatAutoPlayOff => 'Automatische Wiedergabe aus';

  @override
  String get chatReveal => 'Einblenden';

  @override
  String get chatHiddenText => 'Erst hören, dann einblenden';

  @override
  String get chatPlay => 'Morse abspielen';

  @override
  String get chatStop => 'Stoppen';

  @override
  String get chatPlaybackSettings => 'Wiedergabeeinstellungen';

  @override
  String get chatCharacterSpeed => 'Zeichengeschwindigkeit';

  @override
  String get chatFarnsworthSpeed => 'Farnsworth-Geschwindigkeit';

  @override
  String get chatTone => 'Tonhöhe';

  @override
  String get chatWpm => 'WPM';

  @override
  String get chatHz => 'Hz';

  @override
  String get chatMembers => 'Mitglieder';

  @override
  String get chatLeaveGroup => 'Gruppe verlassen';

  @override
  String get chatLeaveGroupTitle => 'Diese Gruppe verlassen?';

  @override
  String get chatLeaveGroupBody => 'Du empfängst keine Nachrichten mehr. Mit der Chat-ID kannst du später wieder beitreten.';

  @override
  String get chatLeave => 'Verlassen';

  @override
  String get chatConferenceNote => 'Klassische Konferenz: Morse-Tastdaten (v2) sind hier nicht verfügbar. Textnachrichten funktionieren weiterhin.';

  @override
  String get chatClearHistory => 'Verlauf löschen';

  @override
  String get chatModeStraightKey => 'Handtaste';

  @override
  String get chatModePaddles => 'Paddles';

  @override
  String get chatKeyMessage => 'Nachricht morsen';

  @override
  String get chatSend => 'Senden';

  @override
  String get chatTooLong => 'Zu lang für eine einzelne Tox-Nachricht';

  @override
  String get chatKeyHint => 'Auf der Taste morsen oder die Leertaste drücken';

  @override
  String get chatPaddleHint => 'Tippe auf die Paddles oder halte Ctrl gedrückt (links Punkt, rechts Strich)';

  @override
  String get chatDeleteLast => 'Letztes Zeichen löschen';

  @override
  String get chatNoFriends => 'Noch keine Freunde. Füge jemanden über die Tox-ID hinzu.';

  @override
  String get chatNoRequests => 'Keine offenen Anfragen';

  @override
  String get chatAddFriend => 'Freund hinzufügen';

  @override
  String get chatMyToxId => 'Meine Tox-ID';

  @override
  String get chatToxIdLabel => 'Tox-ID (76 Hexadezimalzeichen)';

  @override
  String get chatToxIdInvalid => 'Die Tox-ID muss genau 76 Hexadezimalzeichen lang sein';

  @override
  String get chatToxIdOwn => 'Das ist deine eigene Tox-ID';

  @override
  String get chatToxIdAlreadyFriend => 'Bereits in deiner Freundesliste';

  @override
  String get chatRequestMessage => 'Nachricht';

  @override
  String get chatDefaultRequestMessage => 'DitMesh CQ';

  @override
  String get chatSendRequest => 'Anfrage senden';

  @override
  String get chatRequestSent => 'Freundschaftsanfrage gesendet';

  @override
  String get chatScanQr => 'QR-Code scannen';

  @override
  String get chatScanQrDesktopHint => 'Zum Scannen von QR-Codes ist eine Handykamera erforderlich';

  @override
  String get chatScanQrTitle => 'Tox-ID scannen';

  @override
  String get chatScanQrNotToxId => 'Dieser QR-Code ist keine Tox-ID';

  @override
  String get chatAccept => 'Annehmen';

  @override
  String get chatReject => 'Ablehnen';

  @override
  String get chatCopied => 'In die Zwischenablage kopiert';

  @override
  String get chatNoIdentity => 'Keine Identität geladen';

  @override
  String get chatRemoveFriend => 'Freund entfernen';

  @override
  String get chatRemoveFriendTitle => 'Diesen Freund entfernen?';

  @override
  String get chatRemoveFriendBody => 'Diese Person kann dir danach keine Nachrichten mehr senden.';

  @override
  String get chatRemove => 'Entfernen';

  @override
  String get chatNoGroups => 'Noch keine Gruppen. Erstelle eine oder tritt über eine Chat-ID bei.';

  @override
  String get chatCreateGroup => 'Gruppe erstellen';

  @override
  String get chatJoinGroup => 'Gruppe beitreten';

  @override
  String get chatGroupName => 'Gruppenname';

  @override
  String get chatGroupNameRequired => 'Gib der Gruppe einen Namen';

  @override
  String get chatAdvanced => 'Erweitert';

  @override
  String get chatLegacyConference => 'Klassische Konferenz (ältere Clients)';

  @override
  String get chatLegacyConferenceHint => 'Nicht empfohlen: keine dauerhafte Chat-ID, keine Morse-Metadaten.';

  @override
  String get chatCreate => 'Erstellen';

  @override
  String get chatChatIdLabel => 'Chat-ID (64 Hexadezimalzeichen)';

  @override
  String get chatChatIdInvalid => 'Die Chat-ID muss genau 64 Hexadezimalzeichen lang sein';

  @override
  String get chatPassword => 'Passwort (optional)';

  @override
  String get chatJoin => 'Beitreten';

  @override
  String get chatJoinRequested => 'Beitritt läuft – die Gruppe erscheint, sobald ein Teilnehmer gefunden wurde.';

  @override
  String get chatConferenceBadge => 'Konferenz';

  @override
  String get chatCopyChatId => 'Chat-ID kopieren';

  @override
  String get learnLessonCardTitle => 'Koch-Lektion';

  @override
  String get learnCourseComplete => 'Kurs abgeschlossen – bleib dran!';

  @override
  String get learnDailyGoalTitle => 'Heute';

  @override
  String get learnDailyGoalMet => 'Tagesziel erreicht';

  @override
  String get learnNoStreak => 'Starte heute eine Serie';

  @override
  String get learnContinueLesson => 'Lektion fortsetzen';

  @override
  String get learnReceivePractice => 'Hörtraining';

  @override
  String get learnSendPractice => 'Gebetraining';

  @override
  String get learnReviewDue => 'Fällige Zeichen wiederholen';

  @override
  String get learnSettings => 'Trainingseinstellungen';

  @override
  String get learnLoading => 'Dein Fortschritt wird geladen…';

  @override
  String get learnIdentityRequired => 'Erstelle oder entsperre deine Identität, um mit dem Training zu beginnen. Dein Fortschritt wird mit der Identität gespeichert und mit deiner Sicherung übertragen.';

  @override
  String get learnLoadFailed => 'Dein gespeicherter Fortschritt konnte nicht gelesen werden. Du beginnst neu; die alte Datei wurde als .corrupt aufbewahrt.';

  @override
  String get learnProgressSaveFailed => 'Fortschritt konnte nicht gespeichert werden. Das Ergebnis zählt, solange DitMesh geöffnet bleibt.';

  @override
  String get learnChooseDrill => 'Übung wählen';

  @override
  String get learnDrillGroups => 'Zufällige Gruppen';

  @override
  String get learnDrillWords => 'Wörter';

  @override
  String get learnDrillCallsigns => 'Rufzeichen';

  @override
  String get learnDrillQso => 'QSO';

  @override
  String get learnDrillCharacters => 'Einzelzeichen';

  @override
  String get learnDrillAbbreviations => 'Abkürzungen und Q-Gruppen';

  @override
  String get learnDrillNumbers => 'Zifferngruppen';

  @override
  String get learnDrillConfusables => 'Ähnliche Zeichen';

  @override
  String get learnDrillContest => 'Contest-Austausch';

  @override
  String get learnDrillGroupsHint => 'Zufällige Gruppen aus allen gelernten Buchstaben';

  @override
  String get learnDrillCharactersHint => 'Ein Zeichen nach dem anderen – sofort erkennen';

  @override
  String get learnDrillWordsHint => 'Häufige englische Wörter';

  @override
  String get learnDrillAbbreviationsHint => 'TNX, FB, QTH, QSL – Kurzformen im Funkverkehr';

  @override
  String get learnDrillNumbersHint => 'Fünfstellige Gruppen, wie in Telegrammen und laufenden Nummern';

  @override
  String get learnDrillCallsignsHint => 'Amateurfunkrufzeichen aus aller Welt';

  @override
  String get learnDrillConfusablesHint => 'Verwechselte Zeichenpaare wie S/H oder U/V direkt vergleichen';

  @override
  String get learnDrillQsoHint => 'Zeilen aus einer vollständigen Funkverbindung';

  @override
  String get learnDrillContestHint => 'Rufzeichen, 5NN und laufende Nummer oder Zone im Contest-Tempo';

  @override
  String get learnDrillReviewHint => 'Zeichen, deren Wiederholung fällig ist';

  @override
  String get toolsTitle => 'Funkwerkzeuge';

  @override
  String get toolsGridTitle => 'Locator';

  @override
  String get toolsGridHint => 'Locator aus Koordinaten, Entfernung und Antennenrichtung';

  @override
  String get toolsBandsTitle => 'Bänder und Antennen';

  @override
  String get toolsBandsHint => 'Band einer Frequenz, Wellenlänge und Dipollänge';

  @override
  String get toolsSpeedTitle => 'CW-Geschwindigkeit';

  @override
  String get toolsSpeedHint => 'WPM in Punktlänge, Pausen und Zeichen pro Minute umrechnen';

  @override
  String get toolsRstTitle => 'RST-Rapport';

  @override
  String get toolsRstHint => 'Signalrapport erstellen und die Bedeutung jeder Ziffer ansehen';

  @override
  String get toolsClockTitle => 'UTC-Uhr';

  @override
  String get toolsClockHint => 'UTC-Zeit fürs Logbuch neben deiner Ortszeit';

  @override
  String get toolsGridFromCoordinates => 'Aus Koordinaten';

  @override
  String get toolsGridLatitude => 'Breitengrad';

  @override
  String get toolsGridLongitude => 'Längengrad';

  @override
  String get toolsGridCoordinatesHelp => 'Dezimalgrad; Süden und Westen sind negativ';

  @override
  String get toolsGridInvalidCoordinates => 'Breitengrad −90 bis 90, Längengrad −180 bis 180';

  @override
  String get toolsGridLocator => 'Locator';

  @override
  String get toolsGridDistanceSection => 'Entfernung und Richtung';

  @override
  String get toolsGridMine => 'Mein Locator';

  @override
  String get toolsGridTheirs => 'Locator der Gegenstation';

  @override
  String get toolsGridInvalidLocator => '2, 4, 6 oder 8 Zeichen, z. B. OM89ex';

  @override
  String get toolsGridCenter => 'Feldmitte';

  @override
  String get toolsGridDistance => 'Entfernung';

  @override
  String get toolsGridShortPath => 'Kurzweg-Richtung';

  @override
  String get toolsGridLongPath => 'Langweg-Richtung';

  @override
  String get toolsBandsFrequency => 'Frequenz (MHz)';

  @override
  String get toolsBandsInvalidFrequency => 'Gib eine Frequenz größer als 0 ein';

  @override
  String toolsBandsRegionLabel(int number) {
    return 'Region $number';
  }

  @override
  String get toolsBandsRegionHelp => '1: Europa, Afrika, Naher Osten – 2: Amerika – 3: Asien-Pazifik';

  @override
  String toolsBandsInBand(String band) {
    return 'Im Amateurband $band';
  }

  @override
  String get toolsBandsOutOfBand => 'Außerhalb der Amateurbänder';

  @override
  String get toolsBandsWavelength => 'Wellenlänge';

  @override
  String get toolsBandsDipole => 'Halbwellendipol (gesamt)';

  @override
  String get toolsBandsQuarterWave => 'Viertelwellenstrahler';

  @override
  String get toolsBandsAntennaNote => 'Längen mit Verkürzungsfaktor 0,95; auf Resonanz kürzen.';

  @override
  String get toolsBandsTable => 'Bandgrenzen';

  @override
  String toolsBandsQrp(String frequency) {
    return 'QRP CW $frequency';
  }

  @override
  String get toolsBandsDisclaimer => 'ITU-Zuweisungen. Deine Lizenz und der nationale Bandplan können enger sein.';

  @override
  String get toolsSpeedCharacter => 'Zeichengeschwindigkeit';

  @override
  String get toolsSpeedFarnsworth => 'Farnsworth-Abstände';

  @override
  String get toolsSpeedOverall => 'Gesamtgeschwindigkeit';

  @override
  String get toolsSpeedDit => 'Punkt';

  @override
  String get toolsSpeedDah => 'Strich';

  @override
  String get toolsSpeedCharGap => 'Zeichenpause';

  @override
  String get toolsSpeedWordGap => 'Wortpause';

  @override
  String get toolsSpeedCpm => 'Zeichen pro Minute';

  @override
  String get toolsSpeedParis => 'Ein PARIS-Wort';

  @override
  String get toolsRstReadability => 'Lesbarkeit (R)';

  @override
  String get toolsRstStrength => 'Signalstärke (S)';

  @override
  String get toolsRstTone => 'Tonqualität (T)';

  @override
  String get toolsRstReport => 'Rapport';

  @override
  String get toolsRstCut => 'Contest-Form';

  @override
  String get toolsRstPhone => 'Sprechfunk (ohne T)';

  @override
  String get toolsRstR1 => 'Nicht lesbar';

  @override
  String get toolsRstR2 => 'Kaum lesbar, einzelne Wörter';

  @override
  String get toolsRstR3 => 'Nur mit großer Mühe lesbar';

  @override
  String get toolsRstR4 => 'Fast mühelos lesbar';

  @override
  String get toolsRstR5 => 'Einwandfrei lesbar';

  @override
  String get toolsRstS1 => 'Schwach, kaum wahrnehmbar';

  @override
  String get toolsRstS2 => 'Sehr schwach';

  @override
  String get toolsRstS3 => 'Schwach';

  @override
  String get toolsRstS4 => 'Mäßig';

  @override
  String get toolsRstS5 => 'Ziemlich gut';

  @override
  String get toolsRstS6 => 'Gut';

  @override
  String get toolsRstS7 => 'Mäßig stark';

  @override
  String get toolsRstS8 => 'Stark';

  @override
  String get toolsRstS9 => 'Äußerst stark';

  @override
  String get toolsRstT1 => 'Sehr rau und breit, roher Wechselstromton';

  @override
  String get toolsRstT2 => 'Sehr rauer Wechselstromton, scharf und breit';

  @override
  String get toolsRstT3 => 'Rau, gleichgerichtet, aber ungefiltert';

  @override
  String get toolsRstT4 => 'Rau, mit geringer Filterung';

  @override
  String get toolsRstT5 => 'Gefiltert, aber stark durch Restwelligkeit moduliert';

  @override
  String get toolsRstT6 => 'Gefiltert, mit deutlicher Restwelligkeit';

  @override
  String get toolsRstT7 => 'Fast rein, mit geringer Restwelligkeit';

  @override
  String get toolsRstT8 => 'Nahezu perfekt, mit geringer Modulation';

  @override
  String get toolsRstT9 => 'Reiner Ton, ohne Restwelligkeit';

  @override
  String get toolsClockUtc => 'UTC';

  @override
  String get toolsClockLocal => 'Ortszeit';

  @override
  String get toolsClockNote => 'Logbücher und QSL-Karten verwenden UTC.';

  @override
  String get learnReceiveTitle => 'Empfangen';

  @override
  String get learnReviewTitle => 'Wiederholen';

  @override
  String get learnListen => 'Hören…';

  @override
  String get learnReady => 'Bereit';

  @override
  String get learnReplay => 'Erneut abspielen';

  @override
  String get learnAnswerHint => 'Gib ein, was du gehört hast';

  @override
  String get learnSubmit => 'Prüfen';

  @override
  String get learnNext => 'Weiter';

  @override
  String get learnFinish => 'Beenden';

  @override
  String get learnDone => 'Fertig';

  @override
  String get learnBackspace => 'Löschen';

  @override
  String get learnSpace => 'Leerzeichen';

  @override
  String get learnSent => 'Gesendet';

  @override
  String get learnYourCopy => 'Deine Mitschrift';

  @override
  String get learnRoundPerfect => 'Fehlerfrei aufgenommen!';

  @override
  String get learnSessionSummary => 'Übungsübersicht';

  @override
  String get learnLessonPassed => 'Lektion bestanden';

  @override
  String get learnLessonNotPassed => 'Bleib dran: 90 % schalten die nächste Lektion frei';

  @override
  String get learnReviewRecorded => 'Wiederholung gespeichert';

  @override
  String get learnWeakChars => 'Noch üben';

  @override
  String get learnConfusions => 'Verwechselt';

  @override
  String get learnNoFeedbackWarning => 'Ton, Blinken und Vibration sind ausgeschaltet – stattdessen blinkt der Bildschirm.';

  @override
  String get learnSendTitle => 'Senden';

  @override
  String get learnSendThis => 'Sende diesen Text';

  @override
  String get learnCopyFromMemory => 'Aus dem Gedächtnis';

  @override
  String get learnHiddenTarget => 'Verborgen – aus dem Gedächtnis morsen';

  @override
  String get learnDecoded => 'Decodiert';

  @override
  String get learnWaitingForKey => 'Beginne zu morsen, sobald du bereit bist';

  @override
  String get learnRestart => 'Neu starten';

  @override
  String get learnTryAnother => 'Anderen Text versuchen';

  @override
  String get learnKeyerStraight => 'Handtaste';

  @override
  String get learnKeyerIambicA => 'Iambic A';

  @override
  String get learnKeyerIambicB => 'Iambic B';

  @override
  String get learnLegendStraight => 'Leertaste = Taste';

  @override
  String get learnLegendPaddles => 'Linke Ctrl = Punkt, rechte Ctrl = Strich';

  @override
  String get learnSendClean => 'Sauber gegeben – nichts zu verbessern.';

  @override
  String get learnSendIssues => 'Hinweise zum Rhythmus';

  @override
  String get learnYourSending => 'Decodiert als';

  @override
  String get learnStraightKeyLabel => 'TASTE';

  @override
  String get learnDitLabel => 'PUNKT';

  @override
  String get learnDahLabel => 'STRICH';

  @override
  String get learnSettingsTitle => 'Trainingseinstellungen';

  @override
  String get learnCharacterSpeed => 'Zeichengeschwindigkeit';

  @override
  String get learnFarnsworth => 'Farnsworth-Abstände';

  @override
  String get learnFarnsworthHelp => 'Die Zeichen bleiben schnell; die Pausen dazwischen werden auf diese Geschwindigkeit verlängert.';

  @override
  String get learnEffectiveSpeed => 'Effektive Geschwindigkeit';

  @override
  String get learnTone => 'Tonhöhe';

  @override
  String get learnPlaySample => 'Beispiel abspielen';

  @override
  String get learnSessionLength => 'Übungslänge';

  @override
  String get learnFeedback => 'Rückmeldung';

  @override
  String get learnSound => 'Ton';

  @override
  String get learnFlash => 'Bildschirmblinken';

  @override
  String get learnHaptic => 'Vibration';

  @override
  String get learnKeyer => 'Morsetaste';

  @override
  String get learnDailyGoal => 'Tagesziel';

  @override
  String get referenceReferenceTitle => 'Morse-Nachschlagewerk';

  @override
  String get referenceTranslatorTitle => 'Übersetzer';

  @override
  String get referencePlay => 'Abspielen';

  @override
  String get referenceStop => 'Stoppen';

  @override
  String get referenceClear => 'Leeren';

  @override
  String get referenceClose => 'Schließen';

  @override
  String get referenceEmptyOutput => '—';

  @override
  String get referenceSearchHint => 'Zeichen, Verkehrszeichen, Q-Gruppen suchen…';

  @override
  String get referenceClearSearch => 'Suche löschen';

  @override
  String get referenceNoResults => 'Keine passenden Suchergebnisse.';

  @override
  String get referenceSectionAlphabet => 'Alphabet';

  @override
  String get referenceSectionPunctuation => 'Satzzeichen';

  @override
  String get referenceSectionProsigns => 'Verkehrszeichen';

  @override
  String get referenceSectionQCodes => 'Q-Gruppen';

  @override
  String get referenceSectionAbbreviations => 'CW-Abkürzungen';

  @override
  String get referenceSectionKoch => 'Koch-Reihenfolge';

  @override
  String get referenceAlphabetHint => 'Tippe auf eine Karte, um sie zu hören. Halte sie gedrückt, um eine Merkhilfe anzuzeigen.';

  @override
  String get referenceKochHint => 'Die Reihenfolge, in der die Koch-Methode Zeichen einführt (LCWO-Abfolge). Beginne mit K und M; füge bei 90 % richtig aufgenommenen Zeichen ein weiteres hinzu.';

  @override
  String get referenceMnemonicTitle => 'Merkhilfe';

  @override
  String get referenceMeaningLabel => 'Bedeutung';

  @override
  String get referencePlaybackSettings => 'Wiedergabeeinstellungen';

  @override
  String get referenceCharacterSpeed => 'Zeichengeschwindigkeit';

  @override
  String get referenceFarnsworth => 'Farnsworth-Abstände';

  @override
  String get referenceFarnsworthHelp => 'Die Zeichen behalten ihre volle Geschwindigkeit; die Pausen werden für die effektive Geschwindigkeit verlängert.';

  @override
  String get referenceEffectiveSpeed => 'Effektive Geschwindigkeit';

  @override
  String get referenceTone => 'Tonhöhe';

  @override
  String get referenceModeTextToMorse => 'Text → Morse';

  @override
  String get referenceModeMorseToText => 'Morse → Text';

  @override
  String get referenceModeKey => 'Morsen';

  @override
  String get referenceTextInputLabel => 'Text';

  @override
  String get referenceTextInputHint => 'Text zum Codieren eingeben…';

  @override
  String get referencePatternOutputLabel => 'Morse';

  @override
  String get referenceCopyPattern => 'Muster kopieren';

  @override
  String get referencePatternCopied => 'Muster kopiert';

  @override
  String get referencePatternInputLabel => 'Morse';

  @override
  String get referencePatternInputHint => 'Gib . und - ein, Leerzeichen zwischen Buchstaben und / zwischen Wörtern';

  @override
  String get referenceTextOutputLabel => 'Text';

  @override
  String get referenceCopyText => 'Text kopieren';

  @override
  String get referenceTextCopied => 'Text kopiert';

  @override
  String get referenceUnknownPatternHelp => 'Muster ohne zugeordnetes Zeichen werden als <pattern> angezeigt.';

  @override
  String get referenceKeypadDit => 'Punkt';

  @override
  String get referenceKeypadDah => 'Strich';

  @override
  String get referenceKeypadCharGap => 'Buchstabenpause';

  @override
  String get referenceKeypadWordGap => 'Wortpause';

  @override
  String get referenceKeypadBackspace => 'Rücktaste';

  @override
  String get referenceKeyHint => 'Halte die Taste gedrückt, um zu senden. Halte auf einer Tastatur die Leertaste gedrückt.';

  @override
  String get referenceKeyLabel => 'TASTE';

  @override
  String get referenceKeyDecodedLabel => 'Decodiert';

  @override
  String get referenceKeyPendingLabel => 'Tastung';

  @override
  String get statsTitle => 'Statistik';

  @override
  String get statsLoading => 'Deine Statistik wird geladen…';

  @override
  String get statsLoadFailed => 'Dein Fortschritt konnte nicht geladen werden. Ziehe nach unten oder öffne die Seite erneut, um es noch einmal zu versuchen.';

  @override
  String get statsRetry => 'Erneut versuchen';

  @override
  String get statsEmptyTitle => 'Noch keine Übungseinheiten';

  @override
  String get statsEmptyBody => 'Schließe deine erste Hör- oder Gebeübung ab. Dann erscheinen hier dein Genauigkeitsverlauf, deine Stärken bei einzelnen Zeichen und ein Übungskalender.';

  @override
  String get statsEmptyCallToAction => 'Gehe zu „Lernen“ und drücke „Lektion fortsetzen“, um zu beginnen.';

  @override
  String get statsOverviewTitle => 'Übersicht';

  @override
  String get statsTileLesson => 'Koch-Lektion';

  @override
  String get statsTileAccuracy => 'Genauigkeit';

  @override
  String get statsNoData => '--';

  @override
  String get statsTilePractice => 'Übung';

  @override
  String get statsTileStreak => 'Serie';

  @override
  String get statsTileDailyGoal => 'Tagesziel';

  @override
  String get statsGoalMet => 'Heute erreicht';

  @override
  String get statsSummaryTitle => 'Deine Statistik';

  @override
  String get statsSummaryOpen => 'Statistik anzeigen';

  @override
  String get statsTrendTitle => 'Genauigkeitsverlauf';

  @override
  String get statsTrendHint => 'Tippe auf einen Punkt, um eine Übungseinheit anzusehen.';

  @override
  String get statsSeriesReceive => 'Empfangen';

  @override
  String get statsSeriesSend => 'Senden';

  @override
  String get statsAxisSessions => 'Übungseinheit';

  @override
  String get statsCharsTitle => 'Zeichen';

  @override
  String get statsCharsSubtitle => 'Koch-Reihenfolge. Tippe auf ein Zeichen für Details.';

  @override
  String get statsCharsNotStarted => 'Noch nicht geübt';

  @override
  String get statsNotInCourse => 'Nicht im Koch-Kurs enthalten';

  @override
  String get statsSrsTitle => 'Verteilte Wiederholung';

  @override
  String get statsSrsNotTracked => 'Noch nicht eingeplant';

  @override
  String get statsSrsDueNow => 'Jetzt fällig';

  @override
  String get statsConfusionsTitle => 'Am häufigsten verwechselt mit';

  @override
  String get statsConfusionsNone => 'Keine Verwechslungen aufgezeichnet';

  @override
  String get statsConfusionMissed => 'überhört';

  @override
  String get statsBucketLegendTitle => 'Genauigkeit';

  @override
  String get statsBucketNone => 'Keine';

  @override
  String get statsBucketWeak => '< 70%';

  @override
  String get statsBucketFair => '70-89%';

  @override
  String get statsBucketGood => '90-97%';

  @override
  String get statsBucketStrong => '>= 98%';

  @override
  String get statsHeatmapTitle => 'Verwechslungen';

  @override
  String get statsHeatmapSubtitle => 'Zeilen zeigen das gesendete Zeichen, Spalten deine Antwort. Dunkler bedeutet häufiger.';

  @override
  String get statsHeatmapEmpty => 'Noch keine Verwechslungen. Falsche Antworten erscheinen hier.';

  @override
  String get statsHeatmapLegendLow => 'Selten';

  @override
  String get statsHeatmapLegendHigh => 'Häufig';

  @override
  String get statsHeatmapAxisTarget => 'Gesendet';

  @override
  String get statsHeatmapAxisAnswered => 'Geantwortet';

  @override
  String get statsCalendarTitle => 'Übungskalender';

  @override
  String get statsCalendarSubtitle => 'Letzte 12 Wochen';

  @override
  String get statsCalendarLegendLess => 'Weniger';

  @override
  String get statsCalendarLegendMore => 'Mehr';

  @override
  String get statsStreakExplanation => 'Eine Serie zählt aufeinanderfolgende Kalendertage mit mindestens einer Übungseinheit. Ein ganzer Tag ohne Übung setzt sie zurück; zweimal an einem Tag zu üben zählt nur einmal.';

  @override
  String get learnStatistics => 'Statistik';

  @override
  String get listenTitle => 'Mithören';

  @override
  String get listenStart => 'Starten';

  @override
  String get listenStop => 'Stoppen';

  @override
  String get listenStarting => 'Mikrofon wird gestartet…';

  @override
  String get listenClear => 'Text löschen';

  @override
  String get listenCopy => 'Text kopieren';

  @override
  String get listenCopied => 'Decodierter Text kopiert';

  @override
  String get listenSettings => 'Mithöreinstellungen';

  @override
  String get listenDecoded => 'Decodiert';

  @override
  String get listenEmptyHint => 'Richte das Mikrofon auf einen Morseton. Der decodierte Text erscheint hier.';

  @override
  String get listenIdleHint => 'Tippe auf „Starten“, um einen Morseton mitzuhören.';

  @override
  String get listenPending => 'Empfang läuft';

  @override
  String get listenSpeed => 'Geschwindigkeit';

  @override
  String get listenSpeedUnknown => '-- WPM';

  @override
  String get listenLevel => 'Signal';

  @override
  String get listenToneOn => 'Ton';

  @override
  String get listenTone => 'Tonfrequenz';

  @override
  String get listenToneLocked => 'Erfasst';

  @override
  String get listenToneSearching => 'Wird gesucht';

  @override
  String get listenToneManual => 'Manuell';

  @override
  String get listenAutoTune => 'Automatisch abstimmen';

  @override
  String get listenAutoTuneHelp => 'Folgt dem stärksten Ton zwischen 400 und 1000 Hz. Ziehe am Regler, um stattdessen manuell abzustimmen.';

  @override
  String get listenRetune => 'Automatisch';

  @override
  String get listenBlockSize => 'Analyseblock';

  @override
  String get listenBlockSizeHelp => 'Kleinere Blöcke erfassen Signalflanken genauer, nehmen aber mehr Rauschen auf. 256 Abtastwerte (5,3 ms) eignen sich für 5–40 WPM.';

  @override
  String get listenMinElement => 'Kürzestes Element';

  @override
  String get listenMinElementHelp => 'Kürzere Töne und Pausen werden als Klicks und Aussetzer ignoriert.';

  @override
  String get listenPermissionDenied => 'Der Mikrofonzugriff wurde verweigert. Erlaube ihn in den Systemeinstellungen und versuche es erneut.';

  @override
  String get listenPermissionRetry => 'Erneut versuchen';

  @override
  String get listenStartFailed => 'Das Mikrofon konnte nicht gestartet werden.';

  @override
  String get listenNoInput => 'Kein Mikrofon gefunden. Schließe eines an und versuche es erneut.';

  @override
  String get listenStreamFailed => 'Das Mikrofon wurde unerwartet beendet. Versuche es erneut.';

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
    return '$samples Abtastwerte ($ms ms)';
  }

  @override
  String listenMsValue(int ms) {
    return '$ms ms';
  }

  @override
  String get listenStoppedInBackground => 'Das Mithören wurde gestoppt, während die App im Hintergrund war.';

  @override
  String get learnWpmUnknown => '-- WPM';

  @override
  String get learnTipDitTooLongTitle => 'Punkte zu lang';

  @override
  String get learnTipDahTooShortTitle => 'Striche zu kurz';

  @override
  String get learnTipIntraGapTooLongTitle => 'Elemente zu weit auseinander';

  @override
  String get learnTipCharGapTooShortTitle => 'Zeichen zu dicht beieinander';

  @override
  String get learnTipWordGapTooShortTitle => 'Wörter zu dicht beieinander';

  @override
  String get learnTipSpeedUnsteadyTitle => 'Ungleichmäßiges Tempo';

  @override
  String get learnSeverityMinor => 'leicht';

  @override
  String get learnSeverityModerate => 'merklich';

  @override
  String get learnSeveritySevere => 'stark';

  @override
  String get notificationOpen => 'Öffnen';

  @override
  String get notificationChannelMessages => 'Nachrichten';

  @override
  String get notificationChannelMessagesDescription => 'Neue Morsenachrichten von Freunden und Gruppen';

  @override
  String get notificationChannelFriendRequests => 'Freundschaftsanfragen';

  @override
  String get notificationChannelFriendRequestsDescription => 'Jemand möchte dich als Freund hinzufügen';

  @override
  String get notificationChannelGroupInvites => 'Gruppeneinladungen';

  @override
  String get notificationChannelGroupInvitesDescription => 'Ein Freund hat dich in eine Gruppe eingeladen';

  @override
  String get notificationNewMessage => 'Neue Nachricht';

  @override
  String get notificationFriendRequestTitle => 'Neue Freundschaftsanfrage';

  @override
  String learnNewestCharIs(String char) {
    return 'Neu in dieser Lektion: $char';
  }

  @override
  String learnCharNewSemantics(String char) {
    return '$char, neu';
  }

  @override
  String learnPendingPattern(String pattern) {
    return 'Tastung: $pattern';
  }

  @override
  String learnIssueHeadline(String title, String severity) {
    return '$title ($severity)';
  }

  @override
  String learnRatioTimes(String ratio) {
    return '${ratio}x';
  }

  @override
  String learnTipDitTooLong(String ratio) {
    return 'Deine Punkte sind zu lang (etwa $ratio einer Punktlänge). Denke an „di“, nicht „daaah“ – ein Punkt ist ein kurzes Antippen.';
  }

  @override
  String learnTipDahTooShort(String ratio) {
    return 'Deine Striche sind zu kurz (etwa $ratio einer Punktlänge; Ziel ist 3). Halte einen Strich so lang wie drei Punkte.';
  }

  @override
  String learnTipIntraGapTooLong(String ratio) {
    return 'Die Pausen innerhalb der Zeichen sind zu lang (etwa $ratio einer Punktlänge). Halte die Elemente eines Zeichens eng zusammen.';
  }

  @override
  String learnTipCharGapTooShort(String ratio) {
    return 'Die Zeichen laufen ineinander (Pausen etwa $ratio einer Punktlänge; Ziel ist 3). Lass nach jedem Zeichen eine deutliche Pause.';
  }

  @override
  String learnTipWordGapTooShort(String ratio) {
    return 'Die Wörter liegen zu dicht beieinander (Pausen etwa $ratio einer Punktlänge; Ziel ist 7). Halte eine lange Pause zwischen Wörtern.';
  }

  @override
  String learnTipSpeedUnsteady(int percent) {
    return 'Dein Tempo schwankt (Abweichung $percent %). Wähle ein Tempo und behalte es die ganze Zeile bei.';
  }

  @override
  String learnIssueDetailDitTooLong(int offending, int total, String ratio) {
    return '$offending von $total Punkten zu lang (Ø $ratio Punktlängen)';
  }

  @override
  String learnIssueDetailDahTooShort(int offending, int total, String ratio) {
    return '$offending von $total Strichen zu kurz (Ø $ratio Punktlängen)';
  }

  @override
  String learnIssueDetailIntraGapTooLong(int offending, int total, String ratio) {
    return '$offending von $total Pausen innerhalb der Zeichen zu lang (Ø $ratio Punktlängen)';
  }

  @override
  String learnIssueDetailCharGapTooShort(int offending, int total, String ratio) {
    return '$offending von $total Zeichenpausen zu kurz (Ø $ratio Punktlängen)';
  }

  @override
  String learnIssueDetailWordGapTooShort(int offending, int total, String ratio) {
    return '$offending von $total Wortpausen zu kurz (Ø $ratio Punktlängen)';
  }

  @override
  String learnIssueDetailSpeedUnsteady(String cv) {
    return 'Ungleichmäßiges Gebetempo (Variationskoeffizient $cv)';
  }

  @override
  String statsAccuracyDetail(String allTime) {
    return 'Letzte 7 Tage / $allTime insgesamt';
  }

  @override
  String statsDurationHoursMinutes(int hours, int minutes) {
    return '$hours Std. $minutes Min.';
  }

  @override
  String statsDurationMinutes(int minutes) {
    return '$minutes Min.';
  }

  @override
  String statsDurationSeconds(int seconds) {
    return '$seconds Sek.';
  }

  @override
  String get accountNewPasswordRequired => 'Gib ein neues Passwort ein';

  @override
  String get accountToxIdQrSemantics => 'QR-Code der Tox-ID';

  @override
  String get accountBackupSaveDialogTitle => 'DitMesh-Sicherung speichern';

  @override
  String get accountBackupShareSubject => 'DitMesh-Identitätssicherung';

  @override
  String get accountBackupChooseDialogTitle => 'DitMesh-Sicherung wählen';

  @override
  String notificationNewMessages(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count neue Nachrichten',
      one: '$count neue Nachricht',
    );
    return '$_temp0';
  }

  @override
  String notificationFriendRequestFrom(String name) {
    return 'Freundschaftsanfrage von $name';
  }

  @override
  String notificationFriendRequestBody(String name, String message) {
    return '$name: $message';
  }

  @override
  String notificationGroupInviteTitle(String group) {
    return 'Einladung zu $group';
  }

  @override
  String notificationGroupInviteBody(String name) {
    return '$name hat dich eingeladen';
  }

  @override
  String desktopTrayShow(String app) {
    return '$app anzeigen';
  }

  @override
  String desktopTrayHide(String app) {
    return '$app verbergen';
  }

  @override
  String get desktopTraySoundOn => 'Ton an';

  @override
  String get desktopTraySoundOff => 'Ton aus';

  @override
  String desktopTrayQuit(String app) {
    return '$app beenden';
  }

  @override
  String desktopTrayTooltipUnread(String app, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ungelesene Nachrichten',
      one: '$count ungelesene Nachricht',
    );
    return '$app — $_temp0';
  }

  @override
  String desktopWindowTitleUnread(String badge, String app) {
    return '($badge) $app';
  }

  @override
  String get listenStateOn => 'An';

  @override
  String get listenStateOff => 'Aus';

  @override
  String chatBytesLeftCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Bytes übrig',
      one: '$count Byte übrig',
    );
    return '$_temp0';
  }

  @override
  String chatMemberCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Mitglieder',
      one: '$count Mitglied',
    );
    return '$_temp0';
  }

  @override
  String chatFriendsCount(int count) {
    return 'Freunde ($count)';
  }

  @override
  String chatFriendRequestsCount(int count) {
    return 'Freundschaftsanfragen ($count)';
  }

  @override
  String chatGroupInvitesCount(int count) {
    return 'Gruppeneinladungen ($count)';
  }

  @override
  String chatMembersTitleCount(int count) {
    return 'Mitglieder · $count';
  }

  @override
  String chatInvitedByName(String name) {
    return 'Eingeladen von $name';
  }

  @override
  String chatMemberSelf(String name) {
    return '$name (Du)';
  }

  @override
  String chatSliderValue(String label, int value, String unit) {
    return '$label: $value $unit';
  }

  @override
  String referenceTelegraphCodes(String codes) {
    return 'Chinesischer Telegrafencode: $codes';
  }

  @override
  String get referenceTelegraphMainland => 'Festlandchina 1983';

  @override
  String get referenceTelegraphTaiwan => 'Taiwan / HK';

  @override
  String get referenceTelegraphNone => 'Nicht in diesem Codebuch';

  @override
  String get appearanceTitle => 'Darstellung';

  @override
  String get appearanceStyles => 'Oberflächenstil';

  @override
  String get appearanceChoose => 'Stil auswählen, Vorschau ansehen und anwenden';

  @override
  String get appearanceMode => 'Helligkeit';

  @override
  String get appearancePreview => 'Vorschau';

  @override
  String get appearanceApply => 'Stil anwenden';

  @override
  String get appearanceRestore => 'Standardwerte wiederherstellen';

  @override
  String get appearanceApplied => 'Darstellung gespeichert';

  @override
  String get appearanceSaveFailed => 'Darstellung konnte nicht gespeichert werden. Versuche es erneut.';

  @override
  String get appearanceClassic => 'Klassisches Messing';

  @override
  String get appearanceModern => 'Moderne Ruhe';

  @override
  String get appearanceRadio => 'Nachtradio';

  @override
  String get appearancePaper => 'Papierhandbuch';

  @override
  String get appearanceCartoon => 'Lebendiger Comic';

  @override
  String get appearanceLight => 'Hell';

  @override
  String get appearanceDark => 'Dunkel';

  @override
  String get appearanceSubtitle => 'Fünf Stile mit hellem und dunklem Modus';

  @override
  String get chatClearHistoryBody => 'Den Verlauf dieses Gesprächs auf diesem Gerät löschen? Kopien auf anderen Geräten sind nicht betroffen. Dies kann nicht rückgängig gemacht werden.';

  @override
  String get chatLoadEarlier => 'Ältere Nachrichten laden';

  @override
  String get chatHistoryLoadFailed => 'Ältere Nachrichten konnten nicht geladen werden. Tippe, um es erneut zu versuchen.';

  @override
  String get chatRetryHistory => 'Erneut versuchen';

  @override
  String chatNewMessages(int count) {
    return '$count neue Nachrichten';
  }

  @override
  String learnShowAllChars(int count) {
    return 'Alle $count Zeichen anzeigen';
  }

  @override
  String get chatSelfMe => 'Ich';

  @override
  String get chatSelfLocalOnly => 'Nur auf diesem Gerät gespeichert';

  @override
  String get chatSelfContactSubtitle => 'Entwürfe, Übungen und Notizen · werden nie gesendet';

  @override
  String get learnShowFewerChars => 'Weniger Zeichen anzeigen';

  @override
  String get learnLeaveDrillTitle => 'Diese Übung verlassen?';

  @override
  String get learnLeaveDrillBody => 'Die Runden dieser Übung werden nicht gespeichert.';

  @override
  String get learnLeaveDrillConfirm => 'Verlassen';

  @override
  String get chatScanQrPermissionDenied => 'DitMesh benötigt Kamerazugriff, um einen QR-Code zu scannen. Erlaube ihn in den Systemeinstellungen.';

  @override
  String get chatScanQrCameraUnavailable => 'Die Kamera ist auf diesem Gerät nicht verfügbar.';

  @override
  String get learnReplayAssistedNote => 'Wiederholt: Diese Übung zählt als Training, schaltet aber keine Lektion frei und ändert keine Wiederholungen.';

  @override
  String get learnPlanTitle => 'Plan für heute';

  @override
  String learnPlanSummary(int minutes, int done, int total) {
    return 'Etwa $minutes Min. · $done von $total Schritten';
  }

  @override
  String get learnPlanBudget => 'Planlänge';

  @override
  String learnPlanBudgetMinutes(int minutes) {
    return '$minutes Min.';
  }

  @override
  String get learnPlanStart => 'Plan starten';

  @override
  String get learnPlanContinue => 'Plan fortsetzen';

  @override
  String get learnPlanStepReview => 'Fällige Zeichen wiederholen';

  @override
  String get learnPlanStepFocus => 'Gezieltes Üben';

  @override
  String learnPlanStepCourse(int lesson) {
    return 'Lektion $lesson';
  }

  @override
  String get learnPlanStepSend => 'Gebeübung';

  @override
  String learnPlanReasonDueReview(String symbols) {
    return 'Zur Wiederholung fällig: $symbols';
  }

  @override
  String learnPlanReasonConfusions(String symbols) {
    return 'Oft verwechselt: $symbols';
  }

  @override
  String learnPlanReasonWeak(String symbols) {
    return 'Unter 90 %: $symbols';
  }

  @override
  String learnPlanReasonChallenge(int count) {
    return '$count Zeichen: kann die nächste Lektion freischalten';
  }

  @override
  String learnPlanReasonExtended(int count) {
    return 'Auf $count Zeichen verlängert, damit sie die nächste Lektion freischalten kann';
  }

  @override
  String get learnPlanReasonConsolidate => 'Kurze Übung: festigt diese Lektion, schaltet die nächste nicht frei';

  @override
  String learnPlanReasonOutdated(int lesson) {
    return 'Dein Kurs ist weiter: übt Lektion $lesson ohne Freischaltung';
  }

  @override
  String learnPlanReasonSend(int count) {
    return '$count kurze Ziele geben';
  }

  @override
  String learnPlanStepDonePercent(int percent) {
    return 'Erledigt · $percent %';
  }

  @override
  String get learnPlanStepDone => 'Erledigt';

  @override
  String learnPlanSendProgress(int done, int total) {
    return '$done von $total gegeben';
  }

  @override
  String get learnPlanStale => 'Lektion oder Tempo haben sich geändert. Noch nicht begonnene Schritte aktualisieren?';

  @override
  String get learnPlanUpdate => 'Schritte aktualisieren';

  @override
  String get learnPlanComplete => 'Plan für heute erledigt';

  @override
  String learnPlanNeedsWork(String symbols) {
    return 'Noch üben: $symbols';
  }

  @override
  String get learnPlanAllGood => 'Heute keine schwachen Zeichen.';

  @override
  String get learnPlanTomorrow => 'Morgen gibt es einen neuen Plan. Freies Üben ist jederzeit möglich.';

  @override
  String learnPlanNext(String step) {
    return 'Als Nächstes: $step';
  }

  @override
  String learnPlanEarlier(int done, int total) {
    return 'Der frühere Plan endete bei $done von $total Schritten und zählt heute nicht mehr.';
  }

  @override
  String learnSpeedAdviceRaise(int wpm) {
    return 'Bereit für $wpm WpM effektives Tempo';
  }

  @override
  String learnSpeedAdviceRaiseBoth(int wpm) {
    return 'Bereit für $wpm WpM';
  }

  @override
  String learnSpeedAdviceLower(int wpm) {
    return 'Das Mitschreiben fällt bei diesem Tempo schwer. Versuch $wpm WpM effektiv oder eine gezielte Übung.';
  }

  @override
  String learnSpeedAdviceBody(int count, int percent) {
    return 'Basierend auf deinen letzten $count Übungen ohne Hilfe ($percent %). Nichts ändert sich, bevor du es übernimmst.';
  }

  @override
  String get learnSpeedAdviceApply => 'Übernehmen';

  @override
  String get learnSpeedAdviceDismiss => 'Nicht jetzt';

  @override
  String get learnSpeedAdviceInsufficient => 'Für Tempo-Tipps braucht es 3 Übungen ohne Hilfe mit je 50+ Zeichen bei deinem aktuellen Tempo.';

  @override
  String get learnQsoAction => 'QSO-Simulator';

  @override
  String learnQsoLocked(int lesson) {
    return 'Ab Lektion $lesson';
  }

  @override
  String get learnQsoTitle => 'QSO-Simulator';

  @override
  String get learnQsoRespond => 'Auf CQ antworten';

  @override
  String get learnQsoRespondHint => 'Eine Station ruft CQ. Antworte und tauscht Rapporte aus.';

  @override
  String get learnQsoCall => 'CQ rufen';

  @override
  String get learnQsoCallHint => 'Du rufst CQ und eine Station antwortet.';

  @override
  String get learnQsoYourCall => 'Dein Rufzeichen';

  @override
  String get learnQsoYourName => 'Dein Name';

  @override
  String get learnQsoYourQth => 'Dein QTH';

  @override
  String get learnQsoInvalidCall => 'Gib ein Rufzeichen wie BD1XYZ ein';

  @override
  String get learnQsoInvalidWord => 'Ein Wort, nur Buchstaben A–Z';

  @override
  String get learnQsoOffline => 'Läuft komplett auf diesem Gerät. Es wird nichts gesendet.';

  @override
  String get learnQsoStart => 'QSO starten';

  @override
  String get learnQsoResume => 'Unterbrochenes QSO fortsetzen';

  @override
  String get learnQsoStageCallCq => 'Rufe CQ mit deinem Rufzeichen';

  @override
  String get learnQsoStageCallConfirm => 'Antworte: ihr Rufzeichen, DE, deins';

  @override
  String get learnQsoStageExchange => 'Rapport, Name und QTH senden';

  @override
  String get learnQsoStageConfirmInfo => 'Ihre Angaben bestätigen';

  @override
  String get learnQsoStageClosing => 'Mit 73 und <SK> beenden';

  @override
  String get learnQsoStageDone => 'QSO abgeschlossen';

  @override
  String learnQsoSpeed(int wpm) {
    return 'Gegenstation gibt mit $wpm WpM effektiv';
  }

  @override
  String learnQsoRemote(String call) {
    return '$call gibt';
  }

  @override
  String get learnQsoRemoteHidden => 'Nach Gehör mitschreiben – der Text ist verborgen.';

  @override
  String get learnQsoShowText => 'Text zeigen';

  @override
  String get learnQsoListen => 'Anhören';

  @override
  String get learnQsoAccepted => 'Angenommen';

  @override
  String get learnQsoRejected => 'Nicht angenommen';

  @override
  String get learnQsoRemoteSending => 'Die Gegenstation gibt …';

  @override
  String get learnQsoYourTurn => 'Du bist dran: gib deine Antwort und tippe auf Senden.';

  @override
  String get learnQsoDecoded => 'Deine Sendung';

  @override
  String get learnQsoNothingKeyed => 'Noch nichts gegeben';

  @override
  String get learnQsoPlayAgain => 'Wiederholung erbitten (AGN)';

  @override
  String get learnQsoSlower => 'Langsamer erbitten (QRS)';

  @override
  String get learnQsoHint => 'Tipp';

  @override
  String learnQsoHintLabel(String example) {
    return 'Beispiel: $example';
  }

  @override
  String get learnQsoPause => 'Pause';

  @override
  String get learnQsoSend => 'Senden';

  @override
  String get learnQsoClear => 'Löschen';

  @override
  String get learnQsoIssueEmpty => 'Es wurde nichts gegeben.';

  @override
  String get learnQsoIssueMissingCq => 'Beginne mit CQ.';

  @override
  String get learnQsoIssueMissingDe => 'Setze DE zwischen die Rufzeichen.';

  @override
  String get learnQsoIssueWrongLocalCall => 'Dein Rufzeichen fehlt oder ist falsch.';

  @override
  String get learnQsoIssueWrongRemoteCall => 'Das Rufzeichen der Gegenstation ist falsch.';

  @override
  String get learnQsoIssueReversedCalls => 'Rufzeichen vertauscht: zuerst ihres, dann DE und deins.';

  @override
  String get learnQsoIssueMissingEnding => 'Ende mit K oder KN.';

  @override
  String get learnQsoIssueMissingRst => 'Gib einen Rapport, z. B. UR RST 599.';

  @override
  String get learnQsoIssueInvalidRst => 'Dieser RST ist ungültig (R 1–5, S 1–9, T 1–9).';

  @override
  String get learnQsoIssueMissingName => 'Sende NAME und deinen Namen.';

  @override
  String get learnQsoIssueWrongName => 'Das ist nicht dein Name in diesem QSO.';

  @override
  String get learnQsoIssueMissingQth => 'Sende QTH und deinen Standort.';

  @override
  String get learnQsoIssueWrongQth => 'Das ist nicht dein QTH in diesem QSO.';

  @override
  String get learnQsoIssueMissingAck => 'Bestätige mit R oder QSL.';

  @override
  String get learnQsoIssueWrongRemoteName => 'Bestätige den Namen der Gegenstation.';

  @override
  String get learnQsoIssueMissing73 => '73 einfügen.';

  @override
  String get learnQsoIssueMissingSk => 'Beende die Verbindung mit <SK>.';

  @override
  String learnQsoSummaryFields(int count, int total) {
    return 'Beim ersten Mal richtig: $count von $total Schritten';
  }

  @override
  String learnQsoSummaryRepeats(int count) {
    return 'Wiederholungen: $count';
  }

  @override
  String learnQsoSummaryHints(int count) {
    return 'Tipps: $count';
  }

  @override
  String learnQsoSummaryRhythm(int wpm) {
    return 'Dein Geben: etwa $wpm WpM';
  }

  @override
  String get learnQsoSummaryNote => 'QSO-Ergebnisse zählen getrennt von der Mitschreib-Genauigkeit und schalten keine Lektionen frei.';

  @override
  String get messageStatusCancelled => 'Abgebrochen – nie gesendet';

  @override
  String get chatMessageLearnActions => 'Nachrichtenaktionen';

  @override
  String get chatPracticeMessage => 'Diese Nachricht mitschreiben';

  @override
  String get chatSaveAsMaterial => 'Als Übungsmaterial speichern';

  @override
  String get chatSavedAsMaterial => 'In „Meine Materialien“ gespeichert';

  @override
  String get chatSaveMaterialFailed => 'Material konnte nicht gespeichert werden. Versuch es erneut.';

  @override
  String get chatListenOnly => 'Nur-Hören-Training';

  @override
  String get chatListenOnlyHidden => 'Nur Hören: zum Anhören abspielen';

  @override
  String chatClearHistoryMaterials(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Nachrichten aus diesem Chat wurden als Übungsmaterial gespeichert. Die Kopien bleiben, bis du sie unter Lernen › Meine Materialien löschst.',
      one: '1 Nachricht aus diesem Chat wurde als Übungsmaterial gespeichert. Die Kopie bleibt, bis du sie unter Lernen › Meine Materialien löschst.',
    );
    return '$_temp0';
  }

  @override
  String get chatPracticeTitle => 'Mitschreib-Übung';

  @override
  String chatPracticeUnsupported(String chars) {
    return 'Diese Nachricht enthält Zeichen ohne Morsecode: $chars. Sie werden ausgelassen.';
  }

  @override
  String chatPracticeTrainableCount(int count) {
    return '$count Zeichen können geübt werden.';
  }

  @override
  String get chatPracticeNothingTrainable => 'Nichts in dieser Nachricht lässt sich morsen.';

  @override
  String get chatPracticeConfirm => 'Den Rest üben';

  @override
  String get chatPracticeHint => 'Tipp';

  @override
  String chatPracticeHintShown(String symbols) {
    return 'Tipp: $symbols …';
  }

  @override
  String get chatPracticeAssisted => 'Mit Hilfe: zählt als Übung, nicht für Wiederholungen oder Tempo-Tipps.';

  @override
  String chatPracticeErrors(int wrong, int missed, int extra) {
    return '$wrong falsch · $missed fehlend · $extra zu viel';
  }

  @override
  String chatPracticeErrorsAction(String symbols) {
    return 'Fehler üben: $symbols';
  }

  @override
  String get learnTipDahTooLongTitle => 'Striche zu lang';

  @override
  String learnTipDahTooLong(String ratio) {
    return 'Deine Striche sind zu lang (etwa $ratio eines Punkts; Ziel 3). Lass nach drei Punktlängen los.';
  }

  @override
  String learnIssueDetailDahTooLong(int offending, int total, String ratio) {
    return '$offending von $total Strichen zu lang (Ø $ratio Punkt)';
  }

  @override
  String get learnRhythmTitle => 'Rhythmus';

  @override
  String get learnRhythmMine => 'Mein Rhythmus';

  @override
  String get learnRhythmStandard => 'Standardrhythmus (Zieltempo)';

  @override
  String learnRhythmNormalizedNote(int ms) {
    return 'Probleme werden an deiner eigenen Punktlänge ($ms ms) gemessen; gleichmäßig, aber langsam ist in Ordnung. Die Standardspur zeigt das Zieltempo.';
  }

  @override
  String get learnRhythmNotLocated => 'Deine Zeichen ließen sich nicht einzelnen Buchstaben zuordnen. Übe stattdessen das ganze Ziel.';

  @override
  String get learnRhythmPlayMine => 'Meins abspielen';

  @override
  String get learnRhythmPlayStandard => 'Standard abspielen';

  @override
  String learnRhythmPracticePart(int count) {
    return 'Das üben ($count Versuche)';
  }

  @override
  String get learnRhythmPracticeWhole => 'Ganzes Ziel üben';

  @override
  String get learnRhythmSymbolOk => 'Sieht gut aus';

  @override
  String get learnRhythmZoomIn => 'Vergrößern';

  @override
  String get learnRhythmZoomOut => 'Verkleinern';

  @override
  String get chatSearchMessages => 'Nachrichten suchen';

  @override
  String get chatSearchHint => 'Diesen Chat durchsuchen';

  @override
  String get chatSearchAnyone => 'Alle';

  @override
  String get chatSearchMe => 'Ich';

  @override
  String get chatSearchThem => 'Gegenüber';

  @override
  String get chatSearchAnyDate => 'Beliebiges Datum';

  @override
  String chatSearchDateRange(String from, String to) {
    return '$from – $to';
  }

  @override
  String get chatSearchBookmarked => 'Gemerkt';

  @override
  String get chatSearchNoResults => 'Keine passenden Nachrichten.';

  @override
  String get chatSearchMore => 'Mehr laden';

  @override
  String get chatAddBookmark => 'Merken';

  @override
  String get chatRemoveBookmark => 'Nicht mehr merken';

  @override
  String get chatBookmarked => 'Gemerkt';

  @override
  String get chatBookmarkFailed => 'Lesezeichen konnte nicht gespeichert werden.';

  @override
  String get chatRetrySend => 'Erneut senden';

  @override
  String get chatCancelSend => 'Senden abbrechen';

  @override
  String get chatRetryQueued => 'Erneut eingereiht. Wird gesendet, sobald der Kontakt online ist.';

  @override
  String get chatSendCancelled => 'Abgebrochen. Die Nachricht wurde nicht gesendet.';

  @override
  String get chatRetryNotNeeded => 'Diese Nachricht ist nicht mehr fehlgeschlagen.';

  @override
  String get chatCancelTooLate => 'Zu spät: Die Nachricht ist bereits unterwegs und kommt eventuell an.';

  @override
  String get chatSendControlUnavailable => 'Für diese Nachricht nicht verfügbar.';

  @override
  String get chatSendControlFailed => 'Das hat nicht geklappt. Die Nachricht behält ihren Zustand; versuch es erneut.';

  @override
  String get workbenchTitle => 'Aufnahme-Werkbank';

  @override
  String get workbenchOpen => 'Aufnahmen';

  @override
  String get workbenchImport => 'Aufnahme importieren';

  @override
  String get workbenchEmpty => 'Importiere eine WAV-Aufnahme, um sie zu wiederholen, zu dekodieren und mitzuschreiben. Kein Mikrofon nötig.';

  @override
  String get workbenchFormats => 'WAV, 16-Bit-PCM, Mono oder Stereo, 8/16/44,1/48 kHz; bis 50 MB und 20 Minuten.';

  @override
  String get workbenchBackupNote => 'Aufnahmen bleiben auf diesem Gerät und sind nur dann im Identitäts-Backup, wenn du sie beim Exportieren einschließt. Titel, Notizen und Positionen gespeicherter Ausschnitte werden immer gesichert.';

  @override
  String workbenchInfo(String rate, String channels, String duration) {
    return '$rate kHz · $channels · $duration';
  }

  @override
  String get workbenchMono => 'Mono';

  @override
  String get workbenchStereo => 'Stereo';

  @override
  String get workbenchTruncated => 'Die Datei endet vorzeitig; nur das vorhandene Audio wird verwendet.';

  @override
  String get workbenchErrorNotWav => 'Das ist keine WAV-Datei.';

  @override
  String get workbenchErrorFormat => 'Derzeit wird nur 16-Bit-PCM-WAV unterstützt (kein MP3, AAC oder Float-WAV).';

  @override
  String get workbenchErrorChannels => 'Nur Mono- oder Stereoaufnahmen werden unterstützt.';

  @override
  String get workbenchErrorRate => 'Abtastrate nicht unterstützt. Verwende 8, 16, 44,1 oder 48 kHz.';

  @override
  String get workbenchErrorDamaged => 'Die Datei ist beschädigt oder unvollständig.';

  @override
  String get workbenchErrorTooLarge => 'Die Datei ist größer als 50 MB.';

  @override
  String get workbenchErrorTooLong => 'Die Aufnahme ist länger als 20 Minuten.';

  @override
  String get workbenchErrorIo => 'Die Datei konnte nicht gelesen werden.';

  @override
  String get workbenchErrorMissing => 'Die Aufnahmedatei fehlt.';

  @override
  String get workbenchStart => 'Start (s)';

  @override
  String get workbenchEnd => 'Ende (s)';

  @override
  String get workbenchSelectAll => 'Alles auswählen';

  @override
  String get workbenchPlay => 'Auswahl abspielen';

  @override
  String get workbenchStop => 'Stopp';

  @override
  String get workbenchLoop => 'Schleife';

  @override
  String get workbenchPlayLimit => 'Von längeren Auswahlen werden nur die ersten 5 Minuten abgespielt.';

  @override
  String get workbenchAutoTune => 'Ton automatisch finden';

  @override
  String workbenchManualTone(int hz) {
    return 'Ton: $hz Hz';
  }

  @override
  String get workbenchDecode => 'Auswahl dekodieren';

  @override
  String get workbenchCancel => 'Abbrechen';

  @override
  String workbenchDecoding(int percent) {
    return 'Dekodiere … $percent %';
  }

  @override
  String workbenchResultStats(int hz, int wpm) {
    return 'Ton $hz Hz · etwa $wpm WpM';
  }

  @override
  String get workbenchToneNotLocked => 'Kein stabiler Ton gefunden; versuch die manuelle Abstimmung.';

  @override
  String get workbenchNoText => 'In dieser Auswahl wurde nichts dekodiert.';

  @override
  String workbenchUnknown(String patterns) {
    return 'Unbekannte Muster: $patterns';
  }

  @override
  String get workbenchEdgeCut => 'Ein Zeichen am Rand der Auswahl ist abgeschnitten und kann falsch sein.';

  @override
  String get workbenchToneNote => 'Die Tonerkennung ist kein Vertrauenswert; prüfe den Text mit dem Ohr.';

  @override
  String get workbenchModeDecoder => 'Decoder';

  @override
  String get workbenchModeCopy => 'Selbst mitschreiben';

  @override
  String get workbenchDecoderHidden => 'Der Decodertext ist beim Mitschreiben verborgen.';

  @override
  String get workbenchShowDecoder => 'Decodertext zeigen';

  @override
  String get workbenchReference => 'Referenztext (optional)';

  @override
  String get workbenchReferenceHelp => 'Füge den gesendeten Text ein; sonst wird mit der Decoderausgabe verglichen.';

  @override
  String get workbenchAgainstDecoder => 'Mit der Decoderausgabe verglichen, die selbst falsch sein kann.';

  @override
  String get workbenchSave => 'Auswahl speichern';

  @override
  String get workbenchSaveTitle => 'Titel';

  @override
  String get workbenchSaveNote => 'Notiz';

  @override
  String get workbenchSaved => 'Auswahl gespeichert';

  @override
  String get workbenchSaveFailed => 'Auswahl konnte nicht gespeichert werden.';

  @override
  String get workbenchLibrary => 'Gespeicherte Auswahlen';

  @override
  String get workbenchLibraryEmpty => 'Noch keine gespeicherten Auswahlen.';

  @override
  String get workbenchMissing => 'Aufnahmedatei fehlt – wähle sie erneut oder lösche den Eintrag.';

  @override
  String get workbenchRelink => 'Datei erneut wählen';

  @override
  String get workbenchDelete => 'Löschen';

  @override
  String get materialsTitle => 'Meine Materialien';

  @override
  String get materialsNew => 'Neues Material';

  @override
  String get materialsEdit => 'Bearbeiten';

  @override
  String get materialsSave => 'Speichern';

  @override
  String get materialsSaveFailed => 'Material konnte nicht gespeichert werden.';

  @override
  String get materialsTitleField => 'Titel';

  @override
  String get materialsTagsField => 'Schlagwörter (durch Komma getrennt)';

  @override
  String get materialsTextField => 'Text';

  @override
  String get materialsListField => 'Ein Eintrag pro Zeile';

  @override
  String get materialsKindText => 'Text';

  @override
  String get materialsKindWords => 'Wortliste';

  @override
  String get materialsKindCallsigns => 'Rufzeichen';

  @override
  String get materialsPreview => 'Vorschau';

  @override
  String materialsPreviewCounts(int items, int symbols, int prosigns) {
    return '$items Einträge · $symbols Zeichen · $prosigns Betriebszeichen';
  }

  @override
  String materialsPreviewUnsupported(String chars) {
    return 'Ohne Morsecode, beim Üben ausgelassen: $chars';
  }

  @override
  String materialsPreviewDuplicates(int count) {
    return '$count doppelte Einträge werden einmal behalten';
  }

  @override
  String get materialsProblemEmpty => 'Gib zuerst Text ein.';

  @override
  String get materialsProblemTooLarge => 'Zu groß: Materialien sind auf 1 MiB begrenzt.';

  @override
  String materialsProblemTooManyEntries(int count) {
    return 'Zu viele Einträge: höchstens $count.';
  }

  @override
  String materialsProblemEntryTooLong(int count) {
    return 'Ein Eintrag ist zu lang: höchstens $count Zeichen.';
  }

  @override
  String get materialsProblemNothingTrainable => 'Hier lässt sich nichts morsen.';

  @override
  String get materialsSearch => 'Materialien durchsuchen';

  @override
  String get materialsFavoritesOnly => 'Favoriten';

  @override
  String get materialsFavorite => 'Zu Favoriten';

  @override
  String get materialsUnfavorite => 'Aus Favoriten entfernen';

  @override
  String get materialsEmpty => 'Noch keine Materialien. Füge eigene Texte, Wortlisten oder Rufzeichen hinzu oder speichere eine Chatnachricht.';

  @override
  String materialsItems(int count) {
    return '$count Einträge';
  }

  @override
  String get materialsFromChat => 'Aus dem Chat';

  @override
  String get materialsActions => 'Aktionen';

  @override
  String get materialsPractise => 'Üben';

  @override
  String get materialsDelete => 'Löschen';

  @override
  String get materialsDeleteTitle => 'Material löschen?';

  @override
  String materialsDeleteBody(String title) {
    return '„$title“ wird von diesem Gerät entfernt. Dein Übungsverlauf bleibt.';
  }

  @override
  String get materialsImport => 'TXT oder JSON importieren';

  @override
  String get materialsImportDialogTitle => 'Materialdatei wählen';

  @override
  String get materialsSaveDialogTitle => 'Material speichern';

  @override
  String get materialsImportFailed => 'Import fehlgeschlagen. Deine Bibliothek ist unverändert.';

  @override
  String get materialsImportNotUtf8 => 'Nur UTF-8-Textdateien können importiert werden.';

  @override
  String get materialsImportInvalid => 'Keine gültige DitMesh-Materialdatei. Nichts importiert.';

  @override
  String materialsImported(int count) {
    return '$count Materialien importiert.';
  }

  @override
  String get materialsDuplicateTitle => 'Einige Materialien gibt es schon';

  @override
  String get materialsDuplicateOverwrite => 'Ersetzen';

  @override
  String get materialsDuplicateKeepCopy => 'Beide behalten (als Kopie)';

  @override
  String get materialsDuplicateSkip => 'Überspringen';

  @override
  String get materialsExportJson => 'Als JSON exportieren';

  @override
  String materialsExported(int count) {
    return '$count Materialien exportiert.';
  }

  @override
  String get materialsExportFailed => 'Export fehlgeschlagen.';

  @override
  String get materialsExportWav => 'Audio exportieren (WAV)';

  @override
  String materialsWavCharSpeed(int wpm) {
    return 'Zeichentempo: $wpm WpM';
  }

  @override
  String materialsWavEffSpeed(int wpm) {
    return 'Effektives Tempo: $wpm WpM';
  }

  @override
  String materialsWavTone(int hz) {
    return 'Ton: $hz Hz';
  }

  @override
  String get materialsWavWithAnswer => 'Lösungstext beilegen (.txt)';

  @override
  String get materialsWavFormat => '16-Bit-Mono-WAV, 48 kHz.';

  @override
  String materialsWavParts(int count) {
    return 'Länger als 10 Minuten: wird als $count Dateien exportiert.';
  }

  @override
  String materialsWavExported(int count) {
    return '$count Audiodateien gespeichert.';
  }

  @override
  String get materialsPracticeMode => 'Üben mit';

  @override
  String get materialsPracticeLearned => 'Nur gelernte Zeichen';

  @override
  String materialsPracticeLearnedPartial(int count) {
    return 'Nur gelernte Zeichen ($count Einträge nicht verfügbar: noch nicht gelernte Zeichen)';
  }

  @override
  String get materialsPracticeAll => 'Alle Morsezeichen';

  @override
  String get materialsPracticeNothing => 'In diesem Modus lässt sich kein Eintrag üben.';

  @override
  String get guestTryLearning => 'Erst einmal lernen';

  @override
  String get guestBanner => 'Gastmodus: Fortschritt bleibt auf diesem Gerät. Chat braucht eine Identität.';

  @override
  String get guestGetIdentity => 'Identität einrichten';

  @override
  String get guestIdentityTitle => 'Identität erforderlich';

  @override
  String get guestIdentityBody => 'Chatten über Tox braucht deine eigene Identität. Erstelle eine neue, stelle ein Backup wieder her oder entsperre die auf diesem Gerät. Dein Gast-Lernfortschritt zieht automatisch in eine neue Identität um.';

  @override
  String get guestClearData => 'Gast-Lerndaten löschen';

  @override
  String get guestClearDataBody => 'Löscht Fortschritt, Pläne und Materialien aus dem Gastmodus auf diesem Gerät. Identitäten bleiben unberührt.';

  @override
  String get guestClearConfirm => 'Löschen';

  @override
  String get guestCleared => 'Gast-Lerndaten gelöscht.';

  @override
  String get guestClearFailed => 'Gastdaten konnten nicht gelöscht werden.';

  @override
  String get guestMigrationFailed => 'Deine Identität ist bereit, aber dein Gast-Lernfortschritt ist noch nicht umgezogen. Er ist sicher auf diesem Gerät.';

  @override
  String get guestChoiceBody => 'Du hast auch Gast-Lernfortschritt. Verwendet wird der Fortschritt der wiederhergestellten Identität; nichts wurde zusammengeführt.';

  @override
  String get guestChoiceKeep => 'Wiederhergestellten behalten';

  @override
  String get guestChoiceUseGuest => 'Gastfortschritt verwenden';

  @override
  String get placementTitle => 'Mein Niveau prüfen';

  @override
  String get placementCheckLevel => 'Mein aktuelles Niveau prüfen';

  @override
  String get placementFromZero => 'Bei null anfangen';

  @override
  String get placementOfferTitle => 'Neu bei Morse oder schon geübt?';

  @override
  String get placementOfferBody => 'Ein kurzer Test kann einen Startpunkt vorschlagen. Er ist freiwillig und ändert nichts, bis du dich entscheidest.';

  @override
  String get placementIntro => 'Etwa 3–5 Minuten Mitschreiben in fünf Stufen: Koch-Zeichen in Gruppen mit steigendem Tempo, dann kurze Wörter. Eine grobe Orientierung aus wenigen Proben, kein Zertifikat. Jederzeit abbrechbar.';

  @override
  String get placementStart => 'Starten';

  @override
  String get placementSkip => 'Überspringen';

  @override
  String get placementStop => 'Beenden';

  @override
  String placementTierProgress(int step, int total, int wpm) {
    return 'Stufe $step von $total · $wpm WpM effektiv';
  }

  @override
  String get placementTierPassed => 'Gut mitgeschrieben. Die nächste Stufe ist schneller.';

  @override
  String get placementTierStopped => 'Diese Stufe lag unter 90 %, der Test endet hier.';

  @override
  String get placementNextTier => 'Nächste Stufe';

  @override
  String placementSuggestion(int lesson) {
    return 'Vorgeschlagener Start: Lektion $lesson';
  }

  @override
  String placementVerified(int count, int total) {
    return '$count von $total Koch-Zeichen der Reihe nach bestätigt.';
  }

  @override
  String get placementLimits => 'Auf Basis einer kleinen Probe: nicht geprüfte Zeichen bleiben ungeprüft, nichts wird als gelernt markiert. Die Lektion lässt sich jederzeit ändern.';

  @override
  String placementAdopt(int lesson) {
    return 'Mit Lektion $lesson beginnen';
  }

  @override
  String get chatJumpToLatest => 'Neueste Nachrichten';

  @override
  String get chatMessageGone => 'Diese Nachricht ist nicht mehr in diesem Chat.';

  @override
  String get chatListenOnlyPreview => 'Neue Nachricht – zum Mitschreiben anhören';

  @override
  String get chatSaveMaterialConfirm => 'Den Rest speichern';

  @override
  String materialsImportConfirm(int count) {
    return '$count Materialien importieren?';
  }

  @override
  String get materialsExportTxt => 'Als Text exportieren (TXT)';

  @override
  String get accountBackupMediaTitle => 'Gespeicherte Aufnahmen einschließen?';

  @override
  String accountBackupMediaBody(int count, String size) {
    return '$count gespeicherte Aufnahmen ($size MB). Titel, Notizen und Positionen sind immer im Backup, der Ton nur, wenn du ihn einschließt.';
  }

  @override
  String accountBackupMediaTooLarge(String size) {
    return 'Gespeicherte Aufnahmen ($size MB) sind zu groß für ein Backup; nur Titel, Notizen und Positionen werden gesichert.';
  }

  @override
  String get accountBackupMediaInclude => 'Aufnahmen einschließen';

  @override
  String get accountBackupMediaSkip => 'Ohne Aufnahmen';

  @override
  String get diagTitle => 'Verbindungsdiagnose';

  @override
  String get diagOpenSubtitle => 'Warum Nachrichten warten und wie du neu verbindest';

  @override
  String get diagBannerDetails => 'Details';

  @override
  String get diagSummaryNoIdentity => 'Es ist keine Identität geöffnet, daher gibt es keine Verbindung zu prüfen.';

  @override
  String get diagSummaryOnlinePeerOnline => 'Du bist mit dem Tox-Netzwerk verbunden und dieser Kontakt ist online. Nachrichten gehen direkt an ihn.';

  @override
  String get diagSummaryOnlinePeerOffline => 'Du bist verbunden, aber dieser Kontakt ist offline. Nachrichten warten im Postausgang dieses Geräts und werden gesendet, sobald der Kontakt online ist.';

  @override
  String get diagSummaryOnline => 'Du bist mit dem Tox-Netzwerk verbunden.';

  @override
  String get diagSummaryConnecting => 'Verbindung zum Tox-Netzwerk wird hergestellt. Nach dem Start oder einem Netzwechsel kann das eine Minute dauern.';

  @override
  String get diagSummaryOffline => 'Du bist nicht mit dem Tox-Netzwerk verbunden. Bis die Verbindung zurück ist, kann nichts gesendet oder empfangen werden.';

  @override
  String get diagLocalLabel => 'Deine Verbindung';

  @override
  String diagSinceChanged(String time) {
    return 'Seit $time';
  }

  @override
  String diagSinceFirst(String time) {
    return 'Beobachtet seit $time';
  }

  @override
  String diagSinceResumed(String time) {
    return 'Beobachtet seit der Rückkehr in die App um $time';
  }

  @override
  String get diagLastOnlineLabel => 'Zuletzt beobachtete Verbindung';

  @override
  String get diagLastOnlineNow => 'Gerade verbunden';

  @override
  String get diagLastOnlineNone => 'Noch keine Verbindung beobachtet.';

  @override
  String get diagLastOnlineHint => 'Wann dieses Gerät zuletzt selbst verbunden war. Nicht, wann eine Nachricht jemanden erreicht hat.';

  @override
  String get diagPeerLabel => 'Kontakt';

  @override
  String get diagUnknown => 'Unbekannt';

  @override
  String get diagPeerUnknownHint => 'Ob ein Kontakt online ist, lässt sich nur sehen, während du verbunden bist.';

  @override
  String get diagPeerGroupHint => 'Ob Gruppenmitglieder online sind, zeigt die Mitgliederliste.';

  @override
  String get diagPendingLabel => 'Wartet auf Versand';

  @override
  String get diagPendingNone => 'Nichts in Warteschlange';

  @override
  String diagPendingCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Nachrichten',
      one: '1 Nachricht',
    );
    return '$_temp0';
  }

  @override
  String diagPendingOldest(String time) {
    return 'Älteste eingereiht $time';
  }

  @override
  String get diagPendingUnknown => 'Unbekannt, bis der Chat verbunden ist';

  @override
  String get diagPendingHint => 'Wartende Nachrichten bleiben auf diesem Gerät und werden automatisch gesendet, sobald der Kontakt erreichbar ist. Die Diagnose verwirft oder wiederholt sie nie.';

  @override
  String get diagReconnect => 'Neu verbinden';

  @override
  String get diagReconnecting => 'Verbinde neu …';

  @override
  String diagReconnectFailed(String reason) {
    return 'Neu verbinden fehlgeschlagen: $reason';
  }

  @override
  String get diagReconnectNote => 'Neu verbinden startet den Verbindungsversuch neu. Bis du online bist, kann es trotzdem dauern; diese Seite aktualisiert sich dann.';

  @override
  String get diagAboutTitle => 'Wie sich DitMesh verbindet';

  @override
  String get diagAboutBody => 'DitMesh hat keinen Server. Dein Gerät spricht über das Tox-Peer-to-Peer-Netzwerk direkt mit deinen Kontakten; damit eine Nachricht ankommt, müsst ihr beide gleichzeitig online sein. Smartphones pausieren Apps im Hintergrund: Dort kann DitMesh nicht verbunden bleiben und verbindet sich neu, wenn du zurückkehrst.';

  @override
  String get diagDetailsTitle => 'Technische Details';

  @override
  String get diagDetailIdentity => 'Identität';

  @override
  String get diagDetailStatus => 'Status';

  @override
  String get diagDetailObserved => 'Beobachtet um';

  @override
  String get diagDetailQueued => 'Einträge in der Warteschlange';

  @override
  String get diagDetailError => 'Letzter Fehlercode';

  @override
  String get backupXTitle => 'Verschlüsselte Sicherung';

  @override
  String get backupXIntro => 'Wähle aus, was du auf ein anderes Gerät mitnehmen willst. Die ganze Datei wird mit einer Passphrase verschlüsselt, die du hier festlegst.';

  @override
  String get backupXCategoryIdentity => 'Identität und Tox-Profil';

  @override
  String get backupXCategoryTraining => 'Trainingsfortschritt und Materialien';

  @override
  String get backupXCategoryChat => 'Chatverlauf, einschließlich Notizen an mich';

  @override
  String get backupXCategoryMeta => 'Entwürfe, Anheftungen und Lesezeichen';

  @override
  String get backupXCategoryPrefs => 'App-Einstellungen';

  @override
  String get backupXPrefsHint => 'Wiedergabe, Benachrichtigungen, Darstellung und Sprache. Nie Fensterpositionen oder Tastenbelegungen.';

  @override
  String get backupXCategoryMedia => 'Gespeicherte Aufnahmen';

  @override
  String get backupXMediaHint => 'Standardmäßig aus: Aufnahmen können groß sein. Ohne sie kommen nur Titel und Notizen mit.';

  @override
  String get backupXCategoryPending => 'Nicht gesendete Nachrichten';

  @override
  String get backupXPendingHint => 'Sie kommen nur zur Durchsicht zurück und werden nie automatisch gesendet.';

  @override
  String get backupXRequired => 'Erforderlich';

  @override
  String backupXSizeLine(int count, String size) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Elemente',
      one: '1 Element',
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
    return 'Zu groß zum Einschließen ($size)';
  }

  @override
  String backupXInvitesNote(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Gruppeneinladungen, die auf Offline-Kontakte warten, werden nicht übernommen.',
      one: '1 Gruppeneinladung, die auf einen Offline-Kontakt wartet, wird nicht übernommen.',
    );
    return '$_temp0';
  }

  @override
  String get backupXIdentityPasswordNote => 'Dein Identitätspasswort bleibt am Profil: Das neue Gerät fragt danach und nach der Sicherungs-Passphrase.';

  @override
  String backupXTotal(String size) {
    return 'Insgesamt etwa $size';
  }

  @override
  String get backupXPassphrase => 'Sicherungs-Passphrase';

  @override
  String get backupXPassphraseConfirm => 'Passphrase wiederholen';

  @override
  String get backupXPassphraseHint => 'Mindestens 8 Zeichen. Sie ist unabhängig von deinem Identitätspasswort und lässt sich nicht wiederherstellen.';

  @override
  String get backupXPassphraseTooShort => 'Mindestens 8 Zeichen verwenden';

  @override
  String get backupXPassphraseMismatch => 'Die Passphrasen stimmen nicht überein';

  @override
  String get backupXExport => 'Verschlüsselte Sicherung erstellen';

  @override
  String get backupXExporting => 'Sicherung wird erstellt …';

  @override
  String get backupXMigrationNote => 'Wechselst du das Gerät? Nach der Wiederherstellung dort diese Identität hier nicht mehr verwenden: Zwei Geräte mit einer Identität können dieselbe Nachricht doppelt senden.';

  @override
  String get backupXBusy => 'Deine Daten haben sich während der Sicherung ständig geändert. Versuche es erneut.';

  @override
  String get backupXTooLarge => 'Die Sicherung ist zu groß. Lass Aufnahmen weg und versuche es erneut.';

  @override
  String get restoreXWrongPassphrase => 'Falsche Passphrase, oder die Datei wurde verändert bzw. ist unvollständig.';

  @override
  String get restoreXUnsupported => 'Diese Sicherung stammt von einer neueren DitMesh-Version.';

  @override
  String get restoreXCheck => 'Sicherung öffnen';

  @override
  String get restoreXPreviewTitle => 'Inhalt der Sicherung';

  @override
  String restoreXCreated(String date) {
    return 'Erstellt $date';
  }

  @override
  String get restoreXIncluded => 'Enthalten';

  @override
  String get restoreXExcluded => 'Nicht in dieser Sicherung';

  @override
  String restoreXPendingIncluded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count nicht gesendete Nachrichten kommen zur Durchsicht zurück. Sie werden nicht automatisch gesendet.',
      one: '1 nicht gesendete Nachricht kommt zur Durchsicht zurück. Sie wird nicht automatisch gesendet.',
    );
    return '$_temp0';
  }

  @override
  String restoreXPendingExcluded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count nicht gesendete Nachrichten des alten Geräts sind nicht in dieser Sicherung.',
      one: '1 nicht gesendete Nachricht des alten Geräts ist nicht in dieser Sicherung.',
    );
    return '$_temp0';
  }

  @override
  String get restoreXIdentityPassword => 'Identitätspasswort';

  @override
  String get restoreXIdentityPasswordNote => 'Die Identität in dieser Sicherung hat ein eigenes Passwort. Gib es ebenfalls ein.';

  @override
  String get restoreXConfirmTitle => 'Identität auf diesem Gerät ersetzen?';

  @override
  String get restoreXConfirmBody => 'Eine Identität und Daten auf diesem Gerät werden durch die Sicherung ersetzt. Verwende die Identität auf dem alten Gerät nicht mehr, bevor du dich hier verbindest.';

  @override
  String get restoreXConfirm => 'Ersetzen und wiederherstellen';

  @override
  String get restoreXReportTitle => 'Wiederherstellung abgeschlossen';

  @override
  String get restoreXReportRestored => 'Wiederhergestellt';

  @override
  String get restoreXReportNotIncluded => 'Nicht wiederhergestellt';

  @override
  String get restoreXReportPrefsFailed => 'Einstellungen konnten nicht übernommen werden; deine bisherigen bleiben erhalten.';

  @override
  String restoreXReportPendingReview(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count nicht gesendete Nachrichten warten im Chat auf deine Durchsicht.',
      one: '1 nicht gesendete Nachricht wartet im Chat auf deine Durchsicht.',
    );
    return '$_temp0';
  }

  @override
  String restoreXReportPendingNotResumed(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count nicht gesendete Nachrichten vom alten Gerät wurden nicht übernommen.',
      one: '1 nicht gesendete Nachricht vom alten Gerät wurde nicht übernommen.',
    );
    return '$_temp0';
  }

  @override
  String restoreXReportInvites(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count wartende Gruppeneinladungen wurden nicht erneut gesendet.',
      one: '1 wartende Gruppeneinladung wurde nicht erneut gesendet.',
    );
    return '$_temp0';
  }

  @override
  String get restoreXReportStopOld => 'Verwende diese Identität auf dem alten Gerät nicht mehr.';

  @override
  String get restoreXReportDone => 'Fertig';

  @override
  String pendingReviewBanner(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count nicht gesendete Nachrichten vom vorherigen Gerät',
      one: '1 nicht gesendete Nachricht vom vorherigen Gerät',
    );
    return '$_temp0';
  }

  @override
  String get pendingReviewTitle => 'Nicht gesendete Nachrichten';

  @override
  String get pendingReviewBody => 'Diese warteten auf deinem vorherigen Gerät auf den Versand. DitMesh sendet sie nie automatisch; taste eine erneut, wenn sie noch wichtig ist.';

  @override
  String pendingReviewQueuedAt(String time) {
    return 'Eingereiht $time auf dem vorherigen Gerät';
  }

  @override
  String get pendingReviewDismiss => 'Verwerfen';

  @override
  String get pendingReviewDismissAll => 'Alle verwerfen';

  @override
  String get pendingReviewEmpty => 'Nichts mehr zu prüfen.';

  @override
  String get backupXWizardInside => 'Die Sicherungsdatei wird vollständig mit einer selbst gewählten Passphrase verschlüsselt und enthält deinen Identitätsschlüssel und deinen Trainingsfortschritt. Bewahre Datei und Passphrase sicher und außerhalb dieses Geräts auf.';

  @override
  String get backupXMeSubtitle => 'Eine verschlüsselte Datei mit Identität, Chats und Fortschritt – zum Aufbewahren oder für ein anderes Gerät';

  @override
  String get conditionsTitle => 'Bedingungen';

  @override
  String get conditionsClear => 'Klar';

  @override
  String get conditionsLight => 'Leichte Störungen';

  @override
  String get conditionsRadio => 'Funkpraxis';

  @override
  String get conditionsClearHint => 'Ein sauberer, gleichmäßiger Ton: normales Training.';

  @override
  String get conditionsLightHint => 'Leises Rauschen und sanftes Fading. Ergebnisse bleiben getrennt vom klaren Training.';

  @override
  String get conditionsRadioHint => 'Rauschen, tiefes Fading, eine Nachbarstation und leicht ungleichmäßiges Timing. Ergebnisse bleiben getrennt vom klaren Training.';

  @override
  String get conditionsPreview => 'Probe hören';

  @override
  String conditionsActive(String name) {
    return 'Bedingungen: $name';
  }

  @override
  String get conditionsNeedSound => 'Funkbedingungen hört man, man sieht sie nicht: Schalte den Ton in den Trainingseinstellungen ein oder übe mit klaren Bedingungen.';

  @override
  String get conditionsCleanReplay => 'Ohne Effekte abspielen';

  @override
  String conditionsComparable(int count, int accuracy) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Versuche unter diesen Bedingungen bei diesem Tempo: im Schnitt $accuracy %',
      one: '1 Versuch unter diesen Bedingungen bei diesem Tempo: $accuracy %',
    );
    return '$_temp0';
  }

  @override
  String get conditionsSeparateNote => 'Training unter Funkbedingungen zählt als Aktivität, ändert aber weder Lektionen noch Wiederholungsplan oder Tempo-Empfehlung.';

  @override
  String get keysTitle => 'Tasten und externe Keyer';

  @override
  String get keysMeSubtitle => 'Tastenbelegung, Paddles und USB-Keyer-Adapter';

  @override
  String get keysIntro => 'Wähle, welche Tasten Morse geben. USB-Adapter für Tasten und Paddles, die eine Tastatur nachbilden, verhalten sich wie eine Tastatur: Lege ihre Tasten hier fest. Die App erkennt nicht, welches Gerät eine Taste gesendet hat; ein Profil ist daher eine Tastenbelegung.';

  @override
  String get keysStandardProfile => 'Standard';

  @override
  String get keysUnnamed => 'Unbenanntes Profil';

  @override
  String get keysEdit => 'Bearbeiten';

  @override
  String get keysNewProfile => 'Neues Profil';

  @override
  String get keysLimitations => 'MIDI-, serielle und Bluetooth-Keyer, Adapter-Firmware-Einstellungen und Sendersteuerung werden nicht unterstützt. Getestete Adapter stehen in der Dokumentation.';

  @override
  String get keysEditTitle => 'Tastenprofil';

  @override
  String get keysName => 'Profilname';

  @override
  String get keysActionStraight => 'Handtaste';

  @override
  String get keysActionDit => 'Punkt-Paddle';

  @override
  String get keysActionDah => 'Strich-Paddle';

  @override
  String get keysPressKey => 'Taste drücken …';

  @override
  String get keysNone => 'Nicht festgelegt';

  @override
  String get keysSet => 'Festlegen';

  @override
  String keysReserved(String key) {
    return '$key ist vom System oder der App reserviert; wähle eine andere Taste.';
  }

  @override
  String keysConflict(String key, String action) {
    return '$key wird bereits für $action verwendet.';
  }

  @override
  String keysConflictSave(String keys) {
    return 'Jede Taste darf nur eine Aufgabe haben: $keys ist doppelt belegt.';
  }

  @override
  String get keysMissing => 'Lege die Tasten fest, die dieser Keyer-Modus braucht (beide Paddles bei Iambic).';

  @override
  String get keysSwapPaddles => 'Paddles tauschen (Linkshänder)';

  @override
  String get keysKeyerMode => 'Keyer-Modus';

  @override
  String get keysIambicA => 'Iambic A';

  @override
  String get keysIambicB => 'Iambic B';

  @override
  String get keysAdapterKeyer => 'Der Adapter erzeugt die Zeichen selbst';

  @override
  String get keysAdapterKeyerHint => 'Für Adapter mit eigenem Keyer: Seine getakteten Tastendrücke werden unverändert verwendet, ohne zweiten Iambic-Keyer in der App.';

  @override
  String get keysAppSidetone => 'App-Mithörton beim Geben';

  @override
  String get keysAppSidetoneHint => 'Ausschalten, wenn der Adapter selbst einen Mithörton erzeugt. Die Dekodierung bleibt unberührt.';

  @override
  String get keysTestTitle => 'Test';

  @override
  String get keysTestNote => 'Nur zum Testen: Nichts wird gesendet oder dem Training angerechnet.';

  @override
  String get keysTestRelease => 'Tasten lösen';

  @override
  String get keysAdapterActive => 'Der Keyer des Adapters wird verwendet: Paddle-Tasten wirken wie eine Handtaste.';

  @override
  String keysHintCustom(String keys) {
    return 'Tasten: $keys';
  }

  @override
  String get telegraphTitle => 'Chinesischer Telegrafencode';

  @override
  String get telegraphIntro => 'Jedes chinesische Zeichen wird als vierstelliger Code gesendet. Übe das Hören der Ziffern und, getrennt davon, welcher Code für welches Zeichen steht.';

  @override
  String get telegraphCodebook => 'Codebuch';

  @override
  String get telegraphCodebookMainland => 'Festland';

  @override
  String get telegraphCodebookTaiwan => 'Taiwan';

  @override
  String get telegraphDigitsTitle => 'Codegruppen mitschreiben';

  @override
  String get telegraphDigitsHint => 'Höre vierstellige Gruppen echter Codes und tippe die Ziffern.';

  @override
  String telegraphDigitsResults(int count, int accuracy) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Durchgänge: $accuracy % der Ziffern',
      one: '1 Durchgang: $accuracy % der Ziffern',
    );
    return '$_temp0';
  }

  @override
  String get telegraphRecallTitle => 'Codes abrufen';

  @override
  String get telegraphRecallHint => 'Zeichen zu Code und Code zu Zeichen. Getrennt vom Morse-Fortschritt.';

  @override
  String telegraphRecallResults(int count, int accuracy) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Karten beantwortet: $accuracy % gewusst',
      one: '1 Karte beantwortet: $accuracy % gewusst',
    );
    return '$_temp0';
  }

  @override
  String get telegraphSeparateNote => 'Code-Abruf schaltet nie Morse-Lektionen frei und ändert keine Tempo-Empfehlung; Ziffern-Mitschreiben zählt wie anderes Morse-Mitschreiben.';

  @override
  String get telegraphRecallCharPrompt => 'Tippe den Code dieses Zeichens';

  @override
  String get telegraphRecallCodePrompt => 'Wähle das Zeichen zu diesem Code';

  @override
  String get telegraphReveal => 'Lösung zeigen';

  @override
  String get telegraphRevealAssisted => 'Angezeigt: Diese Karte zählt als unterstützt.';

  @override
  String get telegraphCorrect => 'Richtig';

  @override
  String get telegraphIncorrect => 'Nicht ganz';

  @override
  String telegraphRecallSummary(int correct, int total) {
    return '$correct von $total gewusst';
  }

  @override
  String telegraphRecallAssisted(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Karten mit angezeigter Lösung',
      one: '1 Karte mit angezeigter Lösung',
    );
    return '$_temp0';
  }

  @override
  String get telegraphInterpretAction => 'Als chinesischen Telegrafencode deuten';

  @override
  String get telegraphInterpretTitle => 'Deutung als Telegrafencode';

  @override
  String get telegraphInterpretNote => 'Nur hier angezeigt: Die Nachricht selbst bleibt unverändert und nichts wird gesendet.';

  @override
  String get telegraphUnresolved => 'Ungeklärt: Kein Zeichen hat diesen Code';

  @override
  String get telegraphMalformed => 'Keine vierstellige Gruppe';

  @override
  String get telegraphNotCode => 'Text, unverändert';

  @override
  String get telegraphAmbiguous => 'Mehrere Zeichen teilen sich diesen Code';

  @override
  String get groupPracticeTitle => 'Gruppentraining';

  @override
  String get groupPracticeIntro => 'Die Kursleitung gibt Übungen wie gewohnt im Gruppenchat. Jedes Mitglied wählt hier eine Übungsnachricht und schreibt sie im eigenen Tempo mit. Antworten und Ergebnisse bleiben auf deinem Gerät; nichts wird an die Gruppe gesendet.';

  @override
  String get groupPracticeNew => 'Neue Sitzung';

  @override
  String get groupPracticeTitleField => 'Titel';

  @override
  String get groupPracticeCreate => 'Erstellen';

  @override
  String get groupPracticeInstructor => 'Kursleitung';

  @override
  String get groupPracticeParticipant => 'Teilnehmer';

  @override
  String get groupPracticeInstructorHint => 'Gib jede Übung im Gruppenchat, füge sie hier als Runde hinzu und hake sie ab; kündige Durchgänge im Chat an.';

  @override
  String get groupPracticeParticipantHint => 'Füge die Übungsnachrichten der Kursleitung als Runden hinzu und schreibe jede hier mit.';

  @override
  String get groupPracticeLocalNote => 'Nur lokal: Runden, Rollen und Ergebnisse werden nicht mit anderen abgeglichen, und verpasste Nachrichten erreichen nicht unbedingt alle.';

  @override
  String get groupPracticeAddRound => 'Übung hinzufügen';

  @override
  String get groupPracticeNoMessages => 'Keine passenden Nachrichten im jüngsten Verlauf.';

  @override
  String get groupPracticeNotConnected => 'Der Gruppenverlauf ist erst verfügbar, wenn der Chat verbunden ist.';

  @override
  String get groupPracticeRoundOpen => 'Offen';

  @override
  String get groupPracticeRoundDone => 'Erledigt';

  @override
  String get groupPracticeRoundUnavailable => 'Nicht verfügbar';

  @override
  String get groupPracticeSourceGone => 'Die Übungsnachricht ist nicht mehr im Verlauf.';

  @override
  String get groupPracticeSourceLoading => 'Nachricht wird gesucht …';

  @override
  String groupPracticeAttemptResult(int accuracy, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Mitgeschrieben: $accuracy % ($count Versuche)',
      one: 'Mitgeschrieben: $accuracy %',
    );
    return '$_temp0';
  }

  @override
  String get groupPracticeCopy => 'Mitschreiben';

  @override
  String get groupPracticeRemoveRound => 'Runde entfernen';

  @override
  String get groupPracticeSummary => 'Übersicht';

  @override
  String groupPracticeRoundsDone(int done, int total) {
    return '$done von $total Runden erledigt';
  }

  @override
  String groupPracticeUnavailableCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Runden nicht verfügbar',
      one: '1 Runde nicht verfügbar',
    );
    return '$_temp0';
  }

  @override
  String groupPracticeAccuracy(int accuracy) {
    return 'Mitschreib-Genauigkeit: $accuracy %';
  }

  @override
  String groupPracticeAssisted(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Versuche mit Hilfe',
      one: '1 Versuch mit Hilfe',
    );
    return '$_temp0';
  }

  @override
  String groupPracticeShareHint(int done, int total, int accuracy) {
    return 'Zum Teilen gib dein Ergebnis selbst im Gruppenchat, z. B. $done/$total $accuracy%. Nichts wird automatisch gesendet.';
  }

  @override
  String get groupPracticeComplete => 'Sitzung beenden';

  @override
  String get groupPracticeDeleteTitle => 'Diese Sitzung löschen?';

  @override
  String get groupPracticeDeleteBody => 'Runden und lokale Ergebnisse werden von diesem Gerät entfernt. Dein Trainingsverlauf und die Gruppennachrichten bleiben.';

  @override
  String get conditionsAudioFailed => 'Der Ton ließ sich auf diesem Gerät nicht starten. Übe stattdessen mit klaren Bedingungen.';

  @override
  String get moderationBlock => 'Blockieren';

  @override
  String moderationBlockTitle(String name) {
    return '$name blockieren?';
  }

  @override
  String get moderationBlockFriendBody => 'Die Person wird aus deinen Freunden entfernt und eure Unterhaltung gelöscht. Ihre Nachrichten, Freundschaftsanfragen und Gruppeneinladungen erscheinen auf diesem Gerät nicht mehr. Sie wird nicht benachrichtigt.';

  @override
  String get moderationBlockMemberBody => 'Ihre Nachrichten in dieser Gruppe erscheinen auf diesem Gerät nicht mehr. Sie wird nicht benachrichtigt. Tox gibt jedem Mitglied in jeder Gruppe einen eigenen Schlüssel, daher gilt das nur für diese Gruppe.';

  @override
  String get moderationBlocked => 'Blockiert';

  @override
  String get moderationUnblock => 'Freigeben';

  @override
  String get moderationUnblocked => 'Freigegeben';

  @override
  String get moderationBlockedTitle => 'Blockierte Personen';

  @override
  String get moderationBlockedSubtitle => 'Ihre Nachrichten, Anfragen und Einladungen sind ausgeblendet';

  @override
  String get moderationBlockedEmpty => 'Du hast niemanden blockiert.';

  @override
  String get moderationBlockedNote => 'Blockieren wirkt auf diesem Gerät: Tox hat keinen zentralen Server, blockierte Personen können es also weiter versuchen, aber hier wird nichts von ihnen angezeigt.';

  @override
  String get termsGateTitle => 'Community-Richtlinien';

  @override
  String get termsGateIntro => 'Der DitMesh-Chat verbindet dich ohne Server direkt mit anderen. Bitte stimme vorher diesen Regeln zu:';

  @override
  String get termsGateRuleZero => 'Null Toleranz: keine Belästigung, kein Hass, keine Drohungen, keine sexuellen Inhalte mit Minderjährigen, kein Spam, nichts Illegales.';

  @override
  String get termsGateRuleContacts => 'Nur Personen, die du annimmst, können dir schreiben; Gruppen betrittst du per Einladung oder Gruppen-ID.';

  @override
  String get termsGateRuleBlock => 'Blockiere jede Person aus einer Unterhaltung, der Mitgliederliste einer Gruppe, einer Freundschaftsanfrage oder einer Einladung.';

  @override
  String get termsGateAgree => 'Zustimmen und weiter';

  @override
  String get termsGateReadFull => 'Vollständige Nutzungsbedingungen lesen';

  @override
  String get termsGateSaveFailed => 'Deine Antwort konnte nicht gespeichert werden. Versuche es erneut.';

  @override
  String get aboutPrivacyPolicy => 'Datenschutzerklärung';

  @override
  String get aboutTermsOfUse => 'Nutzungsbedingungen';

  @override
  String get aboutSupport => 'Hilfe und Kontakt';

  @override
  String get aboutLinkFailed => 'Der Link ließ sich nicht öffnen und wurde kopiert.';

  @override
  String get errorPeerBlocked => 'Du hast diese Person blockiert. Gib sie zuerst unter Ich → Blockierte Personen frei.';

  @override
  String get offlineClearData => 'Lerndaten löschen';

  @override
  String get offlineClearDataBody => 'Löscht deinen Fortschritt, deine Pläne und Materialien auf diesem Gerät.';

  @override
  String get offlineCleared => 'Lerndaten gelöscht.';

  @override
  String get offlineClearFailed => 'Die Lerndaten konnten nicht gelöscht werden.';

  @override
  String get learnStorageUnavailable => 'Deine Trainingsdaten ließen sich auf diesem Gerät nicht öffnen. Versuche es erneut.';

  @override
  String get backendStartupFailedTitle => 'Chat-Backend nicht verfügbar';

  @override
  String get backendStartupFailedBody => 'DitMesh konnte das Tox-Netzwerk-Backend nicht starten. Prüfe, ob die nativen Bibliotheken installiert sind, und versuche es erneut.';

  @override
  String get bootstrapTitle => 'Netzwerk und Bootstrap';

  @override
  String get bootstrapDescription => 'Wähle die öffentlichen Knoten für den Zugang zum Tox-Netzwerk.';

  @override
  String get bootstrapModeAuto => 'Automatisch';

  @override
  String get bootstrapModeManual => 'Manuell';

  @override
  String get bootstrapModeLan => 'LAN-Host';

  @override
  String get bootstrapAutoDescription => 'Mit integrierten Knoten starten und die offizielle Liste im Hintergrund aktualisieren.';

  @override
  String get bootstrapManualDescription => 'Nur den gewählten Knoten verwenden. Hier kannst du auch einen LAN-Knoten eingeben.';

  @override
  String get bootstrapLanDescription => 'Auf diesem Desktop einen lokalen UDP/DHT-Knoten für andere LAN-Geräte betreiben.';

  @override
  String get bootstrapCurrentNode => 'Aktueller Knoten';

  @override
  String get bootstrapHost => 'Host oder IP-Adresse';

  @override
  String get bootstrapPort => 'UDP-Port';

  @override
  String get bootstrapPublicKey => 'Öffentlicher DHT-Schlüssel';

  @override
  String get bootstrapTestNode => 'Knoten testen';

  @override
  String get bootstrapSaveNode => 'Getesteten Knoten verwenden';

  @override
  String get bootstrapChooseNode => 'Öffentlichen Knoten wählen';

  @override
  String get bootstrapReachable => 'DHT-Antwort empfangen';

  @override
  String get bootstrapUnreachable => 'Keine DHT-Antwort';

  @override
  String get bootstrapInvalid => 'Host, Port oder öffentlicher Schlüssel ungültig';

  @override
  String get bootstrapUdpUnavailable => 'Dieses Gerät konnte keine UDP-Prüfung ausführen. TCP wurde nicht getestet.';

  @override
  String get bootstrapProbeUnavailable => 'Die Prüfung konnte nicht starten. Die Erreichbarkeit des Knotens ist unbekannt.';

  @override
  String get bootstrapFallback => 'Die offizielle Liste konnte nicht geladen werden. Integrierte Ersatzknoten werden angezeigt.';

  @override
  String get bootstrapMaintainer => 'Betreiber';

  @override
  String get bootstrapLocation => 'Standort';

  @override
  String get bootstrapLastPing => 'Letzte öffentliche Prüfung';

  @override
  String get bootstrapSwitchTitle => 'Bootstrap-Knoten wechseln';

  @override
  String get bootstrapSwitchQuestion => 'Diesen Knoten verwenden?';

  @override
  String get bootstrapNotTestedWarning => 'Dieser Knoten wurde auf deinem Gerät noch nicht getestet.';

  @override
  String get bootstrapFailedWarning => 'Dieser Knoten hat auf die UDP-Prüfung nicht geantwortet. Er kann dennoch gewählt werden.';

  @override
  String get bootstrapInconclusiveWarning => 'Die Prüfung war nicht eindeutig. TCP wurde nicht getestet.';

  @override
  String get bootstrapSwitchConfirm => 'Knoten verwenden';

  @override
  String get bootstrapRefresh => 'Liste aktualisieren';

  @override
  String get bootstrapStartLan => 'LAN-Knoten starten';

  @override
  String get bootstrapStopLan => 'LAN-Knoten stoppen';

  @override
  String get bootstrapLanStopped => 'LAN-Knoten gestoppt';

  @override
  String get bootstrapLanRunning => 'LAN-Knoten läuft';

  @override
  String get bootstrapLanKeyChanges => 'Der DHT-Schlüssel ändert sich beim Neustart. Teile den aktuellen vollständigen Schlüssel.';

  @override
  String get bootstrapLanFirewallHint => 'Andere Geräte müssen diesen UDP-Port durch die lokale Firewall erreichen können.';

  @override
  String get bootstrapCopyNode => 'Knotendaten kopieren';

  @override
  String get bootstrapShareNode => 'Knotendaten teilen';

  @override
  String get bootstrapOperationFailed => 'Die Netzwerkeinstellung konnte nicht angewendet werden.';

  @override
  String get bootstrapServiceUnavailable => 'Für dieses Backend sind keine Netzwerkeinstellungen verfügbar.';

  @override
  String get bootstrapSource => 'Offizielle öffentliche Knotenliste';

  @override
  String get bootstrapOnline => 'Online';

  @override
  String get bootstrapOffline => 'Offline';

  @override
  String bootstrapProtocolStatus(String udp, String tcp) {
    return 'UDP: $udp · TCP: $tcp';
  }

  @override
  String get errorNotFriend => 'Diese Person ist nicht mehr in deiner Freundesliste. Füge sie erneut hinzu, um Nachrichten zu senden.';

  @override
  String get chatAcceptWithPassword => 'Mit Passwort annehmen';

  @override
  String chatGroupPasswordTitle(String name) {
    return 'Passwort für $name';
  }

  @override
  String get chatGroupPasswordField => 'Gruppenpasswort';

  @override
  String chatGroupJoinRefusedPassword(String name) {
    return '$name hat den Beitritt abgelehnt: Das Passwort ist falsch oder fehlt.';
  }

  @override
  String chatGroupJoinRefusedFull(String name) {
    return '$name hat den Beitritt abgelehnt: Die Gruppe ist voll.';
  }

  @override
  String chatGroupJoinRefused(String name) {
    return '$name hat den Beitritt abgelehnt.';
  }

  @override
  String chatGroupReconnectRefused(String name) {
    return '$name hat die erneute Verbindung abgelehnt. Der Verlauf bleibt erhalten; versuche es mit dem Gruppenpasswort erneut.';
  }
}
