// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 's.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class SJa extends S {
  SJa([String locale = 'ja']) : super(locale);

  @override
  String get appName => 'DitMesh';

  @override
  String get navLearn => '学習';

  @override
  String get navChat => 'チャット';

  @override
  String get navGroups => 'グループ';

  @override
  String get navMe => '自分';

  @override
  String get navReference => '資料';

  @override
  String get navLearnDescription => 'Koch 法のレッスン、送信練習、受信練習。';

  @override
  String get navChatDescription => 'Tox P2P による、サーバーを使わない 1 対 1 のモールス通信。';

  @override
  String get navGroupsDescription => 'グループ通信網 — 複数の通信者が同じチャンネルで送信。';

  @override
  String get navReferenceDescription => '文字表、手続き符号、Q 符号、略語、双方向変換ツール。';

  @override
  String get navMeDescription => 'コールサイン、Tox の ID 情報、学習の進捗と設定。';

  @override
  String get shellOfflineBanner => 'オフライン：Tox ネットワークに接続していません。オンラインに戻るとメッセージを送信します。';

  @override
  String get actionOk => '確認';

  @override
  String get actionCancel => 'キャンセル';

  @override
  String get actionSave => '保存';

  @override
  String get actionDelete => '削除';

  @override
  String get actionCopy => 'コピー';

  @override
  String get actionShare => '共有';

  @override
  String get actionRetry => '再試行';

  @override
  String get actionClose => '閉じる';

  @override
  String get actionSearch => '検索';

  @override
  String get actionSettings => '設定';

  @override
  String get connectionConnecting => '接続中…';

  @override
  String get connectionOnline => 'オンライン';

  @override
  String get connectionOffline => 'オフライン';

  @override
  String get messageStatusPending => '送信待ち — 相手がオフライン';

  @override
  String get messageStatusPendingDetail => 'Tox にサーバーはありません。相手がオンラインになるとメッセージが届きます。';

  @override
  String get messageStatusSending => '送信中';

  @override
  String get messageStatusSent => '送信済み';

  @override
  String get messageStatusFailed => '送信失敗';

  @override
  String get errorWrongPassword => 'パスワードが違います。もう一度お試しください。';

  @override
  String get errorPeerOffline => 'この連絡先はオフラインです。Tox にサーバーはないため、相手が戻るまでメッセージは送信待ちになります。';

  @override
  String get errorInvalidToxId => '有効な Tox ID ではありません（76 桁の 16 進数が必要です）。';

  @override
  String get errorAlreadyFriend => 'この Tox ID はすでに友達リストに登録されています。';

  @override
  String get errorOwnId => 'これは自分の Tox ID です。';

  @override
  String get errorGroupNotFound => 'グループが見つかりません。';

  @override
  String get errorMessageTooLong => 'メッセージが Tox の 1 件あたりの長さ制限を超えています。';

  @override
  String get errorUnknown => '問題が発生しました';

  @override
  String get errorTeardownUnconfirmed => '前回の Tox セッションがまだ完全に停止していません。しばらくしてから再試行するか、アプリを再起動してください。';

  @override
  String get errorIdentityRecoveryPending => '前回のアイデンティティがまだ復元待ちです。アプリを再起動して再試行するか、アイデンティティのデータを削除してやり直してください。';

  @override
  String get languageTitle => '言語';

  @override
  String get languageSystemDefault => 'システムの設定に従う';

  @override
  String get languageSaveFailed => '言語設定を保存できませんでした。もう一度お試しください。';

  @override
  String learnLessonOf(int lesson, int total) {
    return 'レッスン $lesson / $total';
  }

  @override
  String learnCharsLearned(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 文字を習得',
    );
    return '$_temp0';
  }

  @override
  String learnDailyGoalProgress(int done, int goal) {
    return '$done / $goal 文字';
  }

  @override
  String learnStreakDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days 日連続で練習',
    );
    return '$_temp0';
  }

  @override
  String learnReviewDueCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '復習する文字：$count 文字',
      zero: '復習する文字はありません',
    );
    return '$_temp0';
  }

  @override
  String learnRoundScore(int correct, int total) {
    return '$total 文字中 $correct 文字正解';
  }

  @override
  String learnRoundOf(int round) {
    return 'ラウンド $round';
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
      other: '$count 文字を送信',
    );
    return '$_temp0';
  }

  @override
  String learnLessonUnlocked(String char) {
    return '次の文字を解放しました：$char';
  }

  @override
  String learnConfusedMissed(String target) {
    return '$target を聞き逃しました';
  }

  @override
  String learnConfusedAs(String target, String answered) {
    return '$target を $answered と聞き違えました';
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
      other: '$count 文字',
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
      other: '$count 文字を習得',
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
      other: '$count 文字を受信記録',
    );
    return '$_temp0';
  }

  @override
  String statsSessions(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 回の練習',
    );
    return '$_temp0';
  }

  @override
  String statsDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 日',
    );
    return '$_temp0';
  }

  @override
  String statsBestStreak(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '最長 $count 日連続',
    );
    return '$_temp0';
  }

  @override
  String statsGoalProgress(int done, int goal) {
    return '$done / $goal 文字';
  }

  @override
  String statsGoalRemaining(int remaining) {
    String _temp0 = intl.Intl.pluralLogic(
      remaining,
      locale: localeName,
      other: 'あと $remaining 文字',
    );
    return '$_temp0';
  }

  @override
  String statsTrendSubtitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '最近 $count 回の練習',
      one: '前回の練習',
    );
    return '$_temp0';
  }

  @override
  String statsTooltipSession(int index, int total) {
    return '練習 $index / $total';
  }

  @override
  String statsTooltipCopied(int correct, int total) {
    return '$correct / $total 正解';
  }

  @override
  String statsTooltipLesson(int lesson) {
    return 'レッスン $lesson';
  }

  @override
  String statsAttempts(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 回の試行',
    );
    return '$_temp0';
  }

  @override
  String statsCorrectOf(int correct, int attempts) {
    return '$attempts 回中 $correct 回正解';
  }

  @override
  String statsLessonIntroduced(int lesson) {
    return 'レッスン $lesson で登場';
  }

  @override
  String statsSrsBox(int box, int maxBox) {
    return 'ボックス $box / $maxBox';
  }

  @override
  String statsSrsDueIn(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days 日後に復習',
      one: '明日復習',
    );
    return '$_temp0';
  }

  @override
  String statsTimes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 回',
    );
    return '$_temp0';
  }

  @override
  String statsHeatmapCell(String target, String answered, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 回',
    );
    return '$target を $answered と回答：$_temp0';
  }

  @override
  String statsCalendarDay(String date, int chars) {
    String _temp0 = intl.Intl.pluralLogic(
      chars,
      locale: localeName,
      other: '$chars 文字',
      zero: '練習なし',
    );
    return '$date：$_temp0';
  }

  @override
  String statsActiveDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '練習した日：$count 日',
    );
    return '$_temp0';
  }

  @override
  String referenceEntryCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 件',
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
    return 'スキップしました（モールス符号なし）：$chars';
  }

  @override
  String referenceKochPositionValue(int position) {
    return 'Koch 法での順番：$position';
  }

  @override
  String referenceEstimatedSpeed(String wpm) {
    return '推定 $wpm WPM';
  }

  @override
  String get accountCopied => 'Tox ID をクリップボードにコピーしました';

  @override
  String get accountShowQr => 'QR コードを表示';

  @override
  String get accountToxId => 'Tox ID';

  @override
  String get accountDisplayName => '表示名';

  @override
  String get accountDisplayNameHint => 'コールサインまたはニックネーム';

  @override
  String get accountDisplayNameRequired => '表示名を入力してください';

  @override
  String get accountStatusMessage => 'ステータスメッセージ';

  @override
  String get accountPassword => 'パスワード';

  @override
  String get accountPasswordOptional => 'パスワード（任意）';

  @override
  String get accountConfirmPassword => 'パスワードの確認';

  @override
  String get accountPasswordsDoNotMatch => 'パスワードが一致しません';

  @override
  String get accountShowPassword => 'パスワードを表示';

  @override
  String get accountHidePassword => 'パスワードを隠す';

  @override
  String get accountStrengthWeak => '弱い：8 文字以上にしてください';

  @override
  String get accountStrengthFair => '普通：12 文字以上で複数の文字種を混ぜるとより安全です';

  @override
  String get accountStrengthStrong => '強い';

  @override
  String get accountStartupInspecting => 'ID 情報を確認中…';

  @override
  String get accountStartupOpening => 'ID 情報を開いています…';

  @override
  String get accountStartupFailedTitle => '起動できませんでした';

  @override
  String get accountStartupFailedBody => 'DitMesh が ID 情報を読み取れませんでした。データは変更されていません。再試行できます。';

  @override
  String get accountConnectionTapToReconnect => 'タップして再接続';

  @override
  String get accountWelcomeTitle => 'ID 情報はこのデバイスに保存されます';

  @override
  String get accountWelcomeIntro => 'DitMesh は Tox の P2P ネットワークを使用します。サーバーもアカウント登録も不要です。ID 情報は、このデバイスだけに保存される鍵のペアです。';

  @override
  String get accountWelcomePointNoServer => 'サーバー、電話番号、メールアドレスは不要です。通信者同士がモールス符号で直接やり取りします。';

  @override
  String get accountWelcomePointTraining => 'ストレートキーやアイアンビックパドルでモールス信号を打ち、個人やグループでチャットできます。';

  @override
  String get accountWelcomePointBackup => 'ID 情報を復元できるのは自分だけです。作成したらすぐにバックアップしてください。バックアップがなければ、デバイスを失うと ID 情報も失われます。';

  @override
  String get accountCreateIdentity => 'ID 情報を作成';

  @override
  String get accountRestoreFromBackup => 'バックアップから復元';

  @override
  String get accountCreateTitle => '自分の ID 情報を作成';

  @override
  String get accountCreateBody => '相手に表示する名前を選んでください。パスワードはこのデバイスの ID 情報ファイルを暗号化します。パスワードなしでアプリを開きたい場合は空欄にしてください。';

  @override
  String get accountCreateButton => '作成';

  @override
  String get accountCreating => '作成中…';

  @override
  String get accountBackupTitle => '今すぐ ID 情報をバックアップ';

  @override
  String get accountBackupBody => 'ID 情報はこのデバイスにしか存在しません。デバイスの紛失、初期化、盗難があった場合は復元できません。新しい ID 情報では連絡先に本人だと認識されず、学習の進捗も失われます。';

  @override
  String get accountBackupWhatIsInside => 'バックアップファイルには、パスワードで暗号化された ID 鍵と学習の進捗が含まれます。このデバイス以外の安全な場所に保管してください。';

  @override
  String get accountBackupWhatIsInsidePlain => 'バックアップファイルには、暗号化されていない ID 鍵と学習の進捗が含まれます。このファイルを手に入れた人は誰でもあなたの ID を使えます。鍵を暗号化するには先にパスワードを設定し、ファイルは安全な場所に保管してください。';

  @override
  String get accountPasswordScope => 'パスワードは ID 鍵を暗号化します。メッセージ履歴はディスク上で暗号化されないままですが、デバイスの暗号化で保護できます。';

  @override
  String get accountSectionNotifications => '通知';

  @override
  String get accountNotificationsEnable => '通知を表示';

  @override
  String get accountNotificationsEnableSubtitle => '新しいメッセージ、友だちリクエスト、グループ招待';

  @override
  String get accountNotificationsContent => 'メッセージの内容を表示';

  @override
  String get accountNotificationsContentSubtitle => 'バナーとロック画面にテキストとモールスを表示します。オフにすると、メッセージが届いたことだけを知らせます。';

  @override
  String get accountNotificationsAllow => '通知を許可';

  @override
  String get accountNotificationsAllowSubtitle => 'システムに通知の許可を求めます';

  @override
  String get accountNotificationsBlocked => 'システム設定でブロック中';

  @override
  String get accountNotificationsBlockedSubtitle => 'DitMesh のメッセージ通知はシステム設定でオフになっています。システム設定で再度オンにしてください。';

  @override
  String get accountNotificationsDenied => 'DitMesh の通知はシステム設定でオフになっています。';

  @override
  String get accountBackupSaveFile => 'バックアップファイルを保存';

  @override
  String get accountBackupShareFile => 'バックアップファイルを共有';

  @override
  String get accountBackupSaved => 'バックアップを保存しました';

  @override
  String get accountBackupNotSaved => 'バックアップは保存されませんでした';

  @override
  String get accountBackupFailed => 'バックアップを書き込めませんでした';

  @override
  String get accountBackupAcknowledge => 'このバックアップがなければ ID 情報を復元できないことを理解しました。';

  @override
  String get accountBackupContinue => 'DitMesh を始める';

  @override
  String get accountBackupShowQrHint => '友達は Tox ID を使ってあなたを追加します。テキストまたは QR コードで共有できます。';

  @override
  String get accountRestoreTitle => 'バックアップから復元';

  @override
  String get accountRestoreBody => 'DitMesh からエクスポートしたバックアップファイルを選んでください。ID 情報にパスワードを設定していた場合は、ここで入力する必要があります。';

  @override
  String get accountRestoreChooseFile => 'バックアップファイルを選択';

  @override
  String get accountRestoreNoFile => '先にバックアップファイルを選んでください';

  @override
  String get accountRestoreButton => '復元';

  @override
  String get accountRestoring => '復元中…';

  @override
  String get accountRestoreInvalidFile => 'このファイルは DitMesh のバックアップではありません。';

  @override
  String get accountRestoreReplacesWarning => '復元すると、このデバイスにある現在の ID 情報が置き換わります。';

  @override
  String get accountUnlockTitle => 'ID 情報のロックを解除';

  @override
  String get accountUnlockBody => 'ID 情報ファイルは暗号化されています。パスワードを入力して続行してください。';

  @override
  String get accountUnlockButton => 'ロック解除';

  @override
  String get accountUnlocking => 'ロック解除中…';

  @override
  String get accountUnlockRestoreInstead => '代わりにバックアップから復元';

  @override
  String get accountMeNoIdentity => 'ID 情報が読み込まれていません';

  @override
  String get accountSectionAccount => 'アカウント';

  @override
  String get accountSectionTraining => '練習';

  @override
  String get accountSectionAbout => 'アプリについて';

  @override
  String get accountSectionDanger => '危険な操作';

  @override
  String get accountEditProfile => 'プロフィールを編集';

  @override
  String get accountEditProfileBody => 'Tox ネットワーク上の連絡先に表示されます。';

  @override
  String get accountSetPassword => 'パスワードを設定';

  @override
  String get accountChangePassword => 'パスワードを変更';

  @override
  String get accountRemovePassword => 'パスワードを削除';

  @override
  String get accountCurrentPassword => '現在のパスワード';

  @override
  String get accountNewPassword => '新しいパスワード';

  @override
  String get accountPasswordUpdated => 'パスワードを更新しました';

  @override
  String get accountPasswordRemoved => 'パスワードを削除しました';

  @override
  String get accountProfileUpdated => 'プロフィールを更新しました';

  @override
  String get accountExportBackup => 'バックアップをエクスポート';

  @override
  String get accountExportBackupSubtitle => 'ID 情報と学習の進捗をファイルに保存';

  @override
  String get accountTrainingDefaults => '再生と練習の初期設定';

  @override
  String get accountTrainingDefaultsSubtitle => '速度、音の高さ、Farnsworth 間隔';

  @override
  String get accountTrainingDefaultsPlaceholder => '速度、音の高さ、Farnsworth 間隔の初期設定がここに表示されます。';

  @override
  String get accountAboutLicence => 'ライセンス';

  @override
  String get accountAboutLicenceValue => 'GPL-3.0';

  @override
  String get accountAboutSource => 'ソースコード';

  @override
  String get accountAboutSourceCopied => 'ソースコードのリンクをコピーしました';

  @override
  String get accountAboutBackend => 'バックエンド';

  @override
  String get accountDeleteIdentity => 'ID 情報を削除';

  @override
  String get accountDeleteIdentitySubtitle => 'このデバイスから ID 情報、履歴、学習の進捗を消去';

  @override
  String get accountDeleteDialogTitle => 'この ID 情報を削除しますか？';

  @override
  String get accountDeleteDialogBody => 'このデバイスから ID 情報、チャット履歴、学習の進捗が削除されます。バックアップがなければ復元できません。確認のため DELETE と入力してください。';

  @override
  String get accountDeleteConfirmWord => 'DELETE';

  @override
  String get accountDeleteConfirmHint => 'DELETE と入力';

  @override
  String get accountDeleteButton => '削除';

  @override
  String get accountRecoveryPendingDiscard => '復元待ちのアイデンティティを破棄してやり直す';

  @override
  String accountRestoreFileChosenSize(int bytes) {
    return 'バックアップファイルを選択しました（$bytes バイト）';
  }

  @override
  String get chatSearchConversations => '会話を検索';

  @override
  String get chatNoConversations => 'まだ会話がありません';

  @override
  String get chatNoSearchResults => '一致する会話がありません';

  @override
  String get chatPin => '固定';

  @override
  String get chatUnpin => '固定を解除';

  @override
  String get chatMarkRead => '既読にする';

  @override
  String get chatDelete => '削除';

  @override
  String get chatDeleteConversationTitle => '会話を削除しますか？';

  @override
  String get chatDeleteConversationBody => 'このデバイス上の会話履歴が削除されます。Tox にコピーは保存されていません。';

  @override
  String get chatDraftPrefix => '下書き：';

  @override
  String get chatSelectConversation => '会話を選択';

  @override
  String get chatContacts => '連絡先';

  @override
  String get chatNoMessages => 'まだメッセージがありません。CQ を送って始めましょう。';

  @override
  String get chatTrainingMode => '練習モード';

  @override
  String get chatTrainingModeOn => '練習モード有効：テキストを非表示';

  @override
  String get chatTrainingModeOff => '練習モード無効';

  @override
  String get chatAutoPlay => '受信したモールスを自動再生';

  @override
  String get chatAutoPlayOn => '自動再生オン：新着メッセージを受信時に再生します';

  @override
  String get chatAutoPlayOff => '自動再生オフ';

  @override
  String get chatReveal => '表示';

  @override
  String get chatHiddenText => 'まず聞いてから表示';

  @override
  String get chatPlay => 'モールス符号を再生';

  @override
  String get chatStop => '停止';

  @override
  String get chatPlaybackSettings => '再生設定';

  @override
  String get chatCharacterSpeed => '文字速度';

  @override
  String get chatFarnsworthSpeed => 'Farnsworth 速度';

  @override
  String get chatTone => '音の高さ';

  @override
  String get chatWpm => 'WPM';

  @override
  String get chatHz => 'Hz';

  @override
  String get chatMembers => 'メンバー';

  @override
  String get chatLeaveGroup => 'グループを退出';

  @override
  String get chatLeaveGroupTitle => 'このグループを退出しますか？';

  @override
  String get chatLeaveGroupBody => 'メッセージを受信しなくなります。あとでチャット ID を使って再参加できます。';

  @override
  String get chatLeave => '退出';

  @override
  String get chatConferenceNote => '旧形式の会議：ここではモールスのキー操作メタデータ（v2）を利用できません。テキストは利用できます。';

  @override
  String get chatClearHistory => '履歴を消去';

  @override
  String get chatModeStraightKey => '縦振れ電鍵';

  @override
  String get chatModePaddles => 'パドル';

  @override
  String get chatKeyMessage => '電鍵でメッセージを打鍵';

  @override
  String get chatSend => '送信';

  @override
  String get chatTooLong => 'Tox メッセージ 1 件の長さ制限を超えています';

  @override
  String get chatKeyHint => '電鍵エリアを押すか、スペースキーを押してください';

  @override
  String get chatPaddleHint => 'パドルをタップするか Ctrl を押し続けてください（左：短点、右：長点）';

  @override
  String get chatDeleteLast => '最後の文字を削除';

  @override
  String get chatNoFriends => 'まだ友達がいません。相手の Tox ID で追加してください。';

  @override
  String get chatNoRequests => '保留中のリクエストはありません';

  @override
  String get chatAddFriend => '友達を追加';

  @override
  String get chatMyToxId => '自分の Tox ID';

  @override
  String get chatToxIdLabel => 'Tox ID（76 桁の 16 進数）';

  @override
  String get chatToxIdInvalid => 'Tox ID は 76 桁の 16 進数でなければなりません';

  @override
  String get chatToxIdOwn => 'これは自分の Tox ID です';

  @override
  String get chatToxIdAlreadyFriend => 'すでに友達リストに登録されています';

  @override
  String get chatRequestMessage => 'メッセージ';

  @override
  String get chatDefaultRequestMessage => 'DitMesh CQ';

  @override
  String get chatSendRequest => 'リクエストを送信';

  @override
  String get chatRequestSent => '友達リクエストを送信しました';

  @override
  String get chatScanQr => 'QR コードをスキャン';

  @override
  String get chatScanQrDesktopHint => 'QR コードの読み取りにはスマートフォンのカメラが必要です';

  @override
  String get chatScanQrTitle => 'Tox ID をスキャン';

  @override
  String get chatScanQrNotToxId => 'この QR コードは Tox ID ではありません';

  @override
  String get chatAccept => '承認';

  @override
  String get chatReject => '拒否';

  @override
  String get chatCopied => 'クリップボードにコピーしました';

  @override
  String get chatNoIdentity => 'ID 情報が読み込まれていません';

  @override
  String get chatRemoveFriend => '友達を削除';

  @override
  String get chatRemoveFriendTitle => 'この友達を削除しますか？';

  @override
  String get chatRemoveFriendBody => '相手からメッセージを受信しなくなります。';

  @override
  String get chatRemove => '削除';

  @override
  String get chatNoGroups => 'まだグループがありません。作成するか、チャット ID で参加してください。';

  @override
  String get chatCreateGroup => 'グループを作成';

  @override
  String get chatJoinGroup => 'グループに参加';

  @override
  String get chatGroupName => 'グループ名';

  @override
  String get chatGroupNameRequired => 'グループ名を入力してください';

  @override
  String get chatAdvanced => '詳細設定';

  @override
  String get chatLegacyConference => '旧形式の会議（旧クライアント用）';

  @override
  String get chatLegacyConferenceHint => '非推奨：固定のチャット ID もモールスのメタデータもありません。';

  @override
  String get chatCreate => '作成';

  @override
  String get chatChatIdLabel => 'チャット ID（64 桁の 16 進数）';

  @override
  String get chatChatIdInvalid => 'チャット ID は 64 桁の 16 進数でなければなりません';

  @override
  String get chatPassword => 'パスワード（任意）';

  @override
  String get chatJoin => '参加';

  @override
  String get chatJoinRequested => '参加中 — メンバーが見つかるとグループが表示されます。';

  @override
  String get chatConferenceBadge => '会議';

  @override
  String get chatCopyChatId => 'チャット ID をコピー';

  @override
  String get learnLessonCardTitle => 'Koch 法のレッスン';

  @override
  String get learnCourseComplete => 'コース完了！引き続き腕を磨きましょう。';

  @override
  String get learnDailyGoalTitle => '今日';

  @override
  String get learnDailyGoalMet => '今日の目標を達成';

  @override
  String get learnNoStreak => '今日から毎日練習しましょう';

  @override
  String get learnContinueLesson => 'レッスンを続ける';

  @override
  String get learnReceivePractice => '受信練習';

  @override
  String get learnSendPractice => '送信練習';

  @override
  String get learnReviewDue => '復習の時期が来た文字';

  @override
  String get learnSettings => '練習設定';

  @override
  String get learnLoading => '学習の進捗を読み込み中…';

  @override
  String get learnIdentityRequired => '練習を始めるには ID 情報を作成するか、ロックを解除してください。進捗は ID 情報と一緒に保存され、バックアップにも含まれます。';

  @override
  String get learnLoadFailed => '保存済みの進捗を読み取れませんでした。最初から始めます。元のファイルは .corrupt として保存されています。';

  @override
  String get learnProgressSaveFailed => '進捗を保存できませんでした。DitMesh を閉じるまでは今回の結果が有効です。';

  @override
  String get learnChooseDrill => '練習を選択';

  @override
  String get learnDrillGroups => 'ランダムな文字列';

  @override
  String get learnDrillWords => '単語';

  @override
  String get learnDrillCallsigns => 'コールサイン';

  @override
  String get learnDrillQso => '交信（QSO）';

  @override
  String get learnDrillCharacters => '1 文字ずつ';

  @override
  String get learnDrillAbbreviations => '略語と Q 符号';

  @override
  String get learnDrillNumbers => '数字のグループ';

  @override
  String get learnDrillConfusables => '聞き違えやすい文字';

  @override
  String get learnDrillContest => 'コンテストの交信';

  @override
  String get learnDrillGroupsHint => '学習済みの文字から作るランダムな文字列';

  @override
  String get learnDrillCharactersHint => '1 文字ずつ聞いて、すぐに答えましょう';

  @override
  String get learnDrillWordsHint => 'よく使う英単語';

  @override
  String get learnDrillAbbreviationsHint => 'TNX、FB、QTH、QSL など、無線交信で使う略語';

  @override
  String get learnDrillNumbersHint => '電文や通し番号で使う 5 桁の数字グループ';

  @override
  String get learnDrillCallsignsHint => '世界各地のアマチュア無線のコールサイン';

  @override
  String get learnDrillConfusablesHint => 'S/H、U/V など、聞き違えやすい文字をペアで練習';

  @override
  String get learnDrillQsoHint => '一連の交信で使う文章';

  @override
  String get learnDrillContestHint => 'コンテストの速度でコールサイン、5NN、通し番号やゾーンを受信';

  @override
  String get learnDrillReviewHint => '復習の時期が来た文字';

  @override
  String get toolsTitle => '無線のツール';

  @override
  String get toolsGridTitle => 'グリッドロケーター';

  @override
  String get toolsGridHint => '座標からロケーターを算出し、距離とアンテナの方位を確認';

  @override
  String get toolsBandsTitle => '周波数帯とアンテナ';

  @override
  String get toolsBandsHint => '周波数が属するバンド、波長、ダイポールの長さを確認';

  @override
  String get toolsSpeedTitle => 'CW の速度';

  @override
  String get toolsSpeedHint => 'WPM を短点の長さ、間隔、1 分あたりの文字数に換算';

  @override
  String get toolsRstTitle => 'RST レポート';

  @override
  String get toolsRstHint => '信号レポートを作成し、各桁の意味を確認';

  @override
  String get toolsClockTitle => 'UTC 時計';

  @override
  String get toolsClockHint => 'ログに記録する UTC と現地時刻を並べて表示';

  @override
  String get toolsGridFromCoordinates => '座標から算出';

  @override
  String get toolsGridLatitude => '緯度';

  @override
  String get toolsGridLongitude => '経度';

  @override
  String get toolsGridCoordinatesHelp => '十進数の度数で入力。南緯と西経は負の値です';

  @override
  String get toolsGridInvalidCoordinates => '緯度は -90～90、経度は -180～180';

  @override
  String get toolsGridLocator => 'ロケーター';

  @override
  String get toolsGridDistanceSection => '距離と方位';

  @override
  String get toolsGridMine => '自局のロケーター';

  @override
  String get toolsGridTheirs => '相手局のロケーター';

  @override
  String get toolsGridInvalidLocator => '2、4、6、8 文字で入力してください。例：OM89ex';

  @override
  String get toolsGridCenter => 'グリッドの中心';

  @override
  String get toolsGridDistance => '距離';

  @override
  String get toolsGridShortPath => 'ショートパスの方位';

  @override
  String get toolsGridLongPath => 'ロングパスの方位';

  @override
  String get toolsBandsFrequency => '周波数（MHz）';

  @override
  String get toolsBandsInvalidFrequency => '0 より大きい周波数を入力してください';

  @override
  String toolsBandsRegionLabel(int number) {
    return '第 $number 地域';
  }

  @override
  String get toolsBandsRegionHelp => '1：ヨーロッパ・アフリカ・中東 — 2：南北アメリカ — 3：アジア・太平洋';

  @override
  String toolsBandsInBand(String band) {
    return '$band アマチュア無線バンド内';
  }

  @override
  String get toolsBandsOutOfBand => 'アマチュア無線バンド外';

  @override
  String get toolsBandsWavelength => '波長';

  @override
  String get toolsBandsDipole => '半波長ダイポール（全長）';

  @override
  String get toolsBandsQuarterWave => '1/4 波長の垂直アンテナ';

  @override
  String get toolsBandsAntennaNote => '長さには 0.95 の短縮係数を含みます。共振するように長さを調整してください。';

  @override
  String get toolsBandsTable => '周波数帯の範囲';

  @override
  String toolsBandsQrp(String frequency) {
    return 'QRP CW $frequency';
  }

  @override
  String get toolsBandsDisclaimer => 'ITU の周波数分配です。免許や各国のバンドプランでは、利用できる範囲が狭い場合があります。';

  @override
  String get toolsSpeedCharacter => '文字速度';

  @override
  String get toolsSpeedFarnsworth => 'Farnsworth 間隔';

  @override
  String get toolsSpeedOverall => '全体の速度';

  @override
  String get toolsSpeedDit => '短点';

  @override
  String get toolsSpeedDah => '長点';

  @override
  String get toolsSpeedCharGap => '文字間の間隔';

  @override
  String get toolsSpeedWordGap => '単語間の間隔';

  @override
  String get toolsSpeedCpm => '1 分あたりの文字数';

  @override
  String get toolsSpeedParis => 'PARIS 1 語の所要時間';

  @override
  String get toolsRstReadability => '了解度（R）';

  @override
  String get toolsRstStrength => '信号強度（S）';

  @override
  String get toolsRstTone => '音調（T）';

  @override
  String get toolsRstReport => 'レポート';

  @override
  String get toolsRstCut => 'コンテスト用の略記';

  @override
  String get toolsRstPhone => '音声通信（T の報告なし）';

  @override
  String get toolsRstR1 => '了解できない';

  @override
  String get toolsRstR2 => 'かろうじて了解でき、ときどき単語が聞き取れる';

  @override
  String get toolsRstR3 => 'かなり困難だが了解できる';

  @override
  String get toolsRstR4 => 'ほぼ困難なく了解できる';

  @override
  String get toolsRstR5 => '完全に了解できる';

  @override
  String get toolsRstS1 => '非常に弱く、かろうじて感じられる';

  @override
  String get toolsRstS2 => '非常に弱い';

  @override
  String get toolsRstS3 => '弱い';

  @override
  String get toolsRstS4 => 'まずまずの強さ';

  @override
  String get toolsRstS5 => 'やや良好';

  @override
  String get toolsRstS6 => '良好';

  @override
  String get toolsRstS7 => 'かなり強い';

  @override
  String get toolsRstS8 => '強い';

  @override
  String get toolsRstS9 => '極めて強い';

  @override
  String get toolsRstT1 => '非常に粗く帯域が広い、未整流の交流音';

  @override
  String get toolsRstT2 => '非常に粗い交流音で、耳障りかつ帯域が広い';

  @override
  String get toolsRstT3 => '粗い音。整流されているが、平滑化されていない';

  @override
  String get toolsRstT4 => '粗い音だが、わずかに平滑化されている';

  @override
  String get toolsRstT5 => '平滑化されているが、リップル変調が強い';

  @override
  String get toolsRstT6 => '平滑化されているが、明らかなリップルがある';

  @override
  String get toolsRstT7 => 'ほぼ純音だが、わずかなリップルがある';

  @override
  String get toolsRstT8 => 'ほぼ完全な音で、ごくわずかな変調がある';

  @override
  String get toolsRstT9 => '完全な純音で、リップルがない';

  @override
  String get toolsClockUtc => 'UTC';

  @override
  String get toolsClockLocal => '現地時刻';

  @override
  String get toolsClockNote => 'ログと QSL カードには UTC を使います。';

  @override
  String get learnReceiveTitle => '受信';

  @override
  String get learnReviewTitle => '復習';

  @override
  String get learnListen => '聞いてください…';

  @override
  String get learnReady => '準備完了';

  @override
  String get learnReplay => 'もう一度再生';

  @override
  String get learnAnswerHint => '聞こえた内容を入力';

  @override
  String get learnSubmit => '答え合わせ';

  @override
  String get learnNext => '次へ';

  @override
  String get learnFinish => '終了';

  @override
  String get learnDone => '完了';

  @override
  String get learnBackspace => '削除';

  @override
  String get learnSpace => 'スペース';

  @override
  String get learnSent => '送信内容';

  @override
  String get learnYourCopy => '受信記録';

  @override
  String get learnRoundPerfect => '全問正解！';

  @override
  String get learnSessionSummary => '練習結果';

  @override
  String get learnLessonPassed => 'レッスン合格';

  @override
  String get learnLessonNotPassed => '続けましょう：正答率 90% で次の文字を解放';

  @override
  String get learnReviewRecorded => '復習を記録しました';

  @override
  String get learnWeakChars => '練習が必要';

  @override
  String get learnConfusions => '聞き違い';

  @override
  String get learnNoFeedbackWarning => '音、画面点滅、振動がすべて無効です。代わりに画面を点滅させます。';

  @override
  String get learnSendTitle => '送信';

  @override
  String get learnSendThis => 'これを送信';

  @override
  String get learnCopyFromMemory => '記憶を頼りに';

  @override
  String get learnHiddenTarget => '非表示 — 記憶を頼りに送信';

  @override
  String get learnDecoded => '解読結果';

  @override
  String get learnWaitingForKey => '準備ができたら送信を始めてください';

  @override
  String get learnRestart => '最初から';

  @override
  String get learnTryAnother => '別の問題に挑戦';

  @override
  String get learnKeyerStraight => '縦振れ電鍵';

  @override
  String get learnKeyerIambicA => 'アイアンビック A';

  @override
  String get learnKeyerIambicB => 'アイアンビック B';

  @override
  String get learnLegendStraight => 'スペースキー = 電鍵';

  @override
  String get learnLegendPaddles => '左 Ctrl = 短点、右 Ctrl = 長点';

  @override
  String get learnSendClean => '正確な送信です。修正点はありません。';

  @override
  String get learnSendIssues => 'リズムのアドバイス';

  @override
  String get learnYourSending => '解読結果';

  @override
  String get learnStraightKeyLabel => '電鍵';

  @override
  String get learnDitLabel => '短点';

  @override
  String get learnDahLabel => '長点';

  @override
  String get learnSettingsTitle => '練習設定';

  @override
  String get learnCharacterSpeed => '文字速度';

  @override
  String get learnFarnsworth => 'Farnsworth 間隔';

  @override
  String get learnFarnsworthHelp => '文字自体の速度は速いまま、文字間の間隔をこの速度に合わせて広げます。';

  @override
  String get learnEffectiveSpeed => '実効速度';

  @override
  String get learnTone => '音の高さ';

  @override
  String get learnPlaySample => 'サンプルを再生';

  @override
  String get learnSessionLength => '練習の長さ';

  @override
  String get learnFeedback => 'フィードバック';

  @override
  String get learnSound => '音';

  @override
  String get learnFlash => '画面点滅';

  @override
  String get learnHaptic => '振動';

  @override
  String get learnKeyer => '電鍵モード';

  @override
  String get learnDailyGoal => '毎日の目標';

  @override
  String get referenceReferenceTitle => 'モールス符号の資料';

  @override
  String get referenceTranslatorTitle => '変換ツール';

  @override
  String get referencePlay => '再生';

  @override
  String get referenceStop => '停止';

  @override
  String get referenceClear => '消去';

  @override
  String get referenceClose => '閉じる';

  @override
  String get referenceEmptyOutput => '—';

  @override
  String get referenceSearchHint => '文字、手続き符号、Q 符号を検索…';

  @override
  String get referenceClearSearch => '検索をクリア';

  @override
  String get referenceNoResults => '検索に一致する項目がありません。';

  @override
  String get referenceSectionAlphabet => '文字表';

  @override
  String get referenceSectionPunctuation => '句読点';

  @override
  String get referenceSectionProsigns => '手続き符号';

  @override
  String get referenceSectionQCodes => 'Q 符号';

  @override
  String get referenceSectionAbbreviations => 'CW 略語';

  @override
  String get referenceSectionKoch => 'Koch 法の順番';

  @override
  String get referenceAlphabetHint => 'カードをタップすると音を聞けます。長押しすると覚え方を表示します。';

  @override
  String get referenceKochHint => 'Koch 法で文字を学ぶ順番です（LCWO の順番）。K と M から始め、受信の正答率が 90% に達したら 1 文字追加します。';

  @override
  String get referenceMnemonicTitle => '覚え方';

  @override
  String get referenceMeaningLabel => '意味';

  @override
  String get referencePlaybackSettings => '再生設定';

  @override
  String get referenceCharacterSpeed => '文字速度';

  @override
  String get referenceFarnsworth => 'Farnsworth 間隔';

  @override
  String get referenceFarnsworthHelp => '文字自体の速度はそのまま、間隔を実効速度に合わせて広げます。';

  @override
  String get referenceEffectiveSpeed => '実効速度';

  @override
  String get referenceTone => '音の高さ';

  @override
  String get referenceModeTextToMorse => 'テキスト → モールス符号';

  @override
  String get referenceModeMorseToText => 'モールス符号 → テキスト';

  @override
  String get referenceModeKey => '電鍵で送信';

  @override
  String get referenceTextInputLabel => 'テキスト';

  @override
  String get referenceTextInputHint => '符号に変換するテキストを入力…';

  @override
  String get referencePatternOutputLabel => 'モールス符号';

  @override
  String get referenceCopyPattern => '符号をコピー';

  @override
  String get referencePatternCopied => '符号をコピーしました';

  @override
  String get referencePatternInputLabel => 'モールス符号';

  @override
  String get referencePatternInputHint => '. と - を入力し、文字間はスペース、単語間は / で区切ってください';

  @override
  String get referenceTextOutputLabel => 'テキスト';

  @override
  String get referenceCopyText => 'テキストをコピー';

  @override
  String get referenceTextCopied => 'テキストをコピーしました';

  @override
  String get referenceUnknownPatternHelp => '対応する文字がない符号は <pattern> として表示されます。';

  @override
  String get referenceKeypadDit => '短点';

  @override
  String get referenceKeypadDah => '長点';

  @override
  String get referenceKeypadCharGap => '文字間隔';

  @override
  String get referenceKeypadWordGap => '単語間隔';

  @override
  String get referenceKeypadBackspace => 'バックスペース';

  @override
  String get referenceKeyHint => '電鍵を押し続けて送信してください。キーボードではスペースキーを押し続けます。';

  @override
  String get referenceKeyLabel => '電鍵';

  @override
  String get referenceKeyDecodedLabel => '解読結果';

  @override
  String get referenceKeyPendingLabel => '送信中';

  @override
  String get statsTitle => '統計';

  @override
  String get statsLoading => '統計を読み込み中…';

  @override
  String get statsLoadFailed => '学習の進捗を読み込めませんでした。下に引くか、開き直して再試行してください。';

  @override
  String get statsRetry => '再試行';

  @override
  String get statsEmptyTitle => 'まだ練習記録がありません';

  @override
  String get statsEmptyBody => '初めての受信練習または送信練習を終えると、正答率の推移、文字ごとの習熟度、練習カレンダーがここに表示されます。';

  @override
  String get statsEmptyCallToAction => '「学習」で「レッスンを続ける」を押すと始められます。';

  @override
  String get statsOverviewTitle => '概要';

  @override
  String get statsTileLesson => 'Koch 法のレッスン';

  @override
  String get statsTileAccuracy => '正答率';

  @override
  String get statsNoData => '--';

  @override
  String get statsTilePractice => '練習量';

  @override
  String get statsTileStreak => '連続日数';

  @override
  String get statsTileDailyGoal => '毎日の目標';

  @override
  String get statsGoalMet => '今日の目標達成';

  @override
  String get statsSummaryTitle => '自分の統計';

  @override
  String get statsSummaryOpen => '統計を見る';

  @override
  String get statsTrendTitle => '正答率の推移';

  @override
  String get statsTrendHint => '点をタップすると練習の詳細を確認できます。';

  @override
  String get statsSeriesReceive => '受信';

  @override
  String get statsSeriesSend => '送信';

  @override
  String get statsAxisSessions => '練習';

  @override
  String get statsCharsTitle => '文字';

  @override
  String get statsCharsSubtitle => 'Koch 法の順番です。文字をタップすると詳細を表示します。';

  @override
  String get statsCharsNotStarted => 'まだ練習していません';

  @override
  String get statsNotInCourse => 'Koch 法のコースに含まれていません';

  @override
  String get statsSrsTitle => '間隔反復学習';

  @override
  String get statsSrsNotTracked => 'まだ予定がありません';

  @override
  String get statsSrsDueNow => '今すぐ復習';

  @override
  String get statsConfusionsTitle => 'よく聞き違える文字';

  @override
  String get statsConfusionsNone => '聞き違いの記録はありません';

  @override
  String get statsConfusionMissed => '聞き逃し';

  @override
  String get statsBucketLegendTitle => '正答率';

  @override
  String get statsBucketNone => 'なし';

  @override
  String get statsBucketWeak => '< 70%';

  @override
  String get statsBucketFair => '70-89%';

  @override
  String get statsBucketGood => '90-97%';

  @override
  String get statsBucketStrong => '>= 98%';

  @override
  String get statsHeatmapTitle => '聞き違いの一覧';

  @override
  String get statsHeatmapSubtitle => '行は送信された文字、列は回答した文字です。色が濃いほど回数が多いことを示します。';

  @override
  String get statsHeatmapEmpty => 'まだ聞き違いの記録がありません。間違えた回答がここに表示されます。';

  @override
  String get statsHeatmapLegendLow => '少ない';

  @override
  String get statsHeatmapLegendHigh => '多い';

  @override
  String get statsHeatmapAxisTarget => '送信内容';

  @override
  String get statsHeatmapAxisAnswered => '回答内容';

  @override
  String get statsCalendarTitle => '練習カレンダー';

  @override
  String get statsCalendarSubtitle => '最近 12 週間';

  @override
  String get statsCalendarLegendLess => '少ない';

  @override
  String get statsCalendarLegendMore => '多い';

  @override
  String get statsStreakExplanation => '1 回以上練習した日が何日続いたかを数えます。丸 1 日練習を休むとリセットされます。同じ日に 2 回練習しても 1 日として数えます。';

  @override
  String get learnStatistics => '統計';

  @override
  String get listenTitle => '受信する';

  @override
  String get listenStart => '開始';

  @override
  String get listenStop => '停止';

  @override
  String get listenStarting => 'マイクを起動中…';

  @override
  String get listenClear => 'テキストを消去';

  @override
  String get listenCopy => 'テキストをコピー';

  @override
  String get listenCopied => '解読したテキストをコピーしました';

  @override
  String get listenSettings => '受信設定';

  @override
  String get listenDecoded => '解読結果';

  @override
  String get listenEmptyHint => 'モールスの音にマイクを向けてください。解読したテキストがここに表示されます。';

  @override
  String get listenIdleHint => '「開始」をタップしてモールスの音を受信してください。';

  @override
  String get listenPending => '受信中';

  @override
  String get listenSpeed => '速度';

  @override
  String get listenSpeedUnknown => '-- WPM';

  @override
  String get listenLevel => '信号';

  @override
  String get listenToneOn => '音あり';

  @override
  String get listenTone => '音の周波数';

  @override
  String get listenToneLocked => '周波数ロック中';

  @override
  String get listenToneSearching => '探索中';

  @override
  String get listenToneManual => '手動';

  @override
  String get listenAutoTune => '自動同調';

  @override
  String get listenAutoTuneHelp => '400–1000 Hz の範囲で最も強い音を追尾します。スライダーを動かすと手動で同調できます。';

  @override
  String get listenRetune => '自動';

  @override
  String get listenBlockSize => '解析ブロック';

  @override
  String get listenBlockSizeHelp => 'ブロックが小さいほど短点・長点の境界を正確に捉えますが、ノイズの影響を受けやすくなります。256 サンプル（5.3 ms）は 5–40 WPM に適しています。';

  @override
  String get listenMinElement => '最短の符号要素';

  @override
  String get listenMinElementHelp => 'これより短い音や間隔は、クリックノイズや音切れとして無視します。';

  @override
  String get listenPermissionDenied => 'マイクへのアクセスが許可されていません。システム設定で許可してから再試行してください。';

  @override
  String get listenPermissionRetry => '再試行';

  @override
  String get listenStartFailed => 'マイクを起動できませんでした。';

  @override
  String get listenNoInput => 'マイクが見つかりません。接続してから再試行してください。';

  @override
  String get listenStreamFailed => 'マイクが予期せず停止しました。もう一度お試しください。';

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
    return '$samples サンプル（$ms ms）';
  }

  @override
  String listenMsValue(int ms) {
    return '$ms ms';
  }

  @override
  String get listenStoppedInBackground => 'アプリがバックグラウンドに移ったため、受信を停止しました。';

  @override
  String get learnWpmUnknown => '-- WPM';

  @override
  String get learnTipDitTooLongTitle => '短点が長すぎます';

  @override
  String get learnTipDahTooShortTitle => '長点が短すぎます';

  @override
  String get learnTipIntraGapTooLongTitle => '符号要素が離れすぎています';

  @override
  String get learnTipCharGapTooShortTitle => '文字間が詰まっています';

  @override
  String get learnTipWordGapTooShortTitle => '単語間が詰まっています';

  @override
  String get learnTipSpeedUnsteadyTitle => '速度が不安定です';

  @override
  String get learnSeverityMinor => '軽微';

  @override
  String get learnSeverityModerate => '目立つ';

  @override
  String get learnSeveritySevere => '大きい';

  @override
  String get notificationOpen => '開く';

  @override
  String get notificationChannelMessages => 'メッセージ';

  @override
  String get notificationChannelMessagesDescription => '友達やグループからの新しいモールスメッセージ';

  @override
  String get notificationChannelFriendRequests => '友達リクエスト';

  @override
  String get notificationChannelFriendRequestsDescription => '誰かがあなたを友達に追加したがっています';

  @override
  String get notificationChannelGroupInvites => 'グループへの招待';

  @override
  String get notificationChannelGroupInvitesDescription => '友達からグループに招待されました';

  @override
  String get notificationNewMessage => '新しいメッセージ';

  @override
  String get notificationFriendRequestTitle => '新しい友達リクエスト';

  @override
  String learnNewestCharIs(String char) {
    return 'このレッスンの新しい文字：$char';
  }

  @override
  String learnCharNewSemantics(String char) {
    return '$char、新しい文字';
  }

  @override
  String learnPendingPattern(String pattern) {
    return '送信中：$pattern';
  }

  @override
  String learnIssueHeadline(String title, String severity) {
    return '$title（$severity）';
  }

  @override
  String learnRatioTimes(String ratio) {
    return '$ratio 倍';
  }

  @override
  String learnTipDitTooLong(String ratio) {
    return '短点が長すぎます（短点の約 $ratio）。「ツー」ではなく「トン」と短く、押し続けずに軽くたたく感覚で送信してください。';
  }

  @override
  String learnTipDahTooShort(String ratio) {
    return '長点が短すぎます（短点の約 $ratio、目標は 3 倍）。短点 3 つ分の長さで押し続けてください。';
  }

  @override
  String learnTipIntraGapTooLong(String ratio) {
    return '文字内の間隔が広すぎます（短点の約 $ratio）。1 文字の符号要素は間隔を詰めて送信してください。';
  }

  @override
  String learnTipCharGapTooShort(String ratio) {
    return '文字同士がつながっています（間隔は短点の約 $ratio、目標は 3 倍）。文字の後に明確な休止を入れてください。';
  }

  @override
  String learnTipWordGapTooShort(String ratio) {
    return '単語同士が近すぎます（間隔は短点の約 $ratio、目標は 7 倍）。単語の間には長めの休止を入れてください。';
  }

  @override
  String learnTipSpeedUnsteady(int percent) {
    return '速度が変動しています（変動 $percent%）。一定のテンポを決め、行の最後まで保ちましょう。';
  }

  @override
  String learnIssueDetailDitTooLong(int offending, int total, String ratio) {
    return '短点 $total 個中 $offending 個が長すぎます（平均：短点の $ratio）';
  }

  @override
  String learnIssueDetailDahTooShort(int offending, int total, String ratio) {
    return '長点 $total 個中 $offending 個が短すぎます（平均：短点の $ratio）';
  }

  @override
  String learnIssueDetailIntraGapTooLong(int offending, int total, String ratio) {
    return '文字内の間隔 $total 個中 $offending 個が長すぎます（平均：短点の $ratio）';
  }

  @override
  String learnIssueDetailCharGapTooShort(int offending, int total, String ratio) {
    return '文字間隔 $total 個中 $offending 個が短すぎます（平均：短点の $ratio）';
  }

  @override
  String learnIssueDetailWordGapTooShort(int offending, int total, String ratio) {
    return '単語間隔 $total 個中 $offending 個が短すぎます（平均：短点の $ratio）';
  }

  @override
  String learnIssueDetailSpeedUnsteady(String cv) {
    return '送信速度が不安定です（変動係数 $cv）';
  }

  @override
  String statsAccuracyDetail(String allTime) {
    return '最近 7 日間 / 全期間 $allTime';
  }

  @override
  String statsDurationHoursMinutes(int hours, int minutes) {
    return '$hours 時間 $minutes 分';
  }

  @override
  String statsDurationMinutes(int minutes) {
    return '$minutes 分';
  }

  @override
  String statsDurationSeconds(int seconds) {
    return '$seconds 秒';
  }

  @override
  String get accountNewPasswordRequired => '新しいパスワードを入力してください';

  @override
  String get accountToxIdQrSemantics => 'Tox ID の QR コード';

  @override
  String get accountBackupSaveDialogTitle => 'DitMesh のバックアップを保存';

  @override
  String get accountBackupShareSubject => 'DitMesh の ID 情報のバックアップ';

  @override
  String get accountBackupChooseDialogTitle => 'DitMesh のバックアップを選択';

  @override
  String notificationNewMessages(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '新しいメッセージ $count 件',
    );
    return '$_temp0';
  }

  @override
  String notificationFriendRequestFrom(String name) {
    return '$name からの友達リクエスト';
  }

  @override
  String notificationFriendRequestBody(String name, String message) {
    return '$name：$message';
  }

  @override
  String notificationGroupInviteTitle(String group) {
    return '$group への招待';
  }

  @override
  String notificationGroupInviteBody(String name) {
    return '$name から招待されました';
  }

  @override
  String desktopTrayShow(String app) {
    return '$app を表示';
  }

  @override
  String desktopTrayHide(String app) {
    return '$app を非表示';
  }

  @override
  String get desktopTraySoundOn => '音を有効にしました';

  @override
  String get desktopTraySoundOff => '音を無効にしました';

  @override
  String desktopTrayQuit(String app) {
    return '$app を終了';
  }

  @override
  String desktopTrayTooltipUnread(String app, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '未読メッセージ $count 件',
    );
    return '$app — $_temp0';
  }

  @override
  String desktopWindowTitleUnread(String badge, String app) {
    return '($badge) $app';
  }

  @override
  String get listenStateOn => 'オン';

  @override
  String get listenStateOff => 'オフ';

  @override
  String chatBytesLeftCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '残り $count バイト',
    );
    return '$_temp0';
  }

  @override
  String chatMemberCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'メンバー $count 人',
    );
    return '$_temp0';
  }

  @override
  String chatFriendsCount(int count) {
    return '友達（$count）';
  }

  @override
  String chatFriendRequestsCount(int count) {
    return '友達リクエスト（$count）';
  }

  @override
  String chatGroupInvitesCount(int count) {
    return 'グループへの招待（$count）';
  }

  @override
  String chatMembersTitleCount(int count) {
    return 'メンバー · $count';
  }

  @override
  String chatInvitedByName(String name) {
    return '$name からの招待';
  }

  @override
  String chatMemberSelf(String name) {
    return '$name（自分）';
  }

  @override
  String chatSliderValue(String label, int value, String unit) {
    return '$label：$value $unit';
  }

  @override
  String referenceTelegraphCodes(String codes) {
    return '中国語電信コード：$codes';
  }

  @override
  String get referenceTelegraphMainland => '中国本土（1983 年版）';

  @override
  String get referenceTelegraphTaiwan => '台湾 / 香港';

  @override
  String get referenceTelegraphNone => 'このコード表にありません';

  @override
  String get appearanceTitle => '外観';

  @override
  String get appearanceStyles => 'インターフェースのスタイル';

  @override
  String get appearanceChoose => 'スタイルを選び、プレビューしてから適用';

  @override
  String get appearanceMode => '明るさ';

  @override
  String get appearancePreview => 'プレビュー';

  @override
  String get appearanceApply => 'スタイルを適用';

  @override
  String get appearanceRestore => '初期設定に戻す';

  @override
  String get appearanceApplied => '外観を保存しました';

  @override
  String get appearanceSaveFailed => '外観を保存できませんでした。再試行してください。';

  @override
  String get appearanceClassic => 'クラシックな真鍮';

  @override
  String get appearanceModern => '落ち着いたモダン';

  @override
  String get appearanceRadio => '夜の無線局';

  @override
  String get appearancePaper => '紙のハンドブック';

  @override
  String get appearanceCartoon => 'さわやかなカートゥーン';

  @override
  String get appearanceLight => 'ライト';

  @override
  String get appearanceDark => 'ダーク';

  @override
  String get appearanceSubtitle => '5 つのスタイルにライト・ダークモードを用意';

  @override
  String get chatClearHistoryBody => 'このデバイスに保存された会話履歴を削除しますか？他のデバイスのコピーには影響しません。この操作は取り消せません。';

  @override
  String get chatLoadEarlier => '以前のメッセージを読み込む';

  @override
  String get chatHistoryLoadFailed => '以前のメッセージを読み込めませんでした。タップして再試行してください。';

  @override
  String get chatRetryHistory => '再試行';

  @override
  String chatNewMessages(int count) {
    return '新しいメッセージ $count 件';
  }

  @override
  String learnShowAllChars(int count) {
    return '全 $count 文字を表示';
  }

  @override
  String get chatSelfMe => '自分';

  @override
  String get chatSelfLocalOnly => 'このデバイスにのみ保存';

  @override
  String get chatSelfContactSubtitle => '下書き、練習、メモ · 送信されません';

  @override
  String get learnShowFewerChars => '文字を折りたたむ';

  @override
  String get learnLeaveDrillTitle => 'このセッションを終了しますか？';

  @override
  String get learnLeaveDrillBody => 'このセッションで行ったラウンドは保存されません。';

  @override
  String get learnLeaveDrillConfirm => '終了';

  @override
  String get chatScanQrPermissionDenied => 'QR コードを読み取るには DitMesh にカメラへのアクセスが必要です。システム設定で許可してください。';

  @override
  String get chatScanQrCameraUnavailable => 'このデバイスではカメラを利用できません。';

  @override
  String get learnReplayAssistedNote => '再生し直しました：練習には数えますが、レッスンの解放や復習の更新は行いません。';

  @override
  String get learnPlanTitle => '今日のプラン';

  @override
  String learnPlanSummary(int minutes, int done, int total) {
    return '約$minutes分 · $totalステップ中$done完了';
  }

  @override
  String get learnPlanBudget => 'プランの長さ';

  @override
  String learnPlanBudgetMinutes(int minutes) {
    return '$minutes分';
  }

  @override
  String get learnPlanStart => 'プランを始める';

  @override
  String get learnPlanContinue => 'プランを続ける';

  @override
  String get learnPlanStepReview => '復習期限の文字';

  @override
  String get learnPlanStepFocus => '重点練習';

  @override
  String learnPlanStepCourse(int lesson) {
    return 'レッスン$lesson';
  }

  @override
  String get learnPlanStepSend => '送信練習';

  @override
  String learnPlanReasonDueReview(String symbols) {
    return '復習時期：$symbols';
  }

  @override
  String learnPlanReasonConfusions(String symbols) {
    return 'よく取り違える：$symbols';
  }

  @override
  String learnPlanReasonWeak(String symbols) {
    return '正答率90%未満：$symbols';
  }

  @override
  String learnPlanReasonChallenge(int count) {
    return '$count文字：次のレッスンを解放できます';
  }

  @override
  String learnPlanReasonExtended(int count) {
    return '次のレッスンを解放できるよう$count文字に延長しました';
  }

  @override
  String get learnPlanReasonConsolidate => '短い練習：このレッスンの定着用で、次は解放されません';

  @override
  String learnPlanReasonOutdated(int lesson) {
    return 'コースが進みました：レッスン$lessonを練習しますが解放はしません';
  }

  @override
  String learnPlanReasonSend(int count) {
    return '短い課題を$count回送信';
  }

  @override
  String learnPlanStepDonePercent(int percent) {
    return '完了 · $percent%';
  }

  @override
  String get learnPlanStepDone => '完了';

  @override
  String learnPlanSendProgress(int done, int total) {
    return '$total中$done送信済み';
  }

  @override
  String get learnPlanStale => 'レッスンまたは速度が変わりました。未開始のステップを更新しますか？';

  @override
  String get learnPlanUpdate => 'ステップを更新';

  @override
  String get learnPlanComplete => '今日のプランは完了です';

  @override
  String learnPlanNeedsWork(String symbols) {
    return '要練習：$symbols';
  }

  @override
  String get learnPlanAllGood => '今日は苦手な文字はありません。';

  @override
  String get learnPlanTomorrow => '明日は新しいプランです。自由練習はいつでもできます。';

  @override
  String learnPlanNext(String step) {
    return '次：$step';
  }

  @override
  String learnPlanEarlier(int done, int total) {
    return '前回のプランは$totalステップ中$doneで止まりました。今日の分には数えません。';
  }

  @override
  String learnSpeedAdviceRaise(int wpm) {
    return '実効速度$wpm WPMに進めます';
  }

  @override
  String learnSpeedAdviceRaiseBoth(int wpm) {
    return '$wpm WPMに進めます';
  }

  @override
  String learnSpeedAdviceLower(int wpm) {
    return 'この速度では受信が難しいようです。実効$wpm WPMか重点練習を試しましょう。';
  }

  @override
  String learnSpeedAdviceBody(int count, int percent) {
    return '直近の補助なし練習$count回（$percent%）に基づきます。適用するまで設定は変わりません。';
  }

  @override
  String get learnSpeedAdviceApply => '適用';

  @override
  String get learnSpeedAdviceDismiss => '今はしない';

  @override
  String get learnSpeedAdviceInsufficient => '速度アドバイスには、現在の速度で50文字以上の補助なし練習が3回必要です。';

  @override
  String get learnQsoAction => 'QSOシミュレーター';

  @override
  String learnQsoLocked(int lesson) {
    return 'レッスン$lessonから';
  }

  @override
  String get learnQsoTitle => 'QSOシミュレーター';

  @override
  String get learnQsoRespond => 'CQに応答する';

  @override
  String get learnQsoRespondHint => '局がCQを出しています。応答してレポートを交換します。';

  @override
  String get learnQsoCall => 'CQを出す';

  @override
  String get learnQsoCallHint => 'あなたがCQを出し、局が応答します。';

  @override
  String get learnQsoYourCall => 'あなたのコールサイン';

  @override
  String get learnQsoYourName => 'あなたの名前';

  @override
  String get learnQsoYourQth => 'あなたのQTH';

  @override
  String get learnQsoInvalidCall => 'BD1XYZのようなコールサインを入力してください';

  @override
  String get learnQsoInvalidWord => '1語、A–Zの文字のみ';

  @override
  String get learnQsoOffline => 'すべてこの端末内で動作し、誰にも送信しません。';

  @override
  String get learnQsoStart => 'QSOを始める';

  @override
  String get learnQsoResume => '途中のQSOを再開';

  @override
  String get learnQsoStageCallCq => '自分のコールサインでCQを出す';

  @override
  String get learnQsoStageCallConfirm => '応答：相手のコール、DE、自分のコール';

  @override
  String get learnQsoStageExchange => 'レポート・名前・QTHを送る';

  @override
  String get learnQsoStageConfirmInfo => '相手の情報を確認する';

  @override
  String get learnQsoStageClosing => '73と<SK>で終える';

  @override
  String get learnQsoStageDone => 'QSO完了';

  @override
  String learnQsoSpeed(int wpm) {
    return '相手は実効$wpm WPMで送信';
  }

  @override
  String learnQsoRemote(String call) {
    return '$callの送信';
  }

  @override
  String get learnQsoRemoteHidden => '耳で受信してください（テキストは非表示）。';

  @override
  String get learnQsoShowText => 'テキストを表示';

  @override
  String get learnQsoListen => '聴く';

  @override
  String get learnQsoAccepted => '受理';

  @override
  String get learnQsoRejected => '不受理';

  @override
  String get learnQsoRemoteSending => '相手局が送信中…';

  @override
  String get learnQsoYourTurn => 'あなたの番です：返信を打鍵して「送信」。';

  @override
  String get learnQsoDecoded => 'あなたの送信内容';

  @override
  String get learnQsoNothingKeyed => 'まだ打鍵していません';

  @override
  String get learnQsoPlayAgain => '再送を頼む（AGN）';

  @override
  String get learnQsoSlower => '減速を頼む（QRS）';

  @override
  String get learnQsoHint => 'ヒント';

  @override
  String learnQsoHintLabel(String example) {
    return '例：$example';
  }

  @override
  String get learnQsoPause => '一時停止';

  @override
  String get learnQsoSend => '送信';

  @override
  String get learnQsoClear => '消去';

  @override
  String get learnQsoIssueEmpty => '何も打鍵されていません。';

  @override
  String get learnQsoIssueMissingCq => 'CQで始めてください。';

  @override
  String get learnQsoIssueMissingDe => 'コールサインの間にDEを入れてください。';

  @override
  String get learnQsoIssueWrongLocalCall => '自分のコールサインがないか誤っています。';

  @override
  String get learnQsoIssueWrongRemoteCall => '相手局のコールサインが違います。';

  @override
  String get learnQsoIssueReversedCalls => '順序が逆です：相手、DE、自分の順です。';

  @override
  String get learnQsoIssueMissingEnding => 'KまたはKNで終えてください。';

  @override
  String get learnQsoIssueMissingRst => 'レポートを送ってください（例：UR RST 599）。';

  @override
  String get learnQsoIssueInvalidRst => 'RSTが範囲外です（R 1–5、S 1–9、T 1–9）。';

  @override
  String get learnQsoIssueMissingName => 'NAMEと名前を送ってください。';

  @override
  String get learnQsoIssueWrongName => 'このQSOでのあなたの名前ではありません。';

  @override
  String get learnQsoIssueMissingQth => 'QTHと場所を送ってください。';

  @override
  String get learnQsoIssueWrongQth => 'このQSOでのあなたのQTHではありません。';

  @override
  String get learnQsoIssueMissingAck => 'RまたはQSLで了解を伝えてください。';

  @override
  String get learnQsoIssueWrongRemoteName => '相手のオペレーター名を確認してください。';

  @override
  String get learnQsoIssueMissing73 => '73を入れてください。';

  @override
  String get learnQsoIssueMissingSk => '<SK>で交信を終えてください。';

  @override
  String learnQsoSummaryFields(int count, int total) {
    return '一度で正解：$totalステップ中$count';
  }

  @override
  String learnQsoSummaryRepeats(int count) {
    return '再送：$count';
  }

  @override
  String learnQsoSummaryHints(int count) {
    return 'ヒント：$count';
  }

  @override
  String learnQsoSummaryRhythm(int wpm) {
    return 'あなたの送信：約$wpm WPM';
  }

  @override
  String get learnQsoSummaryNote => 'QSOの結果は受信正答率とは別に扱い、レッスンは解放しません。';

  @override
  String get messageStatusCancelled => 'キャンセル済み（未送信）';

  @override
  String get chatMessageLearnActions => 'メッセージの操作';

  @override
  String get chatPracticeMessage => 'このメッセージを受信練習';

  @override
  String get chatSaveAsMaterial => '練習素材として保存';

  @override
  String get chatSavedAsMaterial => '「マイ素材」に保存しました';

  @override
  String get chatSaveMaterialFailed => '素材を保存できませんでした。もう一度お試しください。';

  @override
  String get chatListenOnly => '聞き取り専用トレーニング';

  @override
  String get chatListenOnlyHidden => '聞き取り専用：再生して聴いてください';

  @override
  String chatClearHistoryMaterials(int count) {
    return 'このチャットの$count件のメッセージが練習素材として保存されています。コピーは「学習 › マイ素材」で削除するまで残ります。';
  }

  @override
  String get chatPracticeTitle => '受信練習';

  @override
  String chatPracticeUnsupported(String chars) {
    return 'このメッセージにはモールスで打てない文字があります：$chars。練習では省きます。';
  }

  @override
  String chatPracticeTrainableCount(int count) {
    return '$count文字を練習できます。';
  }

  @override
  String get chatPracticeNothingTrainable => 'このメッセージにはモールスで練習できる内容がありません。';

  @override
  String get chatPracticeConfirm => '残りを練習する';

  @override
  String get chatPracticeHint => 'ヒント';

  @override
  String chatPracticeHintShown(String symbols) {
    return 'ヒント：$symbols …';
  }

  @override
  String get chatPracticeAssisted => '補助あり：練習には数えますが、復習や速度アドバイスには使いません。';

  @override
  String chatPracticeErrors(int wrong, int missed, int extra) {
    return '誤り$wrong · 抜け$missed · 余分$extra';
  }

  @override
  String chatPracticeErrorsAction(String symbols) {
    return '間違えた文字を練習：$symbols';
  }

  @override
  String get learnTipDahTooLongTitle => '長点が長すぎる';

  @override
  String learnTipDahTooLong(String ratio) {
    return '長点が長すぎます（短点の約$ratio、目標は3倍）。短点3つ分で離しましょう。';
  }

  @override
  String learnIssueDetailDahTooLong(int offending, int total, String ratio) {
    return '長点$total個中$offending個が長すぎ（平均$ratio短点）';
  }

  @override
  String get learnRhythmTitle => 'リズム';

  @override
  String get learnRhythmMine => '自分のリズム';

  @override
  String get learnRhythmStandard => '標準のリズム（目標速度）';

  @override
  String learnRhythmNormalizedNote(int ms) {
    return '問題は自分の短点（$ms ms）を基準に判断します。遅くても均等なら問題ありません。標準は目標速度です。';
  }

  @override
  String get learnRhythmNotLocated => '打鍵を1文字ずつ対応付けられませんでした。課題全体を練習してください。';

  @override
  String get learnRhythmPlayMine => '自分のを再生';

  @override
  String get learnRhythmPlayStandard => '標準を再生';

  @override
  String learnRhythmPracticePart(int count) {
    return 'これを練習（$count回）';
  }

  @override
  String get learnRhythmPracticeWhole => '課題全体を練習';

  @override
  String get learnRhythmSymbolOk => '良好';

  @override
  String get learnRhythmZoomIn => '拡大';

  @override
  String get learnRhythmZoomOut => '縮小';

  @override
  String get chatSearchMessages => 'メッセージを検索';

  @override
  String get chatSearchHint => 'この会話を検索';

  @override
  String get chatSearchAnyone => '全員';

  @override
  String get chatSearchMe => '自分';

  @override
  String get chatSearchThem => '相手';

  @override
  String get chatSearchAnyDate => '期間指定なし';

  @override
  String chatSearchDateRange(String from, String to) {
    return '$from – $to';
  }

  @override
  String get chatSearchBookmarked => 'ブックマーク';

  @override
  String get chatSearchNoResults => '一致するメッセージはありません。';

  @override
  String get chatSearchMore => 'さらに読み込む';

  @override
  String get chatAddBookmark => 'ブックマーク';

  @override
  String get chatRemoveBookmark => 'ブックマークを解除';

  @override
  String get chatBookmarked => 'ブックマーク済み';

  @override
  String get chatBookmarkFailed => 'ブックマークを保存できませんでした。';

  @override
  String get chatRetrySend => '再送信';

  @override
  String get chatCancelSend => '送信を取り消す';

  @override
  String get chatRetryQueued => '再びキューに入れました。相手がオンラインになると送信します。';

  @override
  String get chatSendCancelled => '取り消しました。メッセージは送信されていません。';

  @override
  String get chatRetryNotNeeded => 'このメッセージはもう失敗状態ではありません。';

  @override
  String get chatCancelTooLate => '取り消せません。メッセージはすでにネットワークに渡され、届く可能性があります。';

  @override
  String get chatSendControlUnavailable => 'このメッセージでは利用できません。';

  @override
  String get chatSendControlFailed => 'うまくいきませんでした。メッセージの状態は変わっていません。もう一度お試しください。';

  @override
  String get workbenchTitle => '録音ワークベンチ';

  @override
  String get workbenchOpen => '録音';

  @override
  String get workbenchImport => '録音を読み込む';

  @override
  String get workbenchEmpty => 'WAV録音を読み込むと、ループ再生・解読・自分での受信練習ができます。マイクは不要です。';

  @override
  String get workbenchFormats => 'WAV（16ビットPCM、モノラル/ステレオ、8/16/44.1/48 kHz）、最大50 MB・20分。';

  @override
  String get workbenchBackupNote => '録音はこの端末に残り、バックアップの書き出し時に含めると選んだ場合を除き、ID のバックアップには入りません。保存した選択範囲のタイトル・メモ・位置は常にバックアップされます。';

  @override
  String workbenchInfo(String rate, String channels, String duration) {
    return '$rate kHz · $channels · $duration';
  }

  @override
  String get workbenchMono => 'モノラル';

  @override
  String get workbenchStereo => 'ステレオ';

  @override
  String get workbenchTruncated => 'ファイルが途中で終わっています。ある分だけ使います。';

  @override
  String get workbenchErrorNotWav => 'WAVファイルではありません。';

  @override
  String get workbenchErrorFormat => '現在は16ビットPCMのWAVのみ対応です（MP3・AAC・浮動小数点WAVは不可）。';

  @override
  String get workbenchErrorChannels => 'モノラルかステレオの録音のみ対応しています。';

  @override
  String get workbenchErrorRate => 'このサンプルレートは非対応です。8・16・44.1・48 kHzを使ってください。';

  @override
  String get workbenchErrorDamaged => 'ファイルが壊れているか不完全です。';

  @override
  String get workbenchErrorTooLarge => 'ファイルが50 MBを超えています。';

  @override
  String get workbenchErrorTooLong => '録音が20分を超えています。';

  @override
  String get workbenchErrorIo => 'ファイルを読み込めませんでした。';

  @override
  String get workbenchErrorMissing => '録音ファイルが見つかりません。';

  @override
  String get workbenchStart => '開始（秒）';

  @override
  String get workbenchEnd => '終了（秒）';

  @override
  String get workbenchSelectAll => 'すべて選択';

  @override
  String get workbenchPlay => '選択範囲を再生';

  @override
  String get workbenchStop => '停止';

  @override
  String get workbenchLoop => 'ループ';

  @override
  String get workbenchPlayLimit => '長い選択範囲は最初の5分だけ再生します。';

  @override
  String get workbenchAutoTune => 'トーンを自動で探す';

  @override
  String workbenchManualTone(int hz) {
    return 'トーン：$hz Hz';
  }

  @override
  String get workbenchDecode => '選択範囲を解読';

  @override
  String get workbenchCancel => 'キャンセル';

  @override
  String workbenchDecoding(int percent) {
    return '解読中… $percent%';
  }

  @override
  String workbenchResultStats(int hz, int wpm) {
    return 'トーン$hz Hz · 約$wpm WPM';
  }

  @override
  String get workbenchToneNotLocked => '安定したトーンが見つかりません。手動で合わせてください。';

  @override
  String get workbenchNoText => 'この範囲では何も解読できませんでした。';

  @override
  String workbenchUnknown(String patterns) {
    return '不明な符号：$patterns';
  }

  @override
  String get workbenchEdgeCut => '選択範囲の端の文字が切れており、誤っている可能性があります。';

  @override
  String get workbenchToneNote => 'トーンの捕捉は信頼度ではありません。耳で確認してください。';

  @override
  String get workbenchModeDecoder => 'デコーダー';

  @override
  String get workbenchModeCopy => '自分で受信する';

  @override
  String get workbenchDecoderHidden => '受信中はデコーダーの文字を隠します。';

  @override
  String get workbenchShowDecoder => 'デコーダーの文字を表示';

  @override
  String get workbenchReference => '正解テキスト（任意）';

  @override
  String get workbenchReferenceHelp => '送信されたテキストを貼り付けてください。なければデコーダーの出力と比較します。';

  @override
  String get workbenchAgainstDecoder => 'デコーダーの出力と比較しました。出力自体が誤っている可能性があります。';

  @override
  String get workbenchSave => '選択範囲を保存';

  @override
  String get workbenchSaveTitle => 'タイトル';

  @override
  String get workbenchSaveNote => 'メモ';

  @override
  String get workbenchSaved => '選択範囲を保存しました';

  @override
  String get workbenchSaveFailed => '選択範囲を保存できませんでした。';

  @override
  String get workbenchLibrary => '保存した区間';

  @override
  String get workbenchLibraryEmpty => '保存した区間はまだありません。';

  @override
  String get workbenchMissing => '録音ファイルがありません。選び直すか項目を削除してください。';

  @override
  String get workbenchRelink => 'ファイルを選び直す';

  @override
  String get workbenchDelete => '削除';

  @override
  String get materialsTitle => 'マイ素材';

  @override
  String get materialsNew => '新しい素材';

  @override
  String get materialsEdit => '編集';

  @override
  String get materialsSave => '保存';

  @override
  String get materialsSaveFailed => '素材を保存できませんでした。';

  @override
  String get materialsTitleField => 'タイトル';

  @override
  String get materialsTagsField => 'タグ（カンマ区切り）';

  @override
  String get materialsTextField => 'テキスト';

  @override
  String get materialsListField => '1行に1項目';

  @override
  String get materialsKindText => 'テキスト';

  @override
  String get materialsKindWords => '単語リスト';

  @override
  String get materialsKindCallsigns => 'コールサイン';

  @override
  String get materialsPreview => 'プレビュー';

  @override
  String materialsPreviewCounts(int items, int symbols, int prosigns) {
    return '$items項目 · $symbols文字 · $prosigns略符号';
  }

  @override
  String materialsPreviewUnsupported(String chars) {
    return 'モールス符号がなく練習で省く文字：$chars';
  }

  @override
  String materialsPreviewDuplicates(int count) {
    return '重複$count件は1つにまとめます';
  }

  @override
  String get materialsProblemEmpty => '先にテキストを入力してください。';

  @override
  String get materialsProblemTooLarge => '大きすぎます（上限1 MiB）。';

  @override
  String materialsProblemTooManyEntries(int count) {
    return '項目が多すぎます（最大$count）。';
  }

  @override
  String materialsProblemEntryTooLong(int count) {
    return '長すぎる項目があります（各$count文字まで）。';
  }

  @override
  String get materialsProblemNothingTrainable => 'モールスで練習できる内容がありません。';

  @override
  String get materialsSearch => '素材を検索';

  @override
  String get materialsFavoritesOnly => 'お気に入り';

  @override
  String get materialsFavorite => 'お気に入りに追加';

  @override
  String get materialsUnfavorite => 'お気に入りから削除';

  @override
  String get materialsEmpty => '素材はまだありません。テキスト・単語リスト・コールサインを追加するか、チャットのメッセージを保存してください。';

  @override
  String materialsItems(int count) {
    return '$count項目';
  }

  @override
  String get materialsFromChat => 'チャットから';

  @override
  String get materialsActions => '素材の操作';

  @override
  String get materialsPractise => '練習';

  @override
  String get materialsDelete => '削除';

  @override
  String get materialsDeleteTitle => '素材を削除しますか？';

  @override
  String materialsDeleteBody(String title) {
    return '「$title」をこの端末から削除します。練習履歴は残ります。';
  }

  @override
  String get materialsImport => 'TXT/JSONを読み込む';

  @override
  String get materialsImportDialogTitle => '素材ファイルを選択';

  @override
  String get materialsSaveDialogTitle => '素材を保存';

  @override
  String get materialsImportFailed => '読み込みに失敗しました。ライブラリは変更されていません。';

  @override
  String get materialsImportNotUtf8 => 'UTF-8のテキストファイルのみ読み込めます。';

  @override
  String get materialsImportInvalid => '有効なDitMesh素材ファイルではありません。何も読み込んでいません。';

  @override
  String materialsImported(int count) {
    return '$count件の素材を読み込みました。';
  }

  @override
  String get materialsDuplicateTitle => '一部の素材はすでにあります';

  @override
  String get materialsDuplicateOverwrite => '置き換える';

  @override
  String get materialsDuplicateKeepCopy => '両方残す（コピーとして）';

  @override
  String get materialsDuplicateSkip => 'スキップ';

  @override
  String get materialsExportJson => 'JSONで書き出す';

  @override
  String materialsExported(int count) {
    return '$count件の素材を書き出しました。';
  }

  @override
  String get materialsExportFailed => '書き出しに失敗しました。';

  @override
  String get materialsExportWav => '音声を書き出す（WAV）';

  @override
  String materialsWavCharSpeed(int wpm) {
    return '文字速度：$wpm WPM';
  }

  @override
  String materialsWavEffSpeed(int wpm) {
    return '実効速度：$wpm WPM';
  }

  @override
  String materialsWavTone(int hz) {
    return '音程：$hz Hz';
  }

  @override
  String get materialsWavWithAnswer => '答えのテキストも付ける（.txt）';

  @override
  String get materialsWavFormat => '16ビット・モノラルWAV、48 kHz。';

  @override
  String materialsWavParts(int count) {
    return '10分を超えるため$count個のファイルに分けて書き出します。';
  }

  @override
  String materialsWavExported(int count) {
    return '音声ファイルを$count個保存しました。';
  }

  @override
  String get materialsPracticeMode => '練習の範囲';

  @override
  String get materialsPracticeLearned => '習得済みの文字のみ';

  @override
  String materialsPracticeLearnedPartial(int count) {
    return '習得済みのみ（$count項目は未習得の文字を含むため使えません）';
  }

  @override
  String get materialsPracticeAll => 'すべてのモールス文字';

  @override
  String get materialsPracticeNothing => 'このモードで練習できる項目はありません。';

  @override
  String get guestTryLearning => 'まず学習を試す';

  @override
  String get guestBanner => 'ゲスト学習：進捗はこの端末に保存されます。チャットには ID が必要です。';

  @override
  String get guestGetIdentity => 'ID を設定';

  @override
  String get guestIdentityTitle => 'ID が必要です';

  @override
  String get guestIdentityBody => 'Tox でのチャットには自分の ID が必要です。新規作成、バックアップから復元、またはこの端末の ID のロック解除を行ってください。新しい ID を作るとゲストの学習進捗は自動で移ります。';

  @override
  String get guestClearData => 'ゲストの学習データを消去';

  @override
  String get guestClearDataBody => 'この端末でゲストとして作った進捗・プラン・素材を削除します。ID には影響しません。';

  @override
  String get guestClearConfirm => '消去';

  @override
  String get guestCleared => 'ゲストの学習データを消去しました。';

  @override
  String get guestClearFailed => 'ゲストデータを消去できませんでした。';

  @override
  String get guestMigrationFailed => 'ID は準備できましたが、ゲストの学習進捗はまだ移っていません。この端末に安全に残っています。';

  @override
  String get guestChoiceBody => 'ゲストの学習進捗もあります。現在は復元した ID の進捗を使用しており、統合はしていません。';

  @override
  String get guestChoiceKeep => '復元した方を使う';

  @override
  String get guestChoiceUseGuest => 'ゲストの進捗を使う';

  @override
  String get placementTitle => 'レベルチェック';

  @override
  String get placementCheckLevel => '今のレベルをチェック';

  @override
  String get placementFromZero => 'ゼロから始める';

  @override
  String get placementOfferTitle => 'モールスは初めて？それとも受信できる？';

  @override
  String get placementOfferBody => '短いチェックで開始位置を提案できます。任意で、選ぶまで何も変わりません。';

  @override
  String get placementIntro => '約3〜5分、5段階で受信します。速度を上げながらコッホ順の文字グループ、最後に短い単語。少ないサンプルによる目安で、認定ではありません。いつでも中止できます。';

  @override
  String get placementStart => '開始';

  @override
  String get placementSkip => 'スキップ';

  @override
  String get placementStop => '中止';

  @override
  String placementTierProgress(int step, int total, int wpm) {
    return '$total段階中$step · 実効 $wpm WPM';
  }

  @override
  String get placementTierPassed => 'よく受信できました。次はもっと速くなります。';

  @override
  String get placementTierStopped => 'この段階は90%未満だったため、ここで終了します。';

  @override
  String get placementNextTier => '次の段階';

  @override
  String placementSuggestion(int lesson) {
    return 'おすすめの開始：レッスン$lesson';
  }

  @override
  String placementVerified(int count, int total) {
    return 'コッホ順の$total文字中$count文字を順に確認しました。';
  }

  @override
  String get placementLimits => '少ないサンプルに基づきます。テストしていない文字は未テストのままで、習得済みにはなりません。レッスンはいつでも変えられます。';

  @override
  String placementAdopt(int lesson) {
    return 'レッスン$lessonから始める';
  }

  @override
  String get chatJumpToLatest => '最新のメッセージ';

  @override
  String get chatMessageGone => 'そのメッセージはこの会話にもうありません。';

  @override
  String get chatListenOnlyPreview => '新着メッセージ — 聴いて受信してください';

  @override
  String get chatSaveMaterialConfirm => '残りを保存';

  @override
  String materialsImportConfirm(int count) {
    return '$count件の素材を読み込みますか？';
  }

  @override
  String get materialsExportTxt => 'テキストで書き出す（TXT）';

  @override
  String get accountBackupMediaTitle => '保存した録音を含めますか？';

  @override
  String accountBackupMediaBody(int count, String size) {
    return '保存した録音 $count 件（$size MB）。タイトル・メモ・位置は常にバックアップに入ります。音声は含めた場合のみです。';
  }

  @override
  String accountBackupMediaTooLarge(String size) {
    return '保存した録音（$size MB）は大きすぎるためバックアップに入れられません。タイトル・メモ・位置のみ含めます。';
  }

  @override
  String get accountBackupMediaInclude => '録音を含める';

  @override
  String get accountBackupMediaSkip => '録音なし';

  @override
  String get diagTitle => '接続の診断';

  @override
  String get diagOpenSubtitle => 'メッセージが待機している理由と再接続の方法';

  @override
  String get diagBannerDetails => '詳細';

  @override
  String get diagSummaryNoIdentity => 'ID が開かれていないため、確認できる接続はありません。';

  @override
  String get diagSummaryOnlinePeerOnline => 'Tox ネットワークに接続済みで、この連絡先もオンラインです。メッセージは直接届きます。';

  @override
  String get diagSummaryOnlinePeerOffline => '接続済みですが、この連絡先はオフラインです。メッセージはこの端末の送信待ちに残り、相手がオンラインになると送信されます。';

  @override
  String get diagSummaryOnline => 'Tox ネットワークに接続しています。';

  @override
  String get diagSummaryConnecting => 'Tox ネットワークに接続中です。起動直後やネットワーク変更後は 1 分ほどかかることがあります。';

  @override
  String get diagSummaryOffline => 'Tox ネットワークに接続していません。接続が戻るまで送受信はできません。';

  @override
  String get diagLocalLabel => 'この端末の接続';

  @override
  String diagSinceChanged(String time) {
    return '$time から';
  }

  @override
  String diagSinceFirst(String time) {
    return '$time から観測';
  }

  @override
  String diagSinceResumed(String time) {
    return '$time にアプリへ戻ってから観測';
  }

  @override
  String get diagLastOnlineLabel => '最後に確認した接続';

  @override
  String get diagLastOnlineNow => '現在接続中';

  @override
  String get diagLastOnlineNone => 'まだ接続を確認していません。';

  @override
  String get diagLastOnlineHint => 'この端末が自分の接続を最後に確認した時刻です。メッセージが相手に届いた時刻ではありません。';

  @override
  String get diagPeerLabel => '連絡先';

  @override
  String get diagUnknown => '不明';

  @override
  String get diagPeerUnknownHint => '連絡先の在席状態は、自分が接続しているときだけ確認できます。';

  @override
  String get diagPeerGroupHint => 'グループメンバーの在席状態はメンバー一覧に表示されます。';

  @override
  String get diagPendingLabel => '送信待ち';

  @override
  String get diagPendingNone => '待機中のメッセージはありません';

  @override
  String diagPendingCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 件のメッセージ',
    );
    return '$_temp0';
  }

  @override
  String diagPendingOldest(String time) {
    return '最も古いもの：$time';
  }

  @override
  String get diagPendingUnknown => 'チャットが接続されるまで不明';

  @override
  String get diagPendingHint => '送信待ちのメッセージはこの端末に保存され、相手に届く状態になると自動で送信されます。診断で削除や再送をすることはありません。';

  @override
  String get diagReconnect => '再接続';

  @override
  String get diagReconnecting => '再接続中…';

  @override
  String diagReconnectFailed(String reason) {
    return '再接続に失敗しました：$reason';
  }

  @override
  String get diagReconnectNote => '再接続は接続の試行をやり直します。オンラインになるまで時間がかかることがあり、そのときはこのページが更新されます。';

  @override
  String get diagAboutTitle => 'DitMesh の接続のしくみ';

  @override
  String get diagAboutBody => 'DitMesh にはサーバーがありません。端末は Tox のピアツーピアネットワークで連絡先と直接通信するため、メッセージが届くには双方が同時にオンラインである必要があります。スマートフォンはバックグラウンドのアプリを一時停止するので、その間 DitMesh は接続を保てず、戻ったときに再接続します。';

  @override
  String get diagDetailsTitle => '技術的な詳細';

  @override
  String get diagDetailIdentity => 'ID';

  @override
  String get diagDetailStatus => '状態';

  @override
  String get diagDetailObserved => '観測時刻';

  @override
  String get diagDetailQueued => 'キューの件数';

  @override
  String get diagDetailError => '最後のエラーコード';

  @override
  String get backupXTitle => '暗号化バックアップ';

  @override
  String get backupXIntro => '別の端末へ持っていく内容を選んでください。ファイル全体が、ここで設定するパスフレーズで暗号化されます。';

  @override
  String get backupXCategoryIdentity => 'ID と Tox プロファイル';

  @override
  String get backupXCategoryTraining => '練習の進捗と教材';

  @override
  String get backupXCategoryChat => 'チャット履歴（自分用メモを含む）';

  @override
  String get backupXCategoryMeta => '下書き・ピン留め・ブックマーク';

  @override
  String get backupXCategoryPrefs => 'アプリの設定';

  @override
  String get backupXPrefsHint => '再生・通知・外観・言語。ウィンドウ位置やキー割り当ては含みません。';

  @override
  String get backupXCategoryMedia => '保存した録音';

  @override
  String get backupXMediaHint => '既定ではオフ：録音は大きくなることがあります。含めない場合はタイトルとメモだけが移ります。';

  @override
  String get backupXCategoryPending => '未送信のメッセージ';

  @override
  String get backupXPendingHint => '確認用として戻るだけで、自動送信されることはありません。';

  @override
  String get backupXRequired => '必須';

  @override
  String backupXSizeLine(int count, String size) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 件',
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
    return '大きすぎて含められません（$size）';
  }

  @override
  String backupXInvitesNote(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'オフラインの友だち宛てに待機中のグループ招待 $count 件は引き継がれません。',
    );
    return '$_temp0';
  }

  @override
  String get backupXIdentityPasswordNote => 'ID のパスワードはプロファイルに残ります。新しい端末ではバックアップのパスフレーズに加えて入力が必要です。';

  @override
  String backupXTotal(String size) {
    return '合計 約 $size';
  }

  @override
  String get backupXPassphrase => 'バックアップのパスフレーズ';

  @override
  String get backupXPassphraseConfirm => 'パスフレーズを再入力';

  @override
  String get backupXPassphraseHint => '8 文字以上。ID のパスワードとは別のもので、再発行はできません。';

  @override
  String get backupXPassphraseTooShort => '8 文字以上にしてください';

  @override
  String get backupXPassphraseMismatch => 'パスフレーズが一致しません';

  @override
  String get backupXExport => '暗号化バックアップを作成';

  @override
  String get backupXExporting => 'バックアップを作成中…';

  @override
  String get backupXMigrationNote => '端末を移行しますか？向こうで復元したら、この端末ではこの ID を使わないでください。同じ ID の端末が 2 台あると、同じメッセージが二重に送られることがあります。';

  @override
  String get backupXBusy => 'バックアップ中にデータが変化し続けました。もう一度お試しください。';

  @override
  String get backupXTooLarge => 'バックアップが大きすぎます。録音を除外してもう一度お試しください。';

  @override
  String get restoreXWrongPassphrase => 'パスフレーズが違うか、ファイルが改変・欠損しています。';

  @override
  String get restoreXUnsupported => 'このバックアップは新しいバージョンの DitMesh で作成されています。';

  @override
  String get restoreXCheck => 'バックアップを開く';

  @override
  String get restoreXPreviewTitle => 'バックアップの内容';

  @override
  String restoreXCreated(String date) {
    return '作成日時 $date';
  }

  @override
  String get restoreXIncluded => '含まれるもの';

  @override
  String get restoreXExcluded => 'このバックアップにないもの';

  @override
  String restoreXPendingIncluded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '未送信のメッセージ $count 件が確認用に戻ります。自動送信はされません。',
    );
    return '$_temp0';
  }

  @override
  String restoreXPendingExcluded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '以前の端末にある未送信のメッセージ $count 件はこのバックアップに含まれていません。',
    );
    return '$_temp0';
  }

  @override
  String get restoreXIdentityPassword => 'ID のパスワード';

  @override
  String get restoreXIdentityPasswordNote => 'このバックアップの ID には独自のパスワードがあります。あわせて入力してください。';

  @override
  String get restoreXConfirmTitle => 'この端末の ID を置き換えますか？';

  @override
  String get restoreXConfirmBody => 'この端末の ID とデータはバックアップで置き換えられます。ここで接続する前に、以前の端末でこの ID を使うのをやめてください。';

  @override
  String get restoreXConfirm => '置き換えて復元';

  @override
  String get restoreXReportTitle => '復元が完了しました';

  @override
  String get restoreXReportRestored => '復元したもの';

  @override
  String get restoreXReportNotIncluded => '復元しなかったもの';

  @override
  String get restoreXReportPrefsFailed => '設定を適用できませんでした。以前の設定のままです。';

  @override
  String restoreXReportPendingReview(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '未送信のメッセージ $count 件がチャットで確認を待っています。',
    );
    return '$_temp0';
  }

  @override
  String restoreXReportPendingNotResumed(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '以前の端末の未送信メッセージ $count 件は引き継がれていません。',
    );
    return '$_temp0';
  }

  @override
  String restoreXReportInvites(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '待機中のグループ招待 $count 件は再送されていません。',
    );
    return '$_temp0';
  }

  @override
  String get restoreXReportStopOld => '以前の端末ではこの ID を使わないでください。';

  @override
  String get restoreXReportDone => '完了';

  @override
  String pendingReviewBanner(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '以前の端末の未送信メッセージ $count 件',
    );
    return '$_temp0';
  }

  @override
  String get pendingReviewTitle => '未送信のメッセージ';

  @override
  String get pendingReviewBody => '以前の端末で送信を待っていたメッセージです。DitMesh が自動で送ることはありません。まだ必要なら打ち直してください。';

  @override
  String pendingReviewQueuedAt(String time) {
    return '以前の端末で $time に送信待ち';
  }

  @override
  String get pendingReviewDismiss => '破棄';

  @override
  String get pendingReviewDismissAll => 'すべて破棄';

  @override
  String get pendingReviewEmpty => '確認するものはもうありません。';

  @override
  String get backupXWizardInside => 'バックアップファイルは自分で決めたパスフレーズでまるごと暗号化され、ID の鍵と練習の進捗を含みます。ファイルとパスフレーズは、この端末以外の安全な場所に保管してください。';

  @override
  String get backupXMeSubtitle => 'ID・チャット・進捗をまとめた暗号化ファイル。保管用にも、別の端末への移行にも';

  @override
  String get conditionsTitle => '受信環境';

  @override
  String get conditionsClear => 'クリア';

  @override
  String get conditionsLight => '軽い混信';

  @override
  String get conditionsRadio => '実戦練習';

  @override
  String get conditionsClearHint => 'きれいで一定の音。通常の練習です。';

  @override
  String get conditionsLightHint => '小さな雑音とゆるやかなフェージング。結果はクリアな練習とは別に記録します。';

  @override
  String get conditionsRadioHint => '雑音、深いフェージング、近くの局、少し不揃いなタイミング。結果はクリアな練習とは別に記録します。';

  @override
  String get conditionsPreview => '試聴';

  @override
  String conditionsActive(String name) {
    return '受信環境：$name';
  }

  @override
  String get conditionsNeedSound => '受信環境は音で聞くものです。練習設定で音をオンにするか、「クリア」で練習してください。';

  @override
  String get conditionsCleanReplay => '効果なしで再生';

  @override
  String conditionsComparable(int count, int accuracy) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'この環境・速度での挑戦 $count 回：平均 $accuracy%',
    );
    return '$_temp0';
  }

  @override
  String get conditionsSeparateNote => '受信環境つきの練習は活動として記録されますが、レッスン・復習スケジュール・速度のおすすめは変わりません。';

  @override
  String get keysTitle => 'キーと外部キーヤー';

  @override
  String get keysMeSubtitle => 'キー割り当て・パドル・USB キーヤーアダプター';

  @override
  String get keysIntro => 'モールスを打つキーを選びます。キーボードとして動作する USB 電鍵・パドルアダプターはキーボードと同じ扱いなので、ここでキーを設定してください。どの機器からのキー入力かはアプリには分からないため、プロファイルはキー割り当ての組み合わせです。';

  @override
  String get keysStandardProfile => '標準';

  @override
  String get keysUnnamed => '名前のないプロファイル';

  @override
  String get keysEdit => '編集';

  @override
  String get keysNewProfile => '新しいプロファイル';

  @override
  String get keysLimitations => 'MIDI・シリアル・Bluetooth のキーヤー、アダプターのファームウェア設定、送信機の制御には対応していません。検証済みのアダプターはドキュメントに記載しています。';

  @override
  String get keysEditTitle => 'キープロファイル';

  @override
  String get keysName => 'プロファイル名';

  @override
  String get keysActionStraight => '縦振り電鍵';

  @override
  String get keysActionDit => '短点パドル';

  @override
  String get keysActionDah => '長点パドル';

  @override
  String get keysPressKey => 'キーを押してください…';

  @override
  String get keysNone => '未設定';

  @override
  String get keysSet => '設定';

  @override
  String keysReserved(String key) {
    return '$key はシステムまたはアプリが使用するため設定できません。別のキーを選んでください。';
  }

  @override
  String keysConflict(String key, String action) {
    return '$key はすでに「$action」に使われています。';
  }

  @override
  String keysConflictSave(String keys) {
    return '1 つのキーに割り当てられる動作は 1 つだけです：$keys が重複しています。';
  }

  @override
  String get keysMissing => 'このキーヤーモードに必要なキーを設定してください（iambic では両方のパドル）。';

  @override
  String get keysSwapPaddles => 'パドルを入れ替える（左利き）';

  @override
  String get keysKeyerMode => 'キーヤーモード';

  @override
  String get keysIambicA => 'Iambic A';

  @override
  String get keysIambicB => 'Iambic B';

  @override
  String get keysAdapterKeyer => 'アダプターが自分で符号を作る';

  @override
  String get keysAdapterKeyerHint => 'キーヤー内蔵のアダプター向け：アダプターが計った押下・解放をそのまま使い、アプリ側で二重に iambic 処理しません。';

  @override
  String get keysAppSidetone => '打鍵時のアプリのサイドトーン';

  @override
  String get keysAppSidetoneHint => 'アダプターがサイドトーンを出す場合はオフにします。解読には影響しません。';

  @override
  String get keysTestTitle => 'テスト';

  @override
  String get keysTestNote => 'テスト専用です。送信も練習記録への追加もされません。';

  @override
  String get keysTestRelease => 'キーを解放';

  @override
  String get keysAdapterActive => 'アダプターのキーヤーを使用中：パドルのキーは縦振り電鍵として扱います。';

  @override
  String keysHintCustom(String keys) {
    return 'キー：$keys';
  }

  @override
  String get telegraphTitle => '中文電碼';

  @override
  String get telegraphIntro => '漢字は 1 文字ずつ 4 桁の番号で送られます。数字を聞き取る練習と、どの番号がどの字かを覚える練習を別々に行います。';

  @override
  String get telegraphCodebook => '電碼本';

  @override
  String get telegraphCodebookMainland => '中国大陸';

  @override
  String get telegraphCodebookTaiwan => '台湾';

  @override
  String get telegraphDigitsTitle => '電碼を聞き取る';

  @override
  String get telegraphDigitsHint => '実在する電碼の 4 桁を聞いて、数字を入力します。';

  @override
  String telegraphDigitsResults(int count, int accuracy) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 回：数字の正答率 $accuracy%',
    );
    return '$_temp0';
  }

  @override
  String get telegraphRecallTitle => '電碼を思い出す';

  @override
  String get telegraphRecallHint => '字から番号、番号から字。モールスの進捗とは別に記録します。';

  @override
  String telegraphRecallResults(int count, int accuracy) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 枚回答：正答率 $accuracy%',
    );
    return '$_temp0';
  }

  @override
  String get telegraphSeparateNote => '電碼の暗記がモールスのレッスン解放や速度のおすすめに影響することはありません。数字の聞き取りは他のモールス受信と同じ扱いです。';

  @override
  String get telegraphRecallCharPrompt => 'この字の電碼を入力';

  @override
  String get telegraphRecallCodePrompt => 'この電碼の字を選ぶ';

  @override
  String get telegraphReveal => '答えを見る';

  @override
  String get telegraphRevealAssisted => '表示済み：このカードは補助ありとして記録します。';

  @override
  String get telegraphCorrect => '正解';

  @override
  String get telegraphIncorrect => '不正解';

  @override
  String telegraphRecallSummary(int correct, int total) {
    return '$total 問中 $correct 問正解';
  }

  @override
  String telegraphRecallAssisted(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '答えを見たカード $count 枚',
    );
    return '$_temp0';
  }

  @override
  String get telegraphInterpretAction => '中文電碼として解釈';

  @override
  String get telegraphInterpretTitle => '電碼の解釈';

  @override
  String get telegraphInterpretNote => 'ここに表示するだけで、メッセージ自体は変わらず、何も送信されません。';

  @override
  String get telegraphUnresolved => '未解決：この番号の字はありません';

  @override
  String get telegraphMalformed => '4 桁のグループではありません';

  @override
  String get telegraphNotCode => '文字列（そのまま）';

  @override
  String get telegraphAmbiguous => 'この番号を共有する字が複数あります';

  @override
  String get groupPracticeTitle => 'グループ練習';

  @override
  String get groupPracticeIntro => '指導役はいつもどおりグループチャットで課題を打電します。各メンバーはここで課題メッセージを選び、自分の速度で聞き取ります。解答と得点はこの端末に残り、グループには何も送信されません。';

  @override
  String get groupPracticeNew => '新しいセッション';

  @override
  String get groupPracticeTitleField => 'タイトル';

  @override
  String get groupPracticeCreate => '作成';

  @override
  String get groupPracticeInstructor => '指導役';

  @override
  String get groupPracticeParticipant => '参加者';

  @override
  String get groupPracticeInstructorHint => '課題をグループチャットで打電し、ここでラウンドとして追加して完了にします。順番はチャットで伝えてください。';

  @override
  String get groupPracticeParticipantHint => '指導役の課題メッセージをラウンドとして追加し、ここで 1 つずつ聞き取ります。';

  @override
  String get groupPracticeLocalNote => 'この端末だけの記録です。ラウンド・役割・結果は他のメンバーと同期されず、受け取り損ねたメッセージが全員に届くとは限りません。';

  @override
  String get groupPracticeAddRound => '課題を追加';

  @override
  String get groupPracticeNoMessages => '最近の履歴に追加できるメッセージがありません。';

  @override
  String get groupPracticeNotConnected => 'チャットが接続されるまでグループの履歴は使えません。';

  @override
  String get groupPracticeRoundOpen => '未実施';

  @override
  String get groupPracticeRoundDone => '完了';

  @override
  String get groupPracticeRoundUnavailable => '利用不可';

  @override
  String get groupPracticeSourceGone => '課題メッセージは履歴にもうありません。';

  @override
  String get groupPracticeSourceLoading => 'メッセージを探しています…';

  @override
  String groupPracticeAttemptResult(int accuracy, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '聞き取り：$accuracy%（$count 回）',
    );
    return '$_temp0';
  }

  @override
  String get groupPracticeCopy => '聞き取る';

  @override
  String get groupPracticeRemoveRound => 'ラウンドを削除';

  @override
  String get groupPracticeSummary => 'まとめ';

  @override
  String groupPracticeRoundsDone(int done, int total) {
    return '$total ラウンド中 $done 完了';
  }

  @override
  String groupPracticeUnavailableCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '利用できないラウンド $count',
    );
    return '$_temp0';
  }

  @override
  String groupPracticeAccuracy(int accuracy) {
    return '聞き取り正答率：$accuracy%';
  }

  @override
  String groupPracticeAssisted(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '補助ありの挑戦 $count 回',
    );
    return '$_temp0';
  }

  @override
  String groupPracticeShareHint(int done, int total, int accuracy) {
    return '共有するなら、結果を自分でグループチャットに打電してください（例：$done/$total $accuracy%）。自動送信はされません。';
  }

  @override
  String get groupPracticeComplete => 'セッションを終了';

  @override
  String get groupPracticeDeleteTitle => 'このセッションを削除しますか？';

  @override
  String get groupPracticeDeleteBody => 'ラウンドとこの端末の結果が削除されます。練習履歴とグループのメッセージは残ります。';

  @override
  String get conditionsAudioFailed => 'この端末では音声を開始できませんでした。「クリア」で練習してください。';

  @override
  String get moderationBlock => 'ブロック';

  @override
  String moderationBlockTitle(String name) {
    return '$name をブロックしますか？';
  }

  @override
  String get moderationBlockFriendBody => '友達から削除され、その人との会話も削除されます。以後、その人のメッセージ、友達リクエスト、グループへの招待はこの端末に表示されません。相手には通知されません。';

  @override
  String get moderationBlockMemberBody => '以後、このグループでのその人のメッセージはこの端末に表示されません。相手には通知されません。Tox ではグループごとにメンバーの鍵が異なるため、このグループにのみ適用されます。';

  @override
  String get moderationBlocked => 'ブロックしました';

  @override
  String get moderationUnblock => 'ブロック解除';

  @override
  String get moderationUnblocked => 'ブロックを解除しました';

  @override
  String get moderationBlockedTitle => 'ブロック中のユーザー';

  @override
  String get moderationBlockedSubtitle => 'メッセージ・リクエスト・招待を非表示';

  @override
  String get moderationBlockedEmpty => 'ブロック中のユーザーはいません。';

  @override
  String get moderationBlockedNote => 'ブロックはこの端末で機能します。Tox には中央サーバーがないため、相手は連絡を試みることはできますが、その内容はここに表示されません。';

  @override
  String get termsGateTitle => 'コミュニティガイドライン';

  @override
  String get termsGateIntro => 'DitMesh のチャットはサーバーを介さず、相手と直接つながります。始める前に、次のルールに同意してください。';

  @override
  String get termsGateRuleZero => '一切容認しません：嫌がらせ、ヘイト、脅迫、未成年者が関わる性的コンテンツ、スパム、違法なもの。';

  @override
  String get termsGateRuleContacts => 'メッセージを送れるのはあなたが承認した人だけです。グループには招待かグループ ID で参加します。';

  @override
  String get termsGateRuleBlock => '会話、グループのメンバー一覧、友達リクエスト、グループへの招待から誰でもブロックできます。';

  @override
  String get termsGateAgree => '同意して続ける';

  @override
  String get termsGateReadFull => '利用規約の全文を読む';

  @override
  String get termsGateSaveFailed => '回答を保存できませんでした。もう一度お試しください。';

  @override
  String get aboutPrivacyPolicy => 'プライバシーポリシー';

  @override
  String get aboutTermsOfUse => '利用規約';

  @override
  String get aboutSupport => 'サポート・お問い合わせ';

  @override
  String get aboutLinkFailed => 'リンクを開けなかったため、コピーしました。';

  @override
  String get errorPeerBlocked => 'この人をブロックしています。先に「自分 → ブロック中のユーザー」で解除してください。';

  @override
  String get offlineClearData => '学習データを消去';

  @override
  String get offlineClearDataBody => 'この端末の進捗、プラン、教材を削除します。';

  @override
  String get offlineCleared => '学習データを消去しました。';

  @override
  String get offlineClearFailed => '学習データを消去できませんでした。';

  @override
  String get learnStorageUnavailable => 'この端末でトレーニングデータを開けませんでした。もう一度お試しください。';

  @override
  String get backendStartupFailedTitle => 'チャットのバックエンドを利用できません';

  @override
  String get backendStartupFailedBody => 'DitMesh は Tox ネットワークのバックエンドを起動できませんでした。ネイティブライブラリがインストールされていることを確認し、再試行してください。';

  @override
  String get bootstrapTitle => 'ネットワークとブートストラップ';

  @override
  String get bootstrapDescription => 'Tox ネットワークに参加するための公開ノードを選択します。';

  @override
  String get bootstrapModeAuto => '自動';

  @override
  String get bootstrapModeManual => '手動';

  @override
  String get bootstrapModeLan => 'LAN ホスト';

  @override
  String get bootstrapAutoDescription => '内蔵ノードから開始し、公式一覧をバックグラウンドで更新します。';

  @override
  String get bootstrapManualDescription => '選択したノードのみ使用します。LAN ノードも入力できます。';

  @override
  String get bootstrapLanDescription => 'このデスクトップで他の LAN 端末用の UDP/DHT ノードを実行します。';

  @override
  String get bootstrapCurrentNode => '現在のノード';

  @override
  String get bootstrapHost => 'ホスト名または IP アドレス';

  @override
  String get bootstrapPort => 'UDP ポート';

  @override
  String get bootstrapPublicKey => 'DHT 公開鍵';

  @override
  String get bootstrapTestNode => 'ノードをテスト';

  @override
  String get bootstrapSaveNode => 'テスト済みノードを使用';

  @override
  String get bootstrapChooseNode => '公開ノードを選択';

  @override
  String get bootstrapReachable => 'DHT 応答を受信';

  @override
  String get bootstrapUnreachable => 'DHT 応答なし';

  @override
  String get bootstrapInvalid => 'ホスト、ポート、公開鍵が無効です';

  @override
  String get bootstrapUdpUnavailable => 'この端末では UDP 検査を実行できません。TCP 接続は未検査です。';

  @override
  String get bootstrapProbeUnavailable => '検査を開始できませんでした。ノードの到達性は不明です。';

  @override
  String get bootstrapFallback => '公式一覧を読み込めないため、内蔵の予備ノードを表示しています。';

  @override
  String get bootstrapMaintainer => '管理者';

  @override
  String get bootstrapLocation => '所在地';

  @override
  String get bootstrapLastPing => '最終公開チェック';

  @override
  String get bootstrapSwitchTitle => 'ブートストラップノードを変更';

  @override
  String get bootstrapSwitchQuestion => 'このノードを使用しますか？';

  @override
  String get bootstrapNotTestedWarning => 'この端末ではまだテストしていないノードです。';

  @override
  String get bootstrapFailedWarning => 'UDP 検査に応答しませんでしたが、このノードを選択できます。';

  @override
  String get bootstrapInconclusiveWarning => '検査結果は不明です。TCP 接続は未検査です。';

  @override
  String get bootstrapSwitchConfirm => 'ノードを使用';

  @override
  String get bootstrapRefresh => '一覧を更新';

  @override
  String get bootstrapStartLan => 'LAN ノードを開始';

  @override
  String get bootstrapStopLan => 'LAN ノードを停止';

  @override
  String get bootstrapLanStopped => 'LAN ノード停止中';

  @override
  String get bootstrapLanRunning => 'LAN ノード実行中';

  @override
  String get bootstrapLanKeyChanges => '再起動すると DHT 鍵が変わります。現在の公開鍵全体を共有してください。';

  @override
  String get bootstrapLanFirewallHint => '他の端末からローカルのファイアウォール経由でこの UDP ポートに到達できる必要があります。';

  @override
  String get bootstrapCopyNode => 'ノード情報をコピー';

  @override
  String get bootstrapShareNode => 'ノード情報を共有';

  @override
  String get bootstrapOperationFailed => 'ネットワーク設定を適用できませんでした。';

  @override
  String get bootstrapServiceUnavailable => 'このバックエンドではネットワーク設定を利用できません。';

  @override
  String get bootstrapSource => '公式公開ノード一覧';

  @override
  String get bootstrapOnline => 'オンライン';

  @override
  String get bootstrapOffline => 'オフライン';

  @override
  String bootstrapProtocolStatus(String udp, String tcp) {
    return 'UDP: $udp · TCP: $tcp';
  }

  @override
  String get errorNotFriend => 'この相手はフレンドリストにいません。メッセージを送るには再度追加してください。';

  @override
  String get chatAcceptWithPassword => 'パスワードを入力して承諾';

  @override
  String chatGroupPasswordTitle(String name) {
    return '$name のパスワード';
  }

  @override
  String get chatGroupPasswordField => 'グループのパスワード';

  @override
  String chatGroupJoinRefusedPassword(String name) {
    return '$name への参加が拒否されました。パスワードが違うか、入力されていません。';
  }

  @override
  String chatGroupJoinRefusedFull(String name) {
    return '$name への参加が拒否されました。グループが満員です。';
  }

  @override
  String chatGroupJoinRefused(String name) {
    return '$name への参加が拒否されました。';
  }

  @override
  String chatGroupReconnectRefused(String name) {
    return '$name への再接続が拒否されました。履歴は保持されています。グループのパスワードで再試行してください。';
  }
}
