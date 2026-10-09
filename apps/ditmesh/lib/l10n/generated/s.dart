import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 's_de.dart';
import 's_en.dart';
import 's_es.dart';
import 's_fr.dart';
import 's_ja.dart';
import 's_ko.dart';
import 's_pt.dart';
import 's_ru.dart';
import 's_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of S
/// returned by `S.of(context)`.
///
/// Applications need to include `S.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/s.dart';
///
/// return MaterialApp(
///   localizationsDelegates: S.localizationsDelegates,
///   supportedLocales: S.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the S.supportedLocales
/// property.
abstract class S {
  S(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static S of(BuildContext context) {
    return Localizations.of<S>(context, S)!;
  }

  static const LocalizationsDelegate<S> delegate = _SDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('ja'),
    Locale('ko'),
    Locale('pt'),
    Locale('ru'),
    Locale('zh'),
    Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant')
  ];

  /// Product name; never translated
  ///
  /// In en, this message translates to:
  /// **'DitMesh'**
  String get appName;

  /// Shell destination: Morse training
  ///
  /// In en, this message translates to:
  /// **'Learn'**
  String get navLearn;

  /// Shell destination: 1:1 Morse chat over Tox
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get navChat;

  /// Shell destination: Tox group chats
  ///
  /// In en, this message translates to:
  /// **'Groups'**
  String get navGroups;

  /// Shell destination: profile, identity, settings
  ///
  /// In en, this message translates to:
  /// **'Me'**
  String get navMe;

  /// Shell destination: Morse handbook (alphabet, prosigns, Q-codes, translator)
  ///
  /// In en, this message translates to:
  /// **'Reference'**
  String get navReference;

  /// One-line subtitle of the Learn destination (Learn home header)
  ///
  /// In en, this message translates to:
  /// **'Koch-method lessons, keying drills and copy practice.'**
  String get navLearnDescription;

  /// One-line subtitle of the Chat destination (empty conversation list, placeholder)
  ///
  /// In en, this message translates to:
  /// **'Serverless one-to-one Morse conversations over Tox P2P.'**
  String get navChatDescription;

  /// One-line subtitle of the Groups destination (empty group list, placeholder)
  ///
  /// In en, this message translates to:
  /// **'Group nets — many operators keying on one shared channel.'**
  String get navGroupsDescription;

  /// One-line subtitle of the Reference destination
  ///
  /// In en, this message translates to:
  /// **'Alphabet, prosigns, Q-codes, abbreviations and a two-way translator.'**
  String get navReferenceDescription;

  /// One-line subtitle of the Me destination
  ///
  /// In en, this message translates to:
  /// **'Your callsign, Tox identity, progress and settings.'**
  String get navMeDescription;

  /// Strip above the shell content after being offline for a while (ConnectionBannerPolicy)
  ///
  /// In en, this message translates to:
  /// **'Offline: not connected to the Tox network. Messages will be sent when you are back online.'**
  String get shellOfflineBanner;

  /// Generic dialog button that acknowledges and closes a message (currently unused; keep short)
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get actionOk;

  /// Generic button that dismisses a dialog or sheet without changing anything (e.g. delete-identity dialog, chat layout)
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get actionCancel;

  /// Generic button that saves a form (edit profile, change password pages)
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get actionSave;

  /// Generic destructive button that deletes an item (currently unused; keep short)
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get actionDelete;

  /// Button that copies the user's Tox ID to the clipboard (My Tox ID sheet, Tox ID QR dialog)
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get actionCopy;

  /// Generic button that opens the system share sheet (currently unused; keep short)
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get actionShare;

  /// Button on the startup error screen that retries opening the identity
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get actionRetry;

  /// Generic button that closes a dialog (Tox ID QR dialog, language picker)
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get actionClose;

  /// Generic search action label (currently unused; keep short)
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get actionSearch;

  /// Generic settings action label (currently unused; keep short)
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get actionSettings;

  /// Tox DHT bootstrap in progress
  ///
  /// In en, this message translates to:
  /// **'Connecting…'**
  String get connectionConnecting;

  /// Connected to the Tox network
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get connectionOnline;

  /// Not connected to the Tox network
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get connectionOffline;

  /// Outgoing message waiting for the peer to come online
  ///
  /// In en, this message translates to:
  /// **'Queued on this device'**
  String get messageStatusPending;

  /// Explains why a message can stay queued (P2P, no store-and-forward server)
  ///
  /// In en, this message translates to:
  /// **'The message is saved locally. It will send when both apps are running and their networks can connect.'**
  String get messageStatusPendingDetail;

  /// Chat: tooltip/semantics of the status icon on an outgoing message that is being sent
  ///
  /// In en, this message translates to:
  /// **'Sending'**
  String get messageStatusSending;

  /// Chat: tooltip/semantics of the status icon on an outgoing message that has left the send queue. It does not confirm the peer received it (Tox reports no separate failure here), so avoid words like 'delivered' or 'read'
  ///
  /// In en, this message translates to:
  /// **'Sent'**
  String get messageStatusSent;

  /// Chat: tooltip/semantics of the status icon on an outgoing message that could not be delivered
  ///
  /// In en, this message translates to:
  /// **'Failed to send'**
  String get messageStatusFailed;

  /// ChatException code wrong_password
  ///
  /// In en, this message translates to:
  /// **'Wrong password. Try again.'**
  String get errorWrongPassword;

  /// ChatException code peer_offline
  ///
  /// In en, this message translates to:
  /// **'This contact is offline. Tox has no server, so the message waits until they come back.'**
  String get errorPeerOffline;

  /// ChatException code invalid_tox_id
  ///
  /// In en, this message translates to:
  /// **'That is not a valid Tox ID (76 hex characters).'**
  String get errorInvalidToxId;

  /// ChatException code already_friend
  ///
  /// In en, this message translates to:
  /// **'This Tox ID is already in your friend list.'**
  String get errorAlreadyFriend;

  /// ChatException code own_id
  ///
  /// In en, this message translates to:
  /// **'That is your own Tox ID.'**
  String get errorOwnId;

  /// ChatException code group_not_found
  ///
  /// In en, this message translates to:
  /// **'Group not found.'**
  String get errorGroupNotFound;

  /// ChatException code message_too_long
  ///
  /// In en, this message translates to:
  /// **'Message is too long for one Tox message.'**
  String get errorMessageTooLong;

  /// Fallback for any other ChatException code
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get errorUnknown;

  /// ChatException code teardown_unconfirmed: a stopped Tox session may still be writing, so backup/restore/delete/password changes are refused
  ///
  /// In en, this message translates to:
  /// **'The previous Tox session has not fully stopped. Try again in a moment, or restart the app.'**
  String get errorTeardownUnconfirmed;

  /// ChatException code identity_recovery_pending: create() refused because a previous identity from an interrupted restore is still waiting in staging
  ///
  /// In en, this message translates to:
  /// **'A previous identity is still waiting to be recovered. Restart the app to retry, or delete the identity data to start over.'**
  String get errorIdentityRecoveryPending;

  /// Settings tile on the Me page
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageTitle;

  /// Follow the OS language
  ///
  /// In en, this message translates to:
  /// **'System default'**
  String get languageSystemDefault;

  /// Inline error inside the language dialog when persisting the chosen language failed (the previous choice is kept and the dialog stays open)
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save the language setting. Try again.'**
  String get languageSaveFailed;

  /// Learn home, Koch lesson card: which lesson the user is on out of the whole course (e.g. 'Lesson 4 of 42'); also used in the appearance style preview
  ///
  /// In en, this message translates to:
  /// **'Lesson {lesson} of {total}'**
  String learnLessonOf(int lesson, int total);

  /// Learn home, Koch lesson card: how many Morse characters the user has unlocked so far
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 character learned} other{{count} characters learned}}'**
  String learnCharsLearned(int count);

  /// Learn home, 'Today' card: characters practised today (receive and send practice both count) versus the daily goal (e.g. '120 / 200 chars')
  ///
  /// In en, this message translates to:
  /// **'{done} / {goal} chars'**
  String learnDailyGoalProgress(int done, int goal);

  /// Learn home, 'Today' card: number of consecutive days with practice
  ///
  /// In en, this message translates to:
  /// **'{days, plural, =1{1 day streak} other{{days} day streak}}'**
  String learnStreakDays(int days);

  /// Learn home: trailing count on the 'Review due characters' button — how many spaced-repetition characters are due for review
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Nothing due} =1{1 due} other{{count} due}}'**
  String learnReviewDueCount(int count);

  /// Receive drill: result line for any round that was not a perfect copy (including one where every sent character was right but extra characters were typed); correct and total count characters
  ///
  /// In en, this message translates to:
  /// **'{correct} of {total} correct'**
  String learnRoundScore(int correct, int total);

  /// Receive drill: header showing the number of the current round (1-based)
  ///
  /// In en, this message translates to:
  /// **'Round {round}'**
  String learnRoundOf(int round);

  /// A percentage; percent is already rounded (0-100). Used for the daily-goal completion inside the ring on the Learn home 'Today' card, and for accuracy in receive/send results and their per-character list
  ///
  /// In en, this message translates to:
  /// **'{percent}%'**
  String learnAccuracyPercent(int percent);

  /// Receive drill session summary: how many characters were played to the user in the session
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 character sent} other{{count} characters sent}}'**
  String learnCharsSent(int count);

  /// Receive drill session summary: verdict when the lesson was passed and a new Koch character was unlocked; {char} is that character
  ///
  /// In en, this message translates to:
  /// **'Next character unlocked: {char}'**
  String learnLessonUnlocked(String char);

  /// Receive drill: confusion chip when the user typed nothing for the sent character {target}
  ///
  /// In en, this message translates to:
  /// **'{target} missed'**
  String learnConfusedMissed(String target);

  /// Receive drill: confusion chip when the user typed {answered} for the sent character {target}
  ///
  /// In en, this message translates to:
  /// **'{target} heard as {answered}'**
  String learnConfusedAs(String target, String answered);

  /// Training settings and send-practice tips: a speed in words per minute; wpm is pre-formatted (e.g. 18).
  ///
  /// In en, this message translates to:
  /// **'{wpm} WPM'**
  String learnWpmValue(String wpm);

  /// Training settings: the sidetone pitch in hertz; hz is pre-formatted (e.g. 600)
  ///
  /// In en, this message translates to:
  /// **'{hz} Hz'**
  String learnHzValue(String hz);

  /// Training settings: the session length in characters (slider value and label)
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 character} other{{count} characters}}'**
  String learnCharsCount(int count);

  /// Statistics overview, 'Koch lesson' tile: current lesson out of the total (e.g. '4 / 42')
  ///
  /// In en, this message translates to:
  /// **'{lesson} / {total}'**
  String statsLessonOf(int lesson, int total);

  /// Statistics overview, 'Koch lesson' tile: detail line with the number of unlocked characters
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 character learned} other{{count} characters learned}}'**
  String statsCharsLearned(int count);

  /// Statistics: a percentage (accuracy tiles, chart axis ticks); percent is pre-formatted (e.g. 92.5)
  ///
  /// In en, this message translates to:
  /// **'{percent}%'**
  String statsPercent(String percent);

  /// Statistics overview, 'Practice' tile: total characters copied across all sessions
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 char copied} other{{count} chars copied}}'**
  String statsCharsCopied(int count);

  /// Statistics: number of practice sessions (overview 'Practice' tile, statistics summary card)
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 session} other{{count} sessions}}'**
  String statsSessions(int count);

  /// Statistics: the current streak length in days ('Streak' tile)
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 day} other{{count} days}}'**
  String statsDays(int count);

  /// Statistics, 'Streak' tile: detail line with the longest streak ever reached
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{best 1 day} other{best {count} days}}'**
  String statsBestStreak(int count);

  /// Statistics, 'Daily goal' tile: characters practised today (receive and send practice both count) versus the daily goal
  ///
  /// In en, this message translates to:
  /// **'{done} / {goal} chars'**
  String statsGoalProgress(int done, int goal);

  /// Statistics, 'Daily goal' tile: how many more characters must be practised to reach today's goal
  ///
  /// In en, this message translates to:
  /// **'{remaining, plural, =1{1 char to go} other{{remaining} chars to go}}'**
  String statsGoalRemaining(int remaining);

  /// Statistics, accuracy trend chart: subtitle saying how many recent sessions are plotted
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Last session} other{Last {count} sessions}}'**
  String statsTrendSubtitle(int count);

  /// Statistics, accuracy trend chart: tooltip heading for a tapped point — which session out of those plotted
  ///
  /// In en, this message translates to:
  /// **'Session {index} of {total}'**
  String statsTooltipSession(int index, int total);

  /// Statistics, accuracy trend chart: tooltip line with correct characters out of characters attempted in that session (copied for a receive session, keyed for a send session)
  ///
  /// In en, this message translates to:
  /// **'{correct} / {total} correct'**
  String statsTooltipCopied(int correct, int total);

  /// Statistics, accuracy trend chart: tooltip line with the Koch lesson the session belonged to
  ///
  /// In en, this message translates to:
  /// **'Lesson {lesson}'**
  String statsTooltipLesson(int lesson);

  /// Statistics, character grid: semantics label giving how many times a character was played
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 attempt} other{{count} attempts}}'**
  String statsAttempts(int count);

  /// Statistics, character detail dialog: how often the character was copied correctly out of all attempts
  ///
  /// In en, this message translates to:
  /// **'{correct} of {attempts} correct'**
  String statsCorrectOf(int correct, int attempts);

  /// Statistics, character detail dialog: the Koch lesson in which this character was introduced
  ///
  /// In en, this message translates to:
  /// **'Introduced in lesson {lesson}'**
  String statsLessonIntroduced(int lesson);

  /// Statistics, character detail dialog: the character's Leitner box in spaced repetition (e.g. 'Box 2 of 5')
  ///
  /// In en, this message translates to:
  /// **'Box {box} of {maxBox}'**
  String statsSrsBox(int box, int maxBox);

  /// Statistics, character detail dialog: when the character is next due for spaced-repetition review
  ///
  /// In en, this message translates to:
  /// **'{days, plural, =1{Due tomorrow} other{Due in {days} days}}'**
  String statsSrsDueIn(int days);

  /// Statistics, character detail dialog: how many times the character was confused with another one
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 time} other{{count} times}}'**
  String statsTimes(int count);

  /// Statistics, confusion heatmap: screen-reader label of one cell — sent character {target} was answered as {answered} {count} times
  ///
  /// In en, this message translates to:
  /// **'{target} answered as {answered}, {count, plural, =1{1 time} other{{count} times}}'**
  String statsHeatmapCell(String target, String answered, int count);

  /// Statistics, practice calendar: line under the calendar describing the selected day; date is pre-formatted, chars is the characters practised that day
  ///
  /// In en, this message translates to:
  /// **'{date}: {chars, plural, =0{no practice} other{{chars} chars}}'**
  String statsCalendarDay(String date, int chars);

  /// Statistics, practice calendar: subtitle with how many days had practice in the shown period
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 active day} other{{count} active days}}'**
  String statsActiveDays(int count);

  /// Reference: number of entries in a group, shown at the right of the group's header
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 entry} other{{count} entries}}'**
  String referenceEntryCount(int count);

  /// Reference playback settings: a speed in words per minute; wpm is pre-rounded (e.g. 18)
  ///
  /// In en, this message translates to:
  /// **'{wpm} WPM'**
  String referenceWpmValue(String wpm);

  /// Reference playback settings: the tone pitch in hertz; hz is pre-rounded (e.g. 600)
  ///
  /// In en, this message translates to:
  /// **'{hz} Hz'**
  String referenceHzValue(String hz);

  /// Reference translator, Text to Morse: note listing input characters that have no Morse code and were skipped; chars is that list
  ///
  /// In en, this message translates to:
  /// **'Skipped (no Morse code): {chars}'**
  String referenceSkippedChars(String chars);

  /// Mnemonic dialog: 1-based position of the character in the Koch teaching order
  ///
  /// In en, this message translates to:
  /// **'Koch position: {position}'**
  String referenceKochPositionValue(int position);

  /// Reference translator, Key mode: the speed estimated from the user's keying; wpm is pre-rounded
  ///
  /// In en, this message translates to:
  /// **'Estimated {wpm} WPM'**
  String referenceEstimatedSpeed(String wpm);

  /// Snackbar after the user's Tox ID was copied to the clipboard
  ///
  /// In en, this message translates to:
  /// **'Tox ID copied to clipboard'**
  String get accountCopied;

  /// Button / tooltip that shows the user's Tox ID as a QR code (identity card, backup wizard)
  ///
  /// In en, this message translates to:
  /// **'Show QR code'**
  String get accountShowQr;

  /// Label and dialog title for the user's Tox ID (the 76-character Tox address others use to add them)
  ///
  /// In en, this message translates to:
  /// **'Tox ID'**
  String get accountToxId;

  /// Text field label for the name other Tox users see (create identity, edit profile)
  ///
  /// In en, this message translates to:
  /// **'Display name'**
  String get accountDisplayName;

  /// Hint inside the display-name field on the create-identity page
  ///
  /// In en, this message translates to:
  /// **'Your callsign or nickname'**
  String get accountDisplayNameHint;

  /// Validation error when the display-name field is empty
  ///
  /// In en, this message translates to:
  /// **'Enter a display name'**
  String get accountDisplayNameRequired;

  /// Edit profile page: text field label for the Tox status message shown to friends
  ///
  /// In en, this message translates to:
  /// **'Status message'**
  String get accountStatusMessage;

  /// Unlock page: label of the password field; also the identity card's lock-icon tooltip
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get accountPassword;

  /// Label of the optional password field (create identity, restore backup)
  ///
  /// In en, this message translates to:
  /// **'Password (optional)'**
  String get accountPasswordOptional;

  /// Label of the field where the password is typed a second time
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get accountConfirmPassword;

  /// Validation error when the two password fields differ
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get accountPasswordsDoNotMatch;

  /// Tooltip of the eye button that reveals the typed password
  ///
  /// In en, this message translates to:
  /// **'Show password'**
  String get accountShowPassword;

  /// Tooltip of the eye button that hides the typed password again
  ///
  /// In en, this message translates to:
  /// **'Hide password'**
  String get accountHidePassword;

  /// Password strength meter: verdict for a weak password, with advice
  ///
  /// In en, this message translates to:
  /// **'Weak: use at least 8 characters'**
  String get accountStrengthWeak;

  /// Password strength meter: verdict for a fair password, with advice
  ///
  /// In en, this message translates to:
  /// **'Fair: 12+ characters with mixed types is better'**
  String get accountStrengthFair;

  /// Password strength meter: verdict for a strong password
  ///
  /// In en, this message translates to:
  /// **'Strong'**
  String get accountStrengthStrong;

  /// Startup splash: shown while the app checks whether an identity exists on this device
  ///
  /// In en, this message translates to:
  /// **'Checking your identity…'**
  String get accountStartupInspecting;

  /// Startup splash: shown while the identity is being opened
  ///
  /// In en, this message translates to:
  /// **'Opening your identity…'**
  String get accountStartupOpening;

  /// Startup error screen: title when the identity could not be read
  ///
  /// In en, this message translates to:
  /// **'Could not start'**
  String get accountStartupFailedTitle;

  /// Startup error screen: explanation under the title; nothing was changed and the user can retry
  ///
  /// In en, this message translates to:
  /// **'DitMesh could not read your identity. Nothing was changed; you can try again.'**
  String get accountStartupFailedBody;

  /// Tooltip of the Tox connection chip while offline; tapping it reconnects
  ///
  /// In en, this message translates to:
  /// **'Tap to reconnect'**
  String get accountConnectionTapToReconnect;

  /// Welcome page (first launch): title explaining the identity is stored locally
  ///
  /// In en, this message translates to:
  /// **'Your identity lives on this device'**
  String get accountWelcomeTitle;

  /// Welcome page: introductory paragraph about the serverless Tox identity
  ///
  /// In en, this message translates to:
  /// **'DitMesh uses the Tox peer-to-peer network. There is no server and no account to sign up for: your identity is a key pair stored only here.'**
  String get accountWelcomeIntro;

  /// Welcome page: bullet point — no server or sign-up, peers talk directly
  ///
  /// In en, this message translates to:
  /// **'No server, no phone number, no e-mail. Peers talk to each other directly, in Morse.'**
  String get accountWelcomePointNoServer;

  /// Welcome page: bullet point — training progress is stored with the identity
  ///
  /// In en, this message translates to:
  /// **'Chat one-to-one or in groups using Morse code, with a straight key or iambic paddles.'**
  String get accountWelcomePointTraining;

  /// Welcome page: bullet point warning that only a backup can recover the identity
  ///
  /// In en, this message translates to:
  /// **'Nobody can recover an identity for you. Back it up right after creating it, or you will lose it with the device.'**
  String get accountWelcomePointBackup;

  /// Welcome page: button that starts creating a new identity
  ///
  /// In en, this message translates to:
  /// **'Create identity'**
  String get accountCreateIdentity;

  /// Welcome page: button that restores an identity from a backup file
  ///
  /// In en, this message translates to:
  /// **'Restore from backup'**
  String get accountRestoreFromBackup;

  /// Create identity page: app bar title
  ///
  /// In en, this message translates to:
  /// **'Create your identity'**
  String get accountCreateTitle;

  /// Create identity page: explanation of the display name and the optional password
  ///
  /// In en, this message translates to:
  /// **'Pick a name others will see. A password encrypts the identity file on this device; leave it empty if you prefer to open the app without one.'**
  String get accountCreateBody;

  /// Create identity page: submit button
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get accountCreateButton;

  /// Create identity page: submit button label while the identity is being created
  ///
  /// In en, this message translates to:
  /// **'Creating…'**
  String get accountCreating;

  /// Backup wizard (after creating an identity): title urging the user to back up now
  ///
  /// In en, this message translates to:
  /// **'Back up your identity now'**
  String get accountBackupTitle;

  /// Backup wizard: explanation that a lost device means a lost identity without a backup
  ///
  /// In en, this message translates to:
  /// **'Your identity exists only on this device. If it is lost, reset or stolen, there is no way to recover it: your contacts will not recognise a new identity and your training progress is gone.'**
  String get accountBackupBody;

  /// Backup wizard: what the backup file contains and where to keep it
  ///
  /// In en, this message translates to:
  /// **'The backup file contains your identity key, encrypted with your password, and your training progress. Keep it somewhere safe, outside this device.'**
  String get accountBackupWhatIsInside;

  /// Backup wizard: what the file holds when the identity has no password (the key is NOT encrypted)
  ///
  /// In en, this message translates to:
  /// **'The backup file contains your identity key unencrypted, and your training progress. Anyone who gets this file can use your identity: set a password first if you want the key encrypted, and keep the file somewhere safe.'**
  String get accountBackupWhatIsInsidePlain;

  /// Create identity / change password: what the password protects and what it does not
  ///
  /// In en, this message translates to:
  /// **'Your password encrypts your identity key. Message history remains unencrypted on disk; device encryption can protect it.'**
  String get accountPasswordScope;

  /// Me page: section header for the notification settings
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get accountSectionNotifications;

  /// Me page: switch for all notifications
  ///
  /// In en, this message translates to:
  /// **'Show notifications'**
  String get accountNotificationsEnable;

  /// Me page: subtitle of the notifications switch
  ///
  /// In en, this message translates to:
  /// **'New messages, friend requests and group invites'**
  String get accountNotificationsEnableSubtitle;

  /// Me page: switch for showing message text and Morse in notifications
  ///
  /// In en, this message translates to:
  /// **'Show message content'**
  String get accountNotificationsContent;

  /// Me page: subtitle of the message-content switch
  ///
  /// In en, this message translates to:
  /// **'Text and Morse in banners and on the lock screen. Off: only that a message arrived.'**
  String get accountNotificationsContentSubtitle;

  /// Me page: button asking the OS for notification permission
  ///
  /// In en, this message translates to:
  /// **'Allow notifications'**
  String get accountNotificationsAllow;

  /// Me page: subtitle of the permission button
  ///
  /// In en, this message translates to:
  /// **'Ask the system for permission'**
  String get accountNotificationsAllowSubtitle;

  /// Me page: status line when the user turned the message notification channel off in the Android system settings
  ///
  /// In en, this message translates to:
  /// **'Blocked in system settings'**
  String get accountNotificationsBlocked;

  /// Me page: explains that the OS drops message notifications until the channel is turned on again in system settings
  ///
  /// In en, this message translates to:
  /// **'Message notifications for DitMesh are turned off in the system settings. Turn them on there to get banners again.'**
  String get accountNotificationsBlockedSubtitle;

  /// Me page: snack bar when the OS denied notification permission
  ///
  /// In en, this message translates to:
  /// **'Notifications are off for DitMesh in the system settings.'**
  String get accountNotificationsDenied;

  /// Backup wizard: button that saves the backup file (desktop)
  ///
  /// In en, this message translates to:
  /// **'Save backup file'**
  String get accountBackupSaveFile;

  /// Backup wizard: button that shares the backup file via the system share sheet (mobile)
  ///
  /// In en, this message translates to:
  /// **'Share backup file'**
  String get accountBackupShareFile;

  /// Snackbar / status line after the backup file was saved
  ///
  /// In en, this message translates to:
  /// **'Backup saved'**
  String get accountBackupSaved;

  /// Snackbar when the user cancelled saving the backup
  ///
  /// In en, this message translates to:
  /// **'Backup was not saved'**
  String get accountBackupNotSaved;

  /// Snackbar prefix when writing the backup failed; followed by ': ' and the error message
  ///
  /// In en, this message translates to:
  /// **'Could not write the backup'**
  String get accountBackupFailed;

  /// Backup wizard: checkbox the user must tick to confirm they understand the risk
  ///
  /// In en, this message translates to:
  /// **'I understand that without this backup my identity cannot be recovered.'**
  String get accountBackupAcknowledge;

  /// Backup wizard: button that leaves the wizard and opens the app
  ///
  /// In en, this message translates to:
  /// **'Continue to DitMesh'**
  String get accountBackupContinue;

  /// Backup wizard: explains that the Tox ID is how friends add the user
  ///
  /// In en, this message translates to:
  /// **'Your Tox ID is how friends add you. Share it as text or as a QR code.'**
  String get accountBackupShowQrHint;

  /// Restore backup page: app bar title
  ///
  /// In en, this message translates to:
  /// **'Restore from backup'**
  String get accountRestoreTitle;

  /// Restore backup page: explanation of which file to pick and the password
  ///
  /// In en, this message translates to:
  /// **'Choose a backup file exported from DitMesh. If the identity was protected with a password you will need it here.'**
  String get accountRestoreBody;

  /// Restore backup page: button that opens the file picker
  ///
  /// In en, this message translates to:
  /// **'Choose backup file'**
  String get accountRestoreChooseFile;

  /// Restore backup page: error when Restore is pressed before choosing a file
  ///
  /// In en, this message translates to:
  /// **'Choose a backup file first'**
  String get accountRestoreNoFile;

  /// Restore backup page: submit button
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get accountRestoreButton;

  /// Restore backup page: submit button label while restoring
  ///
  /// In en, this message translates to:
  /// **'Restoring…'**
  String get accountRestoring;

  /// Restore backup page: error when the chosen file is not a DitMesh backup
  ///
  /// In en, this message translates to:
  /// **'This file is not a DitMesh backup.'**
  String get accountRestoreInvalidFile;

  /// Restore backup page: warning that restoring replaces the current identity
  ///
  /// In en, this message translates to:
  /// **'Restoring replaces the identity currently on this device.'**
  String get accountRestoreReplacesWarning;

  /// Unlock page (password-protected identity): title
  ///
  /// In en, this message translates to:
  /// **'Unlock your identity'**
  String get accountUnlockTitle;

  /// Unlock page: explanation that the identity file is encrypted
  ///
  /// In en, this message translates to:
  /// **'Your identity file is encrypted. Enter the password to continue.'**
  String get accountUnlockBody;

  /// Unlock page: submit button
  ///
  /// In en, this message translates to:
  /// **'Unlock'**
  String get accountUnlockButton;

  /// Unlock page: submit button label while unlocking
  ///
  /// In en, this message translates to:
  /// **'Unlocking…'**
  String get accountUnlocking;

  /// Unlock page: text button that switches to restoring from a backup
  ///
  /// In en, this message translates to:
  /// **'Restore from backup instead'**
  String get accountUnlockRestoreInstead;

  /// Me page / snackbar: shown when no identity is loaded
  ///
  /// In en, this message translates to:
  /// **'No identity loaded'**
  String get accountMeNoIdentity;

  /// Me page: section header for account settings
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get accountSectionAccount;

  /// Me page: section header for training settings
  ///
  /// In en, this message translates to:
  /// **'Training'**
  String get accountSectionTraining;

  /// Me page: section header for app information (licence, source code, backend)
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get accountSectionAbout;

  /// Me page: section header for destructive actions (delete identity)
  ///
  /// In en, this message translates to:
  /// **'Danger zone'**
  String get accountSectionDanger;

  /// Me page tile and edit profile page title
  ///
  /// In en, this message translates to:
  /// **'Edit profile'**
  String get accountEditProfile;

  /// Edit profile: explains that the name and status are shown to friends on Tox
  ///
  /// In en, this message translates to:
  /// **'Shown to your contacts on the Tox network.'**
  String get accountEditProfileBody;

  /// Me page tile / page title to add a password to an unprotected identity
  ///
  /// In en, this message translates to:
  /// **'Set password'**
  String get accountSetPassword;

  /// Me page tile / page title to change the identity password
  ///
  /// In en, this message translates to:
  /// **'Change password'**
  String get accountChangePassword;

  /// Change password page: button that removes the password
  ///
  /// In en, this message translates to:
  /// **'Remove password'**
  String get accountRemovePassword;

  /// Change password page: label of the current password field
  ///
  /// In en, this message translates to:
  /// **'Current password'**
  String get accountCurrentPassword;

  /// Change password page: label of the new password field
  ///
  /// In en, this message translates to:
  /// **'New password'**
  String get accountNewPassword;

  /// Snackbar after the password was set or changed
  ///
  /// In en, this message translates to:
  /// **'Password updated'**
  String get accountPasswordUpdated;

  /// Snackbar after the password was removed
  ///
  /// In en, this message translates to:
  /// **'Password removed'**
  String get accountPasswordRemoved;

  /// Snackbar after the profile was saved
  ///
  /// In en, this message translates to:
  /// **'Profile updated'**
  String get accountProfileUpdated;

  /// Me page: tile that exports an identity backup
  ///
  /// In en, this message translates to:
  /// **'Export backup'**
  String get accountExportBackup;

  /// Me page: subtitle of the export-backup tile
  ///
  /// In en, this message translates to:
  /// **'Save your identity and training progress to a file'**
  String get accountExportBackupSubtitle;

  /// Me page: tile that opens the training / playback settings
  ///
  /// In en, this message translates to:
  /// **'Playback & training defaults'**
  String get accountTrainingDefaults;

  /// Me page: subtitle of the training-defaults tile listing what it controls
  ///
  /// In en, this message translates to:
  /// **'Speed, tone, Farnsworth spacing'**
  String get accountTrainingDefaultsSubtitle;

  /// Placeholder text for the training-defaults page (currently unused)
  ///
  /// In en, this message translates to:
  /// **'Speed, tone and Farnsworth defaults will live here.'**
  String get accountTrainingDefaultsPlaceholder;

  /// Me page, About section: tile title for the software licence
  ///
  /// In en, this message translates to:
  /// **'Licence'**
  String get accountAboutLicence;

  /// Me page, About section: the licence identifier; normally kept as is (SPDX id)
  ///
  /// In en, this message translates to:
  /// **'GPL-3.0'**
  String get accountAboutLicenceValue;

  /// Me page, About section: tile that copies the source-code link
  ///
  /// In en, this message translates to:
  /// **'Source code'**
  String get accountAboutSource;

  /// Snackbar after the source-code link was copied
  ///
  /// In en, this message translates to:
  /// **'Source link copied'**
  String get accountAboutSourceCopied;

  /// Me page, About section: tile title naming the chat backend in use (Tox, or the fake backend)
  ///
  /// In en, this message translates to:
  /// **'Backend'**
  String get accountAboutBackend;

  /// Me page, danger zone: tile that deletes the identity
  ///
  /// In en, this message translates to:
  /// **'Delete identity'**
  String get accountDeleteIdentity;

  /// Me page, danger zone: subtitle explaining what deleting erases
  ///
  /// In en, this message translates to:
  /// **'Erase this identity, history and progress from this device'**
  String get accountDeleteIdentitySubtitle;

  /// Delete identity dialog: title
  ///
  /// In en, this message translates to:
  /// **'Delete this identity?'**
  String get accountDeleteDialogTitle;

  /// Delete identity dialog: warning that the deletion cannot be undone without a backup
  ///
  /// In en, this message translates to:
  /// **'This removes your identity, chat history and training progress from this device. Without a backup it cannot be recovered. Type DELETE to confirm.'**
  String get accountDeleteDialogBody;

  /// Delete identity dialog: the word the user must type to confirm; must match the word quoted in accountDeleteConfirmHint
  ///
  /// In en, this message translates to:
  /// **'DELETE'**
  String get accountDeleteConfirmWord;

  /// Delete identity dialog: hint telling the user to type the confirmation word (accountDeleteConfirmWord)
  ///
  /// In en, this message translates to:
  /// **'Type DELETE'**
  String get accountDeleteConfirmHint;

  /// Delete identity dialog: destructive confirm button
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get accountDeleteButton;

  /// Create-identity page: button shown when the backend reports identity_recovery_pending; opens the DELETE confirmation and then deletes the waiting staging copy so a new identity can be created
  ///
  /// In en, this message translates to:
  /// **'Discard the waiting identity and start over'**
  String get accountRecoveryPendingDiscard;

  /// Restore page: confirmation line under the file picker with the picked file's size
  ///
  /// In en, this message translates to:
  /// **'Backup file selected ({bytes} bytes)'**
  String accountRestoreFileChosenSize(int bytes);

  /// Chat list: hint inside the search field
  ///
  /// In en, this message translates to:
  /// **'Search conversations'**
  String get chatSearchConversations;

  /// Chat list: empty state when there are no conversations
  ///
  /// In en, this message translates to:
  /// **'No conversations yet'**
  String get chatNoConversations;

  /// Chat list: empty state when no conversation matches the search
  ///
  /// In en, this message translates to:
  /// **'No conversations match'**
  String get chatNoSearchResults;

  /// Chat list: action that pins a conversation to the top
  ///
  /// In en, this message translates to:
  /// **'Pin'**
  String get chatPin;

  /// Chat list: action that unpins a pinned conversation
  ///
  /// In en, this message translates to:
  /// **'Unpin'**
  String get chatUnpin;

  /// Chat list: context-menu action that marks a conversation as read
  ///
  /// In en, this message translates to:
  /// **'Mark as read'**
  String get chatMarkRead;

  /// Chat list: action / confirm button that deletes a conversation
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get chatDelete;

  /// Chat list: title of the delete-conversation confirmation
  ///
  /// In en, this message translates to:
  /// **'Delete conversation?'**
  String get chatDeleteConversationTitle;

  /// Chat list: body of the delete-conversation confirmation (only local history is removed)
  ///
  /// In en, this message translates to:
  /// **'Local history for this conversation is removed. Tox keeps no copy.'**
  String get chatDeleteConversationBody;

  /// Chat list: prefix before the unsent draft preview of a conversation; keep the trailing space if the language uses one
  ///
  /// In en, this message translates to:
  /// **'Draft: '**
  String get chatDraftPrefix;

  /// Chat (wide layout): placeholder in the detail pane when no conversation is open
  ///
  /// In en, this message translates to:
  /// **'Select a conversation'**
  String get chatSelectConversation;

  /// Title of the Contacts screen (friends plus note-to-self) and tooltip of the button that opens it
  ///
  /// In en, this message translates to:
  /// **'Contacts'**
  String get chatContacts;

  /// Conversation: empty state before any message; CQ is the radio call 'calling any station' and stays as is
  ///
  /// In en, this message translates to:
  /// **'No messages yet — send CQ to start.'**
  String get chatNoMessages;

  /// Conversation: tooltip of the training-mode toggle; in training mode message text stays hidden until the user taps Reveal (chatReveal) on the message
  ///
  /// In en, this message translates to:
  /// **'Training mode'**
  String get chatTrainingMode;

  /// Conversation: snackbar when training mode is switched on
  ///
  /// In en, this message translates to:
  /// **'Training mode on: text hidden'**
  String get chatTrainingModeOn;

  /// Conversation: snackbar when training mode is switched off
  ///
  /// In en, this message translates to:
  /// **'Training mode off'**
  String get chatTrainingModeOff;

  /// Chat app-bar toggle and playback-sheet switch: play incoming messages as they arrive
  ///
  /// In en, this message translates to:
  /// **'Auto-play received Morse'**
  String get chatAutoPlay;

  /// Snack bar after turning chat auto-play on
  ///
  /// In en, this message translates to:
  /// **'Auto-play on: new messages play as they arrive'**
  String get chatAutoPlayOn;

  /// Snack bar after turning chat auto-play off
  ///
  /// In en, this message translates to:
  /// **'Auto-play off'**
  String get chatAutoPlayOff;

  /// Conversation, training mode: button on a hidden message that reveals its text
  ///
  /// In en, this message translates to:
  /// **'Reveal'**
  String get chatReveal;

  /// Conversation, training mode: placeholder shown instead of a hidden message's text
  ///
  /// In en, this message translates to:
  /// **'Listen first, then reveal'**
  String get chatHiddenText;

  /// Conversation: tooltip of the button that plays a message as Morse audio
  ///
  /// In en, this message translates to:
  /// **'Play Morse'**
  String get chatPlay;

  /// Conversation: tooltip of the button that stops Morse playback
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get chatStop;

  /// Conversation: title of the playback settings sheet and tooltip of its button
  ///
  /// In en, this message translates to:
  /// **'Playback settings'**
  String get chatPlaybackSettings;

  /// Chat playback settings: slider label for the speed of each character
  ///
  /// In en, this message translates to:
  /// **'Character speed'**
  String get chatCharacterSpeed;

  /// Chat playback settings: slider label for the Farnsworth (effective, gap-stretched) speed
  ///
  /// In en, this message translates to:
  /// **'Farnsworth speed'**
  String get chatFarnsworthSpeed;

  /// Chat playback settings: slider label for the tone pitch
  ///
  /// In en, this message translates to:
  /// **'Tone'**
  String get chatTone;

  /// Chat playback settings: unit shown after speed values (words per minute)
  ///
  /// In en, this message translates to:
  /// **'WPM'**
  String get chatWpm;

  /// Chat playback settings: unit shown after the tone value (hertz)
  ///
  /// In en, this message translates to:
  /// **'Hz'**
  String get chatHz;

  /// Group conversation / group list menu: shows the group's members
  ///
  /// In en, this message translates to:
  /// **'Members'**
  String get chatMembers;

  /// Group conversation / group list menu: leaves the group
  ///
  /// In en, this message translates to:
  /// **'Leave group'**
  String get chatLeaveGroup;

  /// Leave-group confirmation: title
  ///
  /// In en, this message translates to:
  /// **'Leave this group?'**
  String get chatLeaveGroupTitle;

  /// Leave-group confirmation: body (the chat id lets the user rejoin)
  ///
  /// In en, this message translates to:
  /// **'You will stop receiving messages. Rejoin later with the chat id.'**
  String get chatLeaveGroupBody;

  /// Leave-group confirmation: confirm button
  ///
  /// In en, this message translates to:
  /// **'Leave'**
  String get chatLeave;

  /// Group conversation header: note on legacy Tox conferences, which cannot carry Morse keying metadata
  ///
  /// In en, this message translates to:
  /// **'Legacy conference: Morse keying metadata (v2) will not be available here. Text still works.'**
  String get chatConferenceNote;

  /// Conversation menu item and confirm button that clears local message history
  ///
  /// In en, this message translates to:
  /// **'Clear history'**
  String get chatClearHistory;

  /// Conversation composer: input-mode segment for keying with a straight key
  ///
  /// In en, this message translates to:
  /// **'Straight key'**
  String get chatModeStraightKey;

  /// Conversation composer: input-mode segment for keying with iambic paddles
  ///
  /// In en, this message translates to:
  /// **'Paddles'**
  String get chatModePaddles;

  /// Hint in the read-only chat draft field: messages are keyed with the straight key or paddles, not typed
  ///
  /// In en, this message translates to:
  /// **'Key your message'**
  String get chatKeyMessage;

  /// Conversation composer: tooltip of the send button
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get chatSend;

  /// Conversation composer: error when the message exceeds one Tox message
  ///
  /// In en, this message translates to:
  /// **'Too long for one Tox message'**
  String get chatTooLong;

  /// Conversation composer, straight-key mode: hint on how to key
  ///
  /// In en, this message translates to:
  /// **'Key on the pad or press Space'**
  String get chatKeyHint;

  /// Conversation composer, paddle mode: hint on how to key (left/right Ctrl)
  ///
  /// In en, this message translates to:
  /// **'Tap the paddles or hold Ctrl (left dit, right dah)'**
  String get chatPaddleHint;

  /// Conversation composer: tooltip of the button that deletes the last keyed character
  ///
  /// In en, this message translates to:
  /// **'Delete last character'**
  String get chatDeleteLast;

  /// Contacts screen: empty state when the user has no Tox friends yet
  ///
  /// In en, this message translates to:
  /// **'No friends yet. Add one with their Tox ID.'**
  String get chatNoFriends;

  /// Friend request inbox: empty state
  ///
  /// In en, this message translates to:
  /// **'No pending requests'**
  String get chatNoRequests;

  /// Contacts screen: title of the add-friend sheet and tooltip of its button
  ///
  /// In en, this message translates to:
  /// **'Add friend'**
  String get chatAddFriend;

  /// Contacts screen: title of the sheet showing the user's own Tox ID and tooltip of its button
  ///
  /// In en, this message translates to:
  /// **'My Tox ID'**
  String get chatMyToxId;

  /// Add friend sheet: label of the Tox ID field
  ///
  /// In en, this message translates to:
  /// **'Tox ID (76 hex characters)'**
  String get chatToxIdLabel;

  /// Add friend sheet: error for a malformed Tox ID
  ///
  /// In en, this message translates to:
  /// **'Tox ID must be exactly 76 hex characters'**
  String get chatToxIdInvalid;

  /// Add friend sheet: error when the user enters their own Tox ID
  ///
  /// In en, this message translates to:
  /// **'That is your own Tox ID'**
  String get chatToxIdOwn;

  /// Add friend sheet: error when the Tox ID already belongs to a friend
  ///
  /// In en, this message translates to:
  /// **'Already in your friend list'**
  String get chatToxIdAlreadyFriend;

  /// Add friend sheet: label of the message sent with the friend request
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get chatRequestMessage;

  /// Add friend sheet: default friend-request message; CQ is the radio call 'calling any station'
  ///
  /// In en, this message translates to:
  /// **'DitMesh CQ'**
  String get chatDefaultRequestMessage;

  /// Add friend sheet: submit button that sends the friend request
  ///
  /// In en, this message translates to:
  /// **'Send request'**
  String get chatSendRequest;

  /// Snackbar after a friend request was sent
  ///
  /// In en, this message translates to:
  /// **'Friend request sent'**
  String get chatRequestSent;

  /// Add friend sheet: button that scans a Tox ID QR code with the camera
  ///
  /// In en, this message translates to:
  /// **'Scan QR'**
  String get chatScanQr;

  /// Add friend sheet (desktop): note that QR scanning needs a phone camera
  ///
  /// In en, this message translates to:
  /// **'QR scanning needs a phone camera'**
  String get chatScanQrDesktopHint;

  /// QR scan page: app bar title
  ///
  /// In en, this message translates to:
  /// **'Scan a Tox ID'**
  String get chatScanQrTitle;

  /// QR scan page: error when the scanned QR code is not a Tox ID
  ///
  /// In en, this message translates to:
  /// **'That QR code is not a Tox ID'**
  String get chatScanQrNotToxId;

  /// Friend request / group invite inbox: tooltip of the accept button
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get chatAccept;

  /// Friend request / group invite inbox: tooltip of the reject button
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get chatReject;

  /// Snackbar after a Tox ID or chat id was copied to the clipboard
  ///
  /// In en, this message translates to:
  /// **'Copied to clipboard'**
  String get chatCopied;

  /// My Tox ID sheet: shown when no identity is loaded
  ///
  /// In en, this message translates to:
  /// **'No identity loaded'**
  String get chatNoIdentity;

  /// Contacts screen: friend context-menu item that removes the friend
  ///
  /// In en, this message translates to:
  /// **'Remove friend'**
  String get chatRemoveFriend;

  /// Remove-friend confirmation: title
  ///
  /// In en, this message translates to:
  /// **'Remove this friend?'**
  String get chatRemoveFriendTitle;

  /// Remove-friend confirmation: body
  ///
  /// In en, this message translates to:
  /// **'They will no longer be able to message you.'**
  String get chatRemoveFriendBody;

  /// Remove-friend confirmation: confirm button
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get chatRemove;

  /// Groups list: empty state
  ///
  /// In en, this message translates to:
  /// **'No groups yet. Create one or join by chat id.'**
  String get chatNoGroups;

  /// Groups: title of the create-group sheet and tooltip of its button
  ///
  /// In en, this message translates to:
  /// **'Create group'**
  String get chatCreateGroup;

  /// Groups: title of the join-group sheet and tooltip of its button
  ///
  /// In en, this message translates to:
  /// **'Join group'**
  String get chatJoinGroup;

  /// Create group sheet: label of the group name field
  ///
  /// In en, this message translates to:
  /// **'Group name'**
  String get chatGroupName;

  /// Create group sheet: validation error when the name is empty
  ///
  /// In en, this message translates to:
  /// **'Give the group a name'**
  String get chatGroupNameRequired;

  /// Create group sheet: expander for advanced options
  ///
  /// In en, this message translates to:
  /// **'Advanced'**
  String get chatAdvanced;

  /// Create group sheet: switch that creates an old-style Tox conference instead of a group
  ///
  /// In en, this message translates to:
  /// **'Legacy conference (old clients)'**
  String get chatLegacyConference;

  /// Create group sheet: subtitle warning against legacy conferences
  ///
  /// In en, this message translates to:
  /// **'Not recommended: no persistent chat id, no Morse metadata.'**
  String get chatLegacyConferenceHint;

  /// Create group sheet: submit button
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get chatCreate;

  /// Join group sheet: label of the group chat id field
  ///
  /// In en, this message translates to:
  /// **'Chat id (64 hex characters)'**
  String get chatChatIdLabel;

  /// Join group sheet: error for a malformed chat id
  ///
  /// In en, this message translates to:
  /// **'Chat id must be exactly 64 hex characters'**
  String get chatChatIdInvalid;

  /// Join group sheet: label of the optional group password field
  ///
  /// In en, this message translates to:
  /// **'Password (optional)'**
  String get chatPassword;

  /// Join group sheet: submit button
  ///
  /// In en, this message translates to:
  /// **'Join'**
  String get chatJoin;

  /// Snackbar after a join request; the group shows up once a peer is found
  ///
  /// In en, this message translates to:
  /// **'Joining — the group appears once a peer is found.'**
  String get chatJoinRequested;

  /// Badge on a group that is a legacy Tox conference (group list, conversation header)
  ///
  /// In en, this message translates to:
  /// **'Conference'**
  String get chatConferenceBadge;

  /// Group list menu: copies the group's chat id
  ///
  /// In en, this message translates to:
  /// **'Copy chat id'**
  String get chatCopyChatId;

  /// Learn home: title of the Koch lesson card
  ///
  /// In en, this message translates to:
  /// **'Koch lesson'**
  String get learnLessonCardTitle;

  /// Learn home, Koch lesson card: shown once every Koch character is unlocked
  ///
  /// In en, this message translates to:
  /// **'Course complete - keep sharpening!'**
  String get learnCourseComplete;

  /// Learn home: title of the daily goal card
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get learnDailyGoalTitle;

  /// Learn home, daily goal card: shown when today's goal is reached
  ///
  /// In en, this message translates to:
  /// **'Daily goal reached'**
  String get learnDailyGoalMet;

  /// Learn home, daily goal card: shown instead of the streak when there is none
  ///
  /// In en, this message translates to:
  /// **'Start a streak today'**
  String get learnNoStreak;

  /// Learn home: primary button that starts the current Koch lesson
  ///
  /// In en, this message translates to:
  /// **'Continue lesson'**
  String get learnContinueLesson;

  /// Learn home: button that opens the receive (copy) drill picker
  ///
  /// In en, this message translates to:
  /// **'Receive practice'**
  String get learnReceivePractice;

  /// Learn home: button that opens send (keying) practice
  ///
  /// In en, this message translates to:
  /// **'Send practice'**
  String get learnSendPractice;

  /// Learn home: button that starts a spaced-repetition review of due characters
  ///
  /// In en, this message translates to:
  /// **'Review due characters'**
  String get learnReviewDue;

  /// Learn home: tooltip of the training settings button and that page's title
  ///
  /// In en, this message translates to:
  /// **'Training settings'**
  String get learnSettings;

  /// Learn tab: shown while training progress loads
  ///
  /// In en, this message translates to:
  /// **'Loading your progress...'**
  String get learnLoading;

  /// Learn tab: shown when no identity is open; training needs one
  ///
  /// In en, this message translates to:
  /// **'Create or unlock your identity to start training. Progress is stored with your identity so it travels with your backup.'**
  String get learnIdentityRequired;

  /// Learn home: error line shown when saved progress was unreadable and training restarted fresh
  ///
  /// In en, this message translates to:
  /// **'Your saved progress could not be read. Starting fresh; the old file was kept as .corrupt.'**
  String get learnLoadFailed;

  /// Learn drills: snack bar when a finished session could not be written to disk; the action retries the save
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save your progress. The result still counts while DitMesh stays open.'**
  String get learnProgressSaveFailed;

  /// Receive drill picker sheet: title
  ///
  /// In en, this message translates to:
  /// **'Choose a drill'**
  String get learnChooseDrill;

  /// Receive drill picker: drill with random groups of the characters the user already knows
  ///
  /// In en, this message translates to:
  /// **'Random groups'**
  String get learnDrillGroups;

  /// Receive drill picker: drill with common words
  ///
  /// In en, this message translates to:
  /// **'Words'**
  String get learnDrillWords;

  /// Receive drill picker: drill with amateur radio callsigns
  ///
  /// In en, this message translates to:
  /// **'Callsigns'**
  String get learnDrillCallsigns;

  /// Receive drill picker: drill with short QSO (radio contact) exchanges; QSO is a Q-code, keep as is
  ///
  /// In en, this message translates to:
  /// **'QSO'**
  String get learnDrillQso;

  /// Receive drill: one symbol per round
  ///
  /// In en, this message translates to:
  /// **'Single characters'**
  String get learnDrillCharacters;

  /// Receive drill: CW abbreviations and Q-codes
  ///
  /// In en, this message translates to:
  /// **'Abbreviations & Q-codes'**
  String get learnDrillAbbreviations;

  /// Receive drill: groups of digits
  ///
  /// In en, this message translates to:
  /// **'Number groups'**
  String get learnDrillNumbers;

  /// Receive drill: confusable pairs drilled against each other
  ///
  /// In en, this message translates to:
  /// **'Look-alike characters'**
  String get learnDrillConfusables;

  /// Receive drill: contest exchanges with cut numbers
  ///
  /// In en, this message translates to:
  /// **'Contest exchanges'**
  String get learnDrillContest;

  /// Drill picker subtitle for random groups
  ///
  /// In en, this message translates to:
  /// **'Random groups from every letter you know'**
  String get learnDrillGroupsHint;

  /// Drill picker subtitle for single characters
  ///
  /// In en, this message translates to:
  /// **'One character at a time - name it instantly'**
  String get learnDrillCharactersHint;

  /// Drill picker subtitle for words
  ///
  /// In en, this message translates to:
  /// **'Common English words'**
  String get learnDrillWordsHint;

  /// Drill picker subtitle for abbreviations
  ///
  /// In en, this message translates to:
  /// **'TNX, FB, QTH, QSL - the shorthand of the air'**
  String get learnDrillAbbreviationsHint;

  /// Drill picker subtitle for number groups
  ///
  /// In en, this message translates to:
  /// **'Five-digit groups, as in traffic and serials'**
  String get learnDrillNumbersHint;

  /// Drill picker subtitle for callsigns
  ///
  /// In en, this message translates to:
  /// **'Amateur callsigns from around the world'**
  String get learnDrillCallsignsHint;

  /// Drill picker subtitle for confusables
  ///
  /// In en, this message translates to:
  /// **'Pairs you mix up, like S/H or U/V, side by side'**
  String get learnDrillConfusablesHint;

  /// Drill picker subtitle for QSO
  ///
  /// In en, this message translates to:
  /// **'Lines from a full contact'**
  String get learnDrillQsoHint;

  /// Drill picker subtitle for contest exchanges
  ///
  /// In en, this message translates to:
  /// **'Call, 5NN and a serial or zone, at contest pace'**
  String get learnDrillContestHint;

  /// Drill picker subtitle for review
  ///
  /// In en, this message translates to:
  /// **'Characters that are due for review'**
  String get learnDrillReviewHint;

  /// Title of the radio tools screen and its entry button
  ///
  /// In en, this message translates to:
  /// **'Radio tools'**
  String get toolsTitle;

  /// Maidenhead locator tool title
  ///
  /// In en, this message translates to:
  /// **'Grid locator'**
  String get toolsGridTitle;

  /// Maidenhead tool subtitle
  ///
  /// In en, this message translates to:
  /// **'Locator from coordinates, distance and beam heading'**
  String get toolsGridHint;

  /// Band tool title
  ///
  /// In en, this message translates to:
  /// **'Bands & antennas'**
  String get toolsBandsTitle;

  /// Band tool subtitle
  ///
  /// In en, this message translates to:
  /// **'Which band a frequency is in, wavelength, dipole length'**
  String get toolsBandsHint;

  /// CW speed tool title
  ///
  /// In en, this message translates to:
  /// **'CW speed'**
  String get toolsSpeedTitle;

  /// CW speed tool subtitle
  ///
  /// In en, this message translates to:
  /// **'WPM to dit length, gaps and characters per minute'**
  String get toolsSpeedHint;

  /// RST tool title
  ///
  /// In en, this message translates to:
  /// **'RST report'**
  String get toolsRstTitle;

  /// RST tool subtitle
  ///
  /// In en, this message translates to:
  /// **'Build a signal report and see what each digit means'**
  String get toolsRstHint;

  /// UTC clock tool title
  ///
  /// In en, this message translates to:
  /// **'UTC clock'**
  String get toolsClockTitle;

  /// UTC clock tool subtitle
  ///
  /// In en, this message translates to:
  /// **'Log time in UTC, next to your local time'**
  String get toolsClockHint;

  /// Section header: coordinates to locator
  ///
  /// In en, this message translates to:
  /// **'From coordinates'**
  String get toolsGridFromCoordinates;

  /// Latitude field label
  ///
  /// In en, this message translates to:
  /// **'Latitude'**
  String get toolsGridLatitude;

  /// Longitude field label
  ///
  /// In en, this message translates to:
  /// **'Longitude'**
  String get toolsGridLongitude;

  /// Helper text under the coordinate fields
  ///
  /// In en, this message translates to:
  /// **'Decimal degrees; south and west are negative'**
  String get toolsGridCoordinatesHelp;

  /// Error for out-of-range coordinates
  ///
  /// In en, this message translates to:
  /// **'Latitude -90 to 90, longitude -180 to 180'**
  String get toolsGridInvalidCoordinates;

  /// Result label: the computed locator
  ///
  /// In en, this message translates to:
  /// **'Locator'**
  String get toolsGridLocator;

  /// Section header: distance between two locators
  ///
  /// In en, this message translates to:
  /// **'Distance and heading'**
  String get toolsGridDistanceSection;

  /// Field label: own locator
  ///
  /// In en, this message translates to:
  /// **'My locator'**
  String get toolsGridMine;

  /// Field label: other station's locator
  ///
  /// In en, this message translates to:
  /// **'Their locator'**
  String get toolsGridTheirs;

  /// Error for a malformed locator
  ///
  /// In en, this message translates to:
  /// **'Use 2, 4, 6 or 8 characters, e.g. OM89ex'**
  String get toolsGridInvalidLocator;

  /// Result label: centre of a locator square
  ///
  /// In en, this message translates to:
  /// **'Square centre'**
  String get toolsGridCenter;

  /// Result label: great-circle distance
  ///
  /// In en, this message translates to:
  /// **'Distance'**
  String get toolsGridDistance;

  /// Result label: short-path bearing
  ///
  /// In en, this message translates to:
  /// **'Short-path heading'**
  String get toolsGridShortPath;

  /// Result label: long-path bearing
  ///
  /// In en, this message translates to:
  /// **'Long-path heading'**
  String get toolsGridLongPath;

  /// Frequency field label
  ///
  /// In en, this message translates to:
  /// **'Frequency (MHz)'**
  String get toolsBandsFrequency;

  /// Error for a non-positive frequency
  ///
  /// In en, this message translates to:
  /// **'Enter a frequency above 0'**
  String get toolsBandsInvalidFrequency;

  /// IARU region segment label
  ///
  /// In en, this message translates to:
  /// **'Region {number}'**
  String toolsBandsRegionLabel(int number);

  /// Explains the three IARU regions
  ///
  /// In en, this message translates to:
  /// **'1: Europe, Africa, Middle East - 2: the Americas - 3: Asia-Pacific'**
  String get toolsBandsRegionHelp;

  /// Result when the frequency is inside a band
  ///
  /// In en, this message translates to:
  /// **'In the {band} amateur band'**
  String toolsBandsInBand(String band);

  /// Result when the frequency is in no band
  ///
  /// In en, this message translates to:
  /// **'Outside the amateur bands'**
  String get toolsBandsOutOfBand;

  /// Result label: free-space wavelength
  ///
  /// In en, this message translates to:
  /// **'Wavelength'**
  String get toolsBandsWavelength;

  /// Result label: dipole cut length
  ///
  /// In en, this message translates to:
  /// **'Half-wave dipole (total)'**
  String get toolsBandsDipole;

  /// Result label: quarter-wave length
  ///
  /// In en, this message translates to:
  /// **'Quarter-wave vertical'**
  String get toolsBandsQuarterWave;

  /// Note under the antenna lengths
  ///
  /// In en, this message translates to:
  /// **'Lengths include a 0.95 end factor; trim to resonance.'**
  String get toolsBandsAntennaNote;

  /// Header of the band table
  ///
  /// In en, this message translates to:
  /// **'Band edges'**
  String get toolsBandsTable;

  /// QRP calling frequency in the band table
  ///
  /// In en, this message translates to:
  /// **'QRP CW {frequency}'**
  String toolsBandsQrp(String frequency);

  /// Disclaimer under the band table
  ///
  /// In en, this message translates to:
  /// **'ITU allocations. Your licence and national band plan may be narrower.'**
  String get toolsBandsDisclaimer;

  /// Slider label: character WPM
  ///
  /// In en, this message translates to:
  /// **'Character speed'**
  String get toolsSpeedCharacter;

  /// Switch: enable Farnsworth spacing
  ///
  /// In en, this message translates to:
  /// **'Farnsworth spacing'**
  String get toolsSpeedFarnsworth;

  /// Slider label: Farnsworth overall WPM
  ///
  /// In en, this message translates to:
  /// **'Overall speed'**
  String get toolsSpeedOverall;

  /// Result label: dit length
  ///
  /// In en, this message translates to:
  /// **'Dit'**
  String get toolsSpeedDit;

  /// Result label: dah length
  ///
  /// In en, this message translates to:
  /// **'Dah'**
  String get toolsSpeedDah;

  /// Result label: character gap
  ///
  /// In en, this message translates to:
  /// **'Gap between characters'**
  String get toolsSpeedCharGap;

  /// Result label: word gap
  ///
  /// In en, this message translates to:
  /// **'Gap between words'**
  String get toolsSpeedWordGap;

  /// Result label: characters per minute
  ///
  /// In en, this message translates to:
  /// **'Characters per minute'**
  String get toolsSpeedCpm;

  /// Result label: time for one PARIS word
  ///
  /// In en, this message translates to:
  /// **'One PARIS word'**
  String get toolsSpeedParis;

  /// RST: readability scale
  ///
  /// In en, this message translates to:
  /// **'Readability (R)'**
  String get toolsRstReadability;

  /// RST: strength scale
  ///
  /// In en, this message translates to:
  /// **'Strength (S)'**
  String get toolsRstStrength;

  /// RST: tone scale
  ///
  /// In en, this message translates to:
  /// **'Tone (T)'**
  String get toolsRstTone;

  /// RST: the composed report
  ///
  /// In en, this message translates to:
  /// **'Report'**
  String get toolsRstReport;

  /// RST: cut-number form
  ///
  /// In en, this message translates to:
  /// **'Contest form'**
  String get toolsRstCut;

  /// RST: two-digit RS report
  ///
  /// In en, this message translates to:
  /// **'On voice (no tone)'**
  String get toolsRstPhone;

  /// RST readability 1
  ///
  /// In en, this message translates to:
  /// **'Unreadable'**
  String get toolsRstR1;

  /// RST readability 2
  ///
  /// In en, this message translates to:
  /// **'Barely readable, occasional words'**
  String get toolsRstR2;

  /// RST readability 3
  ///
  /// In en, this message translates to:
  /// **'Readable with considerable difficulty'**
  String get toolsRstR3;

  /// RST readability 4
  ///
  /// In en, this message translates to:
  /// **'Readable with practically no difficulty'**
  String get toolsRstR4;

  /// RST readability 5
  ///
  /// In en, this message translates to:
  /// **'Perfectly readable'**
  String get toolsRstR5;

  /// RST strength 1
  ///
  /// In en, this message translates to:
  /// **'Faint, barely perceptible'**
  String get toolsRstS1;

  /// RST strength 2
  ///
  /// In en, this message translates to:
  /// **'Very weak'**
  String get toolsRstS2;

  /// RST strength 3
  ///
  /// In en, this message translates to:
  /// **'Weak'**
  String get toolsRstS3;

  /// RST strength 4
  ///
  /// In en, this message translates to:
  /// **'Fair'**
  String get toolsRstS4;

  /// RST strength 5
  ///
  /// In en, this message translates to:
  /// **'Fairly good'**
  String get toolsRstS5;

  /// RST strength 6
  ///
  /// In en, this message translates to:
  /// **'Good'**
  String get toolsRstS6;

  /// RST strength 7
  ///
  /// In en, this message translates to:
  /// **'Moderately strong'**
  String get toolsRstS7;

  /// RST strength 8
  ///
  /// In en, this message translates to:
  /// **'Strong'**
  String get toolsRstS8;

  /// RST strength 9
  ///
  /// In en, this message translates to:
  /// **'Extremely strong'**
  String get toolsRstS9;

  /// RST tone 1
  ///
  /// In en, this message translates to:
  /// **'Very rough and broad, raw AC'**
  String get toolsRstT1;

  /// RST tone 2
  ///
  /// In en, this message translates to:
  /// **'Very rough AC, harsh and broad'**
  String get toolsRstT2;

  /// RST tone 3
  ///
  /// In en, this message translates to:
  /// **'Rough, rectified but not filtered'**
  String get toolsRstT3;

  /// RST tone 4
  ///
  /// In en, this message translates to:
  /// **'Rough, some trace of filtering'**
  String get toolsRstT4;

  /// RST tone 5
  ///
  /// In en, this message translates to:
  /// **'Filtered but strongly ripple-modulated'**
  String get toolsRstT5;

  /// RST tone 6
  ///
  /// In en, this message translates to:
  /// **'Filtered, definite trace of ripple'**
  String get toolsRstT6;

  /// RST tone 7
  ///
  /// In en, this message translates to:
  /// **'Near pure, trace of ripple'**
  String get toolsRstT7;

  /// RST tone 8
  ///
  /// In en, this message translates to:
  /// **'Near perfect, slight trace of modulation'**
  String get toolsRstT8;

  /// RST tone 9
  ///
  /// In en, this message translates to:
  /// **'Perfect tone, no ripple at all'**
  String get toolsRstT9;

  /// UTC clock label
  ///
  /// In en, this message translates to:
  /// **'UTC'**
  String get toolsClockUtc;

  /// Local clock label
  ///
  /// In en, this message translates to:
  /// **'Local time'**
  String get toolsClockLocal;

  /// Note under the UTC clock
  ///
  /// In en, this message translates to:
  /// **'Logs and QSL cards use UTC.'**
  String get toolsClockNote;

  /// Receive drill screen: app bar title
  ///
  /// In en, this message translates to:
  /// **'Receive'**
  String get learnReceiveTitle;

  /// Receive drill picker / screen: title of the spaced-repetition review drill
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get learnReviewTitle;

  /// Receive drill: status while Morse is playing
  ///
  /// In en, this message translates to:
  /// **'Listen...'**
  String get learnListen;

  /// Receive drill: status when playback finished and an answer is expected
  ///
  /// In en, this message translates to:
  /// **'Ready'**
  String get learnReady;

  /// Receive drill: button that plays the round again
  ///
  /// In en, this message translates to:
  /// **'Replay'**
  String get learnReplay;

  /// Receive drill: hint inside the answer field
  ///
  /// In en, this message translates to:
  /// **'Type what you heard'**
  String get learnAnswerHint;

  /// Receive drill: button that checks the typed answer
  ///
  /// In en, this message translates to:
  /// **'Check'**
  String get learnSubmit;

  /// Receive drill: button that moves to the next round
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get learnNext;

  /// Receive drill: button on the last round that ends the session
  ///
  /// In en, this message translates to:
  /// **'Finish'**
  String get learnFinish;

  /// Receive drill summary: button that closes the screen. Send practice: button that ends the attempt, records it and shows the result
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get learnDone;

  /// Receive drill on-screen keypad: screen-reader label of the backspace key
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get learnBackspace;

  /// Receive drill on-screen keypad: label of the space key
  ///
  /// In en, this message translates to:
  /// **'Space'**
  String get learnSpace;

  /// Receive drill round result: label of the line with what was sent
  ///
  /// In en, this message translates to:
  /// **'Sent'**
  String get learnSent;

  /// Receive drill round result: label of the line with what the user typed
  ///
  /// In en, this message translates to:
  /// **'Your copy'**
  String get learnYourCopy;

  /// Receive drill round result: shown when every character was copied correctly
  ///
  /// In en, this message translates to:
  /// **'Perfect copy!'**
  String get learnRoundPerfect;

  /// Receive drill: title of the end-of-session summary
  ///
  /// In en, this message translates to:
  /// **'Session summary'**
  String get learnSessionSummary;

  /// Receive drill summary: verdict when the lesson was passed
  ///
  /// In en, this message translates to:
  /// **'Lesson passed'**
  String get learnLessonPassed;

  /// Receive drill summary: verdict when accuracy stayed under the 90% pass mark
  ///
  /// In en, this message translates to:
  /// **'Keep at it: 90% unlocks the next one'**
  String get learnLessonNotPassed;

  /// Receive drill summary: verdict after a review session
  ///
  /// In en, this message translates to:
  /// **'Review recorded'**
  String get learnReviewRecorded;

  /// Receive drill summary: heading over characters copied poorly
  ///
  /// In en, this message translates to:
  /// **'Needs work'**
  String get learnWeakChars;

  /// Receive drill summary: heading over characters mistaken for others
  ///
  /// In en, this message translates to:
  /// **'Confused'**
  String get learnConfusions;

  /// Receive drill: warning when sound, flash and haptics are all disabled
  ///
  /// In en, this message translates to:
  /// **'Sound, flash and haptics are all off - the screen will flash instead.'**
  String get learnNoFeedbackWarning;

  /// Send practice screen: app bar title
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get learnSendTitle;

  /// Send practice: label above the text the user should key
  ///
  /// In en, this message translates to:
  /// **'Send this'**
  String get learnSendThis;

  /// Send practice: app bar switch that hides the target so the user keys it from memory
  ///
  /// In en, this message translates to:
  /// **'From memory'**
  String get learnCopyFromMemory;

  /// Send practice: placeholder replacing the hidden target text
  ///
  /// In en, this message translates to:
  /// **'Hidden - key it from memory'**
  String get learnHiddenTarget;

  /// Send practice: label above the text decoded from the user's keying
  ///
  /// In en, this message translates to:
  /// **'Decoded'**
  String get learnDecoded;

  /// Send practice: shown before the user has keyed anything
  ///
  /// In en, this message translates to:
  /// **'Start keying when ready'**
  String get learnWaitingForKey;

  /// Send practice: button that clears the attempt and starts over
  ///
  /// In en, this message translates to:
  /// **'Restart'**
  String get learnRestart;

  /// Send practice result: button that picks a new target
  ///
  /// In en, this message translates to:
  /// **'Try another'**
  String get learnTryAnother;

  /// Keyer type option: straight key (training settings, send practice)
  ///
  /// In en, this message translates to:
  /// **'Straight'**
  String get learnKeyerStraight;

  /// Keyer type option: iambic paddles, mode A (technical term, usually kept)
  ///
  /// In en, this message translates to:
  /// **'Iambic A'**
  String get learnKeyerIambicA;

  /// Keyer type option: iambic paddles, mode B (technical term, usually kept)
  ///
  /// In en, this message translates to:
  /// **'Iambic B'**
  String get learnKeyerIambicB;

  /// Send practice: keyboard legend for the straight key
  ///
  /// In en, this message translates to:
  /// **'Space = key'**
  String get learnLegendStraight;

  /// Send practice: keyboard legend for paddles (left/right Ctrl)
  ///
  /// In en, this message translates to:
  /// **'Left Ctrl = dit, Right Ctrl = dah'**
  String get learnLegendPaddles;

  /// Send practice result: shown when the keying had no timing issues ('fist' is ham slang for a sender's keying style)
  ///
  /// In en, this message translates to:
  /// **'Clean fist - nothing to fix.'**
  String get learnSendClean;

  /// Send practice result: heading over the list of timing issues
  ///
  /// In en, this message translates to:
  /// **'Rhythm notes'**
  String get learnSendIssues;

  /// Send practice result: label above what the user's keying decoded to
  ///
  /// In en, this message translates to:
  /// **'Decoded as'**
  String get learnYourSending;

  /// Send practice: label printed on the on-screen straight key (short, upper case in English)
  ///
  /// In en, this message translates to:
  /// **'KEY'**
  String get learnStraightKeyLabel;

  /// Send practice: label on the on-screen dit (short element) paddle
  ///
  /// In en, this message translates to:
  /// **'DIT'**
  String get learnDitLabel;

  /// Send practice: label on the on-screen dah (long element) paddle
  ///
  /// In en, this message translates to:
  /// **'DAH'**
  String get learnDahLabel;

  /// Training settings page: app bar title
  ///
  /// In en, this message translates to:
  /// **'Training settings'**
  String get learnSettingsTitle;

  /// Training settings: title of the character speed slider
  ///
  /// In en, this message translates to:
  /// **'Character speed'**
  String get learnCharacterSpeed;

  /// Training settings: switch for Farnsworth spacing (stretched gaps between characters)
  ///
  /// In en, this message translates to:
  /// **'Farnsworth spacing'**
  String get learnFarnsworth;

  /// Training settings: explanation under the Farnsworth switch
  ///
  /// In en, this message translates to:
  /// **'Characters stay fast; the gaps between them stretch to this speed.'**
  String get learnFarnsworthHelp;

  /// Training settings: title of the Farnsworth effective speed slider
  ///
  /// In en, this message translates to:
  /// **'Effective speed'**
  String get learnEffectiveSpeed;

  /// Training settings: title of the tone pitch slider
  ///
  /// In en, this message translates to:
  /// **'Tone'**
  String get learnTone;

  /// Training settings: tooltip of the button that plays a sample at the chosen settings
  ///
  /// In en, this message translates to:
  /// **'Play sample'**
  String get learnPlaySample;

  /// Training settings: practice length in characters, not time; labels the per-session character count slider
  ///
  /// In en, this message translates to:
  /// **'Session length'**
  String get learnSessionLength;

  /// Training settings: section header over the switches that choose how Morse is output during drills (sound, screen flash, vibration) — not right/wrong feedback
  ///
  /// In en, this message translates to:
  /// **'Feedback'**
  String get learnFeedback;

  /// Training settings, output section: switch that plays Morse as a sidetone
  ///
  /// In en, this message translates to:
  /// **'Sound'**
  String get learnSound;

  /// Training settings, output section: switch that flashes the screen in time with the Morse
  ///
  /// In en, this message translates to:
  /// **'Screen flash'**
  String get learnFlash;

  /// Training settings, output section: switch that vibrates in time with the Morse
  ///
  /// In en, this message translates to:
  /// **'Vibration'**
  String get learnHaptic;

  /// Training settings: title of the keyer type selector
  ///
  /// In en, this message translates to:
  /// **'Keyer'**
  String get learnKeyer;

  /// Training settings: title of the daily goal slider (characters per day)
  ///
  /// In en, this message translates to:
  /// **'Daily goal'**
  String get learnDailyGoal;

  /// Reference tab: app bar title
  ///
  /// In en, this message translates to:
  /// **'Morse reference'**
  String get referenceReferenceTitle;

  /// Translator screen title and tooltip of the button that opens it
  ///
  /// In en, this message translates to:
  /// **'Translator'**
  String get referenceTranslatorTitle;

  /// Reference: button / tooltip that plays an entry or translated text as Morse
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get referencePlay;

  /// Reference: button / tooltip that stops Morse playback
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get referenceStop;

  /// Reference translator: tooltip of the button that clears keyed input
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get referenceClear;

  /// Reference entry dialog: close button
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get referenceClose;

  /// Reference translator: placeholder shown when the output is empty (a dash)
  ///
  /// In en, this message translates to:
  /// **'—'**
  String get referenceEmptyOutput;

  /// Reference tab: hint inside the search field
  ///
  /// In en, this message translates to:
  /// **'Search characters, prosigns, Q-codes…'**
  String get referenceSearchHint;

  /// Reference tab: tooltip of the button that clears the search
  ///
  /// In en, this message translates to:
  /// **'Clear search'**
  String get referenceClearSearch;

  /// Reference tab: empty state when the search matches nothing
  ///
  /// In en, this message translates to:
  /// **'Nothing matches your search.'**
  String get referenceNoResults;

  /// Reference section tab: letters and digits
  ///
  /// In en, this message translates to:
  /// **'Alphabet'**
  String get referenceSectionAlphabet;

  /// Reference section tab: punctuation marks
  ///
  /// In en, this message translates to:
  /// **'Punctuation'**
  String get referenceSectionPunctuation;

  /// Reference section tab: procedural signals such as AR, SK
  ///
  /// In en, this message translates to:
  /// **'Prosigns'**
  String get referenceSectionProsigns;

  /// Reference section tab: Q-codes such as QTH, QRZ
  ///
  /// In en, this message translates to:
  /// **'Q-codes'**
  String get referenceSectionQCodes;

  /// Reference section tab: common CW (Morse) abbreviations
  ///
  /// In en, this message translates to:
  /// **'CW abbreviations'**
  String get referenceSectionAbbreviations;

  /// Reference section tab: the Koch teaching order of characters
  ///
  /// In en, this message translates to:
  /// **'Koch order'**
  String get referenceSectionKoch;

  /// Reference alphabet: hint above the grid on tapping and long-pressing
  ///
  /// In en, this message translates to:
  /// **'Tap a card to hear it. Long-press for a mnemonic.'**
  String get referenceAlphabetHint;

  /// Reference, Koch order section: explanation of the Koch character order
  ///
  /// In en, this message translates to:
  /// **'The order the Koch method introduces characters (LCWO sequence). Start with K and M; add one when you copy at 90 %.'**
  String get referenceKochHint;

  /// Reference entry dialog: heading of the memory aid for a character
  ///
  /// In en, this message translates to:
  /// **'Mnemonic'**
  String get referenceMnemonicTitle;

  /// Reference entry dialog: heading of the meaning of a prosign / Q-code / abbreviation
  ///
  /// In en, this message translates to:
  /// **'Meaning'**
  String get referenceMeaningLabel;

  /// Reference playback settings sheet title and tooltip of its button
  ///
  /// In en, this message translates to:
  /// **'Playback settings'**
  String get referencePlaybackSettings;

  /// Reference playback settings: character speed slider label
  ///
  /// In en, this message translates to:
  /// **'Character speed'**
  String get referenceCharacterSpeed;

  /// Reference playback settings: switch for Farnsworth spacing
  ///
  /// In en, this message translates to:
  /// **'Farnsworth spacing'**
  String get referenceFarnsworth;

  /// Reference playback settings: explanation under the Farnsworth switch
  ///
  /// In en, this message translates to:
  /// **'Characters stay at full speed; gaps stretch to the effective speed.'**
  String get referenceFarnsworthHelp;

  /// Reference playback settings: effective speed slider label
  ///
  /// In en, this message translates to:
  /// **'Effective speed'**
  String get referenceEffectiveSpeed;

  /// Reference playback settings: tone pitch slider label
  ///
  /// In en, this message translates to:
  /// **'Tone'**
  String get referenceTone;

  /// Translator: mode segment that converts text to Morse
  ///
  /// In en, this message translates to:
  /// **'Text → Morse'**
  String get referenceModeTextToMorse;

  /// Translator: mode segment that converts Morse to text
  ///
  /// In en, this message translates to:
  /// **'Morse → Text'**
  String get referenceModeMorseToText;

  /// Translator: mode segment where the user keys Morse by hand
  ///
  /// In en, this message translates to:
  /// **'Key'**
  String get referenceModeKey;

  /// Translator, Text to Morse: label of the text input
  ///
  /// In en, this message translates to:
  /// **'Text'**
  String get referenceTextInputLabel;

  /// Translator, Text to Morse: hint inside the text input
  ///
  /// In en, this message translates to:
  /// **'Type text to encode…'**
  String get referenceTextInputHint;

  /// Translator, Text to Morse: label above the dot-dash output
  ///
  /// In en, this message translates to:
  /// **'Morse'**
  String get referencePatternOutputLabel;

  /// Translator, Text to Morse: tooltip of the button that copies the dot-dash pattern
  ///
  /// In en, this message translates to:
  /// **'Copy pattern'**
  String get referenceCopyPattern;

  /// Translator: snackbar after the pattern was copied
  ///
  /// In en, this message translates to:
  /// **'Pattern copied'**
  String get referencePatternCopied;

  /// Translator, Morse to Text: label of the dot-dash input
  ///
  /// In en, this message translates to:
  /// **'Morse'**
  String get referencePatternInputLabel;

  /// Translator, Morse to Text: hint explaining the input syntax (. and -, space, /); keep the symbols
  ///
  /// In en, this message translates to:
  /// **'Type . and -, a space between letters, / between words'**
  String get referencePatternInputHint;

  /// Translator, Morse to Text: label above the decoded text
  ///
  /// In en, this message translates to:
  /// **'Text'**
  String get referenceTextOutputLabel;

  /// Translator, Morse to Text: tooltip of the button that copies the decoded text
  ///
  /// In en, this message translates to:
  /// **'Copy text'**
  String get referenceCopyText;

  /// Translator: snackbar after the decoded text was copied
  ///
  /// In en, this message translates to:
  /// **'Text copied'**
  String get referenceTextCopied;

  /// Translator, Morse to Text: note on how undecodable patterns are shown; keep '<pattern>' as an example
  ///
  /// In en, this message translates to:
  /// **'Patterns with no character are shown as <pattern>.'**
  String get referenceUnknownPatternHelp;

  /// Translator keypad: tooltip of the dit (short element) key
  ///
  /// In en, this message translates to:
  /// **'Dit'**
  String get referenceKeypadDit;

  /// Translator keypad: tooltip of the dah (long element) key
  ///
  /// In en, this message translates to:
  /// **'Dah'**
  String get referenceKeypadDah;

  /// Translator keypad: tooltip of the key inserting a gap between letters
  ///
  /// In en, this message translates to:
  /// **'Letter gap'**
  String get referenceKeypadCharGap;

  /// Translator keypad: tooltip of the key inserting a gap between words
  ///
  /// In en, this message translates to:
  /// **'Word gap'**
  String get referenceKeypadWordGap;

  /// Translator keypad: tooltip of the backspace key
  ///
  /// In en, this message translates to:
  /// **'Backspace'**
  String get referenceKeypadBackspace;

  /// Translator, Key mode: hint on how to key (touch or Space bar)
  ///
  /// In en, this message translates to:
  /// **'Press and hold the key to send. On a keyboard, hold Space.'**
  String get referenceKeyHint;

  /// Translator, Key mode: label on the on-screen key (short, upper case in English)
  ///
  /// In en, this message translates to:
  /// **'KEY'**
  String get referenceKeyLabel;

  /// Translator, Key mode: label above the decoded text
  ///
  /// In en, this message translates to:
  /// **'Decoded'**
  String get referenceKeyDecodedLabel;

  /// Translator, Key mode: label above the character currently being keyed
  ///
  /// In en, this message translates to:
  /// **'Keying'**
  String get referenceKeyPendingLabel;

  /// Statistics screen: app bar title
  ///
  /// In en, this message translates to:
  /// **'Statistics'**
  String get statsTitle;

  /// Statistics screen: shown while statistics load
  ///
  /// In en, this message translates to:
  /// **'Loading your statistics...'**
  String get statsLoading;

  /// Statistics screen: error when progress could not be loaded
  ///
  /// In en, this message translates to:
  /// **'Your progress could not be loaded. Pull down or reopen to retry.'**
  String get statsLoadFailed;

  /// Statistics screen: button that retries loading
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get statsRetry;

  /// Statistics: empty state title before any session
  ///
  /// In en, this message translates to:
  /// **'No sessions yet'**
  String get statsEmptyTitle;

  /// Statistics: empty state explanation of what the page will show
  ///
  /// In en, this message translates to:
  /// **'Finish your first receive or send session and this page fills up with your accuracy trend, per-character strengths and a practice calendar.'**
  String get statsEmptyBody;

  /// Statistics: empty state call to action; the quoted button name must match learnContinueLesson
  ///
  /// In en, this message translates to:
  /// **'Head to Learn and press \"Continue lesson\" to start.'**
  String get statsEmptyCallToAction;

  /// Statistics: title of the overview tiles section
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get statsOverviewTitle;

  /// Statistics overview: label of the Koch lesson tile
  ///
  /// In en, this message translates to:
  /// **'Koch lesson'**
  String get statsTileLesson;

  /// Statistics overview / summary card: label of the accuracy tile
  ///
  /// In en, this message translates to:
  /// **'Accuracy'**
  String get statsTileAccuracy;

  /// Statistics: placeholder shown for a value that has no data yet
  ///
  /// In en, this message translates to:
  /// **'--'**
  String get statsNoData;

  /// Statistics overview: label of the practice totals tile
  ///
  /// In en, this message translates to:
  /// **'Practice'**
  String get statsTilePractice;

  /// Statistics overview / summary card: label of the streak tile
  ///
  /// In en, this message translates to:
  /// **'Streak'**
  String get statsTileStreak;

  /// Statistics overview: label of the daily goal tile
  ///
  /// In en, this message translates to:
  /// **'Daily goal'**
  String get statsTileDailyGoal;

  /// Statistics, daily goal tile: detail line when today's goal is reached
  ///
  /// In en, this message translates to:
  /// **'Reached today'**
  String get statsGoalMet;

  /// Statistics summary card: title (the card is not placed on any screen at the moment)
  ///
  /// In en, this message translates to:
  /// **'Your stats'**
  String get statsSummaryTitle;

  /// Statistics summary card: link that opens the statistics screen (the card is not placed on any screen at the moment)
  ///
  /// In en, this message translates to:
  /// **'View statistics'**
  String get statsSummaryOpen;

  /// Statistics: title of the accuracy trend chart
  ///
  /// In en, this message translates to:
  /// **'Accuracy trend'**
  String get statsTrendTitle;

  /// Statistics, accuracy trend chart: hint below the chart
  ///
  /// In en, this message translates to:
  /// **'Tap a point to inspect a session.'**
  String get statsTrendHint;

  /// Statistics, accuracy trend chart: legend / tooltip for receive (copy) sessions
  ///
  /// In en, this message translates to:
  /// **'Receive'**
  String get statsSeriesReceive;

  /// Statistics, accuracy trend chart: legend / tooltip for send (keying) sessions
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get statsSeriesSend;

  /// Statistics, accuracy trend chart: x-axis label
  ///
  /// In en, this message translates to:
  /// **'Session'**
  String get statsAxisSessions;

  /// Statistics: title of the per-character grid
  ///
  /// In en, this message translates to:
  /// **'Characters'**
  String get statsCharsTitle;

  /// Statistics, character grid: subtitle
  ///
  /// In en, this message translates to:
  /// **'Koch order. Tap a character for detail.'**
  String get statsCharsSubtitle;

  /// Statistics, character grid / detail: a character never practised
  ///
  /// In en, this message translates to:
  /// **'Not practised yet'**
  String get statsCharsNotStarted;

  /// Statistics, character detail: character outside the Koch course
  ///
  /// In en, this message translates to:
  /// **'Not part of the Koch course'**
  String get statsNotInCourse;

  /// Statistics, character detail: heading of the spaced-repetition section
  ///
  /// In en, this message translates to:
  /// **'Spaced repetition'**
  String get statsSrsTitle;

  /// Statistics, character detail: character not yet scheduled for review
  ///
  /// In en, this message translates to:
  /// **'Not scheduled yet'**
  String get statsSrsNotTracked;

  /// Statistics, character detail: character due for review now
  ///
  /// In en, this message translates to:
  /// **'Due now'**
  String get statsSrsDueNow;

  /// Statistics, character detail: heading over the characters it is confused with
  ///
  /// In en, this message translates to:
  /// **'Most often confused with'**
  String get statsConfusionsTitle;

  /// Statistics, character detail: no confusions recorded
  ///
  /// In en, this message translates to:
  /// **'No confusions recorded'**
  String get statsConfusionsNone;

  /// Statistics: shown in place of the answered character when nothing was typed (lower case)
  ///
  /// In en, this message translates to:
  /// **'missed'**
  String get statsConfusionMissed;

  /// Statistics, character grid: title of the accuracy colour legend
  ///
  /// In en, this message translates to:
  /// **'Accuracy'**
  String get statsBucketLegendTitle;

  /// Statistics, character grid legend: no data bucket
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get statsBucketNone;

  /// Statistics, character grid legend: accuracy under 70%
  ///
  /// In en, this message translates to:
  /// **'< 70%'**
  String get statsBucketWeak;

  /// Statistics, character grid legend: accuracy 70 to 89%
  ///
  /// In en, this message translates to:
  /// **'70-89%'**
  String get statsBucketFair;

  /// Statistics, character grid legend: accuracy 90 to 97%
  ///
  /// In en, this message translates to:
  /// **'90-97%'**
  String get statsBucketGood;

  /// Statistics, character grid legend: accuracy 98% or more
  ///
  /// In en, this message translates to:
  /// **'>= 98%'**
  String get statsBucketStrong;

  /// Statistics: title of the confusion heatmap
  ///
  /// In en, this message translates to:
  /// **'Confusions'**
  String get statsHeatmapTitle;

  /// Statistics, confusion heatmap: how to read rows and columns
  ///
  /// In en, this message translates to:
  /// **'Rows are the sent character, columns what you answered. Darker means more often.'**
  String get statsHeatmapSubtitle;

  /// Statistics, confusion heatmap: empty state
  ///
  /// In en, this message translates to:
  /// **'No confusions yet. Wrong answers will show up here.'**
  String get statsHeatmapEmpty;

  /// Statistics, confusion heatmap: legend end for rare confusions
  ///
  /// In en, this message translates to:
  /// **'Rare'**
  String get statsHeatmapLegendLow;

  /// Statistics, confusion heatmap: legend end for frequent confusions
  ///
  /// In en, this message translates to:
  /// **'Frequent'**
  String get statsHeatmapLegendHigh;

  /// Statistics, confusion heatmap: row axis name (the character that was sent)
  ///
  /// In en, this message translates to:
  /// **'Sent'**
  String get statsHeatmapAxisTarget;

  /// Statistics, confusion heatmap: column axis name (what the user answered)
  ///
  /// In en, this message translates to:
  /// **'Answered'**
  String get statsHeatmapAxisAnswered;

  /// Statistics: title of the practice calendar
  ///
  /// In en, this message translates to:
  /// **'Practice calendar'**
  String get statsCalendarTitle;

  /// Statistics, practice calendar: the period shown
  ///
  /// In en, this message translates to:
  /// **'Last 12 weeks'**
  String get statsCalendarSubtitle;

  /// Statistics, practice calendar: legend end for little practice
  ///
  /// In en, this message translates to:
  /// **'Less'**
  String get statsCalendarLegendLess;

  /// Statistics, practice calendar: legend end for much practice
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get statsCalendarLegendMore;

  /// Statistics, practice calendar: explanation of how a streak is counted
  ///
  /// In en, this message translates to:
  /// **'A streak counts consecutive calendar days with at least one session. Skipping a whole day resets it; practising twice in a day counts once.'**
  String get statsStreakExplanation;

  /// Learn home: tooltip of the button that opens the statistics screen
  ///
  /// In en, this message translates to:
  /// **'Statistics'**
  String get learnStatistics;

  /// Listen (microphone decoder) screen title and tooltip of the Reference button that opens it
  ///
  /// In en, this message translates to:
  /// **'Listen'**
  String get listenTitle;

  /// Listen screen: button that starts decoding from the microphone
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get listenStart;

  /// Listen screen: button that stops decoding
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get listenStop;

  /// Listen screen: status while the microphone starts
  ///
  /// In en, this message translates to:
  /// **'Starting microphone...'**
  String get listenStarting;

  /// Listen screen: tooltip of the button that clears the decoded text
  ///
  /// In en, this message translates to:
  /// **'Clear text'**
  String get listenClear;

  /// Listen screen: tooltip of the button that copies the decoded text
  ///
  /// In en, this message translates to:
  /// **'Copy text'**
  String get listenCopy;

  /// Listen screen: snackbar after the decoded text was copied
  ///
  /// In en, this message translates to:
  /// **'Decoded text copied'**
  String get listenCopied;

  /// Listen settings sheet title and tooltip of its button
  ///
  /// In en, this message translates to:
  /// **'Listen settings'**
  String get listenSettings;

  /// Listen screen: label above the decoded text
  ///
  /// In en, this message translates to:
  /// **'Decoded'**
  String get listenDecoded;

  /// Listen screen: placeholder while listening but nothing decoded yet
  ///
  /// In en, this message translates to:
  /// **'Point the microphone at a Morse tone. Decoded text appears here.'**
  String get listenEmptyHint;

  /// Listen screen: placeholder before listening starts; 'Start' refers to listenStart
  ///
  /// In en, this message translates to:
  /// **'Tap Start to listen for a Morse tone.'**
  String get listenIdleHint;

  /// Listen screen: label of the character currently being received
  ///
  /// In en, this message translates to:
  /// **'Receiving'**
  String get listenPending;

  /// Listen screen: label of the estimated sending speed
  ///
  /// In en, this message translates to:
  /// **'Speed'**
  String get listenSpeed;

  /// Listen screen: shown instead of a speed before one can be estimated; same form as learnWpmUnknown
  ///
  /// In en, this message translates to:
  /// **'-- WPM'**
  String get listenSpeedUnknown;

  /// Listen screen: label of the input signal level meter
  ///
  /// In en, this message translates to:
  /// **'Signal'**
  String get listenLevel;

  /// Listen screen: label of the tone-detected indicator
  ///
  /// In en, this message translates to:
  /// **'Tone'**
  String get listenToneOn;

  /// Listen screen: title of the tone frequency control
  ///
  /// In en, this message translates to:
  /// **'Tone frequency'**
  String get listenTone;

  /// Listen screen: auto-tune has locked onto a tone
  ///
  /// In en, this message translates to:
  /// **'Locked'**
  String get listenToneLocked;

  /// Listen screen: auto-tune is still searching for a tone
  ///
  /// In en, this message translates to:
  /// **'Searching'**
  String get listenToneSearching;

  /// Listen screen: the frequency is tuned by hand
  ///
  /// In en, this message translates to:
  /// **'Manual'**
  String get listenToneManual;

  /// Listen settings: switch for automatic tone tracking
  ///
  /// In en, this message translates to:
  /// **'Auto-tune'**
  String get listenAutoTune;

  /// Listen settings: explanation under the auto-tune switch
  ///
  /// In en, this message translates to:
  /// **'Follow the strongest tone between 400 and 1000 Hz. Drag the slider to tune by hand instead.'**
  String get listenAutoTuneHelp;

  /// Listen screen: button that returns to automatic tuning (short)
  ///
  /// In en, this message translates to:
  /// **'Auto'**
  String get listenRetune;

  /// Listen settings: title of the analysis block size setting
  ///
  /// In en, this message translates to:
  /// **'Analysis block'**
  String get listenBlockSize;

  /// Listen settings: explanation of the analysis block size
  ///
  /// In en, this message translates to:
  /// **'Smaller blocks place mark edges more precisely but pick up more noise. 256 samples (5.3 ms) suits 5-40 WPM.'**
  String get listenBlockSizeHelp;

  /// Listen settings: title of the shortest element (debounce) setting
  ///
  /// In en, this message translates to:
  /// **'Shortest element'**
  String get listenMinElement;

  /// Listen settings: explanation of the shortest element setting
  ///
  /// In en, this message translates to:
  /// **'Tones and gaps shorter than this are ignored as clicks and dropouts.'**
  String get listenMinElementHelp;

  /// Listen banner when microphone permission was denied
  ///
  /// In en, this message translates to:
  /// **'Microphone access was denied. Allow it in the system settings, then try again.'**
  String get listenPermissionDenied;

  /// Listen banner: button that retries starting the microphone
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get listenPermissionRetry;

  /// Listen banner when the microphone could not be started
  ///
  /// In en, this message translates to:
  /// **'Could not start the microphone.'**
  String get listenStartFailed;

  /// Listen banner when no microphone input device exists
  ///
  /// In en, this message translates to:
  /// **'No microphone was found. Connect one and try again.'**
  String get listenNoInput;

  /// Listen banner shown when the microphone stream fails after capture has started.
  ///
  /// In en, this message translates to:
  /// **'The microphone stopped unexpectedly. Try again.'**
  String get listenStreamFailed;

  /// Listen screen: estimated sending speed in words per minute; wpm is pre-rounded
  ///
  /// In en, this message translates to:
  /// **'{wpm} WPM'**
  String listenWpmValue(int wpm);

  /// Listen screen / settings: detected or manual tone frequency in hertz; hz is pre-rounded
  ///
  /// In en, this message translates to:
  /// **'{hz} Hz'**
  String listenHzValue(int hz);

  /// Listen settings: analysis block length in samples and milliseconds; ms is pre-formatted with one decimal
  ///
  /// In en, this message translates to:
  /// **'{samples} samples ({ms} ms)'**
  String listenBlockSamples(int samples, String ms);

  /// Listen settings: shortest-element debounce in milliseconds
  ///
  /// In en, this message translates to:
  /// **'{ms} ms'**
  String listenMsValue(int ms);

  /// Listen screen: status when listening stopped because the app went to the background
  ///
  /// In en, this message translates to:
  /// **'Listening stopped while the app was in the background.'**
  String get listenStoppedInBackground;

  /// Send practice tips: shown instead of a speed when it could not be measured; same form as listenSpeedUnknown
  ///
  /// In en, this message translates to:
  /// **'-- WPM'**
  String get learnWpmUnknown;

  /// Send practice tip title: dits were keyed too long
  ///
  /// In en, this message translates to:
  /// **'Dits too long'**
  String get learnTipDitTooLongTitle;

  /// Send practice tip title: dahs were keyed too short
  ///
  /// In en, this message translates to:
  /// **'Dahs too short'**
  String get learnTipDahTooShortTitle;

  /// Send practice tip title: gaps inside a character were too long
  ///
  /// In en, this message translates to:
  /// **'Elements spread out'**
  String get learnTipIntraGapTooLongTitle;

  /// Send practice tip title: gaps between characters were too short
  ///
  /// In en, this message translates to:
  /// **'Characters crowded'**
  String get learnTipCharGapTooShortTitle;

  /// Send practice tip title: gaps between words were too short
  ///
  /// In en, this message translates to:
  /// **'Words crowded'**
  String get learnTipWordGapTooShortTitle;

  /// Send practice tip title: keying speed varied too much
  ///
  /// In en, this message translates to:
  /// **'Speed unsteady'**
  String get learnTipSpeedUnsteadyTitle;

  /// Send practice tip: severity tag for a minor issue (lower case, shown next to the tip title)
  ///
  /// In en, this message translates to:
  /// **'minor'**
  String get learnSeverityMinor;

  /// Send practice tip: severity tag for a noticeable issue
  ///
  /// In en, this message translates to:
  /// **'noticeable'**
  String get learnSeverityModerate;

  /// Send practice tip: severity tag for a major issue
  ///
  /// In en, this message translates to:
  /// **'major'**
  String get learnSeveritySevere;

  /// Linux D-Bus notification default action label (required by the backend)
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get notificationOpen;

  /// Android notification channel name (visible in system settings): inbound chat messages
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get notificationChannelMessages;

  /// Android channel description for the messages channel
  ///
  /// In en, this message translates to:
  /// **'New Morse messages from friends and groups'**
  String get notificationChannelMessagesDescription;

  /// Android notification channel name: friend requests
  ///
  /// In en, this message translates to:
  /// **'Friend requests'**
  String get notificationChannelFriendRequests;

  /// Android channel description for the friend-requests channel
  ///
  /// In en, this message translates to:
  /// **'Someone wants to add you as a friend'**
  String get notificationChannelFriendRequestsDescription;

  /// Android notification channel name: group invites
  ///
  /// In en, this message translates to:
  /// **'Group invites'**
  String get notificationChannelGroupInvites;

  /// Android channel description for the group-invites channel
  ///
  /// In en, this message translates to:
  /// **'A friend invited you to a group'**
  String get notificationChannelGroupInvitesDescription;

  /// Neutral notification body when prefs hide both text and Morse pattern
  ///
  /// In en, this message translates to:
  /// **'New message'**
  String get notificationNewMessage;

  /// Title of a friend-request notification
  ///
  /// In en, this message translates to:
  /// **'New friend request'**
  String get notificationFriendRequestTitle;

  /// Lesson card footer naming the newest learned character
  ///
  /// In en, this message translates to:
  /// **'New this lesson: {char}'**
  String learnNewestCharIs(String char);

  /// Semantics label of the newest learned-character chip
  ///
  /// In en, this message translates to:
  /// **'{char}, new'**
  String learnCharNewSemantics(String char);

  /// Send live view: the dit/dah pattern of the character being keyed (or -)
  ///
  /// In en, this message translates to:
  /// **'Keying: {pattern}'**
  String learnPendingPattern(String pattern);

  /// Send result: issue title followed by its severity label
  ///
  /// In en, this message translates to:
  /// **'{title} ({severity})'**
  String learnIssueHeadline(String title, String severity);

  /// A measured ratio of a dit, pre-formatted with one decimal (e.g. 1.5)
  ///
  /// In en, this message translates to:
  /// **'{ratio}x'**
  String learnRatioTimes(String ratio);

  /// Send tip for SendIssueKind.ditTooLong; ratio via learnRatioTimes
  ///
  /// In en, this message translates to:
  /// **'Your dits are running long (about {ratio} of a dit). Think \'di\', not \'daah\' - a dit is a tap, not a press.'**
  String learnTipDitTooLong(String ratio);

  /// Send tip for SendIssueKind.dahTooShort; ratio via learnRatioTimes
  ///
  /// In en, this message translates to:
  /// **'Your dahs are short (about {ratio} of a dit; aim for 3). Hold the dah for the length of three dits.'**
  String learnTipDahTooShort(String ratio);

  /// Send tip for SendIssueKind.intraGapTooLong; ratio via learnRatioTimes
  ///
  /// In en, this message translates to:
  /// **'Gaps inside characters are too wide (about {ratio} of a dit). Keep the elements of one character tight together.'**
  String learnTipIntraGapTooLong(String ratio);

  /// Send tip for SendIssueKind.charGapTooShort; ratio via learnRatioTimes
  ///
  /// In en, this message translates to:
  /// **'Characters are running into each other (gaps about {ratio} of a dit; aim for 3). Leave a clear pause after each character.'**
  String learnTipCharGapTooShort(String ratio);

  /// Send tip for SendIssueKind.wordGapTooShort; ratio via learnRatioTimes
  ///
  /// In en, this message translates to:
  /// **'Words are too close (gaps about {ratio} of a dit; aim for 7). Count a long pause between words.'**
  String learnTipWordGapTooShort(String ratio);

  /// Send tip for SendIssueKind.speedUnsteady; percent = coefficient of variation x 100, rounded
  ///
  /// In en, this message translates to:
  /// **'Your speed wanders (variation {percent}%). Settle on one tempo and hold it for the whole line.'**
  String learnTipSpeedUnsteady(int percent);

  /// Measurement line under the ditTooLong tip; ratio pre-formatted with two decimals via learnRatioTimes
  ///
  /// In en, this message translates to:
  /// **'{offending} of {total} dits too long (avg {ratio} dit)'**
  String learnIssueDetailDitTooLong(int offending, int total, String ratio);

  /// Measurement line under the dahTooShort tip
  ///
  /// In en, this message translates to:
  /// **'{offending} of {total} dahs too short (avg {ratio} dit)'**
  String learnIssueDetailDahTooShort(int offending, int total, String ratio);

  /// Measurement line under the intraGapTooLong tip
  ///
  /// In en, this message translates to:
  /// **'{offending} of {total} gaps inside characters too long (avg {ratio} dit)'**
  String learnIssueDetailIntraGapTooLong(int offending, int total, String ratio);

  /// Measurement line under the charGapTooShort tip
  ///
  /// In en, this message translates to:
  /// **'{offending} of {total} character gaps too short (avg {ratio} dit)'**
  String learnIssueDetailCharGapTooShort(int offending, int total, String ratio);

  /// Measurement line under the wordGapTooShort tip
  ///
  /// In en, this message translates to:
  /// **'{offending} of {total} word gaps too short (avg {ratio} dit)'**
  String learnIssueDetailWordGapTooShort(int offending, int total, String ratio);

  /// Measurement line under the speedUnsteady tip; cv pre-formatted with two decimals
  ///
  /// In en, this message translates to:
  /// **'keying speed unsteady (cv {cv})'**
  String learnIssueDetailSpeedUnsteady(String cv);

  /// Accuracy tile detail line; allTime is the all-time accuracy already formatted via statsPercent (or statsNoData)
  ///
  /// In en, this message translates to:
  /// **'last 7 days / {allTime} all time'**
  String statsAccuracyDetail(String allTime);

  /// Practice duration of one hour or more
  ///
  /// In en, this message translates to:
  /// **'{hours}h {minutes}m'**
  String statsDurationHoursMinutes(int hours, int minutes);

  /// Practice duration under one hour
  ///
  /// In en, this message translates to:
  /// **'{minutes}m'**
  String statsDurationMinutes(int minutes);

  /// Practice duration under one minute
  ///
  /// In en, this message translates to:
  /// **'{seconds}s'**
  String statsDurationSeconds(int seconds);

  /// Change password page: validation error when the new password field is empty
  ///
  /// In en, this message translates to:
  /// **'Enter a new password'**
  String get accountNewPasswordRequired;

  /// Screen-reader label of the Tox ID QR code image
  ///
  /// In en, this message translates to:
  /// **'Tox ID QR code'**
  String get accountToxIdQrSemantics;

  /// Title of the system save-file dialog when exporting a backup (desktop)
  ///
  /// In en, this message translates to:
  /// **'Save DitMesh backup'**
  String get accountBackupSaveDialogTitle;

  /// Subject line passed to the system share sheet when sharing a backup (mobile, e.g. e-mail subject)
  ///
  /// In en, this message translates to:
  /// **'DitMesh identity backup'**
  String get accountBackupShareSubject;

  /// Title of the system open-file dialog when choosing a backup to restore
  ///
  /// In en, this message translates to:
  /// **'Choose DitMesh backup'**
  String get accountBackupChooseDialogTitle;

  /// Collapsed summary under Android inbox-style grouped message notifications
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 new message} other{{count} new messages}}'**
  String notificationNewMessages(int count);

  /// Body of a friend-request notification when the request carries no message; name = display name or short Tox key
  ///
  /// In en, this message translates to:
  /// **'Friend request from {name}'**
  String notificationFriendRequestFrom(String name);

  /// Body of a friend-request notification with the requester's message; localises the separator
  ///
  /// In en, this message translates to:
  /// **'{name}: {message}'**
  String notificationFriendRequestBody(String name, String message);

  /// Title of a group-invite notification; group = group name
  ///
  /// In en, this message translates to:
  /// **'Invite to {group}'**
  String notificationGroupInviteTitle(String group);

  /// Body of a group-invite notification; name = inviting friend's display name or short Tox key
  ///
  /// In en, this message translates to:
  /// **'{name} invited you'**
  String notificationGroupInviteBody(String name);

  /// Tray menu row while the window is hidden; app = product name
  ///
  /// In en, this message translates to:
  /// **'Show {app}'**
  String desktopTrayShow(String app);

  /// Tray menu row while the window is visible; app = product name
  ///
  /// In en, this message translates to:
  /// **'Hide {app}'**
  String desktopTrayHide(String app);

  /// Tray menu checkbox row label while the sidetone is on
  ///
  /// In en, this message translates to:
  /// **'Sound on'**
  String get desktopTraySoundOn;

  /// Tray menu checkbox row label while the sidetone is off
  ///
  /// In en, this message translates to:
  /// **'Sound off'**
  String get desktopTraySoundOff;

  /// Tray menu row that exits the app for real; app = product name
  ///
  /// In en, this message translates to:
  /// **'Quit {app}'**
  String desktopTrayQuit(String app);

  /// Tray icon tooltip while there is unread traffic (plain app name otherwise)
  ///
  /// In en, this message translates to:
  /// **'{app} — {count, plural, =1{1 unread message} other{{count} unread messages}}'**
  String desktopTrayTooltipUnread(String app, int count);

  /// Desktop window title while there is unread traffic; badge = count capped at 99+
  ///
  /// In en, this message translates to:
  /// **'({badge}) {app}'**
  String desktopWindowTitleUnread(String badge, String app);

  /// Listen screen: value of the tone indicator when a tone is present (screen-reader)
  ///
  /// In en, this message translates to:
  /// **'On'**
  String get listenStateOn;

  /// Listen screen: value of the tone indicator when no tone is present (screen-reader)
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get listenStateOff;

  /// Remaining UTF-8 byte budget under the compose field; count can be negative when the draft is too long
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 byte left} other{{count} bytes left}}'**
  String chatBytesLeftCount(int count);

  /// Group tile subtitle and conversation title subtitle
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 member} other{{count} members}}'**
  String chatMemberCount(int count);

  /// Contacts page section header
  ///
  /// In en, this message translates to:
  /// **'Friends ({count})'**
  String chatFriendsCount(int count);

  /// Friend request inbox header
  ///
  /// In en, this message translates to:
  /// **'Friend requests ({count})'**
  String chatFriendRequestsCount(int count);

  /// Group invite inbox header
  ///
  /// In en, this message translates to:
  /// **'Group invites ({count})'**
  String chatGroupInvitesCount(int count);

  /// Group members sheet title
  ///
  /// In en, this message translates to:
  /// **'Members · {count}'**
  String chatMembersTitleCount(int count);

  /// Group invite subtitle; name is the shortened public key of the inviter
  ///
  /// In en, this message translates to:
  /// **'Invited by {name}'**
  String chatInvitedByName(String name);

  /// Own row in the group members sheet
  ///
  /// In en, this message translates to:
  /// **'{name} (You)'**
  String chatMemberSelf(String name);

  /// Playback settings slider caption, e.g. 'Character speed: 18 WPM'
  ///
  /// In en, this message translates to:
  /// **'{label}: {value} {unit}'**
  String chatSliderValue(String label, int value, String unit);

  /// Translator: the four-digit Chinese telegraph code groups of the typed Chinese characters (sent in Morse as digits)
  ///
  /// In en, this message translates to:
  /// **'Chinese telegraph code: {codes}'**
  String referenceTelegraphCodes(String codes);

  /// Translator: codebook choice, the mainland China (1983) telegraph codebook
  ///
  /// In en, this message translates to:
  /// **'Mainland 1983'**
  String get referenceTelegraphMainland;

  /// Translator: codebook choice, the Taiwan / Hong Kong telegraph codebook
  ///
  /// In en, this message translates to:
  /// **'Taiwan / HK'**
  String get referenceTelegraphTaiwan;

  /// Translator: shown in place of the code groups when the typed Chinese characters exist only in the other codebook
  ///
  /// In en, this message translates to:
  /// **'not in this codebook'**
  String get referenceTelegraphNone;

  /// Appearance page title and tooltip of the Learn home button that opens it
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearanceTitle;

  /// Appearance page: heading over the interface style choices
  ///
  /// In en, this message translates to:
  /// **'Interface style'**
  String get appearanceStyles;

  /// Appearance page: instruction under the style heading
  ///
  /// In en, this message translates to:
  /// **'Choose a style, preview, then apply'**
  String get appearanceChoose;

  /// Appearance page: heading over the light / dark choice
  ///
  /// In en, this message translates to:
  /// **'Brightness'**
  String get appearanceMode;

  /// Appearance page: heading over the live preview
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get appearancePreview;

  /// Appearance page: button that saves the chosen style
  ///
  /// In en, this message translates to:
  /// **'Apply style'**
  String get appearanceApply;

  /// Appearance page: button that resets style and brightness to defaults
  ///
  /// In en, this message translates to:
  /// **'Restore defaults'**
  String get appearanceRestore;

  /// Appearance page: snackbar after saving
  ///
  /// In en, this message translates to:
  /// **'Appearance saved'**
  String get appearanceApplied;

  /// Appearance page: snackbar when saving failed
  ///
  /// In en, this message translates to:
  /// **'Could not save appearance. Try again.'**
  String get appearanceSaveFailed;

  /// Appearance style name (brass-instrument themed); translate as a name
  ///
  /// In en, this message translates to:
  /// **'Classic Brass'**
  String get appearanceClassic;

  /// Appearance style name (calm modern theme); translate as a name
  ///
  /// In en, this message translates to:
  /// **'Modern Calm'**
  String get appearanceModern;

  /// Appearance style name (dark radio-room theme); translate as a name
  ///
  /// In en, this message translates to:
  /// **'Night Radio'**
  String get appearanceRadio;

  /// Appearance style name (printed handbook theme); translate as a name
  ///
  /// In en, this message translates to:
  /// **'Paper Handbook'**
  String get appearancePaper;

  /// Appearance style name (bright cartoon theme); translate as a name
  ///
  /// In en, this message translates to:
  /// **'Fresh Cartoon'**
  String get appearanceCartoon;

  /// Appearance page: light brightness option
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get appearanceLight;

  /// Appearance page: dark brightness option
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get appearanceDark;

  /// Subtitle describing the appearance options (currently unused)
  ///
  /// In en, this message translates to:
  /// **'Five styles with light and dark modes'**
  String get appearanceSubtitle;

  /// Conversation: body of the clear-history confirmation
  ///
  /// In en, this message translates to:
  /// **'Delete this conversation’s history on this device? Copies on other devices are unaffected. This cannot be undone.'**
  String get chatClearHistoryBody;

  /// Conversation timeline: button at the top that loads older messages
  ///
  /// In en, this message translates to:
  /// **'Load earlier messages'**
  String get chatLoadEarlier;

  /// Conversation timeline: text of the button at the top when loading older messages failed; tapping it retries
  ///
  /// In en, this message translates to:
  /// **'Could not load earlier messages. Tap to retry.'**
  String get chatHistoryLoadFailed;

  /// Conversation: button that retries loading the history after a failure
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get chatRetryHistory;

  /// Conversation: button shown while new messages arrived below the visible part of the timeline; tapping it jumps to the latest message
  ///
  /// In en, this message translates to:
  /// **'{count} new messages'**
  String chatNewMessages(int count);

  /// Learn home, Koch lesson card: button that expands the learned-character list to all {count} characters
  ///
  /// In en, this message translates to:
  /// **'Show all {count} characters'**
  String learnShowAllChars(int count);

  /// Badge on the note-to-self conversation (contacts, conversation list), and its title while the profile has no display name
  ///
  /// In en, this message translates to:
  /// **'Me'**
  String get chatSelfMe;

  /// Subtitle of the note-to-self conversation header: its messages are stored locally and never sent
  ///
  /// In en, this message translates to:
  /// **'Saved on this device only'**
  String get chatSelfLocalOnly;

  /// Subtitle of the note-to-self entry at the top of Contacts
  ///
  /// In en, this message translates to:
  /// **'Drafts, practice and notes · never sent'**
  String get chatSelfContactSubtitle;

  /// Learn home, Koch lesson card: button that collapses the expanded learned-character list
  ///
  /// In en, this message translates to:
  /// **'Show fewer characters'**
  String get learnShowFewerChars;

  /// Title of the dialog shown when backing out of a drill or send practice mid-session
  ///
  /// In en, this message translates to:
  /// **'Leave this session?'**
  String get learnLeaveDrillTitle;

  /// Body of the leave-drill confirmation dialog
  ///
  /// In en, this message translates to:
  /// **'The rounds you have done in this session will not be saved.'**
  String get learnLeaveDrillBody;

  /// Confirm button of the leave-drill dialog
  ///
  /// In en, this message translates to:
  /// **'Leave'**
  String get learnLeaveDrillConfirm;

  /// Shown in the QR scanner when camera permission is denied
  ///
  /// In en, this message translates to:
  /// **'DitMesh needs camera access to scan a QR code. Allow it in the system settings.'**
  String get chatScanQrPermissionDenied;

  /// Shown in the QR scanner when the camera cannot be started
  ///
  /// In en, this message translates to:
  /// **'The camera is not available on this device.'**
  String get chatScanQrCameraUnavailable;

  /// Receive drill: shown after the learner replayed a round; replays make the session assisted
  ///
  /// In en, this message translates to:
  /// **'Replayed: this session counts as practice but won\'t unlock a lesson or update reviews.'**
  String get learnReplayAssistedNote;

  /// Learn home: title of the daily plan card
  ///
  /// In en, this message translates to:
  /// **'Today\'s plan'**
  String get learnPlanTitle;

  /// Daily plan card: estimated minutes and completed steps
  ///
  /// In en, this message translates to:
  /// **'About {minutes} min · {done} of {total} steps'**
  String learnPlanSummary(int minutes, int done, int total);

  /// Daily plan card: label of the plan-length selector
  ///
  /// In en, this message translates to:
  /// **'Plan length'**
  String get learnPlanBudget;

  /// Daily plan card: one plan-length choice in minutes
  ///
  /// In en, this message translates to:
  /// **'{minutes} min'**
  String learnPlanBudgetMinutes(int minutes);

  /// Daily plan card: start the first step
  ///
  /// In en, this message translates to:
  /// **'Start plan'**
  String get learnPlanStart;

  /// Daily plan card: continue with the next step
  ///
  /// In en, this message translates to:
  /// **'Continue plan'**
  String get learnPlanContinue;

  /// Daily plan step title: spaced review
  ///
  /// In en, this message translates to:
  /// **'Review due symbols'**
  String get learnPlanStepReview;

  /// Daily plan step title: focused drill on weak symbols
  ///
  /// In en, this message translates to:
  /// **'Focused practice'**
  String get learnPlanStepFocus;

  /// Daily plan step title: Koch course copying of a lesson
  ///
  /// In en, this message translates to:
  /// **'Lesson {lesson}'**
  String learnPlanStepCourse(int lesson);

  /// Daily plan step title: short sending practice
  ///
  /// In en, this message translates to:
  /// **'Sending practice'**
  String get learnPlanStepSend;

  /// Daily plan reason: symbols due for spaced review
  ///
  /// In en, this message translates to:
  /// **'Due for review: {symbols}'**
  String learnPlanReasonDueReview(String symbols);

  /// Daily plan reason: symbols often confused with each other
  ///
  /// In en, this message translates to:
  /// **'Often mixed up: {symbols}'**
  String learnPlanReasonConfusions(String symbols);

  /// Daily plan reason: symbols copied below 90 percent
  ///
  /// In en, this message translates to:
  /// **'Below 90%: {symbols}'**
  String learnPlanReasonWeak(String symbols);

  /// Daily plan reason: course step long enough to unlock
  ///
  /// In en, this message translates to:
  /// **'{count} symbols: can unlock the next lesson'**
  String learnPlanReasonChallenge(int count);

  /// Daily plan reason: course step lengthened beyond its time share so it can unlock
  ///
  /// In en, this message translates to:
  /// **'Lengthened to {count} symbols so it can unlock the next lesson'**
  String learnPlanReasonExtended(int count);

  /// Daily plan reason: course step too short to unlock
  ///
  /// In en, this message translates to:
  /// **'Short session: consolidates this lesson, cannot unlock the next'**
  String get learnPlanReasonConsolidate;

  /// Daily plan reason: the course moved on after the plan was made
  ///
  /// In en, this message translates to:
  /// **'Your course moved on: practises lesson {lesson} without unlocking'**
  String learnPlanReasonOutdated(int lesson);

  /// Daily plan reason: number of short sending targets
  ///
  /// In en, this message translates to:
  /// **'{count} short targets to key'**
  String learnPlanReasonSend(int count);

  /// Daily plan step: completed with strict accuracy
  ///
  /// In en, this message translates to:
  /// **'Done · {percent}%'**
  String learnPlanStepDonePercent(int percent);

  /// Daily plan step: completed (no accuracy, e.g. sending)
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get learnPlanStepDone;

  /// Daily plan send step: keyed targets so far
  ///
  /// In en, this message translates to:
  /// **'{done} of {total} keyed'**
  String learnPlanSendProgress(int done, int total);

  /// Daily plan card: lesson or speed changed after planning
  ///
  /// In en, this message translates to:
  /// **'Your lesson or speed changed. Update the steps you haven\'t started?'**
  String get learnPlanStale;

  /// Daily plan card: regenerate steps that have not started
  ///
  /// In en, this message translates to:
  /// **'Update steps'**
  String get learnPlanUpdate;

  /// Daily plan card: every step done today
  ///
  /// In en, this message translates to:
  /// **'Plan complete for today'**
  String get learnPlanComplete;

  /// Daily plan card: symbols that need work after today's plan
  ///
  /// In en, this message translates to:
  /// **'Needs work: {symbols}'**
  String learnPlanNeedsWork(String symbols);

  /// Daily plan card: no weak symbols after today's plan
  ///
  /// In en, this message translates to:
  /// **'No weak symbols today.'**
  String get learnPlanAllGood;

  /// Daily plan card: after completing the plan
  ///
  /// In en, this message translates to:
  /// **'A new plan arrives tomorrow. Free practice is always open.'**
  String get learnPlanTomorrow;

  /// Daily plan card: the next step to do
  ///
  /// In en, this message translates to:
  /// **'Next: {step}'**
  String learnPlanNext(String step);

  /// Daily plan card: an earlier day's unfinished plan (inspect only)
  ///
  /// In en, this message translates to:
  /// **'Yesterday\'s plan stopped at {done} of {total} steps; it no longer counts for today.'**
  String learnPlanEarlier(int done, int total);

  /// Speed advice: raise the effective (Farnsworth) speed
  ///
  /// In en, this message translates to:
  /// **'Ready for {wpm} WPM effective speed'**
  String learnSpeedAdviceRaise(int wpm);

  /// Speed advice: raise character and effective speed together
  ///
  /// In en, this message translates to:
  /// **'Ready for {wpm} WPM'**
  String learnSpeedAdviceRaiseBoth(int wpm);

  /// Speed advice: suggest lowering the effective speed
  ///
  /// In en, this message translates to:
  /// **'Copying is hard at this speed. Try {wpm} WPM effective, or a focused drill.'**
  String learnSpeedAdviceLower(int wpm);

  /// Speed advice: evidence behind the recommendation
  ///
  /// In en, this message translates to:
  /// **'Based on your last {count} unassisted sessions ({percent}%). Nothing changes until you apply it.'**
  String learnSpeedAdviceBody(int count, int percent);

  /// Speed advice: apply the proposed speed
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get learnSpeedAdviceApply;

  /// Speed advice: dismiss for this evidence batch
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get learnSpeedAdviceDismiss;

  /// Daily plan card: why there is no speed advice yet
  ///
  /// In en, this message translates to:
  /// **'Speed advice needs 3 unassisted sessions of 50+ symbols at your current speed.'**
  String get learnSpeedAdviceInsufficient;

  /// Learn home: entry to the interactive QSO simulator
  ///
  /// In en, this message translates to:
  /// **'QSO simulator'**
  String get learnQsoAction;

  /// Learn home: QSO simulator is locked until a lesson
  ///
  /// In en, this message translates to:
  /// **'From lesson {lesson}'**
  String learnQsoLocked(int lesson);

  /// QSO simulator: screen title
  ///
  /// In en, this message translates to:
  /// **'QSO simulator'**
  String get learnQsoTitle;

  /// QSO setup: scenario where the remote calls CQ
  ///
  /// In en, this message translates to:
  /// **'Answer a CQ'**
  String get learnQsoRespond;

  /// QSO setup: description of the answer-CQ scenario
  ///
  /// In en, this message translates to:
  /// **'A station calls CQ. Answer it and exchange reports.'**
  String get learnQsoRespondHint;

  /// QSO setup: scenario where the learner calls CQ
  ///
  /// In en, this message translates to:
  /// **'Call CQ'**
  String get learnQsoCall;

  /// QSO setup: description of the call-CQ scenario
  ///
  /// In en, this message translates to:
  /// **'You call CQ and a station answers.'**
  String get learnQsoCallHint;

  /// QSO setup: learner's callsign field
  ///
  /// In en, this message translates to:
  /// **'Your callsign'**
  String get learnQsoYourCall;

  /// QSO setup: learner's name field (one word)
  ///
  /// In en, this message translates to:
  /// **'Your name'**
  String get learnQsoYourName;

  /// QSO setup: learner's location field (one word)
  ///
  /// In en, this message translates to:
  /// **'Your QTH'**
  String get learnQsoYourQth;

  /// QSO setup: callsign validation error
  ///
  /// In en, this message translates to:
  /// **'Enter a callsign such as BD1XYZ'**
  String get learnQsoInvalidCall;

  /// QSO setup: name/QTH validation error
  ///
  /// In en, this message translates to:
  /// **'One word, letters A–Z only'**
  String get learnQsoInvalidWord;

  /// QSO setup: privacy note
  ///
  /// In en, this message translates to:
  /// **'Runs entirely on this device. Nothing is sent to anyone.'**
  String get learnQsoOffline;

  /// QSO setup: start button
  ///
  /// In en, this message translates to:
  /// **'Start QSO'**
  String get learnQsoStart;

  /// QSO setup: resume an unfinished simulated QSO
  ///
  /// In en, this message translates to:
  /// **'Resume the unfinished QSO'**
  String get learnQsoResume;

  /// QSO stage: call CQ
  ///
  /// In en, this message translates to:
  /// **'Call CQ with your callsign'**
  String get learnQsoStageCallCq;

  /// QSO stage: answer with both callsigns
  ///
  /// In en, this message translates to:
  /// **'Answer: their call, DE, your call'**
  String get learnQsoStageCallConfirm;

  /// QSO stage: send report, name and QTH
  ///
  /// In en, this message translates to:
  /// **'Send report, name and QTH'**
  String get learnQsoStageExchange;

  /// QSO stage: acknowledge the remote's information
  ///
  /// In en, this message translates to:
  /// **'Confirm their information'**
  String get learnQsoStageConfirmInfo;

  /// QSO stage: close the contact
  ///
  /// In en, this message translates to:
  /// **'Close with 73 and <SK>'**
  String get learnQsoStageClosing;

  /// QSO stage/summary: contact finished
  ///
  /// In en, this message translates to:
  /// **'QSO complete'**
  String get learnQsoStageDone;

  /// QSO screen: current remote playback effective speed
  ///
  /// In en, this message translates to:
  /// **'Remote sends at {wpm} WPM effective'**
  String learnQsoSpeed(int wpm);

  /// QSO log: caption of a remote transmission
  ///
  /// In en, this message translates to:
  /// **'{call} sends'**
  String learnQsoRemote(String call);

  /// QSO log: placeholder while the remote text is hidden
  ///
  /// In en, this message translates to:
  /// **'Copy by ear — the text is hidden.'**
  String get learnQsoRemoteHidden;

  /// QSO log: reveal a remote transmission (counts as a hint)
  ///
  /// In en, this message translates to:
  /// **'Show text'**
  String get learnQsoShowText;

  /// QSO log: play a remote transmission again
  ///
  /// In en, this message translates to:
  /// **'Listen'**
  String get learnQsoListen;

  /// QSO log: semantics for an accepted transmission
  ///
  /// In en, this message translates to:
  /// **'Accepted'**
  String get learnQsoAccepted;

  /// QSO log: semantics for a rejected transmission
  ///
  /// In en, this message translates to:
  /// **'Not accepted'**
  String get learnQsoRejected;

  /// QSO screen: remote is transmitting; keying is paused
  ///
  /// In en, this message translates to:
  /// **'The other station is sending…'**
  String get learnQsoRemoteSending;

  /// QSO screen: learner's turn to key
  ///
  /// In en, this message translates to:
  /// **'Your turn: key your reply, then Send.'**
  String get learnQsoYourTurn;

  /// QSO screen: label of the decoded own transmission
  ///
  /// In en, this message translates to:
  /// **'Your transmission'**
  String get learnQsoDecoded;

  /// QSO screen: nothing keyed yet
  ///
  /// In en, this message translates to:
  /// **'Nothing keyed yet'**
  String get learnQsoNothingKeyed;

  /// QSO screen: send PSE AGN (ask the remote to repeat)
  ///
  /// In en, this message translates to:
  /// **'Ask to repeat (AGN)'**
  String get learnQsoPlayAgain;

  /// QSO screen: send QRS (ask the remote to slow down)
  ///
  /// In en, this message translates to:
  /// **'Ask to slow down (QRS)'**
  String get learnQsoSlower;

  /// QSO screen: show an example for the current stage
  ///
  /// In en, this message translates to:
  /// **'Hint'**
  String get learnQsoHint;

  /// QSO screen: hint example (protocol text, not translated)
  ///
  /// In en, this message translates to:
  /// **'Example: {example}'**
  String learnQsoHintLabel(String example);

  /// QSO screen: stop the remote's playback
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get learnQsoPause;

  /// QSO screen: submit the keyed transmission
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get learnQsoSend;

  /// QSO screen: discard the keyed transmission
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get learnQsoClear;

  /// QSO feedback
  ///
  /// In en, this message translates to:
  /// **'Nothing was keyed.'**
  String get learnQsoIssueEmpty;

  /// QSO feedback
  ///
  /// In en, this message translates to:
  /// **'Start with CQ.'**
  String get learnQsoIssueMissingCq;

  /// QSO feedback
  ///
  /// In en, this message translates to:
  /// **'Put DE between the callsigns.'**
  String get learnQsoIssueMissingDe;

  /// QSO feedback
  ///
  /// In en, this message translates to:
  /// **'Your own callsign is missing or wrong.'**
  String get learnQsoIssueWrongLocalCall;

  /// QSO feedback
  ///
  /// In en, this message translates to:
  /// **'The other station\'s callsign is wrong.'**
  String get learnQsoIssueWrongRemoteCall;

  /// QSO feedback
  ///
  /// In en, this message translates to:
  /// **'Callsigns are reversed: theirs first, then DE and yours.'**
  String get learnQsoIssueReversedCalls;

  /// QSO feedback
  ///
  /// In en, this message translates to:
  /// **'End with K or KN.'**
  String get learnQsoIssueMissingEnding;

  /// QSO feedback
  ///
  /// In en, this message translates to:
  /// **'Give a report, e.g. UR RST 599.'**
  String get learnQsoIssueMissingRst;

  /// QSO feedback
  ///
  /// In en, this message translates to:
  /// **'That RST is out of range (R 1–5, S 1–9, T 1–9).'**
  String get learnQsoIssueInvalidRst;

  /// QSO feedback
  ///
  /// In en, this message translates to:
  /// **'Send NAME and your name.'**
  String get learnQsoIssueMissingName;

  /// QSO feedback
  ///
  /// In en, this message translates to:
  /// **'That is not your name for this QSO.'**
  String get learnQsoIssueWrongName;

  /// QSO feedback
  ///
  /// In en, this message translates to:
  /// **'Send QTH and your location.'**
  String get learnQsoIssueMissingQth;

  /// QSO feedback
  ///
  /// In en, this message translates to:
  /// **'That is not your QTH for this QSO.'**
  String get learnQsoIssueWrongQth;

  /// QSO feedback
  ///
  /// In en, this message translates to:
  /// **'Acknowledge with R or QSL.'**
  String get learnQsoIssueMissingAck;

  /// QSO feedback
  ///
  /// In en, this message translates to:
  /// **'Confirm the other operator\'s name.'**
  String get learnQsoIssueWrongRemoteName;

  /// QSO feedback
  ///
  /// In en, this message translates to:
  /// **'Include 73.'**
  String get learnQsoIssueMissing73;

  /// QSO feedback
  ///
  /// In en, this message translates to:
  /// **'End the contact with <SK>.'**
  String get learnQsoIssueMissingSk;

  /// QSO summary: stages accepted on the first try
  ///
  /// In en, this message translates to:
  /// **'Right first time: {count} of {total} steps'**
  String learnQsoSummaryFields(int count, int total);

  /// QSO summary: number of repeat requests
  ///
  /// In en, this message translates to:
  /// **'Repeats: {count}'**
  String learnQsoSummaryRepeats(int count);

  /// QSO summary: hints and revealed texts
  ///
  /// In en, this message translates to:
  /// **'Hints: {count}'**
  String learnQsoSummaryHints(int count);

  /// QSO summary: average measured sending speed
  ///
  /// In en, this message translates to:
  /// **'Your sending: about {wpm} WPM'**
  String learnQsoSummaryRhythm(int wpm);

  /// QSO summary: how the result is counted
  ///
  /// In en, this message translates to:
  /// **'QSO results are kept apart from copying accuracy and never unlock lessons.'**
  String get learnQsoSummaryNote;

  /// Message status tooltip: a queued send the user cancelled before it left the device
  ///
  /// In en, this message translates to:
  /// **'Cancelled — never sent'**
  String get messageStatusCancelled;

  /// Message bubble: menu with learning actions for a received message
  ///
  /// In en, this message translates to:
  /// **'Message actions'**
  String get chatMessageLearnActions;

  /// Message menu: open copy practice
  ///
  /// In en, this message translates to:
  /// **'Practice this message'**
  String get chatPracticeMessage;

  /// Message menu / practice result: keep a local copy as training material
  ///
  /// In en, this message translates to:
  /// **'Save as training material'**
  String get chatSaveAsMaterial;

  /// Snack bar: the message was saved to My materials
  ///
  /// In en, this message translates to:
  /// **'Saved to My materials'**
  String get chatSavedAsMaterial;

  /// Snack bar: saving the material failed
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save the material. Try again.'**
  String get chatSaveMaterialFailed;

  /// Conversation menu: listen-only training toggle (hides text and dots/dashes)
  ///
  /// In en, this message translates to:
  /// **'Listen-only training'**
  String get chatListenOnly;

  /// Message bubble: placeholder while dots/dashes are hidden in listen-only mode
  ///
  /// In en, this message translates to:
  /// **'Listen-only: tap play to hear it'**
  String get chatListenOnlyHidden;

  /// Clear history dialog: saved material copies stay
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 message from this chat was saved as training material. That copy stays until you delete it in Learn › My materials.} other{{count} messages from this chat were saved as training material. Those copies stay until you delete them in Learn › My materials.}}'**
  String chatClearHistoryMaterials(int count);

  /// Chat copy practice: screen title
  ///
  /// In en, this message translates to:
  /// **'Copy practice'**
  String get chatPracticeTitle;

  /// Chat copy practice: characters Morse cannot key
  ///
  /// In en, this message translates to:
  /// **'This message contains characters Morse can\'t key: {chars}. They will be left out.'**
  String chatPracticeUnsupported(String chars);

  /// Chat copy practice: number of symbols that can be practised
  ///
  /// In en, this message translates to:
  /// **'{count} symbols can be practised.'**
  String chatPracticeTrainableCount(int count);

  /// Chat copy practice: nothing in the message can be keyed
  ///
  /// In en, this message translates to:
  /// **'Nothing in this message can be practised in Morse.'**
  String get chatPracticeNothingTrainable;

  /// Chat copy practice: confirm practising the supported part
  ///
  /// In en, this message translates to:
  /// **'Practice the rest'**
  String get chatPracticeConfirm;

  /// Chat copy practice: reveal one more symbol (assistance)
  ///
  /// In en, this message translates to:
  /// **'Hint'**
  String get chatPracticeHint;

  /// Chat copy practice: symbols revealed by hints
  ///
  /// In en, this message translates to:
  /// **'Hint: {symbols} …'**
  String chatPracticeHintShown(String symbols);

  /// Chat copy practice: assistance used, how it counts
  ///
  /// In en, this message translates to:
  /// **'Assisted: counts as practice, not for reviews or speed advice.'**
  String get chatPracticeAssisted;

  /// Chat copy practice result: error counts
  ///
  /// In en, this message translates to:
  /// **'{wrong} wrong · {missed} missed · {extra} extra'**
  String chatPracticeErrors(int wrong, int missed, int extra);

  /// Chat copy practice result: focused drill on missed learned symbols
  ///
  /// In en, this message translates to:
  /// **'Practice errors: {symbols}'**
  String chatPracticeErrorsAction(String symbols);

  /// Send practice tip title: dahs were held far too long
  ///
  /// In en, this message translates to:
  /// **'Dahs too long'**
  String get learnTipDahTooLongTitle;

  /// Send tip for SendIssueKind.dahTooLong; ratio via learnRatioTimes
  ///
  /// In en, this message translates to:
  /// **'Your dahs run long (about {ratio} of a dit; aim for 3). Release as soon as three dits have passed.'**
  String learnTipDahTooLong(String ratio);

  /// Measurement line under the dahTooLong tip
  ///
  /// In en, this message translates to:
  /// **'{offending} of {total} dahs too long (avg {ratio} dit)'**
  String learnIssueDetailDahTooLong(int offending, int total, String ratio);

  /// Send result: rhythm timeline section title
  ///
  /// In en, this message translates to:
  /// **'Rhythm'**
  String get learnRhythmTitle;

  /// Rhythm timeline lane: measured keying
  ///
  /// In en, this message translates to:
  /// **'My rhythm'**
  String get learnRhythmMine;

  /// Rhythm timeline lane: standard timing at the target speed
  ///
  /// In en, this message translates to:
  /// **'Standard rhythm (target speed)'**
  String get learnRhythmStandard;

  /// Rhythm timeline: how problems are judged
  ///
  /// In en, this message translates to:
  /// **'Problems are judged against your own dit ({ms} ms), so an even but slow fist is fine. The standard lane is the target speed.'**
  String learnRhythmNormalizedNote(int ms);

  /// Rhythm timeline: marks could not be matched symbol by symbol
  ///
  /// In en, this message translates to:
  /// **'Your marks couldn\'t be matched to single symbols, so problems aren\'t pinned to letters. Practise the whole target instead.'**
  String get learnRhythmNotLocated;

  /// Rhythm timeline: replay the measured timing
  ///
  /// In en, this message translates to:
  /// **'Play mine'**
  String get learnRhythmPlayMine;

  /// Rhythm timeline / send screen: play the standard timing
  ///
  /// In en, this message translates to:
  /// **'Play standard'**
  String get learnRhythmPlayStandard;

  /// Rhythm symbol card: start targeted practice
  ///
  /// In en, this message translates to:
  /// **'Practise this ({count} tries)'**
  String learnRhythmPracticePart(int count);

  /// Rhythm timeline: practise the whole target
  ///
  /// In en, this message translates to:
  /// **'Practise the whole target'**
  String get learnRhythmPracticeWhole;

  /// Rhythm symbol card: no problem found
  ///
  /// In en, this message translates to:
  /// **'Looks good'**
  String get learnRhythmSymbolOk;

  /// Rhythm timeline: zoom in
  ///
  /// In en, this message translates to:
  /// **'Zoom in'**
  String get learnRhythmZoomIn;

  /// Rhythm timeline: zoom out
  ///
  /// In en, this message translates to:
  /// **'Zoom out'**
  String get learnRhythmZoomOut;

  /// Conversation app bar: search this conversation's history
  ///
  /// In en, this message translates to:
  /// **'Search messages'**
  String get chatSearchMessages;

  /// Message search field hint
  ///
  /// In en, this message translates to:
  /// **'Search this conversation'**
  String get chatSearchHint;

  /// Message search sender filter: everyone
  ///
  /// In en, this message translates to:
  /// **'Anyone'**
  String get chatSearchAnyone;

  /// Message search sender filter / result sender: the local user
  ///
  /// In en, this message translates to:
  /// **'Me'**
  String get chatSearchMe;

  /// Message search sender filter: the other person in a one-to-one chat
  ///
  /// In en, this message translates to:
  /// **'Them'**
  String get chatSearchThem;

  /// Message search date filter: no date limit
  ///
  /// In en, this message translates to:
  /// **'Any date'**
  String get chatSearchAnyDate;

  /// Message search date filter: chosen range
  ///
  /// In en, this message translates to:
  /// **'{from} – {to}'**
  String chatSearchDateRange(String from, String to);

  /// Message search filter: bookmarked messages only
  ///
  /// In en, this message translates to:
  /// **'Bookmarked'**
  String get chatSearchBookmarked;

  /// Message search: nothing found
  ///
  /// In en, this message translates to:
  /// **'No matching messages.'**
  String get chatSearchNoResults;

  /// Message search: load the next page of results
  ///
  /// In en, this message translates to:
  /// **'Load more'**
  String get chatSearchMore;

  /// Message menu: bookmark this message (local only)
  ///
  /// In en, this message translates to:
  /// **'Bookmark'**
  String get chatAddBookmark;

  /// Message menu: remove the local bookmark
  ///
  /// In en, this message translates to:
  /// **'Remove bookmark'**
  String get chatRemoveBookmark;

  /// Message bubble: semantics of the bookmark mark
  ///
  /// In en, this message translates to:
  /// **'Bookmarked'**
  String get chatBookmarked;

  /// Snack bar: bookmark could not be saved
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save the bookmark.'**
  String get chatBookmarkFailed;

  /// Message menu: retry a failed send (same message, no duplicate bubble)
  ///
  /// In en, this message translates to:
  /// **'Retry sending'**
  String get chatRetrySend;

  /// Message menu: cancel a send that is still queued on this device
  ///
  /// In en, this message translates to:
  /// **'Cancel sending'**
  String get chatCancelSend;

  /// Snack bar: failed message queued again
  ///
  /// In en, this message translates to:
  /// **'Queued again. It will be sent when your contact is online.'**
  String get chatRetryQueued;

  /// Snack bar: queued message cancelled before it left the device
  ///
  /// In en, this message translates to:
  /// **'Cancelled. The message was never sent.'**
  String get chatSendCancelled;

  /// Snack bar: retry not applied because the message is no longer failed
  ///
  /// In en, this message translates to:
  /// **'This message is no longer failed; nothing to retry.'**
  String get chatRetryNotNeeded;

  /// Snack bar: cancel failed because the transport already took the message
  ///
  /// In en, this message translates to:
  /// **'Too late to cancel: the message was already handed to the network and may arrive.'**
  String get chatCancelTooLate;

  /// Snack bar: retry/cancel not available for this message
  ///
  /// In en, this message translates to:
  /// **'Not available for this message.'**
  String get chatSendControlUnavailable;

  /// Snack bar: retry/cancel could not be completed
  ///
  /// In en, this message translates to:
  /// **'That didn\'t work. The message keeps its current state; try again.'**
  String get chatSendControlFailed;

  /// Recording workbench: screen title
  ///
  /// In en, this message translates to:
  /// **'Recording workbench'**
  String get workbenchTitle;

  /// Listen screen: open the recorded-audio workbench
  ///
  /// In en, this message translates to:
  /// **'Recordings'**
  String get workbenchOpen;

  /// Recording workbench: pick a WAV file
  ///
  /// In en, this message translates to:
  /// **'Import recording'**
  String get workbenchImport;

  /// Recording workbench: empty state
  ///
  /// In en, this message translates to:
  /// **'Import a WAV recording to loop, decode and copy it. No microphone needed.'**
  String get workbenchEmpty;

  /// Recording workbench: supported formats and limits
  ///
  /// In en, this message translates to:
  /// **'WAV, 16-bit PCM, mono or stereo, 8/16/44.1/48 kHz; up to 50 MB and 20 minutes.'**
  String get workbenchFormats;

  /// Recording workbench: recordings are not part of identity backups
  ///
  /// In en, this message translates to:
  /// **'Recordings stay on this device and are left out of identity backups unless you choose to include them when exporting a backup. Saved selections always back up their titles, notes and positions.'**
  String get workbenchBackupNote;

  /// Recording workbench: recording format line
  ///
  /// In en, this message translates to:
  /// **'{rate} kHz · {channels} · {duration}'**
  String workbenchInfo(String rate, String channels, String duration);

  /// Recording workbench: one channel
  ///
  /// In en, this message translates to:
  /// **'mono'**
  String get workbenchMono;

  /// Recording workbench: two channels
  ///
  /// In en, this message translates to:
  /// **'stereo'**
  String get workbenchStereo;

  /// Recording workbench: data chunk shorter than declared
  ///
  /// In en, this message translates to:
  /// **'The file ends early; only the audio present is used.'**
  String get workbenchTruncated;

  /// Recording workbench: import error
  ///
  /// In en, this message translates to:
  /// **'This is not a WAV file.'**
  String get workbenchErrorNotWav;

  /// Recording workbench: import error
  ///
  /// In en, this message translates to:
  /// **'Only 16-bit PCM WAV is supported for now (no MP3, AAC or float WAV).'**
  String get workbenchErrorFormat;

  /// Recording workbench: import error
  ///
  /// In en, this message translates to:
  /// **'Only mono or stereo recordings are supported.'**
  String get workbenchErrorChannels;

  /// Recording workbench: import error
  ///
  /// In en, this message translates to:
  /// **'Sample rate not supported. Use 8, 16, 44.1 or 48 kHz.'**
  String get workbenchErrorRate;

  /// Recording workbench: import error
  ///
  /// In en, this message translates to:
  /// **'The file is damaged or incomplete.'**
  String get workbenchErrorDamaged;

  /// Recording workbench: import error
  ///
  /// In en, this message translates to:
  /// **'The file is larger than 50 MB.'**
  String get workbenchErrorTooLarge;

  /// Recording workbench: import error
  ///
  /// In en, this message translates to:
  /// **'The recording is longer than 20 minutes.'**
  String get workbenchErrorTooLong;

  /// Recording workbench: import error
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t read the file.'**
  String get workbenchErrorIo;

  /// Recording workbench: saved recording file not found
  ///
  /// In en, this message translates to:
  /// **'The recording file is missing.'**
  String get workbenchErrorMissing;

  /// Recording workbench: selection start field (seconds)
  ///
  /// In en, this message translates to:
  /// **'Start (s)'**
  String get workbenchStart;

  /// Recording workbench: selection end field (seconds)
  ///
  /// In en, this message translates to:
  /// **'End (s)'**
  String get workbenchEnd;

  /// Recording workbench: select the whole recording
  ///
  /// In en, this message translates to:
  /// **'Select all'**
  String get workbenchSelectAll;

  /// Recording workbench: play the selection
  ///
  /// In en, this message translates to:
  /// **'Play selection'**
  String get workbenchPlay;

  /// Recording workbench: stop playback
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get workbenchStop;

  /// Recording workbench: loop the selection
  ///
  /// In en, this message translates to:
  /// **'Loop'**
  String get workbenchLoop;

  /// Recording workbench: long selections play partly
  ///
  /// In en, this message translates to:
  /// **'Only the first 5 minutes of a longer selection are played.'**
  String get workbenchPlayLimit;

  /// Recording workbench: automatic tone search
  ///
  /// In en, this message translates to:
  /// **'Find the tone automatically'**
  String get workbenchAutoTune;

  /// Recording workbench: manual tone frequency
  ///
  /// In en, this message translates to:
  /// **'Tone: {hz} Hz'**
  String workbenchManualTone(int hz);

  /// Recording workbench: decode the selection
  ///
  /// In en, this message translates to:
  /// **'Decode selection'**
  String get workbenchDecode;

  /// Recording workbench: cancel decoding
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get workbenchCancel;

  /// Recording workbench: decoding progress
  ///
  /// In en, this message translates to:
  /// **'Decoding… {percent}%'**
  String workbenchDecoding(int percent);

  /// Recording workbench: decoder tone and speed
  ///
  /// In en, this message translates to:
  /// **'Tone {hz} Hz · about {wpm} WPM'**
  String workbenchResultStats(int hz, int wpm);

  /// Recording workbench: no steady tone
  ///
  /// In en, this message translates to:
  /// **'No steady tone found; try manual tuning.'**
  String get workbenchToneNotLocked;

  /// Recording workbench: nothing decoded
  ///
  /// In en, this message translates to:
  /// **'Nothing decoded in this selection.'**
  String get workbenchNoText;

  /// Recording workbench: patterns that match no symbol
  ///
  /// In en, this message translates to:
  /// **'Unknown patterns: {patterns}'**
  String workbenchUnknown(String patterns);

  /// Recording workbench: symbol cut by the selection boundary
  ///
  /// In en, this message translates to:
  /// **'A symbol at the edge of the selection is cut off and may be wrong.'**
  String get workbenchEdgeCut;

  /// Recording workbench: tone lock is not a confidence score
  ///
  /// In en, this message translates to:
  /// **'Tone lock is not a confidence score; check the text by ear.'**
  String get workbenchToneNote;

  /// Recording workbench: show decoder output
  ///
  /// In en, this message translates to:
  /// **'Decoder'**
  String get workbenchModeDecoder;

  /// Recording workbench: copy the selection yourself
  ///
  /// In en, this message translates to:
  /// **'Copy it myself'**
  String get workbenchModeCopy;

  /// Recording workbench: decoder output hidden in copy mode
  ///
  /// In en, this message translates to:
  /// **'Decoder text is hidden while you copy.'**
  String get workbenchDecoderHidden;

  /// Recording workbench: reveal decoder output (assisted)
  ///
  /// In en, this message translates to:
  /// **'Show decoder text'**
  String get workbenchShowDecoder;

  /// Recording workbench: optional answer text field
  ///
  /// In en, this message translates to:
  /// **'Reference text (optional)'**
  String get workbenchReference;

  /// Recording workbench: reference text help
  ///
  /// In en, this message translates to:
  /// **'Paste the text that was sent; otherwise your copy is compared with the decoder output.'**
  String get workbenchReferenceHelp;

  /// Recording workbench: scored against decoder output
  ///
  /// In en, this message translates to:
  /// **'Compared with the decoder output, which can itself be wrong.'**
  String get workbenchAgainstDecoder;

  /// Recording workbench: save the selection as an audio material
  ///
  /// In en, this message translates to:
  /// **'Save selection'**
  String get workbenchSave;

  /// Recording workbench: title field
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get workbenchSaveTitle;

  /// Recording workbench: note field
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get workbenchSaveNote;

  /// Recording workbench: selection saved
  ///
  /// In en, this message translates to:
  /// **'Selection saved'**
  String get workbenchSaved;

  /// Recording workbench: saving failed
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save the selection.'**
  String get workbenchSaveFailed;

  /// Recording workbench: saved selections list
  ///
  /// In en, this message translates to:
  /// **'Saved selections'**
  String get workbenchLibrary;

  /// Recording workbench: no saved selections
  ///
  /// In en, this message translates to:
  /// **'No saved selections yet.'**
  String get workbenchLibraryEmpty;

  /// Recording workbench: saved selection whose media file is gone
  ///
  /// In en, this message translates to:
  /// **'Recording file missing — choose it again or delete the entry.'**
  String get workbenchMissing;

  /// Recording workbench: choose the missing file again
  ///
  /// In en, this message translates to:
  /// **'Choose the file again'**
  String get workbenchRelink;

  /// Recording workbench: delete a saved selection
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get workbenchDelete;

  /// My materials: screen title / Learn entry
  ///
  /// In en, this message translates to:
  /// **'My materials'**
  String get materialsTitle;

  /// My materials: create a material
  ///
  /// In en, this message translates to:
  /// **'New material'**
  String get materialsNew;

  /// My materials: edit a material
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get materialsEdit;

  /// Material editor: save
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get materialsSave;

  /// Material editor: saving failed
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save the material.'**
  String get materialsSaveFailed;

  /// Material editor: title field
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get materialsTitleField;

  /// Material editor: tags field (comma separated)
  ///
  /// In en, this message translates to:
  /// **'Tags (comma separated)'**
  String get materialsTagsField;

  /// Material editor: running text field
  ///
  /// In en, this message translates to:
  /// **'Text'**
  String get materialsTextField;

  /// Material editor: one entry per line field
  ///
  /// In en, this message translates to:
  /// **'One entry per line'**
  String get materialsListField;

  /// Material kind: running text
  ///
  /// In en, this message translates to:
  /// **'Text'**
  String get materialsKindText;

  /// Material kind: word list
  ///
  /// In en, this message translates to:
  /// **'Word list'**
  String get materialsKindWords;

  /// Material kind: callsign list
  ///
  /// In en, this message translates to:
  /// **'Callsigns'**
  String get materialsKindCallsigns;

  /// Material editor: preview heading
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get materialsPreview;

  /// Material preview: item/symbol/prosign counts
  ///
  /// In en, this message translates to:
  /// **'{items} items · {symbols} symbols · {prosigns} prosigns'**
  String materialsPreviewCounts(int items, int symbols, int prosigns);

  /// Material preview: characters without Morse code (left out of practice)
  ///
  /// In en, this message translates to:
  /// **'No Morse code, left out of practice: {chars}'**
  String materialsPreviewUnsupported(String chars);

  /// Material preview: duplicate list entries kept once
  ///
  /// In en, this message translates to:
  /// **'{count} duplicate entries are kept once'**
  String materialsPreviewDuplicates(int count);

  /// Material problem
  ///
  /// In en, this message translates to:
  /// **'Enter some text first.'**
  String get materialsProblemEmpty;

  /// Material problem: over 1 MiB
  ///
  /// In en, this message translates to:
  /// **'Too large: materials are limited to 1 MiB.'**
  String get materialsProblemTooLarge;

  /// Material problem: too many entries
  ///
  /// In en, this message translates to:
  /// **'Too many entries: at most {count}.'**
  String materialsProblemTooManyEntries(int count);

  /// Material problem: an entry is too long
  ///
  /// In en, this message translates to:
  /// **'An entry is too long: at most {count} symbols each.'**
  String materialsProblemEntryTooLong(int count);

  /// Material problem: nothing can be keyed
  ///
  /// In en, this message translates to:
  /// **'Nothing here can be practised in Morse.'**
  String get materialsProblemNothingTrainable;

  /// My materials: search field
  ///
  /// In en, this message translates to:
  /// **'Search materials'**
  String get materialsSearch;

  /// My materials: favourites filter
  ///
  /// In en, this message translates to:
  /// **'Favourites'**
  String get materialsFavoritesOnly;

  /// My materials: mark favourite
  ///
  /// In en, this message translates to:
  /// **'Add to favourites'**
  String get materialsFavorite;

  /// My materials: unmark favourite
  ///
  /// In en, this message translates to:
  /// **'Remove from favourites'**
  String get materialsUnfavorite;

  /// My materials: empty library
  ///
  /// In en, this message translates to:
  /// **'No materials yet. Add your own texts, word lists or callsigns, or save a chat message.'**
  String get materialsEmpty;

  /// My materials: number of items
  ///
  /// In en, this message translates to:
  /// **'{count} items'**
  String materialsItems(int count);

  /// My materials: saved from a chat message
  ///
  /// In en, this message translates to:
  /// **'From chat'**
  String get materialsFromChat;

  /// My materials: per-material menu
  ///
  /// In en, this message translates to:
  /// **'Material actions'**
  String get materialsActions;

  /// My materials: start practice
  ///
  /// In en, this message translates to:
  /// **'Practise'**
  String get materialsPractise;

  /// My materials: delete
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get materialsDelete;

  /// My materials: delete confirmation title
  ///
  /// In en, this message translates to:
  /// **'Delete material?'**
  String get materialsDeleteTitle;

  /// My materials: delete confirmation body
  ///
  /// In en, this message translates to:
  /// **'“{title}” will be removed from this device. Your practice history stays.'**
  String materialsDeleteBody(String title);

  /// My materials: import a TXT or JSON file
  ///
  /// In en, this message translates to:
  /// **'Import TXT or JSON'**
  String get materialsImport;

  /// Native file picker title for material import
  ///
  /// In en, this message translates to:
  /// **'Choose a material file'**
  String get materialsImportDialogTitle;

  /// Native save dialog title for material export
  ///
  /// In en, this message translates to:
  /// **'Save material'**
  String get materialsSaveDialogTitle;

  /// My materials: import failed, library unchanged
  ///
  /// In en, this message translates to:
  /// **'Import failed. Your library is unchanged.'**
  String get materialsImportFailed;

  /// My materials: file is not UTF-8 text
  ///
  /// In en, this message translates to:
  /// **'Only UTF-8 text files can be imported.'**
  String get materialsImportNotUtf8;

  /// My materials: JSON library invalid, nothing imported
  ///
  /// In en, this message translates to:
  /// **'Not a valid DitMesh material file. Nothing was imported.'**
  String get materialsImportInvalid;

  /// My materials: import done
  ///
  /// In en, this message translates to:
  /// **'Imported {count} materials.'**
  String materialsImported(int count);

  /// Import: some ids already exist
  ///
  /// In en, this message translates to:
  /// **'Some materials already exist'**
  String get materialsDuplicateTitle;

  /// Import duplicate policy
  ///
  /// In en, this message translates to:
  /// **'Replace them'**
  String get materialsDuplicateOverwrite;

  /// Import duplicate policy
  ///
  /// In en, this message translates to:
  /// **'Keep both (import as copies)'**
  String get materialsDuplicateKeepCopy;

  /// Import duplicate policy
  ///
  /// In en, this message translates to:
  /// **'Skip them'**
  String get materialsDuplicateSkip;

  /// My materials: export the (filtered) library as JSON
  ///
  /// In en, this message translates to:
  /// **'Export as JSON'**
  String get materialsExportJson;

  /// My materials: export done
  ///
  /// In en, this message translates to:
  /// **'Exported {count} materials.'**
  String materialsExported(int count);

  /// My materials: export failed
  ///
  /// In en, this message translates to:
  /// **'Export failed.'**
  String get materialsExportFailed;

  /// My materials: export audio
  ///
  /// In en, this message translates to:
  /// **'Export audio (WAV)'**
  String get materialsExportWav;

  /// WAV export: character speed
  ///
  /// In en, this message translates to:
  /// **'Character speed: {wpm} WPM'**
  String materialsWavCharSpeed(int wpm);

  /// WAV export: effective speed
  ///
  /// In en, this message translates to:
  /// **'Effective speed: {wpm} WPM'**
  String materialsWavEffSpeed(int wpm);

  /// WAV export: tone
  ///
  /// In en, this message translates to:
  /// **'Tone: {hz} Hz'**
  String materialsWavTone(int hz);

  /// WAV export: also save the answer text
  ///
  /// In en, this message translates to:
  /// **'Include the answer text (.txt)'**
  String get materialsWavWithAnswer;

  /// WAV export: file format note
  ///
  /// In en, this message translates to:
  /// **'16-bit mono WAV, 48 kHz.'**
  String get materialsWavFormat;

  /// WAV export: split into parts of at most 10 minutes
  ///
  /// In en, this message translates to:
  /// **'Longer than 10 minutes: exported as {count} files.'**
  String materialsWavParts(int count);

  /// WAV export: done
  ///
  /// In en, this message translates to:
  /// **'Saved {count} audio files.'**
  String materialsWavExported(int count);

  /// Material practice: choose symbol set
  ///
  /// In en, this message translates to:
  /// **'Practise with'**
  String get materialsPracticeMode;

  /// Material practice: learned symbols only
  ///
  /// In en, this message translates to:
  /// **'Learned symbols only'**
  String get materialsPracticeLearned;

  /// Material practice: learned-only leaves some entries out
  ///
  /// In en, this message translates to:
  /// **'Learned symbols only ({count} entries unavailable: they use symbols not learned yet)'**
  String materialsPracticeLearnedPartial(int count);

  /// Material practice: every supported symbol
  ///
  /// In en, this message translates to:
  /// **'All Morse symbols'**
  String get materialsPracticeAll;

  /// Material practice: no usable entries in this mode
  ///
  /// In en, this message translates to:
  /// **'No entries can be practised in this mode.'**
  String get materialsPracticeNothing;

  /// Welcome/unlock: learn without an identity
  ///
  /// In en, this message translates to:
  /// **'Try learning first'**
  String get guestTryLearning;

  /// Guest mode banner over the shell
  ///
  /// In en, this message translates to:
  /// **'Guest learning: progress stays on this device. Chat needs an identity.'**
  String get guestBanner;

  /// Guest mode: go to create / restore / unlock an identity
  ///
  /// In en, this message translates to:
  /// **'Set up identity'**
  String get guestGetIdentity;

  /// Guest mode: title of a chat destination that needs an identity
  ///
  /// In en, this message translates to:
  /// **'Identity needed'**
  String get guestIdentityTitle;

  /// Guest mode: why chat needs an identity
  ///
  /// In en, this message translates to:
  /// **'Chatting over Tox needs your own identity. Create a new one, restore a backup, or unlock the one on this device. Your guest learning progress moves to a new identity automatically.'**
  String get guestIdentityBody;

  /// Guest Me page: delete guest learning data
  ///
  /// In en, this message translates to:
  /// **'Clear guest learning data'**
  String get guestClearData;

  /// Guest Me page: what clearing does
  ///
  /// In en, this message translates to:
  /// **'Deletes the progress, plans and materials you made as a guest on this device. Identities are not affected.'**
  String get guestClearDataBody;

  /// Guest clear dialog: confirm
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get guestClearConfirm;

  /// Snack: guest data cleared
  ///
  /// In en, this message translates to:
  /// **'Guest learning data cleared.'**
  String get guestCleared;

  /// Snack: clearing guest data failed
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t clear the guest data.'**
  String get guestClearFailed;

  /// Banner: guest progress did not move to the new identity yet
  ///
  /// In en, this message translates to:
  /// **'Your identity is ready, but your guest learning progress hasn\'t moved to it yet. It is safe on this device.'**
  String get guestMigrationFailed;

  /// Banner after restore/unlock from guest mode: choose progress
  ///
  /// In en, this message translates to:
  /// **'You also have guest learning progress. The restored identity\'s progress is in use; nothing was merged.'**
  String get guestChoiceBody;

  /// Banner action: keep restored progress
  ///
  /// In en, this message translates to:
  /// **'Keep restored'**
  String get guestChoiceKeep;

  /// Banner action: replace with guest progress (restored data is kept aside)
  ///
  /// In en, this message translates to:
  /// **'Use guest progress'**
  String get guestChoiceUseGuest;

  /// Placement assessment: screen title
  ///
  /// In en, this message translates to:
  /// **'Check my level'**
  String get placementTitle;

  /// Placement offer: start the assessment
  ///
  /// In en, this message translates to:
  /// **'Check my current level'**
  String get placementCheckLevel;

  /// Placement: start the course at lesson one
  ///
  /// In en, this message translates to:
  /// **'Start from zero'**
  String get placementFromZero;

  /// Learn home: offer for brand-new learners
  ///
  /// In en, this message translates to:
  /// **'New to Morse, or already copying?'**
  String get placementOfferTitle;

  /// Learn home: placement offer explanation
  ///
  /// In en, this message translates to:
  /// **'A short check can suggest where to start. It is optional and changes nothing until you choose.'**
  String get placementOfferBody;

  /// Placement intro
  ///
  /// In en, this message translates to:
  /// **'About 3–5 minutes of copying in five steps: Koch symbols in groups at rising speed, then short words. It is a rough guide from a small sample, not a certificate. Stop whenever you like.'**
  String get placementIntro;

  /// Placement: start
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get placementStart;

  /// Placement: skip
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get placementSkip;

  /// Placement: stop early and see the suggestion
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get placementStop;

  /// Placement: current step and effective speed
  ///
  /// In en, this message translates to:
  /// **'Step {step} of {total} · {wpm} WPM effective'**
  String placementTierProgress(int step, int total, int wpm);

  /// Placement: step passed
  ///
  /// In en, this message translates to:
  /// **'Well copied. Next step is faster.'**
  String get placementTierPassed;

  /// Placement: step below 90 percent, check ends
  ///
  /// In en, this message translates to:
  /// **'That step was below 90%, so the check ends here.'**
  String get placementTierStopped;

  /// Placement: continue to the next step
  ///
  /// In en, this message translates to:
  /// **'Next step'**
  String get placementNextTier;

  /// Placement result headline
  ///
  /// In en, this message translates to:
  /// **'Suggested start: lesson {lesson}'**
  String placementSuggestion(int lesson);

  /// Placement result: verified Koch prefix
  ///
  /// In en, this message translates to:
  /// **'{count} of {total} Koch symbols confirmed in order.'**
  String placementVerified(int count, int total);

  /// Placement result: limitations
  ///
  /// In en, this message translates to:
  /// **'Based on a short sample: symbols you were not tested on stay untested, and nothing is marked as learned. You can change the lesson any time.'**
  String get placementLimits;

  /// Placement result: apply the suggested lesson
  ///
  /// In en, this message translates to:
  /// **'Start at lesson {lesson}'**
  String placementAdopt(int lesson);

  /// Conversation: button back to the newest messages after jumping to an older search result
  ///
  /// In en, this message translates to:
  /// **'Latest messages'**
  String get chatJumpToLatest;

  /// Snack: a search result or bookmark points at a message that no longer exists
  ///
  /// In en, this message translates to:
  /// **'That message is no longer in this conversation.'**
  String get chatMessageGone;

  /// Conversation list preview of a received message while listen-only training hides it
  ///
  /// In en, this message translates to:
  /// **'New message — listen to copy it'**
  String get chatListenOnlyPreview;

  /// Save-as-material confirmation: save the supported part
  ///
  /// In en, this message translates to:
  /// **'Save the rest'**
  String get chatSaveMaterialConfirm;

  /// JSON import preview dialog title
  ///
  /// In en, this message translates to:
  /// **'Import {count} materials?'**
  String materialsImportConfirm(int count);

  /// My materials: export the original text as a .txt file
  ///
  /// In en, this message translates to:
  /// **'Export as text (TXT)'**
  String get materialsExportTxt;

  /// Backup export: ask whether to include saved recordings
  ///
  /// In en, this message translates to:
  /// **'Include saved recordings?'**
  String get accountBackupMediaTitle;

  /// Backup export: recordings count and size
  ///
  /// In en, this message translates to:
  /// **'{count} saved recordings ({size} MB). Their titles, notes and positions are always in the backup; the audio only if you include it.'**
  String accountBackupMediaBody(int count, String size);

  /// Backup export: recordings too large to include
  ///
  /// In en, this message translates to:
  /// **'Saved recordings ({size} MB) are too large to put in a backup; only their titles, notes and positions are included.'**
  String accountBackupMediaTooLarge(String size);

  /// Backup export: include recordings
  ///
  /// In en, this message translates to:
  /// **'Include recordings'**
  String get accountBackupMediaInclude;

  /// Backup export: continue without recordings (default)
  ///
  /// In en, this message translates to:
  /// **'Without recordings'**
  String get accountBackupMediaSkip;

  /// Connection diagnostics page title; also the menu / Me entry that opens it
  ///
  /// In en, this message translates to:
  /// **'Connection diagnostics'**
  String get diagTitle;

  /// Me page: subtitle of the Connection diagnostics entry
  ///
  /// In en, this message translates to:
  /// **'Why messages are waiting and how to reconnect'**
  String get diagOpenSubtitle;

  /// Offline banner: button that opens Connection diagnostics
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get diagBannerDetails;

  /// Diagnostics summary when no identity is open
  ///
  /// In en, this message translates to:
  /// **'No identity is open, so there is no connection to inspect.'**
  String get diagSummaryNoIdentity;

  /// Diagnostics summary: we are online and the selected contact is online
  ///
  /// In en, this message translates to:
  /// **'You are connected to the Tox network and this contact is online. Messages go straight to them.'**
  String get diagSummaryOnlinePeerOnline;

  /// Diagnostics summary: we are online but the selected contact is offline
  ///
  /// In en, this message translates to:
  /// **'You are connected, but this contact is offline. Messages wait in the outbox on this device and are sent when the contact comes online.'**
  String get diagSummaryOnlinePeerOffline;

  /// Diagnostics summary: we are online (no contact selected, or its state is unknown)
  ///
  /// In en, this message translates to:
  /// **'You are connected to the Tox network.'**
  String get diagSummaryOnline;

  /// Diagnostics summary while connecting
  ///
  /// In en, this message translates to:
  /// **'Connecting to the Tox network. This can take a minute after the app starts or the network changes.'**
  String get diagSummaryConnecting;

  /// Diagnostics summary while offline
  ///
  /// In en, this message translates to:
  /// **'You are not connected to the Tox network. Nothing can be sent or received until the connection is back.'**
  String get diagSummaryOffline;

  /// Diagnostics: label of the local connection state row
  ///
  /// In en, this message translates to:
  /// **'Your connection'**
  String get diagLocalLabel;

  /// Diagnostics: when the current state was observed to start
  ///
  /// In en, this message translates to:
  /// **'Since {time}'**
  String diagSinceChanged(String time);

  /// Diagnostics: the state was first observed at this time (no change seen yet)
  ///
  /// In en, this message translates to:
  /// **'Observed since {time}'**
  String diagSinceFirst(String time);

  /// Diagnostics: observation restarted when the app returned from the background
  ///
  /// In en, this message translates to:
  /// **'Observed since returning to the app at {time}'**
  String diagSinceResumed(String time);

  /// Diagnostics: label of the last observed local connection row
  ///
  /// In en, this message translates to:
  /// **'Last connection observed'**
  String get diagLastOnlineLabel;

  /// Diagnostics: we are connected right now
  ///
  /// In en, this message translates to:
  /// **'Connected now'**
  String get diagLastOnlineNow;

  /// Diagnostics: no local connection has been observed for this identity yet
  ///
  /// In en, this message translates to:
  /// **'No connection observed yet.'**
  String get diagLastOnlineNone;

  /// Diagnostics: explains that the last-connection time is local, not a delivery time
  ///
  /// In en, this message translates to:
  /// **'When this device last saw its own connection. It is not when a message reached anyone.'**
  String get diagLastOnlineHint;

  /// Diagnostics: label of the selected contact's state row
  ///
  /// In en, this message translates to:
  /// **'Contact'**
  String get diagPeerLabel;

  /// Diagnostics: a fact that cannot be observed right now
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get diagUnknown;

  /// Diagnostics: why the contact state is unknown
  ///
  /// In en, this message translates to:
  /// **'A contact\'s presence can only be seen while you are connected.'**
  String get diagPeerUnknownHint;

  /// Diagnostics: group conversations have no single contact state
  ///
  /// In en, this message translates to:
  /// **'Group members\' presence is shown in the member list.'**
  String get diagPeerGroupHint;

  /// Diagnostics: label of the durable outbox row
  ///
  /// In en, this message translates to:
  /// **'Waiting to send'**
  String get diagPendingLabel;

  /// Diagnostics: the outbox is empty
  ///
  /// In en, this message translates to:
  /// **'Nothing waiting'**
  String get diagPendingNone;

  /// Diagnostics: number of queued messages
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 message} other{{count} messages}}'**
  String diagPendingCount(int count);

  /// Diagnostics: enqueue time of the oldest queued message
  ///
  /// In en, this message translates to:
  /// **'Oldest queued {time}'**
  String diagPendingOldest(String time);

  /// Diagnostics: the outbox cannot be read right now (chat not connected)
  ///
  /// In en, this message translates to:
  /// **'Unknown until chat is connected'**
  String get diagPendingUnknown;

  /// Diagnostics: queued messages are kept and never resent or discarded by diagnostics
  ///
  /// In en, this message translates to:
  /// **'Queued messages stay on this device and are sent automatically when the contact is reachable. Diagnostics never discards or resends them.'**
  String get diagPendingHint;

  /// Diagnostics: reconnect button
  ///
  /// In en, this message translates to:
  /// **'Reconnect'**
  String get diagReconnect;

  /// Diagnostics: reconnect in progress
  ///
  /// In en, this message translates to:
  /// **'Reconnecting…'**
  String get diagReconnecting;

  /// Diagnostics: the reconnect attempt failed; reason is a localized error
  ///
  /// In en, this message translates to:
  /// **'Reconnect failed: {reason}'**
  String diagReconnectFailed(String reason);

  /// Diagnostics: a finished reconnect does not mean online
  ///
  /// In en, this message translates to:
  /// **'Reconnecting restarts the connection attempt. Coming online can still take a while; this page updates when it does.'**
  String get diagReconnectNote;

  /// Diagnostics: heading of the P2P explanation
  ///
  /// In en, this message translates to:
  /// **'How DitMesh connects'**
  String get diagAboutTitle;

  /// Diagnostics: P2P and mobile background explanation
  ///
  /// In en, this message translates to:
  /// **'DitMesh has no server. Your device talks to your contacts directly over the Tox peer-to-peer network, so both of you must be online at the same time for a message to arrive. Phones pause apps in the background: DitMesh cannot stay connected there and reconnects when you return.'**
  String get diagAboutBody;

  /// Diagnostics: expandable technical details
  ///
  /// In en, this message translates to:
  /// **'Technical details'**
  String get diagDetailsTitle;

  /// Diagnostics details: identity key prefix
  ///
  /// In en, this message translates to:
  /// **'Identity'**
  String get diagDetailIdentity;

  /// Diagnostics details: raw connection status
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get diagDetailStatus;

  /// Diagnostics details: when this snapshot was taken
  ///
  /// In en, this message translates to:
  /// **'Observed at'**
  String get diagDetailObserved;

  /// Diagnostics details: raw queue count
  ///
  /// In en, this message translates to:
  /// **'Queue entries'**
  String get diagDetailQueued;

  /// Diagnostics details: last reconnect error code
  ///
  /// In en, this message translates to:
  /// **'Last error code'**
  String get diagDetailError;

  /// Encrypted complete backup page title
  ///
  /// In en, this message translates to:
  /// **'Encrypted backup'**
  String get backupXTitle;

  /// Encrypted backup page: intro
  ///
  /// In en, this message translates to:
  /// **'Choose what to take to another device. The whole file is encrypted with a passphrase you set here.'**
  String get backupXIntro;

  /// Backup category: identity and Tox profile
  ///
  /// In en, this message translates to:
  /// **'Identity and Tox profile'**
  String get backupXCategoryIdentity;

  /// Backup category: training progress and materials
  ///
  /// In en, this message translates to:
  /// **'Training progress and materials'**
  String get backupXCategoryTraining;

  /// Backup category: chat history including note to self
  ///
  /// In en, this message translates to:
  /// **'Chat history, including notes to self'**
  String get backupXCategoryChat;

  /// Backup category: drafts, pins, bookmarks
  ///
  /// In en, this message translates to:
  /// **'Drafts, pins and bookmarks'**
  String get backupXCategoryMeta;

  /// Backup category: portable app preferences
  ///
  /// In en, this message translates to:
  /// **'App preferences'**
  String get backupXCategoryPrefs;

  /// Backup: what app preferences include/exclude
  ///
  /// In en, this message translates to:
  /// **'Playback, notifications, appearance and language. Never window positions or key bindings.'**
  String get backupXPrefsHint;

  /// Backup category: saved recordings
  ///
  /// In en, this message translates to:
  /// **'Saved recordings'**
  String get backupXCategoryMedia;

  /// Backup: recordings are large and off by default
  ///
  /// In en, this message translates to:
  /// **'Off by default: recordings can be large. Without them, only their titles and notes come along.'**
  String get backupXMediaHint;

  /// Backup category: unsent messages
  ///
  /// In en, this message translates to:
  /// **'Unsent messages'**
  String get backupXCategoryPending;

  /// Backup: unsent messages are restored only for review
  ///
  /// In en, this message translates to:
  /// **'They come back for review only and are never sent automatically.'**
  String get backupXPendingHint;

  /// Backup: this category is required
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get backupXRequired;

  /// Backup: item count and size of a category
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 item} other{{count} items}} · {size}'**
  String backupXSizeLine(int count, String size);

  /// File size in kilobytes
  ///
  /// In en, this message translates to:
  /// **'{size} KB'**
  String backupXSizeKb(String size);

  /// File size in megabytes
  ///
  /// In en, this message translates to:
  /// **'{size} MB'**
  String backupXSizeMb(String size);

  /// Backup: recordings exceed the size limit
  ///
  /// In en, this message translates to:
  /// **'Too large to include ({size})'**
  String backupXMediaTooLarge(String size);

  /// Backup: queued group invites are not carried
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 group invitation waiting for an offline friend is not carried over.} other{{count} group invitations waiting for offline friends are not carried over.}}'**
  String backupXInvitesNote(int count);

  /// Backup: the profile keeps its identity password
  ///
  /// In en, this message translates to:
  /// **'Your identity password stays on the profile: the new device asks for it as well as for the backup passphrase.'**
  String get backupXIdentityPasswordNote;

  /// Backup: estimated total size
  ///
  /// In en, this message translates to:
  /// **'About {size} in total'**
  String backupXTotal(String size);

  /// Backup passphrase field (export and restore)
  ///
  /// In en, this message translates to:
  /// **'Backup passphrase'**
  String get backupXPassphrase;

  /// Backup: repeat passphrase field
  ///
  /// In en, this message translates to:
  /// **'Repeat passphrase'**
  String get backupXPassphraseConfirm;

  /// Backup: passphrase guidance
  ///
  /// In en, this message translates to:
  /// **'At least 8 characters. It is separate from your identity password and cannot be recovered.'**
  String get backupXPassphraseHint;

  /// Backup: passphrase too short
  ///
  /// In en, this message translates to:
  /// **'Use at least 8 characters'**
  String get backupXPassphraseTooShort;

  /// Backup: passphrases differ
  ///
  /// In en, this message translates to:
  /// **'The passphrases do not match'**
  String get backupXPassphraseMismatch;

  /// Backup: create button
  ///
  /// In en, this message translates to:
  /// **'Create encrypted backup'**
  String get backupXExport;

  /// Backup: creating in progress
  ///
  /// In en, this message translates to:
  /// **'Creating backup…'**
  String get backupXExporting;

  /// Backup: stop using the identity on the old device after moving
  ///
  /// In en, this message translates to:
  /// **'Moving to a new device? After restoring there, stop using this identity here: two devices with one identity can send the same message twice.'**
  String get backupXMigrationNote;

  /// Backup error: data kept changing
  ///
  /// In en, this message translates to:
  /// **'Your data kept changing while the backup was taken. Try again.'**
  String get backupXBusy;

  /// Backup error: too large
  ///
  /// In en, this message translates to:
  /// **'The backup is too large. Leave out recordings and try again.'**
  String get backupXTooLarge;

  /// Restore: wrong passphrase or altered file
  ///
  /// In en, this message translates to:
  /// **'Wrong passphrase, or the file was changed or is incomplete.'**
  String get restoreXWrongPassphrase;

  /// Restore: backup from a newer version
  ///
  /// In en, this message translates to:
  /// **'This backup was made by a newer version of DitMesh.'**
  String get restoreXUnsupported;

  /// Restore: open the encrypted backup with the passphrase
  ///
  /// In en, this message translates to:
  /// **'Open backup'**
  String get restoreXCheck;

  /// Restore preview title
  ///
  /// In en, this message translates to:
  /// **'Backup contents'**
  String get restoreXPreviewTitle;

  /// Restore preview: creation time
  ///
  /// In en, this message translates to:
  /// **'Created {date}'**
  String restoreXCreated(String date);

  /// Restore preview: included categories heading
  ///
  /// In en, this message translates to:
  /// **'Included'**
  String get restoreXIncluded;

  /// Restore preview: categories not in the backup
  ///
  /// In en, this message translates to:
  /// **'Not in this backup'**
  String get restoreXExcluded;

  /// Restore preview: unsent messages included for review
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 unsent message comes back for review. It will not be sent automatically.} other{{count} unsent messages come back for review. They will not be sent automatically.}}'**
  String restoreXPendingIncluded(int count);

  /// Restore preview: unsent messages not included
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 unsent message on the old device is not in this backup.} other{{count} unsent messages on the old device are not in this backup.}}'**
  String restoreXPendingExcluded(int count);

  /// Restore: identity password field for an encrypted profile
  ///
  /// In en, this message translates to:
  /// **'Identity password'**
  String get restoreXIdentityPassword;

  /// Restore: the profile needs its own password
  ///
  /// In en, this message translates to:
  /// **'The identity in this backup has its own password. Enter it as well.'**
  String get restoreXIdentityPasswordNote;

  /// Restore: confirm replacement dialog title
  ///
  /// In en, this message translates to:
  /// **'Replace the identity on this device?'**
  String get restoreXConfirmTitle;

  /// Restore: confirm replacement dialog body
  ///
  /// In en, this message translates to:
  /// **'Any identity and data on this device are replaced by the backup. Stop using the identity on the old device before connecting here.'**
  String get restoreXConfirmBody;

  /// Restore: confirm button
  ///
  /// In en, this message translates to:
  /// **'Replace and restore'**
  String get restoreXConfirm;

  /// Restore report title
  ///
  /// In en, this message translates to:
  /// **'Restore complete'**
  String get restoreXReportTitle;

  /// Restore report: restored heading
  ///
  /// In en, this message translates to:
  /// **'Restored'**
  String get restoreXReportRestored;

  /// Restore report: not restored heading
  ///
  /// In en, this message translates to:
  /// **'Not restored'**
  String get restoreXReportNotIncluded;

  /// Restore report: preferences failed to apply
  ///
  /// In en, this message translates to:
  /// **'Preferences could not be applied; your previous preferences were kept.'**
  String get restoreXReportPrefsFailed;

  /// Restore report: unsent messages await review
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 unsent message is waiting for your review in Chat.} other{{count} unsent messages are waiting for your review in Chat.}}'**
  String restoreXReportPendingReview(int count);

  /// Restore report: unsent messages not brought over
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 unsent message from the old device was not brought over.} other{{count} unsent messages from the old device were not brought over.}}'**
  String restoreXReportPendingNotResumed(int count);

  /// Restore: queued group invitations not resent
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 queued group invitation was not resent.} other{{count} queued group invitations were not resent.}}'**
  String restoreXReportInvites(int count);

  /// Restore report: stop using the old device
  ///
  /// In en, this message translates to:
  /// **'Stop using this identity on the old device.'**
  String get restoreXReportStopOld;

  /// Restore report: close button
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get restoreXReportDone;

  /// Chat list strip: restored unsent messages to review
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 unsent message from your previous device} other{{count} unsent messages from your previous device}}'**
  String pendingReviewBanner(int count);

  /// Restored unsent messages review page title
  ///
  /// In en, this message translates to:
  /// **'Unsent messages'**
  String get pendingReviewTitle;

  /// Restored unsent messages: explanation
  ///
  /// In en, this message translates to:
  /// **'These were waiting to be sent on your previous device. DitMesh never sends them automatically; key one again if it still matters.'**
  String get pendingReviewBody;

  /// Restored unsent message: when it was queued
  ///
  /// In en, this message translates to:
  /// **'Queued {time} on the previous device'**
  String pendingReviewQueuedAt(String time);

  /// Restored unsent message: dismiss one
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get pendingReviewDismiss;

  /// Restored unsent messages: dismiss all
  ///
  /// In en, this message translates to:
  /// **'Dismiss all'**
  String get pendingReviewDismissAll;

  /// Restored unsent messages: nothing left
  ///
  /// In en, this message translates to:
  /// **'Nothing left to review.'**
  String get pendingReviewEmpty;

  /// First-run backup wizard: what the encrypted backup contains
  ///
  /// In en, this message translates to:
  /// **'The backup file is encrypted as a whole with a passphrase you choose, and holds your identity key and training progress. Keep the file and the passphrase somewhere safe, outside this device.'**
  String get backupXWizardInside;

  /// Me page: subtitle of the export backup entry (encrypted complete backup)
  ///
  /// In en, this message translates to:
  /// **'An encrypted file with your identity, chats and progress, to keep or to move to another device'**
  String get backupXMeSubtitle;

  /// Drill picker: heading of the channel conditions selector
  ///
  /// In en, this message translates to:
  /// **'Conditions'**
  String get conditionsTitle;

  /// Conditions preset: clean tone (default)
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get conditionsClear;

  /// Conditions preset: light interference
  ///
  /// In en, this message translates to:
  /// **'Light interference'**
  String get conditionsLight;

  /// Conditions preset: realistic radio practice
  ///
  /// In en, this message translates to:
  /// **'Radio practice'**
  String get conditionsRadio;

  /// Conditions preset hint: clear
  ///
  /// In en, this message translates to:
  /// **'A clean, steady tone: ordinary practice.'**
  String get conditionsClearHint;

  /// Conditions preset hint: light
  ///
  /// In en, this message translates to:
  /// **'Soft background noise and gentle fading. Results are kept apart from clean practice.'**
  String get conditionsLightHint;

  /// Conditions preset hint: radio practice
  ///
  /// In en, this message translates to:
  /// **'Noise, deep fading, a nearby station and slightly uneven timing. Results are kept apart from clean practice.'**
  String get conditionsRadioHint;

  /// Drill picker: play a short sample under the chosen conditions
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get conditionsPreview;

  /// Receive drill: chip naming the active conditions
  ///
  /// In en, this message translates to:
  /// **'Conditions: {name}'**
  String conditionsActive(String name);

  /// Receive drill: conditions need sound
  ///
  /// In en, this message translates to:
  /// **'Radio conditions are heard, not seen: turn sound on in the training settings, or practise with Clear conditions.'**
  String get conditionsNeedSound;

  /// Round result: replay the round without effects
  ///
  /// In en, this message translates to:
  /// **'Play without effects'**
  String get conditionsCleanReplay;

  /// Receive summary: results under the same conditions and speed
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 attempt under these conditions at this speed: {accuracy}%} other{{count} attempts under these conditions at this speed: {accuracy}% on average}}'**
  String conditionsComparable(int count, int accuracy);

  /// Receive summary: conditions results do not change progress
  ///
  /// In en, this message translates to:
  /// **'Practice under radio conditions counts as activity but does not change your lessons, review schedule or speed advice.'**
  String get conditionsSeparateNote;

  /// Key setup page title; also the Me entry
  ///
  /// In en, this message translates to:
  /// **'Keys and external keyers'**
  String get keysTitle;

  /// Me page: subtitle of the key setup entry
  ///
  /// In en, this message translates to:
  /// **'Key bindings, paddles and USB keyer adapters'**
  String get keysMeSubtitle;

  /// Key setup: introduction
  ///
  /// In en, this message translates to:
  /// **'Choose which keys key Morse. Keyboard-emulating USB key and paddle adapters work like a keyboard: set their keys here. The app cannot tell which device sent a key, so a profile is a set of bindings.'**
  String get keysIntro;

  /// Key setup: built-in default profile
  ///
  /// In en, this message translates to:
  /// **'Standard'**
  String get keysStandardProfile;

  /// Key setup: profile without a name
  ///
  /// In en, this message translates to:
  /// **'Unnamed profile'**
  String get keysUnnamed;

  /// Key setup: edit a profile
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get keysEdit;

  /// Key setup: create a profile
  ///
  /// In en, this message translates to:
  /// **'New profile'**
  String get keysNewProfile;

  /// Key setup: what is not supported
  ///
  /// In en, this message translates to:
  /// **'MIDI, serial and Bluetooth keyers, adapter firmware settings and transmitter control are not supported. Tested adapters are listed in the documentation.'**
  String get keysLimitations;

  /// Key profile editor title
  ///
  /// In en, this message translates to:
  /// **'Key profile'**
  String get keysEditTitle;

  /// Key profile editor: name field
  ///
  /// In en, this message translates to:
  /// **'Profile name'**
  String get keysName;

  /// Key action/keyer mode: straight key
  ///
  /// In en, this message translates to:
  /// **'Straight key'**
  String get keysActionStraight;

  /// Key action: dit paddle
  ///
  /// In en, this message translates to:
  /// **'Dit paddle'**
  String get keysActionDit;

  /// Key action: dah paddle
  ///
  /// In en, this message translates to:
  /// **'Dah paddle'**
  String get keysActionDah;

  /// Key capture: waiting for a key
  ///
  /// In en, this message translates to:
  /// **'Press a key…'**
  String get keysPressKey;

  /// Key capture: no key bound
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get keysNone;

  /// Key capture: start capturing
  ///
  /// In en, this message translates to:
  /// **'Set'**
  String get keysSet;

  /// Key capture: reserved key refused
  ///
  /// In en, this message translates to:
  /// **'{key} is reserved by the system or the app; choose another key.'**
  String keysReserved(String key);

  /// Key capture: key already used for another action
  ///
  /// In en, this message translates to:
  /// **'{key} is already used for {action}.'**
  String keysConflict(String key, String action);

  /// Key profile save refused: duplicate binding
  ///
  /// In en, this message translates to:
  /// **'Each key can do only one thing: {keys} is bound twice.'**
  String keysConflictSave(String keys);

  /// Key profile save refused: keys missing for the mode
  ///
  /// In en, this message translates to:
  /// **'Set the keys this keyer mode needs (both paddles for iambic).'**
  String get keysMissing;

  /// Key profile: swap dit and dah paddles
  ///
  /// In en, this message translates to:
  /// **'Swap paddles (left-handed)'**
  String get keysSwapPaddles;

  /// Key profile: keyer mode heading
  ///
  /// In en, this message translates to:
  /// **'Keyer mode'**
  String get keysKeyerMode;

  /// Keyer mode: iambic A
  ///
  /// In en, this message translates to:
  /// **'Iambic A'**
  String get keysIambicA;

  /// Keyer mode: iambic B
  ///
  /// In en, this message translates to:
  /// **'Iambic B'**
  String get keysIambicB;

  /// Key profile: adapter has its own keyer
  ///
  /// In en, this message translates to:
  /// **'The adapter keys its own elements'**
  String get keysAdapterKeyer;

  /// Key profile: adapter keyer explanation
  ///
  /// In en, this message translates to:
  /// **'For an adapter with its own keyer: its timed key-down and key-up are used as they are, without a second iambic keyer in the app.'**
  String get keysAdapterKeyerHint;

  /// Key profile: app sidetone while keying
  ///
  /// In en, this message translates to:
  /// **'App sidetone while keying'**
  String get keysAppSidetone;

  /// Key profile: sidetone explanation
  ///
  /// In en, this message translates to:
  /// **'Turn off when the adapter makes its own sidetone. Decoding is not affected.'**
  String get keysAppSidetoneHint;

  /// Key profile: test area title
  ///
  /// In en, this message translates to:
  /// **'Test'**
  String get keysTestTitle;

  /// Key profile: test area is not sent or credited
  ///
  /// In en, this message translates to:
  /// **'Testing only: nothing is sent or added to your training.'**
  String get keysTestNote;

  /// Key profile: release all keys (stop a stuck tone)
  ///
  /// In en, this message translates to:
  /// **'Release keys'**
  String get keysTestRelease;

  /// Key profile test: adapter keyer active
  ///
  /// In en, this message translates to:
  /// **'The adapter\'s own keyer is used: paddle keys act as a straight key.'**
  String get keysAdapterActive;

  /// Keying hint with the active profile's keys
  ///
  /// In en, this message translates to:
  /// **'Keys: {keys}'**
  String keysHintCustom(String keys);

  /// Chinese telegraph-code practice title / Learn entry
  ///
  /// In en, this message translates to:
  /// **'Chinese telegraph code'**
  String get telegraphTitle;

  /// Telegraph practice: introduction
  ///
  /// In en, this message translates to:
  /// **'Each Chinese character is sent as a four-digit code. Practise hearing the digits and, separately, remembering which code stands for which character.'**
  String get telegraphIntro;

  /// Codebook selector label
  ///
  /// In en, this message translates to:
  /// **'Codebook'**
  String get telegraphCodebook;

  /// Codebook: mainland China (1983)
  ///
  /// In en, this message translates to:
  /// **'Mainland'**
  String get telegraphCodebookMainland;

  /// Codebook: Taiwan / Hong Kong
  ///
  /// In en, this message translates to:
  /// **'Taiwan'**
  String get telegraphCodebookTaiwan;

  /// Telegraph practice: digit copying task
  ///
  /// In en, this message translates to:
  /// **'Copy code groups'**
  String get telegraphDigitsTitle;

  /// Telegraph practice: digit copying explanation
  ///
  /// In en, this message translates to:
  /// **'Hear four-digit groups of real codes and type the digits.'**
  String get telegraphDigitsHint;

  /// Telegraph practice: digit copying results
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 session: {accuracy}% of digits} other{{count} sessions: {accuracy}% of digits}}'**
  String telegraphDigitsResults(int count, int accuracy);

  /// Telegraph practice: codebook recall task
  ///
  /// In en, this message translates to:
  /// **'Recall codes'**
  String get telegraphRecallTitle;

  /// Telegraph practice: recall explanation
  ///
  /// In en, this message translates to:
  /// **'Character to code and code to character. Kept apart from Morse progress.'**
  String get telegraphRecallHint;

  /// Telegraph practice: recall results
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 card answered: {accuracy}% known} other{{count} cards answered: {accuracy}% known}}'**
  String telegraphRecallResults(int count, int accuracy);

  /// Telegraph practice: recall does not affect Morse progress
  ///
  /// In en, this message translates to:
  /// **'Codebook recall never unlocks Morse lessons or changes speed advice; digit copying counts like other Morse copying.'**
  String get telegraphSeparateNote;

  /// Recall card: type the code of this character
  ///
  /// In en, this message translates to:
  /// **'Type the code of this character'**
  String get telegraphRecallCharPrompt;

  /// Recall card: pick the character of this code
  ///
  /// In en, this message translates to:
  /// **'Pick the character for this code'**
  String get telegraphRecallCodePrompt;

  /// Recall card: reveal the answer (assisted)
  ///
  /// In en, this message translates to:
  /// **'Show answer'**
  String get telegraphReveal;

  /// Recall card: revealed answers count as assisted
  ///
  /// In en, this message translates to:
  /// **'Shown: this card counts as assisted.'**
  String get telegraphRevealAssisted;

  /// Recall card: correct
  ///
  /// In en, this message translates to:
  /// **'Correct'**
  String get telegraphCorrect;

  /// Recall card: incorrect
  ///
  /// In en, this message translates to:
  /// **'Not quite'**
  String get telegraphIncorrect;

  /// Recall summary: correct of total
  ///
  /// In en, this message translates to:
  /// **'{correct} of {total} known'**
  String telegraphRecallSummary(int correct, int total);

  /// Recall summary: cards with a revealed answer
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 card with the answer shown} other{{count} cards with the answer shown}}'**
  String telegraphRecallAssisted(int count);

  /// Chat message menu: interpret digits as telegraph code
  ///
  /// In en, this message translates to:
  /// **'Interpret as Chinese telegraph code'**
  String get telegraphInterpretAction;

  /// Telegraph interpretation sheet title
  ///
  /// In en, this message translates to:
  /// **'Telegraph code interpretation'**
  String get telegraphInterpretTitle;

  /// Telegraph interpretation: local and read-only
  ///
  /// In en, this message translates to:
  /// **'Shown here only: the message itself is not changed and nothing is sent.'**
  String get telegraphInterpretNote;

  /// Telegraph interpretation: unassigned code
  ///
  /// In en, this message translates to:
  /// **'Unresolved: no character has this code'**
  String get telegraphUnresolved;

  /// Telegraph interpretation: digits but not four
  ///
  /// In en, this message translates to:
  /// **'Not a four-digit group'**
  String get telegraphMalformed;

  /// Telegraph interpretation: ordinary text token
  ///
  /// In en, this message translates to:
  /// **'Text, kept as written'**
  String get telegraphNotCode;

  /// Telegraph interpretation: several characters share the code
  ///
  /// In en, this message translates to:
  /// **'Several characters share this code'**
  String get telegraphAmbiguous;

  /// Group practice page title / group menu entry
  ///
  /// In en, this message translates to:
  /// **'Group practice'**
  String get groupPracticeTitle;

  /// Group practice: how the manual workflow works
  ///
  /// In en, this message translates to:
  /// **'The instructor keys exercises in the group chat as usual. Each member picks an exercise message here and copies it at their own speed. Answers and scores stay on your device; nothing is sent to the group.'**
  String get groupPracticeIntro;

  /// Group practice: start a new local session
  ///
  /// In en, this message translates to:
  /// **'New session'**
  String get groupPracticeNew;

  /// Group practice: session title field
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get groupPracticeTitleField;

  /// Group practice: create the session
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get groupPracticeCreate;

  /// Group practice role: instructor (local label)
  ///
  /// In en, this message translates to:
  /// **'Instructor'**
  String get groupPracticeInstructor;

  /// Group practice role: participant
  ///
  /// In en, this message translates to:
  /// **'Participant'**
  String get groupPracticeParticipant;

  /// Group practice: instructor's role explanation
  ///
  /// In en, this message translates to:
  /// **'Key each exercise in the group chat, add it here as a round and tick it off; announce turns in the chat.'**
  String get groupPracticeInstructorHint;

  /// Group practice: participant's role explanation
  ///
  /// In en, this message translates to:
  /// **'Add the instructor\'s exercise messages as rounds and copy each one here.'**
  String get groupPracticeParticipantHint;

  /// Group practice: everything is local, nothing synchronised
  ///
  /// In en, this message translates to:
  /// **'Local only: rounds, roles and results are not synchronised with other members, and missed messages may never reach everyone.'**
  String get groupPracticeLocalNote;

  /// Group practice: add an exercise message as a round
  ///
  /// In en, this message translates to:
  /// **'Add exercise'**
  String get groupPracticeAddRound;

  /// Group practice: no suitable messages to add
  ///
  /// In en, this message translates to:
  /// **'No suitable messages in the recent history.'**
  String get groupPracticeNoMessages;

  /// Group practice: history unavailable (chat not connected)
  ///
  /// In en, this message translates to:
  /// **'Group history is not available until chat is connected.'**
  String get groupPracticeNotConnected;

  /// Group practice round state: open
  ///
  /// In en, this message translates to:
  /// **'To do'**
  String get groupPracticeRoundOpen;

  /// Group practice round state: done
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get groupPracticeRoundDone;

  /// Group practice round state: source message gone
  ///
  /// In en, this message translates to:
  /// **'Unavailable'**
  String get groupPracticeRoundUnavailable;

  /// Group practice: source message deleted or cleared
  ///
  /// In en, this message translates to:
  /// **'The exercise message is no longer in the history.'**
  String get groupPracticeSourceGone;

  /// Group practice: source message not loaded yet
  ///
  /// In en, this message translates to:
  /// **'Looking for the message…'**
  String get groupPracticeSourceLoading;

  /// Group practice round: latest result and number of attempts
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Copied: {accuracy}%} other{Copied: {accuracy}% ({count} attempts)}}'**
  String groupPracticeAttemptResult(int accuracy, int count);

  /// Group practice round: copy this exercise
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get groupPracticeCopy;

  /// Group practice round: remove
  ///
  /// In en, this message translates to:
  /// **'Remove round'**
  String get groupPracticeRemoveRound;

  /// Group practice: summary heading
  ///
  /// In en, this message translates to:
  /// **'Summary'**
  String get groupPracticeSummary;

  /// Group practice: rounds done of total
  ///
  /// In en, this message translates to:
  /// **'{done} of {total} rounds done'**
  String groupPracticeRoundsDone(int done, int total);

  /// Group practice: rounds whose source is gone
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 round unavailable} other{{count} rounds unavailable}}'**
  String groupPracticeUnavailableCount(int count);

  /// Group practice: copy accuracy over latest attempts
  ///
  /// In en, this message translates to:
  /// **'Copy accuracy: {accuracy}%'**
  String groupPracticeAccuracy(int accuracy);

  /// Group practice: attempts with help
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 attempt with help} other{{count} attempts with help}}'**
  String groupPracticeAssisted(int count);

  /// Group practice: a result the learner may key into the chat themselves
  ///
  /// In en, this message translates to:
  /// **'To share, key your result in the group chat yourself, e.g. {done}/{total} {accuracy}%. Nothing is sent automatically.'**
  String groupPracticeShareHint(int done, int total, int accuracy);

  /// Group practice: mark the session complete
  ///
  /// In en, this message translates to:
  /// **'Finish session'**
  String get groupPracticeComplete;

  /// Group practice: confirm deleting a session
  ///
  /// In en, this message translates to:
  /// **'Delete this session?'**
  String get groupPracticeDeleteTitle;

  /// Group practice: what deleting a session removes
  ///
  /// In en, this message translates to:
  /// **'Its rounds and local results are removed from this device. Your training history and the group\'s messages stay.'**
  String get groupPracticeDeleteBody;

  /// Receive drill: the conditions audio could not be started
  ///
  /// In en, this message translates to:
  /// **'The audio could not be started on this device. Practise with Clear conditions instead.'**
  String get conditionsAudioFailed;

  /// Block action (menus, friend request and invite buttons)
  ///
  /// In en, this message translates to:
  /// **'Block'**
  String get moderationBlock;

  /// Block confirmation title; name is the person (name or short key)
  ///
  /// In en, this message translates to:
  /// **'Block {name}?'**
  String moderationBlockTitle(String name);

  /// Block confirmation body for a friend or a friend request
  ///
  /// In en, this message translates to:
  /// **'They are removed from your friends and your conversation with them is deleted. Their messages, friend requests and group invites no longer appear on this device. They are not notified.'**
  String get moderationBlockFriendBody;

  /// Block confirmation body for a group member (NGC keys are per group)
  ///
  /// In en, this message translates to:
  /// **'Their messages in this group no longer appear on this device. They are not notified. Tox gives every group member a separate key in each group, so this applies to this group only.'**
  String get moderationBlockMemberBody;

  /// Snack bar after blocking
  ///
  /// In en, this message translates to:
  /// **'Blocked'**
  String get moderationBlocked;

  /// Unblock action on the blocked people page
  ///
  /// In en, this message translates to:
  /// **'Unblock'**
  String get moderationUnblock;

  /// Snack bar after unblocking
  ///
  /// In en, this message translates to:
  /// **'Unblocked'**
  String get moderationUnblocked;

  /// Blocked people page title and Me tile
  ///
  /// In en, this message translates to:
  /// **'Blocked people'**
  String get moderationBlockedTitle;

  /// Me tile subtitle for blocked people
  ///
  /// In en, this message translates to:
  /// **'Their messages, requests and invites are hidden'**
  String get moderationBlockedSubtitle;

  /// Blocked people page with nobody blocked
  ///
  /// In en, this message translates to:
  /// **'You have not blocked anyone.'**
  String get moderationBlockedEmpty;

  /// Blocked people page: how blocking works
  ///
  /// In en, this message translates to:
  /// **'Blocking works on this device: Tox has no central server, so blocked people can still try to reach you, but nothing of theirs is shown here.'**
  String get moderationBlockedNote;

  /// Terms gate (before chat) title
  ///
  /// In en, this message translates to:
  /// **'Community guidelines'**
  String get termsGateTitle;

  /// Terms gate intro
  ///
  /// In en, this message translates to:
  /// **'DitMesh chat connects you directly with other people, without a server. Before you start, please agree to these rules:'**
  String get termsGateIntro;

  /// Terms gate rule: zero tolerance
  ///
  /// In en, this message translates to:
  /// **'Zero tolerance: no harassment, hate, threats, sexual content involving minors, spam or anything illegal.'**
  String get termsGateRuleZero;

  /// Terms gate rule: only accepted contacts
  ///
  /// In en, this message translates to:
  /// **'Only people you accept can message you; groups are joined by invitation or group ID.'**
  String get termsGateRuleContacts;

  /// Terms gate rule: blocking
  ///
  /// In en, this message translates to:
  /// **'Block anyone from a conversation, a group’s member list, a friend request or a group invite.'**
  String get termsGateRuleBlock;

  /// Terms gate accept button
  ///
  /// In en, this message translates to:
  /// **'Agree and continue'**
  String get termsGateAgree;

  /// Terms gate link to the full terms
  ///
  /// In en, this message translates to:
  /// **'Read the full terms of use'**
  String get termsGateReadFull;

  /// Terms gate: saving acceptance failed
  ///
  /// In en, this message translates to:
  /// **'Your answer could not be saved. Try again.'**
  String get termsGateSaveFailed;

  /// About: privacy policy link
  ///
  /// In en, this message translates to:
  /// **'Privacy policy'**
  String get aboutPrivacyPolicy;

  /// About: terms of use link
  ///
  /// In en, this message translates to:
  /// **'Terms of use'**
  String get aboutTermsOfUse;

  /// About: support and contact link
  ///
  /// In en, this message translates to:
  /// **'Support and contact'**
  String get aboutSupport;

  /// About: a link could not be opened and was copied
  ///
  /// In en, this message translates to:
  /// **'The link could not be opened, so it was copied.'**
  String get aboutLinkFailed;

  /// ChatException code peer_blocked
  ///
  /// In en, this message translates to:
  /// **'You blocked this person. Unblock them under Me → Blocked people first.'**
  String get errorPeerBlocked;

  /// Offline build Me: clear the local learning data
  ///
  /// In en, this message translates to:
  /// **'Clear learning data'**
  String get offlineClearData;

  /// Offline build Me: what clearing removes
  ///
  /// In en, this message translates to:
  /// **'Deletes your progress, plans and materials on this device.'**
  String get offlineClearDataBody;

  /// Offline build Me: snack after clearing
  ///
  /// In en, this message translates to:
  /// **'Learning data cleared.'**
  String get offlineCleared;

  /// Offline build Me: clearing failed
  ///
  /// In en, this message translates to:
  /// **'Couldn’t clear the learning data.'**
  String get offlineClearFailed;

  /// Offline build: the local learning data could not be opened
  ///
  /// In en, this message translates to:
  /// **'Your training data could not be opened on this device. Try again.'**
  String get learnStorageUnavailable;

  /// Native Tox backend preparation failure title
  ///
  /// In en, this message translates to:
  /// **'Chat backend unavailable'**
  String get backendStartupFailedTitle;

  /// Actionable native backend startup failure explanation
  ///
  /// In en, this message translates to:
  /// **'DitMesh could not start the Tox network backend. Check that the native libraries are installed, then retry.'**
  String get backendStartupFailedBody;

  /// Tox bootstrap network settings: Title
  ///
  /// In en, this message translates to:
  /// **'Network and bootstrap'**
  String get bootstrapTitle;

  /// Tox bootstrap network settings: Description
  ///
  /// In en, this message translates to:
  /// **'Choose the public nodes used to join the Tox network.'**
  String get bootstrapDescription;

  /// Tox bootstrap network settings: ModeAuto
  ///
  /// In en, this message translates to:
  /// **'Automatic'**
  String get bootstrapModeAuto;

  /// Tox bootstrap network settings: ModeManual
  ///
  /// In en, this message translates to:
  /// **'Manual'**
  String get bootstrapModeManual;

  /// Tox bootstrap network settings: ModeLan
  ///
  /// In en, this message translates to:
  /// **'LAN host'**
  String get bootstrapModeLan;

  /// Tox bootstrap network settings: AutoDescription
  ///
  /// In en, this message translates to:
  /// **'Start with built-in nodes and refresh the official list in the background.'**
  String get bootstrapAutoDescription;

  /// Tox bootstrap network settings: ManualDescription
  ///
  /// In en, this message translates to:
  /// **'Use only your chosen node. You can enter a LAN node here.'**
  String get bootstrapManualDescription;

  /// Tox bootstrap network settings: LanDescription
  ///
  /// In en, this message translates to:
  /// **'Run a local UDP/DHT node on this desktop for other LAN devices.'**
  String get bootstrapLanDescription;

  /// Tox bootstrap network settings: CurrentNode
  ///
  /// In en, this message translates to:
  /// **'Current node'**
  String get bootstrapCurrentNode;

  /// Tox bootstrap network settings: Host
  ///
  /// In en, this message translates to:
  /// **'Host or IP address'**
  String get bootstrapHost;

  /// Tox bootstrap network settings: Port
  ///
  /// In en, this message translates to:
  /// **'UDP port'**
  String get bootstrapPort;

  /// Tox bootstrap network settings: PublicKey
  ///
  /// In en, this message translates to:
  /// **'DHT public key'**
  String get bootstrapPublicKey;

  /// Tox bootstrap network settings: TestNode
  ///
  /// In en, this message translates to:
  /// **'Test node'**
  String get bootstrapTestNode;

  /// Tox bootstrap network settings: SaveNode
  ///
  /// In en, this message translates to:
  /// **'Use tested node'**
  String get bootstrapSaveNode;

  /// Tox bootstrap network settings: ChooseNode
  ///
  /// In en, this message translates to:
  /// **'Choose public node'**
  String get bootstrapChooseNode;

  /// Tox bootstrap network settings: Reachable
  ///
  /// In en, this message translates to:
  /// **'DHT response received'**
  String get bootstrapReachable;

  /// Tox bootstrap network settings: Unreachable
  ///
  /// In en, this message translates to:
  /// **'No DHT response'**
  String get bootstrapUnreachable;

  /// Tox bootstrap network settings: Invalid
  ///
  /// In en, this message translates to:
  /// **'Invalid host, port or public key'**
  String get bootstrapInvalid;

  /// Tox bootstrap network settings: UdpUnavailable
  ///
  /// In en, this message translates to:
  /// **'A UDP probe could not run on this device. TCP connectivity is not tested.'**
  String get bootstrapUdpUnavailable;

  /// Tox bootstrap network settings: ProbeUnavailable
  ///
  /// In en, this message translates to:
  /// **'The probe could not start. This says nothing about node reachability.'**
  String get bootstrapProbeUnavailable;

  /// Tox bootstrap network settings: Fallback
  ///
  /// In en, this message translates to:
  /// **'Showing built-in fallback nodes; the official list could not be loaded.'**
  String get bootstrapFallback;

  /// Tox bootstrap network settings: Maintainer
  ///
  /// In en, this message translates to:
  /// **'Maintainer'**
  String get bootstrapMaintainer;

  /// Tox bootstrap network settings: Location
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get bootstrapLocation;

  /// Tox bootstrap network settings: LastPing
  ///
  /// In en, this message translates to:
  /// **'Last public check'**
  String get bootstrapLastPing;

  /// Tox bootstrap network settings: SwitchTitle
  ///
  /// In en, this message translates to:
  /// **'Switch bootstrap node'**
  String get bootstrapSwitchTitle;

  /// Tox bootstrap network settings: SwitchQuestion
  ///
  /// In en, this message translates to:
  /// **'Use this node?'**
  String get bootstrapSwitchQuestion;

  /// Tox bootstrap network settings: NotTestedWarning
  ///
  /// In en, this message translates to:
  /// **'This node has not been tested on your device.'**
  String get bootstrapNotTestedWarning;

  /// Tox bootstrap network settings: FailedWarning
  ///
  /// In en, this message translates to:
  /// **'This node did not answer a UDP probe. You can still select it.'**
  String get bootstrapFailedWarning;

  /// Tox bootstrap network settings: InconclusiveWarning
  ///
  /// In en, this message translates to:
  /// **'The probe was inconclusive. TCP connectivity is not tested.'**
  String get bootstrapInconclusiveWarning;

  /// Tox bootstrap network settings: SwitchConfirm
  ///
  /// In en, this message translates to:
  /// **'Use node'**
  String get bootstrapSwitchConfirm;

  /// Tox bootstrap network settings: Refresh
  ///
  /// In en, this message translates to:
  /// **'Refresh list'**
  String get bootstrapRefresh;

  /// Tox bootstrap network settings: StartLan
  ///
  /// In en, this message translates to:
  /// **'Start LAN node'**
  String get bootstrapStartLan;

  /// Tox bootstrap network settings: StopLan
  ///
  /// In en, this message translates to:
  /// **'Stop LAN node'**
  String get bootstrapStopLan;

  /// Tox bootstrap network settings: LanStopped
  ///
  /// In en, this message translates to:
  /// **'LAN node is stopped'**
  String get bootstrapLanStopped;

  /// Tox bootstrap network settings: LanRunning
  ///
  /// In en, this message translates to:
  /// **'LAN node is running'**
  String get bootstrapLanRunning;

  /// Tox bootstrap network settings: LanKeyChanges
  ///
  /// In en, this message translates to:
  /// **'The DHT key changes when the node restarts. Share the current full key.'**
  String get bootstrapLanKeyChanges;

  /// Tox bootstrap network settings: LanFirewallHint
  ///
  /// In en, this message translates to:
  /// **'Other devices must reach this UDP port through your local firewall.'**
  String get bootstrapLanFirewallHint;

  /// Tox bootstrap network settings: CopyNode
  ///
  /// In en, this message translates to:
  /// **'Copy node details'**
  String get bootstrapCopyNode;

  /// Tox bootstrap network settings: ShareNode
  ///
  /// In en, this message translates to:
  /// **'Share node details'**
  String get bootstrapShareNode;

  /// Tox bootstrap network settings: OperationFailed
  ///
  /// In en, this message translates to:
  /// **'The network setting could not be applied.'**
  String get bootstrapOperationFailed;

  /// Tox bootstrap network settings: ServiceUnavailable
  ///
  /// In en, this message translates to:
  /// **'Network settings are unavailable for this backend.'**
  String get bootstrapServiceUnavailable;

  /// Tox bootstrap network settings: Source
  ///
  /// In en, this message translates to:
  /// **'Official public node list'**
  String get bootstrapSource;

  /// Node online status from the public catalogue.
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get bootstrapOnline;

  /// Node offline status from the public catalogue.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get bootstrapOffline;

  /// Catalogue transport availability, not a live connectivity probe.
  ///
  /// In en, this message translates to:
  /// **'UDP: {udp} · TCP: {tcp}'**
  String bootstrapProtocolStatus(String udp, String tcp);

  /// ChatException code not_friend: sending to someone who is not (or no longer) a friend
  ///
  /// In en, this message translates to:
  /// **'This person is no longer in your friend list. Add them again to send messages.'**
  String get errorNotFriend;

  /// Group invite overflow action: accept a password-protected group invite
  ///
  /// In en, this message translates to:
  /// **'Accept with password'**
  String get chatAcceptWithPassword;

  /// Title of the group password dialog; name is the group name or a short chat id
  ///
  /// In en, this message translates to:
  /// **'Password for {name}'**
  String chatGroupPasswordTitle(String name);

  /// Label of the password field in the group password dialog
  ///
  /// In en, this message translates to:
  /// **'Group password'**
  String get chatGroupPasswordField;

  /// Snackbar: a group refused our join because of a wrong or missing password
  ///
  /// In en, this message translates to:
  /// **'{name} refused the join: the password is wrong or missing.'**
  String chatGroupJoinRefusedPassword(String name);

  /// Snackbar: a group refused our join because it is full
  ///
  /// In en, this message translates to:
  /// **'{name} refused the join: the group is full.'**
  String chatGroupJoinRefusedFull(String name);

  /// Snackbar: a group refused our join for another reason
  ///
  /// In en, this message translates to:
  /// **'{name} refused the join.'**
  String chatGroupJoinRefused(String name);

  /// Snackbar: a group we already held refused to take us back on reconnect
  ///
  /// In en, this message translates to:
  /// **'{name} refused to reconnect. Its history is kept; retry with the group\'s password.'**
  String chatGroupReconnectRefused(String name);

  /// Chat interface: firstChatTitle.
  ///
  /// In en, this message translates to:
  /// **'Your first Morse chat'**
  String get firstChatTitle;

  /// Chat interface: firstChatStart.
  ///
  /// In en, this message translates to:
  /// **'Get started'**
  String get firstChatStart;

  /// Chat interface: firstChatDismiss.
  ///
  /// In en, this message translates to:
  /// **'Dismiss guide'**
  String get firstChatDismiss;

  /// Chat interface: firstChatKeyTitle.
  ///
  /// In en, this message translates to:
  /// **'1. Key CQ to yourself'**
  String get firstChatKeyTitle;

  /// Chat interface: firstChatKeyBody.
  ///
  /// In en, this message translates to:
  /// **'Use the key to send CQ. A short press makes a dot and a longer press makes a dash. Your decoded draft stays read-only.'**
  String get firstChatKeyBody;

  /// Chat interface: firstChatSelf.
  ///
  /// In en, this message translates to:
  /// **'Try in my self chat'**
  String get firstChatSelf;

  /// Chat interface: firstChatListenTitle.
  ///
  /// In en, this message translates to:
  /// **'2. Listen and correct'**
  String get firstChatListenTitle;

  /// Chat interface: firstChatListenBody.
  ///
  /// In en, this message translates to:
  /// **'Before sending, use Preview to hear the draft and Backspace to remove a mistake. After sending, tap Play on your message. Self-chat messages stay on this device.'**
  String get firstChatListenBody;

  /// Chat interface: firstChatFriendTitle.
  ///
  /// In en, this message translates to:
  /// **'3. Chat with a friend'**
  String get firstChatFriendTitle;

  /// Chat interface: firstChatFriendBody.
  ///
  /// In en, this message translates to:
  /// **'Open Contacts, add your friend by QR code or Tox ID, and wait for the friend request to be accepted.'**
  String get firstChatFriendBody;

  /// Chat interface: firstChatFriend.
  ///
  /// In en, this message translates to:
  /// **'Add a friend'**
  String get firstChatFriend;

  /// Chat interface: firstChatOnline.
  ///
  /// In en, this message translates to:
  /// **'Keep both apps running and connected for messages to reach your friend.'**
  String get firstChatOnline;

  /// Chat interface: pendingMessagesTitle.
  ///
  /// In en, this message translates to:
  /// **'Pending and failed messages'**
  String get pendingMessagesTitle;

  /// Chat interface: pendingMessagesExplanation.
  ///
  /// In en, this message translates to:
  /// **'Queued messages stay on this device until both apps are connected. You can cancel a queued message or retry a confirmed failure.'**
  String get pendingMessagesExplanation;

  /// Chat interface: pendingMessagesEmpty.
  ///
  /// In en, this message translates to:
  /// **'No pending or failed messages'**
  String get pendingMessagesEmpty;

  /// Chat interface: deliveryDetailsTitle. Keep delivery, reading and listening confirmation distinct.
  ///
  /// In en, this message translates to:
  /// **'Delivery details'**
  String get deliveryDetailsTitle;

  /// Chat interface: deliveryLocalTitle. Keep delivery, reading and listening confirmation distinct.
  ///
  /// In en, this message translates to:
  /// **'Saved locally'**
  String get deliveryLocalTitle;

  /// Chat interface: deliveryLocalDetail. Keep delivery, reading and listening confirmation distinct.
  ///
  /// In en, this message translates to:
  /// **'This self-chat message is saved on this device.'**
  String get deliveryLocalDetail;

  /// Chat interface: deliverySentDetail. Keep delivery, reading and listening confirmation distinct.
  ///
  /// In en, this message translates to:
  /// **'Your app handed the message to transport. Waiting for the recipient to confirm receipt.'**
  String get deliverySentDetail;

  /// Chat interface: deliveryPeerTitle. Keep delivery, reading and listening confirmation distinct.
  ///
  /// In en, this message translates to:
  /// **'Recipient received'**
  String get deliveryPeerTitle;

  /// Chat interface: deliveryPeerDetail. Keep delivery, reading and listening confirmation distinct.
  ///
  /// In en, this message translates to:
  /// **'The recipient confirmed receipt. This does not indicate that they read or listened to it.'**
  String get deliveryPeerDetail;

  /// Chat interface: deliveryGroupTitle. Keep delivery, reading and listening confirmation distinct.
  ///
  /// In en, this message translates to:
  /// **'Received by a group member'**
  String get deliveryGroupTitle;

  /// Chat interface: deliveryGroupDetail. Keep delivery, reading and listening confirmation distinct.
  ///
  /// In en, this message translates to:
  /// **'At least one group member confirmed receipt. Other members may still be offline.'**
  String get deliveryGroupDetail;

  /// Chat interface: deliveryLocalOffline. Keep delivery, reading and listening confirmation distinct.
  ///
  /// In en, this message translates to:
  /// **'This device is not connected yet.'**
  String get deliveryLocalOffline;

  /// Chat interface: deliveryPeerOffline. Keep delivery, reading and listening confirmation distinct.
  ///
  /// In en, this message translates to:
  /// **'Your friend is offline.'**
  String get deliveryPeerOffline;

  /// Chat interface: deliveryGroupWaiting. Keep delivery, reading and listening confirmation distinct.
  ///
  /// In en, this message translates to:
  /// **'Waiting for a connection to the group.'**
  String get deliveryGroupWaiting;

  /// Chat interface: chatPreviewDraft.
  ///
  /// In en, this message translates to:
  /// **'Preview draft'**
  String get chatPreviewDraft;

  /// Chat interface: chatStopPreview.
  ///
  /// In en, this message translates to:
  /// **'Stop preview'**
  String get chatStopPreview;

  /// Message playback control: chatMessagePlayback.
  ///
  /// In en, this message translates to:
  /// **'Message playback'**
  String get chatMessagePlayback;

  /// Message playback control: chatOriginalRhythm.
  ///
  /// In en, this message translates to:
  /// **'Original keying rhythm'**
  String get chatOriginalRhythm;

  /// Message playback control: chatListenerRhythm.
  ///
  /// In en, this message translates to:
  /// **'Your listening speed'**
  String get chatListenerRhythm;

  /// Message playback control: chatOriginalAvailable.
  ///
  /// In en, this message translates to:
  /// **'Recorded marks and gaps are available.'**
  String get chatOriginalAvailable;

  /// Message playback control: chatOriginalUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Original rhythm unavailable; plays at your listening speed.'**
  String get chatOriginalUnavailable;

  /// Message playback control: chatOriginalPlaying.
  ///
  /// In en, this message translates to:
  /// **'Playing original rhythm'**
  String get chatOriginalPlaying;

  /// Message playback control: chatListenerPlaying.
  ///
  /// In en, this message translates to:
  /// **'Playing at your listening speed'**
  String get chatListenerPlaying;

  /// Message playback control: chatPause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get chatPause;

  /// Message playback control: chatResume.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get chatResume;

  /// Message playback control: chatPreviousWord.
  ///
  /// In en, this message translates to:
  /// **'Previous word'**
  String get chatPreviousWord;

  /// Message playback control: chatNextWord.
  ///
  /// In en, this message translates to:
  /// **'Next word'**
  String get chatNextWord;

  /// Message playback control: chatWordNumber.
  ///
  /// In en, this message translates to:
  /// **'Word {number}'**
  String chatWordNumber(int number);

  /// Message playback control: chatRangeStart.
  ///
  /// In en, this message translates to:
  /// **'First word'**
  String get chatRangeStart;

  /// Message playback control: chatRangeEnd.
  ///
  /// In en, this message translates to:
  /// **'Last word'**
  String get chatRangeEnd;

  /// Message playback control: chatRepeatRange.
  ///
  /// In en, this message translates to:
  /// **'Replay selected words'**
  String get chatRepeatRange;

  /// Message playback control: chatLoopRange.
  ///
  /// In en, this message translates to:
  /// **'Loop selected words'**
  String get chatLoopRange;

  /// Message playback control: chatPlaybackProgress.
  ///
  /// In en, this message translates to:
  /// **'Playback progress'**
  String get chatPlaybackProgress;

  /// Message playback control: chatWordProgress.
  ///
  /// In en, this message translates to:
  /// **'Word {current} of {total}'**
  String chatWordProgress(int current, int total);

  /// Message playback control: chatOriginalPreference.
  ///
  /// In en, this message translates to:
  /// **'Use original rhythm when a matching recording is available.'**
  String get chatOriginalPreference;

  /// Tooltip and accessible name of a conversation row's overflow menu button; name is the conversation title
  ///
  /// In en, this message translates to:
  /// **'Actions for {name}'**
  String chatConversationActions(String name);

  /// Snackbar: the compose draft could not be saved to storage
  ///
  /// In en, this message translates to:
  /// **'The draft could not be saved. Keep this screen open or send it now.'**
  String get chatDraftSaveFailed;

  /// Tooltip of the delete button on the message search date-range chip
  ///
  /// In en, this message translates to:
  /// **'Clear date range'**
  String get chatSearchClearDates;

  /// Snackbar: a group we already held refused to take us back, not because of a password
  ///
  /// In en, this message translates to:
  /// **'{name} refused to reconnect. Its history is kept; you can retry.'**
  String chatGroupReconnectFailed(String name);
}

class _SDelegate extends LocalizationsDelegate<S> {
  const _SDelegate();

  @override
  Future<S> load(Locale locale) {
    return SynchronousFuture<S>(lookupS(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['de', 'en', 'es', 'fr', 'ja', 'ko', 'pt', 'ru', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_SDelegate old) => false;
}

S lookupS(Locale locale) {

  // Lookup logic when language+script codes are specified.
  switch (locale.languageCode) {
    case 'zh': {
  switch (locale.scriptCode) {
    case 'Hant': return SZhHant();
   }
  break;
   }
  }

  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de': return SDe();
    case 'en': return SEn();
    case 'es': return SEs();
    case 'fr': return SFr();
    case 'ja': return SJa();
    case 'ko': return SKo();
    case 'pt': return SPt();
    case 'ru': return SRu();
    case 'zh': return SZh();
  }

  throw FlutterError(
    'S.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
