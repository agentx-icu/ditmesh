// Routes and URLs used by the account / Me surfaces. Not UI text, so they
// stay constants here rather than in the ARB files.

/// Route name of the training-defaults page (filled in by the learn UI).
const String kTrainingSettingsRoute = '/settings/training';

/// Public repository, shown (and copied) from the About section.
const String kAboutSourceUrl = 'https://github.com/agentx-icu/ditmesh';

/// Public site (`site/`, GitHub Pages): privacy policy, terms of use and
/// support. Keep in sync with `site/README.md` and `doc/release/APP_STORE.md`.
const String kSiteUrl = 'https://agentx-icu.github.io/ditmesh';
const String kPrivacyPolicyUrl = '$kSiteUrl/privacy/';
const String kTermsUrl = '$kSiteUrl/terms/';
const String kSupportUrl = '$kSiteUrl/support/';
