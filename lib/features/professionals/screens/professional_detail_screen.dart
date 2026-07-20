import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:voyanz/core/config/env.dart';
import 'package:voyanz/core/providers/language_provider.dart';
import 'package:voyanz/core/theme/app_colors.dart';
import 'package:voyanz/core/theme/app_gradients.dart';
import 'package:voyanz/core/theme/widgets.dart';
import 'package:voyanz/features/auth/providers/auth_provider.dart';
import 'package:voyanz/features/reviews/providers/reviews_provider.dart';
import 'package:voyanz/features/professionals/models/professional.dart';
import 'package:voyanz/features/professionals/providers/professionals_provider.dart';
import 'package:voyanz/features/sessions/data/sessions_data_source.dart';
import 'package:voyanz/features/sessions/models/session_status.dart';
import 'package:voyanz/features/sessions/models/session_type.dart';
import 'package:voyanz/features/sessions/navigation/session_navigation.dart';
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
    context.push('/appointment-booking/${pro.coId}');
  }

  double? _sessionTypePrice(
    String type,
    Professional pro, {
    Professional? fromList,
  }) {
    final candidates = switch (type) {
      'phone' => <double?>[
        pro.pricePhonePerMinute,
        fromList?.pricePhonePerMinute,
        pro.pricePerMinute,
        fromList?.pricePerMinute,
      ],
      'video' => <double?>[
        pro.priceVideoPerMinute,
        fromList?.priceVideoPerMinute,
        pro.pricePerMinute,
        fromList?.pricePerMinute,
      ],
      'chat' => <double?>[
        pro.priceChatPerMinute,
        fromList?.priceChatPerMinute,
        pro.pricePerMinute,
        fromList?.pricePerMinute,
      ],
      _ => <double?>[pro.pricePerMinute, fromList?.pricePerMinute],
    };

    for (final value in candidates) {
      if (value != null && value > 0) return value;
    }
    return null;
  }

  bool _supportsSessionType(
    String type,
    Professional pro, {
    Professional? fromList,
  }) {
    return switch (type) {
      'phone' => pro.supportsPhone || (fromList?.supportsPhone ?? false),
      'video' => pro.supportsVideo || (fromList?.supportsVideo ?? false),
      'chat' => pro.supportsChat || (fromList?.supportsChat ?? false),
      _ => false,
    };
  }

  bool _isResumableStatus(String? rawStatus) {
    final status = (rawStatus ?? '').toLowerCase().replaceAll(
      RegExp(r'[^a-z]'),
      '',
    );
    return status == 'inprogress' ||
        status == 'calling' ||
        status == 'accepted' ||
        status == 'pending' ||
        status == 'active' ||
        status == 'started';
  }

  bool _isProfessionalBusyError(String rawMessage) {
    final message = rawMessage.toLowerCase();
    return message.contains('currently in consultation') ||
        message.contains('actuellement en consultation') ||
        message.contains('prenez un rendez-vous') ||
        message.contains('take an appointment');
  }

  void _startSession(
    BuildContext context,
    Professional pro, {
    Professional? fromList,
  }) {
    final t = ref.read(translationsProvider);
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
            if (_supportsSessionType('phone', pro, fromList: fromList)) ...[
              _SessionTypeOption(
                icon: Icons.phone,
                label: t.phoneCall,
                price: _sessionTypePrice('phone', pro, fromList: fromList),
                onTap: () => _startSessionType(ctx, pro, 'phone'),
              ),
              const SizedBox(height: 8),
            ],
            if (_supportsSessionType('video', pro, fromList: fromList)) ...[
              _SessionTypeOption(
                icon: Icons.videocam,
                label: t.videoCall,
                price: _sessionTypePrice('video', pro, fromList: fromList),
                onTap: () => _startSessionType(ctx, pro, 'video'),
              ),
              const SizedBox(height: 8),
            ],
            if (_supportsSessionType('chat', pro, fromList: fromList)) ...[
              _SessionTypeOption(
                icon: Icons.chat_bubble_outline,
                label: t.textChat,
                price: _sessionTypePrice('chat', pro, fromList: fromList),
                onTap: () => _startSessionType(ctx, pro, 'chat'),
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
    BuildContext dialogContext,
    dynamic pro,
    String type,
  ) async {
    if (!mounted) return;
    final t = ref.read(translationsProvider);
    Navigator.of(dialogContext).pop(); // Close dialog only
    final normalizedType = normalizeSessionType(type);
    if (normalizedType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(t.chooseSessionType),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final activeSeId = await _recoverRecentSessionId(
      expectedCoId: pro.coId.toString(),
    );
    if (!mounted) return;
    if (activeSeId != null && activeSeId.isNotEmpty) {
      context.push('/session/wait/$normalizedType/$activeSeId/${pro.coId}');
      return;
    }

    try {
      final launch = await ref
          .read(sessionsRepositoryProvider)
          .createSessionCall(
            typeCall: normalizedType,
            coId: pro.coId.toString(),
          );

      if (!mounted) return;

      openLaunchResult(
        context,
        launch,
        fallbackType: normalizedType,
        coId: pro.coId.toString(),
      );
      return;
    } on SessionAuthExpiredException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('An error occurred. Please try again.'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      await ref.read(authStateProvider.notifier).logout();
      if (!mounted) return;
      context.go('/login');
    } on SessionLaunchException catch (e) {
      if (!mounted) return;

      if (_isProfessionalBusyError(e.toString())) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(t.professionalBusyMessage),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
        _bookSession(context, pro);
        return;
      }

      Future<SessionStatus?> getJoinableStatus(String seId) async {
        try {
          final status = await ref
              .read(sessionsRepositoryProvider)
              .getSessionStatus(seId);
          return status.isTerminal ? null : status;
        } catch (_) {
          return null;
        }
      }

      Future<bool> tryOpenIfJoinable(
        String? seId, {
        String? fallbackType,
        String? fallbackChgrId,
      }) async {
        if (seId == null || seId.isEmpty) return false;
        final status = await getJoinableStatus(seId);
        if (!mounted) return true;
        if (status == null) return false;
        openSessionStatus(
          context,
          status,
          fallbackType: fallbackType ?? normalizedType,
          coId: pro.coId.toString(),
          fallbackChgrId: fallbackChgrId,
        );
        return true;
      }

      // New flow: 409 response includes all session details (se_id, se_type, se_room, chgr_id)
      if (e.isDuplicateSessionWithDetails && _isResumableStatus(e.seStatus)) {
        if (await tryOpenIfJoinable(
          e.resolvedSessionId,
          fallbackType: e.seType,
          fallbackChgrId: e.chgrId,
        )) {
          return;
        }
      }

      // Fallback 1: canResume if session ID present (old format, for backward compat)
      if (e.canResume &&
          (e.seStatus == null || _isResumableStatus(e.seStatus))) {
        if (await tryOpenIfJoinable(e.resolvedSessionId)) return;
      }

      // Fallback 2: Search history if 409 but no details in exception
      final isDuplicateLaunch =
          e.statusCode == 409 ||
          e.toString().toLowerCase().contains('session_already_launched');
      if (isDuplicateLaunch) {
        if (e.canResume) {
          if (await tryOpenIfJoinable(e.resolvedSessionId)) return;
        }

        final recoveredSeId = await _recoverRecentSessionId(
          expectedCoId: pro.coId.toString(),
        );
        if (!mounted) return;
        if (await tryOpenIfJoinable(recoveredSeId)) return;

        try {
          final freshLaunch = await ref
              .read(sessionsRepositoryProvider)
              .createSessionCall(
                typeCall: normalizedType,
                coId: pro.coId.toString(),
              );
          if (!mounted) return;
          openLaunchResult(
            context,
            freshLaunch,
            fallbackType: normalizedType,
            coId: pro.coId.toString(),
          );
          return;
        } on SessionLaunchException catch (retryError) {
          // Backend can keep a short-lived lock after session termination.
          // Retry once after a brief delay before surfacing the error.
          await Future<void>.delayed(const Duration(milliseconds: 1200));
          if (!mounted) return;

          try {
            final retriedLaunch = await ref
                .read(sessionsRepositoryProvider)
                .createSessionCall(
                  typeCall: normalizedType,
                  coId: pro.coId.toString(),
                );
            if (!mounted) return;
            openLaunchResult(
              context,
              retriedLaunch,
              fallbackType: normalizedType,
              coId: pro.coId.toString(),
            );
            return;
          } on SessionLaunchException catch (secondError) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(t.errorMessage(secondError.toString())),
                backgroundColor: AppColors.error,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            );
            return;
          } catch (_) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(t.errorMessage(retryError.toString())),
                backgroundColor: AppColors.error,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            );
            return;
          }
        } catch (_) {
          // Fall through to generic error handling below.
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isDuplicateLaunch
                ? t.sessionAlreadyStarted
                : 'An error occurred. Please try again.',
          ),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString().toLowerCase();
      if (msg.contains('insufficient_balance')) {
        _showInsufficientBalanceDialog(context, ref);
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('An error occurred. Please try again.'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  void _showInsufficientBalanceDialog(BuildContext context, WidgetRef ref) {
    final t = ref.read(translationsProvider);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          t.insufficientBalance,
          style: GoogleFonts.jost(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        content: Text(
          t.topUpNow,
          style: GoogleFonts.montserrat(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              t.cancel,
              style: GoogleFonts.montserrat(color: AppColors.textMuted),
            ),
          ),
          GradientButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.push('/wallet/topup');
            },
            child: Text(t.topUpNow),
          ),
        ],
      ),
    );
  }

  Future<String?> _recoverRecentSessionId({String? expectedCoId}) async {
    String normalize(String? value) =>
        (value ?? '').toLowerCase().replaceAll(RegExp(r'[^a-z]'), '');

    bool isTerminalStatus(String normalizedStatus) {
      return normalizedStatus == 'completed' ||
          normalizedStatus == 'rejected' ||
          normalizedStatus == 'canceled' ||
          normalizedStatus == 'cancelled' ||
          normalizedStatus == 'ended' ||
          normalizedStatus == 'closed' ||
          normalizedStatus == 'expired' ||
          normalizedStatus == 'failed' ||
          normalizedStatus == 'timeout';
    }

    try {
      final history = await ref.read(customerHistoryProvider.future);
      for (final item in history) {
        if (item is! Map<String, dynamic>) continue;
        final nestedSession = item['session'];
        final session = nestedSession is Map<String, dynamic>
            ? nestedSession
            : const <String, dynamic>{};

        final seId =
            item['se_id']?.toString() ??
            session['se_id']?.toString() ??
            item['session_id']?.toString() ??
            item['id']?.toString();
        if (seId == null || seId.isEmpty) continue;

        final rowCoId =
            item['co_id']?.toString() ??
            session['co_id']?.toString() ??
            item['customer_id']?.toString() ??
            item['professional_id']?.toString();
        if (expectedCoId != null &&
            expectedCoId.isNotEmpty &&
            rowCoId != null &&
            rowCoId.isNotEmpty &&
            rowCoId != expectedCoId) {
          continue;
        }

        final rawStatus =
            item['se_status']?.toString() ??
            session['se_status']?.toString() ??
            item['session_status']?.toString() ??
            item['status']?.toString() ??
            item['state']?.toString() ??
            '';
        final status = normalize(rawStatus);

        if (status.isNotEmpty && isTerminalStatus(status)) {
          continue;
        }

        try {
          final liveStatus = await ref
              .read(sessionsRepositoryProvider)
              .getSessionStatus(seId);
          if (!liveStatus.isTerminal) {
            return seId;
          }
        } catch (_) {
          // If live status fails, only trust explicit non-terminal history status.
          if (status.isNotEmpty && !isTerminalStatus(status)) {
            return seId;
          }
        }
      }
    } catch (_) {}

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(translationsProvider);
    final detailAsync = ref.watch(professionalDetailProvider(widget.coId));
    final listAsync = ref.watch(professionalsListProvider);
    final favoriteIds = ref.watch(favoriteProfessionalIdsProvider);
    final isMarkedFavorite = favoriteIds.contains(widget.coId) || _isFavorite;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: VoyanzAppBar(
        showBackButton: true,
        onBackPressed: () => Navigator.of(context).pop(),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: ScaleTransition(
              scale: _favoriteScale,
              child: VoyanzAppBarIconButton(
                icon: isMarkedFavorite ? Icons.favorite : Icons.favorite_border,
                iconSize: 22,
                onPressed: _toggleFavorite,
                tooltip: isMarkedFavorite
                    ? t.removedFavorites
                    : t.addedFavorites,
              ),
            ),
          ),
        ],
      ),
      body: detailAsync.when(
        loading: () => Container(
          decoration: const BoxDecoration(gradient: AppGradients.background),
          child: const Center(
            child: CircularProgressIndicator(color: AppColors.mediumPurple),
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
                const Text(
                  'An error occurred. Please try again.',
                  style: TextStyle(color: AppColors.textSecondary),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
        data: (pro) {
          Professional? listPro;
          final list = listAsync.valueOrNull;
          if (list != null) {
            for (final item in list) {
              if (item.coId == pro.coId) {
                listPro = item;
                break;
              }
            }
          }

          final effectiveOnline = pro.isOnline ?? listPro?.isOnline;
          final effectiveAvailableNow =
              pro.isAvailableNow || (listPro?.isAvailableNow ?? false);

          String? effectiveAvailabilityText = pro.availabilityText;
          if (effectiveAvailabilityText == null ||
              effectiveAvailabilityText.trim().isEmpty) {
            final fallbackText = listPro?.availabilityText;
            if (fallbackText != null && fallbackText.trim().isNotEmpty) {
              effectiveAvailabilityText = fallbackText;
            }
          }

          final availabilityLabel = effectiveAvailableNow
              ? t.availableNow
              : (effectiveAvailabilityText ?? t.noAvailabilityAtMoment);

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
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    // ── Hero Header Strip ──
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0xFFFFEDF5), Color(0xFFF1EEFF), Color(0x00FFFFFF)],
                          stops: [0.0, 0.6, 1.0],
                        ),
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(32),
                          bottomRight: Radius.circular(32),
                        ),
                      ),
                      child: Column(
                        children: [
                          // ── Avatar with online indicator ──
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              // Glow ring
                              Container(
                                width: 136,
                                height: 136,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: const LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [AppColors.mediumPurple, AppColors.magentaRose],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.mediumPurple.withValues(alpha: 0.30),
                                      blurRadius: 24,
                                      spreadRadius: 4,
                                    ),
                                    BoxShadow(
                                      color: AppColors.rosePink.withValues(alpha: 0.20),
                                      blurRadius: 40,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                              ),
                              // Avatar image
                              Container(
                                width: 126,
                                height: 126,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white,
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
                              // Online dot
                              if (effectiveOnline != null)
                                Positioned(
                                  bottom: 6,
                                  right: 6,
                                  child: Container(
                                    width: 22,
                                    height: 22,
                                    decoration: BoxDecoration(
                                      color: effectiveOnline == true
                                          ? AppColors.online
                                          : AppColors.offline,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 3,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: (effectiveOnline == true
                                                  ? AppColors.online
                                                  : AppColors.offline)
                                              .withValues(alpha: 0.5),
                                          blurRadius: 8,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 18),

                          // ── Name ──
                          Text(
                            pro.displayName,
                            style: GoogleFonts.jost(
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                              letterSpacing: -0.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          if (pro.specialty != null &&
                              pro.specialty!.toLowerCase() != 'professional' &&
                              pro.specialty!.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              pro.specialty!,
                              style: GoogleFonts.lora(
                                fontSize: 14,
                                fontStyle: FontStyle.italic,
                                color: AppColors.textSecondary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                          const SizedBox(height: 12),

                          // ── Online pill + Verified badges ──
                          Wrap(
                            alignment: WrapAlignment.center,
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              if (effectiveOnline != null)
                                _StatusPill(
                                  dot: true,
                                  dotColor: effectiveOnline == true
                                      ? AppColors.online
                                      : AppColors.offline,
                                  label: effectiveOnline == true ? t.online : t.offline,
                                  bgColor: (effectiveOnline == true
                                          ? AppColors.online
                                          : AppColors.offline)
                                      .withValues(alpha: 0.12),
                                  borderColor: (effectiveOnline == true
                                          ? AppColors.online
                                          : AppColors.offline)
                                      .withValues(alpha: 0.35),
                                ),
                              if (pro.isVerified)
                                _StatusPill(
                                  icon: Icons.verified,
                                  iconColor: AppColors.mediumPurple,
                                  label: t.verifiedProfile,
                                  bgColor: AppColors.mediumPurple.withValues(alpha: 0.10),
                                  borderColor: AppColors.mediumPurple.withValues(alpha: 0.25),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ── Stats Row (Rating / Reviews / Response) ──
                          if (pro.rating != null && pro.rating! > 0)
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.mediumPurple.withValues(alpha: 0.08),
                                    blurRadius: 16,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                                border: Border.all(
                                  color: AppColors.borderSubtle,
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  _StatCell(
                                    value: pro.rating!.toStringAsFixed(1),
                                    sub: 'Reviews',
                                    icon: Icons.star_rounded,
                                    iconColor: AppColors.gold,
                                    hasDivider: false,
                                  ),
                                  _StatCell(
                                    value: '8+ Yrs',
                                    sub: 'Experience',
                                    icon: Icons.workspace_premium_outlined,
                                    iconColor: AppColors.mediumPurple,
                                    hasDivider: true,
                                  ),
                                  _StatCell(
                                    value: '15 min',
                                    sub: 'Response',
                                    icon: Icons.bolt_outlined,
                                    iconColor: AppColors.magentaRose,
                                    hasDivider: true,
                                  ),
                                ],
                              ),
                            ),
                          if (pro.rating != null && pro.rating! > 0)
                            const SizedBox(height: 20),

                          // ── Availability Banner ──
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 13,
                            ),
                            decoration: BoxDecoration(
                              color: effectiveAvailableNow
                                  ? const Color(0xFFECFDF5)
                                  : const Color(0xFFFFF1F2),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: effectiveAvailableNow
                                    ? AppColors.online.withValues(alpha: 0.4)
                                    : AppColors.rosePink.withValues(alpha: 0.4),
                                width: 1.5,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: effectiveAvailableNow
                                        ? AppColors.online.withValues(alpha: 0.15)
                                        : AppColors.rosePink.withValues(alpha: 0.15),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    effectiveAvailableNow
                                        ? Icons.check_circle_rounded
                                        : Icons.schedule_rounded,
                                    color: effectiveAvailableNow
                                        ? AppColors.online
                                        : AppColors.rosePink,
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    availabilityLabel,
                                    style: GoogleFonts.montserrat(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: effectiveAvailableNow
                                          ? const Color(0xFF15803D)
                                          : AppColors.magentaRose,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),

                          // ── EXPERTISE Section ──
                          if (pro.specialty != null && pro.specialty!.isNotEmpty) ...[
                            Text(
                              'EXPERTISE',
                              style: GoogleFonts.montserrat(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textMuted,
                                letterSpacing: 1.4,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: pro.specialty!
                                  .split(RegExp(r'[,/|]'))
                                  .map((s) => s.trim())
                                  .where((s) => s.isNotEmpty && s.toLowerCase() != 'professional')
                                  .map(
                                    (tag) => Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 7,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.mediumPurple.withValues(alpha: 0.09),
                                        borderRadius: BorderRadius.circular(30),
                                        border: Border.all(
                                          color: AppColors.mediumPurple.withValues(alpha: 0.22),
                                          width: 1.2,
                                        ),
                                      ),
                                      child: Text(
                                        tag,
                                        style: GoogleFonts.montserrat(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.mediumPurple,
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ),
                            const SizedBox(height: 20),
                          ],

                          // ── Available Services Card ──
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.mediumPurple.withValues(alpha: 0.07),
                                  blurRadius: 16,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                              border: Border.all(
                                color: AppColors.borderSubtle,
                                width: 1,
                              ),
                            ),
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(9),
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: [AppColors.mediumPurple, AppColors.magentaRose],
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(
                                        Icons.support_agent,
                                        size: 18,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      t.availableServices,
                                      style: GoogleFonts.jost(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 18),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                                  children: [
                                    _ServiceChip(
                                      icon: Icons.phone_rounded,
                                      label: t.phone,
                                      isAvailable: pro.supportsPhone,
                                      activeColor: AppColors.mediumPurple,
                                    ),
                                    _ServiceChip(
                                      icon: Icons.videocam_rounded,
                                      label: t.video,
                                      isAvailable: pro.supportsVideo,
                                      activeColor: AppColors.magentaRose,
                                    ),
                                    _ServiceChip(
                                      icon: Icons.chat_bubble_rounded,
                                      label: t.tabChat,
                                      isAvailable: pro.supportsChat,
                                      activeColor: AppColors.aqua,
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
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.rosePink.withValues(alpha: 0.07),
                                    blurRadius: 16,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                                border: Border.all(
                                  color: AppColors.borderSubtle,
                                  width: 1,
                                ),
                              ),
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(9),
                                        decoration: BoxDecoration(
                                          color: AppColors.rosePink.withValues(alpha: 0.12),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: const Icon(
                                          Icons.person_outline_rounded,
                                          size: 18,
                                          color: AppColors.rosePink,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        t.about,
                                        style: GoogleFonts.jost(
                                          fontSize: 17,
                                          fontWeight: FontWeight.w700,
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
                                      height: 1.75,
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
                              pro.email != null) ...[
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.aqua.withValues(alpha: 0.07),
                                    blurRadius: 16,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                                border: Border.all(
                                  color: AppColors.borderSubtle,
                                  width: 1,
                                ),
                              ),
                              padding: const EdgeInsets.all(20),
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
                                      Divider(
                                        height: 28,
                                        color: AppColors.borderSubtle,
                                      ),
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
                                      Divider(
                                        height: 28,
                                        color: AppColors.borderSubtle,
                                      ),
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
                            const SizedBox(height: 20),
                          ],

                          // ── Book Session CTA ──
                          _ActionButton(
                            onPressed: () => _bookSession(context, pro),
                            icon: Icons.calendar_today_rounded,
                            label: t.bookSession,
                            isPrimary: true,
                          ),
                          const SizedBox(height: 12),

                          // ── Start Session CTA ──
                          if (effectiveAvailableNow)
                            GradientButton(
                              onPressed: () =>
                                  _startSession(context, pro, fromList: listPro),
                              width: double.infinity,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.bolt_rounded,
                                    color: Colors.white,
                                    size: 22,
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    t.startSessionNow,
                                    style: GoogleFonts.montserrat(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                ],
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




// ── Status Pill Widget ──
class _StatusPill extends StatelessWidget {
  final String label;
  final Color bgColor;
  final Color borderColor;
  final bool dot;
  final Color? dotColor;
  final IconData? icon;
  final Color? iconColor;

  const _StatusPill({
    required this.label,
    required this.bgColor,
    required this.borderColor,
    this.dot = false,
    this.dotColor,
    this.icon,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: borderColor, width: 1.2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (dot && dotColor != null)
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: dotColor,
                shape: BoxShape.circle,
              ),
            ),
          if (icon != null) Icon(icon, size: 13, color: iconColor),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.montserrat(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Stat Cell Widget ──
class _StatCell extends StatelessWidget {
  final String value;
  final String sub;
  final IconData icon;
  final Color iconColor;
  final bool hasDivider;

  const _StatCell({
    required this.value,
    required this.sub,
    required this.icon,
    required this.iconColor,
    required this.hasDivider,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Row(
        children: [
          if (hasDivider)
            Container(width: 1, height: 40, color: AppColors.borderSubtle),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 20, color: iconColor),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: GoogleFonts.jost(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    sub,
                    style: GoogleFonts.montserrat(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textMuted,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ],
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
        width: double.infinity,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                label,
                style: GoogleFonts.montserrat(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
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
            color: iconColor.withValues(alpha: 0.12),
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
                  fontSize: 11,
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                style: GoogleFonts.montserrat(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
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
  final Color activeColor;

  const _ServiceChip({
    required this.icon,
    required this.label,
    required this.isAvailable,
    this.activeColor = AppColors.mediumPurple,
  });

  @override
  Widget build(BuildContext context) {
    final color = isAvailable ? activeColor : AppColors.textMuted;
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: color.withValues(alpha: isAvailable ? 0.12 : 0.07),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: color.withValues(alpha: isAvailable ? 0.28 : 0.14),
              width: 1.5,
            ),
            boxShadow: isAvailable
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.15),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: Icon(
            icon,
            color: color,
            size: 26,
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
        ? '€${price!.toStringAsFixed(2)}/min'
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
