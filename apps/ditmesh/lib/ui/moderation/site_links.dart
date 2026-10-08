import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../i18n/l10n_extension.dart';
import '../account/account_routes.dart';
import '../account/account_widgets.dart';

/// [url] (one of the `kSiteUrl` pages) in the reader's language: the site
/// has English and Simplified Chinese pages; every other language reads the
/// English one.
String localizedSiteUrl(BuildContext context, String url) {
  final Locale locale = Localizations.localeOf(context);
  if (locale.languageCode != 'zh' || !url.startsWith('$kSiteUrl/')) return url;
  return '$kSiteUrl/zh-CN/${url.substring(kSiteUrl.length + 1)}';
}

/// Opens [url] in the browser. When nothing can open it (no browser, a
/// locked-down device) the link is copied instead and a snack says so.
Future<void> openSiteLink(BuildContext context, String url) async {
  final String localized = localizedSiteUrl(context, url);
  final String copied = context.s.aboutLinkFailed;
  bool opened;
  try {
    opened = await launchUrl(
      Uri.parse(localized),
      mode: LaunchMode.externalApplication,
    );
  } on Object {
    opened = false;
  }
  if (!opened && context.mounted) {
    await copyToClipboard(context, localized, confirmation: copied);
  }
}

/// Privacy policy, terms of use and support: in the Me page's About section
/// and on the guest Me page, so they are reachable with or without an
/// identity (App Review 5.1.1: an easily accessible privacy policy).
class SiteLinksSection extends StatelessWidget {
  const SiteLinksSection({super.key});

  @override
  Widget build(BuildContext context) {
    final S s = context.s;
    Widget tile(Key key, IconData icon, String title, String url) => ListTile(
      key: key,
      leading: Icon(icon),
      title: Text(title),
      trailing: const Icon(Icons.open_in_new, size: 18),
      onTap: () => unawaited(openSiteLink(context, url)),
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        tile(
          const ValueKey('about-privacy'),
          Icons.privacy_tip_outlined,
          s.aboutPrivacyPolicy,
          kPrivacyPolicyUrl,
        ),
        tile(
          const ValueKey('about-terms'),
          Icons.description_outlined,
          s.aboutTermsOfUse,
          kTermsUrl,
        ),
        tile(
          const ValueKey('about-support'),
          Icons.support_agent,
          s.aboutSupport,
          kSupportUrl,
        ),
      ],
    );
  }
}
