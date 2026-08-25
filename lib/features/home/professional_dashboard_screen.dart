import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:voyanz/core/theme/app_colors.dart';
import 'package:voyanz/core/theme/app_gradients.dart';
import 'package:voyanz/core/theme/widgets.dart';
import 'package:voyanz/core/utils/ringtone_service.dart';
import 'package:voyanz/features/auth/providers/auth_provider.dart';
import 'package:voyanz/features/reviews/providers/reviews_provider.dart';
import 'package:voyanz/core/providers/language_provider.dart';
import 'package:voyanz/core/l10n/language_switcher.dart';
import 'package:voyanz/core/providers/websocket_provider.dart';
import 'package:voyanz/features/sessions/models/session_type.dart';
import 'package:voyanz/features/sessions/screens/incoming_call_dialog.dart';

/// Dashboard screen for professionals showing upcoming sessions and stats.
class ProfessionalDashboardScreen extends ConsumerStatefulWidget {
  const ProfessionalDashboardScreen({super.key});

  @override
  ConsumerState<ProfessionalDashboardScreen> createState() =>
      _ProfessionalDashboardScreenState();
}

class _ProfessionalDashboardScreenState
    extends ConsumerState<ProfessionalDashboardScreen> {
  Timer? _bannerTimer;

  @override
  void initState() {
    super.initState();
    // Initialize WebSocket connection when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(webSocketServiceProvider).connect();
    });
  }

  @override
  void dispose() {
    _bannerTimer?.cancel();
    // Clean up WebSocket when leaving the screen
    // Note: Don't disconnect here; keep it alive for background notifications
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).valueOrNull;
    // Fetch professional history (sessions)
    final historyAsync = ref.watch(professionalHistoryProvider);

    // Fetch professional reviews
    final reviewsAsync = ref.watch(professionalReviewsProvider);
    final t = ref.watch(translationsProvider);
    final name = _displayName(user, professionalFallback: t.professional);

    // Incoming session handling differs by type:
    // - phone: the backend routes the call directly, so accept silently.
    // - video: show the incoming-call dialog and let the pro accept/decline.
    // - chat:  show a lightweight banner instead of a ringing call modal.
    ref.listen(incomingCallProvider, (previous, next) {
      if (next == null) {
        _stopRingtone();
        return;
      }
      final isNewCall =
          previous == null || previous.customerId != next.customerId;
      if (!isNewCall) return;

      final type = next.type.toLowerCase();
      if (type == 'phone') {
        _acceptCallDirect(next);
        return;
      }

      _startRingtone();
      if (type == 'video') {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const IncomingCallDialog(),
        );
      } else if (type == 'chat') {
        _showIncomingChatBanner(context, next);
      }
    });

    // Listen for session started events and navigate directly to the session.
    ref.listen(sessionStartedProvider, (previous, next) {
      if (next == null) return;
      _stopRingtone();
      ref.read(sessionStartedProvider.notifier).clear();
      _navigateToSession(context, next);
    });

    return GradientScaffold(
      appBar: VoyanzAppBar(
        title: Text(
          t.dashboard,
          style: GoogleFonts.jost(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        actions: const [LanguageSwitcherButton(), SizedBox(width: 8)],
      ),
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // ── Welcome section ──
            SliverToBoxAdapter(
              child: SoftEntrance(
                duration: const Duration(milliseconds: 320),
                offset: const Offset(0, 14),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: _DashboardHeroCard(
                    name: name,
                    subtitle: t.yourProDashboard,
                    onOpenSlots: () => context.go('/availability'),
                    onOpenChat: () => context.go('/chat'),
                  ),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 20)),

            // ── Stats section ──
            SliverToBoxAdapter(
              child: SoftEntrance(
                duration: const Duration(milliseconds: 360),
                offset: const Offset(0, 14),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          title: t.totalSessions,
                          value: historyAsync.when(
                            data: (items) => '${_validSessions(items).length}',
                            loading: () => '-',
                            error: (_, __) => '0',
                          ),
                          icon: Icons.videocam_outlined,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          title: t.avgRating,
                          value: reviewsAsync.when(
                            data: (items) {
                              final validItems = items
                                  .whereType<Map<String, dynamic>>()
                                  .toList();
                              if (validItems.isEmpty) return '0.0';
                              final totalRating = validItems.fold<double>(
                                0,
                                (sum, item) =>
                                    sum +
                                    (double.tryParse(
                                          (item['rv_note'] ??
                                                  item['re_rating'] ??
                                                  '')
                                              .toString(),
                                        ) ??
                                        0),
                              );
                              final avg = (totalRating / validItems.length)
                                  .toStringAsFixed(1);
                              return avg;
                            },
                            loading: () => '-',
                            error: (_, __) => '0.0',
                          ),
                          icon: Icons.star_outline,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 12)),

            SliverToBoxAdapter(
              child: SoftEntrance(
                duration: const Duration(milliseconds: 400),
                offset: const Offset(0, 14),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _StatCard(
                    title: t.upcomingSessions,
                    value: historyAsync.when(
                      data: (items) {
                        final upcoming = _validSessions(items).where((s) {
                          final status = _sessionStatus(s).toLowerCase();
                          return status == 'pending' ||
                              status == 'calling' ||
                              status == 'accepted' ||
                              status == 'inprogress';
                        }).length;
                        return '$upcoming';
                      },
                      loading: () => '-',
                      error: (_, __) => '0',
                    ),
                    icon: Icons.schedule,
                  ),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 24)),

            // ── Recent Sessions ──
            SliverToBoxAdapter(
              child: SoftEntrance(
                duration: const Duration(milliseconds: 440),
                offset: const Offset(0, 14),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    t.recentSessions,
                    style: GoogleFonts.jost(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 12)),

            historyAsync.when(
              data: (items) {
                if (items.isEmpty) {
                  return SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: AppCard(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            Container(
                              width: 54,
                              height: 54,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.mediumPurple.withValues(alpha: 0.1),
                              ),
                              child: const Icon(
                                Icons.inbox_outlined,
                                size: 28,
                                color: AppColors.mediumPurple,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              t.noSessionsYet,
                              style: GoogleFonts.manrope(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }

                final validItems = _validSessions(items).toList()
                  ..sort(_compareSessionsNewestFirst);
                final recentItems = validItems.take(5).toList();

                return SliverList(
                  delegate: SliverChildBuilderDelegate((context, idx) {
                    if (idx >= recentItems.length) {
                      return const SizedBox.shrink();
                    }
                    final session = recentItems[idx];
                    final clientName = _clientName(
                      session,
                      unknownFallback: t.unknown,
                    );
                    final rawType = _sessionType(session);
                    final sessionType = _localizedDashboardType(rawType, t);
                    final rawStatus = _sessionStatus(session);
                    final localizedStatus = _localizedDashboardStatus(
                      rawStatus,
                      t,
                    );
                    final sessionDate = _formatSessionDate(
                      _sessionValue(session, const [
                        'se_date',
                        'session_date',
                        'date',
                        'created_at',
                        'start_at',
                      ]),
                    );
                    final duration = _sessionValue(session, const [
                      'se_duration',
                      'duration',
                      'call_duration',
                      'timef',
                    ]);
                    final price = _sessionValue(session, const [
                      'totalf',
                      'pricef',
                      'price',
                    ]);

                    final statusColor = rawStatus == 'completed'
                        ? AppColors.success
                        : rawStatus == 'cancelled'
                            ? AppColors.error
                            : rawStatus == 'pending'
                                ? AppColors.warning
                                : AppColors.mediumPurple;
                    final statusIcon = rawStatus == 'completed'
                        ? Icons.check_circle_outline
                        : rawStatus == 'cancelled'
                            ? Icons.cancel_outlined
                            : Icons.schedule;

                    final typeIcon = rawType == 'phone'
                        ? Icons.phone_in_talk_outlined
                        : rawType == 'chat'
                            ? Icons.chat_bubble_outline
                            : Icons.videocam_outlined;

                    return SoftEntrance(
                      duration: Duration(milliseconds: 320 + (idx * 40)),
                      offset: const Offset(0, 10),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 6,
                        ),
                        child: AppCard(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      color: AppColors.mediumPurple.withValues(
                                        alpha: 0.10,
                                      ),
                                    ),
                                    child: Icon(
                                      typeIcon,
                                      size: 20,
                                      color: AppColors.mediumPurple,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          clientName,
                                          style: GoogleFonts.manrope(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.textPrimary,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          sessionType,
                                          style: GoogleFonts.manrope(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  StatusPill(
                                    label: localizedStatus,
                                    color: statusColor,
                                    icon: statusIcon,
                                  ),
                                ],
                              ),
                              if (sessionDate.isNotEmpty) ...[
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.calendar_today_outlined,
                                      size: 13,
                                      color: AppColors.textMuted,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      sessionDate,
                                      style: GoogleFonts.manrope(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: AppColors.textMuted,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                              if (duration.isNotEmpty || price.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    if (duration.isNotEmpty) ...[
                                      const Icon(
                                        Icons.schedule,
                                        size: 13,
                                        color: AppColors.textMuted,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        duration,
                                        style: GoogleFonts.manrope(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                          color: AppColors.textMuted,
                                        ),
                                      ),
                                    ],
                                    if (duration.isNotEmpty &&
                                        price.isNotEmpty) ...[
                                      const SizedBox(width: 14),
                                    ],
                                    if (price.isNotEmpty) ...[
                                      const Icon(
                                        Icons.payments_outlined,
                                        size: 13,
                                        color: AppColors.textMuted,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        price,
                                        style: GoogleFonts.manrope(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    );
                  }, childCount: validItems.length),
                );
              },
              loading: () => const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.mediumPurple),
                  ),
                ),
              ),
              error: (e, st) => SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: AppCard(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 44,
                          color: AppColors.error,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          t.failedLoadSessions,
                          style: GoogleFonts.manrope(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
      ),
    );
  }

  /// Accepts a session silently (used for phone, where the backend routes the
  /// call directly without any accept/reject prompt).
  void _acceptCallDirect(IncomingCall call) {
    final ws = ref.read(webSocketServiceProvider);
    final notifier = ref.read(incomingCallProvider.notifier);
    notifier.markAccepted();
    ws.send('session_callaccepted', {
      'callParams': call.toCallParams(),
      'isGroupSession': call.appointmentId != null,
    });
    notifier.clear();
  }

  /// Shows a non-blocking banner for an incoming chat session instead of a
  /// ringing call modal. Auto-dismisses after 20s.
  void _showIncomingChatBanner(BuildContext context, IncomingCall call) {
    final messenger = ScaffoldMessenger.of(context);
    final notifier = ref.read(incomingCallProvider.notifier);
    final customerName = call.customerFullname ?? 'Customer';

    _bannerTimer?.cancel();
    _bannerTimer = Timer(const Duration(seconds: 20), () {
      if (mounted && ref.read(incomingCallProvider) != null) {
        notifier.clear();
      }
      messenger.hideCurrentMaterialBanner();
    });

    messenger
      ..hideCurrentMaterialBanner()
      ..showMaterialBanner(
        MaterialBanner(
          backgroundColor: AppColors.surfaceCard,
          leading: const Icon(
            Icons.chat_bubble_outline,
            color: AppColors.mediumPurple,
            size: 28,
          ),
          content: Text(
            'New chat session from $customerName',
            style: GoogleFonts.manrope(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                _bannerTimer?.cancel();
                messenger.hideCurrentMaterialBanner();
                _acceptCallDirect(call);
              },
              child: Text(
                'Open',
                style: GoogleFonts.manrope(fontWeight: FontWeight.w700),
              ),
            ),
            TextButton(
              onPressed: () {
                _bannerTimer?.cancel();
                messenger.hideCurrentMaterialBanner();
                notifier.clear();
              },
              child: Text(
                'Dismiss',
                style: GoogleFonts.manrope(color: AppColors.textMuted),
              ),
            ),
          ],
        ),
      );
  }

  void _startRingtone() {
    ref.read(ringtoneServiceProvider).start();
  }

  void _stopRingtone() {
    ref.read(ringtoneServiceProvider).stop();
  }

  void _navigateToSession(BuildContext context, SessionStartedEvent event) {
    final seId = event.seId;
    final coId = event.coIdCustomer.isNotEmpty
        ? event.coIdCustomer
        : event.coIdProfessional;
    final seType = event.seType.toLowerCase();

    // Navigate based on session type
    if (seType == 'video') {
      context.push('/video/$seId/$coId');
    } else if (seType == 'phone') {
      context.push('/session/phone/$seId/$coId');
    } else if (seType == 'chat') {
      final chgrId = event.chgrId;
      if (chgrId != null && chgrId.isNotEmpty) {
        context.push('/chat/$chgrId?seId=$seId&coId=$coId');
        return;
      }
      context.push('/session/chat/$seId/$coId');
    }
  }
}

class _DashboardHeroCard extends StatelessWidget {
  final String name;
  final String subtitle;
  final VoidCallback onOpenSlots;
  final VoidCallback onOpenChat;

  const _DashboardHeroCard({
    required this.name,
    required this.subtitle,
    required this.onOpenSlots,
    required this.onOpenChat,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppGradients.accent,
                ),
                child: const Icon(
                  Icons.person_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome back, $name',
                      style: GoogleFonts.jost(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: GoogleFonts.manrope(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: GradientButton(
                  onPressed: onOpenSlots,
                  height: 46,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.calendar_today_outlined, size: 16, color: Colors.white),
                      SizedBox(width: 8),
                      Text('Manage Slots'),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SoftPress(
                  onTap: onOpenChat,
                  child: Container(
                    height: 46,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceCard,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.borderStrong),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.chat_bubble_outline,
                          size: 16,
                          color: AppColors.textPrimary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Messages',
                          style: GoogleFonts.manrope(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RevealIn extends StatelessWidget {
  final Widget child;
  final int delayMs;

  const _RevealIn({required this.child, this.delayMs = 0});

  @override
  Widget build(BuildContext context) {
    return SoftEntrance(
      duration: Duration(milliseconds: 340 + delayMs),
      offset: const Offset(0, 12),
      child: child,
    );
  }
}

String _displayName(
  dynamic user, {
  String professionalFallback = 'Professional',
}) {
  if (user == null) return professionalFallback;
  final full = '${user.firstName ?? ''} ${user.lastName ?? ''}'.trim();
  if (full.isNotEmpty) return full;
  final email = (user.email ?? '').toString();
  if (email.contains('@')) return email.split('@').first;
  return professionalFallback;
}

List<Map<String, dynamic>> _validSessions(List<dynamic> items) {
  return items.whereType<Map<String, dynamic>>().where((item) {
    final type =
        (item['type'] ?? item['se_type'] ?? item['subtype'] ?? '')
            .toString()
            .toLowerCase();
    if (type.isNotEmpty) return type == 'session';
    return item.containsKey('se_id') ||
        item.containsKey('se_status') ||
        item.containsKey('se_type') ||
        item.containsKey('se_date') ||
        item.containsKey('id');
  }).toList();
}

/// Reads the first non-empty value for any of the given keys, checking the
/// nested `session` map first (legacy backend shape) then the item itself.
String _sessionValue(Map<String, dynamic> item, List<String> keys) {
  final nested = item['session'];
  final maps = [
    if (nested is Map<String, dynamic>) nested,
    item,
  ];
  for (final map in maps) {
    for (final key in keys) {
      final value = map[key];
      if (value == null) continue;
      final text = value.toString().trim();
      if (text.isNotEmpty) return text;
    }
  }
  return '';
}

String _clientName(
  Map<String, dynamic> session, {
  String unknownFallback = 'Unknown',
}) {
  final name = _sessionValue(session, const [
    'co_fullname',
    'co_display_name',
    'customer_name',
    'client_name',
    'co_name',
    'name',
  ]);
  if (name.isNotEmpty) return name;
  final fromTitle = _nameFromTitle(session['title']?.toString() ?? '');
  return fromTitle.isEmpty ? unknownFallback : fromTitle;
}

/// Extracts the customer name from backend `title` values. The backend either
/// returns the customer name directly ("Client QA Ghazi") or a French label
/// like "Séance vidéo avec Jean Dupont" / "Session with John Smith" — in the
/// latter case the name is the part after "avec"/"with".
String _nameFromTitle(String title) {
  final text = title.trim();
  if (text.isEmpty) return '';
  final match =
      RegExp(r'(?:avec|with)\s+([^:\-–—]+)$', caseSensitive: false)
          .firstMatch(text);
  if (match == null) return text;
  final name = match.group(1)?.trim() ?? '';
  if (name.isEmpty || name.toLowerCase().contains('session')) return text;
  return name;
}

String _sessionType(Map<String, dynamic> session) {
  final raw = _sessionValue(session, const [
    'se_type',
    'se_type_label',
    'session_type',
    'session_type_label',
    'subtype',
    'typecall',
    'type',
    'se_mode',
  ]);
  final normalized = normalizeSessionType(raw);
  return normalized ?? raw.toLowerCase();
}

String _sessionStatus(Map<String, dynamic> session) {
  final raw = _sessionValue(session, const [
    'se_status',
    'seStatus',
    'session_status',
    'status',
    'state',
    'se_state',
  ]);
  var normalized = _canonicalStatus(raw);
  if (_isKnownHistoryStatus(normalized)) return normalized;

  final duration = _sessionValue(session, const [
    'se_duration',
    'duration',
    'call_duration',
    'timef',
  ]);
  final endedAt = _sessionValue(session, const [
    'ended_at',
    'end_at',
    'se_end_at',
  ]);
  final isEnded = session['is_ended'] == true || session['ended'] == true;
  final price = (session['pricef'] ?? session['price'] ?? session['totalf'] ?? '')
      .toString();
  final recordings = session['recording'];
  final hasRecordings = recordings is List && recordings.isNotEmpty;

  if (isEnded || endedAt.isNotEmpty) return 'completed';

  if (duration.isNotEmpty && duration != '--' && duration != '00s') {
    return 'completed';
  }

  if (hasRecordings) return 'completed';

  if (duration.isEmpty || duration == '00s' || duration == '--') {
    return 'cancelled';
  }

  if (price.startsWith('-')) return 'completed';

  return normalized.isEmpty ? 'pending' : normalized;
}

String _canonicalStatus(String value) {
  if (value.isEmpty) return '';

  final raw = value.toLowerCase().trim();
  final compact = raw
      .replaceAll(RegExp(r'[\s_\-]+'), '')
      .replaceAll('é', 'e')
      .replaceAll('è', 'e')
      .replaceAll('ê', 'e')
      .replaceAll('ë', 'e')
      .replaceAll('à', 'a')
      .replaceAll('â', 'a')
      .replaceAll('î', 'i')
      .replaceAll('ï', 'i')
      .replaceAll('ô', 'o')
      .replaceAll('ö', 'o')
      .replaceAll('ù', 'u')
      .replaceAll('û', 'u')
      .replaceAll('ü', 'u');

  if (compact == 'completed' ||
      compact == 'complete' ||
      compact == 'done' ||
      compact == 'finished' ||
      compact == 'close' ||
      compact == 'closed' ||
      compact == 'success' ||
      compact == 'terminee' ||
      compact == 'termine') {
    return 'completed';
  }
  if (compact == 'cancelled' ||
      compact == 'canceled' ||
      compact == 'rejected' ||
      compact == 'annulee' ||
      compact == 'annule') {
    return 'cancelled';
  }
  if (compact == 'pending' ||
      compact == 'waiting' ||
      compact == 'queued' ||
      compact == 'enattente') {
    return 'pending';
  }
  if (compact == 'inprogress' ||
      compact == 'active' ||
      compact == 'ongoing' ||
      compact == 'encours') {
    return 'inprogress';
  }
  if (compact == 'calling' || compact == 'appelencours') return 'calling';
  if (compact == 'accepted' || compact == 'acceptee' || compact == 'accepte') {
    return 'accepted';
  }
  return compact;
}

bool _isKnownHistoryStatus(String status) {
  return status == 'completed' ||
      status == 'cancelled' ||
      status == 'canceled' ||
      status == 'pending' ||
      status == 'accepted' ||
      status == 'calling' ||
      status == 'inprogress';
}

String _formatSessionDate(String raw) {
  if (raw.isEmpty) return raw;
  final normalized = raw.replaceFirst(' ', 'T');
  final parsed = DateTime.tryParse(normalized);
  if (parsed == null) return raw;
  final mm = parsed.month.toString().padLeft(2, '0');
  final dd = parsed.day.toString().padLeft(2, '0');
  final hh = parsed.hour.toString().padLeft(2, '0');
  final min = parsed.minute.toString().padLeft(2, '0');
  return '${parsed.year}-$mm-$dd $hh:$min';
}

DateTime? _parseSessionDateTime(String raw) {
  if (raw.isEmpty) return null;
  return DateTime.tryParse(raw.replaceFirst(' ', 'T'));
}

/// Sort sessions by their date/time, newest first, so the Recent Sessions
/// section always shows the latest consultations regardless of API ordering.
int _compareSessionsNewestFirst(
  Map<String, dynamic> a,
  Map<String, dynamic> b,
) {
  final da = _parseSessionDateTime(
    _sessionValue(a, const [
      'se_date',
      'session_date',
      'date',
      'created_at',
      'start_at',
    ]),
  );
  final db = _parseSessionDateTime(
    _sessionValue(b, const [
      'se_date',
      'session_date',
      'date',
      'created_at',
      'start_at',
    ]),
  );
  if (da != null && db != null) return db.compareTo(da);
  if (da != null) return -1;
  if (db != null) return 1;
  return 0;
}

String _localizedDashboardType(String type, dynamic t) {
  switch (type.toLowerCase()) {
    case 'phone':
      return t.phoneCall;
    case 'video':
      return t.videoCall;
    case 'chat':
      return t.textChat;
    default:
      return type.isEmpty ? t.session : type;
  }
}

String _localizedDashboardStatus(String status, dynamic t) {
  switch (status.toLowerCase()) {
    case 'completed':
      return t.completed;
    case 'cancelled':
    case 'canceled':
      return t.cancelled;
    case 'pending':
      return t.pending;
    case 'accepted':
      return t.sessionStatusAcceptedLabel;
    case 'calling':
      return t.sessionStatusCallingLabel;
    case 'inprogress':
      return t.sessionStatusInProgressLabel;
    default:
      return status.isEmpty ? t.unknown : status;
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.manrope(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: AppColors.mediumPurple.withValues(alpha: 0.11),
                ),
                child: Icon(icon, size: 15, color: AppColors.mediumPurple),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.jost(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
