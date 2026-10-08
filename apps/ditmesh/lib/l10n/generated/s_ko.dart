// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 's.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class SKo extends S {
  SKo([String locale = 'ko']) : super(locale);

  @override
  String get appName => 'DitMesh';

  @override
  String get navLearn => '학습';

  @override
  String get navChat => '채팅';

  @override
  String get navGroups => '그룹';

  @override
  String get navMe => '내 정보';

  @override
  String get navReference => '참고';

  @override
  String get navLearnDescription => 'Koch 방식 강의, 송신 연습과 수신 받아쓰기 연습.';

  @override
  String get navChatDescription => 'Tox P2P를 통한 서버 없는 일대일 모스 통신.';

  @override
  String get navGroupsDescription => '그룹 통신망 — 여러 운용자가 하나의 채널을 공유하며 송신합니다.';

  @override
  String get navReferenceDescription => '문자표, 절차 부호, Q 부호, 약어와 양방향 변환기.';

  @override
  String get navMeDescription => '콜사인, Tox 신원 정보, 학습 진도와 설정.';

  @override
  String get shellOfflineBanner => '오프라인: Tox 네트워크에 연결되지 않았습니다. 온라인으로 돌아오면 메시지를 보냅니다.';

  @override
  String get actionOk => '확인';

  @override
  String get actionCancel => '취소';

  @override
  String get actionSave => '저장';

  @override
  String get actionDelete => '삭제';

  @override
  String get actionCopy => '복사';

  @override
  String get actionShare => '공유';

  @override
  String get actionRetry => '다시 시도';

  @override
  String get actionClose => '닫기';

  @override
  String get actionSearch => '검색';

  @override
  String get actionSettings => '설정';

  @override
  String get connectionConnecting => '연결 중…';

  @override
  String get connectionOnline => '온라인';

  @override
  String get connectionOffline => '오프라인';

  @override
  String get messageStatusPending => '전송 대기 — 상대방이 오프라인입니다';

  @override
  String get messageStatusPendingDetail => 'Tox에는 서버가 없습니다. 상대방이 온라인이 되면 메시지가 전달됩니다.';

  @override
  String get messageStatusSending => '전송 중';

  @override
  String get messageStatusSent => '전송됨';

  @override
  String get messageStatusFailed => '전송 실패';

  @override
  String get errorWrongPassword => '비밀번호가 올바르지 않습니다. 다시 시도하세요.';

  @override
  String get errorPeerOffline => '이 연락처는 오프라인입니다. Tox에는 서버가 없으므로 상대방이 돌아올 때까지 메시지가 대기합니다.';

  @override
  String get errorInvalidToxId => '유효한 Tox ID가 아닙니다(16진수 문자 76개여야 합니다).';

  @override
  String get errorAlreadyFriend => '이 Tox ID는 이미 친구 목록에 있습니다.';

  @override
  String get errorOwnId => '본인의 Tox ID입니다.';

  @override
  String get errorGroupNotFound => '그룹을 찾을 수 없습니다.';

  @override
  String get errorMessageTooLong => '메시지가 Tox 메시지 한 건의 길이 제한을 초과합니다.';

  @override
  String get errorUnknown => '문제가 발생했습니다';

  @override
  String get errorTeardownUnconfirmed => '이전 Tox 세션이 아직 완전히 종료되지 않았습니다. 잠시 후 다시 시도하거나 앱을 다시 시작하세요.';

  @override
  String get errorIdentityRecoveryPending => '이전 신원이 아직 복구를 기다리고 있습니다. 앱을 다시 시작해 재시도하거나, 신원 데이터를 삭제하고 처음부터 시작하세요.';

  @override
  String get languageTitle => '언어';

  @override
  String get languageSystemDefault => '시스템 기본값';

  @override
  String get languageSaveFailed => '언어 설정을 저장할 수 없습니다. 다시 시도하세요.';

  @override
  String learnLessonOf(int lesson, int total) {
    return '강의 $lesson / $total';
  }

  @override
  String learnCharsLearned(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count개 문자 학습 완료',
    );
    return '$_temp0';
  }

  @override
  String learnDailyGoalProgress(int done, int goal) {
    return '$done / $goal개 문자';
  }

  @override
  String learnStreakDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days일 연속 연습',
    );
    return '$_temp0';
  }

  @override
  String learnReviewDueCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '복습할 문자 $count개',
      zero: '복습할 문자가 없습니다',
    );
    return '$_temp0';
  }

  @override
  String learnRoundScore(int correct, int total) {
    return '$total개 중 $correct개 정답';
  }

  @override
  String learnRoundOf(int round) {
    return '라운드 $round';
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
      other: '$count개 문자 송신 완료',
    );
    return '$_temp0';
  }

  @override
  String learnLessonUnlocked(String char) {
    return '다음 문자가 열렸습니다: $char';
  }

  @override
  String learnConfusedMissed(String target) {
    return '$target을 놓쳤습니다';
  }

  @override
  String learnConfusedAs(String target, String answered) {
    return '$target을 $answered로 잘못 들었습니다';
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
      other: '문자 $count개',
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
      other: '$count개 문자 학습 완료',
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
      other: '$count개 문자 받아쓰기',
    );
    return '$_temp0';
  }

  @override
  String statsSessions(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '연습 $count회',
    );
    return '$_temp0';
  }

  @override
  String statsDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count일',
    );
    return '$_temp0';
  }

  @override
  String statsBestStreak(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '최장 $count일 연속',
    );
    return '$_temp0';
  }

  @override
  String statsGoalProgress(int done, int goal) {
    return '$done / $goal개 문자';
  }

  @override
  String statsGoalRemaining(int remaining) {
    String _temp0 = intl.Intl.pluralLogic(
      remaining,
      locale: localeName,
      other: '$remaining개 문자 남음',
    );
    return '$_temp0';
  }

  @override
  String statsTrendSubtitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '최근 $count회 연습',
      one: '지난 연습',
    );
    return '$_temp0';
  }

  @override
  String statsTooltipSession(int index, int total) {
    return '연습 $index / $total';
  }

  @override
  String statsTooltipCopied(int correct, int total) {
    return '$correct / $total 정답';
  }

  @override
  String statsTooltipLesson(int lesson) {
    return '강의 $lesson';
  }

  @override
  String statsAttempts(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count회 시도',
    );
    return '$_temp0';
  }

  @override
  String statsCorrectOf(int correct, int attempts) {
    return '$attempts회 중 $correct회 정답';
  }

  @override
  String statsLessonIntroduced(int lesson) {
    return '강의 $lesson에서 처음 학습';
  }

  @override
  String statsSrsBox(int box, int maxBox) {
    return '상자 $box / $maxBox';
  }

  @override
  String statsSrsDueIn(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days일 후 복습',
      one: '내일 복습',
    );
    return '$_temp0';
  }

  @override
  String statsTimes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count회',
    );
    return '$_temp0';
  }

  @override
  String statsHeatmapCell(String target, String answered, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count회',
    );
    return '$target을 $answered로 응답, $_temp0';
  }

  @override
  String statsCalendarDay(String date, int chars) {
    String _temp0 = intl.Intl.pluralLogic(
      chars,
      locale: localeName,
      other: '문자 $chars개',
      zero: '연습 없음',
    );
    return '$date: $_temp0';
  }

  @override
  String statsActiveDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '연습한 날 $count일',
    );
    return '$_temp0';
  }

  @override
  String referenceEntryCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count개 항목',
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
    return '건너뜀(모스 부호 없음): $chars';
  }

  @override
  String referenceKochPositionValue(int position) {
    return 'Koch 학습 순서: $position';
  }

  @override
  String referenceEstimatedSpeed(String wpm) {
    return '추정 $wpm WPM';
  }

  @override
  String get accountCopied => 'Tox ID를 클립보드에 복사했습니다';

  @override
  String get accountShowQr => 'QR 코드 보기';

  @override
  String get accountToxId => 'Tox ID';

  @override
  String get accountDisplayName => '표시 이름';

  @override
  String get accountDisplayNameHint => '콜사인 또는 별명';

  @override
  String get accountDisplayNameRequired => '표시 이름을 입력하세요';

  @override
  String get accountStatusMessage => '상태 메시지';

  @override
  String get accountPassword => '비밀번호';

  @override
  String get accountPasswordOptional => '비밀번호(선택 사항)';

  @override
  String get accountConfirmPassword => '비밀번호 확인';

  @override
  String get accountPasswordsDoNotMatch => '비밀번호가 일치하지 않습니다';

  @override
  String get accountShowPassword => '비밀번호 표시';

  @override
  String get accountHidePassword => '비밀번호 숨기기';

  @override
  String get accountStrengthWeak => '약함: 8자 이상 사용하세요';

  @override
  String get accountStrengthFair => '보통: 12자 이상으로 여러 문자 종류를 섞으면 더 안전합니다';

  @override
  String get accountStrengthStrong => '강함';

  @override
  String get accountStartupInspecting => '신원 정보 확인 중…';

  @override
  String get accountStartupOpening => '신원 정보 여는 중…';

  @override
  String get accountStartupFailedTitle => '시작할 수 없습니다';

  @override
  String get accountStartupFailedBody => 'DitMesh가 신원 정보를 읽지 못했습니다. 변경된 내용은 없습니다. 다시 시도할 수 있습니다.';

  @override
  String get accountConnectionTapToReconnect => '탭하여 다시 연결';

  @override
  String get accountWelcomeTitle => '신원 정보는 이 기기에 저장됩니다';

  @override
  String get accountWelcomeIntro => 'DitMesh는 Tox P2P 네트워크를 사용합니다. 서버도 계정 가입도 없습니다. 신원 정보는 이 기기에만 저장되는 키 쌍입니다.';

  @override
  String get accountWelcomePointNoServer => '서버, 전화번호, 이메일이 필요 없습니다. 운용자끼리 모스 부호로 직접 통신합니다.';

  @override
  String get accountWelcomePointTraining => '직선 키나 아이암빅 패들로 모스 부호를 입력해 개인 또는 그룹 채팅을 할 수 있습니다.';

  @override
  String get accountWelcomePointBackup => '다른 누구도 신원 정보를 복구해 줄 수 없습니다. 생성 후 바로 백업하세요. 백업이 없으면 기기를 잃을 때 신원 정보도 잃게 됩니다.';

  @override
  String get accountCreateIdentity => '신원 정보 생성';

  @override
  String get accountRestoreFromBackup => '백업에서 복원';

  @override
  String get accountCreateTitle => '내 신원 정보 생성';

  @override
  String get accountCreateBody => '다른 사람에게 보일 이름을 정하세요. 비밀번호는 이 기기의 신원 정보 파일을 암호화합니다. 비밀번호 없이 앱을 열려면 비워 두세요.';

  @override
  String get accountCreateButton => '생성';

  @override
  String get accountCreating => '생성 중…';

  @override
  String get accountBackupTitle => '지금 신원 정보를 백업하세요';

  @override
  String get accountBackupBody => '신원 정보는 이 기기에만 있습니다. 기기를 잃어버리거나 초기화하거나 도난당하면 복구할 수 없습니다. 연락처는 새로운 신원 정보를 알아보지 못하고 학습 진도도 사라집니다.';

  @override
  String get accountBackupWhatIsInside => '백업 파일에는 비밀번호로 암호화된 신원 키와 학습 진도가 들어 있습니다. 이 기기 밖의 안전한 곳에 보관하세요.';

  @override
  String get accountBackupWhatIsInsidePlain => '백업 파일에는 암호화되지 않은 신원 키와 학습 진도가 들어 있습니다. 이 파일을 가진 사람은 누구나 당신의 신원을 사용할 수 있습니다. 키를 암호화하려면 먼저 비밀번호를 설정하고, 파일은 안전한 곳에 보관하세요.';

  @override
  String get accountPasswordScope => '비밀번호는 신원 키를 암호화합니다. 메시지 기록은 디스크에 암호화되지 않은 채로 남으며, 기기 암호화로 보호할 수 있습니다.';

  @override
  String get accountSectionNotifications => '알림';

  @override
  String get accountNotificationsEnable => '알림 표시';

  @override
  String get accountNotificationsEnableSubtitle => '새 메시지, 친구 요청, 그룹 초대';

  @override
  String get accountNotificationsContent => '메시지 내용 표시';

  @override
  String get accountNotificationsContentSubtitle => '배너와 잠금 화면에 텍스트와 모스 부호를 표시합니다. 끄면 메시지가 왔다는 것만 알립니다.';

  @override
  String get accountNotificationsAllow => '알림 허용';

  @override
  String get accountNotificationsAllowSubtitle => '시스템에 알림 권한을 요청합니다';

  @override
  String get accountNotificationsDenied => '시스템 설정에서 DitMesh 알림이 꺼져 있습니다.';

  @override
  String get accountBackupSaveFile => '백업 파일 저장';

  @override
  String get accountBackupShareFile => '백업 파일 공유';

  @override
  String get accountBackupSaved => '백업이 저장되었습니다';

  @override
  String get accountBackupNotSaved => '백업이 저장되지 않았습니다';

  @override
  String get accountBackupFailed => '백업을 기록할 수 없습니다';

  @override
  String get accountBackupAcknowledge => '이 백업이 없으면 신원 정보를 복구할 수 없음을 이해했습니다.';

  @override
  String get accountBackupContinue => 'DitMesh 시작';

  @override
  String get accountBackupShowQrHint => '친구는 Tox ID로 나를 추가합니다. 텍스트나 QR 코드로 공유할 수 있습니다.';

  @override
  String get accountRestoreTitle => '백업에서 복원';

  @override
  String get accountRestoreBody => 'DitMesh에서 내보낸 백업 파일을 선택하세요. 신원 정보에 비밀번호를 설정했다면 여기서 입력해야 합니다.';

  @override
  String get accountRestoreChooseFile => '백업 파일 선택';

  @override
  String get accountRestoreNoFile => '먼저 백업 파일을 선택하세요';

  @override
  String get accountRestoreButton => '복원';

  @override
  String get accountRestoring => '복원 중…';

  @override
  String get accountRestoreInvalidFile => '이 파일은 DitMesh 백업이 아닙니다.';

  @override
  String get accountRestoreReplacesWarning => '복원하면 이 기기의 현재 신원 정보가 교체됩니다.';

  @override
  String get accountUnlockTitle => '신원 정보 잠금 해제';

  @override
  String get accountUnlockBody => '신원 정보 파일이 암호화되어 있습니다. 계속하려면 비밀번호를 입력하세요.';

  @override
  String get accountUnlockButton => '잠금 해제';

  @override
  String get accountUnlocking => '잠금 해제 중…';

  @override
  String get accountUnlockRestoreInstead => '대신 백업에서 복원';

  @override
  String get accountMeNoIdentity => '신원 정보가 불러와지지 않았습니다';

  @override
  String get accountSectionAccount => '계정';

  @override
  String get accountSectionTraining => '훈련';

  @override
  String get accountSectionAbout => '앱 정보';

  @override
  String get accountSectionDanger => '위험한 작업';

  @override
  String get accountEditProfile => '프로필 편집';

  @override
  String get accountEditProfileBody => 'Tox 네트워크의 연락처에게 표시됩니다.';

  @override
  String get accountSetPassword => '비밀번호 설정';

  @override
  String get accountChangePassword => '비밀번호 변경';

  @override
  String get accountRemovePassword => '비밀번호 제거';

  @override
  String get accountCurrentPassword => '현재 비밀번호';

  @override
  String get accountNewPassword => '새 비밀번호';

  @override
  String get accountPasswordUpdated => '비밀번호가 변경되었습니다';

  @override
  String get accountPasswordRemoved => '비밀번호가 제거되었습니다';

  @override
  String get accountProfileUpdated => '프로필이 수정되었습니다';

  @override
  String get accountExportBackup => '백업 내보내기';

  @override
  String get accountExportBackupSubtitle => '신원 정보와 학습 진도를 파일에 저장';

  @override
  String get accountTrainingDefaults => '재생 및 훈련 기본 설정';

  @override
  String get accountTrainingDefaultsSubtitle => '속도, 음높이, Farnsworth 간격';

  @override
  String get accountTrainingDefaultsPlaceholder => '속도, 음높이, Farnsworth 간격의 기본 설정이 여기에 표시됩니다.';

  @override
  String get accountAboutLicence => '라이선스';

  @override
  String get accountAboutLicenceValue => 'GPL-3.0';

  @override
  String get accountAboutSource => '소스 코드';

  @override
  String get accountAboutSourceCopied => '소스 코드 링크를 복사했습니다';

  @override
  String get accountAboutBackend => '백엔드';

  @override
  String get accountDeleteIdentity => '신원 정보 삭제';

  @override
  String get accountDeleteIdentitySubtitle => '이 기기에서 신원 정보, 기록과 학습 진도 삭제';

  @override
  String get accountDeleteDialogTitle => '이 신원 정보를 삭제할까요?';

  @override
  String get accountDeleteDialogBody => '이 기기에서 신원 정보, 채팅 기록과 학습 진도를 삭제합니다. 백업이 없으면 복구할 수 없습니다. 확인하려면 DELETE를 입력하세요.';

  @override
  String get accountDeleteConfirmWord => 'DELETE';

  @override
  String get accountDeleteConfirmHint => 'DELETE 입력';

  @override
  String get accountDeleteButton => '삭제';

  @override
  String get accountRecoveryPendingDiscard => '복구 대기 중인 신원을 버리고 처음부터 시작';

  @override
  String accountRestoreFileChosenSize(int bytes) {
    return '백업 파일 선택됨($bytes바이트)';
  }

  @override
  String get chatSearchConversations => '대화 검색';

  @override
  String get chatNoConversations => '아직 대화가 없습니다';

  @override
  String get chatNoSearchResults => '일치하는 대화가 없습니다';

  @override
  String get chatPin => '고정';

  @override
  String get chatUnpin => '고정 해제';

  @override
  String get chatMarkRead => '읽음으로 표시';

  @override
  String get chatDelete => '삭제';

  @override
  String get chatDeleteConversationTitle => '대화를 삭제할까요?';

  @override
  String get chatDeleteConversationBody => '이 기기에 저장된 대화 기록이 삭제됩니다. Tox에는 사본이 없습니다.';

  @override
  String get chatDraftPrefix => '초안: ';

  @override
  String get chatSelectConversation => '대화 선택';

  @override
  String get chatContacts => '연락처';

  @override
  String get chatNoMessages => '아직 메시지가 없습니다. CQ를 보내 통신을 시작하세요.';

  @override
  String get chatTrainingMode => '훈련 모드';

  @override
  String get chatTrainingModeOn => '훈련 모드 켜짐: 텍스트 숨김';

  @override
  String get chatTrainingModeOff => '훈련 모드 꺼짐';

  @override
  String get chatAutoPlay => '받은 모스 부호 자동 재생';

  @override
  String get chatAutoPlayOn => '자동 재생 켜짐: 새 메시지가 도착하면 재생됩니다';

  @override
  String get chatAutoPlayOff => '자동 재생 꺼짐';

  @override
  String get chatReveal => '보기';

  @override
  String get chatHiddenText => '먼저 듣고 나서 보기';

  @override
  String get chatPlay => '모스 부호 재생';

  @override
  String get chatStop => '정지';

  @override
  String get chatPlaybackSettings => '재생 설정';

  @override
  String get chatCharacterSpeed => '문자 속도';

  @override
  String get chatFarnsworthSpeed => 'Farnsworth 속도';

  @override
  String get chatTone => '음높이';

  @override
  String get chatWpm => 'WPM';

  @override
  String get chatHz => 'Hz';

  @override
  String get chatMembers => '회원';

  @override
  String get chatLeaveGroup => '그룹 나가기';

  @override
  String get chatLeaveGroupTitle => '이 그룹에서 나갈까요?';

  @override
  String get chatLeaveGroupBody => '더 이상 메시지를 받지 않습니다. 나중에 채팅 ID로 다시 참여할 수 있습니다.';

  @override
  String get chatLeave => '나가기';

  @override
  String get chatConferenceNote => '구형 회의: 여기서는 모스 전건 조작 메타데이터(v2)를 사용할 수 없습니다. 텍스트는 사용할 수 있습니다.';

  @override
  String get chatClearHistory => '기록 지우기';

  @override
  String get chatModeStraightKey => '수동 전건';

  @override
  String get chatModePaddles => '패들';

  @override
  String get chatKeyMessage => '전건으로 메시지를 입력하세요';

  @override
  String get chatSend => '보내기';

  @override
  String get chatTooLong => 'Tox 메시지 한 건의 길이 제한을 초과합니다';

  @override
  String get chatKeyHint => '전건 영역을 누르거나 스페이스 키를 누르세요';

  @override
  String get chatPaddleHint => '패들을 탭하거나 Ctrl을 누르세요(왼쪽: 단점, 오른쪽: 장점)';

  @override
  String get chatDeleteLast => '마지막 문자 삭제';

  @override
  String get chatNoFriends => '아직 친구가 없습니다. 상대방의 Tox ID로 추가하세요.';

  @override
  String get chatNoRequests => '대기 중인 요청이 없습니다';

  @override
  String get chatAddFriend => '친구 추가';

  @override
  String get chatMyToxId => '내 Tox ID';

  @override
  String get chatToxIdLabel => 'Tox ID(16진수 문자 76개)';

  @override
  String get chatToxIdInvalid => 'Tox ID는 정확히 76개의 16진수 문자여야 합니다';

  @override
  String get chatToxIdOwn => '본인의 Tox ID입니다';

  @override
  String get chatToxIdAlreadyFriend => '이미 친구 목록에 있습니다';

  @override
  String get chatRequestMessage => '메시지';

  @override
  String get chatDefaultRequestMessage => 'DitMesh CQ';

  @override
  String get chatSendRequest => '요청 보내기';

  @override
  String get chatRequestSent => '친구 요청을 보냈습니다';

  @override
  String get chatScanQr => 'QR 코드 스캔';

  @override
  String get chatScanQrDesktopHint => 'QR 코드 스캔에는 휴대폰 카메라가 필요합니다';

  @override
  String get chatScanQrTitle => 'Tox ID 스캔';

  @override
  String get chatScanQrNotToxId => '이 QR 코드는 Tox ID가 아닙니다';

  @override
  String get chatAccept => '수락';

  @override
  String get chatReject => '거절';

  @override
  String get chatCopied => '클립보드에 복사했습니다';

  @override
  String get chatNoIdentity => '신원 정보가 불러와지지 않았습니다';

  @override
  String get chatRemoveFriend => '친구 삭제';

  @override
  String get chatRemoveFriendTitle => '이 친구를 삭제할까요?';

  @override
  String get chatRemoveFriendBody => '상대방이 더 이상 나에게 메시지를 보낼 수 없습니다.';

  @override
  String get chatRemove => '삭제';

  @override
  String get chatNoGroups => '아직 그룹이 없습니다. 그룹을 만들거나 채팅 ID로 참여하세요.';

  @override
  String get chatCreateGroup => '그룹 만들기';

  @override
  String get chatJoinGroup => '그룹 참여';

  @override
  String get chatGroupName => '그룹 이름';

  @override
  String get chatGroupNameRequired => '그룹 이름을 입력하세요';

  @override
  String get chatAdvanced => '고급';

  @override
  String get chatLegacyConference => '구형 회의(이전 클라이언트용)';

  @override
  String get chatLegacyConferenceHint => '권장하지 않음: 고정 채팅 ID와 모스 메타데이터가 없습니다.';

  @override
  String get chatCreate => '만들기';

  @override
  String get chatChatIdLabel => '채팅 ID(16진수 문자 64개)';

  @override
  String get chatChatIdInvalid => '채팅 ID는 정확히 64개의 16진수 문자여야 합니다';

  @override
  String get chatPassword => '비밀번호(선택 사항)';

  @override
  String get chatJoin => '참여';

  @override
  String get chatJoinRequested => '참여 중 — 회원을 찾으면 그룹이 표시됩니다.';

  @override
  String get chatConferenceBadge => '회의';

  @override
  String get chatCopyChatId => '채팅 ID 복사';

  @override
  String get learnLessonCardTitle => 'Koch 강의';

  @override
  String get learnCourseComplete => '과정 완료! 계속 실력을 다듬어 보세요.';

  @override
  String get learnDailyGoalTitle => '오늘';

  @override
  String get learnDailyGoalMet => '일일 목표 달성';

  @override
  String get learnNoStreak => '오늘부터 매일 연습해 보세요';

  @override
  String get learnContinueLesson => '강의 계속하기';

  @override
  String get learnReceivePractice => '수신 연습';

  @override
  String get learnSendPractice => '송신 연습';

  @override
  String get learnReviewDue => '복습할 문자';

  @override
  String get learnSettings => '훈련 설정';

  @override
  String get learnLoading => '학습 진도 불러오는 중…';

  @override
  String get learnIdentityRequired => '훈련을 시작하려면 신원 정보를 생성하거나 잠금을 해제하세요. 진도는 신원 정보와 함께 저장되며 백업에도 포함됩니다.';

  @override
  String get learnLoadFailed => '저장된 진도를 읽을 수 없습니다. 처음부터 시작합니다. 기존 파일은 .corrupt로 보관되었습니다.';

  @override
  String get learnProgressSaveFailed => '진행 상황을 저장하지 못했습니다. DitMesh를 닫기 전까지는 이번 결과가 유지됩니다.';

  @override
  String get learnChooseDrill => '연습 선택';

  @override
  String get learnDrillGroups => '무작위 문자 묶음';

  @override
  String get learnDrillWords => '단어';

  @override
  String get learnDrillCallsigns => '콜사인';

  @override
  String get learnDrillQso => '교신(QSO)';

  @override
  String get learnDrillCharacters => '한 문자씩';

  @override
  String get learnDrillAbbreviations => '약어와 Q 부호';

  @override
  String get learnDrillNumbers => '숫자 묶음';

  @override
  String get learnDrillConfusables => '혼동하기 쉬운 문자';

  @override
  String get learnDrillContest => '대회 교환 정보';

  @override
  String get learnDrillGroupsHint => '학습한 문자로 구성한 무작위 문자 묶음';

  @override
  String get learnDrillCharactersHint => '한 번에 한 문자씩 듣고 바로 답하세요';

  @override
  String get learnDrillWordsHint => '자주 쓰는 영어 단어';

  @override
  String get learnDrillAbbreviationsHint => 'TNX, FB, QTH, QSL 등 무선 교신 약어';

  @override
  String get learnDrillNumbersHint => '전문과 일련번호에 쓰이는 다섯 자리 숫자 묶음';

  @override
  String get learnDrillCallsignsHint => '전 세계 아마추어 무선 콜사인';

  @override
  String get learnDrillConfusablesHint => 'S/H, U/V 등 혼동하기 쉬운 문자를 짝지어 연습';

  @override
  String get learnDrillQsoHint => '전체 교신에 쓰이는 문장';

  @override
  String get learnDrillContestHint => '대회 속도로 콜사인, 5NN과 일련번호 또는 구역 번호 수신';

  @override
  String get learnDrillReviewHint => '복습할 때가 된 문자';

  @override
  String get toolsTitle => '무선 도구';

  @override
  String get toolsGridTitle => '그리드 로케이터';

  @override
  String get toolsGridHint => '좌표를 로케이터로 변환하고 거리와 안테나 방위각 확인';

  @override
  String get toolsBandsTitle => '주파수 대역과 안테나';

  @override
  String get toolsBandsHint => '주파수가 속한 대역, 파장과 다이폴 길이 확인';

  @override
  String get toolsSpeedTitle => 'CW 속도';

  @override
  String get toolsSpeedHint => 'WPM을 단점 길이, 간격과 분당 문자 수로 변환';

  @override
  String get toolsRstTitle => 'RST 신호 보고';

  @override
  String get toolsRstHint => '신호 보고를 구성하고 각 숫자의 의미 확인';

  @override
  String get toolsClockTitle => 'UTC 시계';

  @override
  String get toolsClockHint => '로그에 쓰는 UTC 시간과 현지 시간을 함께 표시';

  @override
  String get toolsGridFromCoordinates => '좌표로 계산';

  @override
  String get toolsGridLatitude => '위도';

  @override
  String get toolsGridLongitude => '경도';

  @override
  String get toolsGridCoordinatesHelp => '십진수 도 단위로 입력하세요. 남위와 서경은 음수입니다';

  @override
  String get toolsGridInvalidCoordinates => '위도는 -90~90, 경도는 -180~180';

  @override
  String get toolsGridLocator => '로케이터';

  @override
  String get toolsGridDistanceSection => '거리와 방위각';

  @override
  String get toolsGridMine => '내 로케이터';

  @override
  String get toolsGridTheirs => '상대방 로케이터';

  @override
  String get toolsGridInvalidLocator => '2, 4, 6 또는 8자로 입력하세요. 예: OM89ex';

  @override
  String get toolsGridCenter => '그리드 중심';

  @override
  String get toolsGridDistance => '거리';

  @override
  String get toolsGridShortPath => '단경로 방위각';

  @override
  String get toolsGridLongPath => '장경로 방위각';

  @override
  String get toolsBandsFrequency => '주파수(MHz)';

  @override
  String get toolsBandsInvalidFrequency => '0보다 큰 주파수를 입력하세요';

  @override
  String toolsBandsRegionLabel(int number) {
    return '제$number지역';
  }

  @override
  String get toolsBandsRegionHelp => '1: 유럽, 아프리카, 중동 — 2: 아메리카 — 3: 아시아·태평양';

  @override
  String toolsBandsInBand(String band) {
    return '$band 아마추어 무선 대역에 포함';
  }

  @override
  String get toolsBandsOutOfBand => '아마추어 무선 대역 밖';

  @override
  String get toolsBandsWavelength => '파장';

  @override
  String get toolsBandsDipole => '반파장 다이폴(전체 길이)';

  @override
  String get toolsBandsQuarterWave => '1/4파장 수직 안테나';

  @override
  String get toolsBandsAntennaNote => '길이에 0.95 단축 계수가 반영되어 있습니다. 공진하도록 길이를 조정하세요.';

  @override
  String get toolsBandsTable => '주파수 대역 경계';

  @override
  String toolsBandsQrp(String frequency) {
    return 'QRP CW $frequency';
  }

  @override
  String get toolsBandsDisclaimer => 'ITU의 주파수 분배입니다. 면허와 국가별 주파수 계획에 따라 허용 범위가 더 좁을 수 있습니다.';

  @override
  String get toolsSpeedCharacter => '문자 속도';

  @override
  String get toolsSpeedFarnsworth => 'Farnsworth 간격';

  @override
  String get toolsSpeedOverall => '전체 속도';

  @override
  String get toolsSpeedDit => '단점';

  @override
  String get toolsSpeedDah => '장점';

  @override
  String get toolsSpeedCharGap => '문자 사이 간격';

  @override
  String get toolsSpeedWordGap => '단어 사이 간격';

  @override
  String get toolsSpeedCpm => '분당 문자 수';

  @override
  String get toolsSpeedParis => 'PARIS 한 단어 송신 시간';

  @override
  String get toolsRstReadability => '명료도(R)';

  @override
  String get toolsRstStrength => '신호 강도(S)';

  @override
  String get toolsRstTone => '음질(T)';

  @override
  String get toolsRstReport => '보고';

  @override
  String get toolsRstCut => '대회용 약식 표기';

  @override
  String get toolsRstPhone => '음성 통신(음질 항목 없음)';

  @override
  String get toolsRstR1 => '알아들을 수 없음';

  @override
  String get toolsRstR2 => '겨우 알아들을 수 있으며 가끔 단어가 들림';

  @override
  String get toolsRstR3 => '상당히 어렵지만 알아들을 수 있음';

  @override
  String get toolsRstR4 => '거의 어려움 없이 알아들을 수 있음';

  @override
  String get toolsRstR5 => '완전히 알아들을 수 있음';

  @override
  String get toolsRstS1 => '미약하여 겨우 감지됨';

  @override
  String get toolsRstS2 => '매우 약함';

  @override
  String get toolsRstS3 => '약함';

  @override
  String get toolsRstS4 => '보통';

  @override
  String get toolsRstS5 => '비교적 양호함';

  @override
  String get toolsRstS6 => '양호함';

  @override
  String get toolsRstS7 => '비교적 강함';

  @override
  String get toolsRstS8 => '강함';

  @override
  String get toolsRstS9 => '매우 강함';

  @override
  String get toolsRstT1 => '매우 거칠고 폭이 넓은 미정류 교류음';

  @override
  String get toolsRstT2 => '매우 거칠고 날카로우며 폭이 넓은 교류음';

  @override
  String get toolsRstT3 => '거친 음, 정류되었으나 평활화되지 않음';

  @override
  String get toolsRstT4 => '거친 음이나 약간의 평활화 흔적이 있음';

  @override
  String get toolsRstT5 => '평활화되었으나 리플 변조가 심함';

  @override
  String get toolsRstT6 => '평활화되었으나 뚜렷한 리플이 있음';

  @override
  String get toolsRstT7 => '거의 순수한 음이나 약간의 리플이 있음';

  @override
  String get toolsRstT8 => '거의 완벽한 음으로 아주 약한 변조 흔적이 있음';

  @override
  String get toolsRstT9 => '완벽한 음으로 리플이 전혀 없음';

  @override
  String get toolsClockUtc => 'UTC';

  @override
  String get toolsClockLocal => '현지 시간';

  @override
  String get toolsClockNote => '로그와 QSL 카드에는 UTC를 사용합니다.';

  @override
  String get learnReceiveTitle => '수신';

  @override
  String get learnReviewTitle => '복습';

  @override
  String get learnListen => '들어 보세요…';

  @override
  String get learnReady => '준비 완료';

  @override
  String get learnReplay => '다시 재생';

  @override
  String get learnAnswerHint => '들은 내용을 입력하세요';

  @override
  String get learnSubmit => '정답 확인';

  @override
  String get learnNext => '다음';

  @override
  String get learnFinish => '종료';

  @override
  String get learnDone => '완료';

  @override
  String get learnBackspace => '삭제';

  @override
  String get learnSpace => '공백';

  @override
  String get learnSent => '송신 내용';

  @override
  String get learnYourCopy => '받아쓴 내용';

  @override
  String get learnRoundPerfect => '모두 정확히 받아썼습니다!';

  @override
  String get learnSessionSummary => '연습 요약';

  @override
  String get learnLessonPassed => '강의 통과';

  @override
  String get learnLessonNotPassed => '계속 연습하세요: 정답률 90%면 다음 문자가 열립니다';

  @override
  String get learnReviewRecorded => '복습이 기록되었습니다';

  @override
  String get learnWeakChars => '더 연습할 문자';

  @override
  String get learnConfusions => '혼동한 문자';

  @override
  String get learnNoFeedbackWarning => '소리, 화면 깜박임과 진동이 모두 꺼져 있습니다. 대신 화면을 깜박입니다.';

  @override
  String get learnSendTitle => '송신';

  @override
  String get learnSendThis => '이 내용을 송신하세요';

  @override
  String get learnCopyFromMemory => '기억으로';

  @override
  String get learnHiddenTarget => '숨김 — 기억으로 송신하세요';

  @override
  String get learnDecoded => '해독 결과';

  @override
  String get learnWaitingForKey => '준비되면 송신을 시작하세요';

  @override
  String get learnRestart => '다시 시작';

  @override
  String get learnTryAnother => '다른 문제 풀기';

  @override
  String get learnKeyerStraight => '수동 전건';

  @override
  String get learnKeyerIambicA => '아이앰빅 A';

  @override
  String get learnKeyerIambicB => '아이앰빅 B';

  @override
  String get learnLegendStraight => '스페이스 키 = 전건';

  @override
  String get learnLegendPaddles => '왼쪽 Ctrl = 단점, 오른쪽 Ctrl = 장점';

  @override
  String get learnSendClean => '깔끔한 송신입니다. 고칠 부분이 없습니다.';

  @override
  String get learnSendIssues => '리듬 조언';

  @override
  String get learnYourSending => '해독된 내용';

  @override
  String get learnStraightKeyLabel => '전건';

  @override
  String get learnDitLabel => '단점';

  @override
  String get learnDahLabel => '장점';

  @override
  String get learnSettingsTitle => '훈련 설정';

  @override
  String get learnCharacterSpeed => '문자 속도';

  @override
  String get learnFarnsworth => 'Farnsworth 간격';

  @override
  String get learnFarnsworthHelp => '문자는 빠르게 유지하고 문자 사이 간격을 이 속도에 맞춰 늘립니다.';

  @override
  String get learnEffectiveSpeed => '실효 속도';

  @override
  String get learnTone => '음높이';

  @override
  String get learnPlaySample => '예시 재생';

  @override
  String get learnSessionLength => '연습 길이';

  @override
  String get learnFeedback => '피드백';

  @override
  String get learnSound => '소리';

  @override
  String get learnFlash => '화면 깜박임';

  @override
  String get learnHaptic => '진동';

  @override
  String get learnKeyer => '전건 모드';

  @override
  String get learnDailyGoal => '일일 목표';

  @override
  String get referenceReferenceTitle => '모스 부호 참고 자료';

  @override
  String get referenceTranslatorTitle => '변환기';

  @override
  String get referencePlay => '재생';

  @override
  String get referenceStop => '정지';

  @override
  String get referenceClear => '지우기';

  @override
  String get referenceClose => '닫기';

  @override
  String get referenceEmptyOutput => '—';

  @override
  String get referenceSearchHint => '문자, 절차 부호, Q 부호 검색…';

  @override
  String get referenceClearSearch => '검색 지우기';

  @override
  String get referenceNoResults => '검색과 일치하는 항목이 없습니다.';

  @override
  String get referenceSectionAlphabet => '문자표';

  @override
  String get referenceSectionPunctuation => '문장 부호';

  @override
  String get referenceSectionProsigns => '절차 부호';

  @override
  String get referenceSectionQCodes => 'Q 부호';

  @override
  String get referenceSectionAbbreviations => 'CW 약어';

  @override
  String get referenceSectionKoch => 'Koch 학습 순서';

  @override
  String get referenceAlphabetHint => '카드를 탭하면 소리를 들을 수 있습니다. 길게 누르면 암기법을 볼 수 있습니다.';

  @override
  String get referenceKochHint => 'Koch 방식으로 문자를 배우는 순서입니다(LCWO 순서). K와 M으로 시작하고 받아쓰기 정답률이 90%에 도달하면 문자를 하나 추가합니다.';

  @override
  String get referenceMnemonicTitle => '암기법';

  @override
  String get referenceMeaningLabel => '의미';

  @override
  String get referencePlaybackSettings => '재생 설정';

  @override
  String get referenceCharacterSpeed => '문자 속도';

  @override
  String get referenceFarnsworth => 'Farnsworth 간격';

  @override
  String get referenceFarnsworthHelp => '문자 속도는 유지하고 간격을 실효 속도에 맞춰 늘립니다.';

  @override
  String get referenceEffectiveSpeed => '실효 속도';

  @override
  String get referenceTone => '음높이';

  @override
  String get referenceModeTextToMorse => '텍스트 → 모스 부호';

  @override
  String get referenceModeMorseToText => '모스 부호 → 텍스트';

  @override
  String get referenceModeKey => '전건 송신';

  @override
  String get referenceTextInputLabel => '텍스트';

  @override
  String get referenceTextInputHint => '부호로 변환할 텍스트 입력…';

  @override
  String get referencePatternOutputLabel => '모스 부호';

  @override
  String get referenceCopyPattern => '부호 복사';

  @override
  String get referencePatternCopied => '부호를 복사했습니다';

  @override
  String get referencePatternInputLabel => '모스 부호';

  @override
  String get referencePatternInputHint => '.과 -를 입력하고 문자 사이는 공백, 단어 사이는 /로 구분하세요';

  @override
  String get referenceTextOutputLabel => '텍스트';

  @override
  String get referenceCopyText => '텍스트 복사';

  @override
  String get referenceTextCopied => '텍스트를 복사했습니다';

  @override
  String get referenceUnknownPatternHelp => '대응하는 문자가 없는 부호는 <pattern>으로 표시됩니다.';

  @override
  String get referenceKeypadDit => '단점';

  @override
  String get referenceKeypadDah => '장점';

  @override
  String get referenceKeypadCharGap => '문자 간격';

  @override
  String get referenceKeypadWordGap => '단어 간격';

  @override
  String get referenceKeypadBackspace => '백스페이스';

  @override
  String get referenceKeyHint => '전건을 길게 눌러 송신하세요. 키보드에서는 스페이스 키를 길게 누르세요.';

  @override
  String get referenceKeyLabel => '전건';

  @override
  String get referenceKeyDecodedLabel => '해독 결과';

  @override
  String get referenceKeyPendingLabel => '송신 중';

  @override
  String get statsTitle => '통계';

  @override
  String get statsLoading => '통계 불러오는 중…';

  @override
  String get statsLoadFailed => '학습 진도를 불러올 수 없습니다. 아래로 당기거나 다시 열어 재시도하세요.';

  @override
  String get statsRetry => '다시 시도';

  @override
  String get statsEmptyTitle => '아직 연습 기록이 없습니다';

  @override
  String get statsEmptyBody => '첫 수신 또는 송신 연습을 마치면 정답률 추이, 문자별 숙련도와 연습 달력이 여기에 표시됩니다.';

  @override
  String get statsEmptyCallToAction => '「학습」에서 「강의 계속하기」를 눌러 시작하세요.';

  @override
  String get statsOverviewTitle => '개요';

  @override
  String get statsTileLesson => 'Koch 강의';

  @override
  String get statsTileAccuracy => '정답률';

  @override
  String get statsNoData => '--';

  @override
  String get statsTilePractice => '연습량';

  @override
  String get statsTileStreak => '연속 일수';

  @override
  String get statsTileDailyGoal => '일일 목표';

  @override
  String get statsGoalMet => '오늘 달성';

  @override
  String get statsSummaryTitle => '내 통계';

  @override
  String get statsSummaryOpen => '통계 보기';

  @override
  String get statsTrendTitle => '정답률 추이';

  @override
  String get statsTrendHint => '데이터 점을 탭하면 해당 연습을 확인할 수 있습니다.';

  @override
  String get statsSeriesReceive => '수신';

  @override
  String get statsSeriesSend => '송신';

  @override
  String get statsAxisSessions => '연습';

  @override
  String get statsCharsTitle => '문자';

  @override
  String get statsCharsSubtitle => 'Koch 학습 순서입니다. 문자를 탭하면 자세히 볼 수 있습니다.';

  @override
  String get statsCharsNotStarted => '아직 연습하지 않았습니다';

  @override
  String get statsNotInCourse => 'Koch 과정에 포함되지 않습니다';

  @override
  String get statsSrsTitle => '간격 반복 학습';

  @override
  String get statsSrsNotTracked => '아직 예정되지 않았습니다';

  @override
  String get statsSrsDueNow => '지금 복습';

  @override
  String get statsConfusionsTitle => '자주 혼동하는 문자';

  @override
  String get statsConfusionsNone => '혼동 기록이 없습니다';

  @override
  String get statsConfusionMissed => '놓침';

  @override
  String get statsBucketLegendTitle => '정답률';

  @override
  String get statsBucketNone => '없음';

  @override
  String get statsBucketWeak => '< 70%';

  @override
  String get statsBucketFair => '70-89%';

  @override
  String get statsBucketGood => '90-97%';

  @override
  String get statsBucketStrong => '>= 98%';

  @override
  String get statsHeatmapTitle => '혼동 행렬';

  @override
  String get statsHeatmapSubtitle => '행은 송신된 문자, 열은 응답한 문자입니다. 색이 진할수록 횟수가 많습니다.';

  @override
  String get statsHeatmapEmpty => '아직 혼동 기록이 없습니다. 틀린 응답이 여기에 표시됩니다.';

  @override
  String get statsHeatmapLegendLow => '적음';

  @override
  String get statsHeatmapLegendHigh => '많음';

  @override
  String get statsHeatmapAxisTarget => '송신 문자';

  @override
  String get statsHeatmapAxisAnswered => '응답 문자';

  @override
  String get statsCalendarTitle => '연습 달력';

  @override
  String get statsCalendarSubtitle => '최근 12주';

  @override
  String get statsCalendarLegendLess => '적음';

  @override
  String get statsCalendarLegendMore => '많음';

  @override
  String get statsStreakExplanation => '하루에 한 번 이상 연습한 날이 연속으로 이어지면 연속 일수로 계산합니다. 하루를 통째로 쉬면 초기화됩니다. 하루에 두 번 연습해도 하루로 계산합니다.';

  @override
  String get learnStatistics => '통계';

  @override
  String get listenTitle => '듣기';

  @override
  String get listenStart => '시작';

  @override
  String get listenStop => '정지';

  @override
  String get listenStarting => '마이크 시작 중…';

  @override
  String get listenClear => '텍스트 지우기';

  @override
  String get listenCopy => '텍스트 복사';

  @override
  String get listenCopied => '해독된 텍스트를 복사했습니다';

  @override
  String get listenSettings => '듣기 설정';

  @override
  String get listenDecoded => '해독 결과';

  @override
  String get listenEmptyHint => '마이크를 모스 부호 소리 쪽으로 향하게 하세요. 해독된 텍스트가 여기에 표시됩니다.';

  @override
  String get listenIdleHint => '「시작」을 탭하여 모스 부호 소리를 들어 보세요.';

  @override
  String get listenPending => '수신 중';

  @override
  String get listenSpeed => '속도';

  @override
  String get listenSpeedUnknown => '-- WPM';

  @override
  String get listenLevel => '신호';

  @override
  String get listenToneOn => '소리 감지';

  @override
  String get listenTone => '음 주파수';

  @override
  String get listenToneLocked => '주파수 고정';

  @override
  String get listenToneSearching => '탐색 중';

  @override
  String get listenToneManual => '수동';

  @override
  String get listenAutoTune => '자동 동조';

  @override
  String get listenAutoTuneHelp => '400–1000 Hz 범위에서 가장 강한 음을 추적합니다. 슬라이더를 움직이면 수동으로 동조할 수 있습니다.';

  @override
  String get listenRetune => '자동';

  @override
  String get listenBlockSize => '분석 블록';

  @override
  String get listenBlockSizeHelp => '블록이 작을수록 단점과 장점의 경계를 정확히 찾지만 잡음에 더 민감해집니다. 256샘플(5.3 ms)은 5–40 WPM에 적합합니다.';

  @override
  String get listenMinElement => '최소 부호 요소 길이';

  @override
  String get listenMinElementHelp => '이 길이보다 짧은 음과 간격은 잡음이나 순간 끊김으로 보고 무시합니다.';

  @override
  String get listenPermissionDenied => '마이크 접근이 거부되었습니다. 시스템 설정에서 허용한 후 다시 시도하세요.';

  @override
  String get listenPermissionRetry => '다시 시도';

  @override
  String get listenStartFailed => '마이크를 시작할 수 없습니다.';

  @override
  String get listenNoInput => '마이크를 찾을 수 없습니다. 연결한 후 다시 시도하세요.';

  @override
  String get listenStreamFailed => '마이크가 예기치 않게 중지되었습니다. 다시 시도하세요.';

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
    return '$samples샘플($ms ms)';
  }

  @override
  String listenMsValue(int ms) {
    return '$ms ms';
  }

  @override
  String get listenStoppedInBackground => '앱이 백그라운드로 이동하여 듣기를 중지했습니다.';

  @override
  String get learnWpmUnknown => '-- WPM';

  @override
  String get learnTipDitTooLongTitle => '단점이 너무 깁니다';

  @override
  String get learnTipDahTooShortTitle => '장점이 너무 짧습니다';

  @override
  String get learnTipIntraGapTooLongTitle => '부호 요소 간격이 너무 넓습니다';

  @override
  String get learnTipCharGapTooShortTitle => '문자 간격이 너무 좁습니다';

  @override
  String get learnTipWordGapTooShortTitle => '단어 간격이 너무 좁습니다';

  @override
  String get learnTipSpeedUnsteadyTitle => '속도가 일정하지 않습니다';

  @override
  String get learnSeverityMinor => '경미';

  @override
  String get learnSeverityModerate => '뚜렷함';

  @override
  String get learnSeveritySevere => '심함';

  @override
  String get notificationOpen => '열기';

  @override
  String get notificationChannelMessages => '메시지';

  @override
  String get notificationChannelMessagesDescription => '친구와 그룹이 보내는 새 모스 메시지';

  @override
  String get notificationChannelFriendRequests => '친구 요청';

  @override
  String get notificationChannelFriendRequestsDescription => '누군가 나를 친구로 추가하려고 합니다';

  @override
  String get notificationChannelGroupInvites => '그룹 초대';

  @override
  String get notificationChannelGroupInvitesDescription => '친구가 그룹에 초대했습니다';

  @override
  String get notificationNewMessage => '새 메시지';

  @override
  String get notificationFriendRequestTitle => '새 친구 요청';

  @override
  String learnNewestCharIs(String char) {
    return '이번 강의의 새 문자: $char';
  }

  @override
  String learnCharNewSemantics(String char) {
    return '$char, 새 문자';
  }

  @override
  String learnPendingPattern(String pattern) {
    return '송신 중: $pattern';
  }

  @override
  String learnIssueHeadline(String title, String severity) {
    return '$title($severity)';
  }

  @override
  String learnRatioTimes(String ratio) {
    return '$ratio배';
  }

  @override
  String learnTipDitTooLong(String ratio) {
    return '단점이 너무 깁니다(단점 길이의 약 $ratio). \'다아\'가 아니라 \'딧\'처럼 짧게 내세요. 단점은 길게 누르지 않고 가볍게 톡 누릅니다.';
  }

  @override
  String learnTipDahTooShort(String ratio) {
    return '장점이 너무 짧습니다(단점 길이의 약 $ratio, 목표는 3배). 단점 세 개 길이만큼 누르세요.';
  }

  @override
  String learnTipIntraGapTooLong(String ratio) {
    return '문자 안의 간격이 너무 넓습니다(단점 길이의 약 $ratio). 한 문자의 부호 요소를 촘촘하게 이어 송신하세요.';
  }

  @override
  String learnTipCharGapTooShort(String ratio) {
    return '문자들이 붙어 있습니다(간격이 단점 길이의 약 $ratio, 목표는 3배). 문자마다 뚜렷한 쉼을 두세요.';
  }

  @override
  String learnTipWordGapTooShort(String ratio) {
    return '단어들이 너무 가깝습니다(간격이 단점 길이의 약 $ratio, 목표는 7배). 단어 사이에는 긴 쉼을 두세요.';
  }

  @override
  String learnTipSpeedUnsteady(int percent) {
    return '속도가 흔들립니다(변동 $percent%). 일정한 박자를 정하고 한 줄 내내 유지하세요.';
  }

  @override
  String learnIssueDetailDitTooLong(int offending, int total, String ratio) {
    return '단점 $total개 중 $offending개가 너무 깁니다(평균: 단점 길이의 $ratio)';
  }

  @override
  String learnIssueDetailDahTooShort(int offending, int total, String ratio) {
    return '장점 $total개 중 $offending개가 너무 짧습니다(평균: 단점 길이의 $ratio)';
  }

  @override
  String learnIssueDetailIntraGapTooLong(int offending, int total, String ratio) {
    return '문자 안 간격 $total개 중 $offending개가 너무 깁니다(평균: 단점 길이의 $ratio)';
  }

  @override
  String learnIssueDetailCharGapTooShort(int offending, int total, String ratio) {
    return '문자 간격 $total개 중 $offending개가 너무 짧습니다(평균: 단점 길이의 $ratio)';
  }

  @override
  String learnIssueDetailWordGapTooShort(int offending, int total, String ratio) {
    return '단어 간격 $total개 중 $offending개가 너무 짧습니다(평균: 단점 길이의 $ratio)';
  }

  @override
  String learnIssueDetailSpeedUnsteady(String cv) {
    return '송신 속도가 일정하지 않습니다(변동 계수 $cv)';
  }

  @override
  String statsAccuracyDetail(String allTime) {
    return '최근 7일 / 전체 $allTime';
  }

  @override
  String statsDurationHoursMinutes(int hours, int minutes) {
    return '$hours시간 $minutes분';
  }

  @override
  String statsDurationMinutes(int minutes) {
    return '$minutes분';
  }

  @override
  String statsDurationSeconds(int seconds) {
    return '$seconds초';
  }

  @override
  String get accountNewPasswordRequired => '새 비밀번호를 입력하세요';

  @override
  String get accountToxIdQrSemantics => 'Tox ID QR 코드';

  @override
  String get accountBackupSaveDialogTitle => 'DitMesh 백업 저장';

  @override
  String get accountBackupShareSubject => 'DitMesh 신원 정보 백업';

  @override
  String get accountBackupChooseDialogTitle => 'DitMesh 백업 선택';

  @override
  String notificationNewMessages(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '새 메시지 $count개',
    );
    return '$_temp0';
  }

  @override
  String notificationFriendRequestFrom(String name) {
    return '$name님의 친구 요청';
  }

  @override
  String notificationFriendRequestBody(String name, String message) {
    return '$name: $message';
  }

  @override
  String notificationGroupInviteTitle(String group) {
    return '$group 초대';
  }

  @override
  String notificationGroupInviteBody(String name) {
    return '$name님이 초대했습니다';
  }

  @override
  String desktopTrayShow(String app) {
    return '$app 표시';
  }

  @override
  String desktopTrayHide(String app) {
    return '$app 숨기기';
  }

  @override
  String get desktopTraySoundOn => '소리 켜짐';

  @override
  String get desktopTraySoundOff => '소리 꺼짐';

  @override
  String desktopTrayQuit(String app) {
    return '$app 종료';
  }

  @override
  String desktopTrayTooltipUnread(String app, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '읽지 않은 메시지 $count개',
    );
    return '$app — $_temp0';
  }

  @override
  String desktopWindowTitleUnread(String badge, String app) {
    return '($badge) $app';
  }

  @override
  String get listenStateOn => '켜짐';

  @override
  String get listenStateOff => '꺼짐';

  @override
  String chatBytesLeftCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count바이트 남음',
    );
    return '$_temp0';
  }

  @override
  String chatMemberCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '회원 $count명',
    );
    return '$_temp0';
  }

  @override
  String chatFriendsCount(int count) {
    return '친구($count)';
  }

  @override
  String chatFriendRequestsCount(int count) {
    return '친구 요청($count)';
  }

  @override
  String chatGroupInvitesCount(int count) {
    return '그룹 초대($count)';
  }

  @override
  String chatMembersTitleCount(int count) {
    return '회원 · $count';
  }

  @override
  String chatInvitedByName(String name) {
    return '초대한 사람: $name';
  }

  @override
  String chatMemberSelf(String name) {
    return '$name(나)';
  }

  @override
  String chatSliderValue(String label, int value, String unit) {
    return '$label: $value $unit';
  }

  @override
  String referenceTelegraphCodes(String codes) {
    return '중국어 전신 부호: $codes';
  }

  @override
  String get referenceTelegraphMainland => '중국 본토(1983)';

  @override
  String get referenceTelegraphTaiwan => '대만 / 홍콩';

  @override
  String get referenceTelegraphNone => '이 부호표에 없음';

  @override
  String get appearanceTitle => '화면 모양';

  @override
  String get appearanceStyles => '인터페이스 스타일';

  @override
  String get appearanceChoose => '스타일을 선택하고 미리 본 후 적용하세요';

  @override
  String get appearanceMode => '밝기';

  @override
  String get appearancePreview => '미리 보기';

  @override
  String get appearanceApply => '스타일 적용';

  @override
  String get appearanceRestore => '기본값 복원';

  @override
  String get appearanceApplied => '화면 모양을 저장했습니다';

  @override
  String get appearanceSaveFailed => '화면 모양을 저장할 수 없습니다. 다시 시도하세요.';

  @override
  String get appearanceClassic => '고전적인 황동';

  @override
  String get appearanceModern => '차분한 현대';

  @override
  String get appearanceRadio => '밤의 무선국';

  @override
  String get appearancePaper => '종이 수첩';

  @override
  String get appearanceCartoon => '산뜻한 만화';

  @override
  String get appearanceLight => '밝게';

  @override
  String get appearanceDark => '어둡게';

  @override
  String get appearanceSubtitle => '밝은 모드와 어두운 모드를 지원하는 다섯 가지 스타일';

  @override
  String get chatClearHistoryBody => '이 기기에 저장된 대화 기록을 삭제할까요? 다른 기기의 사본에는 영향을 주지 않습니다. 되돌릴 수 없습니다.';

  @override
  String get chatLoadEarlier => '이전 메시지 불러오기';

  @override
  String get chatHistoryLoadFailed => '이전 메시지를 불러올 수 없습니다. 탭하여 다시 시도하세요.';

  @override
  String get chatRetryHistory => '다시 시도';

  @override
  String chatNewMessages(int count) {
    return '새 메시지 $count개';
  }

  @override
  String learnShowAllChars(int count) {
    return '문자 $count개 모두 보기';
  }

  @override
  String get chatSelfMe => '나';

  @override
  String get chatSelfLocalOnly => '이 기기에만 저장';

  @override
  String get chatSelfContactSubtitle => '초안, 연습과 메모 · 전송되지 않음';

  @override
  String get learnShowFewerChars => '문자 접기';

  @override
  String get learnLeaveDrillTitle => '이 세션을 나가시겠습니까?';

  @override
  String get learnLeaveDrillBody => '이 세션에서 진행한 라운드는 저장되지 않습니다.';

  @override
  String get learnLeaveDrillConfirm => '나가기';

  @override
  String get chatScanQrPermissionDenied => 'QR 코드를 스캔하려면 DitMesh에 카메라 접근 권한이 필요합니다. 시스템 설정에서 허용하세요.';

  @override
  String get chatScanQrCameraUnavailable => '이 기기에서는 카메라를 사용할 수 없습니다.';

  @override
  String get learnReplayAssistedNote => '다시 들음: 연습으로는 집계되지만 레슨 해제나 복습 갱신에는 반영되지 않습니다.';

  @override
  String get learnPlanTitle => '오늘의 계획';

  @override
  String learnPlanSummary(int minutes, int done, int total) {
    return '약 $minutes분 · $total단계 중 $done단계 완료';
  }

  @override
  String get learnPlanBudget => '계획 길이';

  @override
  String learnPlanBudgetMinutes(int minutes) {
    return '$minutes분';
  }

  @override
  String get learnPlanStart => '계획 시작';

  @override
  String get learnPlanContinue => '계획 계속';

  @override
  String get learnPlanStepReview => '복습할 문자';

  @override
  String get learnPlanStepFocus => '집중 연습';

  @override
  String learnPlanStepCourse(int lesson) {
    return '레슨 $lesson';
  }

  @override
  String get learnPlanStepSend => '송신 연습';

  @override
  String learnPlanReasonDueReview(String symbols) {
    return '복습 차례: $symbols';
  }

  @override
  String learnPlanReasonConfusions(String symbols) {
    return '자주 헷갈림: $symbols';
  }

  @override
  String learnPlanReasonWeak(String symbols) {
    return '정확도 90% 미만: $symbols';
  }

  @override
  String learnPlanReasonChallenge(int count) {
    return '$count자: 다음 레슨을 열 수 있음';
  }

  @override
  String learnPlanReasonExtended(int count) {
    return '다음 레슨을 열 수 있도록 $count자로 늘렸습니다';
  }

  @override
  String get learnPlanReasonConsolidate => '짧은 연습: 이번 레슨을 다지며 다음 레슨은 열리지 않습니다';

  @override
  String learnPlanReasonOutdated(int lesson) {
    return '코스가 진행됨: 레슨 $lesson을 연습하지만 해제하지 않습니다';
  }

  @override
  String learnPlanReasonSend(int count) {
    return '짧은 목표 $count개 송신';
  }

  @override
  String learnPlanStepDonePercent(int percent) {
    return '완료 · $percent%';
  }

  @override
  String get learnPlanStepDone => '완료';

  @override
  String learnPlanSendProgress(int done, int total) {
    return '$total개 중 $done개 송신';
  }

  @override
  String get learnPlanStale => '레슨 또는 속도가 바뀌었습니다. 시작하지 않은 단계를 갱신할까요?';

  @override
  String get learnPlanUpdate => '단계 갱신';

  @override
  String get learnPlanComplete => '오늘 계획 완료';

  @override
  String learnPlanNeedsWork(String symbols) {
    return '더 연습할 문자: $symbols';
  }

  @override
  String get learnPlanAllGood => '오늘은 약한 문자가 없습니다.';

  @override
  String get learnPlanTomorrow => '내일 새 계획이 만들어집니다. 자유 연습은 언제든 가능합니다.';

  @override
  String learnPlanNext(String step) {
    return '다음: $step';
  }

  @override
  String learnPlanEarlier(int done, int total) {
    return '이전 계획은 $total단계 중 $done단계에서 멈췄으며 오늘에는 반영되지 않습니다.';
  }

  @override
  String learnSpeedAdviceRaise(int wpm) {
    return '유효 속도 $wpm WPM으로 올릴 준비가 되었습니다';
  }

  @override
  String learnSpeedAdviceRaiseBoth(int wpm) {
    return '$wpm WPM으로 올릴 준비가 되었습니다';
  }

  @override
  String learnSpeedAdviceLower(int wpm) {
    return '이 속도에서는 수신이 어렵습니다. 유효 속도 $wpm WPM 또는 집중 연습을 해 보세요.';
  }

  @override
  String learnSpeedAdviceBody(int count, int percent) {
    return '최근 보조 없는 연습 $count회($percent%) 기준입니다. 적용하기 전에는 아무것도 바뀌지 않습니다.';
  }

  @override
  String get learnSpeedAdviceApply => '적용';

  @override
  String get learnSpeedAdviceDismiss => '나중에';

  @override
  String get learnSpeedAdviceInsufficient => '속도 조언에는 현재 속도에서 50자 이상의 보조 없는 연습 3회가 필요합니다.';

  @override
  String get learnQsoAction => 'QSO 시뮬레이터';

  @override
  String learnQsoLocked(int lesson) {
    return '레슨 $lesson부터';
  }

  @override
  String get learnQsoTitle => 'QSO 시뮬레이터';

  @override
  String get learnQsoRespond => 'CQ에 응답';

  @override
  String get learnQsoRespondHint => '한 국이 CQ를 냅니다. 응답하고 리포트를 교환하세요.';

  @override
  String get learnQsoCall => 'CQ 내기';

  @override
  String get learnQsoCallHint => 'CQ를 내면 한 국이 응답합니다.';

  @override
  String get learnQsoYourCall => '내 호출부호';

  @override
  String get learnQsoYourName => '내 이름';

  @override
  String get learnQsoYourQth => '내 QTH';

  @override
  String get learnQsoInvalidCall => 'BD1XYZ 같은 호출부호를 입력하세요';

  @override
  String get learnQsoInvalidWord => '한 단어, A–Z 문자만';

  @override
  String get learnQsoOffline => '이 기기에서만 동작하며 아무것도 전송하지 않습니다.';

  @override
  String get learnQsoStart => 'QSO 시작';

  @override
  String get learnQsoResume => '중단된 QSO 이어하기';

  @override
  String get learnQsoStageCallCq => '내 호출부호로 CQ 내기';

  @override
  String get learnQsoStageCallConfirm => '응답: 상대 부호, DE, 내 부호';

  @override
  String get learnQsoStageExchange => '리포트, 이름, QTH 보내기';

  @override
  String get learnQsoStageConfirmInfo => '상대 정보 확인';

  @override
  String get learnQsoStageClosing => '73과 <SK>로 마무리';

  @override
  String get learnQsoStageDone => 'QSO 완료';

  @override
  String learnQsoSpeed(int wpm) {
    return '상대는 유효 $wpm WPM으로 송신';
  }

  @override
  String learnQsoRemote(String call) {
    return '$call 송신';
  }

  @override
  String get learnQsoRemoteHidden => '귀로 받아 적으세요. 텍스트는 숨겨져 있습니다.';

  @override
  String get learnQsoShowText => '텍스트 보기';

  @override
  String get learnQsoListen => '듣기';

  @override
  String get learnQsoAccepted => '통과';

  @override
  String get learnQsoRejected => '통과하지 못함';

  @override
  String get learnQsoRemoteSending => '상대 국이 송신 중…';

  @override
  String get learnQsoYourTurn => '내 차례: 응답을 키잉한 뒤 보내기를 누르세요.';

  @override
  String get learnQsoDecoded => '내 송신 내용';

  @override
  String get learnQsoNothingKeyed => '아직 키잉하지 않음';

  @override
  String get learnQsoPlayAgain => '반복 요청(AGN)';

  @override
  String get learnQsoSlower => '속도 낮춤 요청(QRS)';

  @override
  String get learnQsoHint => '힌트';

  @override
  String learnQsoHintLabel(String example) {
    return '예: $example';
  }

  @override
  String get learnQsoPause => '일시정지';

  @override
  String get learnQsoSend => '보내기';

  @override
  String get learnQsoClear => '지우기';

  @override
  String get learnQsoIssueEmpty => '키잉한 내용이 없습니다.';

  @override
  String get learnQsoIssueMissingCq => 'CQ로 시작하세요.';

  @override
  String get learnQsoIssueMissingDe => '호출부호 사이에 DE를 넣으세요.';

  @override
  String get learnQsoIssueWrongLocalCall => '내 호출부호가 없거나 틀렸습니다.';

  @override
  String get learnQsoIssueWrongRemoteCall => '상대 국의 호출부호가 틀렸습니다.';

  @override
  String get learnQsoIssueReversedCalls => '순서가 반대입니다: 상대, DE, 내 부호 순입니다.';

  @override
  String get learnQsoIssueMissingEnding => 'K 또는 KN으로 끝내세요.';

  @override
  String get learnQsoIssueMissingRst => '리포트를 주세요. 예: UR RST 599';

  @override
  String get learnQsoIssueInvalidRst => 'RST 범위를 벗어났습니다(R 1–5, S 1–9, T 1–9).';

  @override
  String get learnQsoIssueMissingName => 'NAME과 이름을 보내세요.';

  @override
  String get learnQsoIssueWrongName => '이번 QSO의 내 이름이 아닙니다.';

  @override
  String get learnQsoIssueMissingQth => 'QTH와 위치를 보내세요.';

  @override
  String get learnQsoIssueWrongQth => '이번 QSO의 내 QTH가 아닙니다.';

  @override
  String get learnQsoIssueMissingAck => 'R 또는 QSL로 확인하세요.';

  @override
  String get learnQsoIssueWrongRemoteName => '상대 운용자 이름을 확인하세요.';

  @override
  String get learnQsoIssueMissing73 => '73을 넣으세요.';

  @override
  String get learnQsoIssueMissingSk => '<SK>로 교신을 끝내세요.';

  @override
  String learnQsoSummaryFields(int count, int total) {
    return '한 번에 통과: $total단계 중 $count';
  }

  @override
  String learnQsoSummaryRepeats(int count) {
    return '반복: $count';
  }

  @override
  String learnQsoSummaryHints(int count) {
    return '힌트: $count';
  }

  @override
  String learnQsoSummaryRhythm(int wpm) {
    return '내 송신: 약 $wpm WPM';
  }

  @override
  String get learnQsoSummaryNote => 'QSO 결과는 수신 정확도와 따로 집계되며 레슨을 열지 않습니다.';

  @override
  String get messageStatusCancelled => '취소됨 — 전송되지 않음';

  @override
  String get chatMessageLearnActions => '메시지 작업';

  @override
  String get chatPracticeMessage => '이 메시지 수신 연습';

  @override
  String get chatSaveAsMaterial => '연습 자료로 저장';

  @override
  String get chatSavedAsMaterial => '내 자료에 저장했습니다';

  @override
  String get chatSaveMaterialFailed => '자료를 저장하지 못했습니다. 다시 시도하세요.';

  @override
  String get chatListenOnly => '듣기 전용 훈련';

  @override
  String get chatListenOnlyHidden => '듣기 전용: 재생을 눌러 들으세요';

  @override
  String chatClearHistoryMaterials(int count) {
    return '이 대화의 메시지 $count개가 연습 자료로 저장되어 있습니다. 사본은 학습 › 내 자료에서 삭제할 때까지 남습니다.';
  }

  @override
  String get chatPracticeTitle => '수신 연습';

  @override
  String chatPracticeUnsupported(String chars) {
    return '이 메시지에 모스로 칠 수 없는 문자가 있습니다: $chars. 연습에서 제외됩니다.';
  }

  @override
  String chatPracticeTrainableCount(int count) {
    return '$count자를 연습할 수 있습니다.';
  }

  @override
  String get chatPracticeNothingTrainable => '이 메시지에는 모스로 연습할 내용이 없습니다.';

  @override
  String get chatPracticeConfirm => '나머지 연습';

  @override
  String get chatPracticeHint => '힌트';

  @override
  String chatPracticeHintShown(String symbols) {
    return '힌트: $symbols …';
  }

  @override
  String get chatPracticeAssisted => '보조 사용: 연습으로는 집계되지만 복습이나 속도 조언에는 쓰이지 않습니다.';

  @override
  String chatPracticeErrors(int wrong, int missed, int extra) {
    return '틀림 $wrong · 빠짐 $missed · 추가 $extra';
  }

  @override
  String chatPracticeErrorsAction(String symbols) {
    return '틀린 문자 연습: $symbols';
  }

  @override
  String get learnTipDahTooLongTitle => '장점이 너무 김';

  @override
  String learnTipDahTooLong(String ratio) {
    return '장점이 깁니다(단점의 약 $ratio, 목표는 3배). 단점 세 개 길이가 지나면 떼세요.';
  }

  @override
  String learnIssueDetailDahTooLong(int offending, int total, String ratio) {
    return '장점 $total개 중 $offending개가 너무 김(평균 $ratio 단점)';
  }

  @override
  String get learnRhythmTitle => '리듬';

  @override
  String get learnRhythmMine => '내 리듬';

  @override
  String get learnRhythmStandard => '표준 리듬(목표 속도)';

  @override
  String learnRhythmNormalizedNote(int ms) {
    return '문제는 내 단점 길이($ms ms)를 기준으로 판단하므로 느려도 고르면 괜찮습니다. 표준 줄은 목표 속도입니다.';
  }

  @override
  String get learnRhythmNotLocated => '키잉을 문자 단위로 맞추지 못했습니다. 목표 전체를 연습하세요.';

  @override
  String get learnRhythmPlayMine => '내 것 재생';

  @override
  String get learnRhythmPlayStandard => '표준 재생';

  @override
  String learnRhythmPracticePart(int count) {
    return '이것 연습($count회)';
  }

  @override
  String get learnRhythmPracticeWhole => '목표 전체 연습';

  @override
  String get learnRhythmSymbolOk => '좋음';

  @override
  String get learnRhythmZoomIn => '확대';

  @override
  String get learnRhythmZoomOut => '축소';

  @override
  String get chatSearchMessages => '메시지 검색';

  @override
  String get chatSearchHint => '이 대화에서 검색';

  @override
  String get chatSearchAnyone => '모두';

  @override
  String get chatSearchMe => '나';

  @override
  String get chatSearchThem => '상대';

  @override
  String get chatSearchAnyDate => '모든 날짜';

  @override
  String chatSearchDateRange(String from, String to) {
    return '$from – $to';
  }

  @override
  String get chatSearchBookmarked => '북마크';

  @override
  String get chatSearchNoResults => '일치하는 메시지가 없습니다.';

  @override
  String get chatSearchMore => '더 보기';

  @override
  String get chatAddBookmark => '북마크';

  @override
  String get chatRemoveBookmark => '북마크 해제';

  @override
  String get chatBookmarked => '북마크됨';

  @override
  String get chatBookmarkFailed => '북마크를 저장하지 못했습니다.';

  @override
  String get chatRetrySend => '다시 보내기';

  @override
  String get chatCancelSend => '전송 취소';

  @override
  String get chatRetryQueued => '다시 대기열에 넣었습니다. 상대가 온라인이 되면 보냅니다.';

  @override
  String get chatSendCancelled => '취소했습니다. 메시지는 전송되지 않았습니다.';

  @override
  String get chatRetryNotNeeded => '이 메시지는 더 이상 실패 상태가 아닙니다.';

  @override
  String get chatCancelTooLate => '취소하기에 늦었습니다. 메시지가 이미 네트워크로 넘어가 도착할 수 있습니다.';

  @override
  String get chatSendControlUnavailable => '이 메시지에는 사용할 수 없습니다.';

  @override
  String get chatSendControlFailed => '실패했습니다. 메시지 상태는 그대로입니다. 다시 시도하세요.';

  @override
  String get workbenchTitle => '녹음 작업대';

  @override
  String get workbenchOpen => '녹음';

  @override
  String get workbenchImport => '녹음 가져오기';

  @override
  String get workbenchEmpty => 'WAV 녹음을 가져와 반복 재생, 해독, 직접 받아 적기를 할 수 있습니다. 마이크는 필요 없습니다.';

  @override
  String get workbenchFormats => 'WAV, 16비트 PCM, 모노 또는 스테레오, 8/16/44.1/48 kHz, 최대 50MB·20분.';

  @override
  String get workbenchBackupNote => '녹음은 이 기기에 남으며, 백업을 내보낼 때 포함하기로 선택하지 않으면 신원 백업에 들어가지 않습니다. 저장한 구간의 제목, 메모, 위치는 항상 백업됩니다.';

  @override
  String workbenchInfo(String rate, String channels, String duration) {
    return '$rate kHz · $channels · $duration';
  }

  @override
  String get workbenchMono => '모노';

  @override
  String get workbenchStereo => '스테레오';

  @override
  String get workbenchTruncated => '파일이 일찍 끝납니다. 있는 오디오만 사용합니다.';

  @override
  String get workbenchErrorNotWav => 'WAV 파일이 아닙니다.';

  @override
  String get workbenchErrorFormat => '현재는 16비트 PCM WAV만 지원합니다(MP3, AAC, 부동소수점 WAV 불가).';

  @override
  String get workbenchErrorChannels => '모노 또는 스테레오 녹음만 지원합니다.';

  @override
  String get workbenchErrorRate => '지원하지 않는 샘플레이트입니다. 8, 16, 44.1, 48kHz를 사용하세요.';

  @override
  String get workbenchErrorDamaged => '파일이 손상되었거나 불완전합니다.';

  @override
  String get workbenchErrorTooLarge => '파일이 50MB를 넘습니다.';

  @override
  String get workbenchErrorTooLong => '녹음이 20분을 넘습니다.';

  @override
  String get workbenchErrorIo => '파일을 읽을 수 없습니다.';

  @override
  String get workbenchErrorMissing => '녹음 파일이 없습니다.';

  @override
  String get workbenchStart => '시작(초)';

  @override
  String get workbenchEnd => '끝(초)';

  @override
  String get workbenchSelectAll => '전체 선택';

  @override
  String get workbenchPlay => '선택 구간 재생';

  @override
  String get workbenchStop => '정지';

  @override
  String get workbenchLoop => '반복';

  @override
  String get workbenchPlayLimit => '긴 구간은 처음 5분만 재생합니다.';

  @override
  String get workbenchAutoTune => '톤 자동 찾기';

  @override
  String workbenchManualTone(int hz) {
    return '톤: $hz Hz';
  }

  @override
  String get workbenchDecode => '선택 구간 해독';

  @override
  String get workbenchCancel => '취소';

  @override
  String workbenchDecoding(int percent) {
    return '해독 중… $percent%';
  }

  @override
  String workbenchResultStats(int hz, int wpm) {
    return '톤 ${hz}Hz · 약 $wpm WPM';
  }

  @override
  String get workbenchToneNotLocked => '안정된 톤을 찾지 못했습니다. 수동 조정을 해 보세요.';

  @override
  String get workbenchNoText => '이 구간에서 해독된 내용이 없습니다.';

  @override
  String workbenchUnknown(String patterns) {
    return '알 수 없는 패턴: $patterns';
  }

  @override
  String get workbenchEdgeCut => '구간 가장자리의 문자가 잘려 틀릴 수 있습니다.';

  @override
  String get workbenchToneNote => '톤 고정은 신뢰도가 아닙니다. 귀로 텍스트를 확인하세요.';

  @override
  String get workbenchModeDecoder => '디코더';

  @override
  String get workbenchModeCopy => '직접 받아 적기';

  @override
  String get workbenchDecoderHidden => '받아 적는 동안 디코더 텍스트는 숨겨집니다.';

  @override
  String get workbenchShowDecoder => '디코더 텍스트 보기';

  @override
  String get workbenchReference => '기준 텍스트(선택)';

  @override
  String get workbenchReferenceHelp => '보낸 텍스트를 붙여 넣으세요. 없으면 디코더 출력과 비교합니다.';

  @override
  String get workbenchAgainstDecoder => '디코더 출력과 비교했으며, 출력 자체가 틀릴 수 있습니다.';

  @override
  String get workbenchSave => '구간 저장';

  @override
  String get workbenchSaveTitle => '제목';

  @override
  String get workbenchSaveNote => '메모';

  @override
  String get workbenchSaved => '구간을 저장했습니다';

  @override
  String get workbenchSaveFailed => '구간을 저장할 수 없습니다.';

  @override
  String get workbenchLibrary => '저장한 구간';

  @override
  String get workbenchLibraryEmpty => '아직 저장한 구간이 없습니다.';

  @override
  String get workbenchMissing => '녹음 파일이 없습니다. 다시 선택하거나 항목을 삭제하세요.';

  @override
  String get workbenchRelink => '파일 다시 선택';

  @override
  String get workbenchDelete => '삭제';

  @override
  String get materialsTitle => '내 자료';

  @override
  String get materialsNew => '새 자료';

  @override
  String get materialsEdit => '편집';

  @override
  String get materialsSave => '저장';

  @override
  String get materialsSaveFailed => '자료를 저장하지 못했습니다.';

  @override
  String get materialsTitleField => '제목';

  @override
  String get materialsTagsField => '태그(쉼표로 구분)';

  @override
  String get materialsTextField => '텍스트';

  @override
  String get materialsListField => '한 줄에 한 항목';

  @override
  String get materialsKindText => '텍스트';

  @override
  String get materialsKindWords => '단어 목록';

  @override
  String get materialsKindCallsigns => '호출부호';

  @override
  String get materialsPreview => '미리 보기';

  @override
  String materialsPreviewCounts(int items, int symbols, int prosigns) {
    return '$items개 항목 · $symbols자 · 절차 신호 $prosigns개';
  }

  @override
  String materialsPreviewUnsupported(String chars) {
    return '모스 부호가 없어 연습에서 제외: $chars';
  }

  @override
  String materialsPreviewDuplicates(int count) {
    return '중복 항목 $count개는 한 번만 유지';
  }

  @override
  String get materialsProblemEmpty => '먼저 텍스트를 입력하세요.';

  @override
  String get materialsProblemTooLarge => '너무 큽니다. 자료는 1 MiB까지입니다.';

  @override
  String materialsProblemTooManyEntries(int count) {
    return '항목이 너무 많습니다(최대 $count).';
  }

  @override
  String materialsProblemEntryTooLong(int count) {
    return '너무 긴 항목이 있습니다(항목당 $count자까지).';
  }

  @override
  String get materialsProblemNothingTrainable => '모스로 연습할 내용이 없습니다.';

  @override
  String get materialsSearch => '자료 검색';

  @override
  String get materialsFavoritesOnly => '즐겨찾기';

  @override
  String get materialsFavorite => '즐겨찾기에 추가';

  @override
  String get materialsUnfavorite => '즐겨찾기에서 제거';

  @override
  String get materialsEmpty => '아직 자료가 없습니다. 직접 텍스트, 단어 목록, 호출부호를 추가하거나 채팅 메시지를 저장하세요.';

  @override
  String materialsItems(int count) {
    return '$count개 항목';
  }

  @override
  String get materialsFromChat => '채팅에서';

  @override
  String get materialsActions => '자료 작업';

  @override
  String get materialsPractise => '연습';

  @override
  String get materialsDelete => '삭제';

  @override
  String get materialsDeleteTitle => '자료를 삭제할까요?';

  @override
  String materialsDeleteBody(String title) {
    return '‘$title’을(를) 이 기기에서 삭제합니다. 연습 기록은 남습니다.';
  }

  @override
  String get materialsImport => 'TXT 또는 JSON 가져오기';

  @override
  String get materialsImportDialogTitle => '자료 파일 선택';

  @override
  String get materialsSaveDialogTitle => '자료 저장';

  @override
  String get materialsImportFailed => '가져오기에 실패했습니다. 자료 목록은 그대로입니다.';

  @override
  String get materialsImportNotUtf8 => 'UTF-8 텍스트 파일만 가져올 수 있습니다.';

  @override
  String get materialsImportInvalid => '올바른 DitMesh 자료 파일이 아닙니다. 아무것도 가져오지 않았습니다.';

  @override
  String materialsImported(int count) {
    return '자료 $count개를 가져왔습니다.';
  }

  @override
  String get materialsDuplicateTitle => '일부 자료가 이미 있습니다';

  @override
  String get materialsDuplicateOverwrite => '바꾸기';

  @override
  String get materialsDuplicateKeepCopy => '둘 다 유지(사본으로)';

  @override
  String get materialsDuplicateSkip => '건너뛰기';

  @override
  String get materialsExportJson => 'JSON으로 내보내기';

  @override
  String materialsExported(int count) {
    return '자료 $count개를 내보냈습니다.';
  }

  @override
  String get materialsExportFailed => '내보내기에 실패했습니다.';

  @override
  String get materialsExportWav => '오디오 내보내기(WAV)';

  @override
  String materialsWavCharSpeed(int wpm) {
    return '문자 속도: $wpm WPM';
  }

  @override
  String materialsWavEffSpeed(int wpm) {
    return '유효 속도: $wpm WPM';
  }

  @override
  String materialsWavTone(int hz) {
    return '톤: $hz Hz';
  }

  @override
  String get materialsWavWithAnswer => '정답 텍스트 포함(.txt)';

  @override
  String get materialsWavFormat => '16비트 모노 WAV, 48kHz.';

  @override
  String materialsWavParts(int count) {
    return '10분이 넘어 파일 $count개로 내보냅니다.';
  }

  @override
  String materialsWavExported(int count) {
    return '오디오 파일 $count개를 저장했습니다.';
  }

  @override
  String get materialsPracticeMode => '연습 범위';

  @override
  String get materialsPracticeLearned => '배운 문자만';

  @override
  String materialsPracticeLearnedPartial(int count) {
    return '배운 문자만(아직 배우지 않은 문자가 있어 $count개 항목 제외)';
  }

  @override
  String get materialsPracticeAll => '모든 모스 문자';

  @override
  String get materialsPracticeNothing => '이 모드에서 연습할 항목이 없습니다.';

  @override
  String get guestTryLearning => '먼저 학습해 보기';

  @override
  String get guestBanner => '게스트 학습: 진행 상황은 이 기기에 남습니다. 채팅에는 신원이 필요합니다.';

  @override
  String get guestGetIdentity => '신원 설정';

  @override
  String get guestIdentityTitle => '신원 필요';

  @override
  String get guestIdentityBody => 'Tox 채팅에는 자신의 신원이 필요합니다. 새로 만들거나 백업을 복원하거나 이 기기의 신원을 잠금 해제하세요. 새 신원을 만들면 게스트 학습 진행 상황이 자동으로 옮겨집니다.';

  @override
  String get guestClearData => '게스트 학습 데이터 삭제';

  @override
  String get guestClearDataBody => '이 기기에서 게스트로 만든 진행 상황, 계획, 자료를 삭제합니다. 신원에는 영향이 없습니다.';

  @override
  String get guestClearConfirm => '삭제';

  @override
  String get guestCleared => '게스트 학습 데이터를 삭제했습니다.';

  @override
  String get guestClearFailed => '게스트 데이터를 삭제하지 못했습니다.';

  @override
  String get guestMigrationFailed => '신원은 준비되었지만 게스트 학습 진행 상황이 아직 옮겨지지 않았습니다. 이 기기에 안전하게 남아 있습니다.';

  @override
  String get guestChoiceBody => '게스트 학습 진행 상황도 있습니다. 복원한 신원의 진행 상황을 사용 중이며 합치지 않았습니다.';

  @override
  String get guestChoiceKeep => '복원본 유지';

  @override
  String get guestChoiceUseGuest => '게스트 진행 상황 사용';

  @override
  String get placementTitle => '내 수준 확인';

  @override
  String get placementCheckLevel => '현재 수준 확인';

  @override
  String get placementFromZero => '처음부터 시작';

  @override
  String get placementOfferTitle => '모스가 처음인가요, 이미 받아 적을 수 있나요?';

  @override
  String get placementOfferBody => '짧은 확인으로 시작 위치를 제안할 수 있습니다. 선택 사항이며 고르기 전에는 아무것도 바뀌지 않습니다.';

  @override
  String get placementIntro => '약 3~5분, 5단계로 받아 적습니다. 속도를 높여 가며 코흐 순서 문자 묶음, 마지막에 짧은 단어. 적은 표본에 따른 대략적 안내이며 인증이 아닙니다. 언제든 멈출 수 있습니다.';

  @override
  String get placementStart => '시작';

  @override
  String get placementSkip => '건너뛰기';

  @override
  String get placementStop => '중지';

  @override
  String placementTierProgress(int step, int total, int wpm) {
    return '$total단계 중 $step · 유효 $wpm WPM';
  }

  @override
  String get placementTierPassed => '잘 받아 적었습니다. 다음 단계는 더 빠릅니다.';

  @override
  String get placementTierStopped => '이 단계가 90% 미만이라 확인을 마칩니다.';

  @override
  String get placementNextTier => '다음 단계';

  @override
  String placementSuggestion(int lesson) {
    return '추천 시작: 레슨 $lesson';
  }

  @override
  String placementVerified(int count, int total) {
    return '코흐 순서 문자 $total개 중 $count개를 차례로 확인했습니다.';
  }

  @override
  String get placementLimits => '짧은 표본 기준입니다. 확인하지 않은 문자는 미확인으로 남고 습득으로 표시되지 않습니다. 레슨은 언제든 바꿀 수 있습니다.';

  @override
  String placementAdopt(int lesson) {
    return '레슨 $lesson부터 시작';
  }

  @override
  String get chatJumpToLatest => '최신 메시지';

  @override
  String get chatMessageGone => '그 메시지는 더 이상 이 대화에 없습니다.';

  @override
  String get chatListenOnlyPreview => '새 메시지 — 들으며 받아 적으세요';

  @override
  String get chatSaveMaterialConfirm => '나머지 저장';

  @override
  String materialsImportConfirm(int count) {
    return '자료 $count개를 가져올까요?';
  }

  @override
  String get materialsExportTxt => '텍스트로 내보내기(TXT)';

  @override
  String get accountBackupMediaTitle => '저장한 녹음을 포함할까요?';

  @override
  String accountBackupMediaBody(int count, String size) {
    return '저장한 녹음 $count개(${size}MB). 제목, 메모, 위치는 항상 백업되며, 오디오는 포함할 때만 들어갑니다.';
  }

  @override
  String accountBackupMediaTooLarge(String size) {
    return '저장한 녹음(${size}MB)은 너무 커서 백업에 넣을 수 없습니다. 제목, 메모, 위치만 포함됩니다.';
  }

  @override
  String get accountBackupMediaInclude => '녹음 포함';

  @override
  String get accountBackupMediaSkip => '녹음 없이';

  @override
  String get diagTitle => '연결 진단';

  @override
  String get diagOpenSubtitle => '메시지가 대기 중인 이유와 다시 연결하는 방법';

  @override
  String get diagBannerDetails => '자세히';

  @override
  String get diagSummaryNoIdentity => '열린 ID가 없어 확인할 연결이 없습니다.';

  @override
  String get diagSummaryOnlinePeerOnline => 'Tox 네트워크에 연결되어 있고 이 연락처도 온라인입니다. 메시지가 바로 전달됩니다.';

  @override
  String get diagSummaryOnlinePeerOffline => '연결되어 있지만 이 연락처는 오프라인입니다. 메시지는 이 기기의 보낼 편지함에서 기다리다가 상대가 온라인이 되면 전송됩니다.';

  @override
  String get diagSummaryOnline => 'Tox 네트워크에 연결되어 있습니다.';

  @override
  String get diagSummaryConnecting => 'Tox 네트워크에 연결하는 중입니다. 앱 시작 직후나 네트워크가 바뀐 뒤에는 1분 정도 걸릴 수 있습니다.';

  @override
  String get diagSummaryOffline => 'Tox 네트워크에 연결되어 있지 않습니다. 연결이 돌아올 때까지 아무것도 주고받을 수 없습니다.';

  @override
  String get diagLocalLabel => '내 연결';

  @override
  String diagSinceChanged(String time) {
    return '$time부터';
  }

  @override
  String diagSinceFirst(String time) {
    return '$time부터 관찰됨';
  }

  @override
  String diagSinceResumed(String time) {
    return '$time에 앱으로 돌아온 뒤부터 관찰됨';
  }

  @override
  String get diagLastOnlineLabel => '마지막으로 확인된 연결';

  @override
  String get diagLastOnlineNow => '지금 연결됨';

  @override
  String get diagLastOnlineNone => '아직 확인된 연결이 없습니다.';

  @override
  String get diagLastOnlineHint => '이 기기가 자신의 연결을 마지막으로 확인한 시각입니다. 메시지가 상대에게 도착한 시각이 아닙니다.';

  @override
  String get diagPeerLabel => '연락처';

  @override
  String get diagUnknown => '알 수 없음';

  @override
  String get diagPeerUnknownHint => '연락처의 접속 여부는 내가 연결되어 있을 때만 볼 수 있습니다.';

  @override
  String get diagPeerGroupHint => '그룹 멤버의 접속 여부는 멤버 목록에 표시됩니다.';

  @override
  String get diagPendingLabel => '전송 대기';

  @override
  String get diagPendingNone => '대기 중인 메시지 없음';

  @override
  String diagPendingCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '메시지 $count개',
    );
    return '$_temp0';
  }

  @override
  String diagPendingOldest(String time) {
    return '가장 오래된 메시지: $time';
  }

  @override
  String get diagPendingUnknown => '채팅이 연결될 때까지 알 수 없음';

  @override
  String get diagPendingHint => '대기 중인 메시지는 이 기기에 남아 있다가 상대에게 닿을 수 있을 때 자동으로 전송됩니다. 진단은 메시지를 삭제하거나 다시 보내지 않습니다.';

  @override
  String get diagReconnect => '다시 연결';

  @override
  String get diagReconnecting => '다시 연결하는 중…';

  @override
  String diagReconnectFailed(String reason) {
    return '다시 연결하지 못했습니다: $reason';
  }

  @override
  String get diagReconnectNote => '다시 연결하면 연결 시도를 새로 시작합니다. 온라인이 되기까지 시간이 걸릴 수 있으며, 그때 이 페이지가 갱신됩니다.';

  @override
  String get diagAboutTitle => 'DitMesh의 연결 방식';

  @override
  String get diagAboutBody => 'DitMesh에는 서버가 없습니다. 기기가 Tox P2P 네트워크로 연락처와 직접 통신하므로, 메시지가 도착하려면 양쪽이 동시에 온라인이어야 합니다. 휴대폰은 백그라운드 앱을 일시 중지하므로 그동안 DitMesh는 연결을 유지할 수 없고, 돌아오면 다시 연결합니다.';

  @override
  String get diagDetailsTitle => '기술 세부 정보';

  @override
  String get diagDetailIdentity => 'ID';

  @override
  String get diagDetailStatus => '상태';

  @override
  String get diagDetailObserved => '관찰 시각';

  @override
  String get diagDetailQueued => '대기열 항목';

  @override
  String get diagDetailError => '마지막 오류 코드';

  @override
  String get backupXTitle => '암호화 백업';

  @override
  String get backupXIntro => '다른 기기로 가져갈 항목을 고르세요. 파일 전체가 여기서 정한 암호 문구로 암호화됩니다.';

  @override
  String get backupXCategoryIdentity => 'ID와 Tox 프로필';

  @override
  String get backupXCategoryTraining => '연습 진도와 자료';

  @override
  String get backupXCategoryChat => '채팅 기록(나에게 쓴 메모 포함)';

  @override
  String get backupXCategoryMeta => '임시 저장, 고정, 북마크';

  @override
  String get backupXCategoryPrefs => '앱 환경설정';

  @override
  String get backupXPrefsHint => '재생, 알림, 모양, 언어. 창 위치나 키 할당은 포함하지 않습니다.';

  @override
  String get backupXCategoryMedia => '저장한 녹음';

  @override
  String get backupXMediaHint => '기본값은 꺼짐: 녹음은 클 수 있습니다. 제외하면 제목과 메모만 옮겨집니다.';

  @override
  String get backupXCategoryPending => '보내지 않은 메시지';

  @override
  String get backupXPendingHint => '검토용으로만 돌아오며 자동으로 전송되지 않습니다.';

  @override
  String get backupXRequired => '필수';

  @override
  String backupXSizeLine(int count, String size) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count개',
    );
    return '$_temp0 · $size';
  }

  @override
  String backupXSizeKb(String size) {
    return '${size}KB';
  }

  @override
  String backupXSizeMb(String size) {
    return '${size}MB';
  }

  @override
  String backupXMediaTooLarge(String size) {
    return '너무 커서 포함할 수 없음($size)';
  }

  @override
  String backupXInvitesNote(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '오프라인 친구를 기다리는 그룹 초대 $count건은 옮겨지지 않습니다.',
    );
    return '$_temp0';
  }

  @override
  String get backupXIdentityPasswordNote => 'ID 비밀번호는 프로필에 그대로 남습니다. 새 기기에서 백업 암호 문구와 함께 물어봅니다.';

  @override
  String backupXTotal(String size) {
    return '합계 약 $size';
  }

  @override
  String get backupXPassphrase => '백업 암호 문구';

  @override
  String get backupXPassphraseConfirm => '암호 문구 다시 입력';

  @override
  String get backupXPassphraseHint => '8자 이상. ID 비밀번호와 별개이며 복구할 수 없습니다.';

  @override
  String get backupXPassphraseTooShort => '8자 이상 입력하세요';

  @override
  String get backupXPassphraseMismatch => '암호 문구가 일치하지 않습니다';

  @override
  String get backupXExport => '암호화 백업 만들기';

  @override
  String get backupXExporting => '백업 만드는 중…';

  @override
  String get backupXMigrationNote => '기기를 옮기시나요? 새 기기에서 복원한 뒤에는 이 기기에서 이 ID를 쓰지 마세요. 같은 ID를 쓰는 기기가 둘이면 같은 메시지가 두 번 전송될 수 있습니다.';

  @override
  String get backupXBusy => '백업하는 동안 데이터가 계속 바뀌었습니다. 다시 시도하세요.';

  @override
  String get backupXTooLarge => '백업이 너무 큽니다. 녹음을 빼고 다시 시도하세요.';

  @override
  String get restoreXWrongPassphrase => '암호 문구가 틀렸거나 파일이 변경되었거나 불완전합니다.';

  @override
  String get restoreXUnsupported => '이 백업은 더 새로운 버전의 DitMesh로 만들어졌습니다.';

  @override
  String get restoreXCheck => '백업 열기';

  @override
  String get restoreXPreviewTitle => '백업 내용';

  @override
  String restoreXCreated(String date) {
    return '만든 시각 $date';
  }

  @override
  String get restoreXIncluded => '포함됨';

  @override
  String get restoreXExcluded => '이 백업에 없음';

  @override
  String restoreXPendingIncluded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '보내지 않은 메시지 $count개가 검토용으로 돌아옵니다. 자동으로 전송되지 않습니다.',
    );
    return '$_temp0';
  }

  @override
  String restoreXPendingExcluded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '이전 기기의 보내지 않은 메시지 $count개는 이 백업에 없습니다.',
    );
    return '$_temp0';
  }

  @override
  String get restoreXIdentityPassword => 'ID 비밀번호';

  @override
  String get restoreXIdentityPasswordNote => '이 백업의 ID에는 별도 비밀번호가 있습니다. 함께 입력하세요.';

  @override
  String get restoreXConfirmTitle => '이 기기의 ID를 바꿀까요?';

  @override
  String get restoreXConfirmBody => '이 기기의 ID와 데이터가 백업으로 바뀝니다. 여기서 연결하기 전에 이전 기기에서 이 ID 사용을 멈추세요.';

  @override
  String get restoreXConfirm => '바꾸고 복원';

  @override
  String get restoreXReportTitle => '복원 완료';

  @override
  String get restoreXReportRestored => '복원됨';

  @override
  String get restoreXReportNotIncluded => '복원되지 않음';

  @override
  String get restoreXReportPrefsFailed => '환경설정을 적용하지 못했습니다. 이전 설정이 유지됩니다.';

  @override
  String restoreXReportPendingReview(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '보내지 않은 메시지 $count개가 채팅에서 검토를 기다리고 있습니다.',
    );
    return '$_temp0';
  }

  @override
  String restoreXReportPendingNotResumed(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '이전 기기의 보내지 않은 메시지 $count개는 옮겨지지 않았습니다.',
    );
    return '$_temp0';
  }

  @override
  String restoreXReportInvites(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '대기 중이던 그룹 초대 $count건은 다시 보내지 않았습니다.',
    );
    return '$_temp0';
  }

  @override
  String get restoreXReportStopOld => '이전 기기에서는 이 ID를 더 이상 쓰지 마세요.';

  @override
  String get restoreXReportDone => '완료';

  @override
  String pendingReviewBanner(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '이전 기기의 보내지 않은 메시지 $count개',
    );
    return '$_temp0';
  }

  @override
  String get pendingReviewTitle => '보내지 않은 메시지';

  @override
  String get pendingReviewBody => '이전 기기에서 전송을 기다리던 메시지입니다. DitMesh는 자동으로 보내지 않습니다. 아직 필요하면 다시 키잉하세요.';

  @override
  String pendingReviewQueuedAt(String time) {
    return '이전 기기에서 $time에 대기열에 추가됨';
  }

  @override
  String get pendingReviewDismiss => '닫기';

  @override
  String get pendingReviewDismissAll => '모두 닫기';

  @override
  String get pendingReviewEmpty => '더 검토할 항목이 없습니다.';

  @override
  String get backupXWizardInside => '백업 파일은 직접 정한 암호 문구로 통째로 암호화되며 ID 키와 연습 진도를 담습니다. 파일과 암호 문구를 이 기기 밖의 안전한 곳에 보관하세요.';

  @override
  String get backupXMeSubtitle => 'ID, 채팅, 진도를 담은 암호화 파일. 보관하거나 다른 기기로 옮길 때 사용';

  @override
  String get conditionsTitle => '수신 환경';

  @override
  String get conditionsClear => '깨끗함';

  @override
  String get conditionsLight => '약한 간섭';

  @override
  String get conditionsRadio => '실전 무선';

  @override
  String get conditionsClearHint => '깨끗하고 일정한 톤: 일반 연습입니다.';

  @override
  String get conditionsLightHint => '잔잔한 배경 잡음과 약한 페이딩. 결과는 깨끗한 연습과 따로 기록됩니다.';

  @override
  String get conditionsRadioHint => '잡음, 깊은 페이딩, 가까운 다른 국, 약간 고르지 않은 타이밍. 결과는 깨끗한 연습과 따로 기록됩니다.';

  @override
  String get conditionsPreview => '미리 듣기';

  @override
  String conditionsActive(String name) {
    return '수신 환경: $name';
  }

  @override
  String get conditionsNeedSound => '무선 환경은 눈이 아니라 귀로 듣는 것입니다. 연습 설정에서 소리를 켜거나 깨끗한 환경으로 연습하세요.';

  @override
  String get conditionsCleanReplay => '효과 없이 재생';

  @override
  String conditionsComparable(int count, int accuracy) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '이 환경과 속도에서 $count회: 평균 $accuracy%',
    );
    return '$_temp0';
  }

  @override
  String get conditionsSeparateNote => '무선 환경 연습은 활동으로 기록되지만 레슨, 복습 일정, 속도 추천은 바뀌지 않습니다.';

  @override
  String get keysTitle => '키와 외부 키어';

  @override
  String get keysMeSubtitle => '키 할당, 패들, USB 키어 어댑터';

  @override
  String get keysIntro => '모스를 키잉할 키를 고르세요. 키보드처럼 동작하는 USB 키·패들 어댑터는 키보드와 같으니 여기서 키를 지정하세요. 앱은 어떤 기기가 키를 보냈는지 알 수 없으므로 프로필은 키 할당 묶음입니다.';

  @override
  String get keysStandardProfile => '기본';

  @override
  String get keysUnnamed => '이름 없는 프로필';

  @override
  String get keysEdit => '편집';

  @override
  String get keysNewProfile => '새 프로필';

  @override
  String get keysLimitations => 'MIDI·시리얼·블루투스 키어, 어댑터 펌웨어 설정, 송신기 제어는 지원하지 않습니다. 검증된 어댑터는 문서에 있습니다.';

  @override
  String get keysEditTitle => '키 프로필';

  @override
  String get keysName => '프로필 이름';

  @override
  String get keysActionStraight => '스트레이트 키';

  @override
  String get keysActionDit => '점 패들';

  @override
  String get keysActionDah => '선 패들';

  @override
  String get keysPressKey => '키를 누르세요…';

  @override
  String get keysNone => '설정 안 됨';

  @override
  String get keysSet => '지정';

  @override
  String keysReserved(String key) {
    return '$key은(는) 시스템이나 앱이 사용하는 키입니다. 다른 키를 고르세요.';
  }

  @override
  String keysConflict(String key, String action) {
    return '$key은(는) 이미 $action에 쓰이고 있습니다.';
  }

  @override
  String keysConflictSave(String keys) {
    return '키 하나에는 동작 하나만 지정할 수 있습니다: $keys이(가) 중복되었습니다.';
  }

  @override
  String get keysMissing => '이 키어 모드에 필요한 키를 지정하세요(아이앰빅은 두 패들 모두).';

  @override
  String get keysSwapPaddles => '패들 바꾸기(왼손잡이)';

  @override
  String get keysKeyerMode => '키어 모드';

  @override
  String get keysIambicA => '아이앰빅 A';

  @override
  String get keysIambicB => '아이앰빅 B';

  @override
  String get keysAdapterKeyer => '어댑터가 직접 부호를 만듦';

  @override
  String get keysAdapterKeyerHint => '자체 키어가 있는 어댑터용: 어댑터가 타이밍을 맞춘 눌림·뗌을 그대로 쓰며 앱에서 아이앰빅을 한 번 더 만들지 않습니다.';

  @override
  String get keysAppSidetone => '키잉할 때 앱 사이드톤';

  @override
  String get keysAppSidetoneHint => '어댑터가 자체 사이드톤을 낼 때 끄세요. 해독에는 영향이 없습니다.';

  @override
  String get keysTestTitle => '테스트';

  @override
  String get keysTestNote => '테스트 전용: 아무것도 전송하거나 연습 기록에 더하지 않습니다.';

  @override
  String get keysTestRelease => '키 놓기';

  @override
  String get keysAdapterActive => '어댑터의 키어를 사용 중: 패들 키는 스트레이트 키로 동작합니다.';

  @override
  String keysHintCustom(String keys) {
    return '키: $keys';
  }

  @override
  String get telegraphTitle => '중국어 전신 부호';

  @override
  String get telegraphIntro => '한자는 한 글자씩 네 자리 숫자로 보냅니다. 숫자를 듣는 연습과, 어떤 부호가 어떤 글자인지 기억하는 연습을 따로 합니다.';

  @override
  String get telegraphCodebook => '부호표';

  @override
  String get telegraphCodebookMainland => '중국 대륙';

  @override
  String get telegraphCodebookTaiwan => '대만';

  @override
  String get telegraphDigitsTitle => '부호 묶음 받아쓰기';

  @override
  String get telegraphDigitsHint => '실제 부호의 네 자리 묶음을 듣고 숫자를 입력합니다.';

  @override
  String telegraphDigitsResults(int count, int accuracy) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count회: 숫자 정확도 $accuracy%',
    );
    return '$_temp0';
  }

  @override
  String get telegraphRecallTitle => '부호 떠올리기';

  @override
  String get telegraphRecallHint => '글자→부호, 부호→글자. 모스 진도와 따로 기록합니다.';

  @override
  String telegraphRecallResults(int count, int accuracy) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count장 답함: $accuracy% 정답',
    );
    return '$_temp0';
  }

  @override
  String get telegraphSeparateNote => '부호 기억은 모스 레슨을 열거나 속도 추천을 바꾸지 않습니다. 숫자 받아쓰기는 다른 모스 수신과 똑같이 집계됩니다.';

  @override
  String get telegraphRecallCharPrompt => '이 글자의 부호를 입력하세요';

  @override
  String get telegraphRecallCodePrompt => '이 부호의 글자를 고르세요';

  @override
  String get telegraphReveal => '정답 보기';

  @override
  String get telegraphRevealAssisted => '표시함: 이 카드는 도움 받은 것으로 기록됩니다.';

  @override
  String get telegraphCorrect => '정답';

  @override
  String get telegraphIncorrect => '오답';

  @override
  String telegraphRecallSummary(int correct, int total) {
    return '$total개 중 $correct개 정답';
  }

  @override
  String telegraphRecallAssisted(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '정답을 본 카드 $count장',
    );
    return '$_temp0';
  }

  @override
  String get telegraphInterpretAction => '중국어 전신 부호로 해석';

  @override
  String get telegraphInterpretTitle => '전신 부호 해석';

  @override
  String get telegraphInterpretNote => '여기에만 표시됩니다. 메시지는 바뀌지 않고 아무것도 전송되지 않습니다.';

  @override
  String get telegraphUnresolved => '미해결: 이 부호에 해당하는 글자가 없습니다';

  @override
  String get telegraphMalformed => '네 자리 묶음이 아닙니다';

  @override
  String get telegraphNotCode => '텍스트(그대로 둠)';

  @override
  String get telegraphAmbiguous => '여러 글자가 이 부호를 함께 씁니다';

  @override
  String get groupPracticeTitle => '그룹 연습';

  @override
  String get groupPracticeIntro => '강사는 평소처럼 그룹 채팅에서 연습 문제를 키잉합니다. 각 멤버는 여기서 연습 메시지를 골라 자기 속도로 받아 적습니다. 답과 점수는 이 기기에만 남고 그룹에 아무것도 보내지 않습니다.';

  @override
  String get groupPracticeNew => '새 세션';

  @override
  String get groupPracticeTitleField => '제목';

  @override
  String get groupPracticeCreate => '만들기';

  @override
  String get groupPracticeInstructor => '강사';

  @override
  String get groupPracticeParticipant => '참가자';

  @override
  String get groupPracticeInstructorHint => '각 연습을 그룹 채팅에서 키잉하고 여기에 라운드로 추가해 체크하세요. 차례는 채팅에서 알리세요.';

  @override
  String get groupPracticeParticipantHint => '강사의 연습 메시지를 라운드로 추가하고 여기서 하나씩 받아 적으세요.';

  @override
  String get groupPracticeLocalNote => '이 기기에만 남습니다. 라운드·역할·결과는 다른 멤버와 동기화되지 않으며, 놓친 메시지가 모두에게 도착한다는 보장은 없습니다.';

  @override
  String get groupPracticeAddRound => '연습 추가';

  @override
  String get groupPracticeNoMessages => '최근 기록에 추가할 메시지가 없습니다.';

  @override
  String get groupPracticeNotConnected => '채팅이 연결될 때까지 그룹 기록을 쓸 수 없습니다.';

  @override
  String get groupPracticeRoundOpen => '할 일';

  @override
  String get groupPracticeRoundDone => '완료';

  @override
  String get groupPracticeRoundUnavailable => '사용 불가';

  @override
  String get groupPracticeSourceGone => '연습 메시지가 더 이상 기록에 없습니다.';

  @override
  String get groupPracticeSourceLoading => '메시지를 찾는 중…';

  @override
  String groupPracticeAttemptResult(int accuracy, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '받아쓰기: $accuracy% ($count회)',
    );
    return '$_temp0';
  }

  @override
  String get groupPracticeCopy => '받아쓰기';

  @override
  String get groupPracticeRemoveRound => '라운드 삭제';

  @override
  String get groupPracticeSummary => '요약';

  @override
  String groupPracticeRoundsDone(int done, int total) {
    return '$total라운드 중 $done 완료';
  }

  @override
  String groupPracticeUnavailableCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '사용할 수 없는 라운드 $count개',
    );
    return '$_temp0';
  }

  @override
  String groupPracticeAccuracy(int accuracy) {
    return '받아쓰기 정확도: $accuracy%';
  }

  @override
  String groupPracticeAssisted(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '도움 받은 시도 $count회',
    );
    return '$_temp0';
  }

  @override
  String groupPracticeShareHint(int done, int total, int accuracy) {
    return '공유하려면 결과를 직접 그룹 채팅에 키잉하세요(예: $done/$total $accuracy%). 자동으로 보내지지 않습니다.';
  }

  @override
  String get groupPracticeComplete => '세션 마치기';

  @override
  String get groupPracticeDeleteTitle => '이 세션을 삭제할까요?';

  @override
  String get groupPracticeDeleteBody => '라운드와 이 기기의 결과가 삭제됩니다. 연습 기록과 그룹 메시지는 남습니다.';

  @override
  String get conditionsAudioFailed => '이 기기에서 오디오를 시작하지 못했습니다. 깨끗한 환경으로 연습하세요.';

  @override
  String get moderationBlock => '차단';

  @override
  String moderationBlockTitle(String name) {
    return '$name님을 차단할까요?';
  }

  @override
  String get moderationBlockFriendBody => '친구에서 삭제되고 대화도 삭제됩니다. 이후 상대의 메시지, 친구 요청, 그룹 초대가 이 기기에 표시되지 않습니다. 상대에게는 알림이 가지 않습니다.';

  @override
  String get moderationBlockMemberBody => '이후 이 그룹에서 상대의 메시지가 이 기기에 표시되지 않습니다. 상대에게는 알림이 가지 않습니다. Tox는 그룹마다 회원에게 다른 키를 쓰므로 이 그룹에만 적용됩니다.';

  @override
  String get moderationBlocked => '차단했습니다';

  @override
  String get moderationUnblock => '차단 해제';

  @override
  String get moderationUnblocked => '차단을 해제했습니다';

  @override
  String get moderationBlockedTitle => '차단한 사용자';

  @override
  String get moderationBlockedSubtitle => '메시지, 요청, 초대를 숨김';

  @override
  String get moderationBlockedEmpty => '차단한 사용자가 없습니다.';

  @override
  String get moderationBlockedNote => '차단은 이 기기에서 적용됩니다. Tox에는 중앙 서버가 없어 상대가 연락을 시도할 수는 있지만, 그 내용은 여기에 표시되지 않습니다.';

  @override
  String get termsGateTitle => '커뮤니티 가이드라인';

  @override
  String get termsGateIntro => 'DitMesh 채팅은 서버 없이 다른 사람과 직접 연결됩니다. 시작하기 전에 다음 규칙에 동의해 주세요.';

  @override
  String get termsGateRuleZero => '무관용: 괴롭힘, 혐오, 협박, 미성년자 관련 성적 콘텐츠, 스팸 및 모든 불법 행위를 금지합니다.';

  @override
  String get termsGateRuleContacts => '내가 수락한 사람만 메시지를 보낼 수 있으며, 그룹은 초대나 그룹 ID로 참여합니다.';

  @override
  String get termsGateRuleBlock => '대화, 그룹 회원 목록, 친구 요청, 그룹 초대에서 누구든 차단할 수 있습니다.';

  @override
  String get termsGateAgree => '동의하고 계속';

  @override
  String get termsGateReadFull => '이용약관 전문 보기';

  @override
  String get termsGateSaveFailed => '답변을 저장하지 못했습니다. 다시 시도하세요.';

  @override
  String get aboutPrivacyPolicy => '개인정보 처리방침';

  @override
  String get aboutTermsOfUse => '이용약관';

  @override
  String get aboutSupport => '지원 및 문의';

  @override
  String get aboutLinkFailed => '링크를 열 수 없어 복사했습니다.';

  @override
  String get errorPeerBlocked => '이 사용자를 차단했습니다. 먼저 내 정보 → 차단한 사용자에서 차단을 해제하세요.';

  @override
  String get offlineClearData => '학습 데이터 지우기';

  @override
  String get offlineClearDataBody => '이 기기의 진도, 계획, 자료를 삭제합니다.';

  @override
  String get offlineCleared => '학습 데이터를 지웠습니다.';

  @override
  String get offlineClearFailed => '학습 데이터를 지우지 못했습니다.';

  @override
  String get learnStorageUnavailable => '이 기기에서 훈련 데이터를 열 수 없습니다. 다시 시도하세요.';

  @override
  String get backendStartupFailedTitle => '채팅 백엔드를 사용할 수 없습니다';

  @override
  String get backendStartupFailedBody => 'DitMesh가 Tox 네트워크 백엔드를 시작하지 못했습니다. 네이티브 라이브러리가 설치되어 있는지 확인한 후 다시 시도하세요.';

  @override
  String get bootstrapTitle => '네트워크 및 부트스트랩';

  @override
  String get bootstrapDescription => 'Tox 네트워크에 참여할 공개 노드를 선택합니다.';

  @override
  String get bootstrapModeAuto => '자동';

  @override
  String get bootstrapModeManual => '수동';

  @override
  String get bootstrapModeLan => 'LAN 호스트';

  @override
  String get bootstrapAutoDescription => '내장 노드로 시작하고 공식 목록을 백그라운드에서 갱신합니다.';

  @override
  String get bootstrapManualDescription => '선택한 노드만 사용합니다. LAN 노드도 입력할 수 있습니다.';

  @override
  String get bootstrapLanDescription => '이 데스크톱에서 다른 LAN 장치용 로컬 UDP/DHT 노드를 실행합니다.';

  @override
  String get bootstrapCurrentNode => '현재 노드';

  @override
  String get bootstrapHost => '호스트 또는 IP 주소';

  @override
  String get bootstrapPort => 'UDP 포트';

  @override
  String get bootstrapPublicKey => 'DHT 공개 키';

  @override
  String get bootstrapTestNode => '노드 테스트';

  @override
  String get bootstrapSaveNode => '테스트한 노드 사용';

  @override
  String get bootstrapChooseNode => '공개 노드 선택';

  @override
  String get bootstrapReachable => 'DHT 응답 수신';

  @override
  String get bootstrapUnreachable => 'DHT 응답 없음';

  @override
  String get bootstrapInvalid => '호스트, 포트 또는 공개 키가 올바르지 않습니다';

  @override
  String get bootstrapUdpUnavailable => '이 장치에서 UDP 검사를 실행할 수 없습니다. TCP 연결은 검사하지 않았습니다.';

  @override
  String get bootstrapProbeUnavailable => '검사를 시작할 수 없습니다. 노드 도달 여부는 알 수 없습니다.';

  @override
  String get bootstrapFallback => '공식 목록을 불러올 수 없어 내장 예비 노드를 표시합니다.';

  @override
  String get bootstrapMaintainer => '관리자';

  @override
  String get bootstrapLocation => '위치';

  @override
  String get bootstrapLastPing => '최근 공개 검사';

  @override
  String get bootstrapSwitchTitle => '부트스트랩 노드 변경';

  @override
  String get bootstrapSwitchQuestion => '이 노드를 사용하시겠습니까?';

  @override
  String get bootstrapNotTestedWarning => '이 장치에서 아직 테스트하지 않은 노드입니다.';

  @override
  String get bootstrapFailedWarning => 'UDP 검사에 응답하지 않았지만 이 노드를 선택할 수 있습니다.';

  @override
  String get bootstrapInconclusiveWarning => '검사 결과가 불확실합니다. TCP 연결은 검사하지 않았습니다.';

  @override
  String get bootstrapSwitchConfirm => '노드 사용';

  @override
  String get bootstrapRefresh => '목록 새로고침';

  @override
  String get bootstrapStartLan => 'LAN 노드 시작';

  @override
  String get bootstrapStopLan => 'LAN 노드 중지';

  @override
  String get bootstrapLanStopped => 'LAN 노드 중지됨';

  @override
  String get bootstrapLanRunning => 'LAN 노드 실행 중';

  @override
  String get bootstrapLanKeyChanges => '노드를 재시작하면 DHT 키가 바뀝니다. 현재 공개 키 전체를 공유하세요.';

  @override
  String get bootstrapLanFirewallHint => '다른 장치가 로컬 방화벽을 통해 이 UDP 포트에 접근할 수 있어야 합니다.';

  @override
  String get bootstrapCopyNode => '노드 정보 복사';

  @override
  String get bootstrapShareNode => '노드 정보 공유';

  @override
  String get bootstrapOperationFailed => '네트워크 설정을 적용하지 못했습니다.';

  @override
  String get bootstrapServiceUnavailable => '이 백엔드에서는 네트워크 설정을 사용할 수 없습니다.';

  @override
  String get bootstrapSource => '공식 공개 노드 목록';

  @override
  String get bootstrapOnline => '온라인';

  @override
  String get bootstrapOffline => '오프라인';

  @override
  String bootstrapProtocolStatus(String udp, String tcp) {
    return 'UDP: $udp · TCP: $tcp';
  }

  @override
  String get errorNotFriend => '이 사람은 더 이상 친구 목록에 없습니다. 메시지를 보내려면 다시 추가하세요.';

  @override
  String get chatAcceptWithPassword => '비밀번호로 수락';

  @override
  String chatGroupPasswordTitle(String name) {
    return '$name 비밀번호';
  }

  @override
  String get chatGroupPasswordField => '그룹 비밀번호';

  @override
  String chatGroupJoinRefusedPassword(String name) {
    return '$name 참여가 거부되었습니다. 비밀번호가 틀렸거나 없습니다.';
  }

  @override
  String chatGroupJoinRefusedFull(String name) {
    return '$name 참여가 거부되었습니다. 그룹이 가득 찼습니다.';
  }

  @override
  String chatGroupJoinRefused(String name) {
    return '$name 참여가 거부되었습니다.';
  }

  @override
  String chatGroupReconnectRefused(String name) {
    return '$name 재연결이 거부되었습니다. 기록은 유지됩니다. 그룹 비밀번호로 다시 시도하세요.';
  }
}
