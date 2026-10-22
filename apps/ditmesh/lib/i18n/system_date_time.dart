import 'package:flutter/widgets.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

/// Locale date order and the OS time convention, including a 24-hour override.
String formatSystemDateTime(BuildContext context, DateTime instant) {
  final formatter = DateFormat.yMd(Localizations.localeOf(context).toString());
  if (MediaQuery.alwaysUse24HourFormatOf(context)) {
    formatter.add_Hm();
  } else if (defaultTargetPlatform == TargetPlatform.android) {
    // Android exposes the explicit user setting independently of app locale.
    formatter.addPattern('h:mm a');
  } else {
    formatter.add_jm();
  }
  return formatter.format(instant.toLocal());
}
