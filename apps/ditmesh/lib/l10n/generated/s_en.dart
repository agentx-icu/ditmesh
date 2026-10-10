// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 's.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class SEn extends S {
  SEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'DitMesh';

  @override
  String get navLearn => 'Learn';

  @override
  String get navChat => 'Chat';

  @override
  String get navGroups => 'Groups';

  @override
  String get navMe => 'Me';

  @override
  String get navReference => 'Reference';

  @override
  String get navChatDescription => 'Serverless one-to-one Morse conversations over Tox P2P.';

  @override
  String get navGroupsDescription => 'Group nets — many operators keying on one shared channel.';

  @override
  String get navReferenceDescription => 'Alphabet, prosigns, Q-codes, abbreviations and a two-way translator.';

  @override
  String get navMeDescription => 'Your callsign, Tox identity, progress and settings.';

  @override
  String get shellOfflineBanner => 'Offline: not connected to the Tox network. Messages will be sent when you are back online.';

  @override
  String get actionOk => 'OK';

  @override
  String get actionCancel => 'Cancel';

  @override
  String get actionSave => 'Save';

  @override
  String get actionDelete => 'Delete';

  @override
  String get actionCopy => 'Copy';

  @override
  String get actionShare => 'Share';

  @override
  String get actionRetry => 'Retry';

  @override
  String get actionClose => 'Close';

  @override
  String get actionSearch => 'Search';

  @override
  String get actionSettings => 'Settings';

  @override
  String get connectionConnecting => 'Connecting…';

  @override
  String get connectionOnline => 'Online';

  @override
  String get connectionOffline => 'Offline';

  @override
  String get messageStatusPending => 'Queued on this device';

  @override
  String get messageStatusPendingDetail => 'The message is saved locally. It will send when both apps are running and their networks can connect.';

  @override
  String get messageStatusSending => 'Sending';

  @override
  String get messageStatusSent => 'Sent';

  @override
  String get messageStatusFailed => 'Failed to send';

  @override
  String get errorWrongPassword => 'Wrong password. Try again.';

  @override
  String get errorPeerOffline => 'This contact is offline. Tox has no server, so the message waits until they come back.';

  @override
  String get errorInvalidToxId => 'That is not a valid Tox ID (76 hex characters).';

  @override
  String get errorAlreadyFriend => 'This Tox ID is already in your friend list.';

  @override
  String get errorOwnId => 'That is your own Tox ID.';

  @override
  String get errorGroupNotFound => 'Group not found.';

  @override
  String get errorMessageTooLong => 'Message is too long for one Tox message.';

  @override
  String get errorUnknown => 'Something went wrong';

  @override
  String get errorTeardownUnconfirmed => 'The previous Tox session has not fully stopped. Try again in a moment, or restart the app.';

  @override
  String get errorIdentityRecoveryPending => 'A previous identity is still waiting to be recovered. Restart the app to retry, or delete the identity data to start over.';

  @override
  String get languageTitle => 'Language';

  @override
  String get languageSystemDefault => 'System default';

  @override
  String get languageSaveFailed => 'Couldn\'t save the language setting. Try again.';

  @override
  String learnLessonOf(int lesson, int total) {
    return 'Lesson $lesson of $total';
  }

  @override
  String learnRoundScore(int correct, int total) {
    return '$correct of $total correct';
  }

  @override
  String learnRoundOf(int round) {
    return 'Round $round';
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
      other: '$count characters sent',
      one: '1 character sent',
    );
    return '$_temp0';
  }

  @override
  String learnLessonUnlocked(String char) {
    return 'Next character unlocked: $char';
  }

  @override
  String learnConfusedMissed(String target) {
    return '$target missed';
  }

  @override
  String learnConfusedAs(String target, String answered) {
    return '$target heard as $answered';
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
      other: '$count characters',
      one: '1 character',
    );
    return '$_temp0';
  }

  @override
  String statsDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days',
      one: '1 day',
    );
    return '$_temp0';
  }

  @override
  String statsTrendSubtitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Last $count sessions',
      one: 'Last session',
    );
    return '$_temp0';
  }

  @override
  String referenceEntryCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count entries',
      one: '1 entry',
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
    return 'Skipped (no Morse code): $chars';
  }

  @override
  String referenceKochPositionValue(int position) {
    return 'Koch position: $position';
  }

  @override
  String referenceEstimatedSpeed(String wpm) {
    return 'Estimated $wpm WPM';
  }

  @override
  String get accountCopied => 'Tox ID copied to clipboard';

  @override
  String get accountShowQr => 'Show QR code';

  @override
  String get accountToxId => 'Tox ID';

  @override
  String get accountDisplayName => 'Display name';

  @override
  String get accountDisplayNameHint => 'Your callsign or nickname';

  @override
  String get accountDisplayNameRequired => 'Enter a display name';

  @override
  String get accountStatusMessage => 'Status message';

  @override
  String get accountPassword => 'Password';

  @override
  String get accountPasswordOptional => 'Password (optional)';

  @override
  String get accountConfirmPassword => 'Confirm password';

  @override
  String get accountPasswordsDoNotMatch => 'Passwords do not match';

  @override
  String get accountShowPassword => 'Show password';

  @override
  String get accountHidePassword => 'Hide password';

  @override
  String get accountStrengthWeak => 'Weak: use at least 8 characters';

  @override
  String get accountStrengthFair => 'Fair: 12+ characters with mixed types is better';

  @override
  String get accountStrengthStrong => 'Strong';

  @override
  String get accountStartupInspecting => 'Checking your identity…';

  @override
  String get accountStartupOpening => 'Opening your identity…';

  @override
  String get accountStartupFailedTitle => 'Could not start';

  @override
  String get accountStartupFailedBody => 'DitMesh could not read your identity. Nothing was changed; you can try again.';

  @override
  String get accountConnectionTapToReconnect => 'Tap to reconnect';

  @override
  String get accountWelcomeTitle => 'Your identity lives on this device';

  @override
  String get accountWelcomeIntro => 'DitMesh uses the Tox peer-to-peer network. There is no server and no account to sign up for: your identity is a key pair stored only here.';

  @override
  String get accountWelcomePointNoServer => 'No server, no phone number, no e-mail. Peers talk to each other directly, in Morse.';

  @override
  String get accountWelcomePointTraining => 'Chat one-to-one or in groups using Morse code, with a straight key or iambic paddles.';

  @override
  String get accountWelcomePointBackup => 'Nobody can recover an identity for you. Back it up right after creating it, or you will lose it with the device.';

  @override
  String get accountCreateIdentity => 'Create identity';

  @override
  String get accountRestoreFromBackup => 'Restore from backup';

  @override
  String get accountCreateTitle => 'Create your identity';

  @override
  String get accountCreateBody => 'Pick a name others will see. A password encrypts the identity file on this device; leave it empty if you prefer to open the app without one.';

  @override
  String get accountCreateButton => 'Create';

  @override
  String get accountCreating => 'Creating…';

  @override
  String get accountBackupTitle => 'Back up your identity now';

  @override
  String get accountBackupBody => 'Your identity exists only on this device. If it is lost, reset or stolen, there is no way to recover it: your contacts will not recognise a new identity and your training progress is gone.';

  @override
  String get accountBackupWhatIsInside => 'The backup file contains your identity key, encrypted with your password, and your training progress. Keep it somewhere safe, outside this device.';

  @override
  String get accountBackupWhatIsInsidePlain => 'The backup file contains your identity key unencrypted, and your training progress. Anyone who gets this file can use your identity: set a password first if you want the key encrypted, and keep the file somewhere safe.';

  @override
  String get accountPasswordScope => 'Your password encrypts your identity key. Message history remains unencrypted on disk; device encryption can protect it.';

  @override
  String get accountSectionNotifications => 'Notifications';

  @override
  String get accountNotificationsEnable => 'Show notifications';

  @override
  String get accountNotificationsEnableSubtitle => 'New messages, friend requests and group invites';

  @override
  String get accountNotificationsContent => 'Show message content';

  @override
  String get accountNotificationsContentSubtitle => 'Text and Morse in banners and on the lock screen. Off: only that a message arrived.';

  @override
  String get accountNotificationsAllow => 'Allow notifications';

  @override
  String get accountNotificationsAllowSubtitle => 'Ask the system for permission';

  @override
  String get accountNotificationsBlocked => 'Blocked in system settings';

  @override
  String get accountNotificationsBlockedSubtitle => 'Message notifications for DitMesh are turned off in the system settings. Turn them on there to get banners again.';

  @override
  String get accountNotificationsDenied => 'Notifications are off for DitMesh in the system settings.';

  @override
  String get accountBackupSaveFile => 'Save backup file';

  @override
  String get accountBackupShareFile => 'Share backup file';

  @override
  String get accountBackupSaved => 'Backup saved';

  @override
  String get accountBackupNotSaved => 'Backup was not saved';

  @override
  String get accountBackupFailed => 'Could not write the backup';

  @override
  String get accountBackupAcknowledge => 'I understand that without this backup my identity cannot be recovered.';

  @override
  String get accountBackupContinue => 'Continue to DitMesh';

  @override
  String get accountBackupShowQrHint => 'Your Tox ID is how friends add you. Share it as text or as a QR code.';

  @override
  String get accountRestoreTitle => 'Restore from backup';

  @override
  String get accountRestoreBody => 'Choose a backup file exported from DitMesh. If the identity was protected with a password you will need it here.';

  @override
  String get accountRestoreChooseFile => 'Choose backup file';

  @override
  String get accountRestoreNoFile => 'Choose a backup file first';

  @override
  String get accountRestoreButton => 'Restore';

  @override
  String get accountRestoring => 'Restoring…';

  @override
  String get accountRestoreInvalidFile => 'This file is not a DitMesh backup.';

  @override
  String get accountRestoreReplacesWarning => 'Restoring replaces the identity currently on this device.';

  @override
  String get accountUnlockTitle => 'Unlock your identity';

  @override
  String get accountUnlockBody => 'Your identity file is encrypted. Enter the password to continue.';

  @override
  String get accountUnlockButton => 'Unlock';

  @override
  String get accountUnlocking => 'Unlocking…';

  @override
  String get accountUnlockRestoreInstead => 'Restore from backup instead';

  @override
  String get accountMeNoIdentity => 'No identity loaded';

  @override
  String get accountSectionAccount => 'Account';

  @override
  String get accountSectionTraining => 'Training';

  @override
  String get accountSectionAbout => 'About';

  @override
  String get accountSectionDanger => 'Danger zone';

  @override
  String get accountEditProfile => 'Edit profile';

  @override
  String get accountEditProfileBody => 'Shown to your contacts on the Tox network.';

  @override
  String get accountSetPassword => 'Set password';

  @override
  String get accountChangePassword => 'Change password';

  @override
  String get accountRemovePassword => 'Remove password';

  @override
  String get accountCurrentPassword => 'Current password';

  @override
  String get accountNewPassword => 'New password';

  @override
  String get accountPasswordUpdated => 'Password updated';

  @override
  String get accountPasswordRemoved => 'Password removed';

  @override
  String get accountProfileUpdated => 'Profile updated';

  @override
  String get accountExportBackup => 'Export backup';

  @override
  String get accountExportBackupSubtitle => 'Save your identity and training progress to a file';

  @override
  String get accountTrainingDefaults => 'Playback & training defaults';

  @override
  String get accountTrainingDefaultsSubtitle => 'Speed, tone, Farnsworth spacing';

  @override
  String get accountTrainingDefaultsPlaceholder => 'Speed, tone and Farnsworth defaults will live here.';

  @override
  String get accountAboutLicence => 'Licence';

  @override
  String get accountAboutLicenceValue => 'GPL-3.0';

  @override
  String get accountAboutSource => 'Source code';

  @override
  String get accountAboutSourceCopied => 'Source link copied';

  @override
  String get accountAboutBackend => 'Backend';

  @override
  String get accountDeleteIdentity => 'Delete identity';

  @override
  String get accountDeleteIdentitySubtitle => 'Erase this identity, history and progress from this device';

  @override
  String get accountDeleteDialogTitle => 'Delete this identity?';

  @override
  String get accountDeleteDialogBody => 'This removes your identity, chat history and training progress from this device. Without a backup it cannot be recovered. Type DELETE to confirm.';

  @override
  String get accountDeleteConfirmWord => 'DELETE';

  @override
  String get accountDeleteConfirmHint => 'Type DELETE';

  @override
  String get accountDeleteButton => 'Delete';

  @override
  String get accountRecoveryPendingDiscard => 'Discard the waiting identity and start over';

  @override
  String accountRestoreFileChosenSize(int bytes) {
    return 'Backup file selected ($bytes bytes)';
  }

  @override
  String get chatSearchConversations => 'Search conversations';

  @override
  String get chatNoConversations => 'No conversations yet';

  @override
  String get chatNoSearchResults => 'No conversations match';

  @override
  String get chatPin => 'Pin';

  @override
  String get chatUnpin => 'Unpin';

  @override
  String get chatMarkRead => 'Mark as read';

  @override
  String get chatDelete => 'Delete';

  @override
  String get chatDeleteConversationTitle => 'Delete conversation?';

  @override
  String get chatDeleteConversationBody => 'Local history for this conversation is removed. Tox keeps no copy.';

  @override
  String get chatDraftPrefix => 'Draft: ';

  @override
  String get chatSelectConversation => 'Select a conversation';

  @override
  String get chatContacts => 'Contacts';

  @override
  String get chatNoMessages => 'No messages yet — send CQ to start.';

  @override
  String get chatTrainingMode => 'Training mode';

  @override
  String get chatTrainingModeOn => 'Training mode on: text hidden';

  @override
  String get chatTrainingModeOff => 'Training mode off';

  @override
  String get chatAutoPlay => 'Auto-play received Morse';

  @override
  String get chatAutoPlayOn => 'Auto-play on: new messages play as they arrive';

  @override
  String get chatAutoPlayOff => 'Auto-play off';

  @override
  String get chatReveal => 'Reveal';

  @override
  String get chatHiddenText => 'Listen first, then reveal';

  @override
  String get chatPlay => 'Play Morse';

  @override
  String get chatStop => 'Stop';

  @override
  String get chatPlaybackSettings => 'Playback settings';

  @override
  String get chatCharacterSpeed => 'Character speed';

  @override
  String get chatFarnsworthSpeed => 'Farnsworth speed';

  @override
  String get chatTone => 'Tone';

  @override
  String get chatWpm => 'WPM';

  @override
  String get chatHz => 'Hz';

  @override
  String get chatMembers => 'Members';

  @override
  String get chatLeaveGroup => 'Leave group';

  @override
  String get chatLeaveGroupTitle => 'Leave this group?';

  @override
  String get chatLeaveGroupBody => 'You will stop receiving messages. Rejoin later with the chat id.';

  @override
  String get chatLeave => 'Leave';

  @override
  String get chatConferenceNote => 'Legacy conference: Morse keying metadata (v2) will not be available here. Text still works.';

  @override
  String get chatClearHistory => 'Clear history';

  @override
  String get chatModeStraightKey => 'Straight key';

  @override
  String get chatModePaddles => 'Paddles';

  @override
  String get chatKeyMessage => 'Key your message';

  @override
  String get chatSend => 'Send';

  @override
  String get chatTooLong => 'Too long for one Tox message';

  @override
  String get chatKeyHint => 'Key on the pad or press Space';

  @override
  String get chatPaddleHint => 'Tap the paddles or hold Ctrl (left dit, right dah)';

  @override
  String get chatDeleteLast => 'Delete last character';

  @override
  String get chatNoFriends => 'No friends yet. Add one with their Tox ID.';

  @override
  String get chatNoRequests => 'No pending requests';

  @override
  String get chatAddFriend => 'Add friend';

  @override
  String get chatMyToxId => 'My Tox ID';

  @override
  String get chatToxIdLabel => 'Tox ID (76 hex characters)';

  @override
  String get chatToxIdInvalid => 'Tox ID must be exactly 76 hex characters';

  @override
  String get chatToxIdOwn => 'That is your own Tox ID';

  @override
  String get chatToxIdAlreadyFriend => 'Already in your friend list';

  @override
  String get chatRequestMessage => 'Message';

  @override
  String get chatDefaultRequestMessage => 'DitMesh CQ';

  @override
  String get chatSendRequest => 'Send request';

  @override
  String get chatRequestSent => 'Friend request sent';

  @override
  String get chatScanQr => 'Scan QR';

  @override
  String get chatScanQrDesktopHint => 'QR scanning needs a phone camera';

  @override
  String get chatScanQrTitle => 'Scan a Tox ID';

  @override
  String get chatScanQrNotToxId => 'That QR code is not a Tox ID';

  @override
  String get chatAccept => 'Accept';

  @override
  String get chatReject => 'Reject';

  @override
  String get chatCopied => 'Copied to clipboard';

  @override
  String get chatNoIdentity => 'No identity loaded';

  @override
  String get chatRemoveFriend => 'Remove friend';

  @override
  String get chatRemoveFriendTitle => 'Remove this friend?';

  @override
  String get chatRemoveFriendBody => 'They will no longer be able to message you.';

  @override
  String get chatRemove => 'Remove';

  @override
  String get chatNoGroups => 'No groups yet. Create one or join by chat id.';

  @override
  String get chatCreateGroup => 'Create group';

  @override
  String get chatJoinGroup => 'Join group';

  @override
  String get chatGroupName => 'Group name';

  @override
  String get chatGroupNameRequired => 'Give the group a name';

  @override
  String get chatAdvanced => 'Advanced';

  @override
  String get chatLegacyConference => 'Legacy conference (old clients)';

  @override
  String get chatLegacyConferenceHint => 'Not recommended: no persistent chat id, no Morse metadata.';

  @override
  String get chatCreate => 'Create';

  @override
  String get chatChatIdLabel => 'Chat id (64 hex characters)';

  @override
  String get chatChatIdInvalid => 'Chat id must be exactly 64 hex characters';

  @override
  String get chatPassword => 'Password (optional)';

  @override
  String get chatJoin => 'Join';

  @override
  String get chatJoinRequested => 'Joining — the group appears once a peer is found.';

  @override
  String get chatConferenceBadge => 'Conference';

  @override
  String get chatCopyChatId => 'Copy chat id';

  @override
  String get learnContinueLesson => 'Continue lesson';

  @override
  String get learnSettings => 'Training settings';

  @override
  String get learnLoading => 'Loading your progress...';

  @override
  String get learnIdentityRequired => 'Create or unlock your identity to start training. Progress is stored with your identity so it travels with your backup.';

  @override
  String get learnProgressSaveFailed => 'Couldn\'t save your progress. The result still counts while DitMesh stays open.';

  @override
  String get toolsTitle => 'Radio tools';

  @override
  String get toolsGridTitle => 'Grid locator';

  @override
  String get toolsGridHint => 'Locator from coordinates, distance and beam heading';

  @override
  String get toolsBandsTitle => 'Bands & antennas';

  @override
  String get toolsBandsHint => 'Which band a frequency is in, wavelength, dipole length';

  @override
  String get toolsSpeedTitle => 'CW speed';

  @override
  String get toolsSpeedHint => 'WPM to dit length, gaps and characters per minute';

  @override
  String get toolsRstTitle => 'RST report';

  @override
  String get toolsRstHint => 'Build a signal report and see what each digit means';

  @override
  String get toolsClockTitle => 'UTC clock';

  @override
  String get toolsClockHint => 'Log time in UTC, next to your local time';

  @override
  String get toolsGridFromCoordinates => 'From coordinates';

  @override
  String get toolsGridLatitude => 'Latitude';

  @override
  String get toolsGridLongitude => 'Longitude';

  @override
  String get toolsGridCoordinatesHelp => 'Decimal degrees; south and west are negative';

  @override
  String get toolsGridInvalidCoordinates => 'Latitude -90 to 90, longitude -180 to 180';

  @override
  String get toolsGridLocator => 'Locator';

  @override
  String get toolsGridDistanceSection => 'Distance and heading';

  @override
  String get toolsGridMine => 'My locator';

  @override
  String get toolsGridTheirs => 'Their locator';

  @override
  String get toolsGridInvalidLocator => 'Use 2, 4, 6 or 8 characters, e.g. OM89ex';

  @override
  String get toolsGridCenter => 'Square centre';

  @override
  String get toolsGridDistance => 'Distance';

  @override
  String get toolsGridShortPath => 'Short-path heading';

  @override
  String get toolsGridLongPath => 'Long-path heading';

  @override
  String get toolsBandsFrequency => 'Frequency (MHz)';

  @override
  String get toolsBandsInvalidFrequency => 'Enter a frequency above 0';

  @override
  String toolsBandsRegionLabel(int number) {
    return 'Region $number';
  }

  @override
  String get toolsBandsRegionHelp => '1: Europe, Africa, Middle East - 2: the Americas - 3: Asia-Pacific';

  @override
  String toolsBandsInBand(String band) {
    return 'In the $band amateur band';
  }

  @override
  String get toolsBandsOutOfBand => 'Outside the amateur bands';

  @override
  String get toolsBandsWavelength => 'Wavelength';

  @override
  String get toolsBandsDipole => 'Half-wave dipole (total)';

  @override
  String get toolsBandsQuarterWave => 'Quarter-wave vertical';

  @override
  String get toolsBandsAntennaNote => 'Lengths include a 0.95 end factor; trim to resonance.';

  @override
  String get toolsBandsTable => 'Band edges';

  @override
  String toolsBandsQrp(String frequency) {
    return 'QRP CW $frequency';
  }

  @override
  String get toolsBandsDisclaimer => 'ITU allocations. Your licence and national band plan may be narrower.';

  @override
  String get toolsSpeedCharacter => 'Character speed';

  @override
  String get toolsSpeedFarnsworth => 'Farnsworth spacing';

  @override
  String get toolsSpeedOverall => 'Overall speed';

  @override
  String get toolsSpeedDit => 'Dit';

  @override
  String get toolsSpeedDah => 'Dah';

  @override
  String get toolsSpeedCharGap => 'Gap between characters';

  @override
  String get toolsSpeedWordGap => 'Gap between words';

  @override
  String get toolsSpeedCpm => 'Characters per minute';

  @override
  String get toolsSpeedParis => 'One PARIS word';

  @override
  String get toolsRstReadability => 'Readability (R)';

  @override
  String get toolsRstStrength => 'Strength (S)';

  @override
  String get toolsRstTone => 'Tone (T)';

  @override
  String get toolsRstReport => 'Report';

  @override
  String get toolsRstCut => 'Contest form';

  @override
  String get toolsRstPhone => 'On voice (no tone)';

  @override
  String get toolsRstR1 => 'Unreadable';

  @override
  String get toolsRstR2 => 'Barely readable, occasional words';

  @override
  String get toolsRstR3 => 'Readable with considerable difficulty';

  @override
  String get toolsRstR4 => 'Readable with practically no difficulty';

  @override
  String get toolsRstR5 => 'Perfectly readable';

  @override
  String get toolsRstS1 => 'Faint, barely perceptible';

  @override
  String get toolsRstS2 => 'Very weak';

  @override
  String get toolsRstS3 => 'Weak';

  @override
  String get toolsRstS4 => 'Fair';

  @override
  String get toolsRstS5 => 'Fairly good';

  @override
  String get toolsRstS6 => 'Good';

  @override
  String get toolsRstS7 => 'Moderately strong';

  @override
  String get toolsRstS8 => 'Strong';

  @override
  String get toolsRstS9 => 'Extremely strong';

  @override
  String get toolsRstT1 => 'Very rough and broad, raw AC';

  @override
  String get toolsRstT2 => 'Very rough AC, harsh and broad';

  @override
  String get toolsRstT3 => 'Rough, rectified but not filtered';

  @override
  String get toolsRstT4 => 'Rough, some trace of filtering';

  @override
  String get toolsRstT5 => 'Filtered but strongly ripple-modulated';

  @override
  String get toolsRstT6 => 'Filtered, definite trace of ripple';

  @override
  String get toolsRstT7 => 'Near pure, trace of ripple';

  @override
  String get toolsRstT8 => 'Near perfect, slight trace of modulation';

  @override
  String get toolsRstT9 => 'Perfect tone, no ripple at all';

  @override
  String get toolsClockUtc => 'UTC';

  @override
  String get toolsClockLocal => 'Local time';

  @override
  String get toolsClockNote => 'Logs and QSL cards use UTC.';

  @override
  String get learnReceiveTitle => 'Receive';

  @override
  String get learnReviewTitle => 'Review';

  @override
  String get learnListen => 'Playing';

  @override
  String get learnReady => 'Ready';

  @override
  String get learnReplay => 'Replay';

  @override
  String get learnAnswerHint => 'Type what you heard';

  @override
  String get learnSubmit => 'Check';

  @override
  String get learnNext => 'Next';

  @override
  String get learnFinish => 'Finish';

  @override
  String get learnDone => 'Done';

  @override
  String get learnBackspace => 'Delete';

  @override
  String get learnSpace => 'Space';

  @override
  String get learnSent => 'Sent';

  @override
  String get learnYourCopy => 'Your copy';

  @override
  String get learnRoundPerfect => 'Perfect copy!';

  @override
  String get learnSessionSummary => 'Session summary';

  @override
  String get learnLessonPassed => 'Lesson passed';

  @override
  String get learnLessonNotPassed => 'Keep at it: 90% unlocks the next one';

  @override
  String get learnReviewRecorded => 'Review recorded';

  @override
  String get learnWeakChars => 'Needs work';

  @override
  String get learnConfusions => 'Confused';

  @override
  String get learnNoFeedbackWarning => 'Sound, flash and haptics are all off - the screen will flash instead.';

  @override
  String get learnKeyerStraight => 'Straight';

  @override
  String get learnKeyerIambicA => 'Iambic A';

  @override
  String get learnKeyerIambicB => 'Iambic B';

  @override
  String get learnStraightKeyLabel => 'KEY';

  @override
  String get learnDitLabel => 'DIT';

  @override
  String get learnDahLabel => 'DAH';

  @override
  String get learnSettingsTitle => 'Training settings';

  @override
  String get learnCharacterSpeed => 'Character speed';

  @override
  String get learnFarnsworth => 'Farnsworth spacing';

  @override
  String get learnFarnsworthHelp => 'Characters stay fast; the gaps between them stretch to this speed.';

  @override
  String get learnEffectiveSpeed => 'Effective speed';

  @override
  String get learnTone => 'Tone';

  @override
  String get learnPlaySample => 'Play sample';

  @override
  String get learnSessionLength => 'Session length';

  @override
  String get learnFeedback => 'Feedback';

  @override
  String get learnSound => 'Sound';

  @override
  String get learnFlash => 'Screen flash';

  @override
  String get learnHaptic => 'Vibration';

  @override
  String get learnKeyer => 'Keyer';

  @override
  String get learnDailyGoal => 'Daily goal';

  @override
  String get referenceReferenceTitle => 'Morse reference';

  @override
  String get referenceTranslatorTitle => 'Translator';

  @override
  String get referencePlay => 'Play';

  @override
  String get referenceStop => 'Stop';

  @override
  String get referenceClear => 'Clear';

  @override
  String get referenceClose => 'Close';

  @override
  String get referenceEmptyOutput => '—';

  @override
  String get referenceSearchHint => 'Search characters, prosigns, Q-codes…';

  @override
  String get referenceClearSearch => 'Clear search';

  @override
  String get referenceNoResults => 'Nothing matches your search.';

  @override
  String get referenceSectionAlphabet => 'Alphabet';

  @override
  String get referenceSectionPunctuation => 'Punctuation';

  @override
  String get referenceSectionProsigns => 'Prosigns';

  @override
  String get referenceSectionQCodes => 'Q-codes';

  @override
  String get referenceSectionAbbreviations => 'CW abbreviations';

  @override
  String get referenceSectionKoch => 'Koch order';

  @override
  String get referenceAlphabetHint => 'Tap a card to hear it. Long-press for a mnemonic.';

  @override
  String get referenceKochHint => 'The order the Koch method introduces characters (LCWO sequence). Start with K and M; add one when you copy at 90 %.';

  @override
  String get referenceMnemonicTitle => 'Mnemonic';

  @override
  String get referenceMeaningLabel => 'Meaning';

  @override
  String get referencePlaybackSettings => 'Playback settings';

  @override
  String get referenceCharacterSpeed => 'Character speed';

  @override
  String get referenceFarnsworth => 'Farnsworth spacing';

  @override
  String get referenceFarnsworthHelp => 'Characters stay at full speed; gaps stretch to the effective speed.';

  @override
  String get referenceEffectiveSpeed => 'Effective speed';

  @override
  String get referenceTone => 'Tone';

  @override
  String get referenceModeTextToMorse => 'Text → Morse';

  @override
  String get referenceModeMorseToText => 'Morse → Text';

  @override
  String get referenceModeKey => 'Key';

  @override
  String get referenceTextInputLabel => 'Text';

  @override
  String get referenceTextInputHint => 'Type text to encode…';

  @override
  String get referencePatternOutputLabel => 'Morse';

  @override
  String get referenceCopyPattern => 'Copy pattern';

  @override
  String get referencePatternCopied => 'Pattern copied';

  @override
  String get referencePatternInputLabel => 'Morse';

  @override
  String get referencePatternInputHint => 'Type . and -, a space between letters, / between words';

  @override
  String get referenceTextOutputLabel => 'Text';

  @override
  String get referenceCopyText => 'Copy text';

  @override
  String get referenceTextCopied => 'Text copied';

  @override
  String get referenceUnknownPatternHelp => 'Patterns with no character are shown as <pattern>.';

  @override
  String get referenceKeypadDit => 'Dit';

  @override
  String get referenceKeypadDah => 'Dah';

  @override
  String get referenceKeypadCharGap => 'Letter gap';

  @override
  String get referenceKeypadWordGap => 'Word gap';

  @override
  String get referenceKeypadBackspace => 'Backspace';

  @override
  String get referenceKeyHint => 'Press and hold the key to send. On a keyboard, hold Space.';

  @override
  String get referenceKeyLabel => 'KEY';

  @override
  String get referenceKeyDecodedLabel => 'Decoded';

  @override
  String get referenceKeyPendingLabel => 'Keying';

  @override
  String get listenTitle => 'Listen';

  @override
  String get listenStart => 'Start';

  @override
  String get listenStop => 'Stop';

  @override
  String get listenStarting => 'Starting microphone...';

  @override
  String get listenClear => 'Clear text';

  @override
  String get listenCopy => 'Copy text';

  @override
  String get listenCopied => 'Decoded text copied';

  @override
  String get listenSettings => 'Listen settings';

  @override
  String get listenDecoded => 'Decoded';

  @override
  String get listenEmptyHint => 'Point the microphone at a Morse tone. Decoded text appears here.';

  @override
  String get listenIdleHint => 'Tap Start to listen for a Morse tone.';

  @override
  String get listenPending => 'Receiving';

  @override
  String get listenSpeed => 'Speed';

  @override
  String get listenSpeedUnknown => '-- WPM';

  @override
  String get listenLevel => 'Signal';

  @override
  String get listenToneOn => 'Tone';

  @override
  String get listenTone => 'Tone frequency';

  @override
  String get listenToneLocked => 'Locked';

  @override
  String get listenToneSearching => 'Searching';

  @override
  String get listenToneManual => 'Manual';

  @override
  String get listenAutoTune => 'Auto-tune';

  @override
  String get listenAutoTuneHelp => 'Follow the strongest tone between 400 and 1000 Hz. Drag the slider to tune by hand instead.';

  @override
  String get listenRetune => 'Auto';

  @override
  String get listenBlockSize => 'Analysis block';

  @override
  String get listenBlockSizeHelp => 'Smaller blocks place mark edges more precisely but pick up more noise. 256 samples (5.3 ms) suits 5-40 WPM.';

  @override
  String get listenMinElement => 'Shortest element';

  @override
  String get listenMinElementHelp => 'Tones and gaps shorter than this are ignored as clicks and dropouts.';

  @override
  String get listenPermissionDenied => 'Microphone access was denied. Allow it in the system settings, then try again.';

  @override
  String get listenPermissionRetry => 'Try again';

  @override
  String get listenStartFailed => 'Could not start the microphone.';

  @override
  String get listenNoInput => 'No microphone was found. Connect one and try again.';

  @override
  String get listenStreamFailed => 'The microphone stopped unexpectedly. Try again.';

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
    return '$samples samples ($ms ms)';
  }

  @override
  String listenMsValue(int ms) {
    return '$ms ms';
  }

  @override
  String get listenStoppedInBackground => 'Listening stopped while the app was in the background.';

  @override
  String get notificationOpen => 'Open';

  @override
  String get notificationChannelMessages => 'Messages';

  @override
  String get notificationChannelMessagesDescription => 'New Morse messages from friends and groups';

  @override
  String get notificationChannelFriendRequests => 'Friend requests';

  @override
  String get notificationChannelFriendRequestsDescription => 'Someone wants to add you as a friend';

  @override
  String get notificationChannelGroupInvites => 'Group invites';

  @override
  String get notificationChannelGroupInvitesDescription => 'A friend invited you to a group';

  @override
  String get notificationNewMessage => 'New message';

  @override
  String get notificationFriendRequestTitle => 'New friend request';

  @override
  String get accountNewPasswordRequired => 'Enter a new password';

  @override
  String get accountToxIdQrSemantics => 'Tox ID QR code';

  @override
  String get accountBackupSaveDialogTitle => 'Save DitMesh backup';

  @override
  String get accountBackupShareSubject => 'DitMesh identity backup';

  @override
  String get accountBackupChooseDialogTitle => 'Choose DitMesh backup';

  @override
  String notificationNewMessages(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count new messages',
      one: '1 new message',
    );
    return '$_temp0';
  }

  @override
  String notificationFriendRequestFrom(String name) {
    return 'Friend request from $name';
  }

  @override
  String notificationFriendRequestBody(String name, String message) {
    return '$name: $message';
  }

  @override
  String notificationGroupInviteTitle(String group) {
    return 'Invite to $group';
  }

  @override
  String notificationGroupInviteBody(String name) {
    return '$name invited you';
  }

  @override
  String desktopTrayShow(String app) {
    return 'Show $app';
  }

  @override
  String desktopTrayHide(String app) {
    return 'Hide $app';
  }

  @override
  String get desktopTraySoundOn => 'Sound on';

  @override
  String get desktopTraySoundOff => 'Sound off';

  @override
  String desktopTrayQuit(String app) {
    return 'Quit $app';
  }

  @override
  String desktopTrayTooltipUnread(String app, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count unread messages',
      one: '1 unread message',
    );
    return '$app — $_temp0';
  }

  @override
  String desktopWindowTitleUnread(String badge, String app) {
    return '($badge) $app';
  }

  @override
  String get listenStateOn => 'On';

  @override
  String get listenStateOff => 'Off';

  @override
  String chatBytesLeftCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count bytes left',
      one: '1 byte left',
    );
    return '$_temp0';
  }

  @override
  String chatMemberCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count members',
      one: '1 member',
    );
    return '$_temp0';
  }

  @override
  String chatFriendsCount(int count) {
    return 'Friends ($count)';
  }

  @override
  String chatFriendRequestsCount(int count) {
    return 'Friend requests ($count)';
  }

  @override
  String chatGroupInvitesCount(int count) {
    return 'Group invites ($count)';
  }

  @override
  String chatMembersTitleCount(int count) {
    return 'Members · $count';
  }

  @override
  String chatInvitedByName(String name) {
    return 'Invited by $name';
  }

  @override
  String chatMemberSelf(String name) {
    return '$name (You)';
  }

  @override
  String chatSliderValue(String label, int value, String unit) {
    return '$label: $value $unit';
  }

  @override
  String referenceTelegraphCodes(String codes) {
    return 'Chinese telegraph code: $codes';
  }

  @override
  String get referenceTelegraphMainland => 'Mainland 1983';

  @override
  String get referenceTelegraphTaiwan => 'Taiwan / HK';

  @override
  String get referenceTelegraphNone => 'not in this codebook';

  @override
  String get appearanceTitle => 'Appearance';

  @override
  String get appearanceStyles => 'Interface style';

  @override
  String get appearanceChoose => 'Choose a style, preview, then apply';

  @override
  String get appearanceMode => 'Brightness';

  @override
  String get appearancePreview => 'Preview';

  @override
  String get appearanceApply => 'Apply style';

  @override
  String get appearanceRestore => 'Restore defaults';

  @override
  String get appearanceApplied => 'Appearance saved';

  @override
  String get appearanceSaveFailed => 'Could not save appearance. Try again.';

  @override
  String get appearanceClassic => 'Classic Brass';

  @override
  String get appearanceModern => 'Modern Calm';

  @override
  String get appearanceRadio => 'Night Radio';

  @override
  String get appearancePaper => 'Paper Handbook';

  @override
  String get appearanceCartoon => 'Fresh Cartoon';

  @override
  String get appearanceLight => 'Light';

  @override
  String get appearanceDark => 'Dark';

  @override
  String get appearanceSubtitle => 'Five styles with light and dark modes';

  @override
  String get chatClearHistoryBody => 'Delete this conversation’s history on this device? Copies on other devices are unaffected. This cannot be undone.';

  @override
  String get chatLoadEarlier => 'Load earlier messages';

  @override
  String get chatHistoryLoadFailed => 'Could not load earlier messages. Tap to retry.';

  @override
  String get chatRetryHistory => 'Retry';

  @override
  String chatNewMessages(int count) {
    return '$count new messages';
  }

  @override
  String get chatSelfMe => 'Me';

  @override
  String get chatSelfLocalOnly => 'Saved on this device only';

  @override
  String get chatSelfContactSubtitle => 'Drafts, practice and notes · never sent';

  @override
  String get learnLeaveDrillTitle => 'Leave this session?';

  @override
  String get learnLeaveDrillBody => 'The rounds you have done in this session will not be saved.';

  @override
  String get learnLeaveDrillConfirm => 'Leave';

  @override
  String get chatScanQrPermissionDenied => 'DitMesh needs camera access to scan a QR code. Allow it in the system settings.';

  @override
  String get chatScanQrCameraUnavailable => 'The camera is not available on this device.';

  @override
  String get learnReplayAssistedNote => 'Replayed: this session counts as practice but won\'t unlock a lesson or update reviews.';

  @override
  String learnPlanNext(String step) {
    return 'Next: $step';
  }

  @override
  String get messageStatusCancelled => 'Cancelled — never sent';

  @override
  String get chatMessageLearnActions => 'Message actions';

  @override
  String get chatPracticeMessage => 'Practice this message';

  @override
  String get chatListenOnly => 'Listen-only training';

  @override
  String get chatListenOnlyHidden => 'Listen-only: tap play to hear it';

  @override
  String get chatPracticeTitle => 'Copy practice';

  @override
  String chatPracticeUnsupported(String chars) {
    return 'This message contains characters Morse can\'t key: $chars. They will be left out.';
  }

  @override
  String chatPracticeTrainableCount(int count) {
    return '$count symbols can be practised.';
  }

  @override
  String get chatPracticeNothingTrainable => 'Nothing in this message can be practised in Morse.';

  @override
  String get chatPracticeConfirm => 'Practice the rest';

  @override
  String get chatPracticeHint => 'Hint';

  @override
  String chatPracticeHintShown(String symbols) {
    return 'Hint: $symbols …';
  }

  @override
  String get chatPracticeAssisted => 'Assisted: counts as practice, not for reviews or speed advice.';

  @override
  String chatPracticeErrors(int wrong, int missed, int extra) {
    return '$wrong wrong · $missed missed · $extra extra';
  }

  @override
  String chatPracticeErrorsAction(String symbols) {
    return 'Practice errors: $symbols';
  }

  @override
  String get chatSearchMessages => 'Search messages';

  @override
  String get chatSearchHint => 'Search this conversation';

  @override
  String get chatSearchAnyone => 'Anyone';

  @override
  String get chatSearchMe => 'Me';

  @override
  String get chatSearchThem => 'Them';

  @override
  String get chatSearchAnyDate => 'Any date';

  @override
  String chatSearchDateRange(String from, String to) {
    return '$from – $to';
  }

  @override
  String get chatSearchBookmarked => 'Bookmarked';

  @override
  String get chatSearchNoResults => 'No matching messages.';

  @override
  String get chatSearchMore => 'Load more';

  @override
  String get chatAddBookmark => 'Bookmark';

  @override
  String get chatRemoveBookmark => 'Remove bookmark';

  @override
  String get chatBookmarked => 'Bookmarked';

  @override
  String get chatBookmarkFailed => 'Couldn\'t save the bookmark.';

  @override
  String get chatRetrySend => 'Retry sending';

  @override
  String get chatCancelSend => 'Cancel sending';

  @override
  String get chatRetryQueued => 'Queued again. It will be sent when your contact is online.';

  @override
  String get chatSendCancelled => 'Cancelled. The message was never sent.';

  @override
  String get chatRetryNotNeeded => 'This message is no longer failed; nothing to retry.';

  @override
  String get chatCancelTooLate => 'Too late to cancel: the message was already handed to the network and may arrive.';

  @override
  String get chatSendControlUnavailable => 'Not available for this message.';

  @override
  String get chatSendControlFailed => 'That didn\'t work. The message keeps its current state; try again.';

  @override
  String get workbenchTitle => 'Recording workbench';

  @override
  String get workbenchOpen => 'Recordings';

  @override
  String get workbenchImport => 'Import recording';

  @override
  String get workbenchEmpty => 'Import a WAV recording to loop, decode and copy it. No microphone needed.';

  @override
  String get workbenchFormats => 'WAV, 16-bit PCM, mono or stereo, 8/16/44.1/48 kHz; up to 50 MB and 20 minutes.';

  @override
  String get workbenchBackupNote => 'Recordings stay on this device and are left out of identity backups unless you choose to include them when exporting a backup. Saved selections always back up their titles, notes and positions.';

  @override
  String workbenchInfo(String rate, String channels, String duration) {
    return '$rate kHz · $channels · $duration';
  }

  @override
  String get workbenchMono => 'mono';

  @override
  String get workbenchStereo => 'stereo';

  @override
  String get workbenchTruncated => 'The file ends early; only the audio present is used.';

  @override
  String get workbenchErrorNotWav => 'This is not a WAV file.';

  @override
  String get workbenchErrorFormat => 'Only 16-bit PCM WAV is supported for now (no MP3, AAC or float WAV).';

  @override
  String get workbenchErrorChannels => 'Only mono or stereo recordings are supported.';

  @override
  String get workbenchErrorRate => 'Sample rate not supported. Use 8, 16, 44.1 or 48 kHz.';

  @override
  String get workbenchErrorDamaged => 'The file is damaged or incomplete.';

  @override
  String get workbenchErrorTooLarge => 'The file is larger than 50 MB.';

  @override
  String get workbenchErrorTooLong => 'The recording is longer than 20 minutes.';

  @override
  String get workbenchErrorIo => 'Couldn\'t read the file.';

  @override
  String get workbenchErrorMissing => 'The recording file is missing.';

  @override
  String get workbenchStart => 'Start (s)';

  @override
  String get workbenchEnd => 'End (s)';

  @override
  String get workbenchSelectAll => 'Select all';

  @override
  String get workbenchPlay => 'Play selection';

  @override
  String get workbenchStop => 'Stop';

  @override
  String get workbenchLoop => 'Loop';

  @override
  String get workbenchPlayLimit => 'Only the first 5 minutes of a longer selection are played.';

  @override
  String get workbenchAutoTune => 'Find the tone automatically';

  @override
  String workbenchManualTone(int hz) {
    return 'Tone: $hz Hz';
  }

  @override
  String get workbenchDecode => 'Decode selection';

  @override
  String get workbenchCancel => 'Cancel';

  @override
  String workbenchDecoding(int percent) {
    return 'Decoding… $percent%';
  }

  @override
  String workbenchResultStats(int hz, int wpm) {
    return 'Tone $hz Hz · about $wpm WPM';
  }

  @override
  String get workbenchToneNotLocked => 'No steady tone found; try manual tuning.';

  @override
  String get workbenchNoText => 'Nothing decoded in this selection.';

  @override
  String workbenchUnknown(String patterns) {
    return 'Unknown patterns: $patterns';
  }

  @override
  String get workbenchEdgeCut => 'A symbol at the edge of the selection is cut off and may be wrong.';

  @override
  String get workbenchToneNote => 'Tone lock is not a confidence score; check the text by ear.';

  @override
  String get workbenchModeDecoder => 'Decoder';

  @override
  String get workbenchModeCopy => 'Copy it myself';

  @override
  String get workbenchDecoderHidden => 'Decoder text is hidden while you copy.';

  @override
  String get workbenchShowDecoder => 'Show decoder text';

  @override
  String get workbenchReference => 'Reference text (optional)';

  @override
  String get workbenchReferenceHelp => 'Paste the text that was sent; otherwise your copy is compared with the decoder output.';

  @override
  String get workbenchAgainstDecoder => 'Compared with the decoder output, which can itself be wrong.';

  @override
  String get workbenchSave => 'Save selection';

  @override
  String get workbenchSaveTitle => 'Title';

  @override
  String get workbenchSaveNote => 'Note';

  @override
  String get workbenchSaved => 'Selection saved';

  @override
  String get workbenchSaveFailed => 'Couldn\'t save the selection.';

  @override
  String get workbenchLibrary => 'Saved selections';

  @override
  String get workbenchLibraryEmpty => 'No saved selections yet.';

  @override
  String get workbenchMissing => 'Recording file missing — choose it again or delete the entry.';

  @override
  String get workbenchRelink => 'Choose the file again';

  @override
  String get workbenchDelete => 'Delete';

  @override
  String get guestTryLearning => 'Try learning first';

  @override
  String get guestBanner => 'Guest learning: progress stays on this device. Chat needs an identity.';

  @override
  String get guestGetIdentity => 'Set up identity';

  @override
  String get guestIdentityTitle => 'Identity needed';

  @override
  String get guestIdentityBody => 'Chatting over Tox needs your own identity. Create a new one, restore a backup, or unlock the one on this device. Your guest learning progress moves to a new identity automatically.';

  @override
  String get guestClearData => 'Clear guest learning data';

  @override
  String get guestClearDataBody => 'Deletes the progress, plans and materials you made as a guest on this device. Identities are not affected.';

  @override
  String get guestClearConfirm => 'Clear';

  @override
  String get guestCleared => 'Guest learning data cleared.';

  @override
  String get guestClearFailed => 'Couldn\'t clear the guest data.';

  @override
  String get guestMigrationFailed => 'Your identity is ready, but your guest learning progress hasn\'t moved to it yet. It is safe on this device.';

  @override
  String get guestChoiceBody => 'You also have guest learning progress. The restored identity\'s progress is in use; nothing was merged.';

  @override
  String get guestChoiceKeep => 'Keep restored';

  @override
  String get guestChoiceUseGuest => 'Use guest progress';

  @override
  String get chatJumpToLatest => 'Latest messages';

  @override
  String get chatMessageGone => 'That message is no longer in this conversation.';

  @override
  String get chatListenOnlyPreview => 'New message — listen to copy it';

  @override
  String get accountBackupMediaTitle => 'Include saved recordings?';

  @override
  String accountBackupMediaBody(int count, String size) {
    return '$count saved recordings ($size MB). Their titles, notes and positions are always in the backup; the audio only if you include it.';
  }

  @override
  String accountBackupMediaTooLarge(String size) {
    return 'Saved recordings ($size MB) are too large to put in a backup; only their titles, notes and positions are included.';
  }

  @override
  String get accountBackupMediaInclude => 'Include recordings';

  @override
  String get accountBackupMediaSkip => 'Without recordings';

  @override
  String get diagTitle => 'Connection diagnostics';

  @override
  String get diagOpenSubtitle => 'Why messages are waiting and how to reconnect';

  @override
  String get diagBannerDetails => 'Details';

  @override
  String get diagSummaryNoIdentity => 'No identity is open, so there is no connection to inspect.';

  @override
  String get diagSummaryOnlinePeerOnline => 'You are connected to the Tox network and this contact is online. Messages go straight to them.';

  @override
  String get diagSummaryOnlinePeerOffline => 'You are connected, but this contact is offline. Messages wait in the outbox on this device and are sent when the contact comes online.';

  @override
  String get diagSummaryOnline => 'You are connected to the Tox network.';

  @override
  String get diagSummaryConnecting => 'Connecting to the Tox network. This can take a minute after the app starts or the network changes.';

  @override
  String get diagSummaryOffline => 'You are not connected to the Tox network. Nothing can be sent or received until the connection is back.';

  @override
  String get diagLocalLabel => 'Your connection';

  @override
  String diagSinceChanged(String time) {
    return 'Since $time';
  }

  @override
  String diagSinceFirst(String time) {
    return 'Observed since $time';
  }

  @override
  String diagSinceResumed(String time) {
    return 'Observed since returning to the app at $time';
  }

  @override
  String get diagLastOnlineLabel => 'Last connection observed';

  @override
  String get diagLastOnlineNow => 'Connected now';

  @override
  String get diagLastOnlineNone => 'No connection observed yet.';

  @override
  String get diagLastOnlineHint => 'When this device last saw its own connection. It is not when a message reached anyone.';

  @override
  String get diagPeerLabel => 'Contact';

  @override
  String get diagUnknown => 'Unknown';

  @override
  String get diagPeerUnknownHint => 'A contact\'s presence can only be seen while you are connected.';

  @override
  String get diagPeerGroupHint => 'Group members\' presence is shown in the member list.';

  @override
  String get diagPendingLabel => 'Waiting to send';

  @override
  String get diagPendingNone => 'Nothing waiting';

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
    return 'Oldest queued $time';
  }

  @override
  String get diagPendingUnknown => 'Unknown until chat is connected';

  @override
  String get diagPendingHint => 'Queued messages stay on this device and are sent automatically when the contact is reachable. Diagnostics never discards or resends them.';

  @override
  String get diagReconnect => 'Reconnect';

  @override
  String get diagReconnecting => 'Reconnecting…';

  @override
  String diagReconnectFailed(String reason) {
    return 'Reconnect failed: $reason';
  }

  @override
  String get diagReconnectNote => 'Reconnecting restarts the connection attempt. Coming online can still take a while; this page updates when it does.';

  @override
  String get diagAboutTitle => 'How DitMesh connects';

  @override
  String get diagAboutBody => 'DitMesh has no server. Your device talks to your contacts directly over the Tox peer-to-peer network, so both of you must be online at the same time for a message to arrive. Phones pause apps in the background: DitMesh cannot stay connected there and reconnects when you return.';

  @override
  String get diagDetailsTitle => 'Technical details';

  @override
  String get diagDetailIdentity => 'Identity';

  @override
  String get diagDetailStatus => 'Status';

  @override
  String get diagDetailObserved => 'Observed at';

  @override
  String get diagDetailQueued => 'Queue entries';

  @override
  String get diagDetailError => 'Last error code';

  @override
  String get backupXTitle => 'Encrypted backup';

  @override
  String get backupXIntro => 'Choose what to take to another device. The whole file is encrypted with a passphrase you set here.';

  @override
  String get backupXCategoryIdentity => 'Identity and Tox profile';

  @override
  String get backupXCategoryTraining => 'Training progress and materials';

  @override
  String get backupXCategoryChat => 'Chat history, including notes to self';

  @override
  String get backupXCategoryMeta => 'Drafts, pins and bookmarks';

  @override
  String get backupXCategoryPrefs => 'App preferences';

  @override
  String get backupXPrefsHint => 'Playback, notifications, appearance and language. Never window positions or key bindings.';

  @override
  String get backupXCategoryMedia => 'Saved recordings';

  @override
  String get backupXMediaHint => 'Off by default: recordings can be large. Without them, only their titles and notes come along.';

  @override
  String get backupXCategoryPending => 'Unsent messages';

  @override
  String get backupXPendingHint => 'They come back for review only and are never sent automatically.';

  @override
  String get backupXRequired => 'Required';

  @override
  String backupXSizeLine(int count, String size) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items',
      one: '1 item',
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
    return 'Too large to include ($size)';
  }

  @override
  String backupXInvitesNote(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count group invitations waiting for offline friends are not carried over.',
      one: '1 group invitation waiting for an offline friend is not carried over.',
    );
    return '$_temp0';
  }

  @override
  String get backupXIdentityPasswordNote => 'Your identity password stays on the profile: the new device asks for it as well as for the backup passphrase.';

  @override
  String backupXTotal(String size) {
    return 'About $size in total';
  }

  @override
  String get backupXPassphrase => 'Backup passphrase';

  @override
  String get backupXPassphraseConfirm => 'Repeat passphrase';

  @override
  String get backupXPassphraseHint => 'At least 8 characters. It is separate from your identity password and cannot be recovered.';

  @override
  String get backupXPassphraseTooShort => 'Use at least 8 characters';

  @override
  String get backupXPassphraseMismatch => 'The passphrases do not match';

  @override
  String get backupXExport => 'Create encrypted backup';

  @override
  String get backupXExporting => 'Creating backup…';

  @override
  String get backupXMigrationNote => 'Moving to a new device? After restoring there, stop using this identity here: two devices with one identity can send the same message twice.';

  @override
  String get backupXBusy => 'Your data kept changing while the backup was taken. Try again.';

  @override
  String get backupXTooLarge => 'The backup is too large. Leave out recordings and try again.';

  @override
  String get restoreXWrongPassphrase => 'Wrong passphrase, or the file was changed or is incomplete.';

  @override
  String get restoreXUnsupported => 'This backup was made by a newer version of DitMesh.';

  @override
  String get restoreXCheck => 'Open backup';

  @override
  String get restoreXPreviewTitle => 'Backup contents';

  @override
  String restoreXCreated(String date) {
    return 'Created $date';
  }

  @override
  String get restoreXIncluded => 'Included';

  @override
  String get restoreXExcluded => 'Not in this backup';

  @override
  String restoreXPendingIncluded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count unsent messages come back for review. They will not be sent automatically.',
      one: '1 unsent message comes back for review. It will not be sent automatically.',
    );
    return '$_temp0';
  }

  @override
  String restoreXPendingExcluded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count unsent messages on the old device are not in this backup.',
      one: '1 unsent message on the old device is not in this backup.',
    );
    return '$_temp0';
  }

  @override
  String get restoreXIdentityPassword => 'Identity password';

  @override
  String get restoreXIdentityPasswordNote => 'The identity in this backup has its own password. Enter it as well.';

  @override
  String get restoreXConfirmTitle => 'Replace the identity on this device?';

  @override
  String get restoreXConfirmBody => 'Any identity and data on this device are replaced by the backup. Stop using the identity on the old device before connecting here.';

  @override
  String get restoreXConfirm => 'Replace and restore';

  @override
  String get restoreXReportTitle => 'Restore complete';

  @override
  String get restoreXReportRestored => 'Restored';

  @override
  String get restoreXReportNotIncluded => 'Not restored';

  @override
  String get restoreXReportPrefsFailed => 'Preferences could not be applied; your previous preferences were kept.';

  @override
  String restoreXReportPendingReview(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count unsent messages are waiting for your review in Chat.',
      one: '1 unsent message is waiting for your review in Chat.',
    );
    return '$_temp0';
  }

  @override
  String restoreXReportPendingNotResumed(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count unsent messages from the old device were not brought over.',
      one: '1 unsent message from the old device was not brought over.',
    );
    return '$_temp0';
  }

  @override
  String restoreXReportInvites(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count queued group invitations were not resent.',
      one: '1 queued group invitation was not resent.',
    );
    return '$_temp0';
  }

  @override
  String get restoreXReportStopOld => 'Stop using this identity on the old device.';

  @override
  String get restoreXReportDone => 'Done';

  @override
  String pendingReviewBanner(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count unsent messages from your previous device',
      one: '1 unsent message from your previous device',
    );
    return '$_temp0';
  }

  @override
  String get pendingReviewTitle => 'Unsent messages';

  @override
  String get pendingReviewBody => 'These were waiting to be sent on your previous device. DitMesh never sends them automatically; key one again if it still matters.';

  @override
  String pendingReviewQueuedAt(String time) {
    return 'Queued $time on the previous device';
  }

  @override
  String get pendingReviewDismiss => 'Dismiss';

  @override
  String get pendingReviewDismissAll => 'Dismiss all';

  @override
  String get pendingReviewEmpty => 'Nothing left to review.';

  @override
  String get backupXWizardInside => 'The backup file is encrypted as a whole with a passphrase you choose, and holds your identity key and training progress. Keep the file and the passphrase somewhere safe, outside this device.';

  @override
  String get backupXMeSubtitle => 'An encrypted file with your identity, chats and progress, to keep or to move to another device';

  @override
  String get conditionsClear => 'Clear';

  @override
  String get conditionsLight => 'Light interference';

  @override
  String get conditionsRadio => 'Radio practice';

  @override
  String get conditionsClearHint => 'A clean, steady tone: ordinary practice.';

  @override
  String get conditionsLightHint => 'Soft background noise and gentle fading. Results are kept apart from clean practice.';

  @override
  String get conditionsRadioHint => 'Noise, deep fading, a nearby station and slightly uneven timing. Results are kept apart from clean practice.';

  @override
  String conditionsActive(String name) {
    return 'Conditions: $name';
  }

  @override
  String get conditionsNeedSound => 'Radio conditions are heard, not seen: turn sound on in the training settings, or practise with Clear conditions.';

  @override
  String get conditionsCleanReplay => 'Play without effects';

  @override
  String conditionsComparable(int count, int accuracy) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count attempts under these conditions at this speed: $accuracy% on average',
      one: '1 attempt under these conditions at this speed: $accuracy%',
    );
    return '$_temp0';
  }

  @override
  String get conditionsSeparateNote => 'Practice under radio conditions counts as activity but does not change your lessons, review schedule or speed advice.';

  @override
  String get keysTitle => 'Keys and external keyers';

  @override
  String get keysMeSubtitle => 'Key bindings, paddles and USB keyer adapters';

  @override
  String get keysIntro => 'Choose which keys key Morse. Keyboard-emulating USB key and paddle adapters work like a keyboard: set their keys here. The app cannot tell which device sent a key, so a profile is a set of bindings.';

  @override
  String get keysStandardProfile => 'Standard';

  @override
  String get keysUnnamed => 'Unnamed profile';

  @override
  String get keysEdit => 'Edit';

  @override
  String get keysNewProfile => 'New profile';

  @override
  String get keysLimitations => 'MIDI, serial and Bluetooth keyers, adapter firmware settings and transmitter control are not supported. Tested adapters are listed in the documentation.';

  @override
  String get keysEditTitle => 'Key profile';

  @override
  String get keysName => 'Profile name';

  @override
  String get keysActionStraight => 'Straight key';

  @override
  String get keysActionDit => 'Dit paddle';

  @override
  String get keysActionDah => 'Dah paddle';

  @override
  String get keysPressKey => 'Press a key…';

  @override
  String get keysNone => 'Not set';

  @override
  String get keysSet => 'Set';

  @override
  String keysReserved(String key) {
    return '$key is reserved by the system or the app; choose another key.';
  }

  @override
  String keysConflict(String key, String action) {
    return '$key is already used for $action.';
  }

  @override
  String keysConflictSave(String keys) {
    return 'Each key can do only one thing: $keys is bound twice.';
  }

  @override
  String get keysMissing => 'Set the keys this keyer mode needs (both paddles for iambic).';

  @override
  String get keysSwapPaddles => 'Swap paddles (left-handed)';

  @override
  String get keysKeyerMode => 'Keyer mode';

  @override
  String get keysIambicA => 'Iambic A';

  @override
  String get keysIambicB => 'Iambic B';

  @override
  String get keysAdapterKeyer => 'The adapter keys its own elements';

  @override
  String get keysAdapterKeyerHint => 'For an adapter with its own keyer: its timed key-down and key-up are used as they are, without a second iambic keyer in the app.';

  @override
  String get keysAppSidetone => 'App sidetone while keying';

  @override
  String get keysAppSidetoneHint => 'Turn off when the adapter makes its own sidetone. Decoding is not affected.';

  @override
  String get keysTestTitle => 'Test';

  @override
  String get keysTestNote => 'Testing only: nothing is sent or added to your training.';

  @override
  String get keysTestRelease => 'Release keys';

  @override
  String get keysAdapterActive => 'The adapter\'s own keyer is used: paddle keys act as a straight key.';

  @override
  String keysHintCustom(String keys) {
    return 'Keys: $keys';
  }

  @override
  String get telegraphCodebook => 'Codebook';

  @override
  String get telegraphCodebookMainland => 'Mainland';

  @override
  String get telegraphCodebookTaiwan => 'Taiwan';

  @override
  String get telegraphInterpretAction => 'Interpret as Chinese telegraph code';

  @override
  String get telegraphInterpretTitle => 'Telegraph code interpretation';

  @override
  String get telegraphInterpretNote => 'Shown here only: the message itself is not changed and nothing is sent.';

  @override
  String get telegraphUnresolved => 'Unresolved: no character has this code';

  @override
  String get telegraphMalformed => 'Not a four-digit group';

  @override
  String get telegraphNotCode => 'Text, kept as written';

  @override
  String get telegraphAmbiguous => 'Several characters share this code';

  @override
  String get groupPracticeTitle => 'Group practice';

  @override
  String get groupPracticeIntro => 'The instructor keys exercises in the group chat as usual. Each member picks an exercise message here and copies it at their own speed. Answers and scores stay on your device; nothing is sent to the group.';

  @override
  String get groupPracticeNew => 'New session';

  @override
  String get groupPracticeTitleField => 'Title';

  @override
  String get groupPracticeCreate => 'Create';

  @override
  String get groupPracticeInstructor => 'Instructor';

  @override
  String get groupPracticeParticipant => 'Participant';

  @override
  String get groupPracticeInstructorHint => 'Key each exercise in the group chat, add it here as a round and tick it off; announce turns in the chat.';

  @override
  String get groupPracticeParticipantHint => 'Add the instructor\'s exercise messages as rounds and copy each one here.';

  @override
  String get groupPracticeLocalNote => 'Local only: rounds, roles and results are not synchronised with other members, and missed messages may never reach everyone.';

  @override
  String get groupPracticeAddRound => 'Add exercise';

  @override
  String get groupPracticeNoMessages => 'No suitable messages in the recent history.';

  @override
  String get groupPracticeNotConnected => 'Group history is not available until chat is connected.';

  @override
  String get groupPracticeRoundOpen => 'To do';

  @override
  String get groupPracticeRoundDone => 'Done';

  @override
  String get groupPracticeRoundUnavailable => 'Unavailable';

  @override
  String get groupPracticeSourceGone => 'The exercise message is no longer in the history.';

  @override
  String get groupPracticeSourceLoading => 'Looking for the message…';

  @override
  String groupPracticeAttemptResult(int accuracy, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Copied: $accuracy% ($count attempts)',
      one: 'Copied: $accuracy%',
    );
    return '$_temp0';
  }

  @override
  String get groupPracticeCopy => 'Copy';

  @override
  String get groupPracticeRemoveRound => 'Remove round';

  @override
  String get groupPracticeSummary => 'Summary';

  @override
  String groupPracticeRoundsDone(int done, int total) {
    return '$done of $total rounds done';
  }

  @override
  String groupPracticeUnavailableCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count rounds unavailable',
      one: '1 round unavailable',
    );
    return '$_temp0';
  }

  @override
  String groupPracticeAccuracy(int accuracy) {
    return 'Copy accuracy: $accuracy%';
  }

  @override
  String groupPracticeAssisted(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count attempts with help',
      one: '1 attempt with help',
    );
    return '$_temp0';
  }

  @override
  String groupPracticeShareHint(int done, int total, int accuracy) {
    return 'To share, key your result in the group chat yourself, e.g. $done/$total $accuracy%. Nothing is sent automatically.';
  }

  @override
  String get groupPracticeComplete => 'Finish session';

  @override
  String get groupPracticeDeleteTitle => 'Delete this session?';

  @override
  String get groupPracticeDeleteBody => 'Its rounds and local results are removed from this device. Your training history and the group\'s messages stay.';

  @override
  String get conditionsAudioFailed => 'The audio could not be started on this device. Practise with Clear conditions instead.';

  @override
  String get moderationBlock => 'Block';

  @override
  String moderationBlockTitle(String name) {
    return 'Block $name?';
  }

  @override
  String get moderationBlockFriendBody => 'They are removed from your friends and your conversation with them is deleted. Their messages, friend requests and group invites no longer appear on this device. They are not notified.';

  @override
  String get moderationBlockMemberBody => 'Their messages in this group no longer appear on this device. They are not notified. Tox gives every group member a separate key in each group, so this applies to this group only.';

  @override
  String get moderationBlocked => 'Blocked';

  @override
  String get moderationUnblock => 'Unblock';

  @override
  String get moderationUnblocked => 'Unblocked';

  @override
  String get moderationBlockedTitle => 'Blocked people';

  @override
  String get moderationBlockedSubtitle => 'Their messages, requests and invites are hidden';

  @override
  String get moderationBlockedEmpty => 'You have not blocked anyone.';

  @override
  String get moderationBlockedNote => 'Blocking works on this device: Tox has no central server, so blocked people can still try to reach you, but nothing of theirs is shown here.';

  @override
  String get termsGateTitle => 'Community guidelines';

  @override
  String get termsGateIntro => 'DitMesh chat connects you directly with other people, without a server. Before you start, please agree to these rules:';

  @override
  String get termsGateRuleZero => 'Zero tolerance: no harassment, hate, threats, sexual content involving minors, spam or anything illegal.';

  @override
  String get termsGateRuleContacts => 'Only people you accept can message you; groups are joined by invitation or group ID.';

  @override
  String get termsGateRuleBlock => 'Block anyone from a conversation, a group’s member list, a friend request or a group invite.';

  @override
  String get termsGateAgree => 'Agree and continue';

  @override
  String get termsGateReadFull => 'Read the full terms of use';

  @override
  String get termsGateSaveFailed => 'Your answer could not be saved. Try again.';

  @override
  String get aboutPrivacyPolicy => 'Privacy policy';

  @override
  String get aboutTermsOfUse => 'Terms of use';

  @override
  String get aboutSupport => 'Support and contact';

  @override
  String get aboutLinkFailed => 'The link could not be opened, so it was copied.';

  @override
  String get errorPeerBlocked => 'You blocked this person. Unblock them under Me → Blocked people first.';

  @override
  String get offlineClearData => 'Clear learning data';

  @override
  String get offlineClearDataBody => 'Deletes your progress, plans and materials on this device.';

  @override
  String get offlineCleared => 'Learning data cleared.';

  @override
  String get offlineClearFailed => 'Couldn’t clear the learning data.';

  @override
  String get learnStorageUnavailable => 'Your training data could not be opened on this device. Try again.';

  @override
  String get backendStartupFailedTitle => 'Chat backend unavailable';

  @override
  String get backendStartupFailedBody => 'DitMesh could not start the Tox network backend. Check that the native libraries are installed, then retry.';

  @override
  String get bootstrapTitle => 'Network and bootstrap';

  @override
  String get bootstrapDescription => 'Choose the public nodes used to join the Tox network.';

  @override
  String get bootstrapModeAuto => 'Automatic';

  @override
  String get bootstrapModeManual => 'Manual';

  @override
  String get bootstrapModeLan => 'LAN host';

  @override
  String get bootstrapAutoDescription => 'Start with built-in nodes and refresh the official list in the background.';

  @override
  String get bootstrapManualDescription => 'Use only your chosen node. You can enter a LAN node here.';

  @override
  String get bootstrapLanDescription => 'Run a local UDP/DHT node on this desktop for other LAN devices.';

  @override
  String get bootstrapCurrentNode => 'Current node';

  @override
  String get bootstrapHost => 'Host or IP address';

  @override
  String get bootstrapPort => 'UDP port';

  @override
  String get bootstrapPublicKey => 'DHT public key';

  @override
  String get bootstrapTestNode => 'Test node';

  @override
  String get bootstrapSaveNode => 'Use tested node';

  @override
  String get bootstrapChooseNode => 'Choose public node';

  @override
  String get bootstrapReachable => 'DHT response received';

  @override
  String get bootstrapUnreachable => 'No DHT response';

  @override
  String get bootstrapInvalid => 'Invalid host, port or public key';

  @override
  String get bootstrapUdpUnavailable => 'A UDP probe could not run on this device. TCP connectivity is not tested.';

  @override
  String get bootstrapProbeUnavailable => 'The probe could not start. This says nothing about node reachability.';

  @override
  String get bootstrapFallback => 'Showing built-in fallback nodes; the official list could not be loaded.';

  @override
  String get bootstrapMaintainer => 'Maintainer';

  @override
  String get bootstrapLocation => 'Location';

  @override
  String get bootstrapLastPing => 'Last public check';

  @override
  String get bootstrapSwitchTitle => 'Switch bootstrap node';

  @override
  String get bootstrapSwitchQuestion => 'Use this node?';

  @override
  String get bootstrapNotTestedWarning => 'This node has not been tested on your device.';

  @override
  String get bootstrapFailedWarning => 'This node did not answer a UDP probe. You can still select it.';

  @override
  String get bootstrapInconclusiveWarning => 'The probe was inconclusive. TCP connectivity is not tested.';

  @override
  String get bootstrapSwitchConfirm => 'Use node';

  @override
  String get bootstrapRefresh => 'Refresh list';

  @override
  String get bootstrapStartLan => 'Start LAN node';

  @override
  String get bootstrapStopLan => 'Stop LAN node';

  @override
  String get bootstrapLanStopped => 'LAN node is stopped';

  @override
  String get bootstrapLanRunning => 'LAN node is running';

  @override
  String get bootstrapLanKeyChanges => 'The DHT key changes when the node restarts. Share the current full key.';

  @override
  String get bootstrapLanFirewallHint => 'Other devices must reach this UDP port through your local firewall.';

  @override
  String get bootstrapCopyNode => 'Copy node details';

  @override
  String get bootstrapShareNode => 'Share node details';

  @override
  String get bootstrapOperationFailed => 'The network setting could not be applied.';

  @override
  String get bootstrapServiceUnavailable => 'Network settings are unavailable for this backend.';

  @override
  String get bootstrapSource => 'Official public node list';

  @override
  String get bootstrapOnline => 'Online';

  @override
  String get bootstrapOffline => 'Offline';

  @override
  String bootstrapProtocolStatus(String udp, String tcp) {
    return 'UDP: $udp · TCP: $tcp';
  }

  @override
  String get errorNotFriend => 'This person is no longer in your friend list. Add them again to send messages.';

  @override
  String get chatAcceptWithPassword => 'Accept with password';

  @override
  String chatGroupPasswordTitle(String name) {
    return 'Password for $name';
  }

  @override
  String get chatGroupPasswordField => 'Group password';

  @override
  String chatGroupJoinRefusedPassword(String name) {
    return '$name refused the join: the password is wrong or missing.';
  }

  @override
  String chatGroupJoinRefusedFull(String name) {
    return '$name refused the join: the group is full.';
  }

  @override
  String chatGroupJoinRefused(String name) {
    return '$name refused the join.';
  }

  @override
  String chatGroupReconnectRefused(String name) {
    return '$name refused to reconnect. Its history is kept; retry with the group\'s password.';
  }

  @override
  String get firstChatTitle => 'Your first Morse chat';

  @override
  String get firstChatStart => 'Get started';

  @override
  String get firstChatDismiss => 'Dismiss guide';

  @override
  String get firstChatKeyTitle => '1. Key CQ to yourself';

  @override
  String get firstChatKeyBody => 'Use the key to send CQ. A short press makes a dot and a longer press makes a dash. Your decoded draft stays read-only.';

  @override
  String get firstChatSelf => 'Try in my self chat';

  @override
  String get firstChatListenTitle => '2. Listen and correct';

  @override
  String get firstChatListenBody => 'Before sending, use Preview to hear the draft and Backspace to remove a mistake. After sending, tap Play on your message. Self-chat messages stay on this device.';

  @override
  String get firstChatFriendTitle => '3. Chat with a friend';

  @override
  String get firstChatFriendBody => 'Open Contacts, add your friend by QR code or Tox ID, and wait for the friend request to be accepted.';

  @override
  String get firstChatFriend => 'Add a friend';

  @override
  String get firstChatOnline => 'Keep both apps running and connected for messages to reach your friend.';

  @override
  String get pendingMessagesTitle => 'Pending and failed messages';

  @override
  String get pendingMessagesExplanation => 'Queued messages stay on this device until both apps are connected. You can cancel a queued message or retry a confirmed failure.';

  @override
  String get pendingMessagesEmpty => 'No pending or failed messages';

  @override
  String get deliveryDetailsTitle => 'Delivery details';

  @override
  String get deliveryLocalTitle => 'Saved locally';

  @override
  String get deliveryLocalDetail => 'This self-chat message is saved on this device.';

  @override
  String get deliverySentDetail => 'Your app handed the message to transport. Waiting for the recipient to confirm receipt.';

  @override
  String get deliveryPeerTitle => 'Recipient received';

  @override
  String get deliveryPeerDetail => 'The recipient confirmed receipt. This does not indicate that they read or listened to it.';

  @override
  String get deliveryGroupTitle => 'Received by a group member';

  @override
  String get deliveryGroupDetail => 'At least one group member confirmed receipt. Other members may still be offline.';

  @override
  String get deliveryLocalOffline => 'This device is not connected yet.';

  @override
  String get deliveryPeerOffline => 'Your friend is offline.';

  @override
  String get deliveryGroupWaiting => 'Waiting for a connection to the group.';

  @override
  String get chatPreviewDraft => 'Preview draft';

  @override
  String get chatStopPreview => 'Stop preview';

  @override
  String get chatMessagePlayback => 'Message playback';

  @override
  String get chatOriginalRhythm => 'Original keying rhythm';

  @override
  String get chatListenerRhythm => 'Your listening speed';

  @override
  String get chatOriginalAvailable => 'Recorded marks and gaps are available.';

  @override
  String get chatOriginalUnavailable => 'Original rhythm unavailable; plays at your listening speed.';

  @override
  String get chatOriginalPlaying => 'Playing original rhythm';

  @override
  String get chatListenerPlaying => 'Playing at your listening speed';

  @override
  String get chatPause => 'Pause';

  @override
  String get chatResume => 'Resume';

  @override
  String get chatPreviousWord => 'Previous word';

  @override
  String get chatNextWord => 'Next word';

  @override
  String chatWordNumber(int number) {
    return 'Word $number';
  }

  @override
  String get chatRangeStart => 'First word';

  @override
  String get chatRangeEnd => 'Last word';

  @override
  String get chatRepeatRange => 'Replay selected words';

  @override
  String get chatLoopRange => 'Loop selected words';

  @override
  String get chatPlaybackProgress => 'Playback progress';

  @override
  String chatWordProgress(int current, int total) {
    return 'Word $current of $total';
  }

  @override
  String get chatOriginalPreference => 'Use original rhythm when a matching recording is available.';

  @override
  String chatConversationActions(String name) {
    return 'Actions for $name';
  }

  @override
  String get chatDraftSaveFailed => 'The draft could not be saved. Keep this screen open or send it now.';

  @override
  String get chatSearchClearDates => 'Clear date range';

  @override
  String chatGroupReconnectFailed(String name) {
    return '$name refused to reconnect. Its history is kept; you can retry.';
  }
}
