// Manual native diagnostic entry point. No account or network session is
// opened, and the report deliberately excludes position coordinates.
import 'dart:convert';
import 'dart:io';

import 'package:ditmesh/l10n/generated/s.dart';
import 'package:ditmesh/nearby/location_source.dart';
import 'package:ditmesh/ui/chat/location_message_bubble.dart';
import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

void main() => runApp(
  const MaterialApp(
    localizationsDelegates: S.localizationsDelegates,
    supportedLocales: S.supportedLocales,
    locale: Locale('zh'),
    home: _Probe(),
  ),
);

class _Probe extends StatefulWidget {
  const _Probe();

  @override
  State<_Probe> createState() => _ProbeState();
}

class _ProbeState extends State<_Probe> {
  var _busy = false;
  String _status = '点击读取真实系统位置。报告不包含坐标，不发送消息。';

  Future<void> _locate() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _status = '正在读取真实系统位置…';
    });
    const source = GeolocatorLocationSource();
    final report = <String, Object?>{
      'startedAtUtc': DateTime.now().toUtc().toIso8601String(),
      'manualForegroundStart': true,
      'syntheticPosition': false,
      'coordinatesRecorded': false,
      'hasFix': false,
    };
    try {
      report['systemServiceEnabled'] =
          await Geolocator.isLocationServiceEnabled().timeout(
            const Duration(seconds: 5),
          );
      report['permissionBefore'] = (await source.permissionState()).name;
      report['permissionAfter'] = (await source.requestPermission()).name;
      report['rawPermissionAfter'] =
          (await Geolocator.checkPermission().timeout(
            const Duration(seconds: 5),
          )).name;
      final fix = await source.currentFix();
      report['hasFix'] = fix != null;
      report['fixValid'] = fix?.isValid;
      report['accuracyM'] = fix?.accuracyM;
      report['positionAgeMs'] = fix == null
          ? null
          : DateTime.now().difference(fix.at).inMilliseconds;
      if (const bool.fromEnvironment('DITMESH_LOCATION_HANDOFF') &&
          fix != null &&
          fix.isValid &&
          DateTime.now().difference(fix.at).abs() <
              const Duration(minutes: 3)) {
        // Opt-in, disposable handoff to the two local native test peers.
        // The sandbox's temporary directory is private to this application.
        final directory = await Directory.systemTemp.createTemp(
          'ditmesh-real-location-',
        );
        final file = File('${directory.path}/snapshot.json');
        await file.writeAsString(
          jsonEncode({
            'latitude': fix.latitude,
            'longitude': fix.longitude,
            'accuracyM': fix.accuracyM,
            'capturedAtUtc': fix.at.toUtc().toIso8601String(),
            'source': 'real-operating-system',
          }),
          flush: true,
        );
        report['privateHandoffPrepared'] = true;
        debugPrint('LOCATION_FIX_HANDOFF ${file.path}');
      }
      await Future<void>.delayed(const Duration(seconds: 2));
      report['rawPermissionAfterDelay'] =
          (await Geolocator.checkPermission().timeout(
            const Duration(seconds: 5),
          )).name;
    } on Object catch (error) {
      report['errorType'] = error.runtimeType.toString();
    }
    report['finishedAtUtc'] = DateTime.now().toUtc().toIso8601String();
    debugPrint('LOCATION_APP_EVIDENCE ${jsonEncode(report)}');
    if (!mounted) return;
    setState(() {
      _busy = false;
      _status = const JsonEncoder.withIndent('  ').convert(report);
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('本机定位与位置卡片验证')),
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            FilledButton(
              onPressed: _busy ? null : _locate,
              child: Text(_busy ? '正在定位…' : '读取真实位置'),
            ),
            const SizedBox(height: 16),
            SelectableText(_status),
            const Divider(height: 40),
            const Text('聊天卡片预览：以下使用太平洋合成坐标，与真实定位无关。'),
            const SizedBox(height: 16),
            LocationMessageBubble(
              message: ChatMessage(
                id: 'synthetic-preview',
                conversationId: 'c2c_test',
                senderId: 'test',
                senderName: '测试对端',
                text: const ChatLocation(
                  latitude: 0,
                  longitude: -140,
                  description: '本机验证用合成位置',
                ).encode(),
                timestamp: DateTime.now(),
                status: MessageStatus.received,
                isMine: false,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
