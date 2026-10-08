import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:ditmesh_chat/src/adapters/scratch_file_adapter.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory tempRoot;
  late IdentityScratchFileService scratch;

  setUp(() async {
    tempRoot = await Directory.systemTemp.createTemp('ditmesh_scratch_');
    scratch = IdentityScratchFileService(p.join(tempRoot.path, 'scratch'));
  });

  tearDown(() async {
    if (tempRoot.existsSync()) await tempRoot.delete(recursive: true);
  });

  test('writeBytesToScratch lands under the category with the name kept', () async {
    final path = await scratch.writeBytesToScratch(
      Uint8List.fromList([1, 2, 3]),
      category: 'voice',
      suggestedFileName: 'note__dur1500.m4a',
    );
    expect(p.isWithin(scratch.rootDirectory, path), isTrue);
    expect(p.basename(path), 'note__dur1500.m4a');
    expect(path, contains('${p.separator}voice${p.separator}'));
    expect(await File(path).readAsBytes(), [1, 2, 3]);
  });

  test('the same suggested name twice never collides', () async {
    final a = await scratch.writeBytesToScratch(
      Uint8List.fromList([1]),
      category: 'c',
      suggestedFileName: 'x.bin',
    );
    final b = await scratch.writeBytesToScratch(
      Uint8List.fromList([2]),
      category: 'c',
      suggestedFileName: 'x.bin',
    );
    expect(a, isNot(b));
    expect(await File(a).readAsBytes(), [1]);
    expect(await File(b).readAsBytes(), [2]);
  });

  test('unsafe characters and path components are sanitised', () async {
    final path = await scratch.writeBytesToScratch(
      Uint8List(0),
      category: '../escape',
      suggestedFileName: r'..\..\evil:name?.txt',
    );
    expect(p.isWithin(scratch.rootDirectory, path), isTrue);
    expect(p.basename(path), isNot(matches(r'[<>:"/\\|?*]')));
    expect(p.basename(path), endsWith('.txt'));
    // No path component escapes: '..' may survive inside a file name but
    // never as a directory step.
    expect(
      p.split(p.relative(path, from: scratch.rootDirectory)),
      isNot(contains('..')),
    );
    expect(File(path).existsSync(), isTrue);
  });

  test('a blank suggested name falls back to "scratch"', () async {
    final path = await scratch.writeBytesToScratch(
      Uint8List(0),
      category: 'c',
      suggestedFileName: '   ',
    );
    expect(p.basename(path), 'scratch');
  });

  test('copyFileToScratch copies the bytes and leaves the source', () async {
    final source = File(p.join(tempRoot.path, 'src.bin'));
    await source.writeAsBytes([9, 8, 7]);
    final path = await scratch.copyFileToScratch(
      source.path,
      category: 'files',
      suggestedFileName: 'copy.bin',
    );
    expect(await File(path).readAsBytes(), [9, 8, 7]);
    expect(source.existsSync(), isTrue);
    expect(p.isWithin(scratch.rootDirectory, path), isTrue);
  });

  test('deleteScratchFile removes the file and its empty allocation directory', () async {
    final path = await scratch.writeBytesToScratch(
      Uint8List.fromList([1]),
      category: 'c',
      suggestedFileName: 'x.bin',
    );
    final allocation = File(path).parent;
    await scratch.deleteScratchFile(path);
    expect(File(path).existsSync(), isFalse);
    expect(allocation.existsSync(), isFalse);
    // The root stays usable.
    expect(Directory(scratch.rootDirectory).existsSync(), isTrue);
  });

  test('deleteScratchFile keeps a directory that still holds siblings', () async {
    final path = await scratch.writeBytesToScratch(
      Uint8List.fromList([1]),
      category: 'c',
      suggestedFileName: 'x.bin',
    );
    final sibling = File(p.join(File(path).parent.path, 'y.bin'));
    await sibling.writeAsBytes([2]);
    await scratch.deleteScratchFile(path);
    expect(File(path).existsSync(), isFalse);
    expect(sibling.existsSync(), isTrue);
  });

  test('deleteScratchFile refuses paths outside the root', () async {
    final outside = File(p.join(tempRoot.path, 'keep.bin'));
    await outside.writeAsBytes([1]);
    await scratch.deleteScratchFile(outside.path);
    expect(outside.existsSync(), isTrue);
  });

  test('deleteScratchFile on a missing file is a no-op', () async {
    final missing = p.join(scratch.rootDirectory, 'c', '0_0', 'gone.bin');
    await expectLater(scratch.deleteScratchFile(missing), completes);
  });

  test('clear removes every scratch file and tolerates a missing root', () async {
    await scratch.writeBytesToScratch(
      Uint8List.fromList([1]),
      category: 'a',
      suggestedFileName: 'x',
    );
    await scratch.writeBytesToScratch(
      Uint8List.fromList([2]),
      category: 'b',
      suggestedFileName: 'y',
    );
    await scratch.clear();
    expect(Directory(scratch.rootDirectory).existsSync(), isFalse);
    await expectLater(scratch.clear(), completes);
    // Still usable afterwards: the next write recreates the tree.
    final path = await scratch.writeBytesToScratch(
      Uint8List.fromList([3]),
      category: 'a',
      suggestedFileName: 'z',
    );
    expect(File(path).existsSync(), isTrue);
  });
}
