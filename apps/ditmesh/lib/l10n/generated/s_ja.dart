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
  String get messageStatusPending => 'この端末で送信待ち';

  @override
  String get messageStatusPendingDetail => 'メッセージは端末に保存されています。双方のアプリが起動し、接続できると送信されます。';

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
  String statsDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 日',
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
  String get meNoteBackgroundTitle => 'スマートフォンでの受信';

  @override
  String get meNoteBackgroundBody => 'DitMesh はプッシュサーバーのないピアツーピアのアプリなので、メッセージを受け取るには開いたままにしてください。バックグラウンドではまもなく端末が DitMesh を一時停止します。その間に送られたメッセージは相手の画面で送信済みと表示されることがあり、DitMesh を再び開くと届きます。';

  @override
  String get meNoteScreenReaderTitle => 'スクリーンリーダーと打鍵';

  @override
  String get meNoteScreenReaderBody => 'スクリーンリーダーでは、縦振れ電鍵を押す長さで短点と長点を打つことはできません。チャットでは電鍵の「短点」「長点」アクションを使うか、パドルを 1 回操作するごとに 1 符号ずつ打つか、物理キーボードで打鍵してください。';

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
  String get learnContinueLesson => 'レッスンを続ける';

  @override
  String get learnSettings => '練習設定';

  @override
  String get learnLoading => '学習の進捗を読み込み中…';

  @override
  String get learnIdentityRequired => '練習を始めるには ID 情報を作成するか、ロックを解除してください。進捗は ID 情報と一緒に保存され、バックアップにも含まれます。';

  @override
  String get learnProgressSaveFailed => '進捗を保存できませんでした。DitMesh を閉じるまでは今回の結果が有効です。';

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
  String get learnListen => '再生中';

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
  String get learnKeyerStraight => '縦振れ電鍵';

  @override
  String get learnKeyerIambicA => 'アイアンビック A';

  @override
  String get learnKeyerIambicB => 'アイアンビック B';

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
  String get chatSelfMe => '自分';

  @override
  String get chatSelfLocalOnly => 'このデバイスにのみ保存';

  @override
  String get chatSelfContactSubtitle => '下書き、練習、メモ · 送信されません';

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
  String learnPlanNext(String step) {
    return '次：$step';
  }

  @override
  String get messageStatusCancelled => 'キャンセル済み（未送信）';

  @override
  String get chatMessageLearnActions => 'メッセージの操作';

  @override
  String get chatPracticeMessage => 'このメッセージを受信練習';

  @override
  String get chatListenOnly => '聞き取り専用トレーニング';

  @override
  String get chatListenOnlyHidden => '聞き取り専用：再生して聴いてください';

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
  String get chatJumpToLatest => '最新のメッセージ';

  @override
  String get chatMessageGone => 'そのメッセージはこの会話にもうありません。';

  @override
  String get chatListenOnlyPreview => '新着メッセージ — 聴いて受信してください';

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
  String get telegraphCodebook => '電碼本';

  @override
  String get telegraphCodebookMainland => '中国大陸';

  @override
  String get telegraphCodebookTaiwan => '台湾';

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

  @override
  String get firstChatTitle => '初めてのモールスチャット';

  @override
  String get firstChatStart => '始める';

  @override
  String get firstChatDismiss => 'ガイドを閉じる';

  @override
  String get firstChatKeyTitle => '1. 自分に CQ を送る';

  @override
  String get firstChatKeyBody => '電鍵で CQ を打ちます。短押しは短点、長押しは長点です。解読された下書きは読み取り専用です。';

  @override
  String get firstChatSelf => '自分宛てのチャットで試す';

  @override
  String get firstChatListenTitle => '2. 聞いて修正する';

  @override
  String get firstChatListenBody => '送信前に試聴で下書きを聞き、削除で誤りを直します。送信後はメッセージの再生を押します。自分宛てのメッセージは端末内に保存されます。';

  @override
  String get firstChatFriendTitle => '3. 友達とチャットする';

  @override
  String get firstChatFriendBody => '連絡先で QR コードまたは Tox ID から友達を追加し、申請の承認を待ちます。';

  @override
  String get firstChatFriend => '友達を追加';

  @override
  String get firstChatOnline => '送達には双方のアプリが起動し、接続されている必要があります。';

  @override
  String get pendingMessagesTitle => '送信待ちと失敗したメッセージ';

  @override
  String get pendingMessagesExplanation => '送信待ちのメッセージは端末に保存され、双方の接続後に送信されます。取り消しや失敗後の再試行ができます。';

  @override
  String get pendingMessagesEmpty => '送信待ちや失敗したメッセージはありません';

  @override
  String get deliveryDetailsTitle => '配信の詳細';

  @override
  String get deliveryLocalTitle => '端末に保存済み';

  @override
  String get deliveryLocalDetail => 'この自分宛てのメッセージは端末に保存されています。';

  @override
  String get deliverySentDetail => 'アプリから転送処理に渡されました。相手の受信確認を待っています。';

  @override
  String get deliveryPeerTitle => '相手が受信済み';

  @override
  String get deliveryPeerDetail => '相手の受信が確認されました。閲覧や再生の確認ではありません。';

  @override
  String get deliveryGroupTitle => 'グループメンバーが受信済み';

  @override
  String get deliveryGroupDetail => '少なくとも一人の受信が確認されました。他のメンバーはオフラインの場合があります。';

  @override
  String get deliveryLocalOffline => 'この端末はまだ接続されていません。';

  @override
  String get deliveryPeerOffline => '友達はオフラインです。';

  @override
  String get deliveryGroupWaiting => 'グループへの接続を待っています。';

  @override
  String get chatPreviewDraft => '下書きを試聴';

  @override
  String get chatStopPreview => '試聴を停止';

  @override
  String get chatMessagePlayback => 'メッセージ再生';

  @override
  String get chatOriginalRhythm => '元の送信リズム';

  @override
  String get chatListenerRhythm => '自分の再生速度';

  @override
  String get chatOriginalAvailable => '実際の打鍵と間隔を記録しています。';

  @override
  String get chatOriginalUnavailable => '元のリズムがないため、自分の速度で再生します。';

  @override
  String get chatOriginalPlaying => '元のリズムで再生中';

  @override
  String get chatListenerPlaying => '自分の速度で再生中';

  @override
  String get chatPause => '一時停止';

  @override
  String get chatResume => '再開';

  @override
  String get chatPreviousWord => '前の単語';

  @override
  String get chatNextWord => '次の単語';

  @override
  String chatWordNumber(int number) {
    return '単語 $number';
  }

  @override
  String get chatRangeStart => '開始単語';

  @override
  String get chatRangeEnd => '終了単語';

  @override
  String get chatRepeatRange => '選択した単語を再生';

  @override
  String get chatLoopRange => '選択した単語をループ';

  @override
  String get chatPlaybackProgress => '再生の進行状況';

  @override
  String chatWordProgress(int current, int total) {
    return '単語 $current / $total';
  }

  @override
  String get chatOriginalPreference => '対応する記録がある場合は元の送信リズムを使います。';

  @override
  String chatConversationActions(String name) {
    return '$name の操作';
  }

  @override
  String get chatDraftSaveFailed => '下書きを保存できませんでした。この画面を開いたままにするか、今すぐ送信してください。';

  @override
  String get chatSearchClearDates => '期間をクリア';

  @override
  String chatGroupReconnectFailed(String name) {
    return '$name への再接続が拒否されました。履歴は保持されています。再試行できます。';
  }
}
