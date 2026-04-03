import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:voyanz/core/config/env.dart';
import 'package:voyanz/core/providers/language_provider.dart';
import 'package:voyanz/core/theme/app_colors.dart';
import 'package:voyanz/core/theme/app_gradients.dart';
import 'package:voyanz/core/theme/widgets.dart';
import 'package:voyanz/features/professionals/providers/professionals_provider.dart';
import 'package:voyanz/features/sessions/providers/sessions_provider.dart';

String? _resolveImageUrl(String? raw) {
  if (raw == null || raw.trim().isEmpty) return null;

  final value = raw.trim();
  if (value.startsWith('http://') || value.startsWith('https://')) {
    return value;
  }

  final base = EnvConfig.current.baseUrl;
  if (value.startsWith('//')) {
    final scheme = Uri.parse(base).scheme;
    return '$scheme:$value';
  }

  final normalizedPath = value.startsWith('/') ? value : '/$value';
  return '$base$normalizedPath';
}

String _profileImageUrl({String? rawAvatar, required String seed}) {
  final resolved = _resolveImageUrl(rawAvatar);
  if (resolved != null) return resolved;

  // Backend currently returns empty avatar for many professionals.
  // Use deterministic fallback photo so each profile keeps a stable image.
  final encodedSeed = Uri.encodeComponent(seed);
  return 'https://i.pravatar.cc/300?u=voyanz-$encodedSeed';
}

class ProfessionalDetailScreen extends ConsumerStatefulWidget {
  final String coId;

  const ProfessionalDetailScreen({super.key, required this.coId});

  @override
  ConsumerState<ProfessionalDetailScreen> createState() =>
      _ProfessionalDetailScreenState();
}

class _ProfessionalDetailScreenState
    extends ConsumerState<ProfessionalDetailScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _favoriteController;
  late Animation<double> _favoriteScale;
  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    _favoriteController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _favoriteScale = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _favoriteController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _favoriteController.dispose();
    super.dispose();
  }

  Future<void> _toggleFavorite() async {
    final coId = widget.coId;
    final currentlyFavorite =
        ref.read(favoriteProfessionalIdsProvider).contains(coId) || _isFavorite;
    final nextValue = !currentlyFavorite;

    setState(() {
      _isFavorite = nextValue;
    });
    ref
        .read(favoriteProfessionalIdsProvider.notifier)
        .setFavorite(coId, nextValue);
    _favoriteController.forward().then((_) {
      _favoriteController.reverse();
    });

    try {
      await ref
          .read(professionalsRepositoryProvider)
          .setProfessionalFavorite(coId, nextValue);

      ref.invalidate(professionalsListProvider);
      ref.invalidate(professionalDetailProvider(widget.coId));

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            nextValue
                ? ref.read(translationsProvider).addedFavorites
                : ref.read(translationsProvider).removedFavorites,
            style: GoogleFonts.montserrat(fontWeight: FontWeight.w600),
          ),
          backgroundColor: nextValue
              ? AppColors.rosePink
              : AppColors.mediumPurple,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    } catch (_) {
      setState(() {
        _isFavorite = currentlyFavorite;
      });
      ref
          .read(favoriteProfessionalIdsProvider.notifier)
          .setFavorite(coId, currentlyFavorite);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ref.read(translationsProvider).couldNotUpdateFavorite,
            style: GoogleFonts.montserrat(fontWeight: FontWeight.w600),
          ),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  void _bookSession(BuildContext context, dynamic pro) {
    // Navigate to pricing screen for this professional
    context.push('/pricing/${pro.coId}');
  }

  void _startSession(BuildContext context, dynamic pro) {
    final t = ref.read(translationsProvider);
    // For now, navigate to pricing/booking since we need to create a session first
    // In production, this would create a session and get a session ID
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          t.startSession,
          style: GoogleFonts.jost(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              t.chooseSessionType,
              style: GoogleFonts.montserrat(
                fontSize: 14,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            if (pro.supportsPhone) ...[
              _SessionTypeOption(
                icon: Icons.phone,
                label: t.phoneCall,
                price: pro.pricePerMinute ?? 0,
                onTap: () => _startSessionType(context, pro, 'phone'),
              ),
              const SizedBox(height: 8),
            ],
            if (pro.supportsVideo) ...[
              _SessionTypeOption(
                icon: Icons.videocam,
                label: t.videoCall,
                price: pro.pricePerMinute ?? 0,
                onTap: () => _startSessionType(context, pro, 'video'),
              ),
              const SizedBox(height: 8),
            ],
            if (pro.supportsChat) ...[
              _SessionTypeOption(
                icon: Icons.chat_bubble_outline,
                label: t.textChat,
                price: (pro.pricePerMinute ?? 0) * 0.8,
                onTap: () => _startSessionType(context, pro, 'chat'),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              t.cancel,
              style: GoogleFonts.montserrat(color: AppColors.textMuted),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _startSessionType(
    BuildContext context,
    dynamic pro,
    String type,
  ) async {
    final t = ref.read(translationsProvider);
    Navigator.pop(context); // Close dialog
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          t.startingSession(type, pro.firstName ?? 'professional'),
          style: GoogleFonts.montserrat(fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppColors.online,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );

    try {
      final seId = await ref
          .read(sessionsRepositoryProvider)
          .createSessionCall(typeCall: type, coId: pro.coId.toString());

      if (!mounted) return;

      context.push('/session/wait/$type/$seId/${pro.coId}');
      return;
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(t.errorMessage(e.toString())),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(translationsProvider);
    final detailAsync = ref.watch(professionalDetailProvider(widget.coId));
    final favoriteIds = ref.watch(favoriteProfessionalIdsProvider);
    final isMarkedFavorite = favoriteIds.contains(widget.coId) || _isFavorite;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.surfaceCard.withValues(alpha: 0.9),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.arrow_back_ios_new, size: 18),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: ScaleTransition(
              scale: _favoriteScale,
              child: IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceCard.withValues(alpha: 0.9),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isMarkedFavorite ? Icons.favorite : Icons.favorite_border,
                    color: isMarkedFavorite
                        ? AppColors.rosePink
                        : AppColors.textMuted,
                    size: 22,
                  ),
                ),
                onPressed: _toggleFavorite,
              ),
            ),
          ),
        ],
      ),
      body: detailAsync.when(
        loading: () => Container(
          decoration: const BoxDecoration(gradient: AppGradients.background),
          child: const Center(
            child: CircularProgressIndicator(color: AppColors.rosePink),
          ),
        ),
        error: (e, _) => Container(
          decoration: const BoxDecoration(gradient: AppGradients.background),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  color: AppColors.rosePink,
                  size: 48,
                ),
                const SizedBox(height: 16),
                Text(
                  t.unableLoadProfile,
                  style: GoogleFonts.montserrat(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  t.errorMessage('$e'),
                  style: const TextStyle(color: AppColors.textSecondary),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
        data: (pro) {
          // Initialize favorite status from data
          if (!_isFavorite && pro.isFavorite) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              ref
                  .read(favoriteProfessionalIdsProvider.notifier)
                  .setFavorite(pro.coId, true);
              setState(() {
                _isFavorite = pro.isFavorite;
              });
            });
          }

          return Container(
            decoration: const BoxDecoration(gradient: AppGradients.hero),
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
                child: Column(
                  children: [
                    // ── Avatar with online indicator ──
                    Stack(
                      children: [
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: AppGradients.accent,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.rosePink.withValues(
                                  alpha: 0.35,
                                ),
                                blurRadius: 32,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: Image.network(
                              _profileImageUrl(
                                rawAvatar: pro.avatar,
                                seed: pro.coId.isNotEmpty
                                    ? pro.coId
                                    : pro.displayName,
                              ),
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stack) =>
                                  _initials(pro),
                            ),
                          ),
                        ),
                        if (pro.isOnline != null)
                          Positioned(
                            bottom: 8,
                            right: 8,
                            child: Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                color: pro.isOnline == true
                                    ? AppColors.online
                                    : AppColors.offline,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.deepIndigo,
                                  width: 3,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // ── Name & Specialty ──
                    Text(
                      pro.displayName,
                      style: GoogleFonts.jost(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (pro.specialty != null &&
                        pro.specialty!.toLowerCase() != 'professional' &&
                        pro.specialty!.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        pro.specialty!,
                        style: GoogleFonts.lora(
                          fontSize: 16,
                          fontStyle: FontStyle.italic,
                          color: AppColors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                    const SizedBox(height: 12),

                    // ── Online Status Badge ──
                    if (pro.isOnline != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color:
                              (pro.isOnline == true
                                      ? AppColors.online
                                      : AppColors.offline)
                                  .withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color:
                                (pro.isOnline == true
                                        ? AppColors.online
                                        : AppColors.offline)
                                    .withValues(alpha: 0.4),
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: pro.isOnline == true
                                    ? AppColors.online
                                    : AppColors.offline,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              pro.isOnline == true ? t.online : t.offline,
                              style: GoogleFonts.montserrat(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 20),

                    // ── Badges Row (Verified + Rating) ──
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        if (pro.isVerified)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.mediumPurple.withValues(alpha: 0.3),
                                  AppColors.rosePink.withValues(alpha: 0.3),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: AppColors.mediumPurple.withValues(
                                  alpha: 0.4,
                                ),
                                width: 1.5,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.verified,
                                  size: 18,
                                  color: AppColors.mediumPurple,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  t.verifiedProfile,
                                  style: GoogleFonts.montserrat(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (pro.rating != null && pro.rating! > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.rosePink.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: AppColors.rosePink.withValues(
                                  alpha: 0.3,
                                ),
                                width: 1.5,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ...List.generate(5, (i) {
                                  return Icon(
                                    i < pro.rating!.round()
                                        ? Icons.star
                                        : Icons.star_outline,
                                    size: 16,
                                    color: AppColors.rosePink,
                                  );
                                }),
                                const SizedBox(width: 6),
                                Text(
                                  pro.rating!.toStringAsFixed(1),
                                  style: GoogleFonts.montserrat(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.rosePink,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // ── Availability Status ──
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: pro.isAvailableNow
                            ? AppColors.online.withValues(alpha: 0.12)
                            : AppColors.rosePink.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: pro.isAvailableNow
                              ? AppColors.online.withValues(alpha: 0.3)
                              : AppColors.rosePink.withValues(alpha: 0.25),
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            pro.isAvailableNow
                                ? Icons.check_circle_outline
                                : Icons.schedule,
                            color: pro.isAvailableNow
                                ? AppColors.online
                                : AppColors.rosePink,
                            size: 22,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              pro.availabilityText ??
                                  (pro.isAvailableNow
                                      ? t.availableNow
                                      : t.noAvailabilityAtMoment),
                              style: GoogleFonts.montserrat(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ── Action Buttons ──
                    Row(
                      children: [
                        Expanded(
                          child: _ActionButton(
                            onPressed: () => _bookSession(context, pro),
                            icon: Icons.calendar_today_outlined,
                            label: t.bookSession,
                            isPrimary: true,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // ── Session Types Card ──
                    GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.mediumPurple.withValues(
                                    alpha: 0.15,
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.support_agent,
                                  size: 20,
                                  color: AppColors.mediumPurple,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                t.availableServices,
                                style: GoogleFonts.jost(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _ServiceChip(
                                icon: Icons.phone,
                                label: t.phone,
                                isAvailable: pro.supportsPhone,
                              ),
                              _ServiceChip(
                                icon: Icons.videocam,
                                label: t.video,
                                isAvailable: pro.supportsVideo,
                              ),
                              _ServiceChip(
                                icon: Icons.chat_bubble_outline,
                                label: t.tabChat,
                                isAvailable: pro.supportsChat,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ── About Section ──
                    if (pro.description != null &&
                        pro.description!.isNotEmpty) ...[
                      GlassCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppColors.rosePink.withValues(
                                      alpha: 0.15,
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(
                                    Icons.person_outline,
                                    size: 20,
                                    color: AppColors.rosePink,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  t.about,
                                  style: GoogleFonts.jost(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            Text(
                              pro.description!,
                              style: GoogleFonts.lora(
                                fontSize: 14,
                                height: 1.7,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // ── Contact Details Card ──
                    if (pro.pricePerMinute != null ||
                        pro.phone != null ||
                        pro.email != null)
                      GlassCard(
                        child: Column(
                          children: [
                            if (pro.pricePerMinute != null) ...[
                              _DetailRow(
                                icon: Icons.payments_outlined,
                                label: t.pricePerMinute,
                                value:
                                    '€${pro.pricePerMinute!.toStringAsFixed(2)}',
                                iconColor: AppColors.online,
                              ),
                            ],
                            if (pro.phone != null) ...[
                              if (pro.pricePerMinute != null)
                                const Divider(height: 28),
                              _DetailRow(
                                icon: Icons.phone_outlined,
                                label: t.phone,
                                value: pro.phone!,
                                iconColor: AppColors.mediumPurple,
                              ),
                            ],
                            if (pro.email != null) ...[
                              if (pro.phone != null ||
                                  pro.pricePerMinute != null)
                                const Divider(height: 28),
                              _DetailRow(
                                icon: Icons.email_outlined,
                                label: t.email,
                                value: pro.email!,
                                iconColor: AppColors.rosePink,
                              ),
                            ],
                          ],
                        ),
                      ),
                    const SizedBox(height: 24),

                    // ── Start Session CTA ──
                    if (pro.isAvailableNow)
                      GradientButton(
                        onPressed: () => _startSession(context, pro),
                        width: double.infinity,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.videocam,
                              color: Colors.white,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              t.startSessionNow,
                              style: GoogleFonts.montserrat(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _initials(dynamic pro) {
    return Center(
      child: Text(
        pro.displayName.isNotEmpty ? pro.displayName[0].toUpperCase() : '?',
        style: GoogleFonts.jost(
          fontSize: 42,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }
}

// ── Action Button Widget ──
class _ActionButton extends StatelessWidget {
  final VoidCallback onPressed;
  final IconData icon;
  final String label;
  final bool isPrimary;

  const _ActionButton({
    required this.onPressed,
    required this.icon,
    required this.label,
    required this.isPrimary,
  });

  @override
  Widget build(BuildContext context) {
    if (isPrimary) {
      return GradientButton(
        onPressed: onPressed,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                style: GoogleFonts.montserrat(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          decoration: BoxDecoration(
            color: AppColors.surfaceCard.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.mediumPurple.withValues(alpha: 0.3),
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: AppColors.mediumPurple, size: 20),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  style: GoogleFonts.montserrat(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Detail Row Widget ──
class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color iconColor;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.montserrat(
                  fontSize: 12,
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: GoogleFonts.montserrat(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Service Chip Widget ──
class _ServiceChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isAvailable;

  const _ServiceChip({
    required this.icon,
    required this.label,
    required this.isAvailable,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: isAvailable
                ? AppColors.online.withValues(alpha: 0.15)
                : AppColors.textMuted.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isAvailable
                  ? AppColors.online.withValues(alpha: 0.3)
                  : AppColors.textMuted.withValues(alpha: 0.2),
              width: 1.5,
            ),
          ),
          child: Icon(
            icon,
            color: isAvailable ? AppColors.online : AppColors.textMuted,
            size: 28,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: GoogleFonts.montserrat(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isAvailable ? AppColors.textPrimary : AppColors.textMuted,
          ),
        ),
      ],
    );
  }
}

class _SessionTypeOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final double? price;
  final VoidCallback onTap;

  const _SessionTypeOption({
    required this.icon,
    required this.label,
    this.price,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final priceText = price != null
        ? '€${(price! / 100).toStringAsFixed(2)}/min'
        : null;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.textMuted.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.online.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.online.withValues(alpha: 0.3),
                  width: 1.5,
                ),
              ),
              child: Icon(icon, color: AppColors.online, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.montserrat(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (priceText != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      priceText,
                      style: GoogleFonts.montserrat(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: AppColors.textMuted.withValues(alpha: 0.5),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}
