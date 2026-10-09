// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 's.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class SZh extends S {
  SZh([String locale = 'zh']) : super(locale);

  @override
  String get appName => 'DitMesh';

  @override
  String get navLearn => '学习';

  @override
  String get navChat => '聊天';

  @override
  String get navGroups => '群组';

  @override
  String get navMe => '我';

  @override
  String get navReference => '参考';

  @override
  String get navLearnDescription => 'Koch 课程、发报练习与听抄练习。';

  @override
  String get navChatDescription => '基于 Tox P2P 的无服务器一对一莫尔斯通联。';

  @override
  String get navGroupsDescription => '群组网络 — 多位报务员在同一共享频道上拍发。';

  @override
  String get navReferenceDescription => '字母表、规程符号、Q 简语、缩写，以及双向翻译器。';

  @override
  String get navMeDescription => '你的呼号、Tox 身份、进度与设置。';

  @override
  String get shellOfflineBanner => '离线：未连接到 Tox 网络。消息将在你恢复在线后发送。';

  @override
  String get actionOk => '确定';

  @override
  String get actionCancel => '取消';

  @override
  String get actionSave => '保存';

  @override
  String get actionDelete => '删除';

  @override
  String get actionCopy => '复制';

  @override
  String get actionShare => '分享';

  @override
  String get actionRetry => '重试';

  @override
  String get actionClose => '关闭';

  @override
  String get actionSearch => '搜索';

  @override
  String get actionSettings => '设置';

  @override
  String get connectionConnecting => '连接中…';

  @override
  String get connectionOnline => '在线';

  @override
  String get connectionOffline => '离线';

  @override
  String get messageStatusPending => '已在本机排队';

  @override
  String get messageStatusPendingDetail => '消息已保存在本机，双方应用同时运行且网络可达时会继续发送。';

  @override
  String get messageStatusSending => '发送中';

  @override
  String get messageStatusSent => '已发送';

  @override
  String get messageStatusFailed => '发送失败';

  @override
  String get errorWrongPassword => '密码错误，请重试。';

  @override
  String get errorPeerOffline => '该好友离线。Tox 没有服务器，消息会等到对方上线后再送达。';

  @override
  String get errorInvalidToxId => '这不是有效的 Tox ID（应为 76 位十六进制字符）。';

  @override
  String get errorAlreadyFriend => '这个 Tox ID 已在你的好友列表中。';

  @override
  String get errorOwnId => '这是你自己的 Tox ID。';

  @override
  String get errorGroupNotFound => '未找到该群组。';

  @override
  String get errorMessageTooLong => '消息超出单条 Tox 消息的长度上限。';

  @override
  String get errorUnknown => '出了点问题';

  @override
  String get errorTeardownUnconfirmed => '上一个 Tox 会话尚未完全停止。请稍后重试，或重启应用。';

  @override
  String get errorIdentityRecoveryPending => '上一个身份仍在等待恢复。请重启应用重试，或删除身份数据后重新开始。';

  @override
  String get languageTitle => '语言';

  @override
  String get languageSystemDefault => '跟随系统';

  @override
  String get languageSaveFailed => '无法保存语言设置，请重试。';

  @override
  String learnLessonOf(int lesson, int total) {
    return '第 $lesson 课 / 共 $total 课';
  }

  @override
  String learnCharsLearned(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '已学 $count 个字符',
    );
    return '$_temp0';
  }

  @override
  String learnDailyGoalProgress(int done, int goal) {
    return '$done / $goal 字符';
  }

  @override
  String learnStreakDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '连续练习 $days 天',
    );
    return '$_temp0';
  }

  @override
  String learnReviewDueCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 个待复习',
      zero: '暂无待复习',
    );
    return '$_temp0';
  }

  @override
  String learnRoundScore(int correct, int total) {
    return '$total 个中抄对 $correct 个';
  }

  @override
  String learnRoundOf(int round) {
    return '第 $round 轮';
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
      other: '已发 $count 个字符',
    );
    return '$_temp0';
  }

  @override
  String learnLessonUnlocked(String char) {
    return '已解锁新字符：$char';
  }

  @override
  String learnConfusedMissed(String target) {
    return '$target 漏抄';
  }

  @override
  String learnConfusedAs(String target, String answered) {
    return '$target 听成了 $answered';
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
      other: '$count 个字符',
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
      other: '已学 $count 个字符',
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
      other: '抄收 $count 个字符',
    );
    return '$_temp0';
  }

  @override
  String statsSessions(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 次练习',
    );
    return '$_temp0';
  }

  @override
  String statsDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 天',
    );
    return '$_temp0';
  }

  @override
  String statsBestStreak(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '最长连续 $count 天',
    );
    return '$_temp0';
  }

  @override
  String statsGoalProgress(int done, int goal) {
    return '$done / $goal 字符';
  }

  @override
  String statsGoalRemaining(int remaining) {
    String _temp0 = intl.Intl.pluralLogic(
      remaining,
      locale: localeName,
      other: '还差 $remaining 个字符',
    );
    return '$_temp0';
  }

  @override
  String statsTrendSubtitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '最近 $count 次练习',
      one: '最近一次练习',
    );
    return '$_temp0';
  }

  @override
  String statsTooltipSession(int index, int total) {
    return '第 $index 次练习 / 共 $total 次';
  }

  @override
  String statsTooltipCopied(int correct, int total) {
    return '$correct / $total 正确';
  }

  @override
  String statsTooltipLesson(int lesson) {
    return '第 $lesson 课';
  }

  @override
  String statsAttempts(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 次尝试',
    );
    return '$_temp0';
  }

  @override
  String statsCorrectOf(int correct, int attempts) {
    return '$attempts 次中对 $correct 次';
  }

  @override
  String statsLessonIntroduced(int lesson) {
    return '在第 $lesson 课引入';
  }

  @override
  String statsSrsBox(int box, int maxBox) {
    return '第 $box 盒 / 共 $maxBox 盒';
  }

  @override
  String statsSrsDueIn(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days 天后到期',
      one: '明天到期',
    );
    return '$_temp0';
  }

  @override
  String statsTimes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 次',
    );
    return '$_temp0';
  }

  @override
  String statsHeatmapCell(String target, String answered, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 次',
    );
    return '$target 被答成 $answered，$_temp0';
  }

  @override
  String statsCalendarDay(String date, int chars) {
    String _temp0 = intl.Intl.pluralLogic(
      chars,
      locale: localeName,
      other: '$chars 个字符',
      zero: '未练习',
    );
    return '$date：$_temp0';
  }

  @override
  String statsActiveDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 个活跃日',
    );
    return '$_temp0';
  }

  @override
  String referenceEntryCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 条',
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
    return '已跳过（无莫尔斯电码）：$chars';
  }

  @override
  String referenceKochPositionValue(int position) {
    return 'Koch 序号：$position';
  }

  @override
  String referenceEstimatedSpeed(String wpm) {
    return '估计 $wpm WPM';
  }

  @override
  String get accountCopied => 'Tox ID 已复制到剪贴板';

  @override
  String get accountShowQr => '显示二维码';

  @override
  String get accountToxId => 'Tox ID';

  @override
  String get accountDisplayName => '显示名称';

  @override
  String get accountDisplayNameHint => '你的呼号或昵称';

  @override
  String get accountDisplayNameRequired => '请输入显示名称';

  @override
  String get accountStatusMessage => '状态消息';

  @override
  String get accountPassword => '密码';

  @override
  String get accountPasswordOptional => '密码（可选）';

  @override
  String get accountConfirmPassword => '确认密码';

  @override
  String get accountPasswordsDoNotMatch => '两次输入的密码不一致';

  @override
  String get accountShowPassword => '显示密码';

  @override
  String get accountHidePassword => '隐藏密码';

  @override
  String get accountStrengthWeak => '弱：至少使用 8 个字符';

  @override
  String get accountStrengthFair => '一般：12 个以上字符并混合多种类型更好';

  @override
  String get accountStrengthStrong => '强';

  @override
  String get accountStartupInspecting => '正在检查你的身份…';

  @override
  String get accountStartupOpening => '正在打开你的身份…';

  @override
  String get accountStartupFailedTitle => '无法启动';

  @override
  String get accountStartupFailedBody => 'DitMesh 无法读取你的身份。没有做任何更改；你可以重试。';

  @override
  String get accountConnectionTapToReconnect => '点按重新连接';

  @override
  String get accountWelcomeTitle => '你的身份只保存在这台设备上';

  @override
  String get accountWelcomeIntro => 'DitMesh 使用 Tox 点对点网络。没有服务器，也无需注册账号：你的身份是一对只保存在本机的密钥。';

  @override
  String get accountWelcomePointNoServer => '没有服务器，不需要手机号或电子邮件。报务员之间直接用莫尔斯电码通联。';

  @override
  String get accountWelcomePointTraining => '使用直键或双桨键拍发 Morse code，进行单聊和群聊。';

  @override
  String get accountWelcomePointBackup => '没有人能为你找回身份。创建后请立即备份，否则设备丢失时身份也会一起丢失。';

  @override
  String get accountCreateIdentity => '创建身份';

  @override
  String get accountRestoreFromBackup => '从备份恢复';

  @override
  String get accountCreateTitle => '创建你的身份';

  @override
  String get accountCreateBody => '取一个别人能看到的名字。密码用于加密本机上的身份文件；如果你希望不输密码就能打开应用，可以留空。';

  @override
  String get accountCreateButton => '创建';

  @override
  String get accountCreating => '创建中…';

  @override
  String get accountBackupTitle => '现在就备份你的身份';

  @override
  String get accountBackupBody => '你的身份只存在于这台设备上。如果设备丢失、重置或被盗，将无法找回：好友不会认出新的身份，训练进度也会丢失。';

  @override
  String get accountBackupWhatIsInside => '备份文件包含用密码加密的身份密钥和你的训练进度。请把它保存在本机以外的安全位置。';

  @override
  String get accountBackupWhatIsInsidePlain => '备份文件包含未加密的身份密钥和你的训练进度。拿到这个文件的人都能使用你的身份：如需加密密钥，请先设置密码，并把文件保存在安全位置。';

  @override
  String get accountPasswordScope => '密码用于加密你的身份密钥。消息记录在磁盘上仍未加密，可借助设备加密来保护。';

  @override
  String get accountSectionNotifications => '通知';

  @override
  String get accountNotificationsEnable => '显示通知';

  @override
  String get accountNotificationsEnableSubtitle => '新消息、好友请求和群组邀请';

  @override
  String get accountNotificationsContent => '显示消息内容';

  @override
  String get accountNotificationsContentSubtitle => '在横幅和锁屏上显示文字和摩尔斯码。关闭后只提示收到了消息。';

  @override
  String get accountNotificationsAllow => '允许通知';

  @override
  String get accountNotificationsAllowSubtitle => '向系统请求通知权限';

  @override
  String get accountNotificationsBlocked => '已在系统设置中屏蔽';

  @override
  String get accountNotificationsBlockedSubtitle => 'DitMesh 的消息通知已在系统设置中关闭。请在系统设置中重新开启。';

  @override
  String get accountNotificationsDenied => 'DitMesh 的通知已在系统设置中关闭。';

  @override
  String get accountBackupSaveFile => '保存备份文件';

  @override
  String get accountBackupShareFile => '分享备份文件';

  @override
  String get accountBackupSaved => '备份已保存';

  @override
  String get accountBackupNotSaved => '备份未保存';

  @override
  String get accountBackupFailed => '无法写入备份';

  @override
  String get accountBackupAcknowledge => '我了解：没有这份备份，我的身份将无法找回。';

  @override
  String get accountBackupContinue => '进入 DitMesh';

  @override
  String get accountBackupShowQrHint => '朋友通过你的 Tox ID 添加你。可以以文本或二维码的形式分享。';

  @override
  String get accountRestoreTitle => '从备份恢复';

  @override
  String get accountRestoreBody => '选择一个由 DitMesh 导出的备份文件。如果该身份设置了密码，这里需要输入。';

  @override
  String get accountRestoreChooseFile => '选择备份文件';

  @override
  String get accountRestoreNoFile => '请先选择备份文件';

  @override
  String get accountRestoreButton => '恢复';

  @override
  String get accountRestoring => '恢复中…';

  @override
  String get accountRestoreInvalidFile => '这个文件不是 DitMesh 备份。';

  @override
  String get accountRestoreReplacesWarning => '恢复将替换当前设备上的身份。';

  @override
  String get accountUnlockTitle => '解锁你的身份';

  @override
  String get accountUnlockBody => '你的身份文件已加密。请输入密码继续。';

  @override
  String get accountUnlockButton => '解锁';

  @override
  String get accountUnlocking => '解锁中…';

  @override
  String get accountUnlockRestoreInstead => '改为从备份恢复';

  @override
  String get accountMeNoIdentity => '未加载身份';

  @override
  String get accountSectionAccount => '账户';

  @override
  String get accountSectionTraining => '训练';

  @override
  String get accountSectionAbout => '关于';

  @override
  String get accountSectionDanger => '危险操作';

  @override
  String get accountEditProfile => '编辑资料';

  @override
  String get accountEditProfileBody => '会显示给 Tox 网络上的好友。';

  @override
  String get accountSetPassword => '设置密码';

  @override
  String get accountChangePassword => '修改密码';

  @override
  String get accountRemovePassword => '移除密码';

  @override
  String get accountCurrentPassword => '当前密码';

  @override
  String get accountNewPassword => '新密码';

  @override
  String get accountPasswordUpdated => '密码已更新';

  @override
  String get accountPasswordRemoved => '密码已移除';

  @override
  String get accountProfileUpdated => '资料已更新';

  @override
  String get accountExportBackup => '导出备份';

  @override
  String get accountExportBackupSubtitle => '把你的身份和训练进度保存到文件';

  @override
  String get accountTrainingDefaults => '播放与训练默认值';

  @override
  String get accountTrainingDefaultsSubtitle => '速度、音调、Farnsworth 间距';

  @override
  String get accountTrainingDefaultsPlaceholder => '速度、音调和 Farnsworth 默认值将放在这里。';

  @override
  String get accountAboutLicence => '许可证';

  @override
  String get accountAboutLicenceValue => 'GPL-3.0';

  @override
  String get accountAboutSource => '源代码';

  @override
  String get accountAboutSourceCopied => '源代码链接已复制';

  @override
  String get accountAboutBackend => '后端';

  @override
  String get accountDeleteIdentity => '删除身份';

  @override
  String get accountDeleteIdentitySubtitle => '从本机抹除这个身份、聊天记录和训练进度';

  @override
  String get accountDeleteDialogTitle => '删除这个身份？';

  @override
  String get accountDeleteDialogBody => '这会从本机删除你的身份、聊天记录和训练进度。没有备份将无法找回。输入 DELETE 以确认。';

  @override
  String get accountDeleteConfirmWord => 'DELETE';

  @override
  String get accountDeleteConfirmHint => '输入 DELETE';

  @override
  String get accountDeleteButton => '删除';

  @override
  String get accountRecoveryPendingDiscard => '丢弃等待恢复的身份并重新开始';

  @override
  String accountRestoreFileChosenSize(int bytes) {
    return '已选择备份文件（$bytes 字节）';
  }

  @override
  String get chatSearchConversations => '搜索会话';

  @override
  String get chatNoConversations => '还没有会话';

  @override
  String get chatNoSearchResults => '没有匹配的会话';

  @override
  String get chatPin => '置顶';

  @override
  String get chatUnpin => '取消置顶';

  @override
  String get chatMarkRead => '标为已读';

  @override
  String get chatDelete => '删除';

  @override
  String get chatDeleteConversationTitle => '删除会话？';

  @override
  String get chatDeleteConversationBody => '将删除本机上这个会话的历史记录。Tox 不保留副本。';

  @override
  String get chatDraftPrefix => '草稿：';

  @override
  String get chatSelectConversation => '选择一个会话';

  @override
  String get chatContacts => '联系人';

  @override
  String get chatNoMessages => '还没有消息 — 呼叫 CQ 开始通联。';

  @override
  String get chatTrainingMode => '训练模式';

  @override
  String get chatTrainingModeOn => '训练模式已开：隐藏文本';

  @override
  String get chatTrainingModeOff => '训练模式已关';

  @override
  String get chatAutoPlay => '自动播放收到的电码';

  @override
  String get chatAutoPlayOn => '自动播放已开：新消息到达即播放';

  @override
  String get chatAutoPlayOff => '自动播放已关';

  @override
  String get chatReveal => '显示';

  @override
  String get chatHiddenText => '先听，再显示';

  @override
  String get chatPlay => '播放莫尔斯';

  @override
  String get chatStop => '停止';

  @override
  String get chatPlaybackSettings => '播放设置';

  @override
  String get chatCharacterSpeed => '字符速度';

  @override
  String get chatFarnsworthSpeed => 'Farnsworth 速度';

  @override
  String get chatTone => '音调';

  @override
  String get chatWpm => 'WPM';

  @override
  String get chatHz => 'Hz';

  @override
  String get chatMembers => '成员';

  @override
  String get chatLeaveGroup => '退出群组';

  @override
  String get chatLeaveGroupTitle => '退出这个群组？';

  @override
  String get chatLeaveGroupBody => '你将不再收到消息。之后可凭 chat id 重新加入。';

  @override
  String get chatLeave => '退出';

  @override
  String get chatConferenceNote => '旧式会议群：此处无法使用莫尔斯键控元数据（v2）。文本仍然可用。';

  @override
  String get chatClearHistory => '清空历史记录';

  @override
  String get chatModeStraightKey => '直键';

  @override
  String get chatModePaddles => '双桨';

  @override
  String get chatKeyMessage => '用电键拍发消息';

  @override
  String get chatSend => '发送';

  @override
  String get chatTooLong => '超出单条 Tox 消息的长度上限';

  @override
  String get chatKeyHint => '在电键区按键，或按空格';

  @override
  String get chatPaddleHint => '点按双桨，或按住 Ctrl（左 点，右 划）';

  @override
  String get chatDeleteLast => '删除最后一个字符';

  @override
  String get chatNoFriends => '还没有好友。用对方的 Tox ID 添加一位。';

  @override
  String get chatNoRequests => '没有待处理的请求';

  @override
  String get chatAddFriend => '添加好友';

  @override
  String get chatMyToxId => '我的 Tox ID';

  @override
  String get chatToxIdLabel => 'Tox ID（76 位十六进制字符）';

  @override
  String get chatToxIdInvalid => 'Tox ID 必须正好是 76 位十六进制字符';

  @override
  String get chatToxIdOwn => '这是你自己的 Tox ID';

  @override
  String get chatToxIdAlreadyFriend => '已在你的好友列表中';

  @override
  String get chatRequestMessage => '附言';

  @override
  String get chatDefaultRequestMessage => 'DitMesh CQ';

  @override
  String get chatSendRequest => '发送请求';

  @override
  String get chatRequestSent => '好友请求已发送';

  @override
  String get chatScanQr => '扫描二维码';

  @override
  String get chatScanQrDesktopHint => '扫描二维码需要手机摄像头';

  @override
  String get chatScanQrTitle => '扫描 Tox ID';

  @override
  String get chatScanQrNotToxId => '这个二维码不是 Tox ID';

  @override
  String get chatAccept => '接受';

  @override
  String get chatReject => '拒绝';

  @override
  String get chatCopied => '已复制到剪贴板';

  @override
  String get chatNoIdentity => '未加载身份';

  @override
  String get chatRemoveFriend => '删除好友';

  @override
  String get chatRemoveFriendTitle => '删除这位好友？';

  @override
  String get chatRemoveFriendBody => '对方将无法再给你发消息。';

  @override
  String get chatRemove => '删除';

  @override
  String get chatNoGroups => '还没有群组。创建一个，或凭 chat id 加入。';

  @override
  String get chatCreateGroup => '创建群组';

  @override
  String get chatJoinGroup => '加入群组';

  @override
  String get chatGroupName => '群组名称';

  @override
  String get chatGroupNameRequired => '请给群组取个名字';

  @override
  String get chatAdvanced => '高级';

  @override
  String get chatLegacyConference => '旧式会议群（兼容旧客户端）';

  @override
  String get chatLegacyConferenceHint => '不推荐：没有固定 chat id，也没有莫尔斯元数据。';

  @override
  String get chatCreate => '创建';

  @override
  String get chatChatIdLabel => 'Chat id（64 位十六进制字符）';

  @override
  String get chatChatIdInvalid => 'Chat id 必须正好是 64 位十六进制字符';

  @override
  String get chatPassword => '密码（可选）';

  @override
  String get chatJoin => '加入';

  @override
  String get chatJoinRequested => '加入中 — 找到一位成员后群组就会出现。';

  @override
  String get chatConferenceBadge => '会议群';

  @override
  String get chatCopyChatId => '复制 chat id';

  @override
  String get learnLessonCardTitle => 'Koch 课程';

  @override
  String get learnCourseComplete => '课程已完成 - 继续磨练！';

  @override
  String get learnDailyGoalTitle => '今天';

  @override
  String get learnDailyGoalMet => '已达成每日目标';

  @override
  String get learnNoStreak => '从今天开始连续练习';

  @override
  String get learnContinueLesson => '继续课程';

  @override
  String get learnReceivePractice => '听抄练习';

  @override
  String get learnSendPractice => '发报练习';

  @override
  String get learnReviewDue => '复习到期字符';

  @override
  String get learnSettings => '训练设置';

  @override
  String get learnLoading => '正在加载你的进度...';

  @override
  String get learnIdentityRequired => '创建或解锁身份后即可开始训练。进度随身份保存，会一同进入备份。';

  @override
  String get learnLoadFailed => '无法读取已保存的进度。将从头开始；旧文件已保留为 .corrupt。';

  @override
  String get learnProgressSaveFailed => '无法保存进度。在 DitMesh 关闭前，本次成绩仍然有效。';

  @override
  String get learnChooseDrill => '选择一种练习';

  @override
  String get learnDrillGroups => '随机字组';

  @override
  String get learnDrillWords => '单词';

  @override
  String get learnDrillCallsigns => '呼号';

  @override
  String get learnDrillQso => '通联（QSO）';

  @override
  String get learnDrillCharacters => '单字速认';

  @override
  String get learnDrillAbbreviations => '缩语与 Q 简语';

  @override
  String get learnDrillNumbers => '数字组';

  @override
  String get learnDrillConfusables => '易混字符';

  @override
  String get learnDrillContest => '竞赛交换';

  @override
  String get learnDrillGroupsHint => '用已学字符组成的随机字组';

  @override
  String get learnDrillCharactersHint => '每次一个字符，听到即答';

  @override
  String get learnDrillWordsHint => '常用英文单词';

  @override
  String get learnDrillAbbreviationsHint => 'TNX、FB、QTH、QSL 等通联常用语';

  @override
  String get learnDrillNumbersHint => '五位数字组，如电报与序号';

  @override
  String get learnDrillCallsignsHint => '世界各地的业余电台呼号';

  @override
  String get learnDrillConfusablesHint => '成对练习容易听混的字符，如 S/H、U/V';

  @override
  String get learnDrillQsoHint => '完整通联中的句子';

  @override
  String get learnDrillContestHint => '呼号 + 5NN + 序号或分区，含缩略数字';

  @override
  String get learnDrillReviewHint => '到期需要复习的字符';

  @override
  String get toolsTitle => '无线电工具';

  @override
  String get toolsGridTitle => '网格定位';

  @override
  String get toolsGridHint => '坐标换算网格、两地距离与天线方位';

  @override
  String get toolsBandsTitle => '频段与天线';

  @override
  String get toolsBandsHint => '频率所在频段、波长与偶极天线长度';

  @override
  String get toolsSpeedTitle => '报速换算';

  @override
  String get toolsSpeedHint => 'WPM 换算点长、间隔与每分钟字符数';

  @override
  String get toolsRstTitle => 'RST 信号报告';

  @override
  String get toolsRstHint => '组合信号报告并查看每一位的含义';

  @override
  String get toolsClockTitle => 'UTC 时钟';

  @override
  String get toolsClockHint => '日志使用的 UTC 时间与本地时间';

  @override
  String get toolsGridFromCoordinates => '由坐标求网格';

  @override
  String get toolsGridLatitude => '纬度';

  @override
  String get toolsGridLongitude => '经度';

  @override
  String get toolsGridCoordinatesHelp => '十进制度数；南纬、西经为负';

  @override
  String get toolsGridInvalidCoordinates => '纬度 -90 至 90，经度 -180 至 180';

  @override
  String get toolsGridLocator => '网格';

  @override
  String get toolsGridDistanceSection => '距离与方位';

  @override
  String get toolsGridMine => '我的网格';

  @override
  String get toolsGridTheirs => '对方网格';

  @override
  String get toolsGridInvalidLocator => '需 2、4、6 或 8 位，如 OM89ex';

  @override
  String get toolsGridCenter => '网格中心';

  @override
  String get toolsGridDistance => '距离';

  @override
  String get toolsGridShortPath => '短程方位';

  @override
  String get toolsGridLongPath => '长程方位';

  @override
  String get toolsBandsFrequency => '频率（MHz）';

  @override
  String get toolsBandsInvalidFrequency => '请输入大于 0 的频率';

  @override
  String toolsBandsRegionLabel(int number) {
    return '$number 区';
  }

  @override
  String get toolsBandsRegionHelp => '1 区：欧洲、非洲、中东 · 2 区：美洲 · 3 区：亚太（含中国）';

  @override
  String toolsBandsInBand(String band) {
    return '位于 $band 业余频段';
  }

  @override
  String get toolsBandsOutOfBand => '不在业余频段内';

  @override
  String get toolsBandsWavelength => '波长';

  @override
  String get toolsBandsDipole => '半波偶极天线（全长）';

  @override
  String get toolsBandsQuarterWave => '四分之一波长垂直天线';

  @override
  String get toolsBandsAntennaNote => '长度已乘 0.95 缩短系数，实际需修剪至谐振。';

  @override
  String get toolsBandsTable => '频段边界';

  @override
  String toolsBandsQrp(String frequency) {
    return 'QRP CW $frequency';
  }

  @override
  String get toolsBandsDisclaimer => '以上为 ITU 划分，请以你的执照与本国频率规划为准（通常更窄）。';

  @override
  String get toolsSpeedCharacter => '字符速度';

  @override
  String get toolsSpeedFarnsworth => 'Farnsworth 间隔';

  @override
  String get toolsSpeedOverall => '整体速度';

  @override
  String get toolsSpeedDit => '点';

  @override
  String get toolsSpeedDah => '划';

  @override
  String get toolsSpeedCharGap => '字符间隔';

  @override
  String get toolsSpeedWordGap => '单词间隔';

  @override
  String get toolsSpeedCpm => '每分钟字符数';

  @override
  String get toolsSpeedParis => '一个 PARIS 单词';

  @override
  String get toolsRstReadability => '可读度 (R)';

  @override
  String get toolsRstStrength => '信号强度 (S)';

  @override
  String get toolsRstTone => '音调 (T)';

  @override
  String get toolsRstReport => '报告';

  @override
  String get toolsRstCut => '竞赛简写';

  @override
  String get toolsRstPhone => '话音（无音调）';

  @override
  String get toolsRstR1 => '无法辨认';

  @override
  String get toolsRstR2 => '勉强可辨，偶尔听出个别字';

  @override
  String get toolsRstR3 => '相当困难才能辨认';

  @override
  String get toolsRstR4 => '基本没有困难';

  @override
  String get toolsRstR5 => '完全清晰';

  @override
  String get toolsRstS1 => '微弱，几乎察觉不到';

  @override
  String get toolsRstS2 => '很弱';

  @override
  String get toolsRstS3 => '弱';

  @override
  String get toolsRstS4 => '尚可';

  @override
  String get toolsRstS5 => '较好';

  @override
  String get toolsRstS6 => '好';

  @override
  String get toolsRstS7 => '较强';

  @override
  String get toolsRstS8 => '强';

  @override
  String get toolsRstS9 => '极强';

  @override
  String get toolsRstT1 => '极粗糙、很宽，像未整流交流';

  @override
  String get toolsRstT2 => '很粗糙的交流音，刺耳且宽';

  @override
  String get toolsRstT3 => '粗糙，已整流未滤波';

  @override
  String get toolsRstT4 => '粗糙，略有滤波痕迹';

  @override
  String get toolsRstT5 => '已滤波，但纹波调制很重';

  @override
  String get toolsRstT6 => '已滤波，有明显纹波';

  @override
  String get toolsRstT7 => '接近纯音，略有纹波';

  @override
  String get toolsRstT8 => '近乎完美，仅有轻微调制';

  @override
  String get toolsRstT9 => '纯净音调，毫无纹波';

  @override
  String get toolsClockUtc => 'UTC';

  @override
  String get toolsClockLocal => '本地时间';

  @override
  String get toolsClockNote => '通联日志与 QSL 卡片统一使用 UTC。';

  @override
  String get learnReceiveTitle => '听抄';

  @override
  String get learnReviewTitle => '复习';

  @override
  String get learnListen => '请听...';

  @override
  String get learnReady => '就绪';

  @override
  String get learnReplay => '重放';

  @override
  String get learnAnswerHint => '输入你听到的内容';

  @override
  String get learnSubmit => '核对';

  @override
  String get learnNext => '下一个';

  @override
  String get learnFinish => '结束';

  @override
  String get learnDone => '完成';

  @override
  String get learnBackspace => '删除';

  @override
  String get learnSpace => '空格';

  @override
  String get learnSent => '发出';

  @override
  String get learnYourCopy => '你的抄收';

  @override
  String get learnRoundPerfect => '全部抄对！';

  @override
  String get learnSessionSummary => '练习小结';

  @override
  String get learnLessonPassed => '本课通过';

  @override
  String get learnLessonNotPassed => '继续加油：正确率达 90% 即可解锁下一个字符';

  @override
  String get learnReviewRecorded => '复习已记录';

  @override
  String get learnWeakChars => '需要加强';

  @override
  String get learnConfusions => '易混淆';

  @override
  String get learnNoFeedbackWarning => '声音、闪光和振动都已关闭 - 将改用屏幕闪烁提示。';

  @override
  String get learnSendTitle => '发报';

  @override
  String get learnSendThis => '请发送';

  @override
  String get learnCopyFromMemory => '凭记忆';

  @override
  String get learnHiddenTarget => '已隐藏 - 凭记忆拍发';

  @override
  String get learnDecoded => '译码';

  @override
  String get learnWaitingForKey => '准备好后开始拍发';

  @override
  String get learnRestart => '重新开始';

  @override
  String get learnTryAnother => '换一个';

  @override
  String get learnKeyerStraight => '直键';

  @override
  String get learnKeyerIambicA => 'Iambic A';

  @override
  String get learnKeyerIambicB => 'Iambic B';

  @override
  String get learnLegendStraight => '空格 = 电键';

  @override
  String get learnLegendPaddles => '左 Ctrl = 点，右 Ctrl = 划';

  @override
  String get learnSendClean => '手法干净 - 无需修正。';

  @override
  String get learnSendIssues => '节奏提示';

  @override
  String get learnYourSending => '译码为';

  @override
  String get learnStraightKeyLabel => '电键';

  @override
  String get learnDitLabel => '点';

  @override
  String get learnDahLabel => '划';

  @override
  String get learnSettingsTitle => '训练设置';

  @override
  String get learnCharacterSpeed => '字符速度';

  @override
  String get learnFarnsworth => 'Farnsworth 间距';

  @override
  String get learnFarnsworthHelp => '字符保持高速；字符之间的间隔拉长到这个速度。';

  @override
  String get learnEffectiveSpeed => '有效速度';

  @override
  String get learnTone => '音调';

  @override
  String get learnPlaySample => '播放示例';

  @override
  String get learnSessionLength => '练习长度';

  @override
  String get learnFeedback => '反馈';

  @override
  String get learnSound => '声音';

  @override
  String get learnFlash => '屏幕闪光';

  @override
  String get learnHaptic => '振动';

  @override
  String get learnKeyer => '电键模式';

  @override
  String get learnDailyGoal => '每日目标';

  @override
  String get referenceReferenceTitle => '莫尔斯电码手册';

  @override
  String get referenceTranslatorTitle => '翻译器';

  @override
  String get referencePlay => '播放';

  @override
  String get referenceStop => '停止';

  @override
  String get referenceClear => '清空';

  @override
  String get referenceClose => '关闭';

  @override
  String get referenceEmptyOutput => '—';

  @override
  String get referenceSearchHint => '搜索字符、规程符号、Q 简语…';

  @override
  String get referenceClearSearch => '清除搜索';

  @override
  String get referenceNoResults => '没有匹配的结果。';

  @override
  String get referenceSectionAlphabet => '字母与数字';

  @override
  String get referenceSectionPunctuation => '标点';

  @override
  String get referenceSectionProsigns => '规程符号（Prosign）';

  @override
  String get referenceSectionQCodes => 'Q 简语';

  @override
  String get referenceSectionAbbreviations => 'CW 缩写';

  @override
  String get referenceSectionKoch => 'Koch 顺序';

  @override
  String get referenceAlphabetHint => '点按卡片试听。长按查看记忆口诀。';

  @override
  String get referenceKochHint => 'Koch 法引入字符的顺序（LCWO 序列）。从 K 和 M 开始；抄收正确率达 90% 时再加一个字符。';

  @override
  String get referenceMnemonicTitle => '记忆口诀';

  @override
  String get referenceMeaningLabel => '含义';

  @override
  String get referencePlaybackSettings => '播放设置';

  @override
  String get referenceCharacterSpeed => '字符速度';

  @override
  String get referenceFarnsworth => 'Farnsworth 间距';

  @override
  String get referenceFarnsworthHelp => '字符保持全速；间隔拉长到有效速度。';

  @override
  String get referenceEffectiveSpeed => '有效速度';

  @override
  String get referenceTone => '音调';

  @override
  String get referenceModeTextToMorse => '文本 → 莫尔斯';

  @override
  String get referenceModeMorseToText => '莫尔斯 → 文本';

  @override
  String get referenceModeKey => '拍发';

  @override
  String get referenceTextInputLabel => '文本';

  @override
  String get referenceTextInputHint => '输入要编码的文本…';

  @override
  String get referencePatternOutputLabel => '莫尔斯';

  @override
  String get referenceCopyPattern => '复制电码';

  @override
  String get referencePatternCopied => '电码已复制';

  @override
  String get referencePatternInputLabel => '莫尔斯';

  @override
  String get referencePatternInputHint => '输入 . 和 -，字母间用空格，单词间用 /';

  @override
  String get referenceTextOutputLabel => '文本';

  @override
  String get referenceCopyText => '复制文本';

  @override
  String get referenceTextCopied => '文本已复制';

  @override
  String get referenceUnknownPatternHelp => '没有对应字符的电码显示为 <电码>。';

  @override
  String get referenceKeypadDit => '点';

  @override
  String get referenceKeypadDah => '划';

  @override
  String get referenceKeypadCharGap => '字母间隔';

  @override
  String get referenceKeypadWordGap => '单词间隔';

  @override
  String get referenceKeypadBackspace => '退格';

  @override
  String get referenceKeyHint => '按住电键发送。使用键盘时按住空格。';

  @override
  String get referenceKeyLabel => '电键';

  @override
  String get referenceKeyDecodedLabel => '译码';

  @override
  String get referenceKeyPendingLabel => '键控中';

  @override
  String get statsTitle => '统计';

  @override
  String get statsLoading => '正在加载你的统计...';

  @override
  String get statsLoadFailed => '无法加载你的进度。下拉或重新打开以重试。';

  @override
  String get statsRetry => '重试';

  @override
  String get statsEmptyTitle => '还没有练习记录';

  @override
  String get statsEmptyBody => '完成第一次听抄或发报练习后，这里会显示你的正确率趋势、各字符掌握程度和练习日历。';

  @override
  String get statsEmptyCallToAction => '前往「学习」并点按「继续课程」开始。';

  @override
  String get statsOverviewTitle => '总览';

  @override
  String get statsTileLesson => 'Koch 课程';

  @override
  String get statsTileAccuracy => '正确率';

  @override
  String get statsNoData => '--';

  @override
  String get statsTilePractice => '练习量';

  @override
  String get statsTileStreak => '连续天数';

  @override
  String get statsTileDailyGoal => '每日目标';

  @override
  String get statsGoalMet => '今日已达成';

  @override
  String get statsSummaryTitle => '你的统计';

  @override
  String get statsSummaryOpen => '查看统计';

  @override
  String get statsTrendTitle => '正确率趋势';

  @override
  String get statsTrendHint => '点按数据点查看该次练习。';

  @override
  String get statsSeriesReceive => '听抄';

  @override
  String get statsSeriesSend => '发报';

  @override
  String get statsAxisSessions => '练习次序';

  @override
  String get statsCharsTitle => '字符';

  @override
  String get statsCharsSubtitle => '按 Koch 顺序。点按字符查看详情。';

  @override
  String get statsCharsNotStarted => '尚未练习';

  @override
  String get statsNotInCourse => '不在 Koch 课程内';

  @override
  String get statsSrsTitle => '间隔重复';

  @override
  String get statsSrsNotTracked => '尚未安排';

  @override
  String get statsSrsDueNow => '现在到期';

  @override
  String get statsConfusionsTitle => '最常混淆为';

  @override
  String get statsConfusionsNone => '没有混淆记录';

  @override
  String get statsConfusionMissed => '漏抄';

  @override
  String get statsBucketLegendTitle => '正确率';

  @override
  String get statsBucketNone => '无';

  @override
  String get statsBucketWeak => '< 70%';

  @override
  String get statsBucketFair => '70-89%';

  @override
  String get statsBucketGood => '90-97%';

  @override
  String get statsBucketStrong => '>= 98%';

  @override
  String get statsHeatmapTitle => '混淆矩阵';

  @override
  String get statsHeatmapSubtitle => '行是发出的字符，列是你的回答。颜色越深表示越频繁。';

  @override
  String get statsHeatmapEmpty => '还没有混淆记录。答错的字符会显示在这里。';

  @override
  String get statsHeatmapLegendLow => '少';

  @override
  String get statsHeatmapLegendHigh => '多';

  @override
  String get statsHeatmapAxisTarget => '发出';

  @override
  String get statsHeatmapAxisAnswered => '回答';

  @override
  String get statsCalendarTitle => '练习日历';

  @override
  String get statsCalendarSubtitle => '最近 12 周';

  @override
  String get statsCalendarLegendLess => '少';

  @override
  String get statsCalendarLegendMore => '多';

  @override
  String get statsStreakExplanation => '连续天数按至少有一次练习的连续日历日计算。整天未练习会重置；一天内练习两次只算一天。';

  @override
  String get learnStatistics => '统计';

  @override
  String get listenTitle => '收听';

  @override
  String get listenStart => '开始';

  @override
  String get listenStop => '停止';

  @override
  String get listenStarting => '正在启动麦克风…';

  @override
  String get listenClear => '清空文本';

  @override
  String get listenCopy => '复制文本';

  @override
  String get listenCopied => '已复制解码文本';

  @override
  String get listenSettings => '收听设置';

  @override
  String get listenDecoded => '解码结果';

  @override
  String get listenEmptyHint => '把麦克风对准莫尔斯电码音，解码文本会显示在这里。';

  @override
  String get listenIdleHint => '点击「开始」以收听莫尔斯电码音。';

  @override
  String get listenPending => '接收中';

  @override
  String get listenSpeed => '速度';

  @override
  String get listenSpeedUnknown => '-- WPM';

  @override
  String get listenLevel => '信号';

  @override
  String get listenToneOn => '有音';

  @override
  String get listenTone => '音调频率';

  @override
  String get listenToneLocked => '已锁定';

  @override
  String get listenToneSearching => '搜索中';

  @override
  String get listenToneManual => '手动';

  @override
  String get listenAutoTune => '自动调谐';

  @override
  String get listenAutoTuneHelp => '跟踪 400–1000 Hz 之间最强的音调；拖动滑块可改为手动调谐。';

  @override
  String get listenRetune => '自动';

  @override
  String get listenBlockSize => '分析块长';

  @override
  String get listenBlockSizeHelp => '块越小，点划边沿定位越精确，但更容易受噪声影响。256 采样（5.3 ms）适合 5–40 WPM。';

  @override
  String get listenMinElement => '最短元素';

  @override
  String get listenMinElementHelp => '短于此时长的音与间隔将被视为杂音或断续而忽略。';

  @override
  String get listenPermissionDenied => '麦克风权限被拒绝。请在系统设置中允许后重试。';

  @override
  String get listenPermissionRetry => '重试';

  @override
  String get listenStartFailed => '无法启动麦克风。';

  @override
  String get listenNoInput => '未找到麦克风。请连接后重试。';

  @override
  String get listenStreamFailed => '麦克风意外中断，请重试。';

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
    return '$samples 采样（$ms ms）';
  }

  @override
  String listenMsValue(int ms) {
    return '$ms ms';
  }

  @override
  String get listenStoppedInBackground => '应用进入后台，已停止收听。';

  @override
  String get learnWpmUnknown => '-- WPM';

  @override
  String get learnTipDitTooLongTitle => '点太长';

  @override
  String get learnTipDahTooShortTitle => '划太短';

  @override
  String get learnTipIntraGapTooLongTitle => '码元过于分散';

  @override
  String get learnTipCharGapTooShortTitle => '字符过于拥挤';

  @override
  String get learnTipWordGapTooShortTitle => '单词过于拥挤';

  @override
  String get learnTipSpeedUnsteadyTitle => '速度不稳';

  @override
  String get learnSeverityMinor => '轻微';

  @override
  String get learnSeverityModerate => '明显';

  @override
  String get learnSeveritySevere => '严重';

  @override
  String get notificationOpen => '打开';

  @override
  String get notificationChannelMessages => '消息';

  @override
  String get notificationChannelMessagesDescription => '来自好友和群组的新莫尔斯电码消息';

  @override
  String get notificationChannelFriendRequests => '好友请求';

  @override
  String get notificationChannelFriendRequestsDescription => '有人想添加你为好友';

  @override
  String get notificationChannelGroupInvites => '群组邀请';

  @override
  String get notificationChannelGroupInvitesDescription => '好友邀请你加入群组';

  @override
  String get notificationNewMessage => '新消息';

  @override
  String get notificationFriendRequestTitle => '新的好友请求';

  @override
  String learnNewestCharIs(String char) {
    return '本课新字符：$char';
  }

  @override
  String learnCharNewSemantics(String char) {
    return '$char，新字符';
  }

  @override
  String learnPendingPattern(String pattern) {
    return '键控中：$pattern';
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
    return '你的点拖得太长（约为一个点的 $ratio）。想着“嘀”而不是“嗒”——点是轻敲，不是长按。';
  }

  @override
  String learnTipDahTooShort(String ratio) {
    return '你的划太短（约为一个点的 $ratio；目标是 3 倍）。划要按住三个点的时长。';
  }

  @override
  String learnTipIntraGapTooLong(String ratio) {
    return '字符内部的间隔太宽（约为一个点的 $ratio）。同一字符的码元要紧凑相连。';
  }

  @override
  String learnTipCharGapTooShort(String ratio) {
    return '字符之间粘在一起了（间隔约为一个点的 $ratio；目标是 3 倍）。每个字符后留出明确的停顿。';
  }

  @override
  String learnTipWordGapTooShort(String ratio) {
    return '单词之间太近（间隔约为一个点的 $ratio；目标是 7 倍）。单词之间要数一个长停顿。';
  }

  @override
  String learnTipSpeedUnsteady(int percent) {
    return '你的速度飘忽不定（波动 $percent%）。定下一个节拍，整行保持不变。';
  }

  @override
  String learnIssueDetailDitTooLong(int offending, int total, String ratio) {
    return '$total 个点中有 $offending 个太长（平均 $ratio 点长）';
  }

  @override
  String learnIssueDetailDahTooShort(int offending, int total, String ratio) {
    return '$total 个划中有 $offending 个太短（平均 $ratio 点长）';
  }

  @override
  String learnIssueDetailIntraGapTooLong(int offending, int total, String ratio) {
    return '$total 个字符内间隔中有 $offending 个太长（平均 $ratio 点长）';
  }

  @override
  String learnIssueDetailCharGapTooShort(int offending, int total, String ratio) {
    return '$total 个字符间隔中有 $offending 个太短（平均 $ratio 点长）';
  }

  @override
  String learnIssueDetailWordGapTooShort(int offending, int total, String ratio) {
    return '$total 个单词间隔中有 $offending 个太短（平均 $ratio 点长）';
  }

  @override
  String learnIssueDetailSpeedUnsteady(String cv) {
    return '拍发速度不稳（变异系数 $cv）';
  }

  @override
  String statsAccuracyDetail(String allTime) {
    return '最近 7 天 / 全部 $allTime';
  }

  @override
  String statsDurationHoursMinutes(int hours, int minutes) {
    return '$hours 小时 $minutes 分';
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
  String get accountNewPasswordRequired => '请输入新密码';

  @override
  String get accountToxIdQrSemantics => 'Tox ID 二维码';

  @override
  String get accountBackupSaveDialogTitle => '保存 DitMesh 备份';

  @override
  String get accountBackupShareSubject => 'DitMesh 身份备份';

  @override
  String get accountBackupChooseDialogTitle => '选择 DitMesh 备份';

  @override
  String notificationNewMessages(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 条新消息',
    );
    return '$_temp0';
  }

  @override
  String notificationFriendRequestFrom(String name) {
    return '来自 $name 的好友请求';
  }

  @override
  String notificationFriendRequestBody(String name, String message) {
    return '$name：$message';
  }

  @override
  String notificationGroupInviteTitle(String group) {
    return '邀请加入 $group';
  }

  @override
  String notificationGroupInviteBody(String name) {
    return '$name 邀请你加入';
  }

  @override
  String desktopTrayShow(String app) {
    return '显示 $app';
  }

  @override
  String desktopTrayHide(String app) {
    return '隐藏 $app';
  }

  @override
  String get desktopTraySoundOn => '声音已开';

  @override
  String get desktopTraySoundOff => '声音已关';

  @override
  String desktopTrayQuit(String app) {
    return '退出 $app';
  }

  @override
  String desktopTrayTooltipUnread(String app, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 条未读',
    );
    return '$app — $_temp0';
  }

  @override
  String desktopWindowTitleUnread(String badge, String app) {
    return '($badge) $app';
  }

  @override
  String get listenStateOn => '开';

  @override
  String get listenStateOff => '关';

  @override
  String chatBytesLeftCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '剩余 $count 字节',
    );
    return '$_temp0';
  }

  @override
  String chatMemberCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 位成员',
    );
    return '$_temp0';
  }

  @override
  String chatFriendsCount(int count) {
    return '好友（$count）';
  }

  @override
  String chatFriendRequestsCount(int count) {
    return '好友请求（$count）';
  }

  @override
  String chatGroupInvitesCount(int count) {
    return '群组邀请（$count）';
  }

  @override
  String chatMembersTitleCount(int count) {
    return '成员 · $count';
  }

  @override
  String chatInvitedByName(String name) {
    return '邀请人：$name';
  }

  @override
  String chatMemberSelf(String name) {
    return '$name（你）';
  }

  @override
  String chatSliderValue(String label, int value, String unit) {
    return '$label：$value $unit';
  }

  @override
  String referenceTelegraphCodes(String codes) {
    return '中文电码：$codes';
  }

  @override
  String get referenceTelegraphMainland => '大陆（1983）';

  @override
  String get referenceTelegraphTaiwan => '台湾 / 香港';

  @override
  String get referenceTelegraphNone => '本电码本无此字';

  @override
  String get appearanceTitle => '外观';

  @override
  String get appearanceStyles => '界面风格';

  @override
  String get appearanceChoose => '选择风格，预览后应用';

  @override
  String get appearanceMode => '明暗模式';

  @override
  String get appearancePreview => '效果预览';

  @override
  String get appearanceApply => '应用风格';

  @override
  String get appearanceRestore => '恢复默认';

  @override
  String get appearanceApplied => '外观已保存';

  @override
  String get appearanceSaveFailed => '无法保存外观，请重试。';

  @override
  String get appearanceClassic => '经典黄铜';

  @override
  String get appearanceModern => '清爽现代';

  @override
  String get appearanceRadio => '夜航电台';

  @override
  String get appearancePaper => '纸感手册';

  @override
  String get appearanceCartoon => '清新卡通';

  @override
  String get appearanceLight => '浅色';

  @override
  String get appearanceDark => '深色';

  @override
  String get appearanceSubtitle => '五种风格，支持浅色与深色';

  @override
  String get chatClearHistoryBody => '删除当前会话在本机保存的历史记录？其他设备上的副本不受影响。此操作无法撤销。';

  @override
  String get chatLoadEarlier => '加载更早消息';

  @override
  String get chatHistoryLoadFailed => '更早消息加载失败，点击重试。';

  @override
  String get chatRetryHistory => '重试';

  @override
  String chatNewMessages(int count) {
    return '$count 条新消息';
  }

  @override
  String learnShowAllChars(int count) {
    return '显示全部 $count 个字符';
  }

  @override
  String get chatSelfMe => '我';

  @override
  String get chatSelfLocalOnly => '仅保存在本机';

  @override
  String get chatSelfContactSubtitle => '草稿、练习与备忘 · 不会发送';

  @override
  String get learnShowFewerChars => '收起字符';

  @override
  String get learnLeaveDrillTitle => '退出本次练习？';

  @override
  String get learnLeaveDrillBody => '本次练习已完成的轮次不会被保存。';

  @override
  String get learnLeaveDrillConfirm => '退出';

  @override
  String get chatScanQrPermissionDenied => 'DitMesh 需要相机权限才能扫描二维码，请在系统设置中允许。';

  @override
  String get chatScanQrCameraUnavailable => '此设备的相机不可用。';

  @override
  String get learnReplayAssistedNote => '已重播：本次练习计入练习量，但不会解锁课程或更新复习。';

  @override
  String get learnPlanTitle => '今日计划';

  @override
  String learnPlanSummary(int minutes, int done, int total) {
    return '约 $minutes 分钟 · 已完成 $done/$total 步';
  }

  @override
  String get learnPlanBudget => '计划时长';

  @override
  String learnPlanBudgetMinutes(int minutes) {
    return '$minutes 分钟';
  }

  @override
  String get learnPlanStart => '开始计划';

  @override
  String get learnPlanContinue => '继续计划';

  @override
  String get learnPlanStepReview => '复习到期字符';

  @override
  String get learnPlanStepFocus => '重点练习';

  @override
  String learnPlanStepCourse(int lesson) {
    return '第 $lesson 课';
  }

  @override
  String get learnPlanStepSend => '发报练习';

  @override
  String learnPlanReasonDueReview(String symbols) {
    return '到期复习：$symbols';
  }

  @override
  String learnPlanReasonConfusions(String symbols) {
    return '经常混淆：$symbols';
  }

  @override
  String learnPlanReasonWeak(String symbols) {
    return '正确率低于 90%：$symbols';
  }

  @override
  String learnPlanReasonChallenge(int count) {
    return '$count 个字符：可以解锁下一课';
  }

  @override
  String learnPlanReasonExtended(int count) {
    return '已延长到 $count 个字符，以便能解锁下一课';
  }

  @override
  String get learnPlanReasonConsolidate => '短练习：巩固本课，不会解锁下一课';

  @override
  String learnPlanReasonOutdated(int lesson) {
    return '课程已前进：练习第 $lesson 课，但不会解锁';
  }

  @override
  String learnPlanReasonSend(int count) {
    return '发送 $count 个短目标';
  }

  @override
  String learnPlanStepDonePercent(int percent) {
    return '完成 · $percent%';
  }

  @override
  String get learnPlanStepDone => '完成';

  @override
  String learnPlanSendProgress(int done, int total) {
    return '已发送 $done/$total';
  }

  @override
  String get learnPlanStale => '课程或速度已更改。要更新尚未开始的步骤吗？';

  @override
  String get learnPlanUpdate => '更新步骤';

  @override
  String get learnPlanComplete => '今日计划已完成';

  @override
  String learnPlanNeedsWork(String symbols) {
    return '需要加强：$symbols';
  }

  @override
  String get learnPlanAllGood => '今天没有薄弱字符。';

  @override
  String get learnPlanTomorrow => '明天会生成新计划。自由练习随时可用。';

  @override
  String learnPlanNext(String step) {
    return '下一步：$step';
  }

  @override
  String learnPlanEarlier(int done, int total) {
    return '之前的计划停在第 $done/$total 步，不再计入今天。';
  }

  @override
  String learnSpeedAdviceRaise(int wpm) {
    return '可以把有效速度提高到 $wpm WPM';
  }

  @override
  String learnSpeedAdviceRaiseBoth(int wpm) {
    return '可以提高到 $wpm WPM';
  }

  @override
  String learnSpeedAdviceLower(int wpm) {
    return '当前速度抄收较吃力。可以试试 $wpm WPM 有效速度，或做重点练习。';
  }

  @override
  String learnSpeedAdviceBody(int count, int percent) {
    return '依据你最近 $count 次无辅助练习（$percent%）。点“应用”前不会改变任何设置。';
  }

  @override
  String get learnSpeedAdviceApply => '应用';

  @override
  String get learnSpeedAdviceDismiss => '暂不';

  @override
  String get learnSpeedAdviceInsufficient => '速度建议需要在当前速度下完成 3 次、每次 50 个字符以上的无辅助练习。';

  @override
  String get learnQsoAction => 'QSO 模拟';

  @override
  String learnQsoLocked(int lesson) {
    return '第 $lesson 课起开放';
  }

  @override
  String get learnQsoTitle => 'QSO 模拟';

  @override
  String get learnQsoRespond => '回应 CQ';

  @override
  String get learnQsoRespondHint => '一个电台在呼叫 CQ。回应它并交换信号报告。';

  @override
  String get learnQsoCall => '呼叫 CQ';

  @override
  String get learnQsoCallHint => '你呼叫 CQ，会有电台回应。';

  @override
  String get learnQsoYourCall => '你的呼号';

  @override
  String get learnQsoYourName => '你的名字';

  @override
  String get learnQsoYourQth => '你的 QTH';

  @override
  String get learnQsoInvalidCall => '请输入呼号，例如 BD1XYZ';

  @override
  String get learnQsoInvalidWord => '一个单词，仅限字母 A–Z';

  @override
  String get learnQsoOffline => '完全在本机运行，不会向任何人发送内容。';

  @override
  String get learnQsoStart => '开始 QSO';

  @override
  String get learnQsoResume => '继续未完成的 QSO';

  @override
  String get learnQsoStageCallCq => '用你的呼号呼叫 CQ';

  @override
  String get learnQsoStageCallConfirm => '回应：对方呼号、DE、你的呼号';

  @override
  String get learnQsoStageExchange => '发送信号报告、名字和 QTH';

  @override
  String get learnQsoStageConfirmInfo => '确认对方的信息';

  @override
  String get learnQsoStageClosing => '以 73 和 <SK> 结束';

  @override
  String get learnQsoStageDone => 'QSO 完成';

  @override
  String learnQsoSpeed(int wpm) {
    return '对方以 $wpm WPM 有效速度发送';
  }

  @override
  String learnQsoRemote(String call) {
    return '$call 发送';
  }

  @override
  String get learnQsoRemoteHidden => '请凭听觉抄收——文本已隐藏。';

  @override
  String get learnQsoShowText => '显示文本';

  @override
  String get learnQsoListen => '收听';

  @override
  String get learnQsoAccepted => '已接受';

  @override
  String get learnQsoRejected => '未通过';

  @override
  String get learnQsoRemoteSending => '对方正在发送……';

  @override
  String get learnQsoYourTurn => '轮到你了：拍发回复，然后点“发送”。';

  @override
  String get learnQsoDecoded => '你的发送内容';

  @override
  String get learnQsoNothingKeyed => '尚未拍发';

  @override
  String get learnQsoPlayAgain => '请求重复（AGN）';

  @override
  String get learnQsoSlower => '请求放慢（QRS）';

  @override
  String get learnQsoHint => '提示';

  @override
  String learnQsoHintLabel(String example) {
    return '示例：$example';
  }

  @override
  String get learnQsoPause => '暂停';

  @override
  String get learnQsoSend => '发送';

  @override
  String get learnQsoClear => '清除';

  @override
  String get learnQsoIssueEmpty => '没有拍发任何内容。';

  @override
  String get learnQsoIssueMissingCq => '以 CQ 开头。';

  @override
  String get learnQsoIssueMissingDe => '在两个呼号之间加 DE。';

  @override
  String get learnQsoIssueWrongLocalCall => '你的呼号缺失或错误。';

  @override
  String get learnQsoIssueWrongRemoteCall => '对方的呼号错误。';

  @override
  String get learnQsoIssueReversedCalls => '呼号顺序反了：先对方，再 DE，再你的。';

  @override
  String get learnQsoIssueMissingEnding => '以 K 或 KN 结尾。';

  @override
  String get learnQsoIssueMissingRst => '给出信号报告，例如 UR RST 599。';

  @override
  String get learnQsoIssueInvalidRst => 'RST 超出范围（R 1–5、S 1–9、T 1–9）。';

  @override
  String get learnQsoIssueMissingName => '发送 NAME 和你的名字。';

  @override
  String get learnQsoIssueWrongName => '这不是你在本次 QSO 中的名字。';

  @override
  String get learnQsoIssueMissingQth => '发送 QTH 和你的位置。';

  @override
  String get learnQsoIssueWrongQth => '这不是你在本次 QSO 中的 QTH。';

  @override
  String get learnQsoIssueMissingAck => '用 R 或 QSL 表示确认。';

  @override
  String get learnQsoIssueWrongRemoteName => '确认对方操作员的名字。';

  @override
  String get learnQsoIssueMissing73 => '加上 73。';

  @override
  String get learnQsoIssueMissingSk => '以 <SK> 结束联络。';

  @override
  String learnQsoSummaryFields(int count, int total) {
    return '一次通过：$total 步中 $count 步';
  }

  @override
  String learnQsoSummaryRepeats(int count) {
    return '重复次数：$count';
  }

  @override
  String learnQsoSummaryHints(int count) {
    return '提示次数：$count';
  }

  @override
  String learnQsoSummaryRhythm(int wpm) {
    return '你的发报：约 $wpm WPM';
  }

  @override
  String get learnQsoSummaryNote => 'QSO 成绩与抄收正确率分开统计，不会解锁课程。';

  @override
  String get messageStatusCancelled => '已取消——未发送';

  @override
  String get chatMessageLearnActions => '消息操作';

  @override
  String get chatPracticeMessage => '练习抄收这条消息';

  @override
  String get chatSaveAsMaterial => '保存为训练素材';

  @override
  String get chatSavedAsMaterial => '已保存到“我的素材”';

  @override
  String get chatSaveMaterialFailed => '保存素材失败，请重试。';

  @override
  String get chatListenOnly => '纯听训练';

  @override
  String get chatListenOnlyHidden => '纯听模式：点播放收听';

  @override
  String chatClearHistoryMaterials(int count) {
    return '此会话中有 $count 条消息已保存为训练素材。这些副本会保留，直到你在“学习 › 我的素材”中删除。';
  }

  @override
  String get chatPracticeTitle => '抄收练习';

  @override
  String chatPracticeUnsupported(String chars) {
    return '这条消息包含无法用莫尔斯码拍发的字符：$chars。练习时会略过它们。';
  }

  @override
  String chatPracticeTrainableCount(int count) {
    return '可练习 $count 个字符。';
  }

  @override
  String get chatPracticeNothingTrainable => '这条消息中没有可用莫尔斯码练习的内容。';

  @override
  String get chatPracticeConfirm => '练习其余部分';

  @override
  String get chatPracticeHint => '提示';

  @override
  String chatPracticeHintShown(String symbols) {
    return '提示：$symbols …';
  }

  @override
  String get chatPracticeAssisted => '已使用辅助：计入练习量，但不用于复习或速度建议。';

  @override
  String chatPracticeErrors(int wrong, int missed, int extra) {
    return '$wrong 个错误 · $missed 个遗漏 · $extra 个多余';
  }

  @override
  String chatPracticeErrorsAction(String symbols) {
    return '练习出错字符：$symbols';
  }

  @override
  String get learnTipDahTooLongTitle => '划太长';

  @override
  String learnTipDahTooLong(String ratio) {
    return '你的划太长（约为一个点的 $ratio；目标是 3 倍）。满三个点长就松开。';
  }

  @override
  String learnIssueDetailDahTooLong(int offending, int total, String ratio) {
    return '$total 个划中有 $offending 个太长（平均 $ratio 点长）';
  }

  @override
  String get learnRhythmTitle => '节奏';

  @override
  String get learnRhythmMine => '我的节奏';

  @override
  String get learnRhythmStandard => '标准节奏（目标速度）';

  @override
  String learnRhythmNormalizedNote(int ms) {
    return '问题按你自己的点长（$ms 毫秒）判断，节奏均匀但偏慢没有问题。标准行按目标速度绘制。';
  }

  @override
  String get learnRhythmNotLocated => '无法把你的拍发逐个对应到字符，因此问题未定位到具体字母。请改为练习整个目标。';

  @override
  String get learnRhythmPlayMine => '播放我的';

  @override
  String get learnRhythmPlayStandard => '播放标准';

  @override
  String learnRhythmPracticePart(int count) {
    return '练习这个（$count 次）';
  }

  @override
  String get learnRhythmPracticeWhole => '练习整个目标';

  @override
  String get learnRhythmSymbolOk => '很好';

  @override
  String get learnRhythmZoomIn => '放大';

  @override
  String get learnRhythmZoomOut => '缩小';

  @override
  String get chatSearchMessages => '搜索消息';

  @override
  String get chatSearchHint => '在此会话中搜索';

  @override
  String get chatSearchAnyone => '所有人';

  @override
  String get chatSearchMe => '我';

  @override
  String get chatSearchThem => '对方';

  @override
  String get chatSearchAnyDate => '任何日期';

  @override
  String chatSearchDateRange(String from, String to) {
    return '$from – $to';
  }

  @override
  String get chatSearchBookmarked => '已收藏';

  @override
  String get chatSearchNoResults => '没有匹配的消息。';

  @override
  String get chatSearchMore => '加载更多';

  @override
  String get chatAddBookmark => '收藏';

  @override
  String get chatRemoveBookmark => '取消收藏';

  @override
  String get chatBookmarked => '已收藏';

  @override
  String get chatBookmarkFailed => '无法保存收藏。';

  @override
  String get chatRetrySend => '重新发送';

  @override
  String get chatCancelSend => '取消发送';

  @override
  String get chatRetryQueued => '已重新排队，联系人上线后发送。';

  @override
  String get chatSendCancelled => '已取消，消息未发送。';

  @override
  String get chatRetryNotNeeded => '这条消息已不再是失败状态，无需重试。';

  @override
  String get chatCancelTooLate => '无法取消：消息已交给网络，可能会送达。';

  @override
  String get chatSendControlUnavailable => '此消息不支持该操作。';

  @override
  String get chatSendControlFailed => '操作未完成，消息保持原状态，请重试。';

  @override
  String get workbenchTitle => '录音工作台';

  @override
  String get workbenchOpen => '录音';

  @override
  String get workbenchImport => '导入录音';

  @override
  String get workbenchEmpty => '导入 WAV 录音，即可循环播放、解码并自己抄收。无需麦克风。';

  @override
  String get workbenchFormats => 'WAV，16 位 PCM，单声道或立体声，8/16/44.1/48 kHz；最大 50 MB、20 分钟。';

  @override
  String get workbenchBackupNote => '录音保存在本设备上，除非导出备份时选择包含，否则不会进入身份备份。已保存选段的标题、备注和位置始终会备份。';

  @override
  String workbenchInfo(String rate, String channels, String duration) {
    return '$rate kHz · $channels · $duration';
  }

  @override
  String get workbenchMono => '单声道';

  @override
  String get workbenchStereo => '立体声';

  @override
  String get workbenchTruncated => '文件提前结束，只使用已有的音频。';

  @override
  String get workbenchErrorNotWav => '这不是 WAV 文件。';

  @override
  String get workbenchErrorFormat => '目前只支持 16 位 PCM WAV（不支持 MP3、AAC 或浮点 WAV）。';

  @override
  String get workbenchErrorChannels => '只支持单声道或立体声录音。';

  @override
  String get workbenchErrorRate => '不支持该采样率。请使用 8、16、44.1 或 48 kHz。';

  @override
  String get workbenchErrorDamaged => '文件已损坏或不完整。';

  @override
  String get workbenchErrorTooLarge => '文件超过 50 MB。';

  @override
  String get workbenchErrorTooLong => '录音超过 20 分钟。';

  @override
  String get workbenchErrorIo => '无法读取该文件。';

  @override
  String get workbenchErrorMissing => '录音文件不见了。';

  @override
  String get workbenchStart => '开始（秒）';

  @override
  String get workbenchEnd => '结束（秒）';

  @override
  String get workbenchSelectAll => '全选';

  @override
  String get workbenchPlay => '播放所选片段';

  @override
  String get workbenchStop => '停止';

  @override
  String get workbenchLoop => '循环';

  @override
  String get workbenchPlayLimit => '较长的片段只播放前 5 分钟。';

  @override
  String get workbenchAutoTune => '自动寻找音调';

  @override
  String workbenchManualTone(int hz) {
    return '音调：$hz Hz';
  }

  @override
  String get workbenchDecode => '解码所选片段';

  @override
  String get workbenchCancel => '取消';

  @override
  String workbenchDecoding(int percent) {
    return '正在解码……$percent%';
  }

  @override
  String workbenchResultStats(int hz, int wpm) {
    return '音调 $hz Hz · 约 $wpm WPM';
  }

  @override
  String get workbenchToneNotLocked => '没有找到稳定的音调，请尝试手动调谐。';

  @override
  String get workbenchNoText => '该片段没有解出内容。';

  @override
  String workbenchUnknown(String patterns) {
    return '无法识别的码型：$patterns';
  }

  @override
  String get workbenchEdgeCut => '片段边缘的字符被截断，可能不准确。';

  @override
  String get workbenchToneNote => '锁定音调不代表结果可信，请用耳朵核对文本。';

  @override
  String get workbenchModeDecoder => '解码器';

  @override
  String get workbenchModeCopy => '我自己抄收';

  @override
  String get workbenchDecoderHidden => '抄收时解码文本会隐藏。';

  @override
  String get workbenchShowDecoder => '显示解码文本';

  @override
  String get workbenchReference => '参考答案（可选）';

  @override
  String get workbenchReferenceHelp => '粘贴实际发送的文本；否则会与解码结果比较。';

  @override
  String get workbenchAgainstDecoder => '已与解码结果比较，而解码结果本身也可能有误。';

  @override
  String get workbenchSave => '保存片段';

  @override
  String get workbenchSaveTitle => '标题';

  @override
  String get workbenchSaveNote => '备注';

  @override
  String get workbenchSaved => '片段已保存';

  @override
  String get workbenchSaveFailed => '无法保存片段。';

  @override
  String get workbenchLibrary => '已保存的片段';

  @override
  String get workbenchLibraryEmpty => '还没有保存的片段。';

  @override
  String get workbenchMissing => '录音文件不见了——请重新选择文件或删除此项。';

  @override
  String get workbenchRelink => '重新选择文件';

  @override
  String get workbenchDelete => '删除';

  @override
  String get materialsTitle => '我的素材';

  @override
  String get materialsNew => '新建素材';

  @override
  String get materialsEdit => '编辑';

  @override
  String get materialsSave => '保存';

  @override
  String get materialsSaveFailed => '无法保存素材。';

  @override
  String get materialsTitleField => '标题';

  @override
  String get materialsTagsField => '标签（用逗号分隔）';

  @override
  String get materialsTextField => '文本';

  @override
  String get materialsListField => '每行一项';

  @override
  String get materialsKindText => '文本';

  @override
  String get materialsKindWords => '单词表';

  @override
  String get materialsKindCallsigns => '呼号';

  @override
  String get materialsPreview => '预览';

  @override
  String materialsPreviewCounts(int items, int symbols, int prosigns) {
    return '$items 项 · $symbols 个字符 · $prosigns 个程序信号';
  }

  @override
  String materialsPreviewUnsupported(String chars) {
    return '无莫尔斯码，练习时略过：$chars';
  }

  @override
  String materialsPreviewDuplicates(int count) {
    return '$count 个重复项只保留一次';
  }

  @override
  String get materialsProblemEmpty => '请先输入文本。';

  @override
  String get materialsProblemTooLarge => '过大：素材上限为 1 MiB。';

  @override
  String materialsProblemTooManyEntries(int count) {
    return '条目过多：最多 $count 条。';
  }

  @override
  String materialsProblemEntryTooLong(int count) {
    return '某个条目过长：每条最多 $count 个字符。';
  }

  @override
  String get materialsProblemNothingTrainable => '这里没有可以用莫尔斯码练习的内容。';

  @override
  String get materialsSearch => '搜索素材';

  @override
  String get materialsFavoritesOnly => '收藏';

  @override
  String get materialsFavorite => '加入收藏';

  @override
  String get materialsUnfavorite => '取消收藏';

  @override
  String get materialsEmpty => '还没有素材。添加你自己的文本、单词表或呼号，或保存一条聊天消息。';

  @override
  String materialsItems(int count) {
    return '$count 项';
  }

  @override
  String get materialsFromChat => '来自聊天';

  @override
  String get materialsActions => '素材操作';

  @override
  String get materialsPractise => '练习';

  @override
  String get materialsDelete => '删除';

  @override
  String get materialsDeleteTitle => '删除素材？';

  @override
  String materialsDeleteBody(String title) {
    return '“$title”将从本设备删除，练习记录会保留。';
  }

  @override
  String get materialsImport => '导入 TXT 或 JSON';

  @override
  String get materialsImportDialogTitle => '选择素材文件';

  @override
  String get materialsSaveDialogTitle => '保存素材';

  @override
  String get materialsImportFailed => '导入失败，素材库未改变。';

  @override
  String get materialsImportNotUtf8 => '只能导入 UTF-8 文本文件。';

  @override
  String get materialsImportInvalid => '不是有效的 DitMesh 素材文件，未导入任何内容。';

  @override
  String materialsImported(int count) {
    return '已导入 $count 个素材。';
  }

  @override
  String get materialsDuplicateTitle => '部分素材已存在';

  @override
  String get materialsDuplicateOverwrite => '替换';

  @override
  String get materialsDuplicateKeepCopy => '两者都保留（作为副本导入）';

  @override
  String get materialsDuplicateSkip => '跳过';

  @override
  String get materialsExportJson => '导出为 JSON';

  @override
  String materialsExported(int count) {
    return '已导出 $count 个素材。';
  }

  @override
  String get materialsExportFailed => '导出失败。';

  @override
  String get materialsExportWav => '导出音频（WAV）';

  @override
  String materialsWavCharSpeed(int wpm) {
    return '字符速度：$wpm WPM';
  }

  @override
  String materialsWavEffSpeed(int wpm) {
    return '有效速度：$wpm WPM';
  }

  @override
  String materialsWavTone(int hz) {
    return '音调：$hz Hz';
  }

  @override
  String get materialsWavWithAnswer => '附带答案文本（.txt）';

  @override
  String get materialsWavFormat => '16 位单声道 WAV，48 kHz。';

  @override
  String materialsWavParts(int count) {
    return '超过 10 分钟：将导出为 $count 个文件。';
  }

  @override
  String materialsWavExported(int count) {
    return '已保存 $count 个音频文件。';
  }

  @override
  String get materialsPracticeMode => '练习范围';

  @override
  String get materialsPracticeLearned => '仅已学字符';

  @override
  String materialsPracticeLearnedPartial(int count) {
    return '仅已学字符（$count 项不可用：含尚未学习的字符）';
  }

  @override
  String get materialsPracticeAll => '所有莫尔斯字符';

  @override
  String get materialsPracticeNothing => '此模式下没有可练习的条目。';

  @override
  String get guestTryLearning => '先试试学习';

  @override
  String get guestBanner => '访客学习：进度保存在本设备。聊天需要身份。';

  @override
  String get guestGetIdentity => '设置身份';

  @override
  String get guestIdentityTitle => '需要身份';

  @override
  String get guestIdentityBody => '通过 Tox 聊天需要你自己的身份。可以新建、从备份恢复，或解锁本设备上的身份。新建身份时，访客学习进度会自动转移过去。';

  @override
  String get guestClearData => '清除访客学习数据';

  @override
  String get guestClearDataBody => '删除你在本设备以访客身份产生的进度、计划和素材。不影响任何身份。';

  @override
  String get guestClearConfirm => '清除';

  @override
  String get guestCleared => '已清除访客学习数据。';

  @override
  String get guestClearFailed => '无法清除访客数据。';

  @override
  String get guestMigrationFailed => '身份已就绪，但访客学习进度尚未转移，数据仍安全保存在本设备。';

  @override
  String get guestChoiceBody => '你还有访客学习进度。当前使用的是恢复身份的进度，没有合并任何内容。';

  @override
  String get guestChoiceKeep => '保留恢复的进度';

  @override
  String get guestChoiceUseGuest => '改用访客进度';

  @override
  String get placementTitle => '测试我的水平';

  @override
  String get placementCheckLevel => '测试我现在的水平';

  @override
  String get placementFromZero => '从零开始';

  @override
  String get placementOfferTitle => '刚接触莫尔斯码，还是已经会抄收？';

  @override
  String get placementOfferBody => '简短测试可以建议起点。测试是可选的，在你选择前不会改变任何设置。';

  @override
  String get placementIntro => '约 3–5 分钟，分五步抄收：先按柯赫顺序分组、速度逐级提高，最后是短单词。这只是基于少量样本的粗略参考，不是认证。随时可以停止。';

  @override
  String get placementStart => '开始';

  @override
  String get placementSkip => '跳过';

  @override
  String get placementStop => '停止';

  @override
  String placementTierProgress(int step, int total, int wpm) {
    return '第 $step/$total 步 · 有效速度 $wpm WPM';
  }

  @override
  String get placementTierPassed => '抄得很好，下一步更快。';

  @override
  String get placementTierStopped => '这一步低于 90%，测试到此结束。';

  @override
  String get placementNextTier => '下一步';

  @override
  String placementSuggestion(int lesson) {
    return '建议从第 $lesson 课开始';
  }

  @override
  String placementVerified(int count, int total) {
    return '按顺序确认了 $total 个柯赫字符中的 $count 个。';
  }

  @override
  String get placementLimits => '基于少量样本：未测到的字符仍视为未测试，也不会被标记为已掌握。你可以随时更改课程。';

  @override
  String placementAdopt(int lesson) {
    return '从第 $lesson 课开始';
  }

  @override
  String get chatJumpToLatest => '最新消息';

  @override
  String get chatMessageGone => '该消息已不在此会话中。';

  @override
  String get chatListenOnlyPreview => '新消息——请收听抄收';

  @override
  String get chatSaveMaterialConfirm => '保存其余部分';

  @override
  String materialsImportConfirm(int count) {
    return '导入 $count 个素材？';
  }

  @override
  String get materialsExportTxt => '导出为文本（TXT）';

  @override
  String get accountBackupMediaTitle => '包含已保存的录音吗？';

  @override
  String accountBackupMediaBody(int count, String size) {
    return '已保存 $count 段录音（$size MB）。标题、备注和位置始终在备份中；音频仅在你选择包含时才会加入。';
  }

  @override
  String accountBackupMediaTooLarge(String size) {
    return '已保存的录音（$size MB）太大，无法放入备份；只会包含标题、备注和位置。';
  }

  @override
  String get accountBackupMediaInclude => '包含录音';

  @override
  String get accountBackupMediaSkip => '不含录音';

  @override
  String get diagTitle => '连接诊断';

  @override
  String get diagOpenSubtitle => '消息为何在等待，以及如何重新连接';

  @override
  String get diagBannerDetails => '详情';

  @override
  String get diagSummaryNoIdentity => '尚未打开身份，没有可检查的连接。';

  @override
  String get diagSummaryOnlinePeerOnline => '你已连接到 Tox 网络，且该联系人在线。消息会直接送达对方。';

  @override
  String get diagSummaryOnlinePeerOffline => '你已连接，但该联系人离线。消息会留在本机的待发队列中，对方上线后自动发送。';

  @override
  String get diagSummaryOnline => '你已连接到 Tox 网络。';

  @override
  String get diagSummaryConnecting => '正在连接 Tox 网络。应用启动或网络切换后可能需要一分钟左右。';

  @override
  String get diagSummaryOffline => '你未连接到 Tox 网络。连接恢复前无法收发任何消息。';

  @override
  String get diagLocalLabel => '本机连接';

  @override
  String diagSinceChanged(String time) {
    return '自 $time 起';
  }

  @override
  String diagSinceFirst(String time) {
    return '自 $time 起观察到';
  }

  @override
  String diagSinceResumed(String time) {
    return '自 $time 回到应用后观察到';
  }

  @override
  String get diagLastOnlineLabel => '最近一次观察到的连接';

  @override
  String get diagLastOnlineNow => '当前已连接';

  @override
  String get diagLastOnlineNone => '尚未观察到连接。';

  @override
  String get diagLastOnlineHint => '这是本机最后一次观察到自身连接的时间，并非消息送达对方的时间。';

  @override
  String get diagPeerLabel => '联系人';

  @override
  String get diagUnknown => '未知';

  @override
  String get diagPeerUnknownHint => '只有在你已连接时才能看到联系人是否在线。';

  @override
  String get diagPeerGroupHint => '群成员是否在线请查看成员列表。';

  @override
  String get diagPendingLabel => '待发送';

  @override
  String get diagPendingNone => '没有待发消息';

  @override
  String diagPendingCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 条消息',
    );
    return '$_temp0';
  }

  @override
  String diagPendingOldest(String time) {
    return '最早一条排队于 $time';
  }

  @override
  String get diagPendingUnknown => '聊天连接后才能得知';

  @override
  String get diagPendingHint => '排队的消息保存在本机，对方可达时会自动发送。诊断页面不会丢弃或重发它们。';

  @override
  String get diagReconnect => '重新连接';

  @override
  String get diagReconnecting => '正在重新连接…';

  @override
  String diagReconnectFailed(String reason) {
    return '重新连接失败：$reason';
  }

  @override
  String get diagReconnectNote => '重新连接会重新发起连接尝试。上线仍可能需要一段时间，届时本页会自动更新。';

  @override
  String get diagAboutTitle => 'DitMesh 如何连接';

  @override
  String get diagAboutBody => 'DitMesh 没有服务器。你的设备通过 Tox 点对点网络直接与联系人通信，因此双方必须同时在线消息才能送达。手机会暂停后台应用：DitMesh 在后台无法保持连接，回到应用时会重新连接。';

  @override
  String get diagDetailsTitle => '技术详情';

  @override
  String get diagDetailIdentity => '身份';

  @override
  String get diagDetailStatus => '状态';

  @override
  String get diagDetailObserved => '观察时间';

  @override
  String get diagDetailQueued => '队列条目';

  @override
  String get diagDetailError => '最近错误代码';

  @override
  String get backupXTitle => '加密备份';

  @override
  String get backupXIntro => '选择要带到其他设备的内容。整个文件都会用你在此设置的口令加密。';

  @override
  String get backupXCategoryIdentity => '身份与 Tox 配置文件';

  @override
  String get backupXCategoryTraining => '训练进度与素材';

  @override
  String get backupXCategoryChat => '聊天记录（含给自己的笔记）';

  @override
  String get backupXCategoryMeta => '草稿、置顶与书签';

  @override
  String get backupXCategoryPrefs => '应用偏好设置';

  @override
  String get backupXPrefsHint => '播放、通知、外观与语言。不含窗口位置和按键绑定。';

  @override
  String get backupXCategoryMedia => '已保存的录音';

  @override
  String get backupXMediaHint => '默认不包含：录音可能很大。不包含时只带走标题和备注。';

  @override
  String get backupXCategoryPending => '未发送的消息';

  @override
  String get backupXPendingHint => '恢复后仅供查看，绝不会自动发送。';

  @override
  String get backupXRequired => '必选';

  @override
  String backupXSizeLine(int count, String size) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 项',
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
    return '太大，无法包含（$size）';
  }

  @override
  String backupXInvitesNote(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '有 $count 个等待离线好友的群邀请不会被带走。',
    );
    return '$_temp0';
  }

  @override
  String get backupXIdentityPasswordNote => '身份密码仍保留在配置文件上：新设备除备份口令外还会要求输入它。';

  @override
  String backupXTotal(String size) {
    return '总计约 $size';
  }

  @override
  String get backupXPassphrase => '备份口令';

  @override
  String get backupXPassphraseConfirm => '再次输入口令';

  @override
  String get backupXPassphraseHint => '至少 8 个字符。它与身份密码相互独立，且无法找回。';

  @override
  String get backupXPassphraseTooShort => '请至少使用 8 个字符';

  @override
  String get backupXPassphraseMismatch => '两次输入的口令不一致';

  @override
  String get backupXExport => '创建加密备份';

  @override
  String get backupXExporting => '正在创建备份…';

  @override
  String get backupXMigrationNote => '要换设备？在新设备恢复后，请停止在本机使用此身份：同一身份的两台设备可能把同一条消息发送两次。';

  @override
  String get backupXBusy => '备份过程中数据持续变化，请重试。';

  @override
  String get backupXTooLarge => '备份太大。请去掉录音后重试。';

  @override
  String get restoreXWrongPassphrase => '口令错误，或文件已被修改、不完整。';

  @override
  String get restoreXUnsupported => '此备份由更新版本的 DitMesh 创建。';

  @override
  String get restoreXCheck => '打开备份';

  @override
  String get restoreXPreviewTitle => '备份内容';

  @override
  String restoreXCreated(String date) {
    return '创建于 $date';
  }

  @override
  String get restoreXIncluded => '包含';

  @override
  String get restoreXExcluded => '不在此备份中';

  @override
  String restoreXPendingIncluded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 条未发送的消息将恢复供你查看，不会自动发送。',
    );
    return '$_temp0';
  }

  @override
  String restoreXPendingExcluded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '旧设备上的 $count 条未发送消息不在此备份中。',
    );
    return '$_temp0';
  }

  @override
  String get restoreXIdentityPassword => '身份密码';

  @override
  String get restoreXIdentityPasswordNote => '此备份中的身份另设有密码，请一并输入。';

  @override
  String get restoreXConfirmTitle => '替换本机上的身份？';

  @override
  String get restoreXConfirmBody => '本机上的身份和数据将被备份替换。在此连接之前，请先停止在旧设备上使用该身份。';

  @override
  String get restoreXConfirm => '替换并恢复';

  @override
  String get restoreXReportTitle => '恢复完成';

  @override
  String get restoreXReportRestored => '已恢复';

  @override
  String get restoreXReportNotIncluded => '未恢复';

  @override
  String get restoreXReportPrefsFailed => '偏好设置未能应用，已保留原有设置。';

  @override
  String restoreXReportPendingReview(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '有 $count 条未发送的消息在“聊天”中等你查看。',
    );
    return '$_temp0';
  }

  @override
  String restoreXReportPendingNotResumed(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '旧设备上的 $count 条未发送消息未被带过来。',
    );
    return '$_temp0';
  }

  @override
  String restoreXReportInvites(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '有 $count 个排队中的群邀请未重新发送。',
    );
    return '$_temp0';
  }

  @override
  String get restoreXReportStopOld => '请停止在旧设备上使用此身份。';

  @override
  String get restoreXReportDone => '完成';

  @override
  String pendingReviewBanner(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '来自旧设备的 $count 条未发送消息',
    );
    return '$_temp0';
  }

  @override
  String get pendingReviewTitle => '未发送的消息';

  @override
  String get pendingReviewBody => '这些消息在旧设备上等待发送。DitMesh 绝不会自动发送；如仍需要，请重新拍发。';

  @override
  String pendingReviewQueuedAt(String time) {
    return '于 $time 在旧设备上排队';
  }

  @override
  String get pendingReviewDismiss => '忽略';

  @override
  String get pendingReviewDismissAll => '全部忽略';

  @override
  String get pendingReviewEmpty => '没有需要查看的内容了。';

  @override
  String get backupXWizardInside => '备份文件会用你自选的口令整体加密，包含身份密钥和训练进度。请把文件和口令保存在本机以外的安全位置。';

  @override
  String get backupXMeSubtitle => '包含身份、聊天和进度的加密文件，可留存或迁移到其他设备';

  @override
  String get conditionsTitle => '收听环境';

  @override
  String get conditionsClear => '清晰';

  @override
  String get conditionsLight => '轻度干扰';

  @override
  String get conditionsRadio => '实战电台';

  @override
  String get conditionsClearHint => '干净稳定的音调，即普通练习。';

  @override
  String get conditionsLightHint => '轻微底噪和缓慢衰落。成绩与清晰练习分开记录。';

  @override
  String get conditionsRadioHint => '噪声、深度衰落、邻近电台干扰和略不均匀的节奏。成绩与清晰练习分开记录。';

  @override
  String get conditionsPreview => '试听';

  @override
  String conditionsActive(String name) {
    return '收听环境：$name';
  }

  @override
  String get conditionsNeedSound => '电台环境只能听不能看：请在训练设置中打开声音，或改用“清晰”环境练习。';

  @override
  String get conditionsCleanReplay => '无效果重播';

  @override
  String conditionsComparable(int count, int accuracy) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '在此环境和速度下共 $count 次：平均 $accuracy%',
    );
    return '$_temp0';
  }

  @override
  String get conditionsSeparateNote => '电台环境练习计入活动，但不会改变课程进度、复习计划或速度建议。';

  @override
  String get keysTitle => '按键与外接电键';

  @override
  String get keysMeSubtitle => '按键绑定、双桨与 USB 电键适配器';

  @override
  String get keysIntro => '选择用哪些键拍发莫尔斯。模拟键盘的 USB 电键/双桨适配器与键盘相同，请在此设置其按键。应用无法分辨按键来自哪个设备，因此配置方案就是一组按键绑定。';

  @override
  String get keysStandardProfile => '标准';

  @override
  String get keysUnnamed => '未命名方案';

  @override
  String get keysEdit => '编辑';

  @override
  String get keysNewProfile => '新建方案';

  @override
  String get keysLimitations => '不支持 MIDI、串口和蓝牙电键，也不支持适配器固件设置和电台控制。已测试的适配器列在文档中。';

  @override
  String get keysEditTitle => '按键方案';

  @override
  String get keysName => '方案名称';

  @override
  String get keysActionStraight => '手键';

  @override
  String get keysActionDit => '点桨';

  @override
  String get keysActionDah => '划桨';

  @override
  String get keysPressKey => '请按一个键…';

  @override
  String get keysNone => '未设置';

  @override
  String get keysSet => '设置';

  @override
  String keysReserved(String key) {
    return '$key 已被系统或应用占用，请换一个键。';
  }

  @override
  String keysConflict(String key, String action) {
    return '$key 已用于“$action”。';
  }

  @override
  String keysConflictSave(String keys) {
    return '每个键只能有一种用途：$keys 被重复绑定。';
  }

  @override
  String get keysMissing => '请设置此电键模式需要的键（自动键需同时设置两只桨）。';

  @override
  String get keysSwapPaddles => '交换双桨（左手）';

  @override
  String get keysKeyerMode => '电键模式';

  @override
  String get keysIambicA => '自动键 A';

  @override
  String get keysIambicB => '自动键 B';

  @override
  String get keysAdapterKeyer => '适配器自行生成点划';

  @override
  String get keysAdapterKeyerHint => '适用于自带电键逻辑的适配器：直接使用它计时好的按下和松开，应用不会再生成一遍自动键序列。';

  @override
  String get keysAppSidetone => '拍发时的应用侧音';

  @override
  String get keysAppSidetoneHint => '适配器自带侧音时请关闭。不影响解码。';

  @override
  String get keysTestTitle => '测试';

  @override
  String get keysTestNote => '仅用于测试：不会发送，也不计入训练。';

  @override
  String get keysTestRelease => '释放按键';

  @override
  String get keysAdapterActive => '正在使用适配器自带的电键逻辑：桨对应的键按手键处理。';

  @override
  String keysHintCustom(String keys) {
    return '按键：$keys';
  }

  @override
  String get telegraphTitle => '中文电码';

  @override
  String get telegraphIntro => '每个汉字以四位数字码拍发。分别练习听写数字，以及记住哪个码对应哪个字。';

  @override
  String get telegraphCodebook => '码本';

  @override
  String get telegraphCodebookMainland => '大陆';

  @override
  String get telegraphCodebookTaiwan => '台湾';

  @override
  String get telegraphDigitsTitle => '抄收电码组';

  @override
  String get telegraphDigitsHint => '收听真实电码的四位数字组并输入数字。';

  @override
  String telegraphDigitsResults(int count, int accuracy) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '共 $count 次：数字正确率 $accuracy%',
    );
    return '$_temp0';
  }

  @override
  String get telegraphRecallTitle => '记忆码本';

  @override
  String get telegraphRecallHint => '由字查码、由码认字。与莫尔斯进度分开记录。';

  @override
  String telegraphRecallResults(int count, int accuracy) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '已答 $count 张：掌握 $accuracy%',
    );
    return '$_temp0';
  }

  @override
  String get telegraphSeparateNote => '码本记忆不会解锁莫尔斯课程，也不改变速度建议；数字抄收与其他莫尔斯抄收同等计入。';

  @override
  String get telegraphRecallCharPrompt => '输入这个字的电码';

  @override
  String get telegraphRecallCodePrompt => '选出这个电码对应的字';

  @override
  String get telegraphReveal => '显示答案';

  @override
  String get telegraphRevealAssisted => '已显示：本题计为有提示。';

  @override
  String get telegraphCorrect => '正确';

  @override
  String get telegraphIncorrect => '不对';

  @override
  String telegraphRecallSummary(int correct, int total) {
    return '$total 题中答对 $correct 题';
  }

  @override
  String telegraphRecallAssisted(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '有 $count 题看过答案',
    );
    return '$_temp0';
  }

  @override
  String get telegraphInterpretAction => '按中文电码解读';

  @override
  String get telegraphInterpretTitle => '电码解读';

  @override
  String get telegraphInterpretNote => '仅在此显示：不会修改原消息，也不会发送任何内容。';

  @override
  String get telegraphUnresolved => '无法解读：没有字对应此码';

  @override
  String get telegraphMalformed => '不是四位数字组';

  @override
  String get telegraphNotCode => '文字，保持原样';

  @override
  String get telegraphAmbiguous => '多个字共用此码';

  @override
  String get groupPracticeTitle => '群组带练';

  @override
  String get groupPracticeIntro => '带练者照常在群聊中拍发练习内容。每位成员在此选择练习消息，按自己的速度抄收。答案和成绩只保存在本机，不会发送到群里。';

  @override
  String get groupPracticeNew => '新建练习';

  @override
  String get groupPracticeTitleField => '标题';

  @override
  String get groupPracticeCreate => '创建';

  @override
  String get groupPracticeInstructor => '带练者';

  @override
  String get groupPracticeParticipant => '参与者';

  @override
  String get groupPracticeInstructorHint => '在群聊中拍发每道练习，在此添加为一轮并勾选完成；轮次请在群聊里通知。';

  @override
  String get groupPracticeParticipantHint => '把带练者的练习消息添加为轮次，并在此逐一抄收。';

  @override
  String get groupPracticeLocalNote => '仅限本机：轮次、角色和成绩不会与其他成员同步，错过的消息也不一定能送达所有人。';

  @override
  String get groupPracticeAddRound => '添加练习';

  @override
  String get groupPracticeNoMessages => '最近记录中没有可添加的消息。';

  @override
  String get groupPracticeNotConnected => '聊天连接后才能读取群记录。';

  @override
  String get groupPracticeRoundOpen => '待完成';

  @override
  String get groupPracticeRoundDone => '已完成';

  @override
  String get groupPracticeRoundUnavailable => '不可用';

  @override
  String get groupPracticeSourceGone => '该练习消息已不在记录中。';

  @override
  String get groupPracticeSourceLoading => '正在查找消息…';

  @override
  String groupPracticeAttemptResult(int accuracy, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '抄收：$accuracy%（$count 次）',
    );
    return '$_temp0';
  }

  @override
  String get groupPracticeCopy => '抄收';

  @override
  String get groupPracticeRemoveRound => '移除本轮';

  @override
  String get groupPracticeSummary => '小结';

  @override
  String groupPracticeRoundsDone(int done, int total) {
    return '已完成 $done/$total 轮';
  }

  @override
  String groupPracticeUnavailableCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 轮不可用',
    );
    return '$_temp0';
  }

  @override
  String groupPracticeAccuracy(int accuracy) {
    return '抄收正确率：$accuracy%';
  }

  @override
  String groupPracticeAssisted(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 次使用了提示',
    );
    return '$_temp0';
  }

  @override
  String groupPracticeShareHint(int done, int total, int accuracy) {
    return '如需分享，请自行在群聊中拍发成绩，例如 $done/$total $accuracy%。不会自动发送。';
  }

  @override
  String get groupPracticeComplete => '结束练习';

  @override
  String get groupPracticeDeleteTitle => '删除这次练习？';

  @override
  String get groupPracticeDeleteBody => '本机上的轮次和成绩将被删除；训练记录和群消息保留。';

  @override
  String get conditionsAudioFailed => '本设备无法播放音频。请改用“清晰”环境练习。';

  @override
  String get moderationBlock => '屏蔽';

  @override
  String moderationBlockTitle(String name) {
    return '屏蔽 $name？';
  }

  @override
  String get moderationBlockFriendBody => '对方将被移出好友，与其的会话也会被删除。此后其消息、好友请求和群组邀请都不会再出现在此设备上。对方不会收到通知。';

  @override
  String get moderationBlockMemberBody => '此后其在本群组的消息都不会再出现在此设备上。对方不会收到通知。Tox 为每位群成员在每个群组中使用不同的密钥，因此仅对本群组生效。';

  @override
  String get moderationBlocked => '已屏蔽';

  @override
  String get moderationUnblock => '解除屏蔽';

  @override
  String get moderationUnblocked => '已解除屏蔽';

  @override
  String get moderationBlockedTitle => '已屏蔽的人';

  @override
  String get moderationBlockedSubtitle => '隐藏其消息、请求和邀请';

  @override
  String get moderationBlockedEmpty => '你还没有屏蔽任何人。';

  @override
  String get moderationBlockedNote => '屏蔽在此设备上生效：Tox 没有中心服务器，被屏蔽的人仍可能尝试联系你，但他们的任何内容都不会在这里显示。';

  @override
  String get termsGateTitle => '社区准则';

  @override
  String get termsGateIntro => 'DitMesh 聊天让你与他人直接连接，中间没有服务器。开始之前，请同意以下规则：';

  @override
  String get termsGateRuleZero => '零容忍：禁止骚扰、仇恨、威胁、涉及未成年人的性内容、垃圾信息以及任何违法内容。';

  @override
  String get termsGateRuleContacts => '只有你接受的人才能给你发消息；群组须通过邀请或群组 ID 加入。';

  @override
  String get termsGateRuleBlock => '可以在会话、群成员列表、好友请求或群组邀请中屏蔽任何人。';

  @override
  String get termsGateAgree => '同意并继续';

  @override
  String get termsGateReadFull => '阅读完整使用条款';

  @override
  String get termsGateSaveFailed => '无法保存你的选择，请重试。';

  @override
  String get aboutPrivacyPolicy => '隐私政策';

  @override
  String get aboutTermsOfUse => '使用条款';

  @override
  String get aboutSupport => '技术支持与联系';

  @override
  String get aboutLinkFailed => '无法打开链接，已复制链接。';

  @override
  String get errorPeerBlocked => '你已屏蔽此人。请先在“我 → 已屏蔽的人”中解除屏蔽。';

  @override
  String get offlineClearData => '清除学习数据';

  @override
  String get offlineClearDataBody => '删除此设备上的学习进度、计划和材料。';

  @override
  String get offlineCleared => '学习数据已清除。';

  @override
  String get offlineClearFailed => '无法清除学习数据。';

  @override
  String get learnStorageUnavailable => '无法在此设备上打开你的训练数据，请重试。';

  @override
  String get backendStartupFailedTitle => '聊天后端不可用';

  @override
  String get backendStartupFailedBody => 'DitMesh 无法启动 Tox 网络后端。请确认原生库已安装，然后重试。';

  @override
  String get bootstrapTitle => '网络与引导节点';

  @override
  String get bootstrapDescription => '选择加入 Tox 网络所使用的公共节点。';

  @override
  String get bootstrapModeAuto => '自动';

  @override
  String get bootstrapModeManual => '手动';

  @override
  String get bootstrapModeLan => 'LAN 托管';

  @override
  String get bootstrapAutoDescription => '先使用内置节点，再在后台刷新官方列表。';

  @override
  String get bootstrapManualDescription => '只使用你选择的节点，也可在此填写局域网节点。';

  @override
  String get bootstrapLanDescription => '在此桌面设备上运行本地 UDP/DHT 节点，供其他局域网设备使用。';

  @override
  String get bootstrapCurrentNode => '当前节点';

  @override
  String get bootstrapHost => '主机名或 IP 地址';

  @override
  String get bootstrapPort => 'UDP 端口';

  @override
  String get bootstrapPublicKey => 'DHT 公钥';

  @override
  String get bootstrapTestNode => '测试节点';

  @override
  String get bootstrapSaveNode => '使用已测试节点';

  @override
  String get bootstrapChooseNode => '选择公共节点';

  @override
  String get bootstrapReachable => '已收到 DHT 响应';

  @override
  String get bootstrapUnreachable => '未收到 DHT 响应';

  @override
  String get bootstrapInvalid => '主机、端口或公钥无效';

  @override
  String get bootstrapUdpUnavailable => '此设备无法进行 UDP 探测，未测试 TCP 连通性。';

  @override
  String get bootstrapProbeUnavailable => '探测无法启动，这不能说明节点是否可达。';

  @override
  String get bootstrapFallback => '无法加载官方列表，正在显示内置备用节点。';

  @override
  String get bootstrapMaintainer => '维护者';

  @override
  String get bootstrapLocation => '位置';

  @override
  String get bootstrapLastPing => '最近公共检查';

  @override
  String get bootstrapSwitchTitle => '切换引导节点';

  @override
  String get bootstrapSwitchQuestion => '使用此节点？';

  @override
  String get bootstrapNotTestedWarning => '此节点尚未在你的设备上测试。';

  @override
  String get bootstrapFailedWarning => '此节点未响应 UDP 探测，你仍然可以选择它。';

  @override
  String get bootstrapInconclusiveWarning => '探测没有明确结论，未测试 TCP 连通性。';

  @override
  String get bootstrapSwitchConfirm => '使用节点';

  @override
  String get bootstrapRefresh => '刷新列表';

  @override
  String get bootstrapStartLan => '启动 LAN 节点';

  @override
  String get bootstrapStopLan => '停止 LAN 节点';

  @override
  String get bootstrapLanStopped => 'LAN 节点已停止';

  @override
  String get bootstrapLanRunning => 'LAN 节点正在运行';

  @override
  String get bootstrapLanKeyChanges => '节点重启后 DHT 公钥会变化，请分享当前完整公钥。';

  @override
  String get bootstrapLanFirewallHint => '其他设备需要通过本地防火墙访问此 UDP 端口。';

  @override
  String get bootstrapCopyNode => '复制节点信息';

  @override
  String get bootstrapShareNode => '分享节点信息';

  @override
  String get bootstrapOperationFailed => '无法应用此网络设置。';

  @override
  String get bootstrapServiceUnavailable => '此后端无法使用网络设置。';

  @override
  String get bootstrapSource => '官方公共节点列表';

  @override
  String get bootstrapOnline => '在线';

  @override
  String get bootstrapOffline => '离线';

  @override
  String bootstrapProtocolStatus(String udp, String tcp) {
    return 'UDP：$udp · TCP：$tcp';
  }

  @override
  String get errorNotFriend => '对方已不在你的好友列表中。重新添加后才能发送消息。';

  @override
  String get chatAcceptWithPassword => '使用密码接受';

  @override
  String chatGroupPasswordTitle(String name) {
    return '$name 的密码';
  }

  @override
  String get chatGroupPasswordField => '群组密码';

  @override
  String chatGroupJoinRefusedPassword(String name) {
    return '$name 拒绝了加入：密码错误或未填写。';
  }

  @override
  String chatGroupJoinRefusedFull(String name) {
    return '$name 拒绝了加入：群组已满。';
  }

  @override
  String chatGroupJoinRefused(String name) {
    return '$name 拒绝了加入。';
  }

  @override
  String chatGroupReconnectRefused(String name) {
    return '$name 拒绝了重新连接。历史记录已保留；请使用群组密码重试。';
  }

  @override
  String get firstChatTitle => '第一次电码聊天';

  @override
  String get firstChatStart => '开始体验';

  @override
  String get firstChatDismiss => '收起引导';

  @override
  String get firstChatKeyTitle => '1. 给自己拍发 CQ';

  @override
  String get firstChatKeyBody => '用电键拍发 CQ：短按是点，长按是划。解码后的草稿保持只读。';

  @override
  String get firstChatSelf => '在发给自己中试一试';

  @override
  String get firstChatListenTitle => '2. 试听与纠错';

  @override
  String get firstChatListenBody => '发送前点试听来听草稿，用退格删除错误。发送后点消息上的播放按钮。发给自己的消息只保存在本机。';

  @override
  String get firstChatFriendTitle => '3. 与好友聊天';

  @override
  String get firstChatFriendBody => '打开联系人，通过二维码或 Tox ID 添加好友，等待对方接受申请。';

  @override
  String get firstChatFriend => '添加好友';

  @override
  String get firstChatOnline => '双方应用都保持运行且网络可达时，消息才能送到好友。';

  @override
  String get pendingMessagesTitle => '待发送与失败消息';

  @override
  String get pendingMessagesExplanation => '排队消息保存在本机，双方应用连接后继续发送。你可以取消排队消息，或重试已确认失败的消息。';

  @override
  String get pendingMessagesEmpty => '没有待发送或失败消息';

  @override
  String get deliveryDetailsTitle => '投递详情';

  @override
  String get deliveryLocalTitle => '已保存到本机';

  @override
  String get deliveryLocalDetail => '这条发给自己的消息已保存在本机。';

  @override
  String get deliverySentDetail => '本机已把消息交给传输层，正在等待对端确认接收。';

  @override
  String get deliveryPeerTitle => '对端已接收';

  @override
  String get deliveryPeerDetail => '对端已确认接收；这不代表对方已经阅读或收听。';

  @override
  String get deliveryGroupTitle => '群成员已接收';

  @override
  String get deliveryGroupDetail => '至少一名群成员已确认接收，其他成员仍可能离线。';

  @override
  String get deliveryLocalOffline => '本机尚未连接到网络。';

  @override
  String get deliveryPeerOffline => '好友目前离线。';

  @override
  String get deliveryGroupWaiting => '正在等待连接到群组。';

  @override
  String get chatPreviewDraft => '试听草稿';

  @override
  String get chatStopPreview => '停止试听';

  @override
  String get chatMessagePlayback => '消息播放器';

  @override
  String get chatOriginalRhythm => '原始拍发节奏';

  @override
  String get chatListenerRhythm => '我的收听速度';

  @override
  String get chatOriginalAvailable => '已保存实际按键与间隔时长。';

  @override
  String get chatOriginalUnavailable => '无可用原始节奏，将按你的收听速度播放。';

  @override
  String get chatOriginalPlaying => '正在播放原始节奏';

  @override
  String get chatListenerPlaying => '正在按你的收听速度播放';

  @override
  String get chatPause => '暂停';

  @override
  String get chatResume => '继续';

  @override
  String get chatPreviousWord => '上一词';

  @override
  String get chatNextWord => '下一词';

  @override
  String chatWordNumber(int number) {
    return '第 $number 词';
  }

  @override
  String get chatRangeStart => '起始词';

  @override
  String get chatRangeEnd => '结束词';

  @override
  String get chatRepeatRange => '重播选定词段';

  @override
  String get chatLoopRange => '循环选定词段';

  @override
  String get chatPlaybackProgress => '播放进度';

  @override
  String chatWordProgress(int current, int total) {
    return '第 $current / $total 词';
  }

  @override
  String get chatOriginalPreference => '有匹配的录音时使用原始拍发节奏。';

  @override
  String chatConversationActions(String name) {
    return '$name 的操作';
  }

  @override
  String get chatDraftSaveFailed => '草稿未能保存。请保持此页面打开，或立即发送。';

  @override
  String get chatSearchClearDates => '清除日期范围';

  @override
  String chatGroupReconnectFailed(String name) {
    return '$name 拒绝了重新连接。历史记录已保留；可以重试。';
  }
}

/// The translations for Chinese, using the Han script (`zh_Hant`).
class SZhHant extends SZh {
  SZhHant(): super('zh_Hant');

  @override
  String get appName => 'DitMesh';

  @override
  String get navLearn => '學習';

  @override
  String get navChat => '聊天';

  @override
  String get navGroups => '群組';

  @override
  String get navMe => '我';

  @override
  String get navReference => '參考';

  @override
  String get navLearnDescription => 'Koch 課程、發報練習與聽抄練習。';

  @override
  String get navChatDescription => '基於 Tox P2P 的無伺服器一對一摩斯通聯。';

  @override
  String get navGroupsDescription => '群組網路 — 多位報務員在同一共享頻道上拍發。';

  @override
  String get navReferenceDescription => '字母表、規程符號、Q 簡語、縮寫，以及雙向翻譯器。';

  @override
  String get navMeDescription => '你的呼號、Tox 身分、進度與設定。';

  @override
  String get shellOfflineBanner => '離線：未連線至 Tox 網路。重新上線後便會傳送訊息。';

  @override
  String get actionOk => '確定';

  @override
  String get actionCancel => '取消';

  @override
  String get actionSave => '儲存';

  @override
  String get actionDelete => '刪除';

  @override
  String get actionCopy => '複製';

  @override
  String get actionShare => '分享';

  @override
  String get actionRetry => '重試';

  @override
  String get actionClose => '關閉';

  @override
  String get actionSearch => '搜尋';

  @override
  String get actionSettings => '設定';

  @override
  String get connectionConnecting => '連線中…';

  @override
  String get connectionOnline => '上線';

  @override
  String get connectionOffline => '離線';

  @override
  String get messageStatusPending => '已在本機排隊';

  @override
  String get messageStatusPendingDetail => '訊息已儲存在本機，雙方應用程式同時執行且網路可達時會繼續傳送。';

  @override
  String get messageStatusSending => '傳送中';

  @override
  String get messageStatusSent => '已傳送';

  @override
  String get messageStatusFailed => '傳送失敗';

  @override
  String get errorWrongPassword => '密碼錯誤，請重試。';

  @override
  String get errorPeerOffline => '該聯絡人離線。Tox 沒有伺服器，訊息會等到對方上線後再送達。';

  @override
  String get errorInvalidToxId => '這不是有效的 Tox ID（應為 76 位十六進位字元）。';

  @override
  String get errorAlreadyFriend => '這個 Tox ID 已在你的好友列表中。';

  @override
  String get errorOwnId => '這是你自己的 Tox ID。';

  @override
  String get errorGroupNotFound => '未找到該群組。';

  @override
  String get errorMessageTooLong => '訊息超出單條 Tox 訊息的長度上限。';

  @override
  String get errorUnknown => '出了點問題';

  @override
  String get errorTeardownUnconfirmed => '上一個 Tox 工作階段尚未完全停止。請稍後重試，或重新啟動應用程式。';

  @override
  String get errorIdentityRecoveryPending => '上一個身分仍在等待復原。請重新啟動應用程式重試，或刪除身分資料後重新開始。';

  @override
  String get languageTitle => '語言';

  @override
  String get languageSystemDefault => '跟隨系統';

  @override
  String get languageSaveFailed => '無法儲存語言設定，請重試。';

  @override
  String learnLessonOf(int lesson, int total) {
    return '第 $lesson 課 / 共 $total 課';
  }

  @override
  String learnCharsLearned(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '已學 $count 個字元',
    );
    return '$_temp0';
  }

  @override
  String learnDailyGoalProgress(int done, int goal) {
    return '$done / $goal 字元';
  }

  @override
  String learnStreakDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '連續練習 $days 天',
    );
    return '$_temp0';
  }

  @override
  String learnReviewDueCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 個待複習',
      zero: '暫無待複習',
    );
    return '$_temp0';
  }

  @override
  String learnRoundScore(int correct, int total) {
    return '$total 個中抄對 $correct 個';
  }

  @override
  String learnRoundOf(int round) {
    return '第 $round 輪';
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
      other: '已發 $count 個字元',
    );
    return '$_temp0';
  }

  @override
  String learnLessonUnlocked(String char) {
    return '已解鎖新字元：$char';
  }

  @override
  String learnConfusedMissed(String target) {
    return '$target 漏抄';
  }

  @override
  String learnConfusedAs(String target, String answered) {
    return '$target 聽成了 $answered';
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
      other: '$count 個字元',
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
      other: '已學 $count 個字元',
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
      other: '抄收 $count 個字元',
    );
    return '$_temp0';
  }

  @override
  String statsSessions(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 次練習',
    );
    return '$_temp0';
  }

  @override
  String statsDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 天',
    );
    return '$_temp0';
  }

  @override
  String statsBestStreak(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '最長連續 $count 天',
    );
    return '$_temp0';
  }

  @override
  String statsGoalProgress(int done, int goal) {
    return '$done / $goal 字元';
  }

  @override
  String statsGoalRemaining(int remaining) {
    String _temp0 = intl.Intl.pluralLogic(
      remaining,
      locale: localeName,
      other: '還差 $remaining 個字元',
    );
    return '$_temp0';
  }

  @override
  String statsTrendSubtitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '最近 $count 次練習',
      one: '最近一次練習',
    );
    return '$_temp0';
  }

  @override
  String statsTooltipSession(int index, int total) {
    return '第 $index 次練習 / 共 $total 次';
  }

  @override
  String statsTooltipCopied(int correct, int total) {
    return '$correct / $total 正確';
  }

  @override
  String statsTooltipLesson(int lesson) {
    return '第 $lesson 課';
  }

  @override
  String statsAttempts(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 次嘗試',
    );
    return '$_temp0';
  }

  @override
  String statsCorrectOf(int correct, int attempts) {
    return '$attempts 次中對 $correct 次';
  }

  @override
  String statsLessonIntroduced(int lesson) {
    return '在第 $lesson 課引入';
  }

  @override
  String statsSrsBox(int box, int maxBox) {
    return '第 $box 盒 / 共 $maxBox 盒';
  }

  @override
  String statsSrsDueIn(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days 天後到期',
      one: '明天到期',
    );
    return '$_temp0';
  }

  @override
  String statsTimes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 次',
    );
    return '$_temp0';
  }

  @override
  String statsHeatmapCell(String target, String answered, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 次',
    );
    return '$target 被答成 $answered，$_temp0';
  }

  @override
  String statsCalendarDay(String date, int chars) {
    String _temp0 = intl.Intl.pluralLogic(
      chars,
      locale: localeName,
      other: '$chars 個字元',
      zero: '未練習',
    );
    return '$date：$_temp0';
  }

  @override
  String statsActiveDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 個活躍日',
    );
    return '$_temp0';
  }

  @override
  String referenceEntryCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 條',
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
    return '已跳過（無摩斯電碼）：$chars';
  }

  @override
  String referenceKochPositionValue(int position) {
    return 'Koch 序號：$position';
  }

  @override
  String referenceEstimatedSpeed(String wpm) {
    return '估計 $wpm WPM';
  }

  @override
  String get accountCopied => 'Tox ID 已複製到剪貼簿';

  @override
  String get accountShowQr => '顯示QR 碼';

  @override
  String get accountToxId => 'Tox ID';

  @override
  String get accountDisplayName => '顯示名稱';

  @override
  String get accountDisplayNameHint => '你的呼號或暱稱';

  @override
  String get accountDisplayNameRequired => '請輸入顯示名稱';

  @override
  String get accountStatusMessage => '狀態訊息';

  @override
  String get accountPassword => '密碼';

  @override
  String get accountPasswordOptional => '密碼（可選）';

  @override
  String get accountConfirmPassword => '確認密碼';

  @override
  String get accountPasswordsDoNotMatch => '兩次輸入的密碼不一致';

  @override
  String get accountShowPassword => '顯示密碼';

  @override
  String get accountHidePassword => '隱藏密碼';

  @override
  String get accountStrengthWeak => '弱：至少使用 8 個字元';

  @override
  String get accountStrengthFair => '一般：12 個以上字元並混合多種類型更好';

  @override
  String get accountStrengthStrong => '強';

  @override
  String get accountStartupInspecting => '正在檢查你的身分…';

  @override
  String get accountStartupOpening => '正在開啟你的身分…';

  @override
  String get accountStartupFailedTitle => '無法啟動';

  @override
  String get accountStartupFailedBody => 'DitMesh 無法讀取你的身分。沒有做任何更改；你可以重試。';

  @override
  String get accountConnectionTapToReconnect => '點按重新連線';

  @override
  String get accountWelcomeTitle => '你的身分只儲存在這台裝置上';

  @override
  String get accountWelcomeIntro => 'DitMesh 使用 Tox 點對點網路。沒有伺服器，也無需註冊帳號：你的身分是一對只儲存在本機的密鑰。';

  @override
  String get accountWelcomePointNoServer => '沒有伺服器，不需要手機號或電子郵件。報務員之間直接用摩斯電碼通聯。';

  @override
  String get accountWelcomePointTraining => '使用直鍵或雙槳鍵拍發 Morse code，進行單聊和群聊。';

  @override
  String get accountWelcomePointBackup => '沒有人能為你找回身分。建立後請立即備份，以免裝置遺失時連同身分一起遺失。';

  @override
  String get accountCreateIdentity => '建立身分';

  @override
  String get accountRestoreFromBackup => '從備份還原';

  @override
  String get accountCreateTitle => '建立你的身分';

  @override
  String get accountCreateBody => '取一個別人能看到的名字。密碼用於加密本機上的身分檔案；如果你希望不輸密碼就能開啟應用程式，可以留空。';

  @override
  String get accountCreateButton => '建立';

  @override
  String get accountCreating => '建立中…';

  @override
  String get accountBackupTitle => '現在就備份你的身分';

  @override
  String get accountBackupBody => '你的身分只存在於這台裝置上。若裝置遺失、重設或遭竊，身分將無法找回：聯絡人不會認出新的身分，訓練進度也會遺失。';

  @override
  String get accountBackupWhatIsInside => '備份檔案包含以密碼加密的身分金鑰和你的訓練進度。請把它儲存在本機以外的安全位置。';

  @override
  String get accountBackupWhatIsInsidePlain => '備份檔案包含未加密的身分金鑰和你的訓練進度。取得這個檔案的人都能使用你的身分：如需加密金鑰，請先設定密碼，並把檔案儲存在安全位置。';

  @override
  String get accountPasswordScope => '密碼用於加密你的身分金鑰。訊息記錄在磁碟上仍未加密，可藉由裝置加密來保護。';

  @override
  String get accountSectionNotifications => '通知';

  @override
  String get accountNotificationsEnable => '顯示通知';

  @override
  String get accountNotificationsEnableSubtitle => '新訊息、好友請求和群組邀請';

  @override
  String get accountNotificationsContent => '顯示訊息內容';

  @override
  String get accountNotificationsContentSubtitle => '在橫幅和鎖定畫面上顯示文字和摩斯碼。關閉後只提示收到了訊息。';

  @override
  String get accountNotificationsAllow => '允許通知';

  @override
  String get accountNotificationsAllowSubtitle => '向系統請求通知權限';

  @override
  String get accountNotificationsBlocked => '已在系統設定中封鎖';

  @override
  String get accountNotificationsBlockedSubtitle => 'DitMesh 的訊息通知已在系統設定中關閉。請在系統設定中重新開啟。';

  @override
  String get accountNotificationsDenied => 'DitMesh 的通知已在系統設定中關閉。';

  @override
  String get accountBackupSaveFile => '儲存備份檔案';

  @override
  String get accountBackupShareFile => '分享備份檔案';

  @override
  String get accountBackupSaved => '備份已儲存';

  @override
  String get accountBackupNotSaved => '備份未儲存';

  @override
  String get accountBackupFailed => '無法寫入備份';

  @override
  String get accountBackupAcknowledge => '我瞭解：沒有這份備份，我的身分將無法找回。';

  @override
  String get accountBackupContinue => '進入 DitMesh';

  @override
  String get accountBackupShowQrHint => '朋友通過你的 Tox ID 新增你。可以以文字或QR 碼的形式分享。';

  @override
  String get accountRestoreTitle => '從備份還原';

  @override
  String get accountRestoreBody => '選擇一個由 DitMesh 匯出的備份檔案。如果該身分設定了密碼，這裡需要輸入。';

  @override
  String get accountRestoreChooseFile => '選擇備份檔案';

  @override
  String get accountRestoreNoFile => '請先選擇備份檔案';

  @override
  String get accountRestoreButton => '還原';

  @override
  String get accountRestoring => '還原中…';

  @override
  String get accountRestoreInvalidFile => '這個檔案不是 DitMesh 備份。';

  @override
  String get accountRestoreReplacesWarning => '還原將替換當前裝置上的身分。';

  @override
  String get accountUnlockTitle => '解鎖你的身分';

  @override
  String get accountUnlockBody => '你的身分檔案已加密。請輸入密碼繼續。';

  @override
  String get accountUnlockButton => '解鎖';

  @override
  String get accountUnlocking => '解鎖中…';

  @override
  String get accountUnlockRestoreInstead => '改為從備份還原';

  @override
  String get accountMeNoIdentity => '未載入身分';

  @override
  String get accountSectionAccount => '帳戶';

  @override
  String get accountSectionTraining => '訓練';

  @override
  String get accountSectionAbout => '關於';

  @override
  String get accountSectionDanger => '危險操作';

  @override
  String get accountEditProfile => '編輯資料';

  @override
  String get accountEditProfileBody => '會顯示給 Tox 網路上的聯絡人。';

  @override
  String get accountSetPassword => '設定密碼';

  @override
  String get accountChangePassword => '修改密碼';

  @override
  String get accountRemovePassword => '移除密碼';

  @override
  String get accountCurrentPassword => '當前密碼';

  @override
  String get accountNewPassword => '新密碼';

  @override
  String get accountPasswordUpdated => '密碼已更新';

  @override
  String get accountPasswordRemoved => '密碼已移除';

  @override
  String get accountProfileUpdated => '資料已更新';

  @override
  String get accountExportBackup => '匯出備份';

  @override
  String get accountExportBackupSubtitle => '把你的身分和訓練進度儲存到檔案';

  @override
  String get accountTrainingDefaults => '播放與訓練預設值';

  @override
  String get accountTrainingDefaultsSubtitle => '速度、音調、Farnsworth 間距';

  @override
  String get accountTrainingDefaultsPlaceholder => '速度、音調和 Farnsworth 預設值將放在這裡。';

  @override
  String get accountAboutLicence => '授權條款';

  @override
  String get accountAboutLicenceValue => 'GPL-3.0';

  @override
  String get accountAboutSource => '原始碼';

  @override
  String get accountAboutSourceCopied => '原始碼連結已複製';

  @override
  String get accountAboutBackend => '後端';

  @override
  String get accountDeleteIdentity => '刪除身分';

  @override
  String get accountDeleteIdentitySubtitle => '從本機抹除這個身分、聊天紀錄和訓練進度';

  @override
  String get accountDeleteDialogTitle => '刪除這個身分？';

  @override
  String get accountDeleteDialogBody => '這會從本機刪除你的身分、聊天紀錄和訓練進度。沒有備份將無法找回。輸入 DELETE 以確認。';

  @override
  String get accountDeleteConfirmWord => 'DELETE';

  @override
  String get accountDeleteConfirmHint => '輸入 DELETE';

  @override
  String get accountDeleteButton => '刪除';

  @override
  String get accountRecoveryPendingDiscard => '捨棄等待復原的身分並重新開始';

  @override
  String accountRestoreFileChosenSize(int bytes) {
    return '已選擇備份檔案（$bytes 位元組）';
  }

  @override
  String get chatSearchConversations => '搜尋對話';

  @override
  String get chatNoConversations => '還沒有對話';

  @override
  String get chatNoSearchResults => '沒有匹配的對話';

  @override
  String get chatPin => '置頂';

  @override
  String get chatUnpin => '取消置頂';

  @override
  String get chatMarkRead => '標為已讀';

  @override
  String get chatDelete => '刪除';

  @override
  String get chatDeleteConversationTitle => '刪除對話？';

  @override
  String get chatDeleteConversationBody => '將刪除本機上這個對話的歷史紀錄。Tox 不保留副本。';

  @override
  String get chatDraftPrefix => '草稿：';

  @override
  String get chatSelectConversation => '選擇一個對話';

  @override
  String get chatContacts => '聯絡人';

  @override
  String get chatNoMessages => '還沒有訊息 — 呼叫 CQ 開始通聯。';

  @override
  String get chatTrainingMode => '訓練模式';

  @override
  String get chatTrainingModeOn => '訓練模式已開：隱藏文字';

  @override
  String get chatTrainingModeOff => '訓練模式已關';

  @override
  String get chatAutoPlay => '自動播放收到的電碼';

  @override
  String get chatAutoPlayOn => '自動播放已開啟：新訊息到達即播放';

  @override
  String get chatAutoPlayOff => '自動播放已關閉';

  @override
  String get chatReveal => '顯示';

  @override
  String get chatHiddenText => '先聽，再顯示';

  @override
  String get chatPlay => '播放摩斯';

  @override
  String get chatStop => '停止';

  @override
  String get chatPlaybackSettings => '播放設定';

  @override
  String get chatCharacterSpeed => '字元速度';

  @override
  String get chatFarnsworthSpeed => 'Farnsworth 速度';

  @override
  String get chatTone => '音調';

  @override
  String get chatWpm => 'WPM';

  @override
  String get chatHz => 'Hz';

  @override
  String get chatMembers => '成員';

  @override
  String get chatLeaveGroup => '離開群組';

  @override
  String get chatLeaveGroupTitle => '離開這個群組？';

  @override
  String get chatLeaveGroupBody => '你將不再收到訊息。之後可憑 chat id 重新加入。';

  @override
  String get chatLeave => '離開';

  @override
  String get chatConferenceNote => '舊式會議群：此處無法使用摩斯鍵控中繼資料（v2）。文字仍然可用。';

  @override
  String get chatClearHistory => '清空歷史紀錄';

  @override
  String get chatModeStraightKey => '直鍵';

  @override
  String get chatModePaddles => '雙槳';

  @override
  String get chatKeyMessage => '用電鍵拍發訊息';

  @override
  String get chatSend => '傳送';

  @override
  String get chatTooLong => '超出單條 Tox 訊息的長度上限';

  @override
  String get chatKeyHint => '在電鍵區按鍵，或按空格';

  @override
  String get chatPaddleHint => '點按雙槳，或按住 Ctrl（左 點，右 劃）';

  @override
  String get chatDeleteLast => '刪除最後一個字元';

  @override
  String get chatNoFriends => '還沒有好友。用對方的 Tox ID 新增一位。';

  @override
  String get chatNoRequests => '沒有待處理的請求';

  @override
  String get chatAddFriend => '新增好友';

  @override
  String get chatMyToxId => '我的 Tox ID';

  @override
  String get chatToxIdLabel => 'Tox ID（76 位十六進位字元）';

  @override
  String get chatToxIdInvalid => 'Tox ID 必須正好是 76 位十六進位字元';

  @override
  String get chatToxIdOwn => '這是你自己的 Tox ID';

  @override
  String get chatToxIdAlreadyFriend => '已在你的好友列表中';

  @override
  String get chatRequestMessage => '附言';

  @override
  String get chatDefaultRequestMessage => 'DitMesh CQ';

  @override
  String get chatSendRequest => '傳送請求';

  @override
  String get chatRequestSent => '好友請求已傳送';

  @override
  String get chatScanQr => '掃描QR 碼';

  @override
  String get chatScanQrDesktopHint => '掃描 QR 碼需要手機相機';

  @override
  String get chatScanQrTitle => '掃描 Tox ID';

  @override
  String get chatScanQrNotToxId => '這個QR 碼不是 Tox ID';

  @override
  String get chatAccept => '接受';

  @override
  String get chatReject => '拒絕';

  @override
  String get chatCopied => '已複製到剪貼簿';

  @override
  String get chatNoIdentity => '未載入身分';

  @override
  String get chatRemoveFriend => '刪除好友';

  @override
  String get chatRemoveFriendTitle => '刪除這位好友？';

  @override
  String get chatRemoveFriendBody => '對方將無法再給你發訊息。';

  @override
  String get chatRemove => '刪除';

  @override
  String get chatNoGroups => '還沒有群組。建立一個，或憑 chat id 加入。';

  @override
  String get chatCreateGroup => '建立群組';

  @override
  String get chatJoinGroup => '加入群組';

  @override
  String get chatGroupName => '群組名稱';

  @override
  String get chatGroupNameRequired => '請給群組取個名字';

  @override
  String get chatAdvanced => '進階';

  @override
  String get chatLegacyConference => '舊式會議群（相容舊客戶端）';

  @override
  String get chatLegacyConferenceHint => '不推薦：沒有固定 chat id，也沒有摩斯中繼資料。';

  @override
  String get chatCreate => '建立';

  @override
  String get chatChatIdLabel => 'Chat id（64 位十六進位字元）';

  @override
  String get chatChatIdInvalid => 'Chat id 必須正好是 64 位十六進位字元';

  @override
  String get chatPassword => '密碼（可選）';

  @override
  String get chatJoin => '加入';

  @override
  String get chatJoinRequested => '加入中 — 找到一位成員後群組就會出現。';

  @override
  String get chatConferenceBadge => '會議群';

  @override
  String get chatCopyChatId => '複製 chat id';

  @override
  String get learnLessonCardTitle => 'Koch 課程';

  @override
  String get learnCourseComplete => '課程已完成 - 繼續磨練！';

  @override
  String get learnDailyGoalTitle => '今天';

  @override
  String get learnDailyGoalMet => '已達成每日目標';

  @override
  String get learnNoStreak => '從今天開始連續練習';

  @override
  String get learnContinueLesson => '繼續課程';

  @override
  String get learnReceivePractice => '聽抄練習';

  @override
  String get learnSendPractice => '發報練習';

  @override
  String get learnReviewDue => '複習到期字元';

  @override
  String get learnSettings => '訓練設定';

  @override
  String get learnLoading => '正在載入你的進度...';

  @override
  String get learnIdentityRequired => '建立或解鎖身分後即可開始訓練。進度隨身分儲存，會一同進入備份。';

  @override
  String get learnLoadFailed => '無法讀取已儲存的進度。將從頭開始；舊檔案已保留為 .corrupt。';

  @override
  String get learnProgressSaveFailed => '無法儲存進度。在 DitMesh 關閉前，本次成績仍然有效。';

  @override
  String get learnChooseDrill => '選擇一種練習';

  @override
  String get learnDrillGroups => '隨機字組';

  @override
  String get learnDrillWords => '單字';

  @override
  String get learnDrillCallsigns => '呼號';

  @override
  String get learnDrillQso => '通聯（QSO）';

  @override
  String get learnDrillCharacters => '單字速認';

  @override
  String get learnDrillAbbreviations => '縮語與 Q 簡語';

  @override
  String get learnDrillNumbers => '數字組';

  @override
  String get learnDrillConfusables => '易混字元';

  @override
  String get learnDrillContest => '競賽交換';

  @override
  String get learnDrillGroupsHint => '用已學字元組成的隨機字組';

  @override
  String get learnDrillCharactersHint => '每次一個字元，聽到即答';

  @override
  String get learnDrillWordsHint => '常用英文單字';

  @override
  String get learnDrillAbbreviationsHint => 'TNX、FB、QTH、QSL 等通聯常用語';

  @override
  String get learnDrillNumbersHint => '五位數字組，如電報與序號';

  @override
  String get learnDrillCallsignsHint => '世界各地的業餘電台呼號';

  @override
  String get learnDrillConfusablesHint => '成對練習容易聽混的字元，如 S/H、U/V';

  @override
  String get learnDrillQsoHint => '完整通聯中的句子';

  @override
  String get learnDrillContestHint => '呼號 + 5NN + 序號或分區，含縮略數字';

  @override
  String get learnDrillReviewHint => '到期需要複習的字元';

  @override
  String get toolsTitle => '無線電工具';

  @override
  String get toolsGridTitle => '網格定位';

  @override
  String get toolsGridHint => '座標換算網格、兩地距離與天線方位';

  @override
  String get toolsBandsTitle => '頻段與天線';

  @override
  String get toolsBandsHint => '頻率所在頻段、波長與偶極天線長度';

  @override
  String get toolsSpeedTitle => '報速換算';

  @override
  String get toolsSpeedHint => 'WPM 換算點長、間隔與每分鐘字元數';

  @override
  String get toolsRstTitle => 'RST 訊號報告';

  @override
  String get toolsRstHint => '組合訊號報告並查看每一位的含義';

  @override
  String get toolsClockTitle => 'UTC 時鐘';

  @override
  String get toolsClockHint => '日誌使用的 UTC 時間與本地時間';

  @override
  String get toolsGridFromCoordinates => '由座標求網格';

  @override
  String get toolsGridLatitude => '緯度';

  @override
  String get toolsGridLongitude => '經度';

  @override
  String get toolsGridCoordinatesHelp => '十進位度數；南緯、西經為負';

  @override
  String get toolsGridInvalidCoordinates => '緯度 -90 至 90，經度 -180 至 180';

  @override
  String get toolsGridLocator => '網格';

  @override
  String get toolsGridDistanceSection => '距離與方位';

  @override
  String get toolsGridMine => '我的網格';

  @override
  String get toolsGridTheirs => '對方網格';

  @override
  String get toolsGridInvalidLocator => '需 2、4、6 或 8 位，如 OM89ex';

  @override
  String get toolsGridCenter => '網格中心';

  @override
  String get toolsGridDistance => '距離';

  @override
  String get toolsGridShortPath => '短程方位';

  @override
  String get toolsGridLongPath => '長程方位';

  @override
  String get toolsBandsFrequency => '頻率（MHz）';

  @override
  String get toolsBandsInvalidFrequency => '請輸入大於 0 的頻率';

  @override
  String toolsBandsRegionLabel(int number) {
    return '$number 區';
  }

  @override
  String get toolsBandsRegionHelp => '1 區：歐洲、非洲、中東 · 2 區：美洲 · 3 區：亞太';

  @override
  String toolsBandsInBand(String band) {
    return '位於 $band 業餘頻段';
  }

  @override
  String get toolsBandsOutOfBand => '不在業餘頻段內';

  @override
  String get toolsBandsWavelength => '波長';

  @override
  String get toolsBandsDipole => '半波偶極天線（全長）';

  @override
  String get toolsBandsQuarterWave => '四分之一波長垂直天線';

  @override
  String get toolsBandsAntennaNote => '長度已乘 0.95 縮短係數，實際需修剪至諧振。';

  @override
  String get toolsBandsTable => '頻段邊界';

  @override
  String toolsBandsQrp(String frequency) {
    return 'QRP CW $frequency';
  }

  @override
  String get toolsBandsDisclaimer => '以上為 ITU 劃分，請以你的執照與本國頻率規劃為準（可能更窄）。';

  @override
  String get toolsSpeedCharacter => '字元速度';

  @override
  String get toolsSpeedFarnsworth => 'Farnsworth 間隔';

  @override
  String get toolsSpeedOverall => '整體速度';

  @override
  String get toolsSpeedDit => '點';

  @override
  String get toolsSpeedDah => '劃';

  @override
  String get toolsSpeedCharGap => '字元間隔';

  @override
  String get toolsSpeedWordGap => '單字間隔';

  @override
  String get toolsSpeedCpm => '每分鐘字元數';

  @override
  String get toolsSpeedParis => '一個 PARIS 單字';

  @override
  String get toolsRstReadability => '可讀度 (R)';

  @override
  String get toolsRstStrength => '訊號強度 (S)';

  @override
  String get toolsRstTone => '音調 (T)';

  @override
  String get toolsRstReport => '報告';

  @override
  String get toolsRstCut => '競賽簡寫';

  @override
  String get toolsRstPhone => '話音（無音調）';

  @override
  String get toolsRstR1 => '無法辨認';

  @override
  String get toolsRstR2 => '勉強可辨，偶爾聽出個別字';

  @override
  String get toolsRstR3 => '相當困難才能辨認';

  @override
  String get toolsRstR4 => '基本沒有困難';

  @override
  String get toolsRstR5 => '完全清晰';

  @override
  String get toolsRstS1 => '微弱，幾乎察覺不到';

  @override
  String get toolsRstS2 => '很弱';

  @override
  String get toolsRstS3 => '弱';

  @override
  String get toolsRstS4 => '尚可';

  @override
  String get toolsRstS5 => '較好';

  @override
  String get toolsRstS6 => '好';

  @override
  String get toolsRstS7 => '較強';

  @override
  String get toolsRstS8 => '強';

  @override
  String get toolsRstS9 => '極強';

  @override
  String get toolsRstT1 => '極粗糙、很寬，像未整流交流';

  @override
  String get toolsRstT2 => '很粗糙的交流音，刺耳且寬';

  @override
  String get toolsRstT3 => '粗糙，已整流未濾波';

  @override
  String get toolsRstT4 => '粗糙，略有濾波痕跡';

  @override
  String get toolsRstT5 => '已濾波，但漣波調變很重';

  @override
  String get toolsRstT6 => '已濾波，有明顯漣波';

  @override
  String get toolsRstT7 => '接近純音，略有漣波';

  @override
  String get toolsRstT8 => '近乎完美，僅有輕微調變';

  @override
  String get toolsRstT9 => '純淨音調，毫無漣波';

  @override
  String get toolsClockUtc => 'UTC';

  @override
  String get toolsClockLocal => '本地時間';

  @override
  String get toolsClockNote => '通聯日誌與 QSL 卡片統一使用 UTC。';

  @override
  String get learnReceiveTitle => '聽抄';

  @override
  String get learnReviewTitle => '複習';

  @override
  String get learnListen => '請聽...';

  @override
  String get learnReady => '就緒';

  @override
  String get learnReplay => '重放';

  @override
  String get learnAnswerHint => '輸入你聽到的內容';

  @override
  String get learnSubmit => '核對';

  @override
  String get learnNext => '下一個';

  @override
  String get learnFinish => '結束';

  @override
  String get learnDone => '完成';

  @override
  String get learnBackspace => '刪除';

  @override
  String get learnSpace => '空格';

  @override
  String get learnSent => '發出';

  @override
  String get learnYourCopy => '你的抄收';

  @override
  String get learnRoundPerfect => '全部抄對！';

  @override
  String get learnSessionSummary => '練習小結';

  @override
  String get learnLessonPassed => '本課通過';

  @override
  String get learnLessonNotPassed => '繼續加油：正確率達 90% 即可解鎖下一個字元';

  @override
  String get learnReviewRecorded => '複習已紀錄';

  @override
  String get learnWeakChars => '需要加強';

  @override
  String get learnConfusions => '易混淆';

  @override
  String get learnNoFeedbackWarning => '聲音、閃光和振動都已關閉 - 將改用螢幕閃爍提示。';

  @override
  String get learnSendTitle => '發報';

  @override
  String get learnSendThis => '請傳送';

  @override
  String get learnCopyFromMemory => '憑記憶';

  @override
  String get learnHiddenTarget => '已隱藏 - 憑記憶拍發';

  @override
  String get learnDecoded => '譯碼';

  @override
  String get learnWaitingForKey => '準備好後開始拍發';

  @override
  String get learnRestart => '重新開始';

  @override
  String get learnTryAnother => '換一個';

  @override
  String get learnKeyerStraight => '直鍵';

  @override
  String get learnKeyerIambicA => 'Iambic A';

  @override
  String get learnKeyerIambicB => 'Iambic B';

  @override
  String get learnLegendStraight => '空格 = 電鍵';

  @override
  String get learnLegendPaddles => '左 Ctrl = 點，右 Ctrl = 劃';

  @override
  String get learnSendClean => '手法乾淨 - 無需修正。';

  @override
  String get learnSendIssues => '節奏提示';

  @override
  String get learnYourSending => '譯碼為';

  @override
  String get learnStraightKeyLabel => '電鍵';

  @override
  String get learnDitLabel => '點';

  @override
  String get learnDahLabel => '劃';

  @override
  String get learnSettingsTitle => '訓練設定';

  @override
  String get learnCharacterSpeed => '字元速度';

  @override
  String get learnFarnsworth => 'Farnsworth 間距';

  @override
  String get learnFarnsworthHelp => '字元保持高速；字元之間的間隔拉長到這個速度。';

  @override
  String get learnEffectiveSpeed => '有效速度';

  @override
  String get learnTone => '音調';

  @override
  String get learnPlaySample => '播放示例';

  @override
  String get learnSessionLength => '練習長度';

  @override
  String get learnFeedback => '回饋';

  @override
  String get learnSound => '聲音';

  @override
  String get learnFlash => '螢幕閃光';

  @override
  String get learnHaptic => '振動';

  @override
  String get learnKeyer => '電鍵模式';

  @override
  String get learnDailyGoal => '每日目標';

  @override
  String get referenceReferenceTitle => '摩斯電碼手冊';

  @override
  String get referenceTranslatorTitle => '翻譯器';

  @override
  String get referencePlay => '播放';

  @override
  String get referenceStop => '停止';

  @override
  String get referenceClear => '清空';

  @override
  String get referenceClose => '關閉';

  @override
  String get referenceEmptyOutput => '—';

  @override
  String get referenceSearchHint => '搜尋字元、規程符號、Q 簡語…';

  @override
  String get referenceClearSearch => '清除搜尋';

  @override
  String get referenceNoResults => '沒有匹配的結果。';

  @override
  String get referenceSectionAlphabet => '字母與數字';

  @override
  String get referenceSectionPunctuation => '標點';

  @override
  String get referenceSectionProsigns => '規程符號（Prosign）';

  @override
  String get referenceSectionQCodes => 'Q 簡語';

  @override
  String get referenceSectionAbbreviations => 'CW 縮寫';

  @override
  String get referenceSectionKoch => 'Koch 順序';

  @override
  String get referenceAlphabetHint => '點按卡片試聽。長按查看記憶口訣。';

  @override
  String get referenceKochHint => 'Koch 法引入字元的順序（LCWO 序列）。從 K 和 M 開始；抄收正確率達 90% 時再加一個字元。';

  @override
  String get referenceMnemonicTitle => '記憶口訣';

  @override
  String get referenceMeaningLabel => '含義';

  @override
  String get referencePlaybackSettings => '播放設定';

  @override
  String get referenceCharacterSpeed => '字元速度';

  @override
  String get referenceFarnsworth => 'Farnsworth 間距';

  @override
  String get referenceFarnsworthHelp => '字元保持全速；間隔拉長到有效速度。';

  @override
  String get referenceEffectiveSpeed => '有效速度';

  @override
  String get referenceTone => '音調';

  @override
  String get referenceModeTextToMorse => '文字 → 摩斯';

  @override
  String get referenceModeMorseToText => '摩斯 → 文字';

  @override
  String get referenceModeKey => '拍發';

  @override
  String get referenceTextInputLabel => '文字';

  @override
  String get referenceTextInputHint => '輸入要編碼的文字…';

  @override
  String get referencePatternOutputLabel => '摩斯';

  @override
  String get referenceCopyPattern => '複製電碼';

  @override
  String get referencePatternCopied => '電碼已複製';

  @override
  String get referencePatternInputLabel => '摩斯';

  @override
  String get referencePatternInputHint => '輸入 . 和 -，字母間用空格，單字間用 /';

  @override
  String get referenceTextOutputLabel => '文字';

  @override
  String get referenceCopyText => '複製文字';

  @override
  String get referenceTextCopied => '文字已複製';

  @override
  String get referenceUnknownPatternHelp => '沒有對應字元的電碼顯示為 <電碼>。';

  @override
  String get referenceKeypadDit => '點';

  @override
  String get referenceKeypadDah => '劃';

  @override
  String get referenceKeypadCharGap => '字母間隔';

  @override
  String get referenceKeypadWordGap => '單字間隔';

  @override
  String get referenceKeypadBackspace => '退格';

  @override
  String get referenceKeyHint => '按住電鍵傳送。使用鍵盤時按住空格。';

  @override
  String get referenceKeyLabel => '電鍵';

  @override
  String get referenceKeyDecodedLabel => '譯碼';

  @override
  String get referenceKeyPendingLabel => '鍵控中';

  @override
  String get statsTitle => '統計';

  @override
  String get statsLoading => '正在載入你的統計...';

  @override
  String get statsLoadFailed => '無法載入你的進度。下拉或重新開啟以重試。';

  @override
  String get statsRetry => '重試';

  @override
  String get statsEmptyTitle => '還沒有練習紀錄';

  @override
  String get statsEmptyBody => '完成第一次聽抄或發報練習後，這裡會顯示你的正確率趨勢、各字元掌握程度和練習日曆。';

  @override
  String get statsEmptyCallToAction => '前往「學習」並點按「繼續課程」開始。';

  @override
  String get statsOverviewTitle => '總覽';

  @override
  String get statsTileLesson => 'Koch 課程';

  @override
  String get statsTileAccuracy => '正確率';

  @override
  String get statsNoData => '--';

  @override
  String get statsTilePractice => '練習量';

  @override
  String get statsTileStreak => '連續天數';

  @override
  String get statsTileDailyGoal => '每日目標';

  @override
  String get statsGoalMet => '今日已達成';

  @override
  String get statsSummaryTitle => '你的統計';

  @override
  String get statsSummaryOpen => '查看統計';

  @override
  String get statsTrendTitle => '正確率趨勢';

  @override
  String get statsTrendHint => '點按資料點查看該次練習。';

  @override
  String get statsSeriesReceive => '聽抄';

  @override
  String get statsSeriesSend => '發報';

  @override
  String get statsAxisSessions => '練習次序';

  @override
  String get statsCharsTitle => '字元';

  @override
  String get statsCharsSubtitle => '按 Koch 順序。點按字元查看詳情。';

  @override
  String get statsCharsNotStarted => '尚未練習';

  @override
  String get statsNotInCourse => '不在 Koch 課程內';

  @override
  String get statsSrsTitle => '間隔重複';

  @override
  String get statsSrsNotTracked => '尚未安排';

  @override
  String get statsSrsDueNow => '現在到期';

  @override
  String get statsConfusionsTitle => '最常混淆為';

  @override
  String get statsConfusionsNone => '沒有混淆紀錄';

  @override
  String get statsConfusionMissed => '漏抄';

  @override
  String get statsBucketLegendTitle => '正確率';

  @override
  String get statsBucketNone => '無';

  @override
  String get statsBucketWeak => '< 70%';

  @override
  String get statsBucketFair => '70-89%';

  @override
  String get statsBucketGood => '90-97%';

  @override
  String get statsBucketStrong => '>= 98%';

  @override
  String get statsHeatmapTitle => '混淆矩陣';

  @override
  String get statsHeatmapSubtitle => '行是發出的字元，列是你的回答。顏色越深表示越頻繁。';

  @override
  String get statsHeatmapEmpty => '還沒有混淆紀錄。答錯的字元會顯示在這裡。';

  @override
  String get statsHeatmapLegendLow => '少';

  @override
  String get statsHeatmapLegendHigh => '多';

  @override
  String get statsHeatmapAxisTarget => '發出';

  @override
  String get statsHeatmapAxisAnswered => '回答';

  @override
  String get statsCalendarTitle => '練習日曆';

  @override
  String get statsCalendarSubtitle => '最近 12 週';

  @override
  String get statsCalendarLegendLess => '少';

  @override
  String get statsCalendarLegendMore => '多';

  @override
  String get statsStreakExplanation => '連續天數按至少有一次練習的連續日曆日計算。整天未練習會重置；一天內練習兩次只算一天。';

  @override
  String get learnStatistics => '統計';

  @override
  String get listenTitle => '收聽';

  @override
  String get listenStart => '開始';

  @override
  String get listenStop => '停止';

  @override
  String get listenStarting => '正在啟動麥克風…';

  @override
  String get listenClear => '清空文字';

  @override
  String get listenCopy => '複製文字';

  @override
  String get listenCopied => '已複製解碼文字';

  @override
  String get listenSettings => '收聽設定';

  @override
  String get listenDecoded => '解碼結果';

  @override
  String get listenEmptyHint => '把麥克風對準摩斯電碼音，解碼文字會顯示在這裡。';

  @override
  String get listenIdleHint => '點選「開始」以收聽摩斯電碼音。';

  @override
  String get listenPending => '接收中';

  @override
  String get listenSpeed => '速度';

  @override
  String get listenSpeedUnknown => '-- WPM';

  @override
  String get listenLevel => '信號';

  @override
  String get listenToneOn => '有音';

  @override
  String get listenTone => '音調頻率';

  @override
  String get listenToneLocked => '已鎖定';

  @override
  String get listenToneSearching => '搜尋中';

  @override
  String get listenToneManual => '手動';

  @override
  String get listenAutoTune => '自動調諧';

  @override
  String get listenAutoTuneHelp => '追蹤 400–1000 Hz 之間最強的音調；拖動滑桿可改為手動調諧。';

  @override
  String get listenRetune => '自動';

  @override
  String get listenBlockSize => '分析區塊長度';

  @override
  String get listenBlockSizeHelp => '區塊越小，點劃邊緣定位越精確，但更容易受雜訊影響。256 個取樣（5.3 ms）適合 5–40 WPM。';

  @override
  String get listenMinElement => '最短元素';

  @override
  String get listenMinElementHelp => '短於此時長的音與間隔會視為雜訊或斷續而忽略。';

  @override
  String get listenPermissionDenied => '麥克風權限被拒絕。請在系統設定中允許後重試。';

  @override
  String get listenPermissionRetry => '重試';

  @override
  String get listenStartFailed => '無法啟動麥克風。';

  @override
  String get listenNoInput => '未找到麥克風。請連線後重試。';

  @override
  String get listenStreamFailed => '麥克風意外中斷，請重試。';

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
    return '$samples 個取樣（$ms ms）';
  }

  @override
  String listenMsValue(int ms) {
    return '$ms ms';
  }

  @override
  String get listenStoppedInBackground => '應用程式進入背景，已停止收聽。';

  @override
  String get learnWpmUnknown => '-- WPM';

  @override
  String get learnTipDitTooLongTitle => '點太長';

  @override
  String get learnTipDahTooShortTitle => '劃太短';

  @override
  String get learnTipIntraGapTooLongTitle => '碼元過於分散';

  @override
  String get learnTipCharGapTooShortTitle => '字元過於擁擠';

  @override
  String get learnTipWordGapTooShortTitle => '單字過於擁擠';

  @override
  String get learnTipSpeedUnsteadyTitle => '速度不穩';

  @override
  String get learnSeverityMinor => '輕微';

  @override
  String get learnSeverityModerate => '明顯';

  @override
  String get learnSeveritySevere => '嚴重';

  @override
  String get notificationOpen => '開啟';

  @override
  String get notificationChannelMessages => '訊息';

  @override
  String get notificationChannelMessagesDescription => '來自好友和群組的新摩斯電碼訊息';

  @override
  String get notificationChannelFriendRequests => '好友請求';

  @override
  String get notificationChannelFriendRequestsDescription => '有人想新增你為好友';

  @override
  String get notificationChannelGroupInvites => '群組邀請';

  @override
  String get notificationChannelGroupInvitesDescription => '好友邀請你加入群組';

  @override
  String get notificationNewMessage => '新訊息';

  @override
  String get notificationFriendRequestTitle => '新的好友請求';

  @override
  String learnNewestCharIs(String char) {
    return '本課新字元：$char';
  }

  @override
  String learnCharNewSemantics(String char) {
    return '$char，新字元';
  }

  @override
  String learnPendingPattern(String pattern) {
    return '鍵控中：$pattern';
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
    return '你的點拖得太長（約為一個點的 $ratio）。想著「滴」而不是「答」——點是輕敲，不是長按。';
  }

  @override
  String learnTipDahTooShort(String ratio) {
    return '你的劃太短（約為一個點的 $ratio；目標是 3 倍）。劃要按住三個點的時長。';
  }

  @override
  String learnTipIntraGapTooLong(String ratio) {
    return '字元內部的間隔太寬（約為一個點的 $ratio）。同一字元的碼元要緊湊相連。';
  }

  @override
  String learnTipCharGapTooShort(String ratio) {
    return '字元之間黏在一起了（間隔約為一個點的 $ratio；目標是 3 倍）。每個字元後留出明確的停頓。';
  }

  @override
  String learnTipWordGapTooShort(String ratio) {
    return '單字之間太近（間隔約為一個點的 $ratio；目標是 7 倍）。單字之間要數一個長停頓。';
  }

  @override
  String learnTipSpeedUnsteady(int percent) {
    return '你的速度飄忽不定（波動 $percent%）。定下一個節拍，整行保持不變。';
  }

  @override
  String learnIssueDetailDitTooLong(int offending, int total, String ratio) {
    return '$total 個點中有 $offending 個太長（平均 $ratio 點長）';
  }

  @override
  String learnIssueDetailDahTooShort(int offending, int total, String ratio) {
    return '$total 個劃中有 $offending 個太短（平均 $ratio 點長）';
  }

  @override
  String learnIssueDetailIntraGapTooLong(int offending, int total, String ratio) {
    return '$total 個字元內間隔中有 $offending 個太長（平均 $ratio 點長）';
  }

  @override
  String learnIssueDetailCharGapTooShort(int offending, int total, String ratio) {
    return '$total 個字元間隔中有 $offending 個太短（平均 $ratio 點長）';
  }

  @override
  String learnIssueDetailWordGapTooShort(int offending, int total, String ratio) {
    return '$total 個單字間隔中有 $offending 個太短（平均 $ratio 點長）';
  }

  @override
  String learnIssueDetailSpeedUnsteady(String cv) {
    return '拍發速度不穩（變異系數 $cv）';
  }

  @override
  String statsAccuracyDetail(String allTime) {
    return '最近 7 天 / 全部 $allTime';
  }

  @override
  String statsDurationHoursMinutes(int hours, int minutes) {
    return '$hours 小時 $minutes 分';
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
  String get accountNewPasswordRequired => '請輸入新密碼';

  @override
  String get accountToxIdQrSemantics => 'Tox ID QR 碼';

  @override
  String get accountBackupSaveDialogTitle => '儲存 DitMesh 備份';

  @override
  String get accountBackupShareSubject => 'DitMesh 身分備份';

  @override
  String get accountBackupChooseDialogTitle => '選擇 DitMesh 備份';

  @override
  String notificationNewMessages(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 條新訊息',
    );
    return '$_temp0';
  }

  @override
  String notificationFriendRequestFrom(String name) {
    return '來自 $name 的好友請求';
  }

  @override
  String notificationFriendRequestBody(String name, String message) {
    return '$name：$message';
  }

  @override
  String notificationGroupInviteTitle(String group) {
    return '邀請加入 $group';
  }

  @override
  String notificationGroupInviteBody(String name) {
    return '$name 邀請你加入';
  }

  @override
  String desktopTrayShow(String app) {
    return '顯示 $app';
  }

  @override
  String desktopTrayHide(String app) {
    return '隱藏 $app';
  }

  @override
  String get desktopTraySoundOn => '聲音已開';

  @override
  String get desktopTraySoundOff => '聲音已關';

  @override
  String desktopTrayQuit(String app) {
    return '離開 $app';
  }

  @override
  String desktopTrayTooltipUnread(String app, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 條未讀',
    );
    return '$app — $_temp0';
  }

  @override
  String desktopWindowTitleUnread(String badge, String app) {
    return '($badge) $app';
  }

  @override
  String get listenStateOn => '開';

  @override
  String get listenStateOff => '關';

  @override
  String chatBytesLeftCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '剩餘 $count 位元組',
    );
    return '$_temp0';
  }

  @override
  String chatMemberCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 位成員',
    );
    return '$_temp0';
  }

  @override
  String chatFriendsCount(int count) {
    return '好友（$count）';
  }

  @override
  String chatFriendRequestsCount(int count) {
    return '好友請求（$count）';
  }

  @override
  String chatGroupInvitesCount(int count) {
    return '群組邀請（$count）';
  }

  @override
  String chatMembersTitleCount(int count) {
    return '成員 · $count';
  }

  @override
  String chatInvitedByName(String name) {
    return '邀請人：$name';
  }

  @override
  String chatMemberSelf(String name) {
    return '$name（你）';
  }

  @override
  String chatSliderValue(String label, int value, String unit) {
    return '$label：$value $unit';
  }

  @override
  String referenceTelegraphCodes(String codes) {
    return '中文電碼：$codes';
  }

  @override
  String get referenceTelegraphMainland => '大陸（1983）';

  @override
  String get referenceTelegraphTaiwan => '臺灣 / 香港';

  @override
  String get referenceTelegraphNone => '本電碼本無此字';

  @override
  String get appearanceTitle => '外觀';

  @override
  String get appearanceStyles => '界面風格';

  @override
  String get appearanceChoose => '選擇風格，預覽後套用';

  @override
  String get appearanceMode => '明暗模式';

  @override
  String get appearancePreview => '效果預覽';

  @override
  String get appearanceApply => '套用風格';

  @override
  String get appearanceRestore => '還原預設';

  @override
  String get appearanceApplied => '外觀已儲存';

  @override
  String get appearanceSaveFailed => '無法儲存外觀，請重試。';

  @override
  String get appearanceClassic => '經典黃銅';

  @override
  String get appearanceModern => '清爽現代';

  @override
  String get appearanceRadio => '夜航電台';

  @override
  String get appearancePaper => '紙感手冊';

  @override
  String get appearanceCartoon => '清新卡通';

  @override
  String get appearanceLight => '淺色';

  @override
  String get appearanceDark => '深色';

  @override
  String get appearanceSubtitle => '五種風格，支援淺色與深色';

  @override
  String get chatClearHistoryBody => '刪除當前對話在本機儲存的歷史紀錄？其他裝置上的副本不受影響。此操作無法撤銷。';

  @override
  String get chatLoadEarlier => '載入更早訊息';

  @override
  String get chatHistoryLoadFailed => '更早訊息載入失敗，點選重試。';

  @override
  String get chatRetryHistory => '重試';

  @override
  String chatNewMessages(int count) {
    return '$count 條新訊息';
  }

  @override
  String learnShowAllChars(int count) {
    return '顯示全部 $count 個字元';
  }

  @override
  String get chatSelfMe => '我';

  @override
  String get chatSelfLocalOnly => '僅儲存在本機';

  @override
  String get chatSelfContactSubtitle => '草稿、練習與備忘 · 不會傳送';

  @override
  String get learnShowFewerChars => '收起字元';

  @override
  String get learnLeaveDrillTitle => '退出本次練習？';

  @override
  String get learnLeaveDrillBody => '本次練習已完成的輪次不會被儲存。';

  @override
  String get learnLeaveDrillConfirm => '退出';

  @override
  String get chatScanQrPermissionDenied => 'DitMesh 需要相機權限才能掃描 QR 碼，請在系統設定中允許。';

  @override
  String get chatScanQrCameraUnavailable => '此裝置的相機無法使用。';

  @override
  String get learnReplayAssistedNote => '已重播：本次練習計入練習量，但不會解鎖課程或更新複習。';

  @override
  String get learnPlanTitle => '今日計畫';

  @override
  String learnPlanSummary(int minutes, int done, int total) {
    return '約 $minutes 分鐘 · 已完成 $done/$total 步';
  }

  @override
  String get learnPlanBudget => '計畫時長';

  @override
  String learnPlanBudgetMinutes(int minutes) {
    return '$minutes 分鐘';
  }

  @override
  String get learnPlanStart => '開始計畫';

  @override
  String get learnPlanContinue => '繼續計畫';

  @override
  String get learnPlanStepReview => '複習到期字元';

  @override
  String get learnPlanStepFocus => '重點練習';

  @override
  String learnPlanStepCourse(int lesson) {
    return '第 $lesson 課';
  }

  @override
  String get learnPlanStepSend => '發報練習';

  @override
  String learnPlanReasonDueReview(String symbols) {
    return '到期複習：$symbols';
  }

  @override
  String learnPlanReasonConfusions(String symbols) {
    return '經常混淆：$symbols';
  }

  @override
  String learnPlanReasonWeak(String symbols) {
    return '正確率低於 90%：$symbols';
  }

  @override
  String learnPlanReasonChallenge(int count) {
    return '$count 個字元：可以解鎖下一課';
  }

  @override
  String learnPlanReasonExtended(int count) {
    return '已延長到 $count 個字元，以便能解鎖下一課';
  }

  @override
  String get learnPlanReasonConsolidate => '短練習：鞏固本課，不會解鎖下一課';

  @override
  String learnPlanReasonOutdated(int lesson) {
    return '課程已前進：練習第 $lesson 課，但不會解鎖';
  }

  @override
  String learnPlanReasonSend(int count) {
    return '發送 $count 個短目標';
  }

  @override
  String learnPlanStepDonePercent(int percent) {
    return '完成 · $percent%';
  }

  @override
  String get learnPlanStepDone => '完成';

  @override
  String learnPlanSendProgress(int done, int total) {
    return '已發送 $done/$total';
  }

  @override
  String get learnPlanStale => '課程或速度已變更。要更新尚未開始的步驟嗎？';

  @override
  String get learnPlanUpdate => '更新步驟';

  @override
  String get learnPlanComplete => '今日計畫已完成';

  @override
  String learnPlanNeedsWork(String symbols) {
    return '需要加強：$symbols';
  }

  @override
  String get learnPlanAllGood => '今天沒有薄弱字元。';

  @override
  String get learnPlanTomorrow => '明天會產生新計畫。自由練習隨時可用。';

  @override
  String learnPlanNext(String step) {
    return '下一步：$step';
  }

  @override
  String learnPlanEarlier(int done, int total) {
    return '之前的計畫停在第 $done/$total 步，不再計入今天。';
  }

  @override
  String learnSpeedAdviceRaise(int wpm) {
    return '可以把有效速度提高到 $wpm WPM';
  }

  @override
  String learnSpeedAdviceRaiseBoth(int wpm) {
    return '可以提高到 $wpm WPM';
  }

  @override
  String learnSpeedAdviceLower(int wpm) {
    return '目前速度抄收較吃力。可以試試 $wpm WPM 有效速度，或做重點練習。';
  }

  @override
  String learnSpeedAdviceBody(int count, int percent) {
    return '依據你最近 $count 次無輔助練習（$percent%）。按「套用」前不會變更任何設定。';
  }

  @override
  String get learnSpeedAdviceApply => '套用';

  @override
  String get learnSpeedAdviceDismiss => '暫不';

  @override
  String get learnSpeedAdviceInsufficient => '速度建議需要在目前速度下完成 3 次、每次 50 個字元以上的無輔助練習。';

  @override
  String get learnQsoAction => 'QSO 模擬';

  @override
  String learnQsoLocked(int lesson) {
    return '第 $lesson 課起開放';
  }

  @override
  String get learnQsoTitle => 'QSO 模擬';

  @override
  String get learnQsoRespond => '回應 CQ';

  @override
  String get learnQsoRespondHint => '一個電台在呼叫 CQ。回應它並交換信號報告。';

  @override
  String get learnQsoCall => '呼叫 CQ';

  @override
  String get learnQsoCallHint => '你呼叫 CQ，會有電台回應。';

  @override
  String get learnQsoYourCall => '你的呼號';

  @override
  String get learnQsoYourName => '你的名字';

  @override
  String get learnQsoYourQth => '你的 QTH';

  @override
  String get learnQsoInvalidCall => '請輸入呼號，例如 BD1XYZ';

  @override
  String get learnQsoInvalidWord => '一個單字，僅限字母 A–Z';

  @override
  String get learnQsoOffline => '完全在本機執行，不會向任何人傳送內容。';

  @override
  String get learnQsoStart => '開始 QSO';

  @override
  String get learnQsoResume => '繼續未完成的 QSO';

  @override
  String get learnQsoStageCallCq => '用你的呼號呼叫 CQ';

  @override
  String get learnQsoStageCallConfirm => '回應：對方呼號、DE、你的呼號';

  @override
  String get learnQsoStageExchange => '發送信號報告、名字和 QTH';

  @override
  String get learnQsoStageConfirmInfo => '確認對方的資訊';

  @override
  String get learnQsoStageClosing => '以 73 和 <SK> 結束';

  @override
  String get learnQsoStageDone => 'QSO 完成';

  @override
  String learnQsoSpeed(int wpm) {
    return '對方以 $wpm WPM 有效速度發送';
  }

  @override
  String learnQsoRemote(String call) {
    return '$call 發送';
  }

  @override
  String get learnQsoRemoteHidden => '請憑聽覺抄收——文字已隱藏。';

  @override
  String get learnQsoShowText => '顯示文字';

  @override
  String get learnQsoListen => '收聽';

  @override
  String get learnQsoAccepted => '已接受';

  @override
  String get learnQsoRejected => '未通過';

  @override
  String get learnQsoRemoteSending => '對方正在發送……';

  @override
  String get learnQsoYourTurn => '輪到你了：拍發回覆，然後按「發送」。';

  @override
  String get learnQsoDecoded => '你的發送內容';

  @override
  String get learnQsoNothingKeyed => '尚未拍發';

  @override
  String get learnQsoPlayAgain => '請求重複（AGN）';

  @override
  String get learnQsoSlower => '請求放慢（QRS）';

  @override
  String get learnQsoHint => '提示';

  @override
  String learnQsoHintLabel(String example) {
    return '範例：$example';
  }

  @override
  String get learnQsoPause => '暫停';

  @override
  String get learnQsoSend => '發送';

  @override
  String get learnQsoClear => '清除';

  @override
  String get learnQsoIssueEmpty => '沒有拍發任何內容。';

  @override
  String get learnQsoIssueMissingCq => '以 CQ 開頭。';

  @override
  String get learnQsoIssueMissingDe => '在兩個呼號之間加 DE。';

  @override
  String get learnQsoIssueWrongLocalCall => '你的呼號缺失或錯誤。';

  @override
  String get learnQsoIssueWrongRemoteCall => '對方的呼號錯誤。';

  @override
  String get learnQsoIssueReversedCalls => '呼號順序反了：先對方，再 DE，再你的。';

  @override
  String get learnQsoIssueMissingEnding => '以 K 或 KN 結尾。';

  @override
  String get learnQsoIssueMissingRst => '給出信號報告，例如 UR RST 599。';

  @override
  String get learnQsoIssueInvalidRst => 'RST 超出範圍（R 1–5、S 1–9、T 1–9）。';

  @override
  String get learnQsoIssueMissingName => '發送 NAME 和你的名字。';

  @override
  String get learnQsoIssueWrongName => '這不是你在本次 QSO 中的名字。';

  @override
  String get learnQsoIssueMissingQth => '發送 QTH 和你的位置。';

  @override
  String get learnQsoIssueWrongQth => '這不是你在本次 QSO 中的 QTH。';

  @override
  String get learnQsoIssueMissingAck => '用 R 或 QSL 表示確認。';

  @override
  String get learnQsoIssueWrongRemoteName => '確認對方操作員的名字。';

  @override
  String get learnQsoIssueMissing73 => '加上 73。';

  @override
  String get learnQsoIssueMissingSk => '以 <SK> 結束聯絡。';

  @override
  String learnQsoSummaryFields(int count, int total) {
    return '一次通過：$total 步中 $count 步';
  }

  @override
  String learnQsoSummaryRepeats(int count) {
    return '重複次數：$count';
  }

  @override
  String learnQsoSummaryHints(int count) {
    return '提示次數：$count';
  }

  @override
  String learnQsoSummaryRhythm(int wpm) {
    return '你的發報：約 $wpm WPM';
  }

  @override
  String get learnQsoSummaryNote => 'QSO 成績與抄收正確率分開統計，不會解鎖課程。';

  @override
  String get messageStatusCancelled => '已取消——未發送';

  @override
  String get chatMessageLearnActions => '訊息操作';

  @override
  String get chatPracticeMessage => '練習抄收這則訊息';

  @override
  String get chatSaveAsMaterial => '儲存為訓練素材';

  @override
  String get chatSavedAsMaterial => '已儲存到「我的素材」';

  @override
  String get chatSaveMaterialFailed => '儲存素材失敗，請重試。';

  @override
  String get chatListenOnly => '純聽訓練';

  @override
  String get chatListenOnlyHidden => '純聽模式：點播放收聽';

  @override
  String chatClearHistoryMaterials(int count) {
    return '此對話中有 $count 則訊息已儲存為訓練素材。這些副本會保留，直到你在「學習 › 我的素材」中刪除。';
  }

  @override
  String get chatPracticeTitle => '抄收練習';

  @override
  String chatPracticeUnsupported(String chars) {
    return '這則訊息包含無法用摩斯碼拍發的字元：$chars。練習時會略過它們。';
  }

  @override
  String chatPracticeTrainableCount(int count) {
    return '可練習 $count 個字元。';
  }

  @override
  String get chatPracticeNothingTrainable => '這則訊息中沒有可用摩斯碼練習的內容。';

  @override
  String get chatPracticeConfirm => '練習其餘部分';

  @override
  String get chatPracticeHint => '提示';

  @override
  String chatPracticeHintShown(String symbols) {
    return '提示：$symbols …';
  }

  @override
  String get chatPracticeAssisted => '已使用輔助：計入練習量，但不用於複習或速度建議。';

  @override
  String chatPracticeErrors(int wrong, int missed, int extra) {
    return '$wrong 個錯誤 · $missed 個遺漏 · $extra 個多餘';
  }

  @override
  String chatPracticeErrorsAction(String symbols) {
    return '練習出錯字元：$symbols';
  }

  @override
  String get learnTipDahTooLongTitle => '劃太長';

  @override
  String learnTipDahTooLong(String ratio) {
    return '你的劃太長（約為一個點的 $ratio；目標是 3 倍）。滿三個點長就鬆開。';
  }

  @override
  String learnIssueDetailDahTooLong(int offending, int total, String ratio) {
    return '$total 個劃中有 $offending 個太長（平均 $ratio 點長）';
  }

  @override
  String get learnRhythmTitle => '節奏';

  @override
  String get learnRhythmMine => '我的節奏';

  @override
  String get learnRhythmStandard => '標準節奏（目標速度）';

  @override
  String learnRhythmNormalizedNote(int ms) {
    return '問題依你自己的點長（$ms 毫秒）判斷，節奏均勻但偏慢沒有問題。標準列依目標速度繪製。';
  }

  @override
  String get learnRhythmNotLocated => '無法把你的拍發逐個對應到字元，因此問題未定位到具體字母。請改為練習整個目標。';

  @override
  String get learnRhythmPlayMine => '播放我的';

  @override
  String get learnRhythmPlayStandard => '播放標準';

  @override
  String learnRhythmPracticePart(int count) {
    return '練習這個（$count 次）';
  }

  @override
  String get learnRhythmPracticeWhole => '練習整個目標';

  @override
  String get learnRhythmSymbolOk => '很好';

  @override
  String get learnRhythmZoomIn => '放大';

  @override
  String get learnRhythmZoomOut => '縮小';

  @override
  String get chatSearchMessages => '搜尋訊息';

  @override
  String get chatSearchHint => '在此對話中搜尋';

  @override
  String get chatSearchAnyone => '所有人';

  @override
  String get chatSearchMe => '我';

  @override
  String get chatSearchThem => '對方';

  @override
  String get chatSearchAnyDate => '任何日期';

  @override
  String chatSearchDateRange(String from, String to) {
    return '$from – $to';
  }

  @override
  String get chatSearchBookmarked => '已收藏';

  @override
  String get chatSearchNoResults => '沒有符合的訊息。';

  @override
  String get chatSearchMore => '載入更多';

  @override
  String get chatAddBookmark => '收藏';

  @override
  String get chatRemoveBookmark => '取消收藏';

  @override
  String get chatBookmarked => '已收藏';

  @override
  String get chatBookmarkFailed => '無法儲存收藏。';

  @override
  String get chatRetrySend => '重新傳送';

  @override
  String get chatCancelSend => '取消傳送';

  @override
  String get chatRetryQueued => '已重新排入佇列，聯絡人上線後傳送。';

  @override
  String get chatSendCancelled => '已取消，訊息未傳送。';

  @override
  String get chatRetryNotNeeded => '這則訊息已不是失敗狀態，無需重試。';

  @override
  String get chatCancelTooLate => '無法取消：訊息已交給網路，可能會送達。';

  @override
  String get chatSendControlUnavailable => '此訊息不支援此操作。';

  @override
  String get chatSendControlFailed => '操作未完成，訊息保持原狀態，請重試。';

  @override
  String get workbenchTitle => '錄音工作台';

  @override
  String get workbenchOpen => '錄音';

  @override
  String get workbenchImport => '匯入錄音';

  @override
  String get workbenchEmpty => '匯入 WAV 錄音，即可循環播放、解碼並自己抄收。不需要麥克風。';

  @override
  String get workbenchFormats => 'WAV，16 位元 PCM，單聲道或立體聲，8/16/44.1/48 kHz；最大 50 MB、20 分鐘。';

  @override
  String get workbenchBackupNote => '錄音儲存在本裝置上，除非匯出備份時選擇包含，否則不會進入身分備份。已儲存選段的標題、備註和位置一律會備份。';

  @override
  String workbenchInfo(String rate, String channels, String duration) {
    return '$rate kHz · $channels · $duration';
  }

  @override
  String get workbenchMono => '單聲道';

  @override
  String get workbenchStereo => '立體聲';

  @override
  String get workbenchTruncated => '檔案提前結束，只使用已有的音訊。';

  @override
  String get workbenchErrorNotWav => '這不是 WAV 檔案。';

  @override
  String get workbenchErrorFormat => '目前只支援 16 位元 PCM WAV（不支援 MP3、AAC 或浮點 WAV）。';

  @override
  String get workbenchErrorChannels => '只支援單聲道或立體聲錄音。';

  @override
  String get workbenchErrorRate => '不支援該取樣率。請使用 8、16、44.1 或 48 kHz。';

  @override
  String get workbenchErrorDamaged => '檔案已損毀或不完整。';

  @override
  String get workbenchErrorTooLarge => '檔案超過 50 MB。';

  @override
  String get workbenchErrorTooLong => '錄音超過 20 分鐘。';

  @override
  String get workbenchErrorIo => '無法讀取該檔案。';

  @override
  String get workbenchErrorMissing => '錄音檔案不見了。';

  @override
  String get workbenchStart => '開始（秒）';

  @override
  String get workbenchEnd => '結束（秒）';

  @override
  String get workbenchSelectAll => '全選';

  @override
  String get workbenchPlay => '播放所選片段';

  @override
  String get workbenchStop => '停止';

  @override
  String get workbenchLoop => '循環';

  @override
  String get workbenchPlayLimit => '較長的片段只播放前 5 分鐘。';

  @override
  String get workbenchAutoTune => '自動尋找音調';

  @override
  String workbenchManualTone(int hz) {
    return '音調：$hz Hz';
  }

  @override
  String get workbenchDecode => '解碼所選片段';

  @override
  String get workbenchCancel => '取消';

  @override
  String workbenchDecoding(int percent) {
    return '正在解碼……$percent%';
  }

  @override
  String workbenchResultStats(int hz, int wpm) {
    return '音調 $hz Hz · 約 $wpm WPM';
  }

  @override
  String get workbenchToneNotLocked => '沒有找到穩定的音調，請嘗試手動調諧。';

  @override
  String get workbenchNoText => '該片段沒有解出內容。';

  @override
  String workbenchUnknown(String patterns) {
    return '無法識別的碼型：$patterns';
  }

  @override
  String get workbenchEdgeCut => '片段邊緣的字元被截斷，可能不準確。';

  @override
  String get workbenchToneNote => '鎖定音調不代表結果可信，請用耳朵核對文字。';

  @override
  String get workbenchModeDecoder => '解碼器';

  @override
  String get workbenchModeCopy => '我自己抄收';

  @override
  String get workbenchDecoderHidden => '抄收時解碼文字會隱藏。';

  @override
  String get workbenchShowDecoder => '顯示解碼文字';

  @override
  String get workbenchReference => '參考答案（選填）';

  @override
  String get workbenchReferenceHelp => '貼上實際發送的文字；否則會與解碼結果比較。';

  @override
  String get workbenchAgainstDecoder => '已與解碼結果比較，而解碼結果本身也可能有誤。';

  @override
  String get workbenchSave => '儲存片段';

  @override
  String get workbenchSaveTitle => '標題';

  @override
  String get workbenchSaveNote => '備註';

  @override
  String get workbenchSaved => '片段已儲存';

  @override
  String get workbenchSaveFailed => '無法儲存片段。';

  @override
  String get workbenchLibrary => '已儲存的片段';

  @override
  String get workbenchLibraryEmpty => '還沒有儲存的片段。';

  @override
  String get workbenchMissing => '錄音檔案不見了——請重新選擇檔案或刪除此項。';

  @override
  String get workbenchRelink => '重新選擇檔案';

  @override
  String get workbenchDelete => '刪除';

  @override
  String get materialsTitle => '我的素材';

  @override
  String get materialsNew => '新增素材';

  @override
  String get materialsEdit => '編輯';

  @override
  String get materialsSave => '儲存';

  @override
  String get materialsSaveFailed => '無法儲存素材。';

  @override
  String get materialsTitleField => '標題';

  @override
  String get materialsTagsField => '標籤（以逗號分隔）';

  @override
  String get materialsTextField => '文字';

  @override
  String get materialsListField => '每行一項';

  @override
  String get materialsKindText => '文字';

  @override
  String get materialsKindWords => '單字表';

  @override
  String get materialsKindCallsigns => '呼號';

  @override
  String get materialsPreview => '預覽';

  @override
  String materialsPreviewCounts(int items, int symbols, int prosigns) {
    return '$items 項 · $symbols 個字元 · $prosigns 個程序信號';
  }

  @override
  String materialsPreviewUnsupported(String chars) {
    return '無摩斯碼，練習時略過：$chars';
  }

  @override
  String materialsPreviewDuplicates(int count) {
    return '$count 個重複項只保留一次';
  }

  @override
  String get materialsProblemEmpty => '請先輸入文字。';

  @override
  String get materialsProblemTooLarge => '過大：素材上限為 1 MiB。';

  @override
  String materialsProblemTooManyEntries(int count) {
    return '條目過多：最多 $count 條。';
  }

  @override
  String materialsProblemEntryTooLong(int count) {
    return '某個條目過長：每條最多 $count 個字元。';
  }

  @override
  String get materialsProblemNothingTrainable => '這裡沒有可以用摩斯碼練習的內容。';

  @override
  String get materialsSearch => '搜尋素材';

  @override
  String get materialsFavoritesOnly => '收藏';

  @override
  String get materialsFavorite => '加入收藏';

  @override
  String get materialsUnfavorite => '取消收藏';

  @override
  String get materialsEmpty => '還沒有素材。新增你自己的文字、單字表或呼號，或儲存一則聊天訊息。';

  @override
  String materialsItems(int count) {
    return '$count 項';
  }

  @override
  String get materialsFromChat => '來自聊天';

  @override
  String get materialsActions => '素材操作';

  @override
  String get materialsPractise => '練習';

  @override
  String get materialsDelete => '刪除';

  @override
  String get materialsDeleteTitle => '刪除素材？';

  @override
  String materialsDeleteBody(String title) {
    return '「$title」將從本裝置刪除，練習紀錄會保留。';
  }

  @override
  String get materialsImport => '匯入 TXT 或 JSON';

  @override
  String get materialsImportDialogTitle => '選擇素材檔案';

  @override
  String get materialsSaveDialogTitle => '儲存素材';

  @override
  String get materialsImportFailed => '匯入失敗，素材庫未變更。';

  @override
  String get materialsImportNotUtf8 => '只能匯入 UTF-8 文字檔。';

  @override
  String get materialsImportInvalid => '不是有效的 DitMesh 素材檔，未匯入任何內容。';

  @override
  String materialsImported(int count) {
    return '已匯入 $count 個素材。';
  }

  @override
  String get materialsDuplicateTitle => '部分素材已存在';

  @override
  String get materialsDuplicateOverwrite => '取代';

  @override
  String get materialsDuplicateKeepCopy => '兩者都保留（作為副本匯入）';

  @override
  String get materialsDuplicateSkip => '略過';

  @override
  String get materialsExportJson => '匯出為 JSON';

  @override
  String materialsExported(int count) {
    return '已匯出 $count 個素材。';
  }

  @override
  String get materialsExportFailed => '匯出失敗。';

  @override
  String get materialsExportWav => '匯出音訊（WAV）';

  @override
  String materialsWavCharSpeed(int wpm) {
    return '字元速度：$wpm WPM';
  }

  @override
  String materialsWavEffSpeed(int wpm) {
    return '有效速度：$wpm WPM';
  }

  @override
  String materialsWavTone(int hz) {
    return '音調：$hz Hz';
  }

  @override
  String get materialsWavWithAnswer => '附帶答案文字（.txt）';

  @override
  String get materialsWavFormat => '16 位元單聲道 WAV，48 kHz。';

  @override
  String materialsWavParts(int count) {
    return '超過 10 分鐘：將匯出為 $count 個檔案。';
  }

  @override
  String materialsWavExported(int count) {
    return '已儲存 $count 個音訊檔。';
  }

  @override
  String get materialsPracticeMode => '練習範圍';

  @override
  String get materialsPracticeLearned => '僅已學字元';

  @override
  String materialsPracticeLearnedPartial(int count) {
    return '僅已學字元（$count 項不可用：含尚未學習的字元）';
  }

  @override
  String get materialsPracticeAll => '所有摩斯字元';

  @override
  String get materialsPracticeNothing => '此模式下沒有可練習的條目。';

  @override
  String get guestTryLearning => '先試試學習';

  @override
  String get guestBanner => '訪客學習：進度儲存在本裝置。聊天需要身分。';

  @override
  String get guestGetIdentity => '設定身分';

  @override
  String get guestIdentityTitle => '需要身分';

  @override
  String get guestIdentityBody => '透過 Tox 聊天需要你自己的身分。可以新建、從備份還原，或解鎖本裝置上的身分。新建身分時，訪客學習進度會自動轉移過去。';

  @override
  String get guestClearData => '清除訪客學習資料';

  @override
  String get guestClearDataBody => '刪除你在本裝置以訪客身分產生的進度、計畫和素材。不影響任何身分。';

  @override
  String get guestClearConfirm => '清除';

  @override
  String get guestCleared => '已清除訪客學習資料。';

  @override
  String get guestClearFailed => '無法清除訪客資料。';

  @override
  String get guestMigrationFailed => '身分已就緒，但訪客學習進度尚未轉移，資料仍安全儲存在本裝置。';

  @override
  String get guestChoiceBody => '你還有訪客學習進度。目前使用的是還原身分的進度，沒有合併任何內容。';

  @override
  String get guestChoiceKeep => '保留還原的進度';

  @override
  String get guestChoiceUseGuest => '改用訪客進度';

  @override
  String get placementTitle => '測試我的程度';

  @override
  String get placementCheckLevel => '測試我現在的程度';

  @override
  String get placementFromZero => '從零開始';

  @override
  String get placementOfferTitle => '剛接觸摩斯碼，還是已經會抄收？';

  @override
  String get placementOfferBody => '簡短測試可以建議起點。測試是可選的，在你選擇前不會改變任何設定。';

  @override
  String get placementIntro => '約 3–5 分鐘，分五步抄收：先按柯赫順序分組、速度逐級提高，最後是短單字。這只是基於少量樣本的粗略參考，不是認證。隨時可以停止。';

  @override
  String get placementStart => '開始';

  @override
  String get placementSkip => '略過';

  @override
  String get placementStop => '停止';

  @override
  String placementTierProgress(int step, int total, int wpm) {
    return '第 $step/$total 步 · 有效速度 $wpm WPM';
  }

  @override
  String get placementTierPassed => '抄得很好，下一步更快。';

  @override
  String get placementTierStopped => '這一步低於 90%，測試到此結束。';

  @override
  String get placementNextTier => '下一步';

  @override
  String placementSuggestion(int lesson) {
    return '建議從第 $lesson 課開始';
  }

  @override
  String placementVerified(int count, int total) {
    return '依順序確認了 $total 個柯赫字元中的 $count 個。';
  }

  @override
  String get placementLimits => '基於少量樣本：未測到的字元仍視為未測試，也不會被標記為已掌握。你可以隨時變更課程。';

  @override
  String placementAdopt(int lesson) {
    return '從第 $lesson 課開始';
  }

  @override
  String get chatJumpToLatest => '最新訊息';

  @override
  String get chatMessageGone => '該訊息已不在此對話中。';

  @override
  String get chatListenOnlyPreview => '新訊息——請收聽抄收';

  @override
  String get chatSaveMaterialConfirm => '儲存其餘部分';

  @override
  String materialsImportConfirm(int count) {
    return '匯入 $count 個素材？';
  }

  @override
  String get materialsExportTxt => '匯出為文字（TXT）';

  @override
  String get accountBackupMediaTitle => '包含已儲存的錄音嗎？';

  @override
  String accountBackupMediaBody(int count, String size) {
    return '已儲存 $count 段錄音（$size MB）。標題、備註和位置一律在備份中；音訊僅在你選擇包含時才會加入。';
  }

  @override
  String accountBackupMediaTooLarge(String size) {
    return '已儲存的錄音（$size MB）太大，無法放入備份；只會包含標題、備註和位置。';
  }

  @override
  String get accountBackupMediaInclude => '包含錄音';

  @override
  String get accountBackupMediaSkip => '不含錄音';

  @override
  String get diagTitle => '連線診斷';

  @override
  String get diagOpenSubtitle => '訊息為何在等待，以及如何重新連線';

  @override
  String get diagBannerDetails => '詳情';

  @override
  String get diagSummaryNoIdentity => '尚未開啟身分，沒有可檢查的連線。';

  @override
  String get diagSummaryOnlinePeerOnline => '你已連線到 Tox 網路，且該聯絡人在線。訊息會直接送達對方。';

  @override
  String get diagSummaryOnlinePeerOffline => '你已連線，但該聯絡人離線。訊息會留在本機的待發佇列中，對方上線後自動傳送。';

  @override
  String get diagSummaryOnline => '你已連線到 Tox 網路。';

  @override
  String get diagSummaryConnecting => '正在連線 Tox 網路。應用程式啟動或網路切換後可能需要一分鐘左右。';

  @override
  String get diagSummaryOffline => '你未連線到 Tox 網路。連線恢復前無法收發任何訊息。';

  @override
  String get diagLocalLabel => '本機連線';

  @override
  String diagSinceChanged(String time) {
    return '自 $time 起';
  }

  @override
  String diagSinceFirst(String time) {
    return '自 $time 起觀察到';
  }

  @override
  String diagSinceResumed(String time) {
    return '自 $time 回到應用程式後觀察到';
  }

  @override
  String get diagLastOnlineLabel => '最近一次觀察到的連線';

  @override
  String get diagLastOnlineNow => '目前已連線';

  @override
  String get diagLastOnlineNone => '尚未觀察到連線。';

  @override
  String get diagLastOnlineHint => '這是本機最後一次觀察到自身連線的時間，並非訊息送達對方的時間。';

  @override
  String get diagPeerLabel => '聯絡人';

  @override
  String get diagUnknown => '未知';

  @override
  String get diagPeerUnknownHint => '只有在你已連線時才能看到聯絡人是否在線。';

  @override
  String get diagPeerGroupHint => '群組成員是否在線請查看成員列表。';

  @override
  String get diagPendingLabel => '待傳送';

  @override
  String get diagPendingNone => '沒有待傳訊息';

  @override
  String diagPendingCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 則訊息',
    );
    return '$_temp0';
  }

  @override
  String diagPendingOldest(String time) {
    return '最早一則排隊於 $time';
  }

  @override
  String get diagPendingUnknown => '聊天連線後才能得知';

  @override
  String get diagPendingHint => '排隊的訊息保存在本機，對方可達時會自動傳送。診斷頁面不會捨棄或重送它們。';

  @override
  String get diagReconnect => '重新連線';

  @override
  String get diagReconnecting => '正在重新連線…';

  @override
  String diagReconnectFailed(String reason) {
    return '重新連線失敗：$reason';
  }

  @override
  String get diagReconnectNote => '重新連線會重新發起連線嘗試。上線仍可能需要一段時間，屆時本頁會自動更新。';

  @override
  String get diagAboutTitle => 'DitMesh 如何連線';

  @override
  String get diagAboutBody => 'DitMesh 沒有伺服器。你的裝置透過 Tox 點對點網路直接與聯絡人通訊，因此雙方必須同時在線訊息才能送達。手機會暫停背景應用程式：DitMesh 在背景無法保持連線，回到應用程式時會重新連線。';

  @override
  String get diagDetailsTitle => '技術詳情';

  @override
  String get diagDetailIdentity => '身分';

  @override
  String get diagDetailStatus => '狀態';

  @override
  String get diagDetailObserved => '觀察時間';

  @override
  String get diagDetailQueued => '佇列項目';

  @override
  String get diagDetailError => '最近錯誤代碼';

  @override
  String get backupXTitle => '加密備份';

  @override
  String get backupXIntro => '選擇要帶到其他裝置的內容。整個檔案都會用你在此設定的通關密語加密。';

  @override
  String get backupXCategoryIdentity => '身分與 Tox 設定檔';

  @override
  String get backupXCategoryTraining => '訓練進度與素材';

  @override
  String get backupXCategoryChat => '聊天紀錄（含給自己的筆記）';

  @override
  String get backupXCategoryMeta => '草稿、置頂與書籤';

  @override
  String get backupXCategoryPrefs => '應用程式偏好設定';

  @override
  String get backupXPrefsHint => '播放、通知、外觀與語言。不含視窗位置與按鍵綁定。';

  @override
  String get backupXCategoryMedia => '已儲存的錄音';

  @override
  String get backupXMediaHint => '預設不包含：錄音可能很大。不包含時只帶走標題與備註。';

  @override
  String get backupXCategoryPending => '未傳送的訊息';

  @override
  String get backupXPendingHint => '還原後僅供查看，絕不會自動傳送。';

  @override
  String get backupXRequired => '必選';

  @override
  String backupXSizeLine(int count, String size) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 項',
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
    return '太大，無法包含（$size）';
  }

  @override
  String backupXInvitesNote(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '有 $count 個等待離線好友的群組邀請不會被帶走。',
    );
    return '$_temp0';
  }

  @override
  String get backupXIdentityPasswordNote => '身分密碼仍保留在設定檔上：新裝置除備份通關密語外還會要求輸入它。';

  @override
  String backupXTotal(String size) {
    return '總計約 $size';
  }

  @override
  String get backupXPassphrase => '備份通關密語';

  @override
  String get backupXPassphraseConfirm => '再次輸入通關密語';

  @override
  String get backupXPassphraseHint => '至少 8 個字元。它與身分密碼相互獨立，且無法找回。';

  @override
  String get backupXPassphraseTooShort => '請至少使用 8 個字元';

  @override
  String get backupXPassphraseMismatch => '兩次輸入的通關密語不一致';

  @override
  String get backupXExport => '建立加密備份';

  @override
  String get backupXExporting => '正在建立備份…';

  @override
  String get backupXMigrationNote => '要換裝置？在新裝置還原後，請停止在本機使用此身分：同一身分的兩台裝置可能把同一則訊息傳送兩次。';

  @override
  String get backupXBusy => '備份過程中資料持續變化，請重試。';

  @override
  String get backupXTooLarge => '備份太大。請去掉錄音後重試。';

  @override
  String get restoreXWrongPassphrase => '通關密語錯誤，或檔案已被修改、不完整。';

  @override
  String get restoreXUnsupported => '此備份由更新版本的 DitMesh 建立。';

  @override
  String get restoreXCheck => '開啟備份';

  @override
  String get restoreXPreviewTitle => '備份內容';

  @override
  String restoreXCreated(String date) {
    return '建立於 $date';
  }

  @override
  String get restoreXIncluded => '包含';

  @override
  String get restoreXExcluded => '不在此備份中';

  @override
  String restoreXPendingIncluded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 則未傳送的訊息將還原供你查看，不會自動傳送。',
    );
    return '$_temp0';
  }

  @override
  String restoreXPendingExcluded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '舊裝置上的 $count 則未傳送訊息不在此備份中。',
    );
    return '$_temp0';
  }

  @override
  String get restoreXIdentityPassword => '身分密碼';

  @override
  String get restoreXIdentityPasswordNote => '此備份中的身分另設有密碼，請一併輸入。';

  @override
  String get restoreXConfirmTitle => '取代本機上的身分？';

  @override
  String get restoreXConfirmBody => '本機上的身分與資料將被備份取代。在此連線之前，請先停止在舊裝置上使用該身分。';

  @override
  String get restoreXConfirm => '取代並還原';

  @override
  String get restoreXReportTitle => '還原完成';

  @override
  String get restoreXReportRestored => '已還原';

  @override
  String get restoreXReportNotIncluded => '未還原';

  @override
  String get restoreXReportPrefsFailed => '偏好設定未能套用，已保留原有設定。';

  @override
  String restoreXReportPendingReview(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '有 $count 則未傳送的訊息在「聊天」中等你查看。',
    );
    return '$_temp0';
  }

  @override
  String restoreXReportPendingNotResumed(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '舊裝置上的 $count 則未傳送訊息未被帶過來。',
    );
    return '$_temp0';
  }

  @override
  String restoreXReportInvites(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '有 $count 個排隊中的群組邀請未重新傳送。',
    );
    return '$_temp0';
  }

  @override
  String get restoreXReportStopOld => '請停止在舊裝置上使用此身分。';

  @override
  String get restoreXReportDone => '完成';

  @override
  String pendingReviewBanner(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '來自舊裝置的 $count 則未傳送訊息',
    );
    return '$_temp0';
  }

  @override
  String get pendingReviewTitle => '未傳送的訊息';

  @override
  String get pendingReviewBody => '這些訊息在舊裝置上等待傳送。DitMesh 絕不會自動傳送；如仍需要，請重新拍發。';

  @override
  String pendingReviewQueuedAt(String time) {
    return '於 $time 在舊裝置上排隊';
  }

  @override
  String get pendingReviewDismiss => '忽略';

  @override
  String get pendingReviewDismissAll => '全部忽略';

  @override
  String get pendingReviewEmpty => '沒有需要查看的內容了。';

  @override
  String get backupXWizardInside => '備份檔案會用你自選的通關密語整體加密，包含身分金鑰與訓練進度。請把檔案與通關密語保存在本機以外的安全位置。';

  @override
  String get backupXMeSubtitle => '包含身分、聊天與進度的加密檔案，可留存或移轉到其他裝置';

  @override
  String get conditionsTitle => '收聽環境';

  @override
  String get conditionsClear => '清晰';

  @override
  String get conditionsLight => '輕度干擾';

  @override
  String get conditionsRadio => '實戰電台';

  @override
  String get conditionsClearHint => '乾淨穩定的音調，即一般練習。';

  @override
  String get conditionsLightHint => '輕微底噪與緩慢衰落。成績與清晰練習分開記錄。';

  @override
  String get conditionsRadioHint => '雜訊、深度衰落、鄰近電台干擾與略不均勻的節奏。成績與清晰練習分開記錄。';

  @override
  String get conditionsPreview => '試聽';

  @override
  String conditionsActive(String name) {
    return '收聽環境：$name';
  }

  @override
  String get conditionsNeedSound => '電台環境只能聽不能看：請在訓練設定中開啟聲音，或改用「清晰」環境練習。';

  @override
  String get conditionsCleanReplay => '無效果重播';

  @override
  String conditionsComparable(int count, int accuracy) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '在此環境與速度下共 $count 次：平均 $accuracy%',
    );
    return '$_temp0';
  }

  @override
  String get conditionsSeparateNote => '電台環境練習計入活動，但不會改變課程進度、複習計畫或速度建議。';

  @override
  String get keysTitle => '按鍵與外接電鍵';

  @override
  String get keysMeSubtitle => '按鍵綁定、雙槳與 USB 電鍵轉接器';

  @override
  String get keysIntro => '選擇用哪些鍵拍發摩斯。模擬鍵盤的 USB 電鍵／雙槳轉接器與鍵盤相同，請在此設定其按鍵。應用程式無法分辨按鍵來自哪個裝置，因此設定方案就是一組按鍵綁定。';

  @override
  String get keysStandardProfile => '標準';

  @override
  String get keysUnnamed => '未命名方案';

  @override
  String get keysEdit => '編輯';

  @override
  String get keysNewProfile => '新增方案';

  @override
  String get keysLimitations => '不支援 MIDI、序列埠與藍牙電鍵，也不支援轉接器韌體設定與電台控制。已測試的轉接器列在文件中。';

  @override
  String get keysEditTitle => '按鍵方案';

  @override
  String get keysName => '方案名稱';

  @override
  String get keysActionStraight => '手鍵';

  @override
  String get keysActionDit => '點槳';

  @override
  String get keysActionDah => '劃槳';

  @override
  String get keysPressKey => '請按一個鍵…';

  @override
  String get keysNone => '未設定';

  @override
  String get keysSet => '設定';

  @override
  String keysReserved(String key) {
    return '$key 已被系統或應用程式佔用，請換一個鍵。';
  }

  @override
  String keysConflict(String key, String action) {
    return '$key 已用於「$action」。';
  }

  @override
  String keysConflictSave(String keys) {
    return '每個鍵只能有一種用途：$keys 被重複綁定。';
  }

  @override
  String get keysMissing => '請設定此電鍵模式需要的鍵（自動鍵需同時設定兩隻槳）。';

  @override
  String get keysSwapPaddles => '交換雙槳（左手）';

  @override
  String get keysKeyerMode => '電鍵模式';

  @override
  String get keysIambicA => '自動鍵 A';

  @override
  String get keysIambicB => '自動鍵 B';

  @override
  String get keysAdapterKeyer => '轉接器自行產生點劃';

  @override
  String get keysAdapterKeyerHint => '適用於內建電鍵邏輯的轉接器：直接使用它計時好的按下與放開，應用程式不會再產生一遍自動鍵序列。';

  @override
  String get keysAppSidetone => '拍發時的應用程式側音';

  @override
  String get keysAppSidetoneHint => '轉接器內建側音時請關閉。不影響解碼。';

  @override
  String get keysTestTitle => '測試';

  @override
  String get keysTestNote => '僅用於測試：不會傳送，也不計入訓練。';

  @override
  String get keysTestRelease => '放開按鍵';

  @override
  String get keysAdapterActive => '正在使用轉接器內建的電鍵邏輯：槳對應的鍵按手鍵處理。';

  @override
  String keysHintCustom(String keys) {
    return '按鍵：$keys';
  }

  @override
  String get telegraphTitle => '中文電碼';

  @override
  String get telegraphIntro => '每個漢字以四位數字碼拍發。分別練習聽寫數字，以及記住哪個碼對應哪個字。';

  @override
  String get telegraphCodebook => '碼本';

  @override
  String get telegraphCodebookMainland => '大陸';

  @override
  String get telegraphCodebookTaiwan => '臺灣';

  @override
  String get telegraphDigitsTitle => '抄收電碼組';

  @override
  String get telegraphDigitsHint => '收聽真實電碼的四位數字組並輸入數字。';

  @override
  String telegraphDigitsResults(int count, int accuracy) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '共 $count 次：數字正確率 $accuracy%',
    );
    return '$_temp0';
  }

  @override
  String get telegraphRecallTitle => '記憶碼本';

  @override
  String get telegraphRecallHint => '由字查碼、由碼認字。與摩斯進度分開記錄。';

  @override
  String telegraphRecallResults(int count, int accuracy) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '已答 $count 張：掌握 $accuracy%',
    );
    return '$_temp0';
  }

  @override
  String get telegraphSeparateNote => '碼本記憶不會解鎖摩斯課程，也不改變速度建議；數字抄收與其他摩斯抄收同等計入。';

  @override
  String get telegraphRecallCharPrompt => '輸入這個字的電碼';

  @override
  String get telegraphRecallCodePrompt => '選出這個電碼對應的字';

  @override
  String get telegraphReveal => '顯示答案';

  @override
  String get telegraphRevealAssisted => '已顯示：本題計為有提示。';

  @override
  String get telegraphCorrect => '正確';

  @override
  String get telegraphIncorrect => '不對';

  @override
  String telegraphRecallSummary(int correct, int total) {
    return '$total 題中答對 $correct 題';
  }

  @override
  String telegraphRecallAssisted(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '有 $count 題看過答案',
    );
    return '$_temp0';
  }

  @override
  String get telegraphInterpretAction => '按中文電碼解讀';

  @override
  String get telegraphInterpretTitle => '電碼解讀';

  @override
  String get telegraphInterpretNote => '僅在此顯示：不會修改原訊息，也不會傳送任何內容。';

  @override
  String get telegraphUnresolved => '無法解讀：沒有字對應此碼';

  @override
  String get telegraphMalformed => '不是四位數字組';

  @override
  String get telegraphNotCode => '文字，保持原樣';

  @override
  String get telegraphAmbiguous => '多個字共用此碼';

  @override
  String get groupPracticeTitle => '群組帶練';

  @override
  String get groupPracticeIntro => '帶練者照常在群聊中拍發練習內容。每位成員在此選擇練習訊息，按自己的速度抄收。答案與成績只保存在本機，不會傳送到群組。';

  @override
  String get groupPracticeNew => '新增練習';

  @override
  String get groupPracticeTitleField => '標題';

  @override
  String get groupPracticeCreate => '建立';

  @override
  String get groupPracticeInstructor => '帶練者';

  @override
  String get groupPracticeParticipant => '參與者';

  @override
  String get groupPracticeInstructorHint => '在群聊中拍發每道練習，在此新增為一輪並勾選完成；輪次請在群聊裡通知。';

  @override
  String get groupPracticeParticipantHint => '把帶練者的練習訊息新增為輪次，並在此逐一抄收。';

  @override
  String get groupPracticeLocalNote => '僅限本機：輪次、角色與成績不會與其他成員同步，錯過的訊息也不一定能送達所有人。';

  @override
  String get groupPracticeAddRound => '新增練習';

  @override
  String get groupPracticeNoMessages => '最近紀錄中沒有可新增的訊息。';

  @override
  String get groupPracticeNotConnected => '聊天連線後才能讀取群組紀錄。';

  @override
  String get groupPracticeRoundOpen => '待完成';

  @override
  String get groupPracticeRoundDone => '已完成';

  @override
  String get groupPracticeRoundUnavailable => '不可用';

  @override
  String get groupPracticeSourceGone => '該練習訊息已不在紀錄中。';

  @override
  String get groupPracticeSourceLoading => '正在尋找訊息…';

  @override
  String groupPracticeAttemptResult(int accuracy, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '抄收：$accuracy%（$count 次）',
    );
    return '$_temp0';
  }

  @override
  String get groupPracticeCopy => '抄收';

  @override
  String get groupPracticeRemoveRound => '移除本輪';

  @override
  String get groupPracticeSummary => '小結';

  @override
  String groupPracticeRoundsDone(int done, int total) {
    return '已完成 $done/$total 輪';
  }

  @override
  String groupPracticeUnavailableCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 輪不可用',
    );
    return '$_temp0';
  }

  @override
  String groupPracticeAccuracy(int accuracy) {
    return '抄收正確率：$accuracy%';
  }

  @override
  String groupPracticeAssisted(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 次使用了提示',
    );
    return '$_temp0';
  }

  @override
  String groupPracticeShareHint(int done, int total, int accuracy) {
    return '如需分享，請自行在群聊中拍發成績，例如 $done/$total $accuracy%。不會自動傳送。';
  }

  @override
  String get groupPracticeComplete => '結束練習';

  @override
  String get groupPracticeDeleteTitle => '刪除這次練習？';

  @override
  String get groupPracticeDeleteBody => '本機上的輪次與成績將被刪除；訓練紀錄與群組訊息保留。';

  @override
  String get conditionsAudioFailed => '本裝置無法播放音訊。請改用「清晰」環境練習。';

  @override
  String get moderationBlock => '封鎖';

  @override
  String moderationBlockTitle(String name) {
    return '封鎖 $name？';
  }

  @override
  String get moderationBlockFriendBody => '對方將被移出好友，與其的對話也會被刪除。此後其訊息、好友請求和群組邀請都不會再出現在此裝置上。對方不會收到通知。';

  @override
  String get moderationBlockMemberBody => '此後其在本群組的訊息都不會再出現在此裝置上。對方不會收到通知。Tox 為每位群組成員在每個群組中使用不同的金鑰，因此僅對本群組生效。';

  @override
  String get moderationBlocked => '已封鎖';

  @override
  String get moderationUnblock => '解除封鎖';

  @override
  String get moderationUnblocked => '已解除封鎖';

  @override
  String get moderationBlockedTitle => '已封鎖的人';

  @override
  String get moderationBlockedSubtitle => '隱藏其訊息、請求和邀請';

  @override
  String get moderationBlockedEmpty => '你尚未封鎖任何人。';

  @override
  String get moderationBlockedNote => '封鎖在此裝置上生效：Tox 沒有中央伺服器，被封鎖的人仍可能嘗試聯絡你，但他們的任何內容都不會在這裡顯示。';

  @override
  String get termsGateTitle => '社群準則';

  @override
  String get termsGateIntro => 'DitMesh 聊天讓你與他人直接連線，中間沒有伺服器。開始之前，請同意以下規則：';

  @override
  String get termsGateRuleZero => '零容忍：禁止騷擾、仇恨、威脅、涉及未成年人的性內容、垃圾訊息以及任何違法內容。';

  @override
  String get termsGateRuleContacts => '只有你接受的人才能傳訊息給你；群組須透過邀請或群組 ID 加入。';

  @override
  String get termsGateRuleBlock => '可以在對話、群組成員清單、好友請求或群組邀請中封鎖任何人。';

  @override
  String get termsGateAgree => '同意並繼續';

  @override
  String get termsGateReadFull => '閱讀完整使用條款';

  @override
  String get termsGateSaveFailed => '無法儲存你的選擇，請再試一次。';

  @override
  String get aboutPrivacyPolicy => '隱私權政策';

  @override
  String get aboutTermsOfUse => '使用條款';

  @override
  String get aboutSupport => '技術支援與聯絡';

  @override
  String get aboutLinkFailed => '無法開啟連結，已複製連結。';

  @override
  String get errorPeerBlocked => '你已封鎖此人。請先在「我 → 已封鎖的人」中解除封鎖。';

  @override
  String get offlineClearData => '清除學習資料';

  @override
  String get offlineClearDataBody => '刪除此裝置上的學習進度、計畫和材料。';

  @override
  String get offlineCleared => '學習資料已清除。';

  @override
  String get offlineClearFailed => '無法清除學習資料。';

  @override
  String get learnStorageUnavailable => '無法在此裝置上開啟你的訓練資料，請再試一次。';

  @override
  String get backendStartupFailedTitle => '聊天後端無法使用';

  @override
  String get backendStartupFailedBody => 'DitMesh 無法啟動 Tox 網路後端。請確認原生函式庫已安裝，然後重試。';

  @override
  String get bootstrapTitle => '網路與引導節點';

  @override
  String get bootstrapDescription => '選擇加入 Tox 網路所使用的公共節點。';

  @override
  String get bootstrapModeAuto => '自動';

  @override
  String get bootstrapModeManual => '手動';

  @override
  String get bootstrapModeLan => 'LAN 託管';

  @override
  String get bootstrapAutoDescription => '先使用內建節點，再於背景更新官方清單。';

  @override
  String get bootstrapManualDescription => '只使用你選擇的節點，也可在此填寫區域網路節點。';

  @override
  String get bootstrapLanDescription => '在此桌面裝置上執行本地 UDP/DHT 節點，供其他區域網路裝置使用。';

  @override
  String get bootstrapCurrentNode => '目前節點';

  @override
  String get bootstrapHost => '主機名稱或 IP 位址';

  @override
  String get bootstrapPort => 'UDP 連接埠';

  @override
  String get bootstrapPublicKey => 'DHT 公開金鑰';

  @override
  String get bootstrapTestNode => '測試節點';

  @override
  String get bootstrapSaveNode => '使用已測試節點';

  @override
  String get bootstrapChooseNode => '選擇公共節點';

  @override
  String get bootstrapReachable => '已收到 DHT 回應';

  @override
  String get bootstrapUnreachable => '未收到 DHT 回應';

  @override
  String get bootstrapInvalid => '主機、連接埠或公開金鑰無效';

  @override
  String get bootstrapUdpUnavailable => '此裝置無法進行 UDP 探測，尚未測試 TCP 連線。';

  @override
  String get bootstrapProbeUnavailable => '探測無法啟動，這不能說明節點是否可達。';

  @override
  String get bootstrapFallback => '無法載入官方清單，正在顯示內建備用節點。';

  @override
  String get bootstrapMaintainer => '維護者';

  @override
  String get bootstrapLocation => '位置';

  @override
  String get bootstrapLastPing => '最近公共檢查';

  @override
  String get bootstrapSwitchTitle => '切換引導節點';

  @override
  String get bootstrapSwitchQuestion => '使用此節點？';

  @override
  String get bootstrapNotTestedWarning => '此節點尚未在你的裝置上測試。';

  @override
  String get bootstrapFailedWarning => '此節點未回應 UDP 探測，你仍然可以選擇它。';

  @override
  String get bootstrapInconclusiveWarning => '探測沒有明確結論，尚未測試 TCP 連線。';

  @override
  String get bootstrapSwitchConfirm => '使用節點';

  @override
  String get bootstrapRefresh => '更新清單';

  @override
  String get bootstrapStartLan => '啟動 LAN 節點';

  @override
  String get bootstrapStopLan => '停止 LAN 節點';

  @override
  String get bootstrapLanStopped => 'LAN 節點已停止';

  @override
  String get bootstrapLanRunning => 'LAN 節點正在執行';

  @override
  String get bootstrapLanKeyChanges => '節點重新啟動後 DHT 公開金鑰會變更，請分享目前完整金鑰。';

  @override
  String get bootstrapLanFirewallHint => '其他裝置需要透過本地防火牆存取此 UDP 連接埠。';

  @override
  String get bootstrapCopyNode => '複製節點資訊';

  @override
  String get bootstrapShareNode => '分享節點資訊';

  @override
  String get bootstrapOperationFailed => '無法套用此網路設定。';

  @override
  String get bootstrapServiceUnavailable => '此後端無法使用網路設定。';

  @override
  String get bootstrapSource => '官方公共節點清單';

  @override
  String get bootstrapOnline => '在線';

  @override
  String get bootstrapOffline => '離線';

  @override
  String bootstrapProtocolStatus(String udp, String tcp) {
    return 'UDP：$udp · TCP：$tcp';
  }

  @override
  String get errorNotFriend => '對方已不在你的好友名單中。重新加入後才能傳送訊息。';

  @override
  String get chatAcceptWithPassword => '使用密碼接受';

  @override
  String chatGroupPasswordTitle(String name) {
    return '$name 的密碼';
  }

  @override
  String get chatGroupPasswordField => '群組密碼';

  @override
  String chatGroupJoinRefusedPassword(String name) {
    return '$name 拒絕了加入：密碼錯誤或未填寫。';
  }

  @override
  String chatGroupJoinRefusedFull(String name) {
    return '$name 拒絕了加入：群組已滿。';
  }

  @override
  String chatGroupJoinRefused(String name) {
    return '$name 拒絕了加入。';
  }

  @override
  String chatGroupReconnectRefused(String name) {
    return '$name 拒絕了重新連線。歷史紀錄已保留；請使用群組密碼重試。';
  }

  @override
  String get firstChatTitle => '第一次電碼聊天';

  @override
  String get firstChatStart => '開始體驗';

  @override
  String get firstChatDismiss => '收起引導';

  @override
  String get firstChatKeyTitle => '1. 給自己拍發 CQ';

  @override
  String get firstChatKeyBody => '用電鍵拍發 CQ：短按是點，長按是劃。解碼後的草稿保持唯讀。';

  @override
  String get firstChatSelf => '在傳給自己中試一試';

  @override
  String get firstChatListenTitle => '2. 試聽與更正';

  @override
  String get firstChatListenBody => '傳送前點試聽來聽草稿，用退格刪除錯誤。傳送後點訊息上的播放按鈕。傳給自己的訊息只儲存在本機。';

  @override
  String get firstChatFriendTitle => '3. 與好友聊天';

  @override
  String get firstChatFriendBody => '開啟聯絡人，透過 QR 碼或 Tox ID 加入好友，等待對方接受邀請。';

  @override
  String get firstChatFriend => '加入好友';

  @override
  String get firstChatOnline => '雙方應用程式都保持執行且網路可達時，訊息才能送到好友。';

  @override
  String get pendingMessagesTitle => '待傳送與失敗訊息';

  @override
  String get pendingMessagesExplanation => '排隊訊息儲存在本機，雙方應用程式連線後繼續傳送。可取消排隊訊息，或重試已確認失敗的訊息。';

  @override
  String get pendingMessagesEmpty => '沒有待傳送或失敗訊息';

  @override
  String get deliveryDetailsTitle => '投遞詳情';

  @override
  String get deliveryLocalTitle => '已儲存到本機';

  @override
  String get deliveryLocalDetail => '這則傳給自己的訊息已儲存在本機。';

  @override
  String get deliverySentDetail => '本機已將訊息交給傳輸層，正在等待對方確認接收。';

  @override
  String get deliveryPeerTitle => '對方已接收';

  @override
  String get deliveryPeerDetail => '對方已確認接收；這不代表對方已經閱讀或收聽。';

  @override
  String get deliveryGroupTitle => '群組成員已接收';

  @override
  String get deliveryGroupDetail => '至少一名群組成員已確認接收，其他成員仍可能離線。';

  @override
  String get deliveryLocalOffline => '本機尚未連線。';

  @override
  String get deliveryPeerOffline => '好友目前離線。';

  @override
  String get deliveryGroupWaiting => '正在等待連線到群組。';

  @override
  String get chatPreviewDraft => '試聽草稿';

  @override
  String get chatStopPreview => '停止試聽';

  @override
  String get chatMessagePlayback => '訊息播放器';

  @override
  String get chatOriginalRhythm => '原始拍發節奏';

  @override
  String get chatListenerRhythm => '我的收聽速度';

  @override
  String get chatOriginalAvailable => '已儲存實際按鍵與間隔時長。';

  @override
  String get chatOriginalUnavailable => '無可用原始節奏，將按你的收聽速度播放。';

  @override
  String get chatOriginalPlaying => '正在播放原始節奏';

  @override
  String get chatListenerPlaying => '正在按你的收聽速度播放';

  @override
  String get chatPause => '暫停';

  @override
  String get chatResume => '繼續';

  @override
  String get chatPreviousWord => '上一詞';

  @override
  String get chatNextWord => '下一詞';

  @override
  String chatWordNumber(int number) {
    return '第 $number 詞';
  }

  @override
  String get chatRangeStart => '起始詞';

  @override
  String get chatRangeEnd => '結束詞';

  @override
  String get chatRepeatRange => '重播選定詞段';

  @override
  String get chatLoopRange => '循環選定詞段';

  @override
  String get chatPlaybackProgress => '播放進度';

  @override
  String chatWordProgress(int current, int total) {
    return '第 $current / $total 詞';
  }

  @override
  String get chatOriginalPreference => '有相符的錄音時使用原始拍發節奏。';

  @override
  String chatConversationActions(String name) {
    return '$name 的操作';
  }

  @override
  String get chatDraftSaveFailed => '草稿未能儲存。請保持此畫面開啟，或立即傳送。';

  @override
  String get chatSearchClearDates => '清除日期範圍';

  @override
  String chatGroupReconnectFailed(String name) {
    return '$name 拒絕了重新連線。歷史紀錄已保留；可以重試。';
  }
}
