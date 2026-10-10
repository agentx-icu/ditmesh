// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 's.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class SRu extends S {
  SRu([String locale = 'ru']) : super(locale);

  @override
  String get appName => 'DitMesh';

  @override
  String get navLearn => 'Обучение';

  @override
  String get navChat => 'Чаты';

  @override
  String get navGroups => 'Группы';

  @override
  String get navMe => 'Профиль';

  @override
  String get navReference => 'Справочник';

  @override
  String get navChatDescription => 'Личные беседы азбукой Морзе без сервера через Tox P2P.';

  @override
  String get navGroupsDescription => 'Групповые сети: несколько операторов передают в одном общем канале.';

  @override
  String get navReferenceDescription => 'Алфавит, служебные сигналы, Q-коды, сокращения и двусторонний переводчик.';

  @override
  String get navMeDescription => 'Ваш позывной, идентификатор Tox, прогресс и настройки.';

  @override
  String get shellOfflineBanner => 'Нет подключения к сети Tox. Сообщения будут отправлены после восстановления подключения.';

  @override
  String get actionOk => 'ОК';

  @override
  String get actionCancel => 'Отмена';

  @override
  String get actionSave => 'Сохранить';

  @override
  String get actionDelete => 'Удалить';

  @override
  String get actionCopy => 'Копировать';

  @override
  String get actionShare => 'Поделиться';

  @override
  String get actionRetry => 'Повторить';

  @override
  String get actionClose => 'Закрыть';

  @override
  String get actionSearch => 'Поиск';

  @override
  String get actionSettings => 'Настройки';

  @override
  String get connectionConnecting => 'Подключение…';

  @override
  String get connectionOnline => 'В сети';

  @override
  String get connectionOffline => 'Не в сети';

  @override
  String get messageStatusPending => 'В очереди на этом устройстве';

  @override
  String get messageStatusPendingDetail => 'Сообщение сохранено локально. Оно будет отправлено, когда обе программы работают и могут подключиться.';

  @override
  String get messageStatusSending => 'Отправка';

  @override
  String get messageStatusSent => 'Отправлено';

  @override
  String get messageStatusFailed => 'Не удалось отправить';

  @override
  String get errorWrongPassword => 'Неверный пароль. Попробуйте ещё раз.';

  @override
  String get errorPeerOffline => 'Этот контакт не в сети. У Tox нет сервера, поэтому сообщение ждёт, пока контакт снова подключится.';

  @override
  String get errorInvalidToxId => 'Недопустимый Tox ID (должно быть 76 шестнадцатеричных символов).';

  @override
  String get errorAlreadyFriend => 'Этот Tox ID уже есть в вашем списке друзей.';

  @override
  String get errorOwnId => 'Это ваш собственный Tox ID.';

  @override
  String get errorGroupNotFound => 'Группа не найдена.';

  @override
  String get errorMessageTooLong => 'Текст превышает предел длины одного сообщения Tox.';

  @override
  String get errorUnknown => 'Произошла ошибка';

  @override
  String get errorTeardownUnconfirmed => 'Предыдущий сеанс Tox ещё не полностью остановлен. Повторите попытку через минуту или перезапустите приложение.';

  @override
  String get errorIdentityRecoveryPending => 'Предыдущая личность всё ещё ожидает восстановления. Перезапустите приложение, чтобы повторить попытку, или удалите данные личности, чтобы начать заново.';

  @override
  String get languageTitle => 'Язык';

  @override
  String get languageSystemDefault => 'Как в системе';

  @override
  String get languageSaveFailed => 'Не удалось сохранить язык. Попробуйте ещё раз.';

  @override
  String learnLessonOf(int lesson, int total) {
    return 'Урок $lesson из $total';
  }

  @override
  String learnRoundScore(int correct, int total) {
    return 'Верно: $correct из $total';
  }

  @override
  String learnRoundOf(int round) {
    return 'Раунд $round';
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
      other: 'Передано $count символа',
      many: 'Передано $count символов',
      few: 'Передано $count символа',
      one: 'Передан $count символ',
    );
    return '$_temp0';
  }

  @override
  String learnLessonUnlocked(String char) {
    return 'Открыт новый символ: $char';
  }

  @override
  String learnConfusedMissed(String target) {
    return '$target пропущен';
  }

  @override
  String learnConfusedAs(String target, String answered) {
    return '$target принят как $answered';
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
      other: '$count символа',
      many: '$count символов',
      few: '$count символа',
      one: '$count символ',
    );
    return '$_temp0';
  }

  @override
  String statsDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count дня',
      many: '$count дней',
      few: '$count дня',
      one: '$count день',
    );
    return '$_temp0';
  }

  @override
  String statsTrendSubtitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Последние $count занятия',
      many: 'Последние $count занятий',
      few: 'Последние $count занятия',
      one: 'Последнее $count занятие',
    );
    return '$_temp0';
  }

  @override
  String referenceEntryCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count записи',
      many: '$count записей',
      few: '$count записи',
      one: '$count запись',
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
    return 'Пропущены (нет кода Морзе): $chars';
  }

  @override
  String referenceKochPositionValue(int position) {
    return 'Номер по методу Коха: $position';
  }

  @override
  String referenceEstimatedSpeed(String wpm) {
    return 'Примерно $wpm WPM';
  }

  @override
  String get accountCopied => 'Tox ID скопирован в буфер обмена';

  @override
  String get accountShowQr => 'Показать QR-код';

  @override
  String get accountToxId => 'Tox ID';

  @override
  String get accountDisplayName => 'Отображаемое имя';

  @override
  String get accountDisplayNameHint => 'Ваш позывной или псевдоним';

  @override
  String get accountDisplayNameRequired => 'Введите отображаемое имя';

  @override
  String get accountStatusMessage => 'Статус';

  @override
  String get accountPassword => 'Пароль';

  @override
  String get accountPasswordOptional => 'Пароль (необязательно)';

  @override
  String get accountConfirmPassword => 'Подтвердите пароль';

  @override
  String get accountPasswordsDoNotMatch => 'Пароли не совпадают';

  @override
  String get accountShowPassword => 'Показать пароль';

  @override
  String get accountHidePassword => 'Скрыть пароль';

  @override
  String get accountStrengthWeak => 'Слабый: используйте не менее 8 символов';

  @override
  String get accountStrengthFair => 'Средний: лучше использовать от 12 символов разных типов';

  @override
  String get accountStrengthStrong => 'Надёжный';

  @override
  String get accountStartupInspecting => 'Проверка ваших ключей…';

  @override
  String get accountStartupOpening => 'Загрузка ваших ключей…';

  @override
  String get accountStartupFailedTitle => 'Не удалось запустить';

  @override
  String get accountStartupFailedBody => 'DitMesh не удалось прочитать ваши ключи. Ничего не изменено; можно попробовать ещё раз.';

  @override
  String get accountConnectionTapToReconnect => 'Нажмите для повторного подключения';

  @override
  String get accountWelcomeTitle => 'Ваши ключи хранятся на этом устройстве';

  @override
  String get accountWelcomeIntro => 'DitMesh использует одноранговую сеть Tox. Здесь нет сервера и не нужно регистрироваться: ваша учётная запись — это пара ключей, которая хранится только на этом устройстве.';

  @override
  String get accountWelcomePointNoServer => 'Нет сервера, номера телефона или электронной почты. Операторы общаются напрямую азбукой Морзе.';

  @override
  String get accountWelcomePointTraining => 'Общайтесь лично или в группах азбукой Морзе с помощью обычного ключа или ямбического манипулятора.';

  @override
  String get accountWelcomePointBackup => 'Никто не сможет восстановить ваши ключи за вас. Создайте резервную копию сразу после создания учётной записи, иначе вы потеряете её вместе с устройством.';

  @override
  String get accountCreateIdentity => 'Создать учётную запись';

  @override
  String get accountRestoreFromBackup => 'Восстановить из резервной копии';

  @override
  String get accountCreateTitle => 'Создайте учётную запись';

  @override
  String get accountCreateBody => 'Выберите имя, которое будут видеть другие. Пароль шифрует файл ключей на этом устройстве; оставьте поле пустым, если хотите открывать приложение без пароля.';

  @override
  String get accountCreateButton => 'Создать';

  @override
  String get accountCreating => 'Создание…';

  @override
  String get accountBackupTitle => 'Создайте резервную копию сейчас';

  @override
  String get accountBackupBody => 'Ваши ключи существуют только на этом устройстве. При его потере, сбросе или краже восстановить их не получится: контакты не узнают новую учётную запись, а прогресс обучения будет потерян.';

  @override
  String get accountBackupWhatIsInside => 'Резервная копия содержит ключ личности, зашифрованный вашим паролем, и прогресс обучения. Храните её в безопасном месте вне этого устройства.';

  @override
  String get accountBackupWhatIsInsidePlain => 'Резервная копия содержит ключ личности без шифрования и прогресс обучения. Любой, кто получит этот файл, сможет пользоваться вашей личностью: чтобы ключ был зашифрован, сначала задайте пароль, и храните файл в безопасном месте.';

  @override
  String get accountPasswordScope => 'Пароль шифрует ключ вашей личности. История сообщений остаётся на диске незашифрованной; её может защитить шифрование устройства.';

  @override
  String get accountSectionNotifications => 'Уведомления';

  @override
  String get accountNotificationsEnable => 'Показывать уведомления';

  @override
  String get accountNotificationsEnableSubtitle => 'Новые сообщения, запросы в друзья и приглашения в группы';

  @override
  String get accountNotificationsContent => 'Показывать содержимое сообщений';

  @override
  String get accountNotificationsContentSubtitle => 'Текст и морзе в баннерах и на экране блокировки. Выключено: только сам факт сообщения.';

  @override
  String get accountNotificationsAllow => 'Разрешить уведомления';

  @override
  String get accountNotificationsAllowSubtitle => 'Запросить разрешение у системы';

  @override
  String get accountNotificationsBlocked => 'Заблокированы в настройках системы';

  @override
  String get accountNotificationsBlockedSubtitle => 'Уведомления о сообщениях DitMesh отключены в настройках системы. Включите их там снова.';

  @override
  String get accountNotificationsDenied => 'Уведомления DitMesh выключены в системных настройках.';

  @override
  String get accountBackupSaveFile => 'Сохранить резервную копию';

  @override
  String get accountBackupShareFile => 'Поделиться резервной копией';

  @override
  String get accountBackupSaved => 'Резервная копия сохранена';

  @override
  String get accountBackupNotSaved => 'Резервная копия не сохранена';

  @override
  String get accountBackupFailed => 'Не удалось записать резервную копию';

  @override
  String get accountBackupAcknowledge => 'Я понимаю, что без этой резервной копии моя учётная запись не может быть восстановлена.';

  @override
  String get accountBackupContinue => 'Перейти в DitMesh';

  @override
  String get accountBackupShowQrHint => 'Друзья добавляют вас по Tox ID. Поделитесь им в виде текста или QR-кода.';

  @override
  String get accountRestoreTitle => 'Восстановить из резервной копии';

  @override
  String get accountRestoreBody => 'Выберите резервную копию, экспортированную из DitMesh. Если ключи защищены паролем, здесь нужно будет его ввести.';

  @override
  String get accountRestoreChooseFile => 'Выбрать резервную копию';

  @override
  String get accountRestoreNoFile => 'Сначала выберите резервную копию';

  @override
  String get accountRestoreButton => 'Восстановить';

  @override
  String get accountRestoring => 'Восстановление…';

  @override
  String get accountRestoreInvalidFile => 'Этот файл не является резервной копией DitMesh.';

  @override
  String get accountRestoreReplacesWarning => 'Восстановление заменит текущую учётную запись на этом устройстве.';

  @override
  String get accountUnlockTitle => 'Разблокируйте учётную запись';

  @override
  String get accountUnlockBody => 'Файл ваших ключей зашифрован. Введите пароль, чтобы продолжить.';

  @override
  String get accountUnlockButton => 'Разблокировать';

  @override
  String get accountUnlocking => 'Разблокировка…';

  @override
  String get accountUnlockRestoreInstead => 'Восстановить из резервной копии';

  @override
  String get accountMeNoIdentity => 'Учётная запись не загружена';

  @override
  String get accountSectionAccount => 'Учётная запись';

  @override
  String get accountSectionTraining => 'Обучение';

  @override
  String get accountSectionAbout => 'О приложении';

  @override
  String get meNoteBackgroundTitle => 'Приём на телефоне';

  @override
  String get meNoteBackgroundBody => 'DitMesh работает напрямую между устройствами, без push-сервера, поэтому держите приложение открытым, чтобы получать сообщения. В фоне телефон быстро приостанавливает DitMesh: отправленные вам в это время сообщения у собеседника могут уже значиться отправленными и придут, когда вы снова откроете DitMesh.';

  @override
  String get meNoteScreenReaderTitle => 'Чтение с экрана и передача';

  @override
  String get meNoteScreenReaderBody => 'С программой чтения с экрана нельзя передавать вертикальным ключом, удерживая его нужное время. В чате используйте вместо этого действия ТОЧКА и ТИРЕ ключа, активируйте манипулятор по одному разу на элемент или передавайте с физической клавиатуры.';

  @override
  String get accountSectionDanger => 'Опасные действия';

  @override
  String get accountEditProfile => 'Редактировать профиль';

  @override
  String get accountEditProfileBody => 'Виден вашим контактам в сети Tox.';

  @override
  String get accountSetPassword => 'Установить пароль';

  @override
  String get accountChangePassword => 'Изменить пароль';

  @override
  String get accountRemovePassword => 'Удалить пароль';

  @override
  String get accountCurrentPassword => 'Текущий пароль';

  @override
  String get accountNewPassword => 'Новый пароль';

  @override
  String get accountPasswordUpdated => 'Пароль обновлён';

  @override
  String get accountPasswordRemoved => 'Пароль удалён';

  @override
  String get accountProfileUpdated => 'Профиль обновлён';

  @override
  String get accountExportBackup => 'Экспортировать резервную копию';

  @override
  String get accountExportBackupSubtitle => 'Сохраните ключи и прогресс обучения в файл';

  @override
  String get accountTrainingDefaults => 'Параметры воспроизведения и обучения';

  @override
  String get accountTrainingDefaultsSubtitle => 'Скорость, тон и интервалы Фарнсворта';

  @override
  String get accountTrainingDefaultsPlaceholder => 'Здесь будут параметры скорости, тона и интервалов Фарнсворта по умолчанию.';

  @override
  String get accountAboutLicence => 'Лицензия';

  @override
  String get accountAboutLicenceValue => 'GPL-3.0';

  @override
  String get accountAboutSource => 'Исходный код';

  @override
  String get accountAboutSourceCopied => 'Ссылка на исходный код скопирована';

  @override
  String get accountAboutBackend => 'Внутренний модуль';

  @override
  String get accountDeleteIdentity => 'Удалить учётную запись';

  @override
  String get accountDeleteIdentitySubtitle => 'Удалить ключи, историю и прогресс с этого устройства';

  @override
  String get accountDeleteDialogTitle => 'Удалить эту учётную запись?';

  @override
  String get accountDeleteDialogBody => 'С этого устройства будут удалены ваши ключи, история чатов и прогресс обучения. Без резервной копии восстановление невозможно. Введите DELETE для подтверждения.';

  @override
  String get accountDeleteConfirmWord => 'DELETE';

  @override
  String get accountDeleteConfirmHint => 'Введите DELETE';

  @override
  String get accountDeleteButton => 'Удалить';

  @override
  String get accountRecoveryPendingDiscard => 'Отбросить ожидающую личность и начать заново';

  @override
  String accountRestoreFileChosenSize(int bytes) {
    return 'Выбрана резервная копия ($bytes байт)';
  }

  @override
  String get chatSearchConversations => 'Поиск бесед';

  @override
  String get chatNoConversations => 'Пока нет бесед';

  @override
  String get chatNoSearchResults => 'Подходящих бесед нет';

  @override
  String get chatPin => 'Закрепить';

  @override
  String get chatUnpin => 'Открепить';

  @override
  String get chatMarkRead => 'Отметить прочитанным';

  @override
  String get chatDelete => 'Удалить';

  @override
  String get chatDeleteConversationTitle => 'Удалить беседу?';

  @override
  String get chatDeleteConversationBody => 'Локальная история этой беседы будет удалена. Tox не хранит копий.';

  @override
  String get chatDraftPrefix => 'Черновик: ';

  @override
  String get chatSelectConversation => 'Выберите беседу';

  @override
  String get chatContacts => 'Контакты';

  @override
  String get chatNoMessages => 'Сообщений пока нет: передайте CQ, чтобы начать.';

  @override
  String get chatTrainingMode => 'Режим обучения';

  @override
  String get chatTrainingModeOn => 'Режим обучения включён: текст скрыт';

  @override
  String get chatTrainingModeOff => 'Режим обучения выключен';

  @override
  String get chatAutoPlay => 'Автоматически воспроизводить принятую морзянку';

  @override
  String get chatAutoPlayOn => 'Автовоспроизведение включено: новые сообщения звучат по мере поступления';

  @override
  String get chatAutoPlayOff => 'Автовоспроизведение выключено';

  @override
  String get chatReveal => 'Показать';

  @override
  String get chatHiddenText => 'Сначала прослушайте, затем откройте текст';

  @override
  String get chatPlay => 'Прослушать Морзе';

  @override
  String get chatStop => 'Остановить';

  @override
  String get chatPlaybackSettings => 'Настройки воспроизведения';

  @override
  String get chatCharacterSpeed => 'Скорость символов';

  @override
  String get chatFarnsworthSpeed => 'Скорость Фарнсворта';

  @override
  String get chatTone => 'Тон';

  @override
  String get chatWpm => 'WPM';

  @override
  String get chatHz => 'Hz';

  @override
  String get chatMembers => 'Участники';

  @override
  String get chatLeaveGroup => 'Покинуть группу';

  @override
  String get chatLeaveGroupTitle => 'Покинуть эту группу?';

  @override
  String get chatLeaveGroupBody => 'Вы перестанете получать сообщения. Позже можно будет вернуться по ID чата.';

  @override
  String get chatLeave => 'Выйти';

  @override
  String get chatConferenceNote => 'Устаревшая конференция: здесь недоступны метаданные передачи Морзе (v2). Текстовые сообщения работают.';

  @override
  String get chatClearHistory => 'Очистить историю';

  @override
  String get chatModeStraightKey => 'Вертикальный ключ';

  @override
  String get chatModePaddles => 'Двухрычажный манипулятор';

  @override
  String get chatKeyMessage => 'Передайте сообщение ключом';

  @override
  String get chatSend => 'Отправить';

  @override
  String get chatTooLong => 'Превышен предел длины сообщения Tox';

  @override
  String get chatKeyHint => 'Нажимайте на область ключа или клавишу пробела';

  @override
  String get chatPaddleHint => 'Нажимайте на рычаги или удерживайте Ctrl (левый — точка, правый — тире)';

  @override
  String get chatDeleteLast => 'Удалить последний символ';

  @override
  String get chatNoFriends => 'Друзей пока нет. Добавьте друга по его Tox ID.';

  @override
  String get chatNoRequests => 'Нет ожидающих запросов';

  @override
  String get chatAddFriend => 'Добавить друга';

  @override
  String get chatMyToxId => 'Мой Tox ID';

  @override
  String get chatToxIdLabel => 'Tox ID (76 шестнадцатеричных символов)';

  @override
  String get chatToxIdInvalid => 'Tox ID должен содержать ровно 76 шестнадцатеричных символов';

  @override
  String get chatToxIdOwn => 'Это ваш собственный Tox ID';

  @override
  String get chatToxIdAlreadyFriend => 'Уже в списке друзей';

  @override
  String get chatRequestMessage => 'Сообщение';

  @override
  String get chatDefaultRequestMessage => 'DitMesh CQ';

  @override
  String get chatSendRequest => 'Отправить запрос';

  @override
  String get chatRequestSent => 'Запрос дружбы отправлен';

  @override
  String get chatScanQr => 'Сканировать QR';

  @override
  String get chatScanQrDesktopHint => 'Для сканирования QR нужна камера телефона';

  @override
  String get chatScanQrTitle => 'Сканировать Tox ID';

  @override
  String get chatScanQrNotToxId => 'Этот QR-код не содержит Tox ID';

  @override
  String get chatAccept => 'Принять';

  @override
  String get chatReject => 'Отклонить';

  @override
  String get chatCopied => 'Скопировано в буфер обмена';

  @override
  String get chatNoIdentity => 'Учётная запись не загружена';

  @override
  String get chatRemoveFriend => 'Удалить друга';

  @override
  String get chatRemoveFriendTitle => 'Удалить этого друга?';

  @override
  String get chatRemoveFriendBody => 'Этот контакт больше не сможет отправлять вам сообщения.';

  @override
  String get chatRemove => 'Удалить';

  @override
  String get chatNoGroups => 'Групп пока нет. Создайте группу или присоединитесь по ID чата.';

  @override
  String get chatCreateGroup => 'Создать группу';

  @override
  String get chatJoinGroup => 'Вступить в группу';

  @override
  String get chatGroupName => 'Название группы';

  @override
  String get chatGroupNameRequired => 'Введите название группы';

  @override
  String get chatAdvanced => 'Дополнительно';

  @override
  String get chatLegacyConference => 'Устаревшая конференция (для старых клиентов)';

  @override
  String get chatLegacyConferenceHint => 'Не рекомендуется: нет постоянного ID чата и метаданных Морзе.';

  @override
  String get chatCreate => 'Создать';

  @override
  String get chatChatIdLabel => 'ID чата (64 шестнадцатеричных символа)';

  @override
  String get chatChatIdInvalid => 'ID чата должен содержать ровно 64 шестнадцатеричных символа';

  @override
  String get chatPassword => 'Пароль (необязательно)';

  @override
  String get chatJoin => 'Вступить';

  @override
  String get chatJoinRequested => 'Подключение: группа появится после обнаружения участника.';

  @override
  String get chatConferenceBadge => 'Конференция';

  @override
  String get chatCopyChatId => 'Копировать ID чата';

  @override
  String get learnContinueLesson => 'Продолжить урок';

  @override
  String get learnSettings => 'Настройки обучения';

  @override
  String get learnLoading => 'Загрузка прогресса...';

  @override
  String get learnIdentityRequired => 'Создайте или разблокируйте учётную запись, чтобы начать обучение. Прогресс сохраняется вместе с ключами и входит в резервную копию.';

  @override
  String get learnProgressSaveFailed => 'Не удалось сохранить прогресс. Результат учитывается, пока DitMesh открыт.';

  @override
  String get toolsTitle => 'Радиоинструменты';

  @override
  String get toolsGridTitle => 'Локатор';

  @override
  String get toolsGridHint => 'Локатор по координатам, расстояние и направление антенны';

  @override
  String get toolsBandsTitle => 'Диапазоны и антенны';

  @override
  String get toolsBandsHint => 'Диапазон частоты, длина волны и длина диполя';

  @override
  String get toolsSpeedTitle => 'Скорость CW';

  @override
  String get toolsSpeedHint => 'Из WPM в длительность точки, паузы и символы в минуту';

  @override
  String get toolsRstTitle => 'Рапорт RST';

  @override
  String get toolsRstHint => 'Составьте рапорт о сигнале и узнайте значение каждой цифры';

  @override
  String get toolsClockTitle => 'Часы UTC';

  @override
  String get toolsClockHint => 'Время UTC для журнала рядом с местным временем';

  @override
  String get toolsGridFromCoordinates => 'По координатам';

  @override
  String get toolsGridLatitude => 'Широта';

  @override
  String get toolsGridLongitude => 'Долгота';

  @override
  String get toolsGridCoordinatesHelp => 'Градусы в десятичном виде; юг и запад — отрицательные значения';

  @override
  String get toolsGridInvalidCoordinates => 'Широта от -90 до 90, долгота от -180 до 180';

  @override
  String get toolsGridLocator => 'Локатор';

  @override
  String get toolsGridDistanceSection => 'Расстояние и азимут';

  @override
  String get toolsGridMine => 'Мой локатор';

  @override
  String get toolsGridTheirs => 'Локатор собеседника';

  @override
  String get toolsGridInvalidLocator => 'Используйте 2, 4, 6 или 8 символов, например OM89ex';

  @override
  String get toolsGridCenter => 'Центр квадрата';

  @override
  String get toolsGridDistance => 'Расстояние';

  @override
  String get toolsGridShortPath => 'Азимут короткого пути';

  @override
  String get toolsGridLongPath => 'Азимут длинного пути';

  @override
  String get toolsBandsFrequency => 'Частота (MHz)';

  @override
  String get toolsBandsInvalidFrequency => 'Введите частоту больше 0';

  @override
  String toolsBandsRegionLabel(int number) {
    return 'Регион $number';
  }

  @override
  String get toolsBandsRegionHelp => '1: Европа, Африка, Ближний Восток · 2: Америка · 3: Азиатско-Тихоокеанский регион';

  @override
  String toolsBandsInBand(String band) {
    return 'В радиолюбительском диапазоне $band';
  }

  @override
  String get toolsBandsOutOfBand => 'Вне радиолюбительских диапазонов';

  @override
  String get toolsBandsWavelength => 'Длина волны';

  @override
  String get toolsBandsDipole => 'Полуволновый диполь (целиком)';

  @override
  String get toolsBandsQuarterWave => 'Вертикальная антенна ¼ волны';

  @override
  String get toolsBandsAntennaNote => 'Длины учитывают коэффициент укорочения 0,95; подрежьте до резонанса.';

  @override
  String get toolsBandsTable => 'Границы диапазонов';

  @override
  String toolsBandsQrp(String frequency) {
    return 'QRP CW $frequency';
  }

  @override
  String get toolsBandsDisclaimer => 'Распределение ITU. Ваша лицензия и национальный частотный план могут задавать более узкие границы.';

  @override
  String get toolsSpeedCharacter => 'Скорость символов';

  @override
  String get toolsSpeedFarnsworth => 'Интервалы Фарнсворта';

  @override
  String get toolsSpeedOverall => 'Общая скорость';

  @override
  String get toolsSpeedDit => 'Точка';

  @override
  String get toolsSpeedDah => 'Тире';

  @override
  String get toolsSpeedCharGap => 'Пауза между символами';

  @override
  String get toolsSpeedWordGap => 'Пауза между словами';

  @override
  String get toolsSpeedCpm => 'Символов в минуту';

  @override
  String get toolsSpeedParis => 'Одно слово PARIS';

  @override
  String get toolsRstReadability => 'Разборчивость (R)';

  @override
  String get toolsRstStrength => 'Сила сигнала (S)';

  @override
  String get toolsRstTone => 'Тон (T)';

  @override
  String get toolsRstReport => 'Рапорт';

  @override
  String get toolsRstCut => 'Для соревнований';

  @override
  String get toolsRstPhone => 'Голосом (без тона)';

  @override
  String get toolsRstR1 => 'Неразборчиво';

  @override
  String get toolsRstR2 => 'Едва разборчиво, отдельные слова';

  @override
  String get toolsRstR3 => 'Разборчиво с большим трудом';

  @override
  String get toolsRstR4 => 'Разборчиво почти без труда';

  @override
  String get toolsRstR5 => 'Полностью разборчиво';

  @override
  String get toolsRstS1 => 'Едва заметный';

  @override
  String get toolsRstS2 => 'Очень слабый';

  @override
  String get toolsRstS3 => 'Слабый';

  @override
  String get toolsRstS4 => 'Умеренный';

  @override
  String get toolsRstS5 => 'Довольно хороший';

  @override
  String get toolsRstS6 => 'Хороший';

  @override
  String get toolsRstS7 => 'Довольно сильный';

  @override
  String get toolsRstS8 => 'Сильный';

  @override
  String get toolsRstS9 => 'Очень сильный';

  @override
  String get toolsRstT1 => 'Очень грубый и широкий, невыпрямленный AC';

  @override
  String get toolsRstT2 => 'Очень грубый тон AC, резкий и широкий';

  @override
  String get toolsRstT3 => 'Грубый, выпрямленный, без фильтрации';

  @override
  String get toolsRstT4 => 'Грубый, с признаками фильтрации';

  @override
  String get toolsRstT5 => 'Отфильтрованный, с сильной модуляцией пульсациями';

  @override
  String get toolsRstT6 => 'Отфильтрованный, с заметной пульсацией';

  @override
  String get toolsRstT7 => 'Почти чистый, со слабой пульсацией';

  @override
  String get toolsRstT8 => 'Почти идеальный, со слабой модуляцией';

  @override
  String get toolsRstT9 => 'Чистый тон, без пульсации';

  @override
  String get toolsClockUtc => 'UTC';

  @override
  String get toolsClockLocal => 'Местное время';

  @override
  String get toolsClockNote => 'В журналах связей и QSL-карточках используют UTC.';

  @override
  String get learnReceiveTitle => 'Приём';

  @override
  String get learnReviewTitle => 'Повторение';

  @override
  String get learnListen => 'Воспроизведение';

  @override
  String get learnReady => 'Готово';

  @override
  String get learnReplay => 'Прослушать снова';

  @override
  String get learnAnswerHint => 'Введите услышанное';

  @override
  String get learnSubmit => 'Проверить';

  @override
  String get learnNext => 'Далее';

  @override
  String get learnFinish => 'Завершить';

  @override
  String get learnDone => 'Готово';

  @override
  String get learnBackspace => 'Удалить';

  @override
  String get learnSpace => 'Пробел';

  @override
  String get learnSent => 'Передано';

  @override
  String get learnYourCopy => 'Ваш приём';

  @override
  String get learnRoundPerfect => 'Всё принято верно!';

  @override
  String get learnSessionSummary => 'Итоги занятия';

  @override
  String get learnLessonPassed => 'Урок пройден';

  @override
  String get learnLessonNotPassed => 'Продолжайте: точность 90% откроет следующий символ';

  @override
  String get learnReviewRecorded => 'Повторение записано';

  @override
  String get learnWeakChars => 'Нужно улучшить';

  @override
  String get learnConfusions => 'Путаете';

  @override
  String get learnNoFeedbackWarning => 'Звук, вспышки и вибрация отключены — вместо них будет мигать экран.';

  @override
  String get learnKeyerStraight => 'Вертикальный';

  @override
  String get learnKeyerIambicA => 'Ямбический A';

  @override
  String get learnKeyerIambicB => 'Ямбический B';

  @override
  String get learnStraightKeyLabel => 'КЛЮЧ';

  @override
  String get learnDitLabel => 'ТОЧКА';

  @override
  String get learnDahLabel => 'ТИРЕ';

  @override
  String get learnSettingsTitle => 'Настройки обучения';

  @override
  String get learnCharacterSpeed => 'Скорость символов';

  @override
  String get learnFarnsworth => 'Интервалы Фарнсворта';

  @override
  String get learnFarnsworthHelp => 'Символы передаются быстро, а интервалы между ними увеличиваются до этой скорости.';

  @override
  String get learnEffectiveSpeed => 'Эффективная скорость';

  @override
  String get learnTone => 'Тон';

  @override
  String get learnPlaySample => 'Прослушать пример';

  @override
  String get learnSessionLength => 'Символов за занятие';

  @override
  String get learnFeedback => 'Обратная связь';

  @override
  String get learnSound => 'Звук';

  @override
  String get learnFlash => 'Вспышка экрана';

  @override
  String get learnHaptic => 'Вибрация';

  @override
  String get learnKeyer => 'Тип ключа';

  @override
  String get learnDailyGoal => 'Дневная цель';

  @override
  String get referenceReferenceTitle => 'Справочник азбуки Морзе';

  @override
  String get referenceTranslatorTitle => 'Переводчик';

  @override
  String get referencePlay => 'Воспроизвести';

  @override
  String get referenceStop => 'Остановить';

  @override
  String get referenceClear => 'Очистить';

  @override
  String get referenceClose => 'Закрыть';

  @override
  String get referenceEmptyOutput => '—';

  @override
  String get referenceSearchHint => 'Поиск символов, служебных сигналов, Q-кодов…';

  @override
  String get referenceClearSearch => 'Очистить поиск';

  @override
  String get referenceNoResults => 'По вашему запросу ничего не найдено.';

  @override
  String get referenceSectionAlphabet => 'Алфавит';

  @override
  String get referenceSectionPunctuation => 'Знаки препинания';

  @override
  String get referenceSectionProsigns => 'Служебные сигналы';

  @override
  String get referenceSectionQCodes => 'Q-коды';

  @override
  String get referenceSectionAbbreviations => 'Сокращения CW';

  @override
  String get referenceSectionKoch => 'Порядок Коха';

  @override
  String get referenceAlphabetHint => 'Нажмите на карточку, чтобы прослушать. Удерживайте её, чтобы увидеть подсказку для запоминания.';

  @override
  String get referenceKochHint => 'Порядок введения символов по методу Коха (последовательность LCWO). Начните с K и M; добавляйте символ, когда точность приёма достигнет 90%.';

  @override
  String get referenceMnemonicTitle => 'Подсказка для запоминания';

  @override
  String get referenceMeaningLabel => 'Значение';

  @override
  String get referencePlaybackSettings => 'Настройки воспроизведения';

  @override
  String get referenceCharacterSpeed => 'Скорость символов';

  @override
  String get referenceFarnsworth => 'Интервалы Фарнсворта';

  @override
  String get referenceFarnsworthHelp => 'Символы передаются на полной скорости, а интервалы увеличиваются до эффективной скорости.';

  @override
  String get referenceEffectiveSpeed => 'Эффективная скорость';

  @override
  String get referenceTone => 'Тон';

  @override
  String get referenceModeTextToMorse => 'Текст → Морзе';

  @override
  String get referenceModeMorseToText => 'Морзе → Текст';

  @override
  String get referenceModeKey => 'Передача';

  @override
  String get referenceTextInputLabel => 'Текст';

  @override
  String get referenceTextInputHint => 'Введите текст для кодирования…';

  @override
  String get referencePatternOutputLabel => 'Морзе';

  @override
  String get referenceCopyPattern => 'Копировать код';

  @override
  String get referencePatternCopied => 'Код скопирован';

  @override
  String get referencePatternInputLabel => 'Морзе';

  @override
  String get referencePatternInputHint => 'Введите . и -, пробел между буквами и / между словами';

  @override
  String get referenceTextOutputLabel => 'Текст';

  @override
  String get referenceCopyText => 'Копировать текст';

  @override
  String get referenceTextCopied => 'Текст скопирован';

  @override
  String get referenceUnknownPatternHelp => 'Коды без соответствующего символа отображаются как <код>.';

  @override
  String get referenceKeypadDit => 'Точка';

  @override
  String get referenceKeypadDah => 'Тире';

  @override
  String get referenceKeypadCharGap => 'Интервал между буквами';

  @override
  String get referenceKeypadWordGap => 'Интервал между словами';

  @override
  String get referenceKeypadBackspace => 'Удалить символ';

  @override
  String get referenceKeyHint => 'Удерживайте ключ для передачи. На клавиатуре удерживайте пробел.';

  @override
  String get referenceKeyLabel => 'КЛЮЧ';

  @override
  String get referenceKeyDecodedLabel => 'Расшифровано';

  @override
  String get referenceKeyPendingLabel => 'Передача';

  @override
  String get listenTitle => 'Прослушивание';

  @override
  String get listenStart => 'Начать';

  @override
  String get listenStop => 'Остановить';

  @override
  String get listenStarting => 'Запуск микрофона...';

  @override
  String get listenClear => 'Очистить текст';

  @override
  String get listenCopy => 'Копировать текст';

  @override
  String get listenCopied => 'Расшифрованный текст скопирован';

  @override
  String get listenSettings => 'Настройки прослушивания';

  @override
  String get listenDecoded => 'Расшифровано';

  @override
  String get listenEmptyHint => 'Направьте микрофон на источник сигнала Морзе. Здесь появится расшифрованный текст.';

  @override
  String get listenIdleHint => 'Нажмите «Начать», чтобы принимать сигнал Морзе.';

  @override
  String get listenPending => 'Приём';

  @override
  String get listenSpeed => 'Скорость';

  @override
  String get listenSpeedUnknown => '-- WPM';

  @override
  String get listenLevel => 'Сигнал';

  @override
  String get listenToneOn => 'Есть тон';

  @override
  String get listenTone => 'Частота тона';

  @override
  String get listenToneLocked => 'Частота найдена';

  @override
  String get listenToneSearching => 'Поиск';

  @override
  String get listenToneManual => 'Вручную';

  @override
  String get listenAutoTune => 'Автонастройка';

  @override
  String get listenAutoTuneHelp => 'Следить за самым сильным тоном в диапазоне 400–1000 Hz. Для ручной настройки переместите ползунок.';

  @override
  String get listenRetune => 'Авто';

  @override
  String get listenBlockSize => 'Блок анализа';

  @override
  String get listenBlockSizeHelp => 'Меньшие блоки точнее определяют границы точек и тире, но сильнее реагируют на шум. 256 отсчётов (5,3 ms) подходят для 5–40 WPM.';

  @override
  String get listenMinElement => 'Минимальная длительность';

  @override
  String get listenMinElementHelp => 'Более короткие тоны и паузы считаются щелчками и провалами сигнала и игнорируются.';

  @override
  String get listenPermissionDenied => 'Доступ к микрофону запрещён. Разрешите его в настройках системы и попробуйте ещё раз.';

  @override
  String get listenPermissionRetry => 'Повторить';

  @override
  String get listenStartFailed => 'Не удалось запустить микрофон.';

  @override
  String get listenNoInput => 'Микрофон не найден. Подключите его и попробуйте ещё раз.';

  @override
  String get listenStreamFailed => 'Микрофон неожиданно отключился. Попробуйте ещё раз.';

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
    return '$samples отсчётов ($ms ms)';
  }

  @override
  String listenMsValue(int ms) {
    return '$ms ms';
  }

  @override
  String get listenStoppedInBackground => 'Прослушивание остановлено после перехода приложения в фоновый режим.';

  @override
  String get notificationOpen => 'Открыть';

  @override
  String get notificationChannelMessages => 'Сообщения';

  @override
  String get notificationChannelMessagesDescription => 'Новые сообщения Морзе от друзей и групп';

  @override
  String get notificationChannelFriendRequests => 'Запросы дружбы';

  @override
  String get notificationChannelFriendRequestsDescription => 'Кто-то хочет добавить вас в друзья';

  @override
  String get notificationChannelGroupInvites => 'Приглашения в группы';

  @override
  String get notificationChannelGroupInvitesDescription => 'Друг пригласил вас в группу';

  @override
  String get notificationNewMessage => 'Новое сообщение';

  @override
  String get notificationFriendRequestTitle => 'Новый запрос дружбы';

  @override
  String get accountNewPasswordRequired => 'Введите новый пароль';

  @override
  String get accountToxIdQrSemantics => 'QR-код Tox ID';

  @override
  String get accountBackupSaveDialogTitle => 'Сохранить резервную копию DitMesh';

  @override
  String get accountBackupShareSubject => 'Резервная копия учётной записи DitMesh';

  @override
  String get accountBackupChooseDialogTitle => 'Выбрать резервную копию DitMesh';

  @override
  String notificationNewMessages(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count нового сообщения',
      many: '$count новых сообщений',
      few: '$count новых сообщения',
      one: '$count новое сообщение',
    );
    return '$_temp0';
  }

  @override
  String notificationFriendRequestFrom(String name) {
    return 'Запрос дружбы от $name';
  }

  @override
  String notificationFriendRequestBody(String name, String message) {
    return '$name: $message';
  }

  @override
  String notificationGroupInviteTitle(String group) {
    return 'Приглашение в $group';
  }

  @override
  String notificationGroupInviteBody(String name) {
    return '$name приглашает вас';
  }

  @override
  String desktopTrayShow(String app) {
    return 'Показать $app';
  }

  @override
  String desktopTrayHide(String app) {
    return 'Скрыть $app';
  }

  @override
  String get desktopTraySoundOn => 'Звук включён';

  @override
  String get desktopTraySoundOff => 'Звук выключен';

  @override
  String desktopTrayQuit(String app) {
    return 'Закрыть $app';
  }

  @override
  String desktopTrayTooltipUnread(String app, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count непрочитанного сообщения',
      many: '$count непрочитанных сообщений',
      few: '$count непрочитанных сообщения',
      one: '$count непрочитанное сообщение',
    );
    return '$app — $_temp0';
  }

  @override
  String desktopWindowTitleUnread(String badge, String app) {
    return '($badge) $app';
  }

  @override
  String get listenStateOn => 'Вкл.';

  @override
  String get listenStateOff => 'Выкл.';

  @override
  String chatBytesLeftCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Осталось $count байта',
      many: 'Осталось $count байт',
      few: 'Осталось $count байта',
      one: 'Остался $count байт',
    );
    return '$_temp0';
  }

  @override
  String chatMemberCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count участника',
      many: '$count участников',
      few: '$count участника',
      one: '$count участник',
    );
    return '$_temp0';
  }

  @override
  String chatFriendsCount(int count) {
    return 'Друзья ($count)';
  }

  @override
  String chatFriendRequestsCount(int count) {
    return 'Запросы дружбы ($count)';
  }

  @override
  String chatGroupInvitesCount(int count) {
    return 'Приглашения в группы ($count)';
  }

  @override
  String chatMembersTitleCount(int count) {
    return 'Участники · $count';
  }

  @override
  String chatInvitedByName(String name) {
    return 'Приглашение от $name';
  }

  @override
  String chatMemberSelf(String name) {
    return '$name (вы)';
  }

  @override
  String chatSliderValue(String label, int value, String unit) {
    return '$label: $value $unit';
  }

  @override
  String referenceTelegraphCodes(String codes) {
    return 'Китайский телеграфный код: $codes';
  }

  @override
  String get referenceTelegraphMainland => 'Материковый Китай, 1983';

  @override
  String get referenceTelegraphTaiwan => 'Тайвань / Гонконг';

  @override
  String get referenceTelegraphNone => 'Нет в этом справочнике кодов';

  @override
  String get appearanceTitle => 'Внешний вид';

  @override
  String get appearanceStyles => 'Стиль интерфейса';

  @override
  String get appearanceChoose => 'Выберите стиль, просмотрите и примените';

  @override
  String get appearanceMode => 'Светлый или тёмный режим';

  @override
  String get appearancePreview => 'Предпросмотр';

  @override
  String get appearanceApply => 'Применить стиль';

  @override
  String get appearanceRestore => 'Восстановить настройки по умолчанию';

  @override
  String get appearanceApplied => 'Внешний вид сохранён';

  @override
  String get appearanceSaveFailed => 'Не удалось сохранить внешний вид. Попробуйте ещё раз.';

  @override
  String get appearanceClassic => 'Классическая латунь';

  @override
  String get appearanceModern => 'Современное спокойствие';

  @override
  String get appearanceRadio => 'Ночное радио';

  @override
  String get appearancePaper => 'Бумажный справочник';

  @override
  String get appearanceCartoon => 'Яркий мультфильм';

  @override
  String get appearanceLight => 'Светлый';

  @override
  String get appearanceDark => 'Тёмный';

  @override
  String get appearanceSubtitle => 'Пять стилей со светлым и тёмным режимами';

  @override
  String get chatClearHistoryBody => 'Удалить историю этой беседы на этом устройстве? Копии на других устройствах сохранятся. Это действие нельзя отменить.';

  @override
  String get chatLoadEarlier => 'Загрузить более ранние сообщения';

  @override
  String get chatHistoryLoadFailed => 'Не удалось загрузить более ранние сообщения. Нажмите для повторной попытки.';

  @override
  String get chatRetryHistory => 'Повторить';

  @override
  String chatNewMessages(int count) {
    return 'Новых сообщений: $count';
  }

  @override
  String get chatSelfMe => 'Я';

  @override
  String get chatSelfLocalOnly => 'Сохранено только на этом устройстве';

  @override
  String get chatSelfContactSubtitle => 'Черновики, практика и заметки · без отправки';

  @override
  String get learnLeaveDrillTitle => 'Выйти из занятия?';

  @override
  String get learnLeaveDrillBody => 'Пройденные в этом занятии раунды не сохранятся.';

  @override
  String get learnLeaveDrillConfirm => 'Выйти';

  @override
  String get chatScanQrPermissionDenied => 'DitMesh нужен доступ к камере для сканирования QR-кода. Разрешите его в настройках системы.';

  @override
  String get chatScanQrCameraUnavailable => 'Камера на этом устройстве недоступна.';

  @override
  String get learnReplayAssistedNote => 'Повтор: занятие засчитано как практика, но не открывает урок и не обновляет повторения.';

  @override
  String learnPlanNext(String step) {
    return 'Далее: $step';
  }

  @override
  String get messageStatusCancelled => 'Отменено — не отправлено';

  @override
  String get chatMessageLearnActions => 'Действия с сообщением';

  @override
  String get chatPracticeMessage => 'Потренироваться на этом сообщении';

  @override
  String get chatListenOnly => 'Тренировка только на слух';

  @override
  String get chatListenOnlyHidden => 'Только на слух: нажмите воспроизведение';

  @override
  String get chatPracticeTitle => 'Практика приёма';

  @override
  String chatPracticeUnsupported(String chars) {
    return 'В сообщении есть символы без кода Морзе: $chars. Они будут пропущены.';
  }

  @override
  String chatPracticeTrainableCount(int count) {
    return 'Можно потренировать знаков: $count.';
  }

  @override
  String get chatPracticeNothingTrainable => 'В этом сообщении нечего тренировать азбукой Морзе.';

  @override
  String get chatPracticeConfirm => 'Тренировать остальное';

  @override
  String get chatPracticeHint => 'Подсказка';

  @override
  String chatPracticeHintShown(String symbols) {
    return 'Подсказка: $symbols …';
  }

  @override
  String get chatPracticeAssisted => 'С подсказками: засчитывается как практика, но не для повторений и совета по скорости.';

  @override
  String chatPracticeErrors(int wrong, int missed, int extra) {
    return 'Ошибок $wrong · пропусков $missed · лишних $extra';
  }

  @override
  String chatPracticeErrorsAction(String symbols) {
    return 'Отработать ошибки: $symbols';
  }

  @override
  String get chatSearchMessages => 'Поиск сообщений';

  @override
  String get chatSearchHint => 'Искать в этом чате';

  @override
  String get chatSearchAnyone => 'Все';

  @override
  String get chatSearchMe => 'Я';

  @override
  String get chatSearchThem => 'Собеседник';

  @override
  String get chatSearchAnyDate => 'Любая дата';

  @override
  String chatSearchDateRange(String from, String to) {
    return '$from – $to';
  }

  @override
  String get chatSearchBookmarked => 'В закладках';

  @override
  String get chatSearchNoResults => 'Подходящих сообщений нет.';

  @override
  String get chatSearchMore => 'Загрузить ещё';

  @override
  String get chatAddBookmark => 'В закладки';

  @override
  String get chatRemoveBookmark => 'Убрать из закладок';

  @override
  String get chatBookmarked => 'В закладках';

  @override
  String get chatBookmarkFailed => 'Не удалось сохранить закладку.';

  @override
  String get chatRetrySend => 'Отправить снова';

  @override
  String get chatCancelSend => 'Отменить отправку';

  @override
  String get chatRetryQueued => 'Снова в очереди. Отправится, когда собеседник будет в сети.';

  @override
  String get chatSendCancelled => 'Отменено. Сообщение не отправлялось.';

  @override
  String get chatRetryNotNeeded => 'Это сообщение больше не в ошибке.';

  @override
  String get chatCancelTooLate => 'Слишком поздно: сообщение уже передано в сеть и может дойти.';

  @override
  String get chatSendControlUnavailable => 'Недоступно для этого сообщения.';

  @override
  String get chatSendControlFailed => 'Не получилось. Состояние сообщения не изменилось; повторите.';

  @override
  String get workbenchTitle => 'Работа с записями';

  @override
  String get workbenchOpen => 'Записи';

  @override
  String get workbenchImport => 'Импортировать запись';

  @override
  String get workbenchEmpty => 'Импортируйте запись WAV, чтобы прослушивать её по кругу, декодировать и принимать самостоятельно. Микрофон не нужен.';

  @override
  String get workbenchFormats => 'WAV, 16-битный PCM, моно или стерео, 8/16/44,1/48 кГц; до 50 МБ и 20 минут.';

  @override
  String get workbenchBackupNote => 'Записи хранятся на устройстве и попадают в резервную копию личности, только если вы включите их при экспорте. Названия, заметки и позиции сохранённых фрагментов сохраняются всегда.';

  @override
  String workbenchInfo(String rate, String channels, String duration) {
    return '$rate кГц · $channels · $duration';
  }

  @override
  String get workbenchMono => 'моно';

  @override
  String get workbenchStereo => 'стерео';

  @override
  String get workbenchTruncated => 'Файл обрывается; используется только имеющийся звук.';

  @override
  String get workbenchErrorNotWav => 'Это не файл WAV.';

  @override
  String get workbenchErrorFormat => 'Пока поддерживается только 16-битный PCM WAV (без MP3, AAC и WAV с плавающей точкой).';

  @override
  String get workbenchErrorChannels => 'Поддерживаются только моно- или стереозаписи.';

  @override
  String get workbenchErrorRate => 'Частота дискретизации не поддерживается. Используйте 8, 16, 44,1 или 48 кГц.';

  @override
  String get workbenchErrorDamaged => 'Файл повреждён или неполон.';

  @override
  String get workbenchErrorTooLarge => 'Файл больше 50 МБ.';

  @override
  String get workbenchErrorTooLong => 'Запись длиннее 20 минут.';

  @override
  String get workbenchErrorIo => 'Не удалось прочитать файл.';

  @override
  String get workbenchErrorMissing => 'Файл записи не найден.';

  @override
  String get workbenchStart => 'Начало (с)';

  @override
  String get workbenchEnd => 'Конец (с)';

  @override
  String get workbenchSelectAll => 'Выбрать всё';

  @override
  String get workbenchPlay => 'Воспроизвести фрагмент';

  @override
  String get workbenchStop => 'Стоп';

  @override
  String get workbenchLoop => 'Повтор';

  @override
  String get workbenchPlayLimit => 'У длинного фрагмента воспроизводятся только первые 5 минут.';

  @override
  String get workbenchAutoTune => 'Искать тон автоматически';

  @override
  String workbenchManualTone(int hz) {
    return 'Тон: $hz Гц';
  }

  @override
  String get workbenchDecode => 'Декодировать фрагмент';

  @override
  String get workbenchCancel => 'Отмена';

  @override
  String workbenchDecoding(int percent) {
    return 'Декодирование… $percent %';
  }

  @override
  String workbenchResultStats(int hz, int wpm) {
    return 'Тон $hz Гц · около $wpm WPM';
  }

  @override
  String get workbenchToneNotLocked => 'Устойчивый тон не найден; попробуйте ручную настройку.';

  @override
  String get workbenchNoText => 'В этом фрагменте ничего не декодировано.';

  @override
  String workbenchUnknown(String patterns) {
    return 'Неизвестные коды: $patterns';
  }

  @override
  String get workbenchEdgeCut => 'Знак на краю фрагмента обрезан и может быть неверен.';

  @override
  String get workbenchToneNote => 'Захват тона — не показатель достоверности; проверьте текст на слух.';

  @override
  String get workbenchModeDecoder => 'Декодер';

  @override
  String get workbenchModeCopy => 'Принять самому';

  @override
  String get workbenchDecoderHidden => 'Текст декодера скрыт, пока вы принимаете.';

  @override
  String get workbenchShowDecoder => 'Показать текст декодера';

  @override
  String get workbenchReference => 'Эталонный текст (необязательно)';

  @override
  String get workbenchReferenceHelp => 'Вставьте переданный текст; иначе ваш приём сравнивается с выводом декодера.';

  @override
  String get workbenchAgainstDecoder => 'Сравнено с выводом декодера, который сам может ошибаться.';

  @override
  String get workbenchSave => 'Сохранить фрагмент';

  @override
  String get workbenchSaveTitle => 'Название';

  @override
  String get workbenchSaveNote => 'Заметка';

  @override
  String get workbenchSaved => 'Фрагмент сохранён';

  @override
  String get workbenchSaveFailed => 'Не удалось сохранить фрагмент.';

  @override
  String get workbenchLibrary => 'Сохранённые фрагменты';

  @override
  String get workbenchLibraryEmpty => 'Сохранённых фрагментов пока нет.';

  @override
  String get workbenchMissing => 'Файл записи отсутствует — выберите его снова или удалите запись.';

  @override
  String get workbenchRelink => 'Выбрать файл снова';

  @override
  String get workbenchDelete => 'Удалить';

  @override
  String get guestTryLearning => 'Сначала попробовать учёбу';

  @override
  String get guestBanner => 'Гостевой режим: прогресс хранится на устройстве. Для чата нужна личность.';

  @override
  String get guestGetIdentity => 'Настроить личность';

  @override
  String get guestIdentityTitle => 'Нужна личность';

  @override
  String get guestIdentityBody => 'Для чата через Tox нужна своя личность. Создайте новую, восстановите резервную копию или разблокируйте имеющуюся. Гостевой прогресс автоматически перейдёт в новую личность.';

  @override
  String get guestClearData => 'Удалить гостевые данные';

  @override
  String get guestClearDataBody => 'Удаляет прогресс, планы и материалы гостевого режима на этом устройстве. Личности не затрагиваются.';

  @override
  String get guestClearConfirm => 'Удалить';

  @override
  String get guestCleared => 'Гостевые данные удалены.';

  @override
  String get guestClearFailed => 'Не удалось удалить гостевые данные.';

  @override
  String get guestMigrationFailed => 'Личность готова, но гостевой прогресс ещё не перенесён. Он сохранён на устройстве.';

  @override
  String get guestChoiceBody => 'Есть и гостевой прогресс. Используется прогресс восстановленной личности; ничего не объединялось.';

  @override
  String get guestChoiceKeep => 'Оставить восстановленный';

  @override
  String get guestChoiceUseGuest => 'Взять гостевой прогресс';

  @override
  String get chatJumpToLatest => 'Последние сообщения';

  @override
  String get chatMessageGone => 'Этого сообщения больше нет в чате.';

  @override
  String get chatListenOnlyPreview => 'Новое сообщение — примите его на слух';

  @override
  String get accountBackupMediaTitle => 'Включить сохранённые записи?';

  @override
  String accountBackupMediaBody(int count, String size) {
    return 'Сохранённых записей: $count ($size МБ). Названия, заметки и позиции всегда в копии; звук — только если вы его включите.';
  }

  @override
  String accountBackupMediaTooLarge(String size) {
    return 'Сохранённые записи ($size МБ) слишком велики для копии; сохраняются только названия, заметки и позиции.';
  }

  @override
  String get accountBackupMediaInclude => 'Включить записи';

  @override
  String get accountBackupMediaSkip => 'Без записей';

  @override
  String get diagTitle => 'Диагностика подключения';

  @override
  String get diagOpenSubtitle => 'Почему сообщения ждут отправки и как переподключиться';

  @override
  String get diagBannerDetails => 'Подробнее';

  @override
  String get diagSummaryNoIdentity => 'Личность не открыта, поэтому проверять нечего.';

  @override
  String get diagSummaryOnlinePeerOnline => 'Вы подключены к сети Tox, и этот контакт в сети. Сообщения доходят напрямую.';

  @override
  String get diagSummaryOnlinePeerOffline => 'Вы подключены, но этот контакт не в сети. Сообщения ждут в исходящих на этом устройстве и отправятся, когда контакт появится в сети.';

  @override
  String get diagSummaryOnline => 'Вы подключены к сети Tox.';

  @override
  String get diagSummaryConnecting => 'Подключение к сети Tox. После запуска или смены сети это может занять минуту.';

  @override
  String get diagSummaryOffline => 'Вы не подключены к сети Tox. Пока соединение не восстановится, ничего нельзя отправить или получить.';

  @override
  String get diagLocalLabel => 'Ваше подключение';

  @override
  String diagSinceChanged(String time) {
    return 'С $time';
  }

  @override
  String diagSinceFirst(String time) {
    return 'Наблюдается с $time';
  }

  @override
  String diagSinceResumed(String time) {
    return 'Наблюдается с возврата в приложение в $time';
  }

  @override
  String get diagLastOnlineLabel => 'Последнее замеченное подключение';

  @override
  String get diagLastOnlineNow => 'Подключено сейчас';

  @override
  String get diagLastOnlineNone => 'Подключение ещё не наблюдалось.';

  @override
  String get diagLastOnlineHint => 'Когда это устройство последний раз видело собственное подключение. Это не время доставки сообщения.';

  @override
  String get diagPeerLabel => 'Контакт';

  @override
  String get diagUnknown => 'Неизвестно';

  @override
  String get diagPeerUnknownHint => 'Присутствие контакта видно, только пока вы подключены.';

  @override
  String get diagPeerGroupHint => 'Присутствие участников группы показано в списке участников.';

  @override
  String get diagPendingLabel => 'Ожидают отправки';

  @override
  String get diagPendingNone => 'Ничего не ожидает';

  @override
  String diagPendingCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count сообщения',
      many: '$count сообщений',
      few: '$count сообщения',
      one: '$count сообщение',
    );
    return '$_temp0';
  }

  @override
  String diagPendingOldest(String time) {
    return 'Самое старое — с $time';
  }

  @override
  String get diagPendingUnknown => 'Неизвестно, пока чат не подключён';

  @override
  String get diagPendingHint => 'Сообщения в очереди хранятся на этом устройстве и отправятся сами, когда контакт станет доступен. Диагностика никогда их не удаляет и не отправляет повторно.';

  @override
  String get diagReconnect => 'Переподключиться';

  @override
  String get diagReconnecting => 'Переподключение…';

  @override
  String diagReconnectFailed(String reason) {
    return 'Не удалось переподключиться: $reason';
  }

  @override
  String get diagReconnectNote => 'Переподключение заново запускает попытку соединения. Выход в сеть всё равно может занять время; страница обновится, когда это произойдёт.';

  @override
  String get diagAboutTitle => 'Как подключается DitMesh';

  @override
  String get diagAboutBody => 'У DitMesh нет сервера. Устройство общается с контактами напрямую через одноранговую сеть Tox, поэтому для доставки сообщения вы оба должны быть в сети одновременно. Телефоны приостанавливают фоновые приложения: там DitMesh не может оставаться на связи и переподключается, когда вы возвращаетесь.';

  @override
  String get diagDetailsTitle => 'Технические подробности';

  @override
  String get diagDetailIdentity => 'Личность';

  @override
  String get diagDetailStatus => 'Статус';

  @override
  String get diagDetailObserved => 'Время наблюдения';

  @override
  String get diagDetailQueued => 'Записей в очереди';

  @override
  String get diagDetailError => 'Последний код ошибки';

  @override
  String get backupXTitle => 'Зашифрованная резервная копия';

  @override
  String get backupXIntro => 'Выберите, что перенести на другое устройство. Весь файл шифруется парольной фразой, которую вы зададите здесь.';

  @override
  String get backupXCategoryIdentity => 'Личность и профиль Tox';

  @override
  String get backupXCategoryTraining => 'Прогресс и материалы тренировок';

  @override
  String get backupXCategoryChat => 'История чатов, включая заметки для себя';

  @override
  String get backupXCategoryMeta => 'Черновики, закрепления и закладки';

  @override
  String get backupXCategoryPrefs => 'Настройки приложения';

  @override
  String get backupXPrefsHint => 'Воспроизведение, уведомления, оформление и язык. Без положения окон и назначений клавиш.';

  @override
  String get backupXCategoryMedia => 'Сохранённые записи';

  @override
  String get backupXMediaHint => 'По умолчанию выключено: записи могут быть большими. Без них переносятся только названия и заметки.';

  @override
  String get backupXCategoryPending => 'Неотправленные сообщения';

  @override
  String get backupXPendingHint => 'Они возвращаются только для просмотра и никогда не отправляются автоматически.';

  @override
  String get backupXRequired => 'Обязательно';

  @override
  String backupXSizeLine(int count, String size) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count элемента',
      many: '$count элементов',
      few: '$count элемента',
      one: '$count элемент',
    );
    return '$_temp0 · $size';
  }

  @override
  String backupXSizeKb(String size) {
    return '$size КБ';
  }

  @override
  String backupXSizeMb(String size) {
    return '$size МБ';
  }

  @override
  String backupXMediaTooLarge(String size) {
    return 'Слишком велико для включения ($size)';
  }

  @override
  String backupXInvitesNote(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count приглашения в группу не переносятся.',
      many: '$count приглашений в группу для друзей не в сети не переносятся.',
      few: '$count приглашения в группу для друзей не в сети не переносятся.',
      one: '$count приглашение в группу для друга не в сети не переносится.',
    );
    return '$_temp0';
  }

  @override
  String get backupXIdentityPasswordNote => 'Пароль личности остаётся на профиле: новое устройство спросит его вместе с парольной фразой копии.';

  @override
  String backupXTotal(String size) {
    return 'Всего около $size';
  }

  @override
  String get backupXPassphrase => 'Парольная фраза копии';

  @override
  String get backupXPassphraseConfirm => 'Повторите парольную фразу';

  @override
  String get backupXPassphraseHint => 'Не менее 8 символов. Она не связана с паролем личности и не восстанавливается.';

  @override
  String get backupXPassphraseTooShort => 'Используйте не менее 8 символов';

  @override
  String get backupXPassphraseMismatch => 'Парольные фразы не совпадают';

  @override
  String get backupXExport => 'Создать зашифрованную копию';

  @override
  String get backupXExporting => 'Создание копии…';

  @override
  String get backupXMigrationNote => 'Переезжаете на новое устройство? После восстановления там перестаньте пользоваться этой личностью здесь: два устройства с одной личностью могут отправить одно сообщение дважды.';

  @override
  String get backupXBusy => 'Данные менялись во время создания копии. Попробуйте ещё раз.';

  @override
  String get backupXTooLarge => 'Копия слишком велика. Исключите записи и попробуйте снова.';

  @override
  String get restoreXWrongPassphrase => 'Неверная парольная фраза, либо файл изменён или неполон.';

  @override
  String get restoreXUnsupported => 'Эта копия создана более новой версией DitMesh.';

  @override
  String get restoreXCheck => 'Открыть копию';

  @override
  String get restoreXPreviewTitle => 'Содержимое копии';

  @override
  String restoreXCreated(String date) {
    return 'Создана $date';
  }

  @override
  String get restoreXIncluded => 'Включено';

  @override
  String get restoreXExcluded => 'Нет в этой копии';

  @override
  String restoreXPendingIncluded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count неотправленного сообщения вернутся для просмотра.',
      many: '$count неотправленных сообщений вернутся для просмотра и не будут отправлены автоматически.',
      few: '$count неотправленных сообщения вернутся для просмотра и не будут отправлены автоматически.',
      one: '$count неотправленное сообщение вернётся для просмотра и не будет отправлено автоматически.',
    );
    return '$_temp0';
  }

  @override
  String restoreXPendingExcluded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count неотправленного сообщения не вошли в копию.',
      many: '$count неотправленных сообщений со старого устройства не вошли в копию.',
      few: '$count неотправленных сообщения со старого устройства не вошли в копию.',
      one: '$count неотправленное сообщение со старого устройства не вошло в копию.',
    );
    return '$_temp0';
  }

  @override
  String get restoreXIdentityPassword => 'Пароль личности';

  @override
  String get restoreXIdentityPasswordNote => 'У личности в этой копии свой пароль. Введите и его.';

  @override
  String get restoreXConfirmTitle => 'Заменить личность на этом устройстве?';

  @override
  String get restoreXConfirmBody => 'Личность и данные на этом устройстве будут заменены копией. Перестаньте пользоваться личностью на старом устройстве, прежде чем подключаться здесь.';

  @override
  String get restoreXConfirm => 'Заменить и восстановить';

  @override
  String get restoreXReportTitle => 'Восстановление завершено';

  @override
  String get restoreXReportRestored => 'Восстановлено';

  @override
  String get restoreXReportNotIncluded => 'Не восстановлено';

  @override
  String get restoreXReportPrefsFailed => 'Не удалось применить настройки; прежние сохранены.';

  @override
  String restoreXReportPendingReview(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count неотправленного сообщения ждут просмотра.',
      many: '$count неотправленных сообщений ждут просмотра в Чате.',
      few: '$count неотправленных сообщения ждут просмотра в Чате.',
      one: '$count неотправленное сообщение ждёт просмотра в Чате.',
    );
    return '$_temp0';
  }

  @override
  String restoreXReportPendingNotResumed(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count неотправленного сообщения не перенесены.',
      many: '$count неотправленных сообщений со старого устройства не перенесены.',
      few: '$count неотправленных сообщения со старого устройства не перенесены.',
      one: '$count неотправленное сообщение со старого устройства не перенесено.',
    );
    return '$_temp0';
  }

  @override
  String restoreXReportInvites(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count приглашения не отправлены повторно.',
      many: '$count приглашений в группу из очереди не отправлены повторно.',
      few: '$count приглашения в группу из очереди не отправлены повторно.',
      one: '$count приглашение в группу из очереди не отправлено повторно.',
    );
    return '$_temp0';
  }

  @override
  String get restoreXReportStopOld => 'Больше не используйте эту личность на старом устройстве.';

  @override
  String get restoreXReportDone => 'Готово';

  @override
  String pendingReviewBanner(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count неотправленного сообщения с прежнего устройства',
      many: '$count неотправленных сообщений с прежнего устройства',
      few: '$count неотправленных сообщения с прежнего устройства',
      one: '$count неотправленное сообщение с прежнего устройства',
    );
    return '$_temp0';
  }

  @override
  String get pendingReviewTitle => 'Неотправленные сообщения';

  @override
  String get pendingReviewBody => 'Эти сообщения ждали отправки на прежнем устройстве. DitMesh никогда не отправляет их сам; передайте ключом заново, если ещё нужно.';

  @override
  String pendingReviewQueuedAt(String time) {
    return 'В очереди с $time на прежнем устройстве';
  }

  @override
  String get pendingReviewDismiss => 'Убрать';

  @override
  String get pendingReviewDismissAll => 'Убрать все';

  @override
  String get pendingReviewEmpty => 'Больше нечего просматривать.';

  @override
  String get backupXWizardInside => 'Файл копии целиком шифруется выбранной вами парольной фразой и содержит ключ личности и прогресс тренировок. Храните файл и фразу в надёжном месте вне этого устройства.';

  @override
  String get backupXMeSubtitle => 'Зашифрованный файл с личностью, чатами и прогрессом — для хранения или переноса на другое устройство';

  @override
  String get conditionsClear => 'Чисто';

  @override
  String get conditionsLight => 'Лёгкие помехи';

  @override
  String get conditionsRadio => 'Эфирная практика';

  @override
  String get conditionsClearHint => 'Чистый ровный тон — обычная тренировка.';

  @override
  String get conditionsLightHint => 'Тихий шум и мягкие замирания. Результаты хранятся отдельно от чистой тренировки.';

  @override
  String get conditionsRadioHint => 'Шум, глубокие замирания, соседняя станция и немного неровный темп. Результаты хранятся отдельно от чистой тренировки.';

  @override
  String conditionsActive(String name) {
    return 'Условия: $name';
  }

  @override
  String get conditionsNeedSound => 'Эфирные условия слышны, а не видны: включите звук в настройках тренировки или занимайтесь в чистых условиях.';

  @override
  String get conditionsCleanReplay => 'Воспроизвести без эффектов';

  @override
  String conditionsComparable(int count, int accuracy) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count попытки: в среднем $accuracy%',
      many: '$count попыток в этих условиях на этой скорости: в среднем $accuracy%',
      few: '$count попытки в этих условиях на этой скорости: в среднем $accuracy%',
      one: '$count попытка в этих условиях на этой скорости: $accuracy%',
    );
    return '$_temp0';
  }

  @override
  String get conditionsSeparateNote => 'Тренировка в эфирных условиях засчитывается как активность, но не меняет уроки, график повторения и советы по скорости.';

  @override
  String get keysTitle => 'Клавиши и внешние ключи';

  @override
  String get keysMeSubtitle => 'Назначение клавиш, манипуляторы и USB-адаптеры';

  @override
  String get keysIntro => 'Выберите клавиши для передачи Морзе. USB-адаптеры ключа и манипулятора, эмулирующие клавиатуру, работают как она: задайте их клавиши здесь. Приложение не знает, какое устройство прислало клавишу, поэтому профиль — это набор назначений.';

  @override
  String get keysStandardProfile => 'Стандарт';

  @override
  String get keysUnnamed => 'Профиль без названия';

  @override
  String get keysEdit => 'Изменить';

  @override
  String get keysNewProfile => 'Новый профиль';

  @override
  String get keysLimitations => 'MIDI-, последовательные и Bluetooth-ключи, настройки прошивки адаптеров и управление передатчиком не поддерживаются. Проверенные адаптеры перечислены в документации.';

  @override
  String get keysEditTitle => 'Профиль клавиш';

  @override
  String get keysName => 'Название профиля';

  @override
  String get keysActionStraight => 'Прямой ключ';

  @override
  String get keysActionDit => 'Лопатка точки';

  @override
  String get keysActionDah => 'Лопатка тире';

  @override
  String get keysPressKey => 'Нажмите клавишу…';

  @override
  String get keysNone => 'Не задано';

  @override
  String get keysSet => 'Задать';

  @override
  String keysReserved(String key) {
    return '$key зарезервирована системой или приложением; выберите другую клавишу.';
  }

  @override
  String keysConflict(String key, String action) {
    return '$key уже используется для: $action.';
  }

  @override
  String keysConflictSave(String keys) {
    return 'Каждая клавиша может выполнять только одно действие: $keys назначена дважды.';
  }

  @override
  String get keysMissing => 'Задайте клавиши, нужные этому режиму (обе лопатки для ямбического).';

  @override
  String get keysSwapPaddles => 'Поменять лопатки (левша)';

  @override
  String get keysKeyerMode => 'Режим ключа';

  @override
  String get keysIambicA => 'Ямбический A';

  @override
  String get keysIambicB => 'Ямбический B';

  @override
  String get keysAdapterKeyer => 'Адаптер сам формирует элементы';

  @override
  String get keysAdapterKeyerHint => 'Для адаптера со своим ключом: его нажатия и отпускания используются как есть, без второго ямбического ключа в приложении.';

  @override
  String get keysAppSidetone => 'Самоконтроль приложения при передаче';

  @override
  String get keysAppSidetoneHint => 'Выключите, если адаптер сам даёт самоконтроль. На декодирование не влияет.';

  @override
  String get keysTestTitle => 'Проверка';

  @override
  String get keysTestNote => 'Только проверка: ничего не отправляется и не засчитывается в тренировку.';

  @override
  String get keysTestRelease => 'Отпустить клавиши';

  @override
  String get keysAdapterActive => 'Используется ключ адаптера: клавиши лопаток работают как прямой ключ.';

  @override
  String keysHintCustom(String keys) {
    return 'Клавиши: $keys';
  }

  @override
  String get telegraphCodebook => 'Кодовая книга';

  @override
  String get telegraphCodebookMainland => 'Материковый';

  @override
  String get telegraphCodebookTaiwan => 'Тайвань';

  @override
  String get telegraphInterpretAction => 'Расшифровать как китайский телеграфный код';

  @override
  String get telegraphInterpretTitle => 'Расшифровка телеграфного кода';

  @override
  String get telegraphInterpretNote => 'Только для просмотра: само сообщение не меняется, ничего не отправляется.';

  @override
  String get telegraphUnresolved => 'Не найдено: нет иероглифа с этим кодом';

  @override
  String get telegraphMalformed => 'Не четырёхзначная группа';

  @override
  String get telegraphNotCode => 'Текст, без изменений';

  @override
  String get telegraphAmbiguous => 'Этот код у нескольких иероглифов';

  @override
  String get groupPracticeTitle => 'Групповая тренировка';

  @override
  String get groupPracticeIntro => 'Ведущий, как обычно, передаёт упражнения в чат группы. Каждый участник выбирает здесь сообщение-упражнение и принимает его на своей скорости. Ответы и баллы остаются на вашем устройстве; в группу ничего не отправляется.';

  @override
  String get groupPracticeNew => 'Новое занятие';

  @override
  String get groupPracticeTitleField => 'Название';

  @override
  String get groupPracticeCreate => 'Создать';

  @override
  String get groupPracticeInstructor => 'Ведущий';

  @override
  String get groupPracticeParticipant => 'Участник';

  @override
  String get groupPracticeInstructorHint => 'Передайте упражнение в чат группы, добавьте его здесь как раунд и отметьте; очерёдность объявляйте в чате.';

  @override
  String get groupPracticeParticipantHint => 'Добавьте сообщения-упражнения ведущего как раунды и примите каждое здесь.';

  @override
  String get groupPracticeLocalNote => 'Только локально: раунды, роли и результаты не синхронизируются, а пропущенные сообщения могут дойти не до всех.';

  @override
  String get groupPracticeAddRound => 'Добавить упражнение';

  @override
  String get groupPracticeNoMessages => 'В недавней истории нет подходящих сообщений.';

  @override
  String get groupPracticeNotConnected => 'История группы недоступна, пока чат не подключён.';

  @override
  String get groupPracticeRoundOpen => 'Не выполнено';

  @override
  String get groupPracticeRoundDone => 'Выполнено';

  @override
  String get groupPracticeRoundUnavailable => 'Недоступно';

  @override
  String get groupPracticeSourceGone => 'Сообщения-упражнения больше нет в истории.';

  @override
  String get groupPracticeSourceLoading => 'Поиск сообщения…';

  @override
  String groupPracticeAttemptResult(int accuracy, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Принято: $accuracy% ($count попытки)',
      many: 'Принято: $accuracy% ($count попыток)',
      few: 'Принято: $accuracy% ($count попытки)',
      one: 'Принято: $accuracy%',
    );
    return '$_temp0';
  }

  @override
  String get groupPracticeCopy => 'Принять';

  @override
  String get groupPracticeRemoveRound => 'Удалить раунд';

  @override
  String get groupPracticeSummary => 'Итоги';

  @override
  String groupPracticeRoundsDone(int done, int total) {
    return 'Выполнено раундов: $done из $total';
  }

  @override
  String groupPracticeUnavailableCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count раунда недоступны',
      many: '$count раундов недоступны',
      few: '$count раунда недоступны',
      one: '$count раунд недоступен',
    );
    return '$_temp0';
  }

  @override
  String groupPracticeAccuracy(int accuracy) {
    return 'Точность приёма: $accuracy%';
  }

  @override
  String groupPracticeAssisted(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count попытки с подсказкой',
      many: '$count попыток с подсказкой',
      few: '$count попытки с подсказкой',
      one: '$count попытка с подсказкой',
    );
    return '$_temp0';
  }

  @override
  String groupPracticeShareHint(int done, int total, int accuracy) {
    return 'Чтобы поделиться, сами передайте результат в чат группы, например $done/$total $accuracy%. Автоматически ничего не отправляется.';
  }

  @override
  String get groupPracticeComplete => 'Завершить занятие';

  @override
  String get groupPracticeDeleteTitle => 'Удалить это занятие?';

  @override
  String get groupPracticeDeleteBody => 'Раунды и локальные результаты будут удалены с этого устройства. История тренировок и сообщения группы останутся.';

  @override
  String get conditionsAudioFailed => 'Не удалось запустить звук на этом устройстве. Занимайтесь в чистых условиях.';

  @override
  String get moderationBlock => 'Заблокировать';

  @override
  String moderationBlockTitle(String name) {
    return 'Заблокировать $name?';
  }

  @override
  String get moderationBlockFriendBody => 'Человек будет удалён из друзей, а переписка с ним — удалена. Его сообщения, запросы дружбы и приглашения в группы больше не появятся на этом устройстве. Он не получит уведомления.';

  @override
  String get moderationBlockMemberBody => 'Его сообщения в этой группе больше не появятся на этом устройстве. Он не получит уведомления. Tox выдаёт участнику отдельный ключ в каждой группе, поэтому блокировка действует только в этой группе.';

  @override
  String get moderationBlocked => 'Заблокировано';

  @override
  String get moderationUnblock => 'Разблокировать';

  @override
  String get moderationUnblocked => 'Разблокировано';

  @override
  String get moderationBlockedTitle => 'Заблокированные';

  @override
  String get moderationBlockedSubtitle => 'Их сообщения, запросы и приглашения скрыты';

  @override
  String get moderationBlockedEmpty => 'Вы никого не заблокировали.';

  @override
  String get moderationBlockedNote => 'Блокировка действует на этом устройстве: у Tox нет центрального сервера, поэтому заблокированные могут пытаться связаться с вами, но здесь ничего от них не показывается.';

  @override
  String get termsGateTitle => 'Правила сообщества';

  @override
  String get termsGateIntro => 'Чат DitMesh соединяет вас с людьми напрямую, без сервера. Прежде чем начать, примите эти правила:';

  @override
  String get termsGateRuleZero => 'Нулевая терпимость: никакой травли, ненависти, угроз, сексуального контента с участием несовершеннолетних, спама и ничего незаконного.';

  @override
  String get termsGateRuleContacts => 'Писать вам могут только те, кого вы приняли; в группы входят по приглашению или по ID группы.';

  @override
  String get termsGateRuleBlock => 'Блокируйте кого угодно из переписки, списка участников группы, запроса дружбы или приглашения.';

  @override
  String get termsGateAgree => 'Принять и продолжить';

  @override
  String get termsGateReadFull => 'Прочитать полные условия использования';

  @override
  String get termsGateSaveFailed => 'Не удалось сохранить ответ. Попробуйте ещё раз.';

  @override
  String get aboutPrivacyPolicy => 'Политика конфиденциальности';

  @override
  String get aboutTermsOfUse => 'Условия использования';

  @override
  String get aboutSupport => 'Поддержка и контакты';

  @override
  String get aboutLinkFailed => 'Не удалось открыть ссылку, она скопирована.';

  @override
  String get errorPeerBlocked => 'Вы заблокировали этого человека. Сначала разблокируйте его в разделе Профиль → Заблокированные.';

  @override
  String get offlineClearData => 'Удалить данные обучения';

  @override
  String get offlineClearDataBody => 'Удаляет прогресс, планы и материалы на этом устройстве.';

  @override
  String get offlineCleared => 'Данные обучения удалены.';

  @override
  String get offlineClearFailed => 'Не удалось удалить данные обучения.';

  @override
  String get learnStorageUnavailable => 'Не удалось открыть данные тренировок на этом устройстве. Попробуйте ещё раз.';

  @override
  String get backendStartupFailedTitle => 'Служба чата недоступна';

  @override
  String get backendStartupFailedBody => 'DitMesh не удалось запустить сетевую службу Tox. Проверьте, что нативные библиотеки установлены, и повторите попытку.';

  @override
  String get bootstrapTitle => 'Сеть и узлы начальной загрузки';

  @override
  String get bootstrapDescription => 'Выберите публичные узлы для подключения к сети Tox.';

  @override
  String get bootstrapModeAuto => 'Автоматически';

  @override
  String get bootstrapModeManual => 'Вручную';

  @override
  String get bootstrapModeLan => 'Узел LAN';

  @override
  String get bootstrapAutoDescription => 'Начать со встроенных узлов и обновлять официальный список в фоне.';

  @override
  String get bootstrapManualDescription => 'Использовать только выбранный узел. Здесь можно ввести узел локальной сети.';

  @override
  String get bootstrapLanDescription => 'Запустить локальный узел UDP/DHT на этом компьютере для других устройств LAN.';

  @override
  String get bootstrapCurrentNode => 'Текущий узел';

  @override
  String get bootstrapHost => 'Хост или IP-адрес';

  @override
  String get bootstrapPort => 'Порт UDP';

  @override
  String get bootstrapPublicKey => 'Открытый ключ DHT';

  @override
  String get bootstrapTestNode => 'Проверить узел';

  @override
  String get bootstrapSaveNode => 'Использовать проверенный узел';

  @override
  String get bootstrapChooseNode => 'Выбрать публичный узел';

  @override
  String get bootstrapReachable => 'Получен ответ DHT';

  @override
  String get bootstrapUnreachable => 'Нет ответа DHT';

  @override
  String get bootstrapInvalid => 'Недопустимый хост, порт или открытый ключ';

  @override
  String get bootstrapUdpUnavailable => 'Устройство не смогло выполнить проверку UDP. Соединение TCP не проверялось.';

  @override
  String get bootstrapProbeUnavailable => 'Не удалось запустить проверку. Доступность узла неизвестна.';

  @override
  String get bootstrapFallback => 'Не удалось загрузить официальный список. Показаны встроенные резервные узлы.';

  @override
  String get bootstrapMaintainer => 'Администратор';

  @override
  String get bootstrapLocation => 'Расположение';

  @override
  String get bootstrapLastPing => 'Последняя публичная проверка';

  @override
  String get bootstrapSwitchTitle => 'Сменить узел начальной загрузки';

  @override
  String get bootstrapSwitchQuestion => 'Использовать этот узел?';

  @override
  String get bootstrapNotTestedWarning => 'Этот узел ещё не проверялся на вашем устройстве.';

  @override
  String get bootstrapFailedWarning => 'Узел не ответил на проверку UDP. Вы всё равно можете выбрать его.';

  @override
  String get bootstrapInconclusiveWarning => 'Проверка не дала определённого результата. Соединение TCP не проверялось.';

  @override
  String get bootstrapSwitchConfirm => 'Использовать узел';

  @override
  String get bootstrapRefresh => 'Обновить список';

  @override
  String get bootstrapStartLan => 'Запустить узел LAN';

  @override
  String get bootstrapStopLan => 'Остановить узел LAN';

  @override
  String get bootstrapLanStopped => 'Узел LAN остановлен';

  @override
  String get bootstrapLanRunning => 'Узел LAN работает';

  @override
  String get bootstrapLanKeyChanges => 'Ключ DHT меняется при перезапуске. Поделитесь полным текущим ключом.';

  @override
  String get bootstrapLanFirewallHint => 'Другие устройства должны иметь доступ к этому порту UDP через локальный брандмауэр.';

  @override
  String get bootstrapCopyNode => 'Копировать данные узла';

  @override
  String get bootstrapShareNode => 'Поделиться данными узла';

  @override
  String get bootstrapOperationFailed => 'Не удалось применить настройку сети.';

  @override
  String get bootstrapServiceUnavailable => 'Настройки сети недоступны для этого движка.';

  @override
  String get bootstrapSource => 'Официальный список публичных узлов';

  @override
  String get bootstrapOnline => 'В сети';

  @override
  String get bootstrapOffline => 'Не в сети';

  @override
  String bootstrapProtocolStatus(String udp, String tcp) {
    return 'UDP: $udp · TCP: $tcp';
  }

  @override
  String get errorNotFriend => 'Этого человека больше нет в списке друзей. Добавьте его снова, чтобы отправлять сообщения.';

  @override
  String get chatAcceptWithPassword => 'Принять с паролем';

  @override
  String chatGroupPasswordTitle(String name) {
    return 'Пароль для $name';
  }

  @override
  String get chatGroupPasswordField => 'Пароль группы';

  @override
  String chatGroupJoinRefusedPassword(String name) {
    return '$name отклонила вступление: пароль неверный или не указан.';
  }

  @override
  String chatGroupJoinRefusedFull(String name) {
    return '$name отклонила вступление: группа заполнена.';
  }

  @override
  String chatGroupJoinRefused(String name) {
    return '$name отклонила вступление.';
  }

  @override
  String chatGroupReconnectRefused(String name) {
    return '$name отклонила повторное подключение. История сохранена; повторите попытку с паролем группы.';
  }

  @override
  String get firstChatTitle => 'Ваш первый чат Морзе';

  @override
  String get firstChatStart => 'Начать';

  @override
  String get firstChatDismiss => 'Закрыть подсказку';

  @override
  String get firstChatKeyTitle => '1. Передайте себе CQ';

  @override
  String get firstChatKeyBody => 'Передайте CQ ключом: короткое нажатие — точка, длинное — тире. Расшифрованный черновик доступен только для чтения.';

  @override
  String get firstChatSelf => 'Попробовать в чате с собой';

  @override
  String get firstChatListenTitle => '2. Прослушайте и исправьте';

  @override
  String get firstChatListenBody => 'Перед отправкой прослушайте черновик и удалите ошибки. Затем нажмите воспроизведение у сообщения. Сообщения себе остаются на этом устройстве.';

  @override
  String get firstChatFriendTitle => '3. Общайтесь с другом';

  @override
  String get firstChatFriendBody => 'Откройте Контакты, добавьте друга по QR или Tox ID и дождитесь принятия запроса.';

  @override
  String get firstChatFriend => 'Добавить друга';

  @override
  String get firstChatOnline => 'Для доставки обе программы должны работать и быть подключены.';

  @override
  String get pendingMessagesTitle => 'Ожидающие сообщения и ошибки';

  @override
  String get pendingMessagesExplanation => 'Сообщения остаются на устройстве до подключения обеих программ. Можно отменить отправку или повторить её после подтверждённой ошибки.';

  @override
  String get pendingMessagesEmpty => 'Нет ожидающих сообщений или ошибок';

  @override
  String get deliveryDetailsTitle => 'Сведения о доставке';

  @override
  String get deliveryLocalTitle => 'Сохранено локально';

  @override
  String get deliveryLocalDetail => 'Это сообщение себе сохранено на данном устройстве.';

  @override
  String get deliverySentDetail => 'Программа передала сообщение транспорту и ждёт подтверждения получения.';

  @override
  String get deliveryPeerTitle => 'Получение подтверждено';

  @override
  String get deliveryPeerDetail => 'Получатель подтвердил получение. Это не подтверждает чтение или прослушивание.';

  @override
  String get deliveryGroupTitle => 'Получено участником группы';

  @override
  String get deliveryGroupDetail => 'Как минимум один участник подтвердил получение. Остальные могут быть не в сети.';

  @override
  String get deliveryLocalOffline => 'Это устройство ещё не подключено.';

  @override
  String get deliveryPeerOffline => 'Друг не в сети.';

  @override
  String get deliveryGroupWaiting => 'Ожидание подключения к группе.';

  @override
  String get chatPreviewDraft => 'Прослушать черновик';

  @override
  String get chatStopPreview => 'Остановить прослушивание';

  @override
  String get chatMessagePlayback => 'Воспроизведение сообщения';

  @override
  String get chatOriginalRhythm => 'Исходный ритм передачи';

  @override
  String get chatListenerRhythm => 'Ваша скорость прослушивания';

  @override
  String get chatOriginalAvailable => 'Реальные нажатия и паузы сохранены.';

  @override
  String get chatOriginalUnavailable => 'Исходный ритм недоступен; используется ваша скорость.';

  @override
  String get chatOriginalPlaying => 'Воспроизводится исходный ритм';

  @override
  String get chatListenerPlaying => 'Воспроизведение с вашей скоростью';

  @override
  String get chatPause => 'Пауза';

  @override
  String get chatResume => 'Продолжить';

  @override
  String get chatPreviousWord => 'Предыдущее слово';

  @override
  String get chatNextWord => 'Следующее слово';

  @override
  String chatWordNumber(int number) {
    return 'Слово $number';
  }

  @override
  String get chatRangeStart => 'Первое слово';

  @override
  String get chatRangeEnd => 'Последнее слово';

  @override
  String get chatRepeatRange => 'Повторить выбранные слова';

  @override
  String get chatLoopRange => 'Повторять выбранные слова циклически';

  @override
  String get chatPlaybackProgress => 'Ход воспроизведения';

  @override
  String chatWordProgress(int current, int total) {
    return 'Слово $current из $total';
  }

  @override
  String get chatOriginalPreference => 'Использовать исходный ритм, если доступна соответствующая запись.';

  @override
  String chatConversationActions(String name) {
    return 'Действия для $name';
  }

  @override
  String get chatDraftSaveFailed => 'Не удалось сохранить черновик. Не закрывайте этот экран или отправьте сообщение сейчас.';

  @override
  String get chatSearchClearDates => 'Сбросить период';

  @override
  String chatGroupReconnectFailed(String name) {
    return '$name отклонила повторное подключение. История сохранена; можно повторить попытку.';
  }
}
