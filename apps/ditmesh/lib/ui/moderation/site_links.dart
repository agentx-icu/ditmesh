import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../i18n/l10n_extension.dart';
import '../account/account_widgets.dart';

/// Opens [url] in the browser. When nothing can open it (no browser, a
/// locked-down device) the link is copied instead and a snack says so.
Future<void> openSiteLink(BuildContext context, String url) async {
  final String copied = context.s.aboutLinkFailed;
  bool opened;
  try {
    opened = await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    );
  } on Object {
    opened = false;
  }
  if (!opened && context.mounted) {
    await copyToClipboard(context, url, confirmation: copied);
  }
}
