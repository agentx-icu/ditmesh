import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ditmesh/l10n/generated/s.dart';
import 'package:ditmesh/ui/account/backup_actions.dart';
import 'package:ditmesh/ui/account/backup_file_gateway.dart';
import 'package:ditmesh/ui/theme.dart';
import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';

final S s = lookupS(const Locale('en'));

/// A backend without complete encrypted backups (F10): the legacy
/// identity + training archive path of [exportBackupWithFeedback].
final class _LegacyIdentity implements IdentityService {
  _LegacyIdentity(this.dir, {this.current});

  final String dir;
  @override
  final Identity? current;
  Object? exportError;
  final List<bool> exports = [];

  @override
  Future<String> dataDirectory() async => p.join(dir, 'data');

  @override
  Future<Uint8List> exportBackup({bool includeMedia = false}) async {
    final error = exportError;
    if (error != null) throw error;
    exports.add(includeMedia);
    return Uint8List.fromList([1, 2, 3]);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

final Identity _ann = Identity(
  toxId: '${'C' * 64}${'0' * 12}',
  displayName: 'Ann Lee!',
);

void main() {
  late Directory dir;
  late FakeBackupFileGateway gateway;
  BackupExportResult? result;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('backup_export_');
    gateway = FakeBackupFileGateway();
    result = null;
  });
  tearDown(() => dir.deleteSync(recursive: true));

  /// Saved recordings referenced by the materials document, [bytes] each.
  void saveRecordings(List<int> sizes) {
    final materials = File(p.join(dir.path, 'data', BackupMedia.materialsDoc))
      ..createSync(recursive: true);
    materials.writeAsStringSync(
      jsonEncode({
        'materials': [
          for (var i = 0; i < sizes.length; i++)
            {'file': 'media/recordings/r$i.wav'},
        ],
      }),
    );
    for (var i = 0; i < sizes.length; i++) {
      final f = File(p.join(dir.path, 'media', 'recordings', 'r$i.wav'))
        ..createSync(recursive: true);
      // Sparse: the size is what counts, not the bytes.
      f.openSync(mode: FileMode.write)
        ..setPositionSync(0)
        ..truncateSync(sizes[i])
        ..closeSync();
    }
  }

  Future<void> pump(WidgetTester tester, IdentityService identity) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<IdentityService>.value(value: identity),
          Provider<BackupFileGateway>.value(value: gateway),
        ],
        child: MaterialApp(
          theme: DitmeshTheme.light(),
          localizationsDelegates: S.localizationsDelegates,
          supportedLocales: S.supportedLocales,
          locale: const Locale('en'),
          home: Scaffold(
            body: Center(
              child: Builder(
                builder: (context) => FilledButton(
                  key: const ValueKey('export'),
                  onPressed: () async {
                    result = await exportBackupWithFeedback(
                      context,
                      anchor: context,
                    );
                  },
                  child: const Text('export'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> tapExport(WidgetTester tester) async {
    await tester.tap(find.byKey(const ValueKey('export')));
    await tester.pumpAndSettle();
  }

  group('backupFileName', () {
    test('keeps a readable, file-system-safe name and the key prefix', () {
      expect(backupFileName(_ann), 'ditmesh-Ann_Lee-CCCCCCCC.mcqbackup');
      expect(
        backupFileName(Identity(toxId: _ann.toxId, displayName: '__a-b__')),
        'ditmesh-a-b-CCCCCCCC.mcqbackup',
      );
    });

    test('a name with nothing safe in it falls back to "identity"', () {
      for (final name in ['', '!!!', '张三', '   ']) {
        expect(
          backupFileName(Identity(toxId: _ann.toxId, displayName: name)),
          'ditmesh-identity-CCCCCCCC.mcqbackup',
          reason: '"$name"',
        );
      }
    });
  });

  testWidgets('no open identity: nothing exported, the user is told', (
    tester,
  ) async {
    final identity = _LegacyIdentity(dir.path);
    await pump(tester, identity);
    await tapExport(tester);
    expect(result, BackupExportResult.failed);
    expect(find.text(s.accountMeNoIdentity), findsOneWidget);
    expect(identity.exports, isEmpty);
    expect(gateway.saved, isEmpty);
  });

  testWidgets('without saved recordings the archive is saved directly', (
    tester,
  ) async {
    final identity = _LegacyIdentity(dir.path, current: _ann);
    await pump(tester, identity);
    await tapExport(tester);
    expect(find.byType(AlertDialog), findsNothing);
    expect(identity.exports, [false]);
    expect(gateway.savedNames, ['ditmesh-Ann_Lee-CCCCCCCC.mcqbackup']);
    // Anchored to the tapped control (the iPad share popover).
    final origin = gateway.shareOrigins.single!;
    expect(
      origin.center,
      tester.getCenter(find.byKey(const ValueKey('export'))),
    );
    expect(find.text(s.accountBackupSaved), findsOneWidget);
    expect(result, BackupExportResult.saved);
  });

  testWidgets('a cancelled save sheet is reported as not saved', (
    tester,
  ) async {
    gateway.saveResult = false;
    await pump(tester, _LegacyIdentity(dir.path, current: _ann));
    await tapExport(tester);
    expect(find.text(s.accountBackupNotSaved), findsOneWidget);
    expect(result, BackupExportResult.cancelled);
  });

  testWidgets('an export or save failure is reported, not thrown', (
    tester,
  ) async {
    final identity = _LegacyIdentity(dir.path, current: _ann)
      ..exportError = const ChatException('io', 'disk full');
    await pump(tester, identity);
    await tapExport(tester);
    expect(result, BackupExportResult.failed);
    expect(find.textContaining(s.accountBackupFailed), findsOneWidget);

    identity.exportError = null;
    gateway.saveError = const FileSystemException('denied');
    ScaffoldMessenger.of(
      tester.element(find.byKey(const ValueKey('export'))),
    ).clearSnackBars();
    await tester.pumpAndSettle();
    await tapExport(tester);
    expect(result, BackupExportResult.failed);
    expect(find.textContaining(s.accountBackupFailed), findsOneWidget);
  });

  testWidgets('saved recordings: include, skip or cancel', (tester) async {
    saveRecordings([1024 * 1024, 512 * 1024]);
    final identity = _LegacyIdentity(dir.path, current: _ann);
    await pump(tester, identity);

    await tapExport(tester);
    expect(find.text(s.accountBackupMediaTitle), findsOneWidget);
    expect(find.text(s.accountBackupMediaBody(2, '1.5')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('backup-include-media')));
    await tester.pumpAndSettle();
    expect(identity.exports, [true]);
    expect(result, BackupExportResult.saved);

    await tapExport(tester);
    await tester.tap(find.byKey(const ValueKey('backup-without-media')));
    await tester.pumpAndSettle();
    expect(identity.exports, [true, false]);

    await tapExport(tester);
    await tester.tap(find.text(s.actionCancel));
    await tester.pumpAndSettle();
    expect(result, BackupExportResult.cancelled);
    expect(identity.exports, [true, false], reason: 'cancel exports nothing');
    expect(gateway.saved, hasLength(2));
  });

  testWidgets('recordings over the limit can only be left out', (tester) async {
    saveRecordings([maxBackupMediaBytes + 1]);
    final identity = _LegacyIdentity(dir.path, current: _ann);
    await pump(tester, identity);
    await tapExport(tester);
    expect(find.byKey(const ValueKey('backup-include-media')), findsNothing);
    final mb = ((maxBackupMediaBytes + 1) / (1024 * 1024)).toStringAsFixed(1);
    expect(find.text(s.accountBackupMediaTooLarge(mb)), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('backup-without-media')));
    await tester.pumpAndSettle();
    expect(identity.exports, [false]);
  });

  testWidgets('recordings no longer on disk do not prompt', (tester) async {
    saveRecordings([10]);
    File(p.join(dir.path, 'media', 'recordings', 'r0.wav')).deleteSync();
    final identity = _LegacyIdentity(dir.path, current: _ann);
    await pump(tester, identity);
    await tapExport(tester);
    expect(find.byType(AlertDialog), findsNothing);
    expect(identity.exports, [false]);
  });
}
