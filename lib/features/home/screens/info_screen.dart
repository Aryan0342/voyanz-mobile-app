import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
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

class InfoScreen extends ConsumerWidget {
  final InfoScreenKind kind;

  const InfoScreen({super.key, required this.kind});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final translations = ref.watch(translationsProvider);
    final language = ref.watch(languageProvider);
    final content = _InfoContent.forKind(kind, language);

    return GradientScaffold(
      appBar: VoyanzAppBar(
        showBackButton: true,
        title: Text(
          _title(translations),
          style: GoogleFonts.jost(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: _InfoHero(
                icon: _icon,
                title: _title(translations),
                subtitle: content.intro,
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(18, 20, 18, 150),
              sliver: SliverList.separated(
                itemCount: content.sections.length + 1,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  if (index < content.sections.length) {
                    return _InfoCard(section: content.sections[index]);
                  }
                  return _InfoActions(
                    officialUrl: content.officialUrl,
                    email: content.email,
                    language: language,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData get _icon => switch (kind) {
    InfoScreenKind.support => Icons.support_agent_rounded,
    InfoScreenKind.privacy => Icons.shield_outlined,
    InfoScreenKind.about => Icons.auto_awesome_outlined,
    InfoScreenKind.terms => Icons.description_outlined,
    InfoScreenKind.service => Icons.receipt_long_outlined,
    InfoScreenKind.legal => Icons.account_balance_outlined,
    InfoScreenKind.trust => Icons.verified_user_outlined,
    InfoScreenKind.contact => Icons.mark_email_read_outlined,
  };

  String _title(AppTranslations t) => switch (kind) {
    InfoScreenKind.support => t.helpCenter,
    InfoScreenKind.privacy => t.privacyPolicy,
    InfoScreenKind.about => t.aboutVoyanz,
    InfoScreenKind.terms => t.termsOfUse,
    InfoScreenKind.service => t.termsOfService,
    InfoScreenKind.legal => t.legalNotice,
    InfoScreenKind.trust => t.trustQuality,
    InfoScreenKind.contact => t.contactSupport,
  };
}

class _InfoHero extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _InfoHero({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppGradients.accent,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.brandMagenta.withValues(alpha: .18),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .18),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.jost(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: GoogleFonts.montserrat(
                    fontSize: 12.5,
                    height: 1.45,
                    color: Colors.white.withValues(alpha: .88),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final _InfoSection section;

  const _InfoCard({required this.section});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard.withValues(alpha: .92),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: .08)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.aqua.withValues(alpha: .12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(section.icon, color: AppColors.aqua, size: 21),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  section.title,
                  style: GoogleFonts.jost(
                    color: AppColors.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  section.body,
                  style: GoogleFonts.montserrat(
                    color: AppColors.textSecondary,
                    height: 1.55,
                    fontSize: 12.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoActions extends StatelessWidget {
  final String? officialUrl;
  final String? email;
  final String language;

  const _InfoActions({this.officialUrl, this.email, required this.language});

  @override
  Widget build(BuildContext context) {
    if (officialUrl == null && email == null) return const SizedBox.shrink();
    final french = language == 'fr';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (email != null)
          FilledButton.icon(
            onPressed: () => launchUrl(Uri(scheme: 'mailto', path: email)),
            icon: const Icon(Icons.mail_outline_rounded),
            label: Text(french ? 'Contacter le support' : 'Contact support'),
          ),
        if (email != null && officialUrl != null) const SizedBox(height: 10),
        if (officialUrl != null)
          OutlinedButton.icon(
            onPressed: () => launchUrl(
              Uri.parse(officialUrl!),
              mode: LaunchMode.externalApplication,
            ),
            icon: const Icon(Icons.open_in_new_rounded),
            label: Text(
              french
                  ? 'Voir le document officiel complet'
                  : 'View the complete official document',
            ),
          ),
      ],
    );
  }
}

class _InfoSection {
  final IconData icon;
  final String title;
  final String body;

  const _InfoSection(this.icon, this.title, this.body);
}

class _InfoContent {
  final String intro;
  final List<_InfoSection> sections;
  final String? officialUrl;
  final String? email;

  const _InfoContent({
    required this.intro,
    required this.sections,
    this.officialUrl,
    this.email,
  });

  static _InfoContent forKind(InfoScreenKind kind, String language) {
    final fr = language == 'fr';
    final base = 'https://voyanz.com/${fr ? 'fr' : 'en'}';
    _InfoSection section(
      IconData icon,
      String frTitle,
      String enTitle,
      String frBody,
      String enBody,
    ) => _InfoSection(icon, fr ? frTitle : enTitle, fr ? frBody : enBody);

    return switch (kind) {
      InfoScreenKind.support => _InfoContent(
        intro: fr
            ? 'Des réponses rapides pour votre compte, votre portefeuille et vos consultations.'
            : 'Quick answers for your account, wallet and consultations.',
        email: 'contact@voyanz.com',
        officialUrl: '$base/help-center',
        sections: [
          section(
            Icons.person_outline,
            'Compte et connexion',
            'Account and login',
            'Connectez-vous avec votre adresse e-mail. Utilisez la récupération de mot de passe si nécessaire.',
            'Sign in with your email address. Use password recovery when needed.',
          ),
          section(
            Icons.account_balance_wallet_outlined,
            'Portefeuille et paiements',
            'Wallet and payments',
            'Rechargez votre portefeuille avant une consultation payante. Votre solde reste visible dans votre espace.',
            'Top up your wallet before a paid consultation. Your balance remains visible in your account.',
          ),
          section(
            Icons.forum_outlined,
            'Consultations',
            'Consultations',
            'Choisissez un professionnel et démarrez une consultation disponible par chat, téléphone ou vidéo.',
            'Choose a professional and start an available consultation by chat, phone or video.',
          ),
          section(
            Icons.history_rounded,
            'Historique et avis',
            'History and reviews',
            'Retrouvez vos consultations passées et laissez un avis depuis votre historique.',
            'Find previous consultations and leave a review from your history.',
          ),
        ],
      ),
      InfoScreenKind.privacy => _InfoContent(
        intro: fr
            ? 'Comprendre comment vos données sont utilisées et protégées.'
            : 'Understand how your data is used and protected.',
        officialUrl: '$base/privacy',
        sections: [
          section(
            Icons.inventory_2_outlined,
            'Données collectées',
            'Data collected',
            'Voyanz traite les données nécessaires au compte, aux consultations, aux paiements et au support.',
            'Voyanz processes data needed for accounts, consultations, payments and support.',
          ),
          section(
            Icons.tune_rounded,
            'Utilisation',
            'How data is used',
            'Les données servent à fournir le service, sécuriser les échanges et répondre à vos demandes.',
            'Data is used to provide the service, secure interactions and answer your requests.',
          ),
          section(
            Icons.lock_outline,
            'Protection et conservation',
            'Protection and retention',
            'Des mesures techniques et organisationnelles protègent les informations.',
            'Technical and organisational measures protect your information.',
          ),
          section(
            Icons.manage_accounts_outlined,
            'Vos droits',
            'Your rights',
            'Vous pouvez exercer vos droits selon les conditions légales décrites dans la politique complète.',
            'You can exercise your rights under the conditions described in the full policy.',
          ),
        ],
      ),
      InfoScreenKind.about => _InfoContent(
        intro: fr
            ? 'Une expérience humaine et accessible pour trouver le bon accompagnement.'
            : 'A human, accessible experience for finding the right guidance.',
        sections: [
          section(
            Icons.explore_outlined,
            'Notre mission',
            'Our mission',
            'Voyanz vous met en relation avec des professionnels selon vos besoins et préférences.',
            'Voyanz connects you with professionals according to your needs and preferences.',
          ),
          section(
            Icons.phone_iphone_rounded,
            'Une expérience simple',
            'A simple experience',
            'Découvrez les profils, les disponibilités et échangez par chat, téléphone ou vidéo.',
            'Discover profiles and availability, then connect by chat, phone or video.',
          ),
          section(
            Icons.favorite_border_rounded,
            'Une approche humaine',
            'A human approach',
            'Les profils, notes et avis vous aident à choisir en toute transparence.',
            'Profiles, ratings and reviews help you choose transparently.',
          ),
        ],
      ),
      InfoScreenKind.terms => _InfoContent(
        intro: fr
            ? 'Les règles essentielles pour utiliser la plateforme Voyanz.'
            : 'The essential rules for using the Voyanz platform.',
        officialUrl: '$base/cgu',
        sections: [
          section(
            Icons.login_rounded,
            'Accès au service',
            'Access to the service',
            'L’utilisation nécessite un compte valide et le respect des conditions d’âge.',
            'Use requires a valid account and compliance with age requirements.',
          ),
          section(
            Icons.gavel_outlined,
            'Utilisation responsable',
            'Responsible use',
            'Chaque utilisateur s’engage à utiliser la plateforme légalement et à respecter les autres membres.',
            'Each user agrees to use the platform lawfully and respect other members.',
          ),
          section(
            Icons.security_rounded,
            'Sécurité du compte',
            'Account security',
            'Gardez vos identifiants confidentiels et signalez toute utilisation non autorisée.',
            'Keep your credentials confidential and report unauthorised use.',
          ),
        ],
      ),
      InfoScreenKind.service => _InfoContent(
        intro: fr
            ? 'Les conditions applicables aux consultations et aux paiements.'
            : 'The conditions that apply to consultations and payments.',
        officialUrl: '$base/cgs',
        sections: [
          section(
            Icons.price_check_outlined,
            'Tarification transparente',
            'Transparent pricing',
            'Le tarif est affiché avant le démarrage de chaque service payant.',
            'The price is displayed before each paid service begins.',
          ),
          section(
            Icons.account_balance_wallet_outlined,
            'Portefeuille et paiement',
            'Wallet and payment',
            'Les consultations payantes utilisent le solde disponible selon le mode choisi.',
            'Paid consultations use the available balance for the selected mode.',
          ),
          section(
            Icons.support_agent_rounded,
            'Assistance',
            'Support',
            'En cas de problème, contactez le support avec les détails utiles.',
            'If there is a problem, contact support with the relevant details.',
          ),
        ],
      ),
      InfoScreenKind.legal => _InfoContent(
        intro: fr
            ? 'Informations légales relatives à l’édition et à l’utilisation de Voyanz.'
            : 'Legal information about the publication and use of Voyanz.',
        officialUrl: '$base/legal',
        sections: [
          section(
            Icons.business_outlined,
            'Éditeur',
            'Publisher',
            'Les informations complètes sur l’éditeur sont disponibles dans la notice officielle.',
            'Full publisher details are available in the official notice.',
          ),
          section(
            Icons.dns_outlined,
            'Hébergement',
            'Hosting',
            'Les informations d’hébergement sont maintenues dans la version officielle en ligne.',
            'Hosting details are maintained in the official online version.',
          ),
          section(
            Icons.copyright_rounded,
            'Propriété intellectuelle',
            'Intellectual property',
            'Les marques, contenus et éléments graphiques sont protégés.',
            'Brands, content and visual elements are protected.',
          ),
        ],
      ),
      InfoScreenKind.trust => _InfoContent(
        intro: fr
            ? 'Des repères clairs pour une expérience sûre et transparente.'
            : 'Clear standards for a safe and transparent experience.',
        officialUrl: '$base/trust',
        sections: [
          section(
            Icons.badge_outlined,
            'Profils professionnels',
            'Professional profiles',
            'Les spécialités et modes de consultation facilitent votre choix.',
            'Specialties and consultation modes help you choose.',
          ),
          section(
            Icons.star_outline_rounded,
            'Notes et avis',
            'Ratings and reviews',
            'Les retours après consultation apportent un indicateur de confiance.',
            'Feedback after consultations provides an additional trust indicator.',
          ),
          section(
            Icons.visibility_outlined,
            'Transparence',
            'Transparency',
            'Disponibilités, tarifs et conditions sont présentés avant de commencer.',
            'Availability, prices and conditions are shown before you begin.',
          ),
          section(
            Icons.shield_outlined,
            'Sécurité',
            'Security',
            'Les outils de la plateforme contribuent à protéger les comptes et les échanges.',
            'Platform tools help protect accounts and interactions.',
          ),
        ],
      ),
      InfoScreenKind.contact => _InfoContent(
        intro: fr
            ? 'Notre équipe vous accompagne en cas de question ou de difficulté.'
            : 'Our team is here to help with questions or difficulties.',
        email: 'contact@voyanz.com',
        sections: [
          section(
            Icons.alternate_email_rounded,
            'Nous écrire',
            'Email us',
            'Contactez contact@voyanz.com et décrivez votre demande avec précision.',
            'Email contact@voyanz.com and describe your request precisely.',
          ),
          section(
            Icons.fact_check_outlined,
            'Informations utiles',
            'Helpful information',
            'Indiquez votre adresse de compte et le service concerné. Ne transmettez jamais votre mot de passe.',
            'Include your account email and relevant service. Never send your password.',
          ),
          section(
            Icons.schedule_rounded,
            'Suivi',
            'Follow-up',
            'Conservez les références communiquées par le support.',
            'Keep any reference supplied by support.',
          ),
        ],
      ),
    };
  }
}
