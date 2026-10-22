import 'dart:convert';
import 'dart:io';

import 'package:ditmesh/desktop/desktop_instance.dart';

Future<void> main(List<String> args) async {
  final owner = await DesktopInstance.acquire(Directory(args.single));
  if (owner == null) {
    stdout.writeln('secondary');
    return;
  }
  owner.onActivate = () async => stdout.writeln('activated');
  stdout.writeln('owner');
  await stdin.transform(utf8.decoder).first;
  await owner.close();
}
