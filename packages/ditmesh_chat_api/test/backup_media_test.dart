import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';
import 'package:test/test.dart';

void main() {
  test('only referenced, managed, saved recordings count', () {
    final names = BackupMedia.referenced('''
{"v":1,"materials":[
  {"id":"a","file":"media/recordings/rec_a.wav"},
  {"id":"b","file":"media/recordings/current.wav"},
  {"id":"c","file":"media/recordings/../x.wav"},
  {"id":"d","file":"C:\\\\evil.wav"},
  {"id":"e"}
]}''');
    expect(names, {'rec_a.wav'});
  });

  test('missing or damaged documents count nothing', () {
    expect(BackupMedia.referenced(null), isEmpty);
    expect(BackupMedia.referenced('{'), isEmpty);
    expect(BackupMedia.referenced('[]'), isEmpty);
  });
}
