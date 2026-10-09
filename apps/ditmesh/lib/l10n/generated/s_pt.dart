// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 's.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class SPt extends S {
  SPt([String locale = 'pt']) : super(locale);

  @override
  String get appName => 'DitMesh';

  @override
  String get navLearn => 'Aprender';

  @override
  String get navChat => 'Conversas';

  @override
  String get navGroups => 'Grupos';

  @override
  String get navMe => 'Eu';

  @override
  String get navReference => 'Referência';

  @override
  String get navLearnDescription => 'Lições do método Koch, exercícios de transmissão e prática de recepção.';

  @override
  String get navChatDescription => 'Conversas individuais em Morse, sem servidor, pela rede Tox P2P.';

  @override
  String get navGroupsDescription => 'Redes de grupo: vários operadores transmitem em um canal compartilhado.';

  @override
  String get navReferenceDescription => 'Alfabeto, sinais de procedimento, códigos Q, abreviaturas e um tradutor bidirecional.';

  @override
  String get navMeDescription => 'Seu indicativo, identidade Tox, progresso e configurações.';

  @override
  String get shellOfflineBanner => 'Sem conexão com a rede Tox. As mensagens serão enviadas quando você se conectar novamente.';

  @override
  String get actionOk => 'OK';

  @override
  String get actionCancel => 'Cancelar';

  @override
  String get actionSave => 'Salvar';

  @override
  String get actionDelete => 'Excluir';

  @override
  String get actionCopy => 'Copiar';

  @override
  String get actionShare => 'Compartilhar';

  @override
  String get actionRetry => 'Tentar novamente';

  @override
  String get actionClose => 'Fechar';

  @override
  String get actionSearch => 'Buscar';

  @override
  String get actionSettings => 'Configurações';

  @override
  String get connectionConnecting => 'Conectando…';

  @override
  String get connectionOnline => 'Online';

  @override
  String get connectionOffline => 'Offline';

  @override
  String get messageStatusPending => 'Na fila neste dispositivo';

  @override
  String get messageStatusPendingDetail => 'A mensagem está salva localmente. Será enviada quando ambos os aplicativos estiverem abertos e puderem se conectar.';

  @override
  String get messageStatusSending => 'Enviando';

  @override
  String get messageStatusSent => 'Enviada';

  @override
  String get messageStatusFailed => 'Falha ao enviar';

  @override
  String get errorWrongPassword => 'Senha incorreta. Tente novamente.';

  @override
  String get errorPeerOffline => 'Este contato está offline. O Tox não tem servidor, então a mensagem aguarda até ele se conectar novamente.';

  @override
  String get errorInvalidToxId => 'Este Tox ID não é válido (deve ter 76 caracteres hexadecimais).';

  @override
  String get errorAlreadyFriend => 'Este Tox ID já está na sua lista de amigos.';

  @override
  String get errorOwnId => 'Este é o seu próprio Tox ID.';

  @override
  String get errorGroupNotFound => 'Grupo não encontrado.';

  @override
  String get errorMessageTooLong => 'O texto ultrapassa o limite de uma mensagem do Tox.';

  @override
  String get errorUnknown => 'Ocorreu um erro';

  @override
  String get errorTeardownUnconfirmed => 'A sessão Tox anterior ainda não parou completamente. Tente novamente daqui a pouco ou reinicie a aplicação.';

  @override
  String get errorIdentityRecoveryPending => 'Uma identidade anterior ainda aguarda recuperação. Reinicie a aplicação para tentar de novo ou elimine os dados da identidade para recomeçar.';

  @override
  String get languageTitle => 'Idioma';

  @override
  String get languageSystemDefault => 'Padrão do sistema';

  @override
  String get languageSaveFailed => 'Não foi possível salvar o idioma. Tente novamente.';

  @override
  String learnLessonOf(int lesson, int total) {
    return 'Lição $lesson de $total';
  }

  @override
  String learnCharsLearned(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count caracteres aprendidos',
      one: '$count caractere aprendido',
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
      other: '$days dias seguidos',
      one: '$days dia seguido',
    );
    return '$_temp0';
  }

  @override
  String learnReviewDueCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pendentes',
      one: '$count pendente',
      zero: 'Nada pendente',
    );
    return '$_temp0';
  }

  @override
  String learnRoundScore(int correct, int total) {
    return '$correct de $total corretos';
  }

  @override
  String learnRoundOf(int round) {
    return 'Rodada $round';
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
      one: '$count caractere transmitido',
    );
    return '$_temp0';
  }

  @override
  String learnLessonUnlocked(String char) {
    return 'Novo caractere desbloqueado: $char';
  }

  @override
  String learnConfusedMissed(String target) {
    return '$target não recebido';
  }

  @override
  String learnConfusedAs(String target, String answered) {
    return '$target ouvido como $answered';
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
      one: '$count caractere',
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
      one: '$count caractere aprendido',
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
      other: '$count caracteres recebidos',
      one: '$count caractere recebido',
    );
    return '$_temp0';
  }

  @override
  String statsSessions(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sessões',
      one: '$count sessão',
    );
    return '$_temp0';
  }

  @override
  String statsDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dias',
      one: '$count dia',
    );
    return '$_temp0';
  }

  @override
  String statsBestStreak(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Recorde: $count dias',
      one: 'Recorde: $count dia',
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
      other: 'Faltam $remaining caracteres',
      one: 'Falta $remaining caractere',
    );
    return '$_temp0';
  }

  @override
  String statsTrendSubtitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Últimas $count sessões',
      one: 'Última sessão',
      zero: 'Nenhuma sessão',
    );
    return '$_temp0';
  }

  @override
  String statsTooltipSession(int index, int total) {
    return 'Sessão $index de $total';
  }

  @override
  String statsTooltipCopied(int correct, int total) {
    return '$correct / $total corretos';
  }

  @override
  String statsTooltipLesson(int lesson) {
    return 'Lição $lesson';
  }

  @override
  String statsAttempts(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tentativas',
      one: '$count tentativa',
    );
    return '$_temp0';
  }

  @override
  String statsCorrectOf(int correct, int attempts) {
    return '$correct de $attempts corretos';
  }

  @override
  String statsLessonIntroduced(int lesson) {
    return 'Introduzido na lição $lesson';
  }

  @override
  String statsSrsBox(int box, int maxBox) {
    return 'Caixa $box de $maxBox';
  }

  @override
  String statsSrsDueIn(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Revisar em $days dias',
      one: 'Revisar em $days dia',
    );
    return '$_temp0';
  }

  @override
  String statsTimes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count vezes',
      one: '$count vez',
    );
    return '$_temp0';
  }

  @override
  String statsHeatmapCell(String target, String answered, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count vezes',
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
      one: '$chars caractere',
      zero: 'sem prática',
    );
    return '$date: $_temp0';
  }

  @override
  String statsActiveDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dias ativos',
      one: '$count dia ativo',
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
    return 'Ignorados (sem código Morse): $chars';
  }

  @override
  String referenceKochPositionValue(int position) {
    return 'Posição Koch: $position';
  }

  @override
  String referenceEstimatedSpeed(String wpm) {
    return 'Aproximadamente $wpm WPM';
  }

  @override
  String get accountCopied => 'Tox ID copiado para a área de transferência';

  @override
  String get accountShowQr => 'Mostrar código QR';

  @override
  String get accountToxId => 'Tox ID';

  @override
  String get accountDisplayName => 'Nome de exibição';

  @override
  String get accountDisplayNameHint => 'Seu indicativo ou apelido';

  @override
  String get accountDisplayNameRequired => 'Digite um nome de exibição';

  @override
  String get accountStatusMessage => 'Mensagem de status';

  @override
  String get accountPassword => 'Senha';

  @override
  String get accountPasswordOptional => 'Senha (opcional)';

  @override
  String get accountConfirmPassword => 'Confirmar senha';

  @override
  String get accountPasswordsDoNotMatch => 'As senhas não coincidem';

  @override
  String get accountShowPassword => 'Mostrar senha';

  @override
  String get accountHidePassword => 'Ocultar senha';

  @override
  String get accountStrengthWeak => 'Fraca: use pelo menos 8 caracteres';

  @override
  String get accountStrengthFair => 'Razoável: prefira 12 ou mais caracteres de tipos variados';

  @override
  String get accountStrengthStrong => 'Forte';

  @override
  String get accountStartupInspecting => 'Verificando sua identidade…';

  @override
  String get accountStartupOpening => 'Abrindo sua identidade…';

  @override
  String get accountStartupFailedTitle => 'Não foi possível iniciar';

  @override
  String get accountStartupFailedBody => 'O DitMesh não conseguiu ler sua identidade. Nada foi alterado; você pode tentar novamente.';

  @override
  String get accountConnectionTapToReconnect => 'Toque para reconectar';

  @override
  String get accountWelcomeTitle => 'Sua identidade fica neste dispositivo';

  @override
  String get accountWelcomeIntro => 'O DitMesh usa a rede ponto a ponto Tox. Não há servidor nem conta para cadastrar: sua identidade é um par de chaves armazenado apenas aqui.';

  @override
  String get accountWelcomePointNoServer => 'Sem servidor, telefone ou e-mail. Os operadores conversam diretamente em Morse.';

  @override
  String get accountWelcomePointTraining => 'Converse com uma pessoa ou em grupo usando código Morse, com uma chave reta ou palhetas iâmbicas.';

  @override
  String get accountWelcomePointBackup => 'Ninguém pode recuperar sua identidade por você. Faça um backup logo após criá-la ou ela será perdida junto com o dispositivo.';

  @override
  String get accountCreateIdentity => 'Criar identidade';

  @override
  String get accountRestoreFromBackup => 'Restaurar do backup';

  @override
  String get accountCreateTitle => 'Crie sua identidade';

  @override
  String get accountCreateBody => 'Escolha um nome que os outros verão. Uma senha criptografa o arquivo de identidade neste dispositivo; deixe em branco se preferir abrir o aplicativo sem senha.';

  @override
  String get accountCreateButton => 'Criar';

  @override
  String get accountCreating => 'Criando…';

  @override
  String get accountBackupTitle => 'Faça um backup da sua identidade agora';

  @override
  String get accountBackupBody => 'Sua identidade existe apenas neste dispositivo. Se ele for perdido, redefinido ou roubado, não será possível recuperá-la: seus contatos não reconhecerão uma nova identidade e seu progresso será perdido.';

  @override
  String get accountBackupWhatIsInside => 'O arquivo de backup contém sua chave de identidade, criptografada com sua senha, e seu progresso. Guarde-o em um local seguro fora deste dispositivo.';

  @override
  String get accountBackupWhatIsInsidePlain => 'O arquivo de backup contém sua chave de identidade sem criptografia e seu progresso. Qualquer pessoa que obtiver este arquivo pode usar sua identidade: defina uma senha antes se quiser a chave criptografada e guarde o arquivo em um local seguro.';

  @override
  String get accountPasswordScope => 'Sua senha criptografa sua chave de identidade. O histórico de mensagens fica sem criptografia no disco; a criptografia do dispositivo pode protegê-lo.';

  @override
  String get accountSectionNotifications => 'Notificações';

  @override
  String get accountNotificationsEnable => 'Mostrar notificações';

  @override
  String get accountNotificationsEnableSubtitle => 'Novas mensagens, pedidos de amizade e convites de grupo';

  @override
  String get accountNotificationsContent => 'Mostrar o conteúdo das mensagens';

  @override
  String get accountNotificationsContentSubtitle => 'Texto e Morse nos avisos e na tela de bloqueio. Desligado: só que chegou uma mensagem.';

  @override
  String get accountNotificationsAllow => 'Permitir notificações';

  @override
  String get accountNotificationsAllowSubtitle => 'Pedir permissão ao sistema';

  @override
  String get accountNotificationsBlocked => 'Bloqueadas nas definições do sistema';

  @override
  String get accountNotificationsBlockedSubtitle => 'As notificações de mensagens do DitMesh estão desativadas nas definições do sistema. Reative-as lá.';

  @override
  String get accountNotificationsDenied => 'As notificações do DitMesh estão desligadas nas configurações do sistema.';

  @override
  String get accountBackupSaveFile => 'Salvar arquivo de backup';

  @override
  String get accountBackupShareFile => 'Compartilhar arquivo de backup';

  @override
  String get accountBackupSaved => 'Backup salvo';

  @override
  String get accountBackupNotSaved => 'O backup não foi salvo';

  @override
  String get accountBackupFailed => 'Não foi possível gravar o backup';

  @override
  String get accountBackupAcknowledge => 'Entendo que, sem este backup, minha identidade não poderá ser recuperada.';

  @override
  String get accountBackupContinue => 'Continuar para o DitMesh';

  @override
  String get accountBackupShowQrHint => 'Seus amigos adicionam você pelo seu Tox ID. Compartilhe-o como texto ou código QR.';

  @override
  String get accountRestoreTitle => 'Restaurar do backup';

  @override
  String get accountRestoreBody => 'Escolha um arquivo de backup exportado pelo DitMesh. Se a identidade estava protegida por senha, você precisará dela aqui.';

  @override
  String get accountRestoreChooseFile => 'Escolher arquivo de backup';

  @override
  String get accountRestoreNoFile => 'Escolha primeiro um arquivo de backup';

  @override
  String get accountRestoreButton => 'Restaurar';

  @override
  String get accountRestoring => 'Restaurando…';

  @override
  String get accountRestoreInvalidFile => 'Este arquivo não é um backup do DitMesh.';

  @override
  String get accountRestoreReplacesWarning => 'A restauração substitui a identidade atual neste dispositivo.';

  @override
  String get accountUnlockTitle => 'Desbloqueie sua identidade';

  @override
  String get accountUnlockBody => 'Seu arquivo de identidade está criptografado. Digite a senha para continuar.';

  @override
  String get accountUnlockButton => 'Desbloquear';

  @override
  String get accountUnlocking => 'Desbloqueando…';

  @override
  String get accountUnlockRestoreInstead => 'Restaurar do backup em vez disso';

  @override
  String get accountMeNoIdentity => 'Nenhuma identidade carregada';

  @override
  String get accountSectionAccount => 'Conta';

  @override
  String get accountSectionTraining => 'Treinamento';

  @override
  String get accountSectionAbout => 'Sobre';

  @override
  String get accountSectionDanger => 'Zona de perigo';

  @override
  String get accountEditProfile => 'Editar perfil';

  @override
  String get accountEditProfileBody => 'Visível para seus contatos na rede Tox.';

  @override
  String get accountSetPassword => 'Definir senha';

  @override
  String get accountChangePassword => 'Alterar senha';

  @override
  String get accountRemovePassword => 'Remover senha';

  @override
  String get accountCurrentPassword => 'Senha atual';

  @override
  String get accountNewPassword => 'Nova senha';

  @override
  String get accountPasswordUpdated => 'Senha atualizada';

  @override
  String get accountPasswordRemoved => 'Senha removida';

  @override
  String get accountProfileUpdated => 'Perfil atualizado';

  @override
  String get accountExportBackup => 'Exportar backup';

  @override
  String get accountExportBackupSubtitle => 'Salve sua identidade e seu progresso em um arquivo';

  @override
  String get accountTrainingDefaults => 'Padrões de reprodução e treinamento';

  @override
  String get accountTrainingDefaultsSubtitle => 'Velocidade, tom e espaçamento Farnsworth';

  @override
  String get accountTrainingDefaultsPlaceholder => 'Os padrões de velocidade, tom e Farnsworth ficarão aqui.';

  @override
  String get accountAboutLicence => 'Licença';

  @override
  String get accountAboutLicenceValue => 'GPL-3.0';

  @override
  String get accountAboutSource => 'Código-fonte';

  @override
  String get accountAboutSourceCopied => 'Link do código-fonte copiado';

  @override
  String get accountAboutBackend => 'Motor interno';

  @override
  String get accountDeleteIdentity => 'Excluir identidade';

  @override
  String get accountDeleteIdentitySubtitle => 'Apague a identidade, o histórico e o progresso deste dispositivo';

  @override
  String get accountDeleteDialogTitle => 'Excluir esta identidade?';

  @override
  String get accountDeleteDialogBody => 'Isso remove sua identidade, histórico de conversas e progresso deste dispositivo. Sem backup, não será possível recuperar. Digite DELETE para confirmar.';

  @override
  String get accountDeleteConfirmWord => 'DELETE';

  @override
  String get accountDeleteConfirmHint => 'Digite DELETE';

  @override
  String get accountDeleteButton => 'Excluir';

  @override
  String get accountRecoveryPendingDiscard => 'Descartar a identidade pendente e recomeçar';

  @override
  String accountRestoreFileChosenSize(int bytes) {
    return 'Arquivo de backup selecionado ($bytes bytes)';
  }

  @override
  String get chatSearchConversations => 'Buscar conversas';

  @override
  String get chatNoConversations => 'Ainda não há conversas';

  @override
  String get chatNoSearchResults => 'Nenhuma conversa corresponde à busca';

  @override
  String get chatPin => 'Fixar';

  @override
  String get chatUnpin => 'Desafixar';

  @override
  String get chatMarkRead => 'Marcar como lida';

  @override
  String get chatDelete => 'Excluir';

  @override
  String get chatDeleteConversationTitle => 'Excluir conversa?';

  @override
  String get chatDeleteConversationBody => 'O histórico local desta conversa será removido. O Tox não mantém cópias.';

  @override
  String get chatDraftPrefix => 'Rascunho: ';

  @override
  String get chatSelectConversation => 'Selecione uma conversa';

  @override
  String get chatContacts => 'Contatos';

  @override
  String get chatNoMessages => 'Ainda não há mensagens: envie CQ para começar.';

  @override
  String get chatTrainingMode => 'Modo de treinamento';

  @override
  String get chatTrainingModeOn => 'Treinamento ativado: texto oculto';

  @override
  String get chatTrainingModeOff => 'Treinamento desativado';

  @override
  String get chatAutoPlay => 'Reproduzir automaticamente o Morse recebido';

  @override
  String get chatAutoPlayOn => 'Reprodução automática ativada: novas mensagens tocam ao chegar';

  @override
  String get chatAutoPlayOff => 'Reprodução automática desativada';

  @override
  String get chatReveal => 'Mostrar';

  @override
  String get chatHiddenText => 'Ouça primeiro e depois mostre o texto';

  @override
  String get chatPlay => 'Reproduzir Morse';

  @override
  String get chatStop => 'Parar';

  @override
  String get chatPlaybackSettings => 'Configurações de reprodução';

  @override
  String get chatCharacterSpeed => 'Velocidade dos caracteres';

  @override
  String get chatFarnsworthSpeed => 'Velocidade Farnsworth';

  @override
  String get chatTone => 'Tom';

  @override
  String get chatWpm => 'WPM';

  @override
  String get chatHz => 'Hz';

  @override
  String get chatMembers => 'Membros';

  @override
  String get chatLeaveGroup => 'Sair do grupo';

  @override
  String get chatLeaveGroupTitle => 'Sair deste grupo?';

  @override
  String get chatLeaveGroupBody => 'Você deixará de receber mensagens. Entre novamente depois com o ID do chat.';

  @override
  String get chatLeave => 'Sair';

  @override
  String get chatConferenceNote => 'Conferência antiga: os metadados de transmissão Morse (v2) não estão disponíveis aqui. O texto continua funcionando.';

  @override
  String get chatClearHistory => 'Limpar histórico';

  @override
  String get chatModeStraightKey => 'Chave manual';

  @override
  String get chatModePaddles => 'Palhetas';

  @override
  String get chatKeyMessage => 'Transmita sua mensagem em Morse';

  @override
  String get chatSend => 'Enviar';

  @override
  String get chatTooLong => 'Ultrapassa o limite de uma mensagem do Tox';

  @override
  String get chatKeyHint => 'Use a área da chave ou pressione Espaço';

  @override
  String get chatPaddleHint => 'Toque nas palhetas ou segure Ctrl (esquerdo: ponto; direito: traço)';

  @override
  String get chatDeleteLast => 'Excluir último caractere';

  @override
  String get chatNoFriends => 'Ainda não há amigos. Adicione alguém pelo Tox ID.';

  @override
  String get chatNoRequests => 'Não há solicitações pendentes';

  @override
  String get chatAddFriend => 'Adicionar amigo';

  @override
  String get chatMyToxId => 'Meu Tox ID';

  @override
  String get chatToxIdLabel => 'Tox ID (76 caracteres hexadecimais)';

  @override
  String get chatToxIdInvalid => 'O Tox ID deve ter exatamente 76 caracteres hexadecimais';

  @override
  String get chatToxIdOwn => 'Este é o seu próprio Tox ID';

  @override
  String get chatToxIdAlreadyFriend => 'Já está na sua lista de amigos';

  @override
  String get chatRequestMessage => 'Mensagem';

  @override
  String get chatDefaultRequestMessage => 'DitMesh CQ';

  @override
  String get chatSendRequest => 'Enviar solicitação';

  @override
  String get chatRequestSent => 'Solicitação de amizade enviada';

  @override
  String get chatScanQr => 'Ler QR';

  @override
  String get chatScanQrDesktopHint => 'A leitura de QR requer a câmera de um celular';

  @override
  String get chatScanQrTitle => 'Ler um Tox ID';

  @override
  String get chatScanQrNotToxId => 'Este código QR não é um Tox ID';

  @override
  String get chatAccept => 'Aceitar';

  @override
  String get chatReject => 'Recusar';

  @override
  String get chatCopied => 'Copiado para a área de transferência';

  @override
  String get chatNoIdentity => 'Nenhuma identidade carregada';

  @override
  String get chatRemoveFriend => 'Remover amigo';

  @override
  String get chatRemoveFriendTitle => 'Remover este amigo?';

  @override
  String get chatRemoveFriendBody => 'Ele não poderá mais enviar mensagens para você.';

  @override
  String get chatRemove => 'Remover';

  @override
  String get chatNoGroups => 'Ainda não há grupos. Crie um ou entre pelo ID do chat.';

  @override
  String get chatCreateGroup => 'Criar grupo';

  @override
  String get chatJoinGroup => 'Entrar em um grupo';

  @override
  String get chatGroupName => 'Nome do grupo';

  @override
  String get chatGroupNameRequired => 'Dê um nome ao grupo';

  @override
  String get chatAdvanced => 'Avançado';

  @override
  String get chatLegacyConference => 'Conferência antiga (clientes antigos)';

  @override
  String get chatLegacyConferenceHint => 'Não recomendado: sem ID permanente do chat nem metadados Morse.';

  @override
  String get chatCreate => 'Criar';

  @override
  String get chatChatIdLabel => 'ID do chat (64 caracteres hexadecimais)';

  @override
  String get chatChatIdInvalid => 'O ID do chat deve ter exatamente 64 caracteres hexadecimais';

  @override
  String get chatPassword => 'Senha (opcional)';

  @override
  String get chatJoin => 'Entrar';

  @override
  String get chatJoinRequested => 'Entrando: o grupo aparecerá quando um membro for encontrado.';

  @override
  String get chatConferenceBadge => 'Conferência';

  @override
  String get chatCopyChatId => 'Copiar ID do chat';

  @override
  String get learnLessonCardTitle => 'Lição Koch';

  @override
  String get learnCourseComplete => 'Curso concluído: continue aperfeiçoando!';

  @override
  String get learnDailyGoalTitle => 'Hoje';

  @override
  String get learnDailyGoalMet => 'Meta diária alcançada';

  @override
  String get learnNoStreak => 'Comece hoje uma sequência';

  @override
  String get learnContinueLesson => 'Continuar lição';

  @override
  String get learnReceivePractice => 'Prática de recepção';

  @override
  String get learnSendPractice => 'Prática de transmissão';

  @override
  String get learnReviewDue => 'Revisar caracteres pendentes';

  @override
  String get learnSettings => 'Configurações de treinamento';

  @override
  String get learnLoading => 'Carregando seu progresso...';

  @override
  String get learnIdentityRequired => 'Crie ou desbloqueie sua identidade para começar a treinar. O progresso é salvo com ela e incluído no backup.';

  @override
  String get learnLoadFailed => 'Não foi possível ler seu progresso salvo. Você começará do zero; o arquivo antigo foi preservado como .corrupt.';

  @override
  String get learnProgressSaveFailed => 'Não foi possível salvar seu progresso. O resultado vale enquanto o DitMesh estiver aberto.';

  @override
  String get learnChooseDrill => 'Escolha um exercício';

  @override
  String get learnDrillGroups => 'Grupos aleatórios';

  @override
  String get learnDrillWords => 'Palavras';

  @override
  String get learnDrillCallsigns => 'Indicativos';

  @override
  String get learnDrillQso => 'QSO';

  @override
  String get learnDrillCharacters => 'Caracteres individuais';

  @override
  String get learnDrillAbbreviations => 'Abreviações e códigos Q';

  @override
  String get learnDrillNumbers => 'Grupos de números';

  @override
  String get learnDrillConfusables => 'Caracteres parecidos';

  @override
  String get learnDrillContest => 'Trocas de concurso';

  @override
  String get learnDrillGroupsHint => 'Grupos aleatórios com todos os caracteres que você conhece';

  @override
  String get learnDrillCharactersHint => 'Um caractere por vez: reconheça na hora';

  @override
  String get learnDrillWordsHint => 'Palavras comuns em inglês';

  @override
  String get learnDrillAbbreviationsHint => 'TNX, FB, QTH, QSL: as abreviações do rádio';

  @override
  String get learnDrillNumbersHint => 'Grupos de cinco dígitos, como em mensagens e números de série';

  @override
  String get learnDrillCallsignsHint => 'Indicativos de radioamadores do mundo todo';

  @override
  String get learnDrillConfusablesHint => 'Pares que você confunde, como S/H ou U/V, lado a lado';

  @override
  String get learnDrillQsoHint => 'Frases de um contato completo';

  @override
  String get learnDrillContestHint => 'Indicativo, 5NN e número de série ou zona, no ritmo de um concurso';

  @override
  String get learnDrillReviewHint => 'Caracteres com revisão pendente';

  @override
  String get toolsTitle => 'Ferramentas de rádio';

  @override
  String get toolsGridTitle => 'Localizador';

  @override
  String get toolsGridHint => 'Localizador por coordenadas, distância e direção da antena';

  @override
  String get toolsBandsTitle => 'Bandas e antenas';

  @override
  String get toolsBandsHint => 'Banda de uma frequência, comprimento de onda e do dipolo';

  @override
  String get toolsSpeedTitle => 'Velocidade CW';

  @override
  String get toolsSpeedHint => 'De WPM para duração do ponto, intervalos e caracteres por minuto';

  @override
  String get toolsRstTitle => 'Relatório RST';

  @override
  String get toolsRstHint => 'Monte um relatório de sinal e veja o significado de cada dígito';

  @override
  String get toolsClockTitle => 'Relógio UTC';

  @override
  String get toolsClockHint => 'Hora UTC para o registro, ao lado da sua hora local';

  @override
  String get toolsGridFromCoordinates => 'A partir de coordenadas';

  @override
  String get toolsGridLatitude => 'Latitude';

  @override
  String get toolsGridLongitude => 'Longitude';

  @override
  String get toolsGridCoordinatesHelp => 'Graus decimais; sul e oeste são negativos';

  @override
  String get toolsGridInvalidCoordinates => 'Latitude de -90 a 90, longitude de -180 a 180';

  @override
  String get toolsGridLocator => 'Localizador';

  @override
  String get toolsGridDistanceSection => 'Distância e direção';

  @override
  String get toolsGridMine => 'Meu localizador';

  @override
  String get toolsGridTheirs => 'Localizador remoto';

  @override
  String get toolsGridInvalidLocator => 'Use 2, 4, 6 ou 8 caracteres, por exemplo, OM89ex';

  @override
  String get toolsGridCenter => 'Centro da quadrícula';

  @override
  String get toolsGridDistance => 'Distância';

  @override
  String get toolsGridShortPath => 'Direção pelo caminho curto';

  @override
  String get toolsGridLongPath => 'Direção pelo caminho longo';

  @override
  String get toolsBandsFrequency => 'Frequência (MHz)';

  @override
  String get toolsBandsInvalidFrequency => 'Digite uma frequência maior que 0';

  @override
  String toolsBandsRegionLabel(int number) {
    return 'Região $number';
  }

  @override
  String get toolsBandsRegionHelp => '1: Europa, África, Oriente Médio · 2: Américas · 3: Ásia-Pacífico';

  @override
  String toolsBandsInBand(String band) {
    return 'Na banda de radioamador de $band';
  }

  @override
  String get toolsBandsOutOfBand => 'Fora das bandas de radioamador';

  @override
  String get toolsBandsWavelength => 'Comprimento de onda';

  @override
  String get toolsBandsDipole => 'Dipolo de meia onda (total)';

  @override
  String get toolsBandsQuarterWave => 'Vertical de um quarto de onda';

  @override
  String get toolsBandsAntennaNote => 'Os comprimentos incluem um fator de encurtamento de 0,95; ajuste até a ressonância.';

  @override
  String get toolsBandsTable => 'Limites das bandas';

  @override
  String toolsBandsQrp(String frequency) {
    return 'QRP CW $frequency';
  }

  @override
  String get toolsBandsDisclaimer => 'Atribuições da ITU. Sua licença e o plano nacional de bandas podem ser mais restritos.';

  @override
  String get toolsSpeedCharacter => 'Velocidade dos caracteres';

  @override
  String get toolsSpeedFarnsworth => 'Espaçamento Farnsworth';

  @override
  String get toolsSpeedOverall => 'Velocidade geral';

  @override
  String get toolsSpeedDit => 'Ponto';

  @override
  String get toolsSpeedDah => 'Traço';

  @override
  String get toolsSpeedCharGap => 'Intervalo entre caracteres';

  @override
  String get toolsSpeedWordGap => 'Intervalo entre palavras';

  @override
  String get toolsSpeedCpm => 'Caracteres por minuto';

  @override
  String get toolsSpeedParis => 'Uma palavra PARIS';

  @override
  String get toolsRstReadability => 'Legibilidade (R)';

  @override
  String get toolsRstStrength => 'Intensidade (S)';

  @override
  String get toolsRstTone => 'Tom (T)';

  @override
  String get toolsRstReport => 'Relatório';

  @override
  String get toolsRstCut => 'Forma de concurso';

  @override
  String get toolsRstPhone => 'Em voz (sem tom)';

  @override
  String get toolsRstR1 => 'Ilegível';

  @override
  String get toolsRstR2 => 'Quase ilegível, palavras isoladas';

  @override
  String get toolsRstR3 => 'Legível com muita dificuldade';

  @override
  String get toolsRstR4 => 'Legível quase sem dificuldade';

  @override
  String get toolsRstR5 => 'Perfeitamente legível';

  @override
  String get toolsRstS1 => 'Fraco, quase imperceptível';

  @override
  String get toolsRstS2 => 'Muito fraco';

  @override
  String get toolsRstS3 => 'Fraco';

  @override
  String get toolsRstS4 => 'Razoável';

  @override
  String get toolsRstS5 => 'Razoavelmente bom';

  @override
  String get toolsRstS6 => 'Bom';

  @override
  String get toolsRstS7 => 'Moderadamente forte';

  @override
  String get toolsRstS8 => 'Forte';

  @override
  String get toolsRstS9 => 'Extremamente forte';

  @override
  String get toolsRstT1 => 'Muito áspero e largo, AC sem retificação';

  @override
  String get toolsRstT2 => 'AC muito áspera, estridente e larga';

  @override
  String get toolsRstT3 => 'Áspero, retificado sem filtragem';

  @override
  String get toolsRstT4 => 'Áspero, com alguma filtragem';

  @override
  String get toolsRstT5 => 'Filtrado, com forte modulação por ondulação';

  @override
  String get toolsRstT6 => 'Filtrado, com ondulação evidente';

  @override
  String get toolsRstT7 => 'Quase puro, com leve ondulação';

  @override
  String get toolsRstT8 => 'Quase perfeito, com leve modulação';

  @override
  String get toolsRstT9 => 'Tom perfeito, sem ondulação';

  @override
  String get toolsClockUtc => 'UTC';

  @override
  String get toolsClockLocal => 'Hora local';

  @override
  String get toolsClockNote => 'Os registros de contatos e os cartões QSL usam UTC.';

  @override
  String get learnReceiveTitle => 'Recepção';

  @override
  String get learnReviewTitle => 'Revisão';

  @override
  String get learnListen => 'Reproduzindo';

  @override
  String get learnReady => 'Pronto';

  @override
  String get learnReplay => 'Reproduzir novamente';

  @override
  String get learnAnswerHint => 'Digite o que ouviu';

  @override
  String get learnSubmit => 'Conferir';

  @override
  String get learnNext => 'Próximo';

  @override
  String get learnFinish => 'Finalizar';

  @override
  String get learnDone => 'Concluído';

  @override
  String get learnBackspace => 'Excluir';

  @override
  String get learnSpace => 'Espaço';

  @override
  String get learnSent => 'Transmitido';

  @override
  String get learnYourCopy => 'Sua recepção';

  @override
  String get learnRoundPerfect => 'Recepção perfeita!';

  @override
  String get learnSessionSummary => 'Resumo da sessão';

  @override
  String get learnLessonPassed => 'Lição concluída';

  @override
  String get learnLessonNotPassed => 'Continue praticando: 90% desbloqueia o próximo caractere';

  @override
  String get learnReviewRecorded => 'Revisão registrada';

  @override
  String get learnWeakChars => 'Precisa melhorar';

  @override
  String get learnConfusions => 'Confusões';

  @override
  String get learnNoFeedbackWarning => 'Som, flashes e vibração estão desligados: a tela piscará no lugar deles.';

  @override
  String get learnSendTitle => 'Transmissão';

  @override
  String get learnSendThis => 'Transmita isto';

  @override
  String get learnCopyFromMemory => 'De memória';

  @override
  String get learnHiddenTarget => 'Oculto: transmita de memória';

  @override
  String get learnDecoded => 'Decodificado';

  @override
  String get learnWaitingForKey => 'Comece a transmitir quando estiver pronto';

  @override
  String get learnRestart => 'Recomeçar';

  @override
  String get learnTryAnother => 'Tentar outro';

  @override
  String get learnKeyerStraight => 'Manual';

  @override
  String get learnKeyerIambicA => 'Iâmbico A';

  @override
  String get learnKeyerIambicB => 'Iâmbico B';

  @override
  String get learnLegendStraight => 'Espaço = chave';

  @override
  String get learnLegendPaddles => 'Ctrl esquerdo = ponto; Ctrl direito = traço';

  @override
  String get learnSendClean => 'Transmissão limpa: nada a corrigir.';

  @override
  String get learnSendIssues => 'Dicas de ritmo';

  @override
  String get learnYourSending => 'Decodificado como';

  @override
  String get learnStraightKeyLabel => 'CHAVE';

  @override
  String get learnDitLabel => 'PONTO';

  @override
  String get learnDahLabel => 'TRAÇO';

  @override
  String get learnSettingsTitle => 'Configurações de treinamento';

  @override
  String get learnCharacterSpeed => 'Velocidade dos caracteres';

  @override
  String get learnFarnsworth => 'Espaçamento Farnsworth';

  @override
  String get learnFarnsworthHelp => 'Os caracteres continuam rápidos; os intervalos entre eles se alongam até esta velocidade.';

  @override
  String get learnEffectiveSpeed => 'Velocidade efetiva';

  @override
  String get learnTone => 'Tom';

  @override
  String get learnPlaySample => 'Reproduzir exemplo';

  @override
  String get learnSessionLength => 'Caracteres por sessão';

  @override
  String get learnFeedback => 'Retorno sensorial';

  @override
  String get learnSound => 'Som';

  @override
  String get learnFlash => 'Flash da tela';

  @override
  String get learnHaptic => 'Vibração';

  @override
  String get learnKeyer => 'Manipulador';

  @override
  String get learnDailyGoal => 'Meta diária';

  @override
  String get referenceReferenceTitle => 'Referência de Morse';

  @override
  String get referenceTranslatorTitle => 'Tradutor';

  @override
  String get referencePlay => 'Reproduzir';

  @override
  String get referenceStop => 'Parar';

  @override
  String get referenceClear => 'Limpar';

  @override
  String get referenceClose => 'Fechar';

  @override
  String get referenceEmptyOutput => '—';

  @override
  String get referenceSearchHint => 'Buscar caracteres, sinais de procedimento, códigos Q…';

  @override
  String get referenceClearSearch => 'Limpar busca';

  @override
  String get referenceNoResults => 'Nenhum resultado para sua busca.';

  @override
  String get referenceSectionAlphabet => 'Alfabeto';

  @override
  String get referenceSectionPunctuation => 'Pontuação';

  @override
  String get referenceSectionProsigns => 'Sinais de procedimento';

  @override
  String get referenceSectionQCodes => 'Códigos Q';

  @override
  String get referenceSectionAbbreviations => 'Abreviações CW';

  @override
  String get referenceSectionKoch => 'Ordem Koch';

  @override
  String get referenceAlphabetHint => 'Toque em um cartão para ouvir. Pressione e segure para ver uma dica de memorização.';

  @override
  String get referenceKochHint => 'Ordem de introdução dos caracteres no método Koch (sequência LCWO). Comece com K e M; adicione um ao atingir 90% de acertos na recepção.';

  @override
  String get referenceMnemonicTitle => 'Dica de memorização';

  @override
  String get referenceMeaningLabel => 'Significado';

  @override
  String get referencePlaybackSettings => 'Configurações de reprodução';

  @override
  String get referenceCharacterSpeed => 'Velocidade dos caracteres';

  @override
  String get referenceFarnsworth => 'Espaçamento Farnsworth';

  @override
  String get referenceFarnsworthHelp => 'Os caracteres mantêm a velocidade máxima; os intervalos se alongam até a velocidade efetiva.';

  @override
  String get referenceEffectiveSpeed => 'Velocidade efetiva';

  @override
  String get referenceTone => 'Tom';

  @override
  String get referenceModeTextToMorse => 'Texto → Morse';

  @override
  String get referenceModeMorseToText => 'Morse → Texto';

  @override
  String get referenceModeKey => 'Transmitir';

  @override
  String get referenceTextInputLabel => 'Texto';

  @override
  String get referenceTextInputHint => 'Digite o texto para codificar…';

  @override
  String get referencePatternOutputLabel => 'Morse';

  @override
  String get referenceCopyPattern => 'Copiar código';

  @override
  String get referencePatternCopied => 'Código copiado';

  @override
  String get referencePatternInputLabel => 'Morse';

  @override
  String get referencePatternInputHint => 'Digite . e -, um espaço entre letras e / entre palavras';

  @override
  String get referenceTextOutputLabel => 'Texto';

  @override
  String get referenceCopyText => 'Copiar texto';

  @override
  String get referenceTextCopied => 'Texto copiado';

  @override
  String get referenceUnknownPatternHelp => 'Os códigos sem caractere correspondente aparecem como <código>.';

  @override
  String get referenceKeypadDit => 'Ponto';

  @override
  String get referenceKeypadDah => 'Traço';

  @override
  String get referenceKeypadCharGap => 'Intervalo entre letras';

  @override
  String get referenceKeypadWordGap => 'Intervalo entre palavras';

  @override
  String get referenceKeypadBackspace => 'Apagar';

  @override
  String get referenceKeyHint => 'Segure a chave para transmitir. No teclado, segure Espaço.';

  @override
  String get referenceKeyLabel => 'CHAVE';

  @override
  String get referenceKeyDecodedLabel => 'Decodificado';

  @override
  String get referenceKeyPendingLabel => 'Transmitindo';

  @override
  String get statsTitle => 'Estatísticas';

  @override
  String get statsLoading => 'Carregando suas estatísticas...';

  @override
  String get statsLoadFailed => 'Não foi possível carregar seu progresso. Puxe para baixo ou reabra para tentar novamente.';

  @override
  String get statsRetry => 'Tentar novamente';

  @override
  String get statsEmptyTitle => 'Ainda não há sessões';

  @override
  String get statsEmptyBody => 'Conclua sua primeira sessão de recepção ou transmissão para ver aqui a evolução da precisão, o domínio de cada caractere e um calendário de prática.';

  @override
  String get statsEmptyCallToAction => 'Vá para Aprender e toque em «Continuar lição» para começar.';

  @override
  String get statsOverviewTitle => 'Visão geral';

  @override
  String get statsTileLesson => 'Lição Koch';

  @override
  String get statsTileAccuracy => 'Precisão';

  @override
  String get statsNoData => '--';

  @override
  String get statsTilePractice => 'Prática';

  @override
  String get statsTileStreak => 'Sequência';

  @override
  String get statsTileDailyGoal => 'Meta diária';

  @override
  String get statsGoalMet => 'Alcançada hoje';

  @override
  String get statsSummaryTitle => 'Suas estatísticas';

  @override
  String get statsSummaryOpen => 'Ver estatísticas';

  @override
  String get statsTrendTitle => 'Evolução da precisão';

  @override
  String get statsTrendHint => 'Toque em um ponto para ver a sessão.';

  @override
  String get statsSeriesReceive => 'Recepção';

  @override
  String get statsSeriesSend => 'Transmissão';

  @override
  String get statsAxisSessions => 'Sessão';

  @override
  String get statsCharsTitle => 'Caracteres';

  @override
  String get statsCharsSubtitle => 'Ordem Koch. Toque em um caractere para ver detalhes.';

  @override
  String get statsCharsNotStarted => 'Ainda não praticado';

  @override
  String get statsNotInCourse => 'Não faz parte do curso Koch';

  @override
  String get statsSrsTitle => 'Repetição espaçada';

  @override
  String get statsSrsNotTracked => 'Ainda não agendado';

  @override
  String get statsSrsDueNow => 'Revisar agora';

  @override
  String get statsConfusionsTitle => 'Mais confundido com';

  @override
  String get statsConfusionsNone => 'Nenhuma confusão registrada';

  @override
  String get statsConfusionMissed => 'não recebido';

  @override
  String get statsBucketLegendTitle => 'Precisão';

  @override
  String get statsBucketNone => 'Nenhuma';

  @override
  String get statsBucketWeak => '< 70%';

  @override
  String get statsBucketFair => '70-89%';

  @override
  String get statsBucketGood => '90-97%';

  @override
  String get statsBucketStrong => '>= 98%';

  @override
  String get statsHeatmapTitle => 'Confusões';

  @override
  String get statsHeatmapSubtitle => 'As linhas mostram o caractere transmitido e as colunas, sua resposta. Quanto mais escuro, mais frequente.';

  @override
  String get statsHeatmapEmpty => 'Ainda não há confusões. As respostas incorretas aparecerão aqui.';

  @override
  String get statsHeatmapLegendLow => 'Rara';

  @override
  String get statsHeatmapLegendHigh => 'Frequente';

  @override
  String get statsHeatmapAxisTarget => 'Transmitido';

  @override
  String get statsHeatmapAxisAnswered => 'Respondido';

  @override
  String get statsCalendarTitle => 'Calendário de prática';

  @override
  String get statsCalendarSubtitle => 'Últimas 12 semanas';

  @override
  String get statsCalendarLegendLess => 'Menos';

  @override
  String get statsCalendarLegendMore => 'Mais';

  @override
  String get statsStreakExplanation => 'Uma sequência conta os dias consecutivos com pelo menos uma sessão. Ficar um dia inteiro sem praticar a reinicia; praticar duas vezes no mesmo dia conta apenas uma vez.';

  @override
  String get learnStatistics => 'Estatísticas';

  @override
  String get listenTitle => 'Escutar';

  @override
  String get listenStart => 'Iniciar';

  @override
  String get listenStop => 'Parar';

  @override
  String get listenStarting => 'Iniciando microfone...';

  @override
  String get listenClear => 'Limpar texto';

  @override
  String get listenCopy => 'Copiar texto';

  @override
  String get listenCopied => 'Texto decodificado copiado';

  @override
  String get listenSettings => 'Configurações de escuta';

  @override
  String get listenDecoded => 'Decodificado';

  @override
  String get listenEmptyHint => 'Aponte o microfone para um tom Morse. O texto decodificado aparecerá aqui.';

  @override
  String get listenIdleHint => 'Toque em Iniciar para escutar um tom Morse.';

  @override
  String get listenPending => 'Recebendo';

  @override
  String get listenSpeed => 'Velocidade';

  @override
  String get listenSpeedUnknown => '-- WPM';

  @override
  String get listenLevel => 'Sinal';

  @override
  String get listenToneOn => 'Tom';

  @override
  String get listenTone => 'Frequência do tom';

  @override
  String get listenToneLocked => 'Sintonizada';

  @override
  String get listenToneSearching => 'Buscando';

  @override
  String get listenToneManual => 'Manual';

  @override
  String get listenAutoTune => 'Sintonia automática';

  @override
  String get listenAutoTuneHelp => 'Acompanha o tom mais forte entre 400 e 1000 Hz. Arraste o controle para sintonizar manualmente.';

  @override
  String get listenRetune => 'Automático';

  @override
  String get listenBlockSize => 'Bloco de análise';

  @override
  String get listenBlockSizeHelp => 'Blocos menores localizam os limites dos elementos com mais precisão, mas captam mais ruído. 256 amostras (5,3 ms) são adequadas para 5–40 WPM.';

  @override
  String get listenMinElement => 'Elemento mais curto';

  @override
  String get listenMinElementHelp => 'Tons e intervalos mais curtos são ignorados como estalos e falhas de sinal.';

  @override
  String get listenPermissionDenied => 'O acesso ao microfone foi negado. Permita-o nas configurações do sistema e tente novamente.';

  @override
  String get listenPermissionRetry => 'Tentar novamente';

  @override
  String get listenStartFailed => 'Não foi possível iniciar o microfone.';

  @override
  String get listenNoInput => 'Nenhum microfone foi encontrado. Conecte um e tente novamente.';

  @override
  String get listenStreamFailed => 'O microfone parou inesperadamente. Tente novamente.';

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
    return '$samples amostras ($ms ms)';
  }

  @override
  String listenMsValue(int ms) {
    return '$ms ms';
  }

  @override
  String get listenStoppedInBackground => 'A escuta parou enquanto o aplicativo estava em segundo plano.';

  @override
  String get learnWpmUnknown => '-- WPM';

  @override
  String get learnTipDitTooLongTitle => 'Pontos longos demais';

  @override
  String get learnTipDahTooShortTitle => 'Traços curtos demais';

  @override
  String get learnTipIntraGapTooLongTitle => 'Elementos muito espaçados';

  @override
  String get learnTipCharGapTooShortTitle => 'Caracteres muito próximos';

  @override
  String get learnTipWordGapTooShortTitle => 'Palavras muito próximas';

  @override
  String get learnTipSpeedUnsteadyTitle => 'Velocidade irregular';

  @override
  String get learnSeverityMinor => 'leve';

  @override
  String get learnSeverityModerate => 'perceptível';

  @override
  String get learnSeveritySevere => 'grave';

  @override
  String get notificationOpen => 'Abrir';

  @override
  String get notificationChannelMessages => 'Mensagens';

  @override
  String get notificationChannelMessagesDescription => 'Novas mensagens Morse de amigos e grupos';

  @override
  String get notificationChannelFriendRequests => 'Solicitações de amizade';

  @override
  String get notificationChannelFriendRequestsDescription => 'Alguém quer adicionar você como amigo';

  @override
  String get notificationChannelGroupInvites => 'Convites para grupos';

  @override
  String get notificationChannelGroupInvitesDescription => 'Um amigo convidou você para um grupo';

  @override
  String get notificationNewMessage => 'Nova mensagem';

  @override
  String get notificationFriendRequestTitle => 'Nova solicitação de amizade';

  @override
  String learnNewestCharIs(String char) {
    return 'Novo nesta lição: $char';
  }

  @override
  String learnCharNewSemantics(String char) {
    return '$char, novo';
  }

  @override
  String learnPendingPattern(String pattern) {
    return 'Transmitindo: $pattern';
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
    return 'Seus pontos estão longos (cerca de $ratio de um ponto). Pense em «di», não «daah»: um ponto é um toque, não uma pressão prolongada.';
  }

  @override
  String learnTipDahTooShort(String ratio) {
    return 'Seus traços estão curtos (cerca de $ratio de um ponto; a meta é 3). Segure o traço pelo tempo de três pontos.';
  }

  @override
  String learnTipIntraGapTooLong(String ratio) {
    return 'Os intervalos dentro dos caracteres estão longos (cerca de $ratio de um ponto). Mantenha os elementos de cada caractere próximos.';
  }

  @override
  String learnTipCharGapTooShort(String ratio) {
    return 'Os caracteres se misturam (intervalos de cerca de $ratio de um ponto; a meta é 3). Deixe uma pausa clara após cada caractere.';
  }

  @override
  String learnTipWordGapTooShort(String ratio) {
    return 'As palavras estão próximas demais (intervalos de cerca de $ratio de um ponto; a meta é 7). Conte uma pausa longa entre as palavras.';
  }

  @override
  String learnTipSpeedUnsteady(int percent) {
    return 'Sua velocidade varia (variação de $percent%). Escolha um ritmo e mantenha-o durante toda a linha.';
  }

  @override
  String learnIssueDetailDitTooLong(int offending, int total, String ratio) {
    return '$offending de $total pontos longos demais (média: $ratio pontos)';
  }

  @override
  String learnIssueDetailDahTooShort(int offending, int total, String ratio) {
    return '$offending de $total traços curtos demais (média: $ratio pontos)';
  }

  @override
  String learnIssueDetailIntraGapTooLong(int offending, int total, String ratio) {
    return '$offending de $total intervalos dentro dos caracteres longos demais (média: $ratio pontos)';
  }

  @override
  String learnIssueDetailCharGapTooShort(int offending, int total, String ratio) {
    return '$offending de $total intervalos entre caracteres curtos demais (média: $ratio pontos)';
  }

  @override
  String learnIssueDetailWordGapTooShort(int offending, int total, String ratio) {
    return '$offending de $total intervalos entre palavras curtos demais (média: $ratio pontos)';
  }

  @override
  String learnIssueDetailSpeedUnsteady(String cv) {
    return 'Velocidade de transmissão irregular (coef. de variação: $cv)';
  }

  @override
  String statsAccuracyDetail(String allTime) {
    return 'Últimos 7 dias / total: $allTime';
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
  String get accountNewPasswordRequired => 'Digite uma nova senha';

  @override
  String get accountToxIdQrSemantics => 'Código QR do Tox ID';

  @override
  String get accountBackupSaveDialogTitle => 'Salvar backup do DitMesh';

  @override
  String get accountBackupShareSubject => 'Backup da identidade DitMesh';

  @override
  String get accountBackupChooseDialogTitle => 'Escolher backup do DitMesh';

  @override
  String notificationNewMessages(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count novas mensagens',
      one: '$count nova mensagem',
    );
    return '$_temp0';
  }

  @override
  String notificationFriendRequestFrom(String name) {
    return 'Solicitação de amizade de $name';
  }

  @override
  String notificationFriendRequestBody(String name, String message) {
    return '$name: $message';
  }

  @override
  String notificationGroupInviteTitle(String group) {
    return 'Convite para $group';
  }

  @override
  String notificationGroupInviteBody(String name) {
    return '$name convidou você';
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
  String get desktopTraySoundOn => 'Som ligado';

  @override
  String get desktopTraySoundOff => 'Som desligado';

  @override
  String desktopTrayQuit(String app) {
    return 'Sair do $app';
  }

  @override
  String desktopTrayTooltipUnread(String app, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count mensagens não lidas',
      one: '$count mensagem não lida',
    );
    return '$app — $_temp0';
  }

  @override
  String desktopWindowTitleUnread(String badge, String app) {
    return '($badge) $app';
  }

  @override
  String get listenStateOn => 'Ligado';

  @override
  String get listenStateOff => 'Desligado';

  @override
  String chatBytesLeftCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Restam $count bytes',
      one: 'Resta $count byte',
    );
    return '$_temp0';
  }

  @override
  String chatMemberCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count membros',
      one: '$count membro',
    );
    return '$_temp0';
  }

  @override
  String chatFriendsCount(int count) {
    return 'Amigos ($count)';
  }

  @override
  String chatFriendRequestsCount(int count) {
    return 'Solicitações de amizade ($count)';
  }

  @override
  String chatGroupInvitesCount(int count) {
    return 'Convites para grupos ($count)';
  }

  @override
  String chatMembersTitleCount(int count) {
    return 'Membros · $count';
  }

  @override
  String chatInvitedByName(String name) {
    return 'Convidado por $name';
  }

  @override
  String chatMemberSelf(String name) {
    return '$name (você)';
  }

  @override
  String chatSliderValue(String label, int value, String unit) {
    return '$label: $value $unit';
  }

  @override
  String referenceTelegraphCodes(String codes) {
    return 'Código telegráfico chinês: $codes';
  }

  @override
  String get referenceTelegraphMainland => 'China continental 1983';

  @override
  String get referenceTelegraphTaiwan => 'Taiwan / Hong Kong';

  @override
  String get referenceTelegraphNone => 'Não consta neste código';

  @override
  String get appearanceTitle => 'Aparência';

  @override
  String get appearanceStyles => 'Estilo da interface';

  @override
  String get appearanceChoose => 'Escolha um estilo, veja a prévia e aplique';

  @override
  String get appearanceMode => 'Luminosidade';

  @override
  String get appearancePreview => 'Prévia';

  @override
  String get appearanceApply => 'Aplicar estilo';

  @override
  String get appearanceRestore => 'Restaurar padrões';

  @override
  String get appearanceApplied => 'Aparência salva';

  @override
  String get appearanceSaveFailed => 'Não foi possível salvar a aparência. Tente novamente.';

  @override
  String get appearanceClassic => 'Latão clássico';

  @override
  String get appearanceModern => 'Calma moderna';

  @override
  String get appearanceRadio => 'Rádio noturno';

  @override
  String get appearancePaper => 'Manual de papel';

  @override
  String get appearanceCartoon => 'Desenho leve';

  @override
  String get appearanceLight => 'Claro';

  @override
  String get appearanceDark => 'Escuro';

  @override
  String get appearanceSubtitle => 'Cinco estilos com modos claro e escuro';

  @override
  String get chatClearHistoryBody => 'Excluir o histórico desta conversa neste dispositivo? As cópias em outros dispositivos não serão afetadas. Esta ação não pode ser desfeita.';

  @override
  String get chatLoadEarlier => 'Carregar mensagens anteriores';

  @override
  String get chatHistoryLoadFailed => 'Não foi possível carregar as mensagens anteriores. Toque para tentar novamente.';

  @override
  String get chatRetryHistory => 'Tentar novamente';

  @override
  String chatNewMessages(int count) {
    return '$count novas mensagens';
  }

  @override
  String learnShowAllChars(int count) {
    return 'Mostrar todos os $count caracteres';
  }

  @override
  String get chatSelfMe => 'Eu';

  @override
  String get chatSelfLocalOnly => 'Salvo apenas neste dispositivo';

  @override
  String get chatSelfContactSubtitle => 'Rascunhos, prática e notas · nunca enviados';

  @override
  String get learnShowFewerChars => 'Mostrar menos caracteres';

  @override
  String get learnLeaveDrillTitle => 'Sair desta sessão?';

  @override
  String get learnLeaveDrillBody => 'As rodadas desta sessão não serão salvas.';

  @override
  String get learnLeaveDrillConfirm => 'Sair';

  @override
  String get chatScanQrPermissionDenied => 'O DitMesh precisa de acesso à câmera para ler um código QR. Permita-o nas configurações do sistema.';

  @override
  String get chatScanQrCameraUnavailable => 'A câmera não está disponível neste dispositivo.';

  @override
  String get learnReplayAssistedNote => 'Repetido: esta sessão conta como prática, mas não desbloqueia lições nem atualiza revisões.';

  @override
  String get learnPlanTitle => 'Plano de hoje';

  @override
  String learnPlanSummary(int minutes, int done, int total) {
    return 'Cerca de $minutes min · $done de $total passos';
  }

  @override
  String get learnPlanBudget => 'Duração do plano';

  @override
  String learnPlanBudgetMinutes(int minutes) {
    return '$minutes min';
  }

  @override
  String get learnPlanStart => 'Começar o plano';

  @override
  String get learnPlanContinue => 'Continuar o plano';

  @override
  String get learnPlanStepReview => 'Revisar símbolos pendentes';

  @override
  String get learnPlanStepFocus => 'Prática focada';

  @override
  String learnPlanStepCourse(int lesson) {
    return 'Lição $lesson';
  }

  @override
  String get learnPlanStepSend => 'Prática de transmissão';

  @override
  String learnPlanReasonDueReview(String symbols) {
    return 'Para revisar: $symbols';
  }

  @override
  String learnPlanReasonConfusions(String symbols) {
    return 'Confundidos com frequência: $symbols';
  }

  @override
  String learnPlanReasonWeak(String symbols) {
    return 'Abaixo de 90%: $symbols';
  }

  @override
  String learnPlanReasonChallenge(int count) {
    return '$count símbolos: pode desbloquear a próxima lição';
  }

  @override
  String learnPlanReasonExtended(int count) {
    return 'Ampliado para $count símbolos para poder desbloquear a próxima lição';
  }

  @override
  String get learnPlanReasonConsolidate => 'Sessão curta: consolida a lição, não desbloqueia a próxima';

  @override
  String learnPlanReasonOutdated(int lesson) {
    return 'Seu curso avançou: pratica a lição $lesson sem desbloquear';
  }

  @override
  String learnPlanReasonSend(int count) {
    return '$count alvos curtos para transmitir';
  }

  @override
  String learnPlanStepDonePercent(int percent) {
    return 'Concluído · $percent%';
  }

  @override
  String get learnPlanStepDone => 'Concluído';

  @override
  String learnPlanSendProgress(int done, int total) {
    return '$done de $total enviados';
  }

  @override
  String get learnPlanStale => 'Sua lição ou velocidade mudou. Atualizar os passos não iniciados?';

  @override
  String get learnPlanUpdate => 'Atualizar passos';

  @override
  String get learnPlanComplete => 'Plano de hoje concluído';

  @override
  String learnPlanNeedsWork(String symbols) {
    return 'Precisa de prática: $symbols';
  }

  @override
  String get learnPlanAllGood => 'Nenhum símbolo fraco hoje.';

  @override
  String get learnPlanTomorrow => 'Amanhã chega um plano novo. A prática livre está sempre aberta.';

  @override
  String learnPlanNext(String step) {
    return 'Próximo: $step';
  }

  @override
  String learnPlanEarlier(int done, int total) {
    return 'O plano anterior parou em $done de $total passos; não conta para hoje.';
  }

  @override
  String learnSpeedAdviceRaise(int wpm) {
    return 'Pronto para $wpm PPM de velocidade efetiva';
  }

  @override
  String learnSpeedAdviceRaiseBoth(int wpm) {
    return 'Pronto para $wpm PPM';
  }

  @override
  String learnSpeedAdviceLower(int wpm) {
    return 'Copiar nesta velocidade está difícil. Tente $wpm PPM efetivas ou uma prática focada.';
  }

  @override
  String learnSpeedAdviceBody(int count, int percent) {
    return 'Com base nas suas últimas $count sessões sem ajuda ($percent%). Nada muda até você aplicar.';
  }

  @override
  String get learnSpeedAdviceApply => 'Aplicar';

  @override
  String get learnSpeedAdviceDismiss => 'Agora não';

  @override
  String get learnSpeedAdviceInsufficient => 'A sugestão de velocidade precisa de 3 sessões sem ajuda de 50+ símbolos na velocidade atual.';

  @override
  String get learnQsoAction => 'Simulador de QSO';

  @override
  String learnQsoLocked(int lesson) {
    return 'A partir da lição $lesson';
  }

  @override
  String get learnQsoTitle => 'Simulador de QSO';

  @override
  String get learnQsoRespond => 'Responder a um CQ';

  @override
  String get learnQsoRespondHint => 'Uma estação chama CQ. Responda e troquem reportagens.';

  @override
  String get learnQsoCall => 'Chamar CQ';

  @override
  String get learnQsoCallHint => 'Você chama CQ e uma estação responde.';

  @override
  String get learnQsoYourCall => 'Seu indicativo';

  @override
  String get learnQsoYourName => 'Seu nome';

  @override
  String get learnQsoYourQth => 'Seu QTH';

  @override
  String get learnQsoInvalidCall => 'Digite um indicativo como BD1XYZ';

  @override
  String get learnQsoInvalidWord => 'Uma palavra, apenas letras A–Z';

  @override
  String get learnQsoOffline => 'Funciona inteiramente neste dispositivo. Nada é enviado.';

  @override
  String get learnQsoStart => 'Iniciar QSO';

  @override
  String get learnQsoResume => 'Retomar o QSO inacabado';

  @override
  String get learnQsoStageCallCq => 'Chame CQ com seu indicativo';

  @override
  String get learnQsoStageCallConfirm => 'Responda: indicativo dele, DE, o seu';

  @override
  String get learnQsoStageExchange => 'Envie reportagem, nome e QTH';

  @override
  String get learnQsoStageConfirmInfo => 'Confirme as informações dele';

  @override
  String get learnQsoStageClosing => 'Encerre com 73 e <SK>';

  @override
  String get learnQsoStageDone => 'QSO concluído';

  @override
  String learnQsoSpeed(int wpm) {
    return 'O correspondente transmite a $wpm PPM efetivas';
  }

  @override
  String learnQsoRemote(String call) {
    return '$call transmite';
  }

  @override
  String get learnQsoRemoteHidden => 'Copie de ouvido: o texto está oculto.';

  @override
  String get learnQsoShowText => 'Mostrar texto';

  @override
  String get learnQsoListen => 'Ouvir';

  @override
  String get learnQsoAccepted => 'Aceito';

  @override
  String get learnQsoRejected => 'Não aceito';

  @override
  String get learnQsoRemoteSending => 'A outra estação está transmitindo…';

  @override
  String get learnQsoYourTurn => 'Sua vez: transmita a resposta e toque em Enviar.';

  @override
  String get learnQsoDecoded => 'Sua transmissão';

  @override
  String get learnQsoNothingKeyed => 'Nada transmitido ainda';

  @override
  String get learnQsoPlayAgain => 'Pedir repetição (AGN)';

  @override
  String get learnQsoSlower => 'Pedir mais devagar (QRS)';

  @override
  String get learnQsoHint => 'Dica';

  @override
  String learnQsoHintLabel(String example) {
    return 'Exemplo: $example';
  }

  @override
  String get learnQsoPause => 'Pausar';

  @override
  String get learnQsoSend => 'Enviar';

  @override
  String get learnQsoClear => 'Limpar';

  @override
  String get learnQsoIssueEmpty => 'Nada foi transmitido.';

  @override
  String get learnQsoIssueMissingCq => 'Comece com CQ.';

  @override
  String get learnQsoIssueMissingDe => 'Coloque DE entre os indicativos.';

  @override
  String get learnQsoIssueWrongLocalCall => 'Seu indicativo está ausente ou errado.';

  @override
  String get learnQsoIssueWrongRemoteCall => 'O indicativo da outra estação está errado.';

  @override
  String get learnQsoIssueReversedCalls => 'Indicativos invertidos: primeiro o dele, depois DE e o seu.';

  @override
  String get learnQsoIssueMissingEnding => 'Termine com K ou KN.';

  @override
  String get learnQsoIssueMissingRst => 'Dê uma reportagem, ex.: UR RST 599.';

  @override
  String get learnQsoIssueInvalidRst => 'Esse RST está fora do intervalo (R 1–5, S 1–9, T 1–9).';

  @override
  String get learnQsoIssueMissingName => 'Envie NAME e seu nome.';

  @override
  String get learnQsoIssueWrongName => 'Esse não é seu nome neste QSO.';

  @override
  String get learnQsoIssueMissingQth => 'Envie QTH e sua localização.';

  @override
  String get learnQsoIssueWrongQth => 'Esse não é seu QTH neste QSO.';

  @override
  String get learnQsoIssueMissingAck => 'Confirme com R ou QSL.';

  @override
  String get learnQsoIssueWrongRemoteName => 'Confirme o nome do outro operador.';

  @override
  String get learnQsoIssueMissing73 => 'Inclua 73.';

  @override
  String get learnQsoIssueMissingSk => 'Encerre o contato com <SK>.';

  @override
  String learnQsoSummaryFields(int count, int total) {
    return 'Certo de primeira: $count de $total passos';
  }

  @override
  String learnQsoSummaryRepeats(int count) {
    return 'Repetições: $count';
  }

  @override
  String learnQsoSummaryHints(int count) {
    return 'Dicas: $count';
  }

  @override
  String learnQsoSummaryRhythm(int wpm) {
    return 'Sua transmissão: cerca de $wpm PPM';
  }

  @override
  String get learnQsoSummaryNote => 'Os resultados de QSO ficam separados da precisão de cópia e nunca desbloqueiam lições.';

  @override
  String get messageStatusCancelled => 'Cancelado — nunca enviado';

  @override
  String get chatMessageLearnActions => 'Ações da mensagem';

  @override
  String get chatPracticeMessage => 'Praticar esta mensagem';

  @override
  String get chatSaveAsMaterial => 'Salvar como material de treino';

  @override
  String get chatSavedAsMaterial => 'Salvo em Meus materiais';

  @override
  String get chatSaveMaterialFailed => 'Não foi possível salvar o material. Tente novamente.';

  @override
  String get chatListenOnly => 'Treino só de escuta';

  @override
  String get chatListenOnlyHidden => 'Só escuta: toque em reproduzir';

  @override
  String chatClearHistoryMaterials(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count mensagens deste chat foram salvas como material. Essas cópias ficam até você excluí-las em Aprender › Meus materiais.',
      one: '1 mensagem deste chat foi salva como material. Essa cópia fica até você excluí-la em Aprender › Meus materiais.',
    );
    return '$_temp0';
  }

  @override
  String get chatPracticeTitle => 'Prática de cópia';

  @override
  String chatPracticeUnsupported(String chars) {
    return 'Esta mensagem tem caracteres sem código Morse: $chars. Eles serão omitidos.';
  }

  @override
  String chatPracticeTrainableCount(int count) {
    return '$count símbolos podem ser praticados.';
  }

  @override
  String get chatPracticeNothingTrainable => 'Nada nesta mensagem pode ser praticado em Morse.';

  @override
  String get chatPracticeConfirm => 'Praticar o resto';

  @override
  String get chatPracticeHint => 'Dica';

  @override
  String chatPracticeHintShown(String symbols) {
    return 'Dica: $symbols …';
  }

  @override
  String get chatPracticeAssisted => 'Com ajuda: conta como prática, não para revisões nem sugestão de velocidade.';

  @override
  String chatPracticeErrors(int wrong, int missed, int extra) {
    return '$wrong errados · $missed omitidos · $extra a mais';
  }

  @override
  String chatPracticeErrorsAction(String symbols) {
    return 'Praticar erros: $symbols';
  }

  @override
  String get learnTipDahTooLongTitle => 'Traços longos demais';

  @override
  String learnTipDahTooLong(String ratio) {
    return 'Seus traços estão longos (cerca de $ratio de um ponto; meta 3). Solte ao completar três pontos.';
  }

  @override
  String learnIssueDetailDahTooLong(int offending, int total, String ratio) {
    return '$offending de $total traços longos demais (média $ratio ponto)';
  }

  @override
  String get learnRhythmTitle => 'Ritmo';

  @override
  String get learnRhythmMine => 'Meu ritmo';

  @override
  String get learnRhythmStandard => 'Ritmo padrão (velocidade alvo)';

  @override
  String learnRhythmNormalizedNote(int ms) {
    return 'Os problemas são julgados pelo seu próprio ponto ($ms ms); regular mas lento está ok. A faixa padrão é a velocidade alvo.';
  }

  @override
  String get learnRhythmNotLocated => 'Não foi possível associar suas marcas a símbolos. Pratique o alvo inteiro.';

  @override
  String get learnRhythmPlayMine => 'Tocar o meu';

  @override
  String get learnRhythmPlayStandard => 'Tocar padrão';

  @override
  String learnRhythmPracticePart(int count) {
    return 'Praticar isto ($count tentativas)';
  }

  @override
  String get learnRhythmPracticeWhole => 'Praticar o alvo inteiro';

  @override
  String get learnRhythmSymbolOk => 'Bom';

  @override
  String get learnRhythmZoomIn => 'Ampliar';

  @override
  String get learnRhythmZoomOut => 'Reduzir';

  @override
  String get chatSearchMessages => 'Pesquisar mensagens';

  @override
  String get chatSearchHint => 'Pesquisar nesta conversa';

  @override
  String get chatSearchAnyone => 'Todos';

  @override
  String get chatSearchMe => 'Eu';

  @override
  String get chatSearchThem => 'A outra pessoa';

  @override
  String get chatSearchAnyDate => 'Qualquer data';

  @override
  String chatSearchDateRange(String from, String to) {
    return '$from – $to';
  }

  @override
  String get chatSearchBookmarked => 'Favoritos';

  @override
  String get chatSearchNoResults => 'Nenhuma mensagem correspondente.';

  @override
  String get chatSearchMore => 'Carregar mais';

  @override
  String get chatAddBookmark => 'Favoritar';

  @override
  String get chatRemoveBookmark => 'Remover dos favoritos';

  @override
  String get chatBookmarked => 'Favoritado';

  @override
  String get chatBookmarkFailed => 'Não foi possível salvar o favorito.';

  @override
  String get chatRetrySend => 'Tentar enviar de novo';

  @override
  String get chatCancelSend => 'Cancelar envio';

  @override
  String get chatRetryQueued => 'Na fila de novo. Será enviada quando o contato estiver online.';

  @override
  String get chatSendCancelled => 'Cancelado. A mensagem nunca foi enviada.';

  @override
  String get chatRetryNotNeeded => 'Esta mensagem não está mais com falha.';

  @override
  String get chatCancelTooLate => 'Tarde demais: a mensagem já saiu e pode chegar.';

  @override
  String get chatSendControlUnavailable => 'Indisponível para esta mensagem.';

  @override
  String get chatSendControlFailed => 'Não funcionou. A mensagem mantém o estado; tente novamente.';

  @override
  String get workbenchTitle => 'Bancada de gravações';

  @override
  String get workbenchOpen => 'Gravações';

  @override
  String get workbenchImport => 'Importar gravação';

  @override
  String get workbenchEmpty => 'Importe uma gravação WAV para repetir, decodificar e copiar. Não precisa de microfone.';

  @override
  String get workbenchFormats => 'WAV, PCM de 16 bits, mono ou estéreo, 8/16/44,1/48 kHz; até 50 MB e 20 minutos.';

  @override
  String get workbenchBackupNote => 'As gravações ficam neste dispositivo e não entram no backup da identidade, a menos que você opte por incluí-las ao exportar. Títulos, notas e posições das seleções salvas sempre entram no backup.';

  @override
  String workbenchInfo(String rate, String channels, String duration) {
    return '$rate kHz · $channels · $duration';
  }

  @override
  String get workbenchMono => 'mono';

  @override
  String get workbenchStereo => 'estéreo';

  @override
  String get workbenchTruncated => 'O arquivo termina antes; só o áudio presente é usado.';

  @override
  String get workbenchErrorNotWav => 'Este não é um arquivo WAV.';

  @override
  String get workbenchErrorFormat => 'Por enquanto só WAV PCM de 16 bits é suportado (sem MP3, AAC ou WAV float).';

  @override
  String get workbenchErrorChannels => 'Só gravações mono ou estéreo são suportadas.';

  @override
  String get workbenchErrorRate => 'Taxa de amostragem não suportada. Use 8, 16, 44,1 ou 48 kHz.';

  @override
  String get workbenchErrorDamaged => 'O arquivo está danificado ou incompleto.';

  @override
  String get workbenchErrorTooLarge => 'O arquivo tem mais de 50 MB.';

  @override
  String get workbenchErrorTooLong => 'A gravação tem mais de 20 minutos.';

  @override
  String get workbenchErrorIo => 'Não foi possível ler o arquivo.';

  @override
  String get workbenchErrorMissing => 'O arquivo da gravação está faltando.';

  @override
  String get workbenchStart => 'Início (s)';

  @override
  String get workbenchEnd => 'Fim (s)';

  @override
  String get workbenchSelectAll => 'Selecionar tudo';

  @override
  String get workbenchPlay => 'Tocar seleção';

  @override
  String get workbenchStop => 'Parar';

  @override
  String get workbenchLoop => 'Repetir';

  @override
  String get workbenchPlayLimit => 'Só os primeiros 5 minutos de uma seleção maior são tocados.';

  @override
  String get workbenchAutoTune => 'Encontrar o tom automaticamente';

  @override
  String workbenchManualTone(int hz) {
    return 'Tom: $hz Hz';
  }

  @override
  String get workbenchDecode => 'Decodificar seleção';

  @override
  String get workbenchCancel => 'Cancelar';

  @override
  String workbenchDecoding(int percent) {
    return 'Decodificando… $percent%';
  }

  @override
  String workbenchResultStats(int hz, int wpm) {
    return 'Tom $hz Hz · cerca de $wpm PPM';
  }

  @override
  String get workbenchToneNotLocked => 'Nenhum tom estável; tente o ajuste manual.';

  @override
  String get workbenchNoText => 'Nada decodificado nesta seleção.';

  @override
  String workbenchUnknown(String patterns) {
    return 'Padrões desconhecidos: $patterns';
  }

  @override
  String get workbenchEdgeCut => 'Um símbolo na borda da seleção está cortado e pode estar errado.';

  @override
  String get workbenchToneNote => 'Travar o tom não é uma medida de confiança; confira o texto de ouvido.';

  @override
  String get workbenchModeDecoder => 'Decodificador';

  @override
  String get workbenchModeCopy => 'Copiar eu mesmo';

  @override
  String get workbenchDecoderHidden => 'O texto do decodificador fica oculto enquanto você copia.';

  @override
  String get workbenchShowDecoder => 'Mostrar texto do decodificador';

  @override
  String get workbenchReference => 'Texto de referência (opcional)';

  @override
  String get workbenchReferenceHelp => 'Cole o texto enviado; caso contrário, sua cópia é comparada com a saída do decodificador.';

  @override
  String get workbenchAgainstDecoder => 'Comparado com a saída do decodificador, que também pode estar errada.';

  @override
  String get workbenchSave => 'Salvar seleção';

  @override
  String get workbenchSaveTitle => 'Título';

  @override
  String get workbenchSaveNote => 'Nota';

  @override
  String get workbenchSaved => 'Seleção salva';

  @override
  String get workbenchSaveFailed => 'Não foi possível salvar a seleção.';

  @override
  String get workbenchLibrary => 'Seleções salvas';

  @override
  String get workbenchLibraryEmpty => 'Nenhuma seleção salva ainda.';

  @override
  String get workbenchMissing => 'Arquivo faltando — escolha-o de novo ou exclua a entrada.';

  @override
  String get workbenchRelink => 'Escolher o arquivo de novo';

  @override
  String get workbenchDelete => 'Excluir';

  @override
  String get materialsTitle => 'Meus materiais';

  @override
  String get materialsNew => 'Novo material';

  @override
  String get materialsEdit => 'Editar';

  @override
  String get materialsSave => 'Salvar';

  @override
  String get materialsSaveFailed => 'Não foi possível salvar o material.';

  @override
  String get materialsTitleField => 'Título';

  @override
  String get materialsTagsField => 'Tags';

  @override
  String get materialsTagsHelper => 'Separe as tags com vírgulas';

  @override
  String get materialsTextField => 'Texto';

  @override
  String get materialsListField => 'Uma entrada por linha';

  @override
  String get materialsKindText => 'Texto';

  @override
  String get materialsKindWords => 'Lista de palavras';

  @override
  String get materialsKindCallsigns => 'Indicativos';

  @override
  String get materialsPreview => 'Prévia';

  @override
  String materialsPreviewCounts(int items, int symbols, int prosigns) {
    return '$items itens · $symbols símbolos · $prosigns prossinais';
  }

  @override
  String materialsPreviewUnsupported(String chars) {
    return 'Sem código Morse, omitidos na prática: $chars';
  }

  @override
  String materialsPreviewDuplicates(int count) {
    return '$count entradas duplicadas são mantidas uma vez';
  }

  @override
  String get materialsProblemEmpty => 'Digite algum texto primeiro.';

  @override
  String get materialsProblemTooLarge => 'Grande demais: o limite é 1 MiB.';

  @override
  String materialsProblemTooManyEntries(int count) {
    return 'Entradas demais: no máximo $count.';
  }

  @override
  String materialsProblemEntryTooLong(int count) {
    return 'Uma entrada é longa demais: no máximo $count símbolos.';
  }

  @override
  String get materialsProblemNothingTrainable => 'Nada aqui pode ser praticado em Morse.';

  @override
  String get materialsSearch => 'Pesquisar materiais';

  @override
  String get materialsFavoritesOnly => 'Favoritos';

  @override
  String get materialsFavorite => 'Adicionar aos favoritos';

  @override
  String get materialsUnfavorite => 'Remover dos favoritos';

  @override
  String get materialsEmpty => 'Ainda não há materiais. Adicione seus textos, listas ou indicativos, ou salve uma mensagem do chat.';

  @override
  String materialsItems(int count) {
    return '$count itens';
  }

  @override
  String get materialsFromChat => 'Do chat';

  @override
  String get materialsActions => 'Ações';

  @override
  String get materialsPractise => 'Praticar';

  @override
  String get materialsDelete => 'Excluir';

  @override
  String get materialsDeleteTitle => 'Excluir material?';

  @override
  String materialsDeleteBody(String title) {
    return '“$title” será removido deste dispositivo. Seu histórico permanece.';
  }

  @override
  String get materialsImport => 'Importar TXT ou JSON';

  @override
  String get materialsImportDialogTitle => 'Escolha um arquivo';

  @override
  String get materialsSaveDialogTitle => 'Salvar material';

  @override
  String get materialsImportFailed => 'Falha na importação. Sua biblioteca não mudou.';

  @override
  String get materialsImportNotUtf8 => 'Somente arquivos de texto UTF-8 podem ser importados.';

  @override
  String get materialsImportInvalid => 'Não é um arquivo de materiais do DitMesh válido. Nada foi importado.';

  @override
  String materialsImported(int count) {
    return '$count materiais importados.';
  }

  @override
  String get materialsDuplicateTitle => 'Alguns materiais já existem';

  @override
  String get materialsDuplicateOverwrite => 'Substituir';

  @override
  String get materialsDuplicateKeepCopy => 'Manter ambos (como cópia)';

  @override
  String get materialsDuplicateSkip => 'Ignorar';

  @override
  String get materialsExportJson => 'Exportar como JSON';

  @override
  String materialsExported(int count) {
    return '$count materiais exportados.';
  }

  @override
  String get materialsExportFailed => 'Falha na exportação.';

  @override
  String get materialsExportWav => 'Exportar áudio (WAV)';

  @override
  String materialsWavCharSpeed(int wpm) {
    return 'Velocidade dos caracteres: $wpm PPM';
  }

  @override
  String materialsWavEffSpeed(int wpm) {
    return 'Velocidade efetiva: $wpm PPM';
  }

  @override
  String materialsWavTone(int hz) {
    return 'Tom: $hz Hz';
  }

  @override
  String get materialsWavWithAnswer => 'Incluir o texto da resposta (.txt)';

  @override
  String get materialsWavFormat => 'WAV mono de 16 bits, 48 kHz.';

  @override
  String materialsWavParts(int count) {
    return 'Mais de 10 minutos: exportado em $count arquivos.';
  }

  @override
  String materialsWavExported(int count) {
    return '$count arquivos de áudio salvos.';
  }

  @override
  String get materialsPracticeMode => 'Praticar com';

  @override
  String get materialsPracticeLearned => 'Somente símbolos aprendidos';

  @override
  String materialsPracticeLearnedPartial(int count) {
    return 'Somente símbolos aprendidos ($count entradas indisponíveis: usam símbolos ainda não aprendidos)';
  }

  @override
  String get materialsPracticeAll => 'Todos os símbolos Morse';

  @override
  String get materialsPracticeNothing => 'Nenhuma entrada pode ser praticada neste modo.';

  @override
  String get guestTryLearning => 'Experimentar aprender primeiro';

  @override
  String get guestBanner => 'Modo convidado: o progresso fica neste dispositivo. O chat precisa de uma identidade.';

  @override
  String get guestGetIdentity => 'Configurar identidade';

  @override
  String get guestIdentityTitle => 'Identidade necessária';

  @override
  String get guestIdentityBody => 'Conversar pelo Tox requer sua própria identidade. Crie uma nova, restaure um backup ou desbloqueie a deste dispositivo. Seu progresso como convidado passa automaticamente para uma identidade nova.';

  @override
  String get guestClearData => 'Apagar dados de convidado';

  @override
  String get guestClearDataBody => 'Apaga o progresso, planos e materiais criados como convidado neste dispositivo. Identidades não são afetadas.';

  @override
  String get guestClearConfirm => 'Apagar';

  @override
  String get guestCleared => 'Dados de convidado apagados.';

  @override
  String get guestClearFailed => 'Não foi possível apagar os dados.';

  @override
  String get guestMigrationFailed => 'Sua identidade está pronta, mas o progresso de convidado ainda não foi movido. Ele está seguro neste dispositivo.';

  @override
  String get guestChoiceBody => 'Você também tem progresso de convidado. O progresso da identidade restaurada está em uso; nada foi mesclado.';

  @override
  String get guestChoiceKeep => 'Manter o restaurado';

  @override
  String get guestChoiceUseGuest => 'Usar o progresso de convidado';

  @override
  String get placementTitle => 'Verificar meu nível';

  @override
  String get placementCheckLevel => 'Verificar meu nível atual';

  @override
  String get placementFromZero => 'Começar do zero';

  @override
  String get placementOfferTitle => 'Novo no Morse ou já copia?';

  @override
  String get placementOfferBody => 'Um teste curto pode sugerir por onde começar. É opcional e nada muda até você escolher.';

  @override
  String get placementIntro => 'Cerca de 3–5 minutos de cópia em cinco etapas: símbolos Koch em grupos com velocidade crescente e depois palavras curtas. É uma referência aproximada com poucas amostras, não um certificado. Pare quando quiser.';

  @override
  String get placementStart => 'Começar';

  @override
  String get placementSkip => 'Pular';

  @override
  String get placementStop => 'Parar';

  @override
  String placementTierProgress(int step, int total, int wpm) {
    return 'Etapa $step de $total · $wpm PPM efetivas';
  }

  @override
  String get placementTierPassed => 'Bem copiado. A próxima etapa é mais rápida.';

  @override
  String get placementTierStopped => 'Essa etapa ficou abaixo de 90%, o teste termina aqui.';

  @override
  String get placementNextTier => 'Próxima etapa';

  @override
  String placementSuggestion(int lesson) {
    return 'Início sugerido: lição $lesson';
  }

  @override
  String placementVerified(int count, int total) {
    return '$count de $total símbolos Koch confirmados em ordem.';
  }

  @override
  String get placementLimits => 'Baseado em uma amostra curta: símbolos não testados continuam não testados e nada é marcado como aprendido. Você pode mudar a lição quando quiser.';

  @override
  String placementAdopt(int lesson) {
    return 'Começar na lição $lesson';
  }

  @override
  String get chatJumpToLatest => 'Mensagens mais recentes';

  @override
  String get chatMessageGone => 'Essa mensagem não está mais nesta conversa.';

  @override
  String get chatListenOnlyPreview => 'Nova mensagem — ouça para copiá-la';

  @override
  String get chatSaveMaterialConfirm => 'Salvar o resto';

  @override
  String materialsImportConfirm(int count) {
    return 'Importar $count materiais?';
  }

  @override
  String get materialsExportTxt => 'Exportar como texto (TXT)';

  @override
  String get accountBackupMediaTitle => 'Incluir as gravações salvas?';

  @override
  String accountBackupMediaBody(int count, String size) {
    return '$count gravações salvas ($size MB). Títulos, notas e posições sempre entram no backup; o áudio só se você incluir.';
  }

  @override
  String accountBackupMediaTooLarge(String size) {
    return 'As gravações salvas ($size MB) são grandes demais para o backup; só títulos, notas e posições entram.';
  }

  @override
  String get accountBackupMediaInclude => 'Incluir gravações';

  @override
  String get accountBackupMediaSkip => 'Sem gravações';

  @override
  String get diagTitle => 'Diagnóstico de conexão';

  @override
  String get diagOpenSubtitle => 'Por que há mensagens aguardando e como reconectar';

  @override
  String get diagBannerDetails => 'Detalhes';

  @override
  String get diagSummaryNoIdentity => 'Nenhuma identidade está aberta, então não há conexão para verificar.';

  @override
  String get diagSummaryOnlinePeerOnline => 'Você está conectado à rede Tox e este contato está online. As mensagens chegam diretamente.';

  @override
  String get diagSummaryOnlinePeerOffline => 'Você está conectado, mas este contato está offline. As mensagens aguardam na caixa de saída deste dispositivo e são enviadas quando o contato ficar online.';

  @override
  String get diagSummaryOnline => 'Você está conectado à rede Tox.';

  @override
  String get diagSummaryConnecting => 'Conectando à rede Tox. Pode levar um minuto após iniciar o app ou trocar de rede.';

  @override
  String get diagSummaryOffline => 'Você não está conectado à rede Tox. Nada pode ser enviado ou recebido até a conexão voltar.';

  @override
  String get diagLocalLabel => 'Sua conexão';

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
    return 'Observado desde a volta ao app às $time';
  }

  @override
  String get diagLastOnlineLabel => 'Última conexão observada';

  @override
  String get diagLastOnlineNow => 'Conectado agora';

  @override
  String get diagLastOnlineNone => 'Nenhuma conexão observada ainda.';

  @override
  String get diagLastOnlineHint => 'Quando este dispositivo viu sua própria conexão pela última vez. Não é quando uma mensagem chegou a alguém.';

  @override
  String get diagPeerLabel => 'Contato';

  @override
  String get diagUnknown => 'Desconhecido';

  @override
  String get diagPeerUnknownHint => 'A presença de um contato só pode ser vista enquanto você está conectado.';

  @override
  String get diagPeerGroupHint => 'A presença dos membros aparece na lista de membros.';

  @override
  String get diagPendingLabel => 'Aguardando envio';

  @override
  String get diagPendingNone => 'Nada aguardando';

  @override
  String diagPendingCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count mensagens',
      one: '1 mensagem',
    );
    return '$_temp0';
  }

  @override
  String diagPendingOldest(String time) {
    return 'A mais antiga, na fila desde $time';
  }

  @override
  String get diagPendingUnknown => 'Desconhecido até o chat conectar';

  @override
  String get diagPendingHint => 'As mensagens na fila ficam neste dispositivo e são enviadas automaticamente quando o contato estiver acessível. O diagnóstico nunca as descarta nem reenvia.';

  @override
  String get diagReconnect => 'Reconectar';

  @override
  String get diagReconnecting => 'Reconectando…';

  @override
  String diagReconnectFailed(String reason) {
    return 'Falha ao reconectar: $reason';
  }

  @override
  String get diagReconnectNote => 'Reconectar reinicia a tentativa de conexão. Ainda pode demorar para ficar online; esta página é atualizada quando isso acontecer.';

  @override
  String get diagAboutTitle => 'Como o DitMesh se conecta';

  @override
  String get diagAboutBody => 'O DitMesh não tem servidor. Seu dispositivo fala diretamente com seus contatos pela rede ponto a ponto Tox, então ambos precisam estar online ao mesmo tempo para a mensagem chegar. Celulares pausam apps em segundo plano: ali o DitMesh não consegue continuar conectado e reconecta quando você volta.';

  @override
  String get diagDetailsTitle => 'Detalhes técnicos';

  @override
  String get diagDetailIdentity => 'Identidade';

  @override
  String get diagDetailStatus => 'Estado';

  @override
  String get diagDetailObserved => 'Observado em';

  @override
  String get diagDetailQueued => 'Itens na fila';

  @override
  String get diagDetailError => 'Último código de erro';

  @override
  String get backupXTitle => 'Backup criptografado';

  @override
  String get backupXIntro => 'Escolha o que levar para outro dispositivo. O arquivo inteiro é criptografado com uma frase-senha definida aqui.';

  @override
  String get backupXCategoryIdentity => 'Identidade e perfil Tox';

  @override
  String get backupXCategoryTraining => 'Progresso e materiais de treino';

  @override
  String get backupXCategoryChat => 'Histórico de conversas, incluindo notas para mim';

  @override
  String get backupXCategoryMeta => 'Rascunhos, fixados e favoritos';

  @override
  String get backupXCategoryPrefs => 'Preferências do app';

  @override
  String get backupXPrefsHint => 'Reprodução, notificações, aparência e idioma. Nunca posições de janela nem atribuições de teclas.';

  @override
  String get backupXCategoryMedia => 'Gravações salvas';

  @override
  String get backupXMediaHint => 'Desligado por padrão: gravações podem ser grandes. Sem elas, só títulos e notas vão junto.';

  @override
  String get backupXCategoryPending => 'Mensagens não enviadas';

  @override
  String get backupXPendingHint => 'Voltam só para revisão e nunca são enviadas automaticamente.';

  @override
  String get backupXRequired => 'Obrigatório';

  @override
  String backupXSizeLine(int count, String size) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count itens',
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
    return 'Grande demais para incluir ($size)';
  }

  @override
  String backupXInvitesNote(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count convites de grupo aguardando amigos offline não são levados.',
      one: '1 convite de grupo aguardando um amigo offline não é levado.',
    );
    return '$_temp0';
  }

  @override
  String get backupXIdentityPasswordNote => 'A senha da sua identidade continua no perfil: o novo dispositivo vai pedi-la além da frase-senha do backup.';

  @override
  String backupXTotal(String size) {
    return 'Cerca de $size no total';
  }

  @override
  String get backupXPassphrase => 'Frase-senha do backup';

  @override
  String get backupXPassphraseConfirm => 'Repita a frase-senha';

  @override
  String get backupXPassphraseHint => 'Pelo menos 8 caracteres. É separada da senha da sua identidade e não pode ser recuperada.';

  @override
  String get backupXPassphraseTooShort => 'Use pelo menos 8 caracteres';

  @override
  String get backupXPassphraseMismatch => 'As frases-senha não coincidem';

  @override
  String get backupXExport => 'Criar backup criptografado';

  @override
  String get backupXExporting => 'Criando backup…';

  @override
  String get backupXMigrationNote => 'Mudando de dispositivo? Depois de restaurar lá, pare de usar esta identidade aqui: dois dispositivos com a mesma identidade podem enviar a mesma mensagem duas vezes.';

  @override
  String get backupXBusy => 'Seus dados mudaram durante o backup. Tente novamente.';

  @override
  String get backupXTooLarge => 'O backup é grande demais. Deixe as gravações de fora e tente novamente.';

  @override
  String get restoreXWrongPassphrase => 'Frase-senha errada, ou o arquivo foi alterado ou está incompleto.';

  @override
  String get restoreXUnsupported => 'Este backup foi feito por uma versão mais nova do DitMesh.';

  @override
  String get restoreXCheck => 'Abrir backup';

  @override
  String get restoreXPreviewTitle => 'Conteúdo do backup';

  @override
  String restoreXCreated(String date) {
    return 'Criado em $date';
  }

  @override
  String get restoreXIncluded => 'Incluído';

  @override
  String get restoreXExcluded => 'Não está neste backup';

  @override
  String restoreXPendingIncluded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count mensagens não enviadas voltam para revisão. Elas não serão enviadas automaticamente.',
      one: '1 mensagem não enviada volta para revisão. Ela não será enviada automaticamente.',
    );
    return '$_temp0';
  }

  @override
  String restoreXPendingExcluded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count mensagens não enviadas do dispositivo antigo não estão neste backup.',
      one: '1 mensagem não enviada do dispositivo antigo não está neste backup.',
    );
    return '$_temp0';
  }

  @override
  String get restoreXIdentityPassword => 'Senha da identidade';

  @override
  String get restoreXIdentityPasswordNote => 'A identidade deste backup tem senha própria. Digite-a também.';

  @override
  String get restoreXConfirmTitle => 'Substituir a identidade deste dispositivo?';

  @override
  String get restoreXConfirmBody => 'A identidade e os dados deste dispositivo são substituídos pelo backup. Pare de usar a identidade no dispositivo antigo antes de conectar aqui.';

  @override
  String get restoreXConfirm => 'Substituir e restaurar';

  @override
  String get restoreXReportTitle => 'Restauração concluída';

  @override
  String get restoreXReportRestored => 'Restaurado';

  @override
  String get restoreXReportNotIncluded => 'Não restaurado';

  @override
  String get restoreXReportPrefsFailed => 'Não foi possível aplicar as preferências; as anteriores foram mantidas.';

  @override
  String restoreXReportPendingReview(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count mensagens não enviadas aguardam sua revisão no Chat.',
      one: '1 mensagem não enviada aguarda sua revisão no Chat.',
    );
    return '$_temp0';
  }

  @override
  String restoreXReportPendingNotResumed(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count mensagens não enviadas do dispositivo antigo não foram trazidas.',
      one: '1 mensagem não enviada do dispositivo antigo não foi trazida.',
    );
    return '$_temp0';
  }

  @override
  String restoreXReportInvites(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count convites de grupo na fila não foram reenviados.',
      one: '1 convite de grupo na fila não foi reenviado.',
    );
    return '$_temp0';
  }

  @override
  String get restoreXReportStopOld => 'Pare de usar esta identidade no dispositivo antigo.';

  @override
  String get restoreXReportDone => 'Concluído';

  @override
  String pendingReviewBanner(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count mensagens não enviadas do seu dispositivo anterior',
      one: '1 mensagem não enviada do seu dispositivo anterior',
    );
    return '$_temp0';
  }

  @override
  String get pendingReviewTitle => 'Mensagens não enviadas';

  @override
  String get pendingReviewBody => 'Estas aguardavam envio no seu dispositivo anterior. O DitMesh nunca as envia automaticamente; manipule uma de novo se ainda importar.';

  @override
  String pendingReviewQueuedAt(String time) {
    return 'Na fila desde $time no dispositivo anterior';
  }

  @override
  String get pendingReviewDismiss => 'Descartar';

  @override
  String get pendingReviewDismissAll => 'Descartar tudo';

  @override
  String get pendingReviewEmpty => 'Nada mais para revisar.';

  @override
  String get backupXWizardInside => 'O arquivo de backup é criptografado por inteiro com uma frase-senha escolhida por você e contém a chave da sua identidade e seu progresso. Guarde o arquivo e a frase em um lugar seguro, fora deste dispositivo.';

  @override
  String get backupXMeSubtitle => 'Um arquivo criptografado com sua identidade, conversas e progresso, para guardar ou levar a outro dispositivo';

  @override
  String get conditionsTitle => 'Condições';

  @override
  String get conditionsClear => 'Limpo';

  @override
  String get conditionsLight => 'Interferência leve';

  @override
  String get conditionsRadio => 'Prática de rádio';

  @override
  String get conditionsClearHint => 'Um tom limpo e estável: prática normal.';

  @override
  String get conditionsLightHint => 'Ruído de fundo suave e desvanecimento leve. Os resultados ficam separados da prática limpa.';

  @override
  String get conditionsRadioHint => 'Ruído, desvanecimento forte, uma estação vizinha e ritmo um pouco irregular. Os resultados ficam separados da prática limpa.';

  @override
  String get conditionsPreview => 'Ouvir';

  @override
  String conditionsActive(String name) {
    return 'Condições: $name';
  }

  @override
  String get conditionsNeedSound => 'Condições de rádio se ouvem, não se veem: ative o som nos ajustes de treino ou pratique com condições limpas.';

  @override
  String get conditionsCleanReplay => 'Tocar sem efeitos';

  @override
  String conditionsComparable(int count, int accuracy) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tentativas nestas condições e velocidade: média de $accuracy%',
      one: '1 tentativa nestas condições e velocidade: $accuracy%',
    );
    return '$_temp0';
  }

  @override
  String get conditionsSeparateNote => 'A prática com condições de rádio conta como atividade, mas não muda suas lições, revisões nem a recomendação de velocidade.';

  @override
  String get keysTitle => 'Teclas e manipuladores externos';

  @override
  String get keysMeSubtitle => 'Atribuição de teclas, paletas e adaptadores USB';

  @override
  String get keysIntro => 'Escolha quais teclas manipulam Morse. Adaptadores USB de manipulador e paletas que emulam teclado funcionam como um: defina as teclas aqui. O app não sabe qual dispositivo enviou uma tecla, então um perfil é um conjunto de atribuições.';

  @override
  String get keysStandardProfile => 'Padrão';

  @override
  String get keysUnnamed => 'Perfil sem nome';

  @override
  String get keysEdit => 'Editar';

  @override
  String get keysNewProfile => 'Novo perfil';

  @override
  String get keysLimitations => 'Manipuladores MIDI, seriais e Bluetooth, ajustes de firmware de adaptadores e controle de transmissor não são suportados. Os adaptadores testados estão na documentação.';

  @override
  String get keysEditTitle => 'Perfil de teclas';

  @override
  String get keysName => 'Nome do perfil';

  @override
  String get keysActionStraight => 'Manipulador vertical';

  @override
  String get keysActionDit => 'Paleta de ponto';

  @override
  String get keysActionDah => 'Paleta de traço';

  @override
  String get keysPressKey => 'Pressione uma tecla…';

  @override
  String get keysNone => 'Não definido';

  @override
  String get keysSet => 'Definir';

  @override
  String keysReserved(String key) {
    return '$key é reservada pelo sistema ou pelo app; escolha outra tecla.';
  }

  @override
  String keysConflict(String key, String action) {
    return '$key já é usada para $action.';
  }

  @override
  String keysConflictSave(String keys) {
    return 'Cada tecla só pode fazer uma coisa: $keys está atribuída duas vezes.';
  }

  @override
  String get keysMissing => 'Defina as teclas que este modo precisa (as duas paletas no iâmbico).';

  @override
  String get keysSwapPaddles => 'Inverter paletas (canhoto)';

  @override
  String get keysKeyerMode => 'Modo do manipulador';

  @override
  String get keysIambicA => 'Iâmbico A';

  @override
  String get keysIambicB => 'Iâmbico B';

  @override
  String get keysAdapterKeyer => 'O adaptador gera os próprios elementos';

  @override
  String get keysAdapterKeyerHint => 'Para adaptador com manipulador próprio: suas pressões temporizadas são usadas como estão, sem um segundo manipulador iâmbico no app.';

  @override
  String get keysAppSidetone => 'Tom local do app ao manipular';

  @override
  String get keysAppSidetoneHint => 'Desligue quando o adaptador gerar o próprio tom. A decodificação não é afetada.';

  @override
  String get keysTestTitle => 'Teste';

  @override
  String get keysTestNote => 'Só teste: nada é enviado nem somado ao seu treino.';

  @override
  String get keysTestRelease => 'Soltar teclas';

  @override
  String get keysAdapterActive => 'O manipulador do adaptador é usado: as teclas de paleta agem como manipulador vertical.';

  @override
  String keysHintCustom(String keys) {
    return 'Teclas: $keys';
  }

  @override
  String get telegraphTitle => 'Código telegráfico chinês';

  @override
  String get telegraphIntro => 'Cada caractere chinês é enviado como um código de quatro dígitos. Pratique ouvir os dígitos e, separadamente, lembrar qual código corresponde a cada caractere.';

  @override
  String get telegraphCodebook => 'Livro de códigos';

  @override
  String get telegraphCodebookMainland => 'China continental';

  @override
  String get telegraphCodebookTaiwan => 'Taiwan';

  @override
  String get telegraphDigitsTitle => 'Copiar grupos de código';

  @override
  String get telegraphDigitsHint => 'Ouça grupos de quatro dígitos de códigos reais e digite os dígitos.';

  @override
  String telegraphDigitsResults(int count, int accuracy) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sessões: $accuracy% dos dígitos',
      one: '1 sessão: $accuracy% dos dígitos',
    );
    return '$_temp0';
  }

  @override
  String get telegraphRecallTitle => 'Lembrar códigos';

  @override
  String get telegraphRecallHint => 'De caractere para código e de código para caractere. Separado do progresso em Morse.';

  @override
  String telegraphRecallResults(int count, int accuracy) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count cartões respondidos: $accuracy% sabido',
      one: '1 cartão respondido: $accuracy% sabido',
    );
    return '$_temp0';
  }

  @override
  String get telegraphSeparateNote => 'Lembrar códigos nunca desbloqueia lições de Morse nem muda a recomendação de velocidade; copiar dígitos conta como qualquer cópia em Morse.';

  @override
  String get telegraphRecallCharPrompt => 'Digite o código deste caractere';

  @override
  String get telegraphRecallCodePrompt => 'Escolha o caractere deste código';

  @override
  String get telegraphReveal => 'Ver resposta';

  @override
  String get telegraphRevealAssisted => 'Mostrada: este cartão conta como assistido.';

  @override
  String get telegraphCorrect => 'Correto';

  @override
  String get telegraphIncorrect => 'Não exatamente';

  @override
  String telegraphRecallSummary(int correct, int total) {
    return '$correct de $total sabidas';
  }

  @override
  String telegraphRecallAssisted(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count cartões com a resposta mostrada',
      one: '1 cartão com a resposta mostrada',
    );
    return '$_temp0';
  }

  @override
  String get telegraphInterpretAction => 'Interpretar como código telegráfico chinês';

  @override
  String get telegraphInterpretTitle => 'Interpretação do código telegráfico';

  @override
  String get telegraphInterpretNote => 'Só exibido aqui: a mensagem não muda e nada é enviado.';

  @override
  String get telegraphUnresolved => 'Não resolvido: nenhum caractere tem este código';

  @override
  String get telegraphMalformed => 'Não é um grupo de quatro dígitos';

  @override
  String get telegraphNotCode => 'Texto, mantido como está';

  @override
  String get telegraphAmbiguous => 'Vários caracteres compartilham este código';

  @override
  String get groupPracticeTitle => 'Prática em grupo';

  @override
  String get groupPracticeIntro => 'O instrutor manipula os exercícios no chat do grupo como de costume. Cada membro escolhe aqui uma mensagem de exercício e a copia na própria velocidade. Respostas e pontuações ficam no seu dispositivo; nada é enviado ao grupo.';

  @override
  String get groupPracticeNew => 'Nova sessão';

  @override
  String get groupPracticeTitleField => 'Título';

  @override
  String get groupPracticeCreate => 'Criar';

  @override
  String get groupPracticeInstructor => 'Instrutor';

  @override
  String get groupPracticeParticipant => 'Participante';

  @override
  String get groupPracticeInstructorHint => 'Manipule cada exercício no chat do grupo, adicione-o aqui como rodada e marque; anuncie as vezes no chat.';

  @override
  String get groupPracticeParticipantHint => 'Adicione as mensagens de exercício do instrutor como rodadas e copie cada uma aqui.';

  @override
  String get groupPracticeLocalNote => 'Apenas local: rodadas, papéis e resultados não são sincronizados com outros membros, e mensagens perdidas podem nunca chegar a todos.';

  @override
  String get groupPracticeAddRound => 'Adicionar exercício';

  @override
  String get groupPracticeNoMessages => 'Nenhuma mensagem adequada no histórico recente.';

  @override
  String get groupPracticeNotConnected => 'O histórico do grupo só fica disponível quando o chat conectar.';

  @override
  String get groupPracticeRoundOpen => 'A fazer';

  @override
  String get groupPracticeRoundDone => 'Feito';

  @override
  String get groupPracticeRoundUnavailable => 'Indisponível';

  @override
  String get groupPracticeSourceGone => 'A mensagem de exercício não está mais no histórico.';

  @override
  String get groupPracticeSourceLoading => 'Procurando a mensagem…';

  @override
  String groupPracticeAttemptResult(int accuracy, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Copiado: $accuracy% ($count tentativas)',
      one: 'Copiado: $accuracy%',
    );
    return '$_temp0';
  }

  @override
  String get groupPracticeCopy => 'Copiar';

  @override
  String get groupPracticeRemoveRound => 'Remover rodada';

  @override
  String get groupPracticeSummary => 'Resumo';

  @override
  String groupPracticeRoundsDone(int done, int total) {
    return '$done de $total rodadas feitas';
  }

  @override
  String groupPracticeUnavailableCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count rodadas indisponíveis',
      one: '1 rodada indisponível',
    );
    return '$_temp0';
  }

  @override
  String groupPracticeAccuracy(int accuracy) {
    return 'Precisão da cópia: $accuracy%';
  }

  @override
  String groupPracticeAssisted(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tentativas com ajuda',
      one: '1 tentativa com ajuda',
    );
    return '$_temp0';
  }

  @override
  String groupPracticeShareHint(int done, int total, int accuracy) {
    return 'Para compartilhar, manipule você mesmo o resultado no chat do grupo, ex.: $done/$total $accuracy%. Nada é enviado automaticamente.';
  }

  @override
  String get groupPracticeComplete => 'Encerrar sessão';

  @override
  String get groupPracticeDeleteTitle => 'Excluir esta sessão?';

  @override
  String get groupPracticeDeleteBody => 'Suas rodadas e resultados locais são removidos deste dispositivo. Seu histórico de treino e as mensagens do grupo permanecem.';

  @override
  String get conditionsAudioFailed => 'Não foi possível iniciar o áudio neste dispositivo. Pratique com condições limpas.';

  @override
  String get moderationBlock => 'Bloquear';

  @override
  String moderationBlockTitle(String name) {
    return 'Bloquear $name?';
  }

  @override
  String get moderationBlockFriendBody => 'A pessoa é removida dos seus amigos e a conversa com ela é apagada. Mensagens, solicitações de amizade e convites para grupos dela deixam de aparecer neste dispositivo. Ela não é avisada.';

  @override
  String get moderationBlockMemberBody => 'As mensagens dela neste grupo deixam de aparecer neste dispositivo. Ela não é avisada. O Tox dá a cada membro uma chave diferente em cada grupo, por isso isto vale só para este grupo.';

  @override
  String get moderationBlocked => 'Bloqueado';

  @override
  String get moderationUnblock => 'Desbloquear';

  @override
  String get moderationUnblocked => 'Desbloqueado';

  @override
  String get moderationBlockedTitle => 'Pessoas bloqueadas';

  @override
  String get moderationBlockedSubtitle => 'Mensagens, solicitações e convites ficam ocultos';

  @override
  String get moderationBlockedEmpty => 'Você não bloqueou ninguém.';

  @override
  String get moderationBlockedNote => 'O bloqueio funciona neste dispositivo: o Tox não tem servidor central, então pessoas bloqueadas ainda podem tentar falar com você, mas nada delas aparece aqui.';

  @override
  String get termsGateTitle => 'Diretrizes da comunidade';

  @override
  String get termsGateIntro => 'O chat do DitMesh conecta você diretamente a outras pessoas, sem servidor. Antes de começar, aceite estas regras:';

  @override
  String get termsGateRuleZero => 'Tolerância zero: nada de assédio, ódio, ameaças, conteúdo sexual envolvendo menores, spam ou qualquer coisa ilegal.';

  @override
  String get termsGateRuleContacts => 'Só quem você aceitar pode mandar mensagens; grupos são acessados por convite ou pelo ID do grupo.';

  @override
  String get termsGateRuleBlock => 'Bloqueie qualquer pessoa a partir de uma conversa, da lista de membros de um grupo, de uma solicitação de amizade ou de um convite.';

  @override
  String get termsGateAgree => 'Aceitar e continuar';

  @override
  String get termsGateReadFull => 'Ler os termos de uso completos';

  @override
  String get termsGateSaveFailed => 'Não foi possível salvar sua resposta. Tente de novo.';

  @override
  String get aboutPrivacyPolicy => 'Política de privacidade';

  @override
  String get aboutTermsOfUse => 'Termos de uso';

  @override
  String get aboutSupport => 'Suporte e contato';

  @override
  String get aboutLinkFailed => 'Não foi possível abrir o link, então ele foi copiado.';

  @override
  String get errorPeerBlocked => 'Você bloqueou esta pessoa. Desbloqueie-a primeiro em Eu → Pessoas bloqueadas.';

  @override
  String get offlineClearData => 'Apagar os dados de aprendizagem';

  @override
  String get offlineClearDataBody => 'Apaga o seu progresso, planos e materiais neste dispositivo.';

  @override
  String get offlineCleared => 'Dados de aprendizagem apagados.';

  @override
  String get offlineClearFailed => 'Não foi possível apagar os dados de aprendizagem.';

  @override
  String get learnStorageUnavailable => 'Não foi possível abrir os seus dados de treino neste dispositivo. Tente de novo.';

  @override
  String get backendStartupFailedTitle => 'Serviço de chat indisponível';

  @override
  String get backendStartupFailedBody => 'O DitMesh não conseguiu iniciar o serviço de rede Tox. Verifique se as bibliotecas nativas estão instaladas e tente novamente.';

  @override
  String get bootstrapTitle => 'Rede e nós de inicialização';

  @override
  String get bootstrapDescription => 'Escolha os nós públicos para entrar na rede Tox.';

  @override
  String get bootstrapModeAuto => 'Automático';

  @override
  String get bootstrapModeManual => 'Manual';

  @override
  String get bootstrapModeLan => 'Servidor LAN';

  @override
  String get bootstrapAutoDescription => 'Iniciar com nós integrados e atualizar a lista oficial em segundo plano.';

  @override
  String get bootstrapManualDescription => 'Usar apenas o nó escolhido. Também pode inserir um nó LAN aqui.';

  @override
  String get bootstrapLanDescription => 'Executar um nó UDP/DHT local neste computador para outros dispositivos LAN.';

  @override
  String get bootstrapCurrentNode => 'Nó atual';

  @override
  String get bootstrapHost => 'Host ou endereço IP';

  @override
  String get bootstrapPort => 'Porta UDP';

  @override
  String get bootstrapPublicKey => 'Chave pública DHT';

  @override
  String get bootstrapTestNode => 'Testar nó';

  @override
  String get bootstrapSaveNode => 'Usar nó testado';

  @override
  String get bootstrapChooseNode => 'Escolher nó público';

  @override
  String get bootstrapReachable => 'Resposta DHT recebida';

  @override
  String get bootstrapUnreachable => 'Sem resposta DHT';

  @override
  String get bootstrapInvalid => 'Host, porta ou chave pública inválidos';

  @override
  String get bootstrapUdpUnavailable => 'Este dispositivo não conseguiu executar o teste UDP. A ligação TCP não foi testada.';

  @override
  String get bootstrapProbeUnavailable => 'O teste não pôde iniciar. Isto não indica se o nó está acessível.';

  @override
  String get bootstrapFallback => 'Não foi possível carregar a lista oficial. A mostrar os nós de reserva integrados.';

  @override
  String get bootstrapMaintainer => 'Responsável';

  @override
  String get bootstrapLocation => 'Localização';

  @override
  String get bootstrapLastPing => 'Última verificação pública';

  @override
  String get bootstrapSwitchTitle => 'Mudar nó de inicialização';

  @override
  String get bootstrapSwitchQuestion => 'Usar este nó?';

  @override
  String get bootstrapNotTestedWarning => 'Este nó ainda não foi testado no seu dispositivo.';

  @override
  String get bootstrapFailedWarning => 'Este nó não respondeu ao teste UDP. Pode escolhê-lo na mesma.';

  @override
  String get bootstrapInconclusiveWarning => 'O teste foi inconclusivo. A ligação TCP não foi testada.';

  @override
  String get bootstrapSwitchConfirm => 'Usar nó';

  @override
  String get bootstrapRefresh => 'Atualizar lista';

  @override
  String get bootstrapStartLan => 'Iniciar nó LAN';

  @override
  String get bootstrapStopLan => 'Parar nó LAN';

  @override
  String get bootstrapLanStopped => 'Nó LAN parado';

  @override
  String get bootstrapLanRunning => 'Nó LAN ativo';

  @override
  String get bootstrapLanKeyChanges => 'A chave DHT muda ao reiniciar o nó. Partilhe a chave completa atual.';

  @override
  String get bootstrapLanFirewallHint => 'Outros dispositivos devem conseguir aceder a esta porta UDP através da firewall local.';

  @override
  String get bootstrapCopyNode => 'Copiar detalhes do nó';

  @override
  String get bootstrapShareNode => 'Partilhar detalhes do nó';

  @override
  String get bootstrapOperationFailed => 'Não foi possível aplicar a configuração de rede.';

  @override
  String get bootstrapServiceUnavailable => 'As configurações de rede não estão disponíveis para este motor.';

  @override
  String get bootstrapSource => 'Lista oficial de nós públicos';

  @override
  String get bootstrapOnline => 'Online';

  @override
  String get bootstrapOffline => 'Offline';

  @override
  String bootstrapProtocolStatus(String udp, String tcp) {
    return 'UDP: $udp · TCP: $tcp';
  }

  @override
  String get errorNotFriend => 'Esta pessoa já não está na sua lista de amigos. Adicione-a novamente para enviar mensagens.';

  @override
  String get chatAcceptWithPassword => 'Aceitar com palavra-passe';

  @override
  String chatGroupPasswordTitle(String name) {
    return 'Palavra-passe de $name';
  }

  @override
  String get chatGroupPasswordField => 'Palavra-passe do grupo';

  @override
  String chatGroupJoinRefusedPassword(String name) {
    return '$name recusou a entrada: a palavra-passe está errada ou em falta.';
  }

  @override
  String chatGroupJoinRefusedFull(String name) {
    return '$name recusou a entrada: o grupo está cheio.';
  }

  @override
  String chatGroupJoinRefused(String name) {
    return '$name recusou a entrada.';
  }

  @override
  String chatGroupReconnectRefused(String name) {
    return '$name recusou a nova ligação. O histórico mantém-se; tente novamente com a palavra-passe do grupo.';
  }

  @override
  String get firstChatTitle => 'Seu primeiro chat Morse';

  @override
  String get firstChatStart => 'Começar';

  @override
  String get firstChatDismiss => 'Fechar guia';

  @override
  String get firstChatKeyTitle => '1. Envie CQ para si';

  @override
  String get firstChatKeyBody => 'Transmita CQ com a chave: um toque curto faz um ponto e um longo faz um traço. O rascunho decodificado é somente leitura.';

  @override
  String get firstChatSelf => 'Testar no meu chat pessoal';

  @override
  String get firstChatListenTitle => '2. Ouça e corrija';

  @override
  String get firstChatListenBody => 'Antes de enviar, ouça a prévia e apague os erros. Depois, toque em Reproduzir na mensagem. Mensagens pessoais ficam neste dispositivo.';

  @override
  String get firstChatFriendTitle => '3. Converse com um amigo';

  @override
  String get firstChatFriendBody => 'Abra Contatos, adicione seu amigo por QR ou Tox ID e espere que aceite o pedido.';

  @override
  String get firstChatFriend => 'Adicionar amigo';

  @override
  String get firstChatOnline => 'Os dois aplicativos devem estar abertos e conectados para entregar mensagens.';

  @override
  String get pendingMessagesTitle => 'Mensagens pendentes e com falha';

  @override
  String get pendingMessagesExplanation => 'As mensagens ficam neste dispositivo até que os dois aplicativos estejam conectados. Você pode cancelar ou tentar novamente após uma falha confirmada.';

  @override
  String get pendingMessagesEmpty => 'Nenhuma mensagem pendente ou com falha';

  @override
  String get deliveryDetailsTitle => 'Detalhes de entrega';

  @override
  String get deliveryLocalTitle => 'Salvo localmente';

  @override
  String get deliveryLocalDetail => 'Esta mensagem pessoal está salva neste dispositivo.';

  @override
  String get deliverySentDetail => 'O aplicativo passou a mensagem ao transporte e aguarda a confirmação do destinatário.';

  @override
  String get deliveryPeerTitle => 'Recebimento confirmado';

  @override
  String get deliveryPeerDetail => 'O destinatário confirmou o recebimento. Isso não confirma leitura ou reprodução.';

  @override
  String get deliveryGroupTitle => 'Recebido por um membro';

  @override
  String get deliveryGroupDetail => 'Pelo menos um membro confirmou o recebimento. Outros ainda podem estar desconectados.';

  @override
  String get deliveryLocalOffline => 'Este dispositivo ainda não está conectado.';

  @override
  String get deliveryPeerOffline => 'Seu amigo está desconectado.';

  @override
  String get deliveryGroupWaiting => 'Aguardando conexão ao grupo.';

  @override
  String get chatPreviewDraft => 'Ouvir rascunho';

  @override
  String get chatStopPreview => 'Parar prévia';

  @override
  String get chatMessagePlayback => 'Reproduzir mensagem';

  @override
  String get chatOriginalRhythm => 'Ritmo de transmissão original';

  @override
  String get chatListenerRhythm => 'Sua velocidade de escuta';

  @override
  String get chatOriginalAvailable => 'As marcações e pausas reais foram gravadas.';

  @override
  String get chatOriginalUnavailable => 'Ritmo original indisponível; usa sua velocidade de escuta.';

  @override
  String get chatOriginalPlaying => 'Reproduzindo o ritmo original';

  @override
  String get chatListenerPlaying => 'Reproduzindo na sua velocidade';

  @override
  String get chatPause => 'Pausar';

  @override
  String get chatResume => 'Continuar';

  @override
  String get chatPreviousWord => 'Palavra anterior';

  @override
  String get chatNextWord => 'Próxima palavra';

  @override
  String chatWordNumber(int number) {
    return 'Palavra $number';
  }

  @override
  String get chatRangeStart => 'Primeira palavra';

  @override
  String get chatRangeEnd => 'Última palavra';

  @override
  String get chatRepeatRange => 'Repetir palavras selecionadas';

  @override
  String get chatLoopRange => 'Repetir em ciclo';

  @override
  String get chatPlaybackProgress => 'Progresso da reprodução';

  @override
  String chatWordProgress(int current, int total) {
    return 'Palavra $current de $total';
  }

  @override
  String get chatOriginalPreference => 'Usar o ritmo original quando houver uma gravação correspondente.';

  @override
  String chatConversationActions(String name) {
    return 'Ações para $name';
  }

  @override
  String get chatDraftSaveFailed => 'Não foi possível guardar o rascunho. Mantenha este ecrã aberto ou envie-o agora.';

  @override
  String get chatSearchClearDates => 'Limpar intervalo de datas';

  @override
  String chatGroupReconnectFailed(String name) {
    return '$name recusou a nova ligação. O histórico mantém-se; pode tentar novamente.';
  }
}
