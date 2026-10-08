// Demo data for the product screenshots: one hero identity, three friends,
// a CW QSO, a group net, a pending friend request and a week of training.
//
// Each locale is a separate copy, not just a different UI language: the
// Chinese frames show Chinese names and a Chinese group (a Chinese UI over
// English names reads as half-translated). The Morse text itself stays in CW
// abbreviations in both — that is what gets keyed on the air.
import 'dart:io';

import 'package:morse_trainer/morse_trainer.dart';
import 'package:ditmesh/training/file_trainer_store.dart';
import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';
import 'package:ditmesh_chat_api/testing.dart';

class SeedFriend {
  const SeedFriend(this.name, this.status, {this.online = false});

  final String name;
  final String status;
  final bool online;
}

/// One message; `from` indexes [SeedCopy.friends] for inbound lines.
class SeedLine {
  const SeedLine.mine(this.text) : from = null;
  const SeedLine.from(this.from, this.text);

  final int? from;
  final String text;
}

class SeedCopy {
  const SeedCopy({
    required this.locale,
    required this.heroName,
    required this.heroStatus,
    required this.friends,
    required this.qso,
    required this.groupName,
    required this.net,
    required this.requestMessage,
    required this.unreadFromSecondFriend,
  });

  final String locale;
  final String heroName;
  final String heroStatus;
  final List<SeedFriend> friends;
  final List<SeedLine> qso;
  final String groupName;
  final List<SeedLine> net;
  final String requestMessage;
  final String unreadFromSecondFriend;
}

const Map<String, SeedCopy> seedCopies = <String, SeedCopy>{
  'en': SeedCopy(
    locale: 'en',
    heroName: 'Ann',
    heroStatus: 'QRV on 40 m CW',
    friends: <SeedFriend>[
      SeedFriend('Alex Chen', 'CQ on 7.030', online: true),
      SeedFriend('Sofia Rossi', 'Koch lesson 12', online: true),
      SeedFriend('Kenta Sato', 'QRT tonight'),
    ],
    qso: <SeedLine>[
      SeedLine.from(0, 'CQ CQ CQ DE ALEX ALEX K'),
      SeedLine.mine('ALEX DE ANN GM UR RST 599 5NN K'),
      SeedLine.from(0, 'R R ANN TNX FER CALL UR RST 579 QTH SHANGHAI HW?'),
      SeedLine.mine('FB ALEX QSL 73 SK'),
    ],
    groupName: 'Weekend Net',
    net: <SeedLine>[
      SeedLine.from(0, 'NET DE ALEX QNI K'),
      SeedLine.from(1, 'QNI SOFIA 599'),
      SeedLine.mine('QNI ANN 73'),
    ],
    requestMessage: 'CQ CQ DE JORDAN',
    unreadFromSecondFriend: 'ANN DE SOFIA QRV? K',
  ),
  'zh': SeedCopy(
    locale: 'zh',
    heroName: '李安',
    heroStatus: '40 米波段 CW 守听中',
    friends: <SeedFriend>[
      SeedFriend('陈亮', '7.030 呼叫 CQ', online: true),
      SeedFriend('林小雨', '科赫第 12 课', online: true),
      SeedFriend('王浩', '今晚 QRT'),
    ],
    qso: <SeedLine>[
      SeedLine.from(0, 'CQ CQ CQ DE BG1CL BG1CL K'),
      SeedLine.mine('BG1CL DE BG2AN GM UR RST 599 5NN K'),
      SeedLine.from(0, 'R R TNX FER CALL UR RST 579 QTH SHANGHAI HW?'),
      SeedLine.mine('FB QSL 73 SK'),
    ],
    groupName: '周末通联网',
    net: <SeedLine>[
      SeedLine.from(0, 'NET DE BG1CL QNI K'),
      SeedLine.from(1, 'QNI BG3XY 599'),
      SeedLine.mine('QNI BG2AN 73'),
    ],
    requestMessage: 'CQ CQ DE BD4ZW',
    unreadFromSecondFriend: 'BG2AN DE BG3XY QRV? K',
  ),
};

SeedCopy seedCopyFor(String locale) =>
    seedCopies[locale] ?? seedCopies['en']!;

/// Deterministic 64-hex public key `n`.
String seedKey(int n) => (n.toRadixString(16).padLeft(2, '0') * 32).toUpperCase();

/// Services pre-filled from a [SeedCopy], ready for `FakeBackendFactory`.
class SeededBackend {
  SeededBackend({
    required this.identity,
    required this.chat,
    required this.copy,
    required this.groupId,
  });

  final FakeIdentityService identity;
  final FakeChatService chat;
  final SeedCopy copy;
  final String groupId;

  String get firstFriendKey => seedKey(1);
  String get qsoConversationId =>
      FakeChatService.c2cConversationId(firstFriendKey);
  String get unreadConversationId =>
      FakeChatService.c2cConversationId(seedKey(2));
  String get groupConversationId =>
      FakeChatService.groupConversationId(groupId);
}

/// How long the seeded timeline runs forward from [seedAnchor]; every
/// seeded timestamp lies within it.
const Duration kSeedSpan = Duration(minutes: 45);

/// The single moment every seeded timestamp derives from. Today at 09:12
/// whenever the whole timeline ([kSeedSpan]) after it is already past, so
/// frames captured on different days show the same clock times. In an
/// earlier run: three hours ago, pulled forward to today's midnight so the
/// lists still show today's times -- unless even that would end after [now]
/// (a run just after midnight), then three hours back. Nothing is ever in
/// the future.
DateTime seedAnchor(DateTime now) {
  final morning = DateTime(now.year, now.month, now.day, 9, 12);
  if (!morning.add(kSeedSpan).isAfter(now)) return morning;
  final back = now.subtract(const Duration(hours: 3));
  final midnight = DateTime(now.year, now.month, now.day);
  if (!back.isBefore(midnight)) return back;
  return midnight.add(kSeedSpan).isAfter(now) ? back : midnight;
}

Future<SeededBackend> buildSeed(
  SeedCopy copy, {
  required String dataDir,
  DateTime? now,
}) async {
  final anchor = seedAnchor(now ?? DateTime.now());
  final identity = FakeIdentityService.withProfile(
    identity: Identity(
      toxId: FakeIdentityService.toxIdForSeed(42),
      displayName: copy.heroName,
      statusMessage: copy.heroStatus,
    ),
    connectDelay: Duration.zero,
    dataDirectoryPath: dataDir,
  );
  // open() sets `current` so the data directory (and thus the training
  // progress file) can be seeded; the startup gate opens it again, which is
  // idempotent on the fake.
  await identity.open();
  await seedTrainingProgress(await identity.dataDirectory(), anchor: anchor);

  var clock = anchor;
  DateTime tick(int minutes) {
    clock = clock.add(Duration(minutes: minutes));
    assert(!clock.isAfter(anchor.add(kSeedSpan)), 'seed outgrew kSeedSpan');
    return clock;
  }

  final chat = FakeChatService(
    selfPublicKey: identity.current!.publicKey,
    clock: () => clock,
  );
  for (var i = 0; i < copy.friends.length; i++) {
    final f = copy.friends[i];
    chat.addFakeFriend(
      Friend(
        publicKey: seedKey(i + 1),
        displayName: f.name,
        statusMessage: f.status,
        online: f.online,
      ),
    );
  }

  final qsoId = FakeChatService.c2cConversationId(seedKey(1));
  for (final line in copy.qso) {
    final from = line.from;
    if (from == null) {
      tick(2);
      await chat.sendText(qsoId, line.text);
    } else {
      chat.receiveMessage(qsoId, line.text, timestamp: tick(3));
    }
  }
  await chat.markRead(qsoId);

  // One unread line from the second friend so the list shows a badge.
  chat.receiveMessage(
    FakeChatService.c2cConversationId(seedKey(2)),
    copy.unreadFromSecondFriend,
    timestamp: tick(4),
  );

  final group = await chat.createGroup(copy.groupName);
  for (var i = 0; i < copy.friends.length; i++) {
    chat.addFakeGroupMember(
      group.id,
      GroupMember(
        publicKey: seedKey(i + 1),
        displayName: copy.friends[i].name,
        online: copy.friends[i].online,
      ),
    );
  }
  final groupId = FakeChatService.groupConversationId(group.id);
  for (final line in copy.net) {
    final from = line.from;
    if (from == null) {
      tick(1);
      await chat.sendText(groupId, line.text);
    } else {
      chat.receiveMessage(
        groupId,
        line.text,
        senderId: seedKey(from + 1),
        senderName: copy.friends[from].name,
        timestamp: tick(2),
      );
    }
  }
  await chat.markRead(groupId);

  chat.receiveFriendRequest(seedKey(9), message: copy.requestMessage);

  return SeededBackend(
    identity: identity,
    chat: chat,
    copy: copy,
    groupId: group.id,
  );
}

/// A week of Koch practice (lesson 4, K M R S U) with a few S/U slips, so
/// the Learn home, the statistics page and the calendar have content. The
/// last receive session is at [anchor] and the send session just after it,
/// so "today" always has practice (see [seedAnchor]).
Future<void> seedTrainingProgress(
  String dataDir, {
  required DateTime anchor,
}) async {
  var progress = TrainerProgress(currentLesson: 4, dailyGoalChars: 30);
  const target = 'KMRSU SUKMR RSUMK KMRSU';
  const answers = <String>[
    'KMRSU SUKMR RSUMK KMRSU',
    'KMRSU SUKMR RSUMK KMRUU',
    'KMRSU UUKMR RSUMK KMRSU',
    'KMRSU SUKMR RSUMK KMRSU',
    'KMRSS SUKMR RSUMK KMRSU',
    'KMRSU SUKMR RSSMK KMRSU',
  ];
  for (var i = answers.length - 1; i >= 0; i--) {
    final at = anchor.subtract(Duration(days: i));
    final score = SessionScore.evaluate(
      target,
      answers[i],
      at: at,
      elapsed: const Duration(minutes: 3),
      lesson: 4,
      drillKind: 'groups',
    );
    progress = progress.recordSession(score, now: at, lesson: 4);
  }
  final sendAt = anchor.add(const Duration(minutes: 40));
  final send = SessionScore.evaluate(
    'KMRS SUK',
    'KMRS SUK',
    at: sendAt,
    elapsed: const Duration(minutes: 1),
    lesson: 4,
    drillKind: 'send',
  );
  progress = progress.recordSession(
    send,
    now: sendAt,
    lesson: 4,
    updateSrs: false,
  );
  await Directory(dataDir).create(recursive: true);
  await FileTrainerStore.inDataDirectory(dataDir).save(progress);
}
