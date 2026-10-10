// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 's.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class SFr extends S {
  SFr([String locale = 'fr']) : super(locale);

  @override
  String get appName => 'DitMesh';

  @override
  String get navLearn => 'Apprendre';

  @override
  String get navChat => 'Discussion';

  @override
  String get navGroups => 'Groupes';

  @override
  String get navMe => 'Moi';

  @override
  String get navReference => 'Référence';

  @override
  String get navChatDescription => 'Conversations en Morse à deux via Tox P2P, sans serveur.';

  @override
  String get navGroupsDescription => 'Réseaux de groupe : plusieurs opérateurs transmettent sur un canal commun.';

  @override
  String get navReferenceDescription => 'Alphabet, signaux de procédure, codes Q, abréviations et traduction dans les deux sens.';

  @override
  String get navMeDescription => 'Votre indicatif, votre identité Tox, votre progression et vos réglages.';

  @override
  String get shellOfflineBanner => 'Hors ligne : aucune connexion au réseau Tox. Les messages seront envoyés dès votre retour en ligne.';

  @override
  String get actionOk => 'OK';

  @override
  String get actionCancel => 'Annuler';

  @override
  String get actionSave => 'Enregistrer';

  @override
  String get actionDelete => 'Supprimer';

  @override
  String get actionCopy => 'Copier';

  @override
  String get actionShare => 'Partager';

  @override
  String get actionRetry => 'Réessayer';

  @override
  String get actionClose => 'Fermer';

  @override
  String get actionSearch => 'Rechercher';

  @override
  String get actionSettings => 'Réglages';

  @override
  String get connectionConnecting => 'Connexion…';

  @override
  String get connectionOnline => 'En ligne';

  @override
  String get connectionOffline => 'Hors ligne';

  @override
  String get messageStatusPending => 'En attente sur cet appareil';

  @override
  String get messageStatusPendingDetail => 'Le message est enregistré localement. Il sera envoyé lorsque les deux applications fonctionneront et pourront se connecter.';

  @override
  String get messageStatusSending => 'Envoi en cours';

  @override
  String get messageStatusSent => 'Envoyé';

  @override
  String get messageStatusFailed => 'Échec de l’envoi';

  @override
  String get errorWrongPassword => 'Mot de passe incorrect. Réessayez.';

  @override
  String get errorPeerOffline => 'Ce contact est hors ligne. Tox n’a pas de serveur ; le message attendra son retour.';

  @override
  String get errorInvalidToxId => 'Cet identifiant Tox n’est pas valide (76 caractères hexadécimaux).';

  @override
  String get errorAlreadyFriend => 'Cet identifiant Tox figure déjà dans votre liste d’amis.';

  @override
  String get errorOwnId => 'Il s’agit de votre propre identifiant Tox.';

  @override
  String get errorGroupNotFound => 'Groupe introuvable.';

  @override
  String get errorMessageTooLong => 'Le texte est trop long pour un seul message Tox.';

  @override
  String get errorUnknown => 'Une erreur est survenue';

  @override
  String get errorTeardownUnconfirmed => 'La session Tox précédente ne s’est pas encore complètement arrêtée. Réessayez dans un instant ou redémarrez l’application.';

  @override
  String get errorIdentityRecoveryPending => 'Une identité précédente attend encore d’être récupérée. Redémarrez l’application pour réessayer, ou supprimez les données d’identité pour repartir de zéro.';

  @override
  String get languageTitle => 'Langue';

  @override
  String get languageSystemDefault => 'Langue du système';

  @override
  String get languageSaveFailed => 'Impossible d’enregistrer la langue. Réessayez.';

  @override
  String learnLessonOf(int lesson, int total) {
    return 'Leçon $lesson sur $total';
  }

  @override
  String learnRoundScore(int correct, int total) {
    return '$correct bonnes réponses sur $total';
  }

  @override
  String learnRoundOf(int round) {
    return 'Série $round';
  }

  @override
  String learnAccuracyPercent(int percent) {
    return '$percent %';
  }

  @override
  String learnCharsSent(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count caractères envoyés',
      one: '$count caractère envoyé',
    );
    return '$_temp0';
  }

  @override
  String learnLessonUnlocked(String char) {
    return 'Caractère suivant débloqué : $char';
  }

  @override
  String learnConfusedMissed(String target) {
    return '$target manqué';
  }

  @override
  String learnConfusedAs(String target, String answered) {
    return '$target entendu comme $answered';
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
      other: '$count caractères',
      one: '$count caractère',
    );
    return '$_temp0';
  }

  @override
  String statsDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count jours',
      one: '$count jour',
    );
    return '$_temp0';
  }

  @override
  String statsTrendSubtitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Dernières $count séances',
      one: 'Dernière séance',
      zero: 'Aucune séance',
    );
    return '$_temp0';
  }

  @override
  String referenceEntryCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count entrées',
      one: '$count entrée',
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
    return 'Ignorés (sans code Morse) : $chars';
  }

  @override
  String referenceKochPositionValue(int position) {
    return 'Position dans la méthode Koch : $position';
  }

  @override
  String referenceEstimatedSpeed(String wpm) {
    return 'Estimation : $wpm WPM';
  }

  @override
  String get accountCopied => 'Identifiant Tox copié dans le presse-papiers';

  @override
  String get accountShowQr => 'Afficher le code QR';

  @override
  String get accountToxId => 'Identifiant Tox';

  @override
  String get accountDisplayName => 'Nom affiché';

  @override
  String get accountDisplayNameHint => 'Votre indicatif ou surnom';

  @override
  String get accountDisplayNameRequired => 'Saisissez un nom à afficher';

  @override
  String get accountStatusMessage => 'Message de statut';

  @override
  String get accountPassword => 'Mot de passe';

  @override
  String get accountPasswordOptional => 'Mot de passe (facultatif)';

  @override
  String get accountConfirmPassword => 'Confirmer le mot de passe';

  @override
  String get accountPasswordsDoNotMatch => 'Les mots de passe ne correspondent pas';

  @override
  String get accountShowPassword => 'Afficher le mot de passe';

  @override
  String get accountHidePassword => 'Masquer le mot de passe';

  @override
  String get accountStrengthWeak => 'Faible : utilisez au moins 8 caractères';

  @override
  String get accountStrengthFair => 'Moyen : préférez au moins 12 caractères de types différents';

  @override
  String get accountStrengthStrong => 'Fort';

  @override
  String get accountStartupInspecting => 'Vérification de votre identité…';

  @override
  String get accountStartupOpening => 'Ouverture de votre identité…';

  @override
  String get accountStartupFailedTitle => 'Démarrage impossible';

  @override
  String get accountStartupFailedBody => 'DitMesh n’a pas pu lire votre identité. Rien n’a été modifié ; vous pouvez réessayer.';

  @override
  String get accountConnectionTapToReconnect => 'Touchez pour vous reconnecter';

  @override
  String get accountWelcomeTitle => 'Votre identité réside sur cet appareil';

  @override
  String get accountWelcomeIntro => 'DitMesh utilise le réseau pair à pair Tox. Il n’y a ni serveur ni compte à créer : votre identité est une paire de clés stockée uniquement ici.';

  @override
  String get accountWelcomePointNoServer => 'Aucun serveur, numéro de téléphone ni adresse e-mail. Les contacts communiquent directement entre eux, en Morse.';

  @override
  String get accountWelcomePointTraining => 'Discutez en tête-à-tête ou en groupe en code Morse, avec une pioche ou des palettes iambiques.';

  @override
  String get accountWelcomePointBackup => 'Personne ne peut récupérer votre identité à votre place. Sauvegardez-la dès sa création pour ne pas la perdre avec l’appareil.';

  @override
  String get accountCreateIdentity => 'Créer une identité';

  @override
  String get accountRestoreFromBackup => 'Restaurer une sauvegarde';

  @override
  String get accountCreateTitle => 'Créer votre identité';

  @override
  String get accountCreateBody => 'Choisissez un nom que les autres verront. Un mot de passe chiffre le fichier d’identité sur cet appareil ; laissez le champ vide si vous préférez ouvrir l’application sans mot de passe.';

  @override
  String get accountCreateButton => 'Créer';

  @override
  String get accountCreating => 'Création…';

  @override
  String get accountBackupTitle => 'Sauvegardez votre identité maintenant';

  @override
  String get accountBackupBody => 'Votre identité existe uniquement sur cet appareil. S’il est perdu, réinitialisé ou volé, elle sera irrécupérable : vos contacts ne reconnaîtront pas une nouvelle identité et votre progression sera perdue.';

  @override
  String get accountBackupWhatIsInside => 'Le fichier de sauvegarde contient votre clé d\'identité, chiffrée avec votre mot de passe, et votre progression. Conservez-le en lieu sûr, ailleurs que sur cet appareil.';

  @override
  String get accountBackupWhatIsInsidePlain => 'Le fichier de sauvegarde contient votre clé d\'identité non chiffrée et votre progression. Quiconque obtient ce fichier peut utiliser votre identité : définissez d\'abord un mot de passe si vous voulez chiffrer la clé, et conservez le fichier en lieu sûr.';

  @override
  String get accountPasswordScope => 'Votre mot de passe chiffre votre clé d\'identité. L\'historique des messages reste non chiffré sur le disque ; le chiffrement de l\'appareil peut le protéger.';

  @override
  String get accountSectionNotifications => 'Notifications';

  @override
  String get accountNotificationsEnable => 'Afficher les notifications';

  @override
  String get accountNotificationsEnableSubtitle => 'Nouveaux messages, demandes d\'ami et invitations de groupe';

  @override
  String get accountNotificationsContent => 'Afficher le contenu des messages';

  @override
  String get accountNotificationsContentSubtitle => 'Texte et Morse dans les bannières et sur l\'écran verrouillé. Désactivé : seulement l\'arrivée d\'un message.';

  @override
  String get accountNotificationsAllow => 'Autoriser les notifications';

  @override
  String get accountNotificationsAllowSubtitle => 'Demander l\'autorisation au système';

  @override
  String get accountNotificationsBlocked => 'Bloquées dans les réglages système';

  @override
  String get accountNotificationsBlockedSubtitle => 'Les notifications de messages de DitMesh sont désactivées dans les réglages système. Réactivez-les à cet endroit.';

  @override
  String get accountNotificationsDenied => 'Les notifications de DitMesh sont désactivées dans les réglages du système.';

  @override
  String get accountBackupSaveFile => 'Enregistrer le fichier de sauvegarde';

  @override
  String get accountBackupShareFile => 'Partager le fichier de sauvegarde';

  @override
  String get accountBackupSaved => 'Sauvegarde enregistrée';

  @override
  String get accountBackupNotSaved => 'La sauvegarde n’a pas été enregistrée';

  @override
  String get accountBackupFailed => 'Impossible d’écrire la sauvegarde';

  @override
  String get accountBackupAcknowledge => 'Je comprends que sans cette sauvegarde, mon identité sera irrécupérable.';

  @override
  String get accountBackupContinue => 'Continuer vers DitMesh';

  @override
  String get accountBackupShowQrHint => 'Vos amis vous ajoutent grâce à votre identifiant Tox. Partagez-le sous forme de texte ou de code QR.';

  @override
  String get accountRestoreTitle => 'Restaurer une sauvegarde';

  @override
  String get accountRestoreBody => 'Choisissez un fichier de sauvegarde exporté depuis DitMesh. Si l’identité était protégée par un mot de passe, vous devrez le saisir ici.';

  @override
  String get accountRestoreChooseFile => 'Choisir un fichier de sauvegarde';

  @override
  String get accountRestoreNoFile => 'Choisissez d’abord un fichier de sauvegarde';

  @override
  String get accountRestoreButton => 'Restaurer';

  @override
  String get accountRestoring => 'Restauration…';

  @override
  String get accountRestoreInvalidFile => 'Ce fichier n’est pas une sauvegarde DitMesh.';

  @override
  String get accountRestoreReplacesWarning => 'La restauration remplace l’identité actuellement sur cet appareil.';

  @override
  String get accountUnlockTitle => 'Déverrouiller votre identité';

  @override
  String get accountUnlockBody => 'Votre fichier d’identité est chiffré. Saisissez le mot de passe pour continuer.';

  @override
  String get accountUnlockButton => 'Déverrouiller';

  @override
  String get accountUnlocking => 'Déverrouillage…';

  @override
  String get accountUnlockRestoreInstead => 'Restaurer plutôt une sauvegarde';

  @override
  String get accountMeNoIdentity => 'Aucune identité chargée';

  @override
  String get accountSectionAccount => 'Compte';

  @override
  String get accountSectionTraining => 'Entraînement';

  @override
  String get accountSectionAbout => 'À propos';

  @override
  String get meNoteBackgroundTitle => 'Réception sur téléphone';

  @override
  String get meNoteBackgroundBody => 'DitMesh est pair-à-pair et n\'a pas de serveur de notifications push : gardez l\'app ouverte pour recevoir des messages. En arrière-plan, votre téléphone met vite DitMesh en pause ; les messages qu\'on vous envoie alors peuvent déjà apparaître comme envoyés chez votre contact et arrivent quand vous rouvrez DitMesh.';

  @override
  String get meNoteScreenReaderTitle => 'Lecteurs d\'écran et manipulation';

  @override
  String get meNoteScreenReaderBody => 'Avec un lecteur d\'écran, impossible de manipuler à la pioche en la tenant plus ou moins longtemps. Dans une discussion, utilisez plutôt les actions POINT et TRAIT de la touche, activez une palette une fois par élément ou manipulez avec un clavier physique.';

  @override
  String get accountSectionDanger => 'Zone de danger';

  @override
  String get accountEditProfile => 'Modifier le profil';

  @override
  String get accountEditProfileBody => 'Visible par vos contacts sur le réseau Tox.';

  @override
  String get accountSetPassword => 'Définir un mot de passe';

  @override
  String get accountChangePassword => 'Changer le mot de passe';

  @override
  String get accountRemovePassword => 'Supprimer le mot de passe';

  @override
  String get accountCurrentPassword => 'Mot de passe actuel';

  @override
  String get accountNewPassword => 'Nouveau mot de passe';

  @override
  String get accountPasswordUpdated => 'Mot de passe mis à jour';

  @override
  String get accountPasswordRemoved => 'Mot de passe supprimé';

  @override
  String get accountProfileUpdated => 'Profil mis à jour';

  @override
  String get accountExportBackup => 'Exporter une sauvegarde';

  @override
  String get accountExportBackupSubtitle => 'Enregistrer votre identité et votre progression dans un fichier';

  @override
  String get accountTrainingDefaults => 'Réglages de lecture et d’entraînement par défaut';

  @override
  String get accountTrainingDefaultsSubtitle => 'Vitesse, tonalité et espacement Farnsworth';

  @override
  String get accountTrainingDefaultsPlaceholder => 'Les réglages de vitesse, de tonalité et de Farnsworth par défaut seront disponibles ici.';

  @override
  String get accountAboutLicence => 'Licence';

  @override
  String get accountAboutLicenceValue => 'GPL-3.0';

  @override
  String get accountAboutSource => 'Code source';

  @override
  String get accountAboutSourceCopied => 'Lien du code source copié';

  @override
  String get accountAboutBackend => 'Moteur';

  @override
  String get accountDeleteIdentity => 'Supprimer l’identité';

  @override
  String get accountDeleteIdentitySubtitle => 'Effacer cette identité, l’historique et la progression de cet appareil';

  @override
  String get accountDeleteDialogTitle => 'Supprimer cette identité ?';

  @override
  String get accountDeleteDialogBody => 'Votre identité, votre historique de discussion et votre progression seront supprimés de cet appareil. Sans sauvegarde, ils seront irrécupérables. Saisissez DELETE pour confirmer.';

  @override
  String get accountDeleteConfirmWord => 'DELETE';

  @override
  String get accountDeleteConfirmHint => 'Saisissez DELETE';

  @override
  String get accountDeleteButton => 'Supprimer';

  @override
  String get accountRecoveryPendingDiscard => 'Abandonner l’identité en attente et repartir de zéro';

  @override
  String accountRestoreFileChosenSize(int bytes) {
    return 'Fichier de sauvegarde sélectionné ($bytes octets)';
  }

  @override
  String get chatSearchConversations => 'Rechercher des conversations';

  @override
  String get chatNoConversations => 'Aucune conversation pour l’instant';

  @override
  String get chatNoSearchResults => 'Aucune conversation correspondante';

  @override
  String get chatPin => 'Épingler';

  @override
  String get chatUnpin => 'Désépingler';

  @override
  String get chatMarkRead => 'Marquer comme lu';

  @override
  String get chatDelete => 'Supprimer';

  @override
  String get chatDeleteConversationTitle => 'Supprimer la conversation ?';

  @override
  String get chatDeleteConversationBody => 'L’historique local de cette conversation sera supprimé. Tox n’en conserve aucune copie.';

  @override
  String get chatDraftPrefix => 'Brouillon : ';

  @override
  String get chatSelectConversation => 'Sélectionnez une conversation';

  @override
  String get chatContacts => 'Contacts';

  @override
  String get chatNoMessages => 'Aucun message pour l’instant : envoyez CQ pour commencer.';

  @override
  String get chatTrainingMode => 'Mode entraînement';

  @override
  String get chatTrainingModeOn => 'Mode entraînement activé : texte masqué';

  @override
  String get chatTrainingModeOff => 'Mode entraînement désactivé';

  @override
  String get chatAutoPlay => 'Lire automatiquement le morse reçu';

  @override
  String get chatAutoPlayOn => 'Lecture auto activée : les nouveaux messages sont lus à leur arrivée';

  @override
  String get chatAutoPlayOff => 'Lecture auto désactivée';

  @override
  String get chatReveal => 'Révéler';

  @override
  String get chatHiddenText => 'Écoutez d’abord, puis révélez le texte';

  @override
  String get chatPlay => 'Écouter le Morse';

  @override
  String get chatStop => 'Arrêter';

  @override
  String get chatPlaybackSettings => 'Réglages de lecture';

  @override
  String get chatCharacterSpeed => 'Vitesse des caractères';

  @override
  String get chatFarnsworthSpeed => 'Vitesse Farnsworth';

  @override
  String get chatTone => 'Tonalité';

  @override
  String get chatWpm => 'WPM';

  @override
  String get chatHz => 'Hz';

  @override
  String get chatMembers => 'Membres';

  @override
  String get chatLeaveGroup => 'Quitter le groupe';

  @override
  String get chatLeaveGroupTitle => 'Quitter ce groupe ?';

  @override
  String get chatLeaveGroupBody => 'Vous ne recevrez plus de messages. Vous pourrez revenir avec l’identifiant de discussion.';

  @override
  String get chatLeave => 'Quitter';

  @override
  String get chatConferenceNote => 'Conférence ancienne : les métadonnées de manipulation Morse (v2) ne sont pas disponibles ici. Les messages texte fonctionnent toujours.';

  @override
  String get chatClearHistory => 'Effacer l’historique';

  @override
  String get chatModeStraightKey => 'Pioche';

  @override
  String get chatModePaddles => 'Palettes';

  @override
  String get chatKeyMessage => 'Manipulez votre message';

  @override
  String get chatSend => 'Envoyer';

  @override
  String get chatTooLong => 'Trop long pour un seul message Tox';

  @override
  String get chatKeyHint => 'Manipulez sur la zone de saisie ou appuyez sur Espace';

  @override
  String get chatPaddleHint => 'Touchez les palettes ou maintenez Ctrl (gauche : point, droite : trait)';

  @override
  String get chatDeleteLast => 'Supprimer le dernier caractère';

  @override
  String get chatNoFriends => 'Aucun ami pour l’instant. Ajoutez-en un avec son identifiant Tox.';

  @override
  String get chatNoRequests => 'Aucune demande en attente';

  @override
  String get chatAddFriend => 'Ajouter un ami';

  @override
  String get chatMyToxId => 'Mon identifiant Tox';

  @override
  String get chatToxIdLabel => 'Identifiant Tox (76 caractères hexadécimaux)';

  @override
  String get chatToxIdInvalid => 'L’identifiant Tox doit comporter exactement 76 caractères hexadécimaux';

  @override
  String get chatToxIdOwn => 'Il s’agit de votre propre identifiant Tox';

  @override
  String get chatToxIdAlreadyFriend => 'Déjà dans votre liste d’amis';

  @override
  String get chatRequestMessage => 'Message';

  @override
  String get chatDefaultRequestMessage => 'DitMesh CQ';

  @override
  String get chatSendRequest => 'Envoyer la demande';

  @override
  String get chatRequestSent => 'Demande d’ami envoyée';

  @override
  String get chatScanQr => 'Scanner un code QR';

  @override
  String get chatScanQrDesktopHint => 'La lecture des codes QR nécessite une caméra de téléphone';

  @override
  String get chatScanQrTitle => 'Scanner un identifiant Tox';

  @override
  String get chatScanQrNotToxId => 'Ce code QR n’est pas un identifiant Tox';

  @override
  String get chatAccept => 'Accepter';

  @override
  String get chatReject => 'Refuser';

  @override
  String get chatCopied => 'Copié dans le presse-papiers';

  @override
  String get chatNoIdentity => 'Aucune identité chargée';

  @override
  String get chatRemoveFriend => 'Retirer un ami';

  @override
  String get chatRemoveFriendTitle => 'Retirer cet ami ?';

  @override
  String get chatRemoveFriendBody => 'Cette personne ne pourra plus vous envoyer de messages.';

  @override
  String get chatRemove => 'Retirer';

  @override
  String get chatNoGroups => 'Aucun groupe pour l’instant. Créez-en un ou rejoignez-en un avec son identifiant de discussion.';

  @override
  String get chatCreateGroup => 'Créer un groupe';

  @override
  String get chatJoinGroup => 'Rejoindre un groupe';

  @override
  String get chatGroupName => 'Nom du groupe';

  @override
  String get chatGroupNameRequired => 'Donnez un nom au groupe';

  @override
  String get chatAdvanced => 'Avancé';

  @override
  String get chatLegacyConference => 'Conférence ancienne (anciens clients)';

  @override
  String get chatLegacyConferenceHint => 'Déconseillé : aucun identifiant de discussion permanent ni métadonnées Morse.';

  @override
  String get chatCreate => 'Créer';

  @override
  String get chatChatIdLabel => 'Identifiant de discussion (64 caractères hexadécimaux)';

  @override
  String get chatChatIdInvalid => 'L’identifiant de discussion doit comporter exactement 64 caractères hexadécimaux';

  @override
  String get chatPassword => 'Mot de passe (facultatif)';

  @override
  String get chatJoin => 'Rejoindre';

  @override
  String get chatJoinRequested => 'Connexion au groupe : il apparaîtra dès qu’un pair sera trouvé.';

  @override
  String get chatConferenceBadge => 'Conférence';

  @override
  String get chatCopyChatId => 'Copier l’identifiant de discussion';

  @override
  String get learnContinueLesson => 'Continuer la leçon';

  @override
  String get learnSettings => 'Réglages d’entraînement';

  @override
  String get learnLoading => 'Chargement de votre progression…';

  @override
  String get learnIdentityRequired => 'Créez ou déverrouillez votre identité pour commencer l’entraînement. Votre progression est enregistrée avec votre identité et suit votre sauvegarde.';

  @override
  String get learnProgressSaveFailed => 'Impossible d\'enregistrer votre progression. Le résultat compte tant que DitMesh reste ouvert.';

  @override
  String get toolsTitle => 'Outils radio';

  @override
  String get toolsGridTitle => 'Localisateur';

  @override
  String get toolsGridHint => 'Localisateur à partir des coordonnées, distance et azimut';

  @override
  String get toolsBandsTitle => 'Bandes et antennes';

  @override
  String get toolsBandsHint => 'Bande d’une fréquence, longueur d’onde et longueur du dipôle';

  @override
  String get toolsSpeedTitle => 'Vitesse CW';

  @override
  String get toolsSpeedHint => 'Convertir les WPM en durée des points, pauses et caractères par minute';

  @override
  String get toolsRstTitle => 'Rapport RST';

  @override
  String get toolsRstHint => 'Composez un rapport de signal et découvrez le sens de chaque chiffre';

  @override
  String get toolsClockTitle => 'Horloge UTC';

  @override
  String get toolsClockHint => 'Heure UTC pour le journal, à côté de votre heure locale';

  @override
  String get toolsGridFromCoordinates => 'Depuis les coordonnées';

  @override
  String get toolsGridLatitude => 'Latitude';

  @override
  String get toolsGridLongitude => 'Longitude';

  @override
  String get toolsGridCoordinatesHelp => 'Degrés décimaux ; sud et ouest sont négatifs';

  @override
  String get toolsGridInvalidCoordinates => 'Latitude de −90 à 90, longitude de −180 à 180';

  @override
  String get toolsGridLocator => 'Localisateur';

  @override
  String get toolsGridDistanceSection => 'Distance et azimut';

  @override
  String get toolsGridMine => 'Mon localisateur';

  @override
  String get toolsGridTheirs => 'Localisateur du correspondant';

  @override
  String get toolsGridInvalidLocator => 'Utilisez 2, 4, 6 ou 8 caractères, par exemple OM89ex';

  @override
  String get toolsGridCenter => 'Centre du carré';

  @override
  String get toolsGridDistance => 'Distance';

  @override
  String get toolsGridShortPath => 'Azimut trajet court';

  @override
  String get toolsGridLongPath => 'Azimut trajet long';

  @override
  String get toolsBandsFrequency => 'Fréquence (MHz)';

  @override
  String get toolsBandsInvalidFrequency => 'Saisissez une fréquence supérieure à 0';

  @override
  String toolsBandsRegionLabel(int number) {
    return 'Région $number';
  }

  @override
  String get toolsBandsRegionHelp => '1 : Europe, Afrique, Moyen-Orient – 2 : Amériques – 3 : Asie-Pacifique';

  @override
  String toolsBandsInBand(String band) {
    return 'Dans la bande amateur $band';
  }

  @override
  String get toolsBandsOutOfBand => 'Hors des bandes amateurs';

  @override
  String get toolsBandsWavelength => 'Longueur d’onde';

  @override
  String get toolsBandsDipole => 'Dipôle demi-onde (total)';

  @override
  String get toolsBandsQuarterWave => 'Verticale quart d’onde';

  @override
  String get toolsBandsAntennaNote => 'Longueurs avec facteur de raccourcissement de 0,95 ; ajustez pour la résonance.';

  @override
  String get toolsBandsTable => 'Limites des bandes';

  @override
  String toolsBandsQrp(String frequency) {
    return 'QRP CW $frequency';
  }

  @override
  String get toolsBandsDisclaimer => 'Attributions UIT. Votre licence et le plan de bandes national peuvent être plus restrictifs.';

  @override
  String get toolsSpeedCharacter => 'Vitesse des caractères';

  @override
  String get toolsSpeedFarnsworth => 'Espacement Farnsworth';

  @override
  String get toolsSpeedOverall => 'Vitesse globale';

  @override
  String get toolsSpeedDit => 'Point';

  @override
  String get toolsSpeedDah => 'Trait';

  @override
  String get toolsSpeedCharGap => 'Pause entre caractères';

  @override
  String get toolsSpeedWordGap => 'Pause entre mots';

  @override
  String get toolsSpeedCpm => 'Caractères par minute';

  @override
  String get toolsSpeedParis => 'Un mot PARIS';

  @override
  String get toolsRstReadability => 'Lisibilité (R)';

  @override
  String get toolsRstStrength => 'Force du signal (S)';

  @override
  String get toolsRstTone => 'Tonalité (T)';

  @override
  String get toolsRstReport => 'Rapport';

  @override
  String get toolsRstCut => 'Notation concours';

  @override
  String get toolsRstPhone => 'Phonie (sans tonalité)';

  @override
  String get toolsRstR1 => 'Illisible';

  @override
  String get toolsRstR2 => 'À peine lisible, quelques mots';

  @override
  String get toolsRstR3 => 'Lisible avec beaucoup de difficulté';

  @override
  String get toolsRstR4 => 'Lisible sans difficulté notable';

  @override
  String get toolsRstR5 => 'Parfaitement lisible';

  @override
  String get toolsRstS1 => 'Faible, à peine perceptible';

  @override
  String get toolsRstS2 => 'Très faible';

  @override
  String get toolsRstS3 => 'Faible';

  @override
  String get toolsRstS4 => 'Moyenne';

  @override
  String get toolsRstS5 => 'Assez bonne';

  @override
  String get toolsRstS6 => 'Bonne';

  @override
  String get toolsRstS7 => 'Modérément forte';

  @override
  String get toolsRstS8 => 'Forte';

  @override
  String get toolsRstS9 => 'Extrêmement forte';

  @override
  String get toolsRstT1 => 'Très rauque et large, son alternatif non redressé';

  @override
  String get toolsRstT2 => 'Son alternatif très rauque, strident et large';

  @override
  String get toolsRstT3 => 'Rauque, redressée mais non filtrée';

  @override
  String get toolsRstT4 => 'Rauque, légèrement filtrée';

  @override
  String get toolsRstT5 => 'Filtrée, mais fortement modulée par l’ondulation';

  @override
  String get toolsRstT6 => 'Filtrée, avec une ondulation nette';

  @override
  String get toolsRstT7 => 'Presque pure, faible ondulation';

  @override
  String get toolsRstT8 => 'Presque parfaite, légère modulation';

  @override
  String get toolsRstT9 => 'Tonalité pure, sans ondulation';

  @override
  String get toolsClockUtc => 'UTC';

  @override
  String get toolsClockLocal => 'Heure locale';

  @override
  String get toolsClockNote => 'Les journaux de trafic et les cartes QSL utilisent UTC.';

  @override
  String get learnReceiveTitle => 'Réception';

  @override
  String get learnReviewTitle => 'Révision';

  @override
  String get learnListen => 'Lecture en cours';

  @override
  String get learnReady => 'Prêt';

  @override
  String get learnReplay => 'Réécouter';

  @override
  String get learnAnswerHint => 'Saisissez ce que vous avez entendu';

  @override
  String get learnSubmit => 'Vérifier';

  @override
  String get learnNext => 'Suivant';

  @override
  String get learnFinish => 'Terminer';

  @override
  String get learnDone => 'Terminé';

  @override
  String get learnBackspace => 'Supprimer';

  @override
  String get learnSpace => 'Espace';

  @override
  String get learnSent => 'Envoyé';

  @override
  String get learnYourCopy => 'Votre réception';

  @override
  String get learnRoundPerfect => 'Réception parfaite !';

  @override
  String get learnSessionSummary => 'Bilan de la séance';

  @override
  String get learnLessonPassed => 'Leçon réussie';

  @override
  String get learnLessonNotPassed => 'Persévérez : 90 % débloquent la leçon suivante';

  @override
  String get learnReviewRecorded => 'Révision enregistrée';

  @override
  String get learnWeakChars => 'À travailler';

  @override
  String get learnConfusions => 'Confusions';

  @override
  String get learnNoFeedbackWarning => 'Le son, les flashs et les vibrations sont désactivés ; l’écran clignotera à leur place.';

  @override
  String get learnKeyerStraight => 'Pioche';

  @override
  String get learnKeyerIambicA => 'Iambic A';

  @override
  String get learnKeyerIambicB => 'Iambic B';

  @override
  String get learnStraightKeyLabel => 'MANIPULATEUR';

  @override
  String get learnDitLabel => 'POINT';

  @override
  String get learnDahLabel => 'TRAIT';

  @override
  String get learnSettingsTitle => 'Réglages d’entraînement';

  @override
  String get learnCharacterSpeed => 'Vitesse des caractères';

  @override
  String get learnFarnsworth => 'Espacement Farnsworth';

  @override
  String get learnFarnsworthHelp => 'Les caractères restent rapides ; les pauses entre eux sont allongées pour atteindre cette vitesse.';

  @override
  String get learnEffectiveSpeed => 'Vitesse effective';

  @override
  String get learnTone => 'Tonalité';

  @override
  String get learnPlaySample => 'Écouter un exemple';

  @override
  String get learnSessionLength => 'Longueur de la séance';

  @override
  String get learnFeedback => 'Retour sensoriel';

  @override
  String get learnSound => 'Son';

  @override
  String get learnFlash => 'Flash de l’écran';

  @override
  String get learnHaptic => 'Vibration';

  @override
  String get learnKeyer => 'Manipulateur';

  @override
  String get learnDailyGoal => 'Objectif quotidien';

  @override
  String get referenceReferenceTitle => 'Référence Morse';

  @override
  String get referenceTranslatorTitle => 'Traducteur';

  @override
  String get referencePlay => 'Écouter';

  @override
  String get referenceStop => 'Arrêter';

  @override
  String get referenceClear => 'Effacer';

  @override
  String get referenceClose => 'Fermer';

  @override
  String get referenceEmptyOutput => '—';

  @override
  String get referenceSearchHint => 'Rechercher des caractères, signaux de procédure, codes Q…';

  @override
  String get referenceClearSearch => 'Effacer la recherche';

  @override
  String get referenceNoResults => 'Aucun résultat pour votre recherche.';

  @override
  String get referenceSectionAlphabet => 'Alphabet';

  @override
  String get referenceSectionPunctuation => 'Ponctuation';

  @override
  String get referenceSectionProsigns => 'Signaux de procédure';

  @override
  String get referenceSectionQCodes => 'Codes Q';

  @override
  String get referenceSectionAbbreviations => 'Abréviations CW';

  @override
  String get referenceSectionKoch => 'Ordre Koch';

  @override
  String get referenceAlphabetHint => 'Touchez une carte pour l’écouter. Faites un appui long pour voir un moyen mnémotechnique.';

  @override
  String get referenceKochHint => 'Ordre d’introduction des caractères selon la méthode Koch (séquence LCWO). Commencez par K et M ; ajoutez-en un lorsque votre réception atteint 90 %.';

  @override
  String get referenceMnemonicTitle => 'Moyen mnémotechnique';

  @override
  String get referenceMeaningLabel => 'Signification';

  @override
  String get referencePlaybackSettings => 'Réglages de lecture';

  @override
  String get referenceCharacterSpeed => 'Vitesse des caractères';

  @override
  String get referenceFarnsworth => 'Espacement Farnsworth';

  @override
  String get referenceFarnsworthHelp => 'Les caractères gardent leur vitesse maximale ; les pauses sont allongées pour atteindre la vitesse effective.';

  @override
  String get referenceEffectiveSpeed => 'Vitesse effective';

  @override
  String get referenceTone => 'Tonalité';

  @override
  String get referenceModeTextToMorse => 'Texte → Morse';

  @override
  String get referenceModeMorseToText => 'Morse → Texte';

  @override
  String get referenceModeKey => 'Manipuler';

  @override
  String get referenceTextInputLabel => 'Texte';

  @override
  String get referenceTextInputHint => 'Saisissez le texte à coder…';

  @override
  String get referencePatternOutputLabel => 'Morse';

  @override
  String get referenceCopyPattern => 'Copier la séquence';

  @override
  String get referencePatternCopied => 'Séquence copiée';

  @override
  String get referencePatternInputLabel => 'Morse';

  @override
  String get referencePatternInputHint => 'Saisissez . et -, un espace entre les lettres, / entre les mots';

  @override
  String get referenceTextOutputLabel => 'Texte';

  @override
  String get referenceCopyText => 'Copier le texte';

  @override
  String get referenceTextCopied => 'Texte copié';

  @override
  String get referenceUnknownPatternHelp => 'Les séquences sans caractère correspondant s’affichent sous la forme <pattern>.';

  @override
  String get referenceKeypadDit => 'Point';

  @override
  String get referenceKeypadDah => 'Trait';

  @override
  String get referenceKeypadCharGap => 'Pause entre lettres';

  @override
  String get referenceKeypadWordGap => 'Pause entre mots';

  @override
  String get referenceKeypadBackspace => 'Retour arrière';

  @override
  String get referenceKeyHint => 'Maintenez le manipulateur pour transmettre. Sur un clavier, maintenez la touche Espace.';

  @override
  String get referenceKeyLabel => 'MANIPULATEUR';

  @override
  String get referenceKeyDecodedLabel => 'Décodé';

  @override
  String get referenceKeyPendingLabel => 'Manipulation';

  @override
  String get listenTitle => 'Écoute';

  @override
  String get listenStart => 'Démarrer';

  @override
  String get listenStop => 'Arrêter';

  @override
  String get listenStarting => 'Démarrage du microphone…';

  @override
  String get listenClear => 'Effacer le texte';

  @override
  String get listenCopy => 'Copier le texte';

  @override
  String get listenCopied => 'Texte décodé copié';

  @override
  String get listenSettings => 'Réglages d’écoute';

  @override
  String get listenDecoded => 'Décodé';

  @override
  String get listenEmptyHint => 'Dirigez le microphone vers un signal sonore Morse. Le texte décodé apparaîtra ici.';

  @override
  String get listenIdleHint => 'Touchez « Démarrer » pour écouter un signal Morse.';

  @override
  String get listenPending => 'Réception en cours';

  @override
  String get listenSpeed => 'Vitesse';

  @override
  String get listenSpeedUnknown => '-- WPM';

  @override
  String get listenLevel => 'Signal';

  @override
  String get listenToneOn => 'Tonalité';

  @override
  String get listenTone => 'Fréquence de la tonalité';

  @override
  String get listenToneLocked => 'Verrouillée';

  @override
  String get listenToneSearching => 'Recherche';

  @override
  String get listenToneManual => 'Manuelle';

  @override
  String get listenAutoTune => 'Accord automatique';

  @override
  String get listenAutoTuneHelp => 'Suit la tonalité la plus forte entre 400 et 1000 Hz. Déplacez le curseur pour régler la fréquence manuellement.';

  @override
  String get listenRetune => 'Automatique';

  @override
  String get listenBlockSize => 'Bloc d’analyse';

  @override
  String get listenBlockSizeHelp => 'Les petits blocs repèrent mieux les transitions du signal, mais captent davantage de bruit. 256 échantillons (5,3 ms) conviennent à 5–40 WPM.';

  @override
  String get listenMinElement => 'Élément le plus court';

  @override
  String get listenMinElementHelp => 'Les sons et pauses plus courts que cette durée sont ignorés comme des clics ou des coupures.';

  @override
  String get listenPermissionDenied => 'L’accès au microphone a été refusé. Autorisez-le dans les réglages du système, puis réessayez.';

  @override
  String get listenPermissionRetry => 'Réessayer';

  @override
  String get listenStartFailed => 'Impossible de démarrer le microphone.';

  @override
  String get listenNoInput => 'Aucun microphone trouvé. Connectez-en un et réessayez.';

  @override
  String get listenStreamFailed => 'Le microphone s’est arrêté de façon inattendue. Réessayez.';

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
    return '$samples échantillons ($ms ms)';
  }

  @override
  String listenMsValue(int ms) {
    return '$ms ms';
  }

  @override
  String get listenStoppedInBackground => 'L’écoute s’est arrêtée lorsque l’application est passée en arrière-plan.';

  @override
  String get notificationOpen => 'Ouvrir';

  @override
  String get notificationChannelMessages => 'Messages';

  @override
  String get notificationChannelMessagesDescription => 'Nouveaux messages Morse de vos amis et groupes';

  @override
  String get notificationChannelFriendRequests => 'Demandes d’ami';

  @override
  String get notificationChannelFriendRequestsDescription => 'Quelqu’un souhaite vous ajouter comme ami';

  @override
  String get notificationChannelGroupInvites => 'Invitations de groupe';

  @override
  String get notificationChannelGroupInvitesDescription => 'Un ami vous a invité dans un groupe';

  @override
  String get notificationNewMessage => 'Nouveau message';

  @override
  String get notificationFriendRequestTitle => 'Nouvelle demande d’ami';

  @override
  String get accountNewPasswordRequired => 'Saisissez un nouveau mot de passe';

  @override
  String get accountToxIdQrSemantics => 'Code QR de l’identifiant Tox';

  @override
  String get accountBackupSaveDialogTitle => 'Enregistrer la sauvegarde DitMesh';

  @override
  String get accountBackupShareSubject => 'Sauvegarde d’identité DitMesh';

  @override
  String get accountBackupChooseDialogTitle => 'Choisir une sauvegarde DitMesh';

  @override
  String notificationNewMessages(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count nouveaux messages',
      one: '$count nouveau message',
    );
    return '$_temp0';
  }

  @override
  String notificationFriendRequestFrom(String name) {
    return 'Demande d’ami de $name';
  }

  @override
  String notificationFriendRequestBody(String name, String message) {
    return '$name : $message';
  }

  @override
  String notificationGroupInviteTitle(String group) {
    return 'Invitation dans $group';
  }

  @override
  String notificationGroupInviteBody(String name) {
    return '$name vous a invité';
  }

  @override
  String desktopTrayShow(String app) {
    return 'Afficher $app';
  }

  @override
  String desktopTrayHide(String app) {
    return 'Masquer $app';
  }

  @override
  String get desktopTraySoundOn => 'Son activé';

  @override
  String get desktopTraySoundOff => 'Son désactivé';

  @override
  String desktopTrayQuit(String app) {
    return 'Quitter $app';
  }

  @override
  String desktopTrayTooltipUnread(String app, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count messages non lus',
      one: '$count message non lu',
    );
    return '$app — $_temp0';
  }

  @override
  String desktopWindowTitleUnread(String badge, String app) {
    return '($badge) $app';
  }

  @override
  String get listenStateOn => 'Activé';

  @override
  String get listenStateOff => 'Désactivé';

  @override
  String chatBytesLeftCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count octets restants',
      one: '$count octet restant',
    );
    return '$_temp0';
  }

  @override
  String chatMemberCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count membres',
      one: '$count membre',
    );
    return '$_temp0';
  }

  @override
  String chatFriendsCount(int count) {
    return 'Amis ($count)';
  }

  @override
  String chatFriendRequestsCount(int count) {
    return 'Demandes d’ami ($count)';
  }

  @override
  String chatGroupInvitesCount(int count) {
    return 'Invitations de groupe ($count)';
  }

  @override
  String chatMembersTitleCount(int count) {
    return 'Membres · $count';
  }

  @override
  String chatInvitedByName(String name) {
    return 'Invité par $name';
  }

  @override
  String chatMemberSelf(String name) {
    return '$name (Vous)';
  }

  @override
  String chatSliderValue(String label, int value, String unit) {
    return '$label : $value $unit';
  }

  @override
  String referenceTelegraphCodes(String codes) {
    return 'Code télégraphique chinois : $codes';
  }

  @override
  String get referenceTelegraphMainland => 'Chine continentale 1983';

  @override
  String get referenceTelegraphTaiwan => 'Taïwan / HK';

  @override
  String get referenceTelegraphNone => 'Absent de ce répertoire';

  @override
  String get appearanceTitle => 'Apparence';

  @override
  String get appearanceStyles => 'Style de l’interface';

  @override
  String get appearanceChoose => 'Choisissez un style, prévisualisez-le, puis appliquez-le';

  @override
  String get appearanceMode => 'Luminosité';

  @override
  String get appearancePreview => 'Aperçu';

  @override
  String get appearanceApply => 'Appliquer le style';

  @override
  String get appearanceRestore => 'Rétablir les valeurs par défaut';

  @override
  String get appearanceApplied => 'Apparence enregistrée';

  @override
  String get appearanceSaveFailed => 'Impossible d’enregistrer l’apparence. Réessayez.';

  @override
  String get appearanceClassic => 'Laiton classique';

  @override
  String get appearanceModern => 'Calme moderne';

  @override
  String get appearanceRadio => 'Radio de nuit';

  @override
  String get appearancePaper => 'Manuel papier';

  @override
  String get appearanceCartoon => 'Dessin pétillant';

  @override
  String get appearanceLight => 'Clair';

  @override
  String get appearanceDark => 'Sombre';

  @override
  String get appearanceSubtitle => 'Cinq styles avec modes clair et sombre';

  @override
  String get chatClearHistoryBody => 'Supprimer l’historique de cette conversation sur cet appareil ? Les copies sur les autres appareils sont conservées. Cette action est irréversible.';

  @override
  String get chatLoadEarlier => 'Charger les messages précédents';

  @override
  String get chatHistoryLoadFailed => 'Impossible de charger les messages précédents. Touchez pour réessayer.';

  @override
  String get chatRetryHistory => 'Réessayer';

  @override
  String chatNewMessages(int count) {
    return '$count nouveaux messages';
  }

  @override
  String get chatSelfMe => 'Moi';

  @override
  String get chatSelfLocalOnly => 'Enregistré uniquement sur cet appareil';

  @override
  String get chatSelfContactSubtitle => 'Brouillons, exercices et notes · jamais envoyés';

  @override
  String get learnLeaveDrillTitle => 'Quitter cette séance ?';

  @override
  String get learnLeaveDrillBody => 'Les manches de cette séance ne seront pas enregistrées.';

  @override
  String get learnLeaveDrillConfirm => 'Quitter';

  @override
  String get chatScanQrPermissionDenied => 'DitMesh a besoin de la caméra pour scanner un code QR. Autorisez-la dans les réglages du système.';

  @override
  String get chatScanQrCameraUnavailable => 'La caméra n\'est pas disponible sur cet appareil.';

  @override
  String get learnReplayAssistedNote => 'Rejoué : cette séance compte comme entraînement mais ne débloque pas de leçon et ne met pas à jour les révisions.';

  @override
  String learnPlanNext(String step) {
    return 'Ensuite : $step';
  }

  @override
  String get messageStatusCancelled => 'Annulé — jamais envoyé';

  @override
  String get chatMessageLearnActions => 'Actions du message';

  @override
  String get chatPracticeMessage => 'S\'exercer sur ce message';

  @override
  String get chatListenOnly => 'Entraînement à l\'écoute seule';

  @override
  String get chatListenOnlyHidden => 'Écoute seule : lancez la lecture';

  @override
  String get chatPracticeTitle => 'Exercice de copie';

  @override
  String chatPracticeUnsupported(String chars) {
    return 'Ce message contient des caractères sans code Morse : $chars. Ils seront ignorés.';
  }

  @override
  String chatPracticeTrainableCount(int count) {
    return '$count signes peuvent être travaillés.';
  }

  @override
  String get chatPracticeNothingTrainable => 'Rien dans ce message ne peut être travaillé en Morse.';

  @override
  String get chatPracticeConfirm => 'S\'exercer sur le reste';

  @override
  String get chatPracticeHint => 'Indice';

  @override
  String chatPracticeHintShown(String symbols) {
    return 'Indice : $symbols …';
  }

  @override
  String get chatPracticeAssisted => 'Avec aide : compte comme entraînement, pas pour les révisions ni le conseil de vitesse.';

  @override
  String chatPracticeErrors(int wrong, int missed, int extra) {
    return '$wrong faux · $missed oubliés · $extra en trop';
  }

  @override
  String chatPracticeErrorsAction(String symbols) {
    return 'Travailler les erreurs : $symbols';
  }

  @override
  String get chatSearchMessages => 'Rechercher des messages';

  @override
  String get chatSearchHint => 'Rechercher dans cette conversation';

  @override
  String get chatSearchAnyone => 'Tout le monde';

  @override
  String get chatSearchMe => 'Moi';

  @override
  String get chatSearchThem => 'L\'autre';

  @override
  String get chatSearchAnyDate => 'N\'importe quelle date';

  @override
  String chatSearchDateRange(String from, String to) {
    return '$from – $to';
  }

  @override
  String get chatSearchBookmarked => 'Favoris';

  @override
  String get chatSearchNoResults => 'Aucun message correspondant.';

  @override
  String get chatSearchMore => 'Charger plus';

  @override
  String get chatAddBookmark => 'Ajouter aux favoris';

  @override
  String get chatRemoveBookmark => 'Retirer des favoris';

  @override
  String get chatBookmarked => 'Dans les favoris';

  @override
  String get chatBookmarkFailed => 'Impossible d\'enregistrer le favori.';

  @override
  String get chatRetrySend => 'Réessayer l\'envoi';

  @override
  String get chatCancelSend => 'Annuler l\'envoi';

  @override
  String get chatRetryQueued => 'Remis en file d\'attente. Envoi dès que le contact est en ligne.';

  @override
  String get chatSendCancelled => 'Annulé. Le message n\'a jamais été envoyé.';

  @override
  String get chatRetryNotNeeded => 'Ce message n\'est plus en échec.';

  @override
  String get chatCancelTooLate => 'Trop tard : le message est déjà parti et peut arriver.';

  @override
  String get chatSendControlUnavailable => 'Indisponible pour ce message.';

  @override
  String get chatSendControlFailed => 'Échec. Le message garde son état ; réessayez.';

  @override
  String get workbenchTitle => 'Atelier d\'enregistrements';

  @override
  String get workbenchOpen => 'Enregistrements';

  @override
  String get workbenchImport => 'Importer un enregistrement';

  @override
  String get workbenchEmpty => 'Importez un enregistrement WAV pour le boucler, le décoder et le copier. Aucun micro requis.';

  @override
  String get workbenchFormats => 'WAV, PCM 16 bits, mono ou stéréo, 8/16/44,1/48 kHz ; jusqu\'à 50 Mo et 20 minutes.';

  @override
  String get workbenchBackupNote => 'Les enregistrements restent sur cet appareil et ne sont pas dans la sauvegarde d\'identité, sauf si vous choisissez de les inclure à l\'export. Les titres, notes et positions des sélections sont toujours sauvegardés.';

  @override
  String workbenchInfo(String rate, String channels, String duration) {
    return '$rate kHz · $channels · $duration';
  }

  @override
  String get workbenchMono => 'mono';

  @override
  String get workbenchStereo => 'stéréo';

  @override
  String get workbenchTruncated => 'Le fichier se termine trop tôt ; seul l\'audio présent est utilisé.';

  @override
  String get workbenchErrorNotWav => 'Ce n\'est pas un fichier WAV.';

  @override
  String get workbenchErrorFormat => 'Seul le WAV PCM 16 bits est pris en charge pour l\'instant (pas de MP3, AAC ni WAV flottant).';

  @override
  String get workbenchErrorChannels => 'Seuls les enregistrements mono ou stéréo sont pris en charge.';

  @override
  String get workbenchErrorRate => 'Fréquence d\'échantillonnage non prise en charge. Utilisez 8, 16, 44,1 ou 48 kHz.';

  @override
  String get workbenchErrorDamaged => 'Le fichier est endommagé ou incomplet.';

  @override
  String get workbenchErrorTooLarge => 'Le fichier dépasse 50 Mo.';

  @override
  String get workbenchErrorTooLong => 'L\'enregistrement dure plus de 20 minutes.';

  @override
  String get workbenchErrorIo => 'Impossible de lire le fichier.';

  @override
  String get workbenchErrorMissing => 'Le fichier d\'enregistrement est introuvable.';

  @override
  String get workbenchStart => 'Début (s)';

  @override
  String get workbenchEnd => 'Fin (s)';

  @override
  String get workbenchSelectAll => 'Tout sélectionner';

  @override
  String get workbenchPlay => 'Lire la sélection';

  @override
  String get workbenchStop => 'Arrêter';

  @override
  String get workbenchLoop => 'Boucle';

  @override
  String get workbenchPlayLimit => 'Seules les 5 premières minutes d\'une sélection plus longue sont lues.';

  @override
  String get workbenchAutoTune => 'Trouver la tonalité automatiquement';

  @override
  String workbenchManualTone(int hz) {
    return 'Tonalité : $hz Hz';
  }

  @override
  String get workbenchDecode => 'Décoder la sélection';

  @override
  String get workbenchCancel => 'Annuler';

  @override
  String workbenchDecoding(int percent) {
    return 'Décodage… $percent %';
  }

  @override
  String workbenchResultStats(int hz, int wpm) {
    return 'Tonalité $hz Hz · environ $wpm mots/min';
  }

  @override
  String get workbenchToneNotLocked => 'Aucune tonalité stable ; essayez le réglage manuel.';

  @override
  String get workbenchNoText => 'Rien n\'a été décodé dans cette sélection.';

  @override
  String workbenchUnknown(String patterns) {
    return 'Motifs inconnus : $patterns';
  }

  @override
  String get workbenchEdgeCut => 'Un signe au bord de la sélection est coupé et peut être faux.';

  @override
  String get workbenchToneNote => 'Le verrouillage de tonalité n\'est pas un indice de confiance ; vérifiez le texte à l\'oreille.';

  @override
  String get workbenchModeDecoder => 'Décodeur';

  @override
  String get workbenchModeCopy => 'Le copier moi-même';

  @override
  String get workbenchDecoderHidden => 'Le texte du décodeur est masqué pendant la copie.';

  @override
  String get workbenchShowDecoder => 'Afficher le texte du décodeur';

  @override
  String get workbenchReference => 'Texte de référence (facultatif)';

  @override
  String get workbenchReferenceHelp => 'Collez le texte envoyé ; sinon votre copie est comparée à la sortie du décodeur.';

  @override
  String get workbenchAgainstDecoder => 'Comparé à la sortie du décodeur, qui peut elle-même être fausse.';

  @override
  String get workbenchSave => 'Enregistrer la sélection';

  @override
  String get workbenchSaveTitle => 'Titre';

  @override
  String get workbenchSaveNote => 'Note';

  @override
  String get workbenchSaved => 'Sélection enregistrée';

  @override
  String get workbenchSaveFailed => 'Impossible d\'enregistrer la sélection.';

  @override
  String get workbenchLibrary => 'Sélections enregistrées';

  @override
  String get workbenchLibraryEmpty => 'Aucune sélection enregistrée pour l\'instant.';

  @override
  String get workbenchMissing => 'Fichier manquant : choisissez-le à nouveau ou supprimez l\'entrée.';

  @override
  String get workbenchRelink => 'Choisir à nouveau le fichier';

  @override
  String get workbenchDelete => 'Supprimer';

  @override
  String get guestTryLearning => 'Essayer d\'apprendre d\'abord';

  @override
  String get guestBanner => 'Mode invité : la progression reste sur cet appareil. Le chat demande une identité.';

  @override
  String get guestGetIdentity => 'Configurer l\'identité';

  @override
  String get guestIdentityTitle => 'Identité requise';

  @override
  String get guestIdentityBody => 'Discuter via Tox nécessite votre propre identité. Créez-en une, restaurez une sauvegarde ou déverrouillez celle de l\'appareil. Votre progression d\'invité passe automatiquement à une nouvelle identité.';

  @override
  String get guestClearData => 'Effacer les données d\'invité';

  @override
  String get guestClearDataBody => 'Supprime la progression, les programmes et les supports créés en invité sur cet appareil. Les identités ne sont pas touchées.';

  @override
  String get guestClearConfirm => 'Effacer';

  @override
  String get guestCleared => 'Données d\'invité effacées.';

  @override
  String get guestClearFailed => 'Impossible d\'effacer les données.';

  @override
  String get guestMigrationFailed => 'Votre identité est prête, mais votre progression d\'invité n\'a pas encore été transférée. Elle reste en sécurité sur l\'appareil.';

  @override
  String get guestChoiceBody => 'Vous avez aussi une progression d\'invité. La progression de l\'identité restaurée est utilisée ; rien n\'a été fusionné.';

  @override
  String get guestChoiceKeep => 'Garder la restauration';

  @override
  String get guestChoiceUseGuest => 'Utiliser la progression d\'invité';

  @override
  String get chatJumpToLatest => 'Derniers messages';

  @override
  String get chatMessageGone => 'Ce message n\'est plus dans cette conversation.';

  @override
  String get chatListenOnlyPreview => 'Nouveau message — écoutez-le pour le copier';

  @override
  String get accountBackupMediaTitle => 'Inclure les enregistrements sauvegardés ?';

  @override
  String accountBackupMediaBody(int count, String size) {
    return '$count enregistrements sauvegardés ($size Mo). Titres, notes et positions sont toujours dans la sauvegarde ; l\'audio seulement si vous l\'incluez.';
  }

  @override
  String accountBackupMediaTooLarge(String size) {
    return 'Les enregistrements ($size Mo) sont trop volumineux pour la sauvegarde ; seuls titres, notes et positions sont inclus.';
  }

  @override
  String get accountBackupMediaInclude => 'Inclure les enregistrements';

  @override
  String get accountBackupMediaSkip => 'Sans les enregistrements';

  @override
  String get diagTitle => 'Diagnostic de connexion';

  @override
  String get diagOpenSubtitle => 'Pourquoi des messages attendent et comment se reconnecter';

  @override
  String get diagBannerDetails => 'Détails';

  @override
  String get diagSummaryNoIdentity => 'Aucune identité n\'est ouverte : il n\'y a pas de connexion à examiner.';

  @override
  String get diagSummaryOnlinePeerOnline => 'Vous êtes connecté au réseau Tox et ce contact est en ligne. Les messages lui parviennent directement.';

  @override
  String get diagSummaryOnlinePeerOffline => 'Vous êtes connecté, mais ce contact est hors ligne. Les messages attendent dans la boîte d\'envoi de cet appareil et partent dès que le contact revient en ligne.';

  @override
  String get diagSummaryOnline => 'Vous êtes connecté au réseau Tox.';

  @override
  String get diagSummaryConnecting => 'Connexion au réseau Tox en cours. Cela peut prendre une minute après le démarrage ou un changement de réseau.';

  @override
  String get diagSummaryOffline => 'Vous n\'êtes pas connecté au réseau Tox. Rien ne peut être envoyé ni reçu tant que la connexion n\'est pas rétablie.';

  @override
  String get diagLocalLabel => 'Votre connexion';

  @override
  String diagSinceChanged(String time) {
    return 'Depuis $time';
  }

  @override
  String diagSinceFirst(String time) {
    return 'Observé depuis $time';
  }

  @override
  String diagSinceResumed(String time) {
    return 'Observé depuis le retour dans l\'app à $time';
  }

  @override
  String get diagLastOnlineLabel => 'Dernière connexion observée';

  @override
  String get diagLastOnlineNow => 'Connecté maintenant';

  @override
  String get diagLastOnlineNone => 'Aucune connexion observée pour l\'instant.';

  @override
  String get diagLastOnlineHint => 'Moment où cet appareil a vu sa propre connexion pour la dernière fois. Ce n\'est pas l\'heure de réception d\'un message.';

  @override
  String get diagPeerLabel => 'Contact';

  @override
  String get diagUnknown => 'Inconnu';

  @override
  String get diagPeerUnknownHint => 'La présence d\'un contact n\'est visible que lorsque vous êtes connecté.';

  @override
  String get diagPeerGroupHint => 'La présence des membres est indiquée dans la liste des membres.';

  @override
  String get diagPendingLabel => 'En attente d\'envoi';

  @override
  String get diagPendingNone => 'Rien en attente';

  @override
  String diagPendingCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count messages',
      one: '1 message',
    );
    return '$_temp0';
  }

  @override
  String diagPendingOldest(String time) {
    return 'La plus ancienne, en attente depuis $time';
  }

  @override
  String get diagPendingUnknown => 'Inconnu tant que le chat n\'est pas connecté';

  @override
  String get diagPendingHint => 'Les messages en attente restent sur cet appareil et partent automatiquement quand le contact est joignable. Le diagnostic ne les supprime ni ne les renvoie jamais.';

  @override
  String get diagReconnect => 'Se reconnecter';

  @override
  String get diagReconnecting => 'Reconnexion…';

  @override
  String diagReconnectFailed(String reason) {
    return 'Échec de la reconnexion : $reason';
  }

  @override
  String get diagReconnectNote => 'La reconnexion relance la tentative de connexion. La mise en ligne peut encore prendre du temps ; cette page se met à jour à ce moment-là.';

  @override
  String get diagAboutTitle => 'Comment DitMesh se connecte';

  @override
  String get diagAboutBody => 'DitMesh n\'a pas de serveur. Votre appareil communique directement avec vos contacts via le réseau pair-à-pair Tox : vous devez être en ligne en même temps pour qu\'un message arrive. Les téléphones mettent les apps en pause en arrière-plan : DitMesh ne peut pas y rester connecté et se reconnecte à votre retour.';

  @override
  String get diagDetailsTitle => 'Détails techniques';

  @override
  String get diagDetailIdentity => 'Identité';

  @override
  String get diagDetailStatus => 'État';

  @override
  String get diagDetailObserved => 'Observé à';

  @override
  String get diagDetailQueued => 'Entrées en file';

  @override
  String get diagDetailError => 'Dernier code d\'erreur';

  @override
  String get backupXTitle => 'Sauvegarde chiffrée';

  @override
  String get backupXIntro => 'Choisissez ce que vous emportez sur un autre appareil. Le fichier entier est chiffré avec une phrase secrète définie ici.';

  @override
  String get backupXCategoryIdentity => 'Identité et profil Tox';

  @override
  String get backupXCategoryTraining => 'Progression et supports d\'entraînement';

  @override
  String get backupXCategoryChat => 'Historique des discussions, notes perso comprises';

  @override
  String get backupXCategoryMeta => 'Brouillons, épingles et signets';

  @override
  String get backupXCategoryPrefs => 'Préférences de l\'app';

  @override
  String get backupXPrefsHint => 'Lecture, notifications, apparence et langue. Jamais les positions de fenêtre ni les affectations de touches.';

  @override
  String get backupXCategoryMedia => 'Enregistrements sauvegardés';

  @override
  String get backupXMediaHint => 'Désactivé par défaut : les enregistrements peuvent être volumineux. Sans eux, seuls les titres et notes suivent.';

  @override
  String get backupXCategoryPending => 'Messages non envoyés';

  @override
  String get backupXPendingHint => 'Ils reviennent uniquement pour relecture et ne sont jamais envoyés automatiquement.';

  @override
  String get backupXRequired => 'Obligatoire';

  @override
  String backupXSizeLine(int count, String size) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count éléments',
      one: '1 élément',
    );
    return '$_temp0 · $size';
  }

  @override
  String backupXSizeKb(String size) {
    return '$size Ko';
  }

  @override
  String backupXSizeMb(String size) {
    return '$size Mo';
  }

  @override
  String backupXMediaTooLarge(String size) {
    return 'Trop volumineux pour être inclus ($size)';
  }

  @override
  String backupXInvitesNote(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count invitations de groupe en attente d\'amis hors ligne ne sont pas reprises.',
      one: '1 invitation de groupe en attente d\'un ami hors ligne n\'est pas reprise.',
    );
    return '$_temp0';
  }

  @override
  String get backupXIdentityPasswordNote => 'Le mot de passe de votre identité reste sur le profil : le nouvel appareil le demandera en plus de la phrase secrète.';

  @override
  String backupXTotal(String size) {
    return 'Environ $size au total';
  }

  @override
  String get backupXPassphrase => 'Phrase secrète de la sauvegarde';

  @override
  String get backupXPassphraseConfirm => 'Répétez la phrase secrète';

  @override
  String get backupXPassphraseHint => 'Au moins 8 caractères. Elle est distincte du mot de passe de votre identité et ne peut pas être récupérée.';

  @override
  String get backupXPassphraseTooShort => 'Utilisez au moins 8 caractères';

  @override
  String get backupXPassphraseMismatch => 'Les phrases secrètes ne correspondent pas';

  @override
  String get backupXExport => 'Créer la sauvegarde chiffrée';

  @override
  String get backupXExporting => 'Création de la sauvegarde…';

  @override
  String get backupXMigrationNote => 'Vous changez d\'appareil ? Après la restauration là-bas, n\'utilisez plus cette identité ici : deux appareils avec une même identité peuvent envoyer deux fois le même message.';

  @override
  String get backupXBusy => 'Vos données ont changé pendant la sauvegarde. Réessayez.';

  @override
  String get backupXTooLarge => 'La sauvegarde est trop volumineuse. Excluez les enregistrements et réessayez.';

  @override
  String get restoreXWrongPassphrase => 'Phrase secrète incorrecte, ou fichier modifié ou incomplet.';

  @override
  String get restoreXUnsupported => 'Cette sauvegarde provient d\'une version plus récente de DitMesh.';

  @override
  String get restoreXCheck => 'Ouvrir la sauvegarde';

  @override
  String get restoreXPreviewTitle => 'Contenu de la sauvegarde';

  @override
  String restoreXCreated(String date) {
    return 'Créée le $date';
  }

  @override
  String get restoreXIncluded => 'Inclus';

  @override
  String get restoreXExcluded => 'Absent de cette sauvegarde';

  @override
  String restoreXPendingIncluded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count messages non envoyés reviennent pour relecture. Ils ne seront pas envoyés automatiquement.',
      one: '1 message non envoyé revient pour relecture. Il ne sera pas envoyé automatiquement.',
    );
    return '$_temp0';
  }

  @override
  String restoreXPendingExcluded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count messages non envoyés de l\'ancien appareil ne sont pas dans cette sauvegarde.',
      one: '1 message non envoyé de l\'ancien appareil n\'est pas dans cette sauvegarde.',
    );
    return '$_temp0';
  }

  @override
  String get restoreXIdentityPassword => 'Mot de passe de l\'identité';

  @override
  String get restoreXIdentityPasswordNote => 'L\'identité de cette sauvegarde a son propre mot de passe. Saisissez-le aussi.';

  @override
  String get restoreXConfirmTitle => 'Remplacer l\'identité de cet appareil ?';

  @override
  String get restoreXConfirmBody => 'L\'identité et les données de cet appareil sont remplacées par la sauvegarde. Cessez d\'utiliser l\'identité sur l\'ancien appareil avant de vous connecter ici.';

  @override
  String get restoreXConfirm => 'Remplacer et restaurer';

  @override
  String get restoreXReportTitle => 'Restauration terminée';

  @override
  String get restoreXReportRestored => 'Restauré';

  @override
  String get restoreXReportNotIncluded => 'Non restauré';

  @override
  String get restoreXReportPrefsFailed => 'Les préférences n\'ont pas pu être appliquées ; les précédentes sont conservées.';

  @override
  String restoreXReportPendingReview(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count messages non envoyés attendent votre relecture dans Discussions.',
      one: '1 message non envoyé attend votre relecture dans Discussions.',
    );
    return '$_temp0';
  }

  @override
  String restoreXReportPendingNotResumed(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count messages non envoyés de l\'ancien appareil n\'ont pas été repris.',
      one: '1 message non envoyé de l\'ancien appareil n\'a pas été repris.',
    );
    return '$_temp0';
  }

  @override
  String restoreXReportInvites(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count invitations de groupe en attente n\'ont pas été renvoyées.',
      one: '1 invitation de groupe en attente n\'a pas été renvoyée.',
    );
    return '$_temp0';
  }

  @override
  String get restoreXReportStopOld => 'N\'utilisez plus cette identité sur l\'ancien appareil.';

  @override
  String get restoreXReportDone => 'Terminé';

  @override
  String pendingReviewBanner(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count messages non envoyés de votre ancien appareil',
      one: '1 message non envoyé de votre ancien appareil',
    );
    return '$_temp0';
  }

  @override
  String get pendingReviewTitle => 'Messages non envoyés';

  @override
  String get pendingReviewBody => 'Ils attendaient d\'être envoyés sur votre ancien appareil. DitMesh ne les envoie jamais automatiquement ; manipulez-en un à nouveau s\'il compte encore.';

  @override
  String pendingReviewQueuedAt(String time) {
    return 'En attente depuis $time sur l\'ancien appareil';
  }

  @override
  String get pendingReviewDismiss => 'Ignorer';

  @override
  String get pendingReviewDismissAll => 'Tout ignorer';

  @override
  String get pendingReviewEmpty => 'Plus rien à relire.';

  @override
  String get backupXWizardInside => 'Le fichier de sauvegarde est entièrement chiffré avec une phrase secrète de votre choix et contient la clé de votre identité et votre progression. Conservez le fichier et la phrase en lieu sûr, hors de cet appareil.';

  @override
  String get backupXMeSubtitle => 'Un fichier chiffré avec votre identité, vos discussions et votre progression, à garder ou à emporter sur un autre appareil';

  @override
  String get conditionsClear => 'Clair';

  @override
  String get conditionsLight => 'Légères perturbations';

  @override
  String get conditionsRadio => 'Pratique radio';

  @override
  String get conditionsClearHint => 'Une tonalité nette et stable : entraînement habituel.';

  @override
  String get conditionsLightHint => 'Léger bruit de fond et fading doux. Les résultats sont séparés de l\'entraînement clair.';

  @override
  String get conditionsRadioHint => 'Bruit, fading profond, une station voisine et un rythme légèrement irrégulier. Les résultats sont séparés de l\'entraînement clair.';

  @override
  String conditionsActive(String name) {
    return 'Conditions : $name';
  }

  @override
  String get conditionsNeedSound => 'Les conditions radio s\'entendent, elles ne se voient pas : activez le son dans les réglages d\'entraînement ou entraînez-vous en conditions claires.';

  @override
  String get conditionsCleanReplay => 'Écouter sans effets';

  @override
  String conditionsComparable(int count, int accuracy) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count essais dans ces conditions à cette vitesse : $accuracy % en moyenne',
      one: '1 essai dans ces conditions à cette vitesse : $accuracy %',
    );
    return '$_temp0';
  }

  @override
  String get conditionsSeparateNote => 'L\'entraînement en conditions radio compte comme activité mais ne modifie ni vos leçons, ni vos révisions, ni les conseils de vitesse.';

  @override
  String get keysTitle => 'Touches et manipulateurs externes';

  @override
  String get keysMeSubtitle => 'Affectation des touches, palettes et adaptateurs USB';

  @override
  String get keysIntro => 'Choisissez les touches qui manipulent le Morse. Les adaptateurs USB de manipulateur et de palettes qui émulent un clavier fonctionnent comme lui : définissez leurs touches ici. L\'app ne sait pas quel appareil a envoyé une touche ; un profil est donc un ensemble d\'affectations.';

  @override
  String get keysStandardProfile => 'Standard';

  @override
  String get keysUnnamed => 'Profil sans nom';

  @override
  String get keysEdit => 'Modifier';

  @override
  String get keysNewProfile => 'Nouveau profil';

  @override
  String get keysLimitations => 'Les manipulateurs MIDI, série et Bluetooth, les réglages du firmware des adaptateurs et la commande d\'émetteur ne sont pas pris en charge. Les adaptateurs testés figurent dans la documentation.';

  @override
  String get keysEditTitle => 'Profil de touches';

  @override
  String get keysName => 'Nom du profil';

  @override
  String get keysActionStraight => 'Manipulateur droit';

  @override
  String get keysActionDit => 'Palette point';

  @override
  String get keysActionDah => 'Palette trait';

  @override
  String get keysPressKey => 'Appuyez sur une touche…';

  @override
  String get keysNone => 'Non défini';

  @override
  String get keysSet => 'Définir';

  @override
  String keysReserved(String key) {
    return '$key est réservée par le système ou l\'app ; choisissez une autre touche.';
  }

  @override
  String keysConflict(String key, String action) {
    return '$key est déjà utilisée pour $action.';
  }

  @override
  String keysConflictSave(String keys) {
    return 'Chaque touche ne peut faire qu\'une chose : $keys est affectée deux fois.';
  }

  @override
  String get keysMissing => 'Définissez les touches requises par ce mode (les deux palettes en iambique).';

  @override
  String get keysSwapPaddles => 'Inverser les palettes (gaucher)';

  @override
  String get keysKeyerMode => 'Mode du manipulateur';

  @override
  String get keysIambicA => 'Iambique A';

  @override
  String get keysIambicB => 'Iambique B';

  @override
  String get keysAdapterKeyer => 'L\'adaptateur génère lui-même les éléments';

  @override
  String get keysAdapterKeyerHint => 'Pour un adaptateur doté de son propre manipulateur : ses appuis temporisés sont utilisés tels quels, sans second manipulateur iambique dans l\'app.';

  @override
  String get keysAppSidetone => 'Tonalité locale de l\'app en manipulant';

  @override
  String get keysAppSidetoneHint => 'Désactivez-la si l\'adaptateur produit sa propre tonalité. Le décodage n\'est pas affecté.';

  @override
  String get keysTestTitle => 'Test';

  @override
  String get keysTestNote => 'Test uniquement : rien n\'est envoyé ni ajouté à votre entraînement.';

  @override
  String get keysTestRelease => 'Relâcher les touches';

  @override
  String get keysAdapterActive => 'Le manipulateur de l\'adaptateur est utilisé : les touches de palette agissent comme un manipulateur droit.';

  @override
  String keysHintCustom(String keys) {
    return 'Touches : $keys';
  }

  @override
  String get telegraphCodebook => 'Code de référence';

  @override
  String get telegraphCodebookMainland => 'Chine continentale';

  @override
  String get telegraphCodebookTaiwan => 'Taïwan';

  @override
  String get telegraphInterpretAction => 'Interpréter comme code télégraphique chinois';

  @override
  String get telegraphInterpretTitle => 'Interprétation du code télégraphique';

  @override
  String get telegraphInterpretNote => 'Affiché ici seulement : le message n\'est pas modifié et rien n\'est envoyé.';

  @override
  String get telegraphUnresolved => 'Non résolu : aucun caractère n\'a ce code';

  @override
  String get telegraphMalformed => 'Pas un groupe de quatre chiffres';

  @override
  String get telegraphNotCode => 'Texte, laissé tel quel';

  @override
  String get telegraphAmbiguous => 'Plusieurs caractères partagent ce code';

  @override
  String get groupPracticeTitle => 'Entraînement de groupe';

  @override
  String get groupPracticeIntro => 'L\'instructeur manipule les exercices dans le chat du groupe comme d\'habitude. Chaque membre choisit ici un message d\'exercice et le copie à sa vitesse. Réponses et scores restent sur votre appareil ; rien n\'est envoyé au groupe.';

  @override
  String get groupPracticeNew => 'Nouvelle séance';

  @override
  String get groupPracticeTitleField => 'Titre';

  @override
  String get groupPracticeCreate => 'Créer';

  @override
  String get groupPracticeInstructor => 'Instructeur';

  @override
  String get groupPracticeParticipant => 'Participant';

  @override
  String get groupPracticeInstructorHint => 'Manipulez chaque exercice dans le chat du groupe, ajoutez-le ici comme manche et cochez-le ; annoncez les tours dans le chat.';

  @override
  String get groupPracticeParticipantHint => 'Ajoutez les messages d\'exercice de l\'instructeur comme manches et copiez-les ici.';

  @override
  String get groupPracticeLocalNote => 'Local uniquement : manches, rôles et résultats ne sont pas synchronisés, et les messages manqués peuvent ne jamais atteindre tout le monde.';

  @override
  String get groupPracticeAddRound => 'Ajouter un exercice';

  @override
  String get groupPracticeNoMessages => 'Aucun message adapté dans l\'historique récent.';

  @override
  String get groupPracticeNotConnected => 'L\'historique du groupe n\'est disponible qu\'une fois le chat connecté.';

  @override
  String get groupPracticeRoundOpen => 'À faire';

  @override
  String get groupPracticeRoundDone => 'Fait';

  @override
  String get groupPracticeRoundUnavailable => 'Indisponible';

  @override
  String get groupPracticeSourceGone => 'Le message d\'exercice n\'est plus dans l\'historique.';

  @override
  String get groupPracticeSourceLoading => 'Recherche du message…';

  @override
  String groupPracticeAttemptResult(int accuracy, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Copié : $accuracy % ($count essais)',
      one: 'Copié : $accuracy %',
    );
    return '$_temp0';
  }

  @override
  String get groupPracticeCopy => 'Copier';

  @override
  String get groupPracticeRemoveRound => 'Retirer la manche';

  @override
  String get groupPracticeSummary => 'Résumé';

  @override
  String groupPracticeRoundsDone(int done, int total) {
    return '$done manches sur $total faites';
  }

  @override
  String groupPracticeUnavailableCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count manches indisponibles',
      one: '1 manche indisponible',
    );
    return '$_temp0';
  }

  @override
  String groupPracticeAccuracy(int accuracy) {
    return 'Précision de copie : $accuracy %';
  }

  @override
  String groupPracticeAssisted(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count essais avec aide',
      one: '1 essai avec aide',
    );
    return '$_temp0';
  }

  @override
  String groupPracticeShareHint(int done, int total, int accuracy) {
    return 'Pour partager, manipulez vous-même votre résultat dans le chat du groupe, par ex. $done/$total $accuracy%. Rien n\'est envoyé automatiquement.';
  }

  @override
  String get groupPracticeComplete => 'Terminer la séance';

  @override
  String get groupPracticeDeleteTitle => 'Supprimer cette séance ?';

  @override
  String get groupPracticeDeleteBody => 'Ses manches et résultats locaux sont supprimés de cet appareil. Votre historique d\'entraînement et les messages du groupe restent.';

  @override
  String get conditionsAudioFailed => 'Le son n\'a pas pu démarrer sur cet appareil. Entraînez-vous plutôt en conditions claires.';

  @override
  String get moderationBlock => 'Bloquer';

  @override
  String moderationBlockTitle(String name) {
    return 'Bloquer $name ?';
  }

  @override
  String get moderationBlockFriendBody => 'Cette personne est retirée de vos amis et votre conversation est supprimée. Ses messages, demandes d’ami et invitations de groupe n’apparaissent plus sur cet appareil. Elle n’est pas prévenue.';

  @override
  String get moderationBlockMemberBody => 'Ses messages dans ce groupe n’apparaissent plus sur cet appareil. Elle n’est pas prévenue. Tox attribue à chaque membre une clé distincte par groupe : le blocage ne vaut que pour ce groupe.';

  @override
  String get moderationBlocked => 'Bloqué';

  @override
  String get moderationUnblock => 'Débloquer';

  @override
  String get moderationUnblocked => 'Débloqué';

  @override
  String get moderationBlockedTitle => 'Personnes bloquées';

  @override
  String get moderationBlockedSubtitle => 'Leurs messages, demandes et invitations sont masqués';

  @override
  String get moderationBlockedEmpty => 'Vous n’avez bloqué personne.';

  @override
  String get moderationBlockedNote => 'Le blocage agit sur cet appareil : Tox n’a pas de serveur central, les personnes bloquées peuvent donc encore essayer de vous joindre, mais rien d’elles ne s’affiche ici.';

  @override
  String get termsGateTitle => 'Règles de la communauté';

  @override
  String get termsGateIntro => 'Le chat DitMesh vous relie directement à d’autres personnes, sans serveur. Avant de commencer, acceptez ces règles :';

  @override
  String get termsGateRuleZero => 'Tolérance zéro : ni harcèlement, ni haine, ni menaces, ni contenu sexuel impliquant des mineurs, ni spam, ni rien d’illégal.';

  @override
  String get termsGateRuleContacts => 'Seules les personnes que vous acceptez peuvent vous écrire ; on rejoint un groupe sur invitation ou avec son identifiant.';

  @override
  String get termsGateRuleBlock => 'Bloquez n’importe qui depuis une conversation, la liste des membres d’un groupe, une demande d’ami ou une invitation.';

  @override
  String get termsGateAgree => 'Accepter et continuer';

  @override
  String get termsGateReadFull => 'Lire les conditions d’utilisation complètes';

  @override
  String get termsGateSaveFailed => 'Votre réponse n’a pas pu être enregistrée. Réessayez.';

  @override
  String get aboutPrivacyPolicy => 'Politique de confidentialité';

  @override
  String get aboutTermsOfUse => 'Conditions d’utilisation';

  @override
  String get aboutSupport => 'Assistance et contact';

  @override
  String get aboutLinkFailed => 'Le lien n’a pas pu s’ouvrir ; il a été copié.';

  @override
  String get errorPeerBlocked => 'Vous avez bloqué cette personne. Débloquez-la d’abord dans Moi → Personnes bloquées.';

  @override
  String get offlineClearData => 'Effacer les données d’apprentissage';

  @override
  String get offlineClearDataBody => 'Supprime votre progression, vos plans et vos supports sur cet appareil.';

  @override
  String get offlineCleared => 'Données d’apprentissage effacées.';

  @override
  String get offlineClearFailed => 'Impossible d’effacer les données d’apprentissage.';

  @override
  String get learnStorageUnavailable => 'Vos données d’entraînement n’ont pas pu être ouvertes sur cet appareil. Réessayez.';

  @override
  String get backendStartupFailedTitle => 'Service de discussion indisponible';

  @override
  String get backendStartupFailedBody => 'DitMesh n’a pas pu démarrer le service réseau Tox. Vérifiez que les bibliothèques natives sont installées, puis réessayez.';

  @override
  String get bootstrapTitle => 'Réseau et amorçage';

  @override
  String get bootstrapDescription => 'Choisissez les nœuds publics pour rejoindre le réseau Tox.';

  @override
  String get bootstrapModeAuto => 'Automatique';

  @override
  String get bootstrapModeManual => 'Manuel';

  @override
  String get bootstrapModeLan => 'Hôte LAN';

  @override
  String get bootstrapAutoDescription => 'Démarrer avec les nœuds intégrés et actualiser la liste officielle en arrière-plan.';

  @override
  String get bootstrapManualDescription => 'Utiliser uniquement le nœud choisi. Vous pouvez aussi saisir un nœud LAN ici.';

  @override
  String get bootstrapLanDescription => 'Exécuter un nœud UDP/DHT local sur cet ordinateur pour les autres appareils du LAN.';

  @override
  String get bootstrapCurrentNode => 'Nœud actuel';

  @override
  String get bootstrapHost => 'Hôte ou adresse IP';

  @override
  String get bootstrapPort => 'Port UDP';

  @override
  String get bootstrapPublicKey => 'Clé publique DHT';

  @override
  String get bootstrapTestNode => 'Tester le nœud';

  @override
  String get bootstrapSaveNode => 'Utiliser le nœud testé';

  @override
  String get bootstrapChooseNode => 'Choisir un nœud public';

  @override
  String get bootstrapReachable => 'Réponse DHT reçue';

  @override
  String get bootstrapUnreachable => 'Aucune réponse DHT';

  @override
  String get bootstrapInvalid => 'Hôte, port ou clé publique invalide';

  @override
  String get bootstrapUdpUnavailable => 'Cet appareil ne peut pas effectuer le test UDP. La connexion TCP n’a pas été testée.';

  @override
  String get bootstrapProbeUnavailable => 'Le test n’a pas pu démarrer. Cela ne renseigne pas sur l’accessibilité du nœud.';

  @override
  String get bootstrapFallback => 'La liste officielle n’a pas pu être chargée. Affichage des nœuds de secours intégrés.';

  @override
  String get bootstrapMaintainer => 'Responsable';

  @override
  String get bootstrapLocation => 'Emplacement';

  @override
  String get bootstrapLastPing => 'Dernière vérification publique';

  @override
  String get bootstrapSwitchTitle => 'Changer de nœud d’amorçage';

  @override
  String get bootstrapSwitchQuestion => 'Utiliser ce nœud ?';

  @override
  String get bootstrapNotTestedWarning => 'Ce nœud n’a pas encore été testé sur votre appareil.';

  @override
  String get bootstrapFailedWarning => 'Ce nœud n’a pas répondu au test UDP. Vous pouvez tout de même le choisir.';

  @override
  String get bootstrapInconclusiveWarning => 'Le test n’est pas concluant. La connexion TCP n’a pas été testée.';

  @override
  String get bootstrapSwitchConfirm => 'Utiliser le nœud';

  @override
  String get bootstrapRefresh => 'Actualiser la liste';

  @override
  String get bootstrapStartLan => 'Démarrer le nœud LAN';

  @override
  String get bootstrapStopLan => 'Arrêter le nœud LAN';

  @override
  String get bootstrapLanStopped => 'Nœud LAN arrêté';

  @override
  String get bootstrapLanRunning => 'Nœud LAN en cours';

  @override
  String get bootstrapLanKeyChanges => 'La clé DHT change au redémarrage. Partagez la clé complète actuelle.';

  @override
  String get bootstrapLanFirewallHint => 'Les autres appareils doivent pouvoir accéder à ce port UDP via le pare-feu local.';

  @override
  String get bootstrapCopyNode => 'Copier les détails du nœud';

  @override
  String get bootstrapShareNode => 'Partager les détails du nœud';

  @override
  String get bootstrapOperationFailed => 'Le paramètre réseau n’a pas pu être appliqué.';

  @override
  String get bootstrapServiceUnavailable => 'Les réglages réseau sont indisponibles pour ce moteur.';

  @override
  String get bootstrapSource => 'Liste officielle des nœuds publics';

  @override
  String get bootstrapOnline => 'En ligne';

  @override
  String get bootstrapOffline => 'Hors ligne';

  @override
  String bootstrapProtocolStatus(String udp, String tcp) {
    return 'UDP : $udp · TCP : $tcp';
  }

  @override
  String get errorNotFriend => 'Cette personne ne figure plus dans votre liste d\'amis. Ajoutez-la à nouveau pour lui envoyer des messages.';

  @override
  String get chatAcceptWithPassword => 'Accepter avec un mot de passe';

  @override
  String chatGroupPasswordTitle(String name) {
    return 'Mot de passe de $name';
  }

  @override
  String get chatGroupPasswordField => 'Mot de passe du groupe';

  @override
  String chatGroupJoinRefusedPassword(String name) {
    return '$name a refusé l\'adhésion : le mot de passe est incorrect ou manquant.';
  }

  @override
  String chatGroupJoinRefusedFull(String name) {
    return '$name a refusé l\'adhésion : le groupe est complet.';
  }

  @override
  String chatGroupJoinRefused(String name) {
    return '$name a refusé l\'adhésion.';
  }

  @override
  String chatGroupReconnectRefused(String name) {
    return '$name a refusé la reconnexion. L\'historique est conservé ; réessayez avec le mot de passe du groupe.';
  }

  @override
  String get firstChatTitle => 'Votre premier chat Morse';

  @override
  String get firstChatStart => 'Commencer';

  @override
  String get firstChatDismiss => 'Fermer le guide';

  @override
  String get firstChatKeyTitle => '1. Envoyez-vous CQ';

  @override
  String get firstChatKeyBody => 'Tapez CQ avec la clé : une pression courte produit un point, une longue un trait. Le brouillon décodé reste en lecture seule.';

  @override
  String get firstChatSelf => 'Essayer dans mon chat personnel';

  @override
  String get firstChatListenTitle => '2. Écoutez et corrigez';

  @override
  String get firstChatListenBody => 'Avant l’envoi, écoutez l’aperçu et effacez les erreurs. Ensuite, appuyez sur Lecture sur le message. Les messages personnels restent sur cet appareil.';

  @override
  String get firstChatFriendTitle => '3. Discutez avec un ami';

  @override
  String get firstChatFriendBody => 'Ouvrez Contacts, ajoutez un ami par QR ou Tox ID, puis attendez son accord.';

  @override
  String get firstChatFriend => 'Ajouter un ami';

  @override
  String get firstChatOnline => 'Les deux applications doivent fonctionner et être connectées pour livrer les messages.';

  @override
  String get pendingMessagesTitle => 'Messages en attente et en échec';

  @override
  String get pendingMessagesExplanation => 'Les messages restent sur cet appareil jusqu’à la connexion des deux applications. Vous pouvez les annuler ou réessayer après un échec confirmé.';

  @override
  String get pendingMessagesEmpty => 'Aucun message en attente ou en échec';

  @override
  String get deliveryDetailsTitle => 'Détails de livraison';

  @override
  String get deliveryLocalTitle => 'Enregistré localement';

  @override
  String get deliveryLocalDetail => 'Ce message personnel est enregistré sur cet appareil.';

  @override
  String get deliverySentDetail => 'L’application a transmis le message au transport et attend la confirmation du destinataire.';

  @override
  String get deliveryPeerTitle => 'Réception confirmée';

  @override
  String get deliveryPeerDetail => 'Le destinataire a confirmé la réception. La lecture ou l’écoute n’est pas confirmée.';

  @override
  String get deliveryGroupTitle => 'Reçu par un membre';

  @override
  String get deliveryGroupDetail => 'Au moins un membre a confirmé la réception. Les autres peuvent encore être hors ligne.';

  @override
  String get deliveryLocalOffline => 'Cet appareil n’est pas encore connecté.';

  @override
  String get deliveryPeerOffline => 'Votre ami est hors ligne.';

  @override
  String get deliveryGroupWaiting => 'En attente de connexion au groupe.';

  @override
  String get chatPreviewDraft => 'Écouter le brouillon';

  @override
  String get chatStopPreview => 'Arrêter l’écoute';

  @override
  String get chatMessagePlayback => 'Lecture du message';

  @override
  String get chatOriginalRhythm => 'Rythme de manipulation original';

  @override
  String get chatListenerRhythm => 'Votre vitesse d’écoute';

  @override
  String get chatOriginalAvailable => 'Les impulsions et pauses réelles sont enregistrées.';

  @override
  String get chatOriginalUnavailable => 'Rythme original indisponible ; lecture à votre vitesse.';

  @override
  String get chatOriginalPlaying => 'Lecture du rythme original';

  @override
  String get chatListenerPlaying => 'Lecture à votre vitesse';

  @override
  String get chatPause => 'Pause';

  @override
  String get chatResume => 'Reprendre';

  @override
  String get chatPreviousWord => 'Mot précédent';

  @override
  String get chatNextWord => 'Mot suivant';

  @override
  String chatWordNumber(int number) {
    return 'Mot $number';
  }

  @override
  String get chatRangeStart => 'Premier mot';

  @override
  String get chatRangeEnd => 'Dernier mot';

  @override
  String get chatRepeatRange => 'Rejouer les mots sélectionnés';

  @override
  String get chatLoopRange => 'Répéter les mots en boucle';

  @override
  String get chatPlaybackProgress => 'Progression de lecture';

  @override
  String chatWordProgress(int current, int total) {
    return 'Mot $current sur $total';
  }

  @override
  String get chatOriginalPreference => 'Utiliser le rythme original si un enregistrement correspondant est disponible.';

  @override
  String chatConversationActions(String name) {
    return 'Actions pour $name';
  }

  @override
  String get chatDraftSaveFailed => 'Le brouillon n\'a pas pu être enregistré. Gardez cet écran ouvert ou envoyez-le maintenant.';

  @override
  String get chatSearchClearDates => 'Effacer la plage de dates';

  @override
  String chatGroupReconnectFailed(String name) {
    return '$name a refusé la reconnexion. L\'historique est conservé ; vous pouvez réessayer.';
  }
}
