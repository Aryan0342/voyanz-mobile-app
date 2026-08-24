import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:voyanz/core/l10n/app_translations.dart';
import 'package:voyanz/core/providers/language_provider.dart';
import 'package:voyanz/core/theme/app_colors.dart';
import 'package:voyanz/core/theme/app_gradients.dart';
import 'package:voyanz/core/theme/widgets.dart';

enum InfoScreenKind {
  support,
  privacy,
  about,
  terms,
  service,
  legal,
  trust,
  contact,
}

class InfoScreen extends ConsumerStatefulWidget {
  final InfoScreenKind kind;

  const InfoScreen({super.key, required this.kind});

  @override
  ConsumerState<InfoScreen> createState() => _InfoScreenState();
}

class _InfoScreenState extends ConsumerState<InfoScreen> {
  WebViewController? _controller;

  IconData get _icon => switch (widget.kind) {
    InfoScreenKind.support => Icons.support_agent,
    InfoScreenKind.privacy => Icons.privacy_tip_outlined,
    InfoScreenKind.about => Icons.info_outline,
    InfoScreenKind.terms => Icons.description_outlined,
    InfoScreenKind.service => Icons.receipt_long_outlined,
    InfoScreenKind.legal => Icons.account_balance_outlined,
    InfoScreenKind.trust => Icons.verified_outlined,
    InfoScreenKind.contact => Icons.mail_outline,
  };

  String _title(AppTranslations t) => switch (widget.kind) {
    InfoScreenKind.support => t.helpCenter,
    InfoScreenKind.privacy => t.privacyPolicy,
    InfoScreenKind.about => t.aboutVoyanz,
    InfoScreenKind.terms => t.termsOfUse,
    InfoScreenKind.service => t.termsOfService,
    InfoScreenKind.legal => t.legalNotice,
    InfoScreenKind.trust => t.trustQuality,
    InfoScreenKind.contact => t.contactSupport,
  };

  String _subtitle(AppTranslations t) => switch (widget.kind) {
    InfoScreenKind.support => t.faqsGuides,
    InfoScreenKind.privacy => t.readOurTerms,
    InfoScreenKind.about => t.version100,
    InfoScreenKind.terms => t.readOurTerms,
    InfoScreenKind.service => t.readOurTerms,
    InfoScreenKind.legal => t.legalNoticeSubtitle,
    InfoScreenKind.trust => t.trustQualitySubtitle,
    InfoScreenKind.contact => t.contactSupportSubtitle,
  };

  String _path() => switch (widget.kind) {
    InfoScreenKind.support => 'page2',
    InfoScreenKind.privacy => 'page1',
    InfoScreenKind.about => 'whoweare',
    InfoScreenKind.terms => 'cgu',
    InfoScreenKind.service => 'cgs',
    InfoScreenKind.legal => 'legal',
    InfoScreenKind.trust => 'trust',
    InfoScreenKind.contact => 'contact',
  };

  String _url(String lang) => 'https://voyanz.com/$lang/${_path()}';

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(translationsProvider);
    final lang = ref.watch(languageProvider);
    final url = _url(lang);

    _controller ??= WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(AppColors.canvas)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (progress) {},
          onWebResourceError: (error) {},
        ),
      )
      ..loadRequest(Uri.parse(url));

    return GradientScaffold(
      appBar: VoyanzAppBar(
        showBackButton: true,
        title: Text(
          _title(t),
          style: GoogleFonts.jost(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
              decoration: BoxDecoration(
                gradient: AppGradients.accent,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(28),
                  bottomRight: Radius.circular(28),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Icon(_icon, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _title(t),
                          style: GoogleFonts.jost(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _subtitle(t),
                          style: GoogleFonts.montserrat(
                            fontSize: 12,
                            color: Colors.white.withValues(alpha: 0.75),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: WebViewWidget(controller: _controller!),
            ),
          ],
        ),
      ),
    );
  }
}