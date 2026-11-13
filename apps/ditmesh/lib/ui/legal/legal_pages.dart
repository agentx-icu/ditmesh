import 'package:flutter/material.dart';

import '../../i18n/l10n_extension.dart';
import '../account/account_widgets.dart';
import '../common/app_bar_title.dart';

/// Privacy policy bundled with the app.
class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) =>
      _LegalDocument(title: context.s.aboutPrivacyPolicy, file: 'privacy');
}

/// Terms of use and community guidelines bundled with the app.
class TermsOfUsePage extends StatelessWidget {
  const TermsOfUsePage({super.key});

  @override
  Widget build(BuildContext context) =>
      _LegalDocument(title: context.s.aboutTermsOfUse, file: 'terms');
}

class _LegalDocument extends StatefulWidget {
  const _LegalDocument({required this.title, required this.file});

  final String title;
  final String file;

  @override
  State<_LegalDocument> createState() => _LegalDocumentState();
}

class _LegalDocumentState extends State<_LegalDocument> {
  late Future<String> _document;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Use the same resolved locale as the page title and error text.
    final locale = context.s.localeName;
    _document = DefaultAssetBundle.of(
      context,
    ).loadString('assets/legal/${widget.file}_$locale.txt', cache: false);
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<String>(
    key: ObjectKey(_document),
    future: _document,
    builder: (context, snapshot) => _LegalTextPage(
      title: widget.title,
      content: switch (snapshot) {
        AsyncSnapshot(data: final String text) => Text(text),
        AsyncSnapshot(hasError: true) => Text(
          context.s.legalDocumentUnavailable,
        ),
        _ => const Center(child: CircularProgressIndicator()),
      },
    ),
  );
}

class _LegalTextPage extends StatelessWidget {
  const _LegalTextPage({required this.title, required this.content});

  final String title;
  final Widget content;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: AppBarTitle(title)),
    body: AccountPageBody(maxWidth: 640, children: [content]),
  );
}

/// Local legal and support routes for the Me screens.
class LegalLinksSection extends StatelessWidget {
  const LegalLinksSection({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    Widget pageTile(String key, IconData icon, String title, Widget page) =>
        ListTile(
          key: ValueKey(key),
          leading: Icon(icon),
          title: Text(title),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.of(
            context,
          ).push(MaterialPageRoute<void>(builder: (_) => page)),
        );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        pageTile(
          'about-privacy',
          Icons.privacy_tip_outlined,
          s.aboutPrivacyPolicy,
          const PrivacyPolicyPage(),
        ),
        pageTile(
          'about-terms',
          Icons.description_outlined,
          s.aboutTermsOfUse,
          const TermsOfUsePage(),
        ),
        pageTile(
          'account-personal-info',
          Icons.badge_outlined,
          s.accountPersonalInfoList,
          _LegalTextPage(
            title: s.accountPersonalInfoList,
            content: Text(s.personalInfoListText),
          ),
        ),
        pageTile(
          'account-third-party',
          Icons.handshake_outlined,
          s.accountThirdPartyShareList,
          _LegalTextPage(
            title: s.accountThirdPartyShareList,
            content: Text(s.thirdPartyShareText),
          ),
        ),
        pageTile(
          'account-permissions',
          Icons.mic_none_outlined,
          s.accountPermissionList,
          _LegalTextPage(
            title: s.accountPermissionList,
            content: Text(s.permissionListText),
          ),
        ),
        pageTile(
          'about-support',
          Icons.support_agent,
          s.aboutSupport,
          _LegalTextPage(
            title: s.aboutSupport,
            content: Text(s.technicalSupportText),
          ),
        ),
      ],
    );
  }
}
