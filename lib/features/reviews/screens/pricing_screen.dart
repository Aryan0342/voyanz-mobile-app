import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:voyanz/core/providers/language_provider.dart';
import 'package:voyanz/core/theme/app_colors.dart';
import 'package:voyanz/core/theme/widgets.dart';
import 'package:voyanz/features/auth/providers/auth_provider.dart';
import 'package:voyanz/features/appointments/providers/appointments_provider.dart';
import 'package:voyanz/features/professionals/models/professional.dart';
import 'package:voyanz/features/professionals/providers/professionals_provider.dart';
import 'package:voyanz/features/reviews/providers/reviews_provider.dart';
import 'package:voyanz/features/sessions/data/sessions_data_source.dart';
import 'package:voyanz/features/sessions/models/session_status.dart';
import 'package:voyanz/features/sessions/models/session_type.dart';
import 'package:voyanz/features/sessions/navigation/session_navigation.dart';
import 'package:voyanz/features/sessions/providers/sessions_provider.dart';

class PricingScreen extends ConsumerStatefulWidget {
  final String? coId;

  const PricingScreen({super.key, this.coId});

  @override
  ConsumerState<PricingScreen> createState() => _PricingScreenState();
}

class _PricingScreenState extends ConsumerState<PricingScreen> {
  String? _selectedPricingKey;
  final _promoCtrl = TextEditingController();

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

  @override
  void dispose() {
    _promoCtrl.dispose();
    super.dispose();
  }

  Future<void> _applyPromoCode() async {
    final t = ref.read(translationsProvider);
    final code = _promoCtrl.text.trim();
    if (code.isEmpty) return;

    try {
      final result = await ref
          .read(reviewsHistoryRepositoryProvider)
          .checkPromoCode(code);
      final valid = result['valid'] == true || result['isValid'] == true;
      final discount =
          result['discount']?.toString() ??
          result['percent']?.toString() ??
          '0';

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            valid ? t.promoApplied(code, discount) : t.promoInvalid,
          ),
          backgroundColor: valid ? AppColors.online : AppColors.error,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(t.promoCheckFailed(e.toString())),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<List<_AppointmentCandidate>> _loadAppointmentCandidates() async {
    final candidates = <_AppointmentCandidate>[];
    final seen = <String>{};

    void addCandidate(String id, String label) {
      final key = '$id|$label';
      if (id.isEmpty || seen.contains(key)) return;
      seen.add(key);
      candidates.add(_AppointmentCandidate(id: id, label: label));
    }

    try {
      final history = await ref
          .read(reviewsHistoryRepositoryProvider)
          .getCustomerHistory();
      for (final row in history) {
        if (row is! Map<String, dynamic>) continue;
        final apId =
            row['ap_id']?.toString() ??
            row['appointment_id']?.toString() ??
            row['apId']?.toString();
        final date =
            row['se_date']?.toString() ?? row['date']?.toString() ?? '';
        final name =
            row['co_fullname']?.toString() ?? row['co_name']?.toString() ?? '';
        if (apId != null && apId.trim().isNotEmpty) {
          addCandidate(
            apId.trim(),
            '$name ${date.isNotEmpty ? '- $date' : ''}'.trim(),
          );
        }
      }
    } catch (_) {}

    try {
      final dispo = await ref
          .read(professionalsRepositoryProvider)
          .getDisponibilities();
      for (final row in dispo) {
        if (row is! Map<String, dynamic>) continue;
        final apId =
            row['ap_id']?.toString() ??
            row['appointment_id']?.toString() ??
            row['apId']?.toString() ??
            row['di_id']?.toString();
        if (apId == null || apId.trim().isEmpty) continue;
        final day = row['day']?.toString() ?? row['di_day']?.toString() ?? '';
        final hourFrom =
            row['di_hour_from']?.toString() ?? row['time']?.toString() ?? '';
        final hourTo = row['di_hour_to']?.toString() ?? '';
        final slotLabel = (hourFrom.isNotEmpty && hourTo.isNotEmpty)
            ? '$hourFrom-$hourTo'
            : hourFrom;
        addCandidate(
          apId.trim(),
          '${day.isNotEmpty ? '$day ' : ''}${slotLabel.trim()}'.trim(),
        );
      }
    } catch (_) {}

    return candidates;
  }

  // ignore: unused_element
  Future<void> _registerAppointment() async {
    final t = ref.read(translationsProvider);
    final candidates = await _loadAppointmentCandidates();

    if (!mounted) return;
    if (candidates.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(t.noAppointmentCandidates),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final searchCtrl = TextEditingController();
    String? selectedApId;

    final shouldSubmit = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final q = searchCtrl.text.trim().toLowerCase();
          final filtered = q.isEmpty
              ? candidates
              : candidates
                    .where(
                      (c) =>
                          c.id.toLowerCase().contains(q) ||
                          c.label.toLowerCase().contains(q),
                    )
                    .toList();

          return AlertDialog(
            backgroundColor: AppColors.surfaceCard,
            title: Text(
              t.selectAppointment,
              style: GoogleFonts.jost(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            content: SizedBox(
              width: 420,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: searchCtrl,
                    decoration: InputDecoration(
                      labelText: t.searchAppointments,
                      prefixIcon: const Icon(Icons.search),
                    ),
                    onChanged: (_) => setDialogState(() {}),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 280,
                    child: ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (_, i) {
                        final item = filtered[i];
                        final selected = selectedApId == item.id;
                        return ListTile(
                          onTap: () =>
                              setDialogState(() => selectedApId = item.id),
                          leading: Icon(
                            selected
                                ? Icons.radio_button_checked
                                : Icons.radio_button_unchecked,
                            color: selected
                                ? AppColors.rosePink
                                : AppColors.textMuted,
                          ),
                          title: Text(item.id),
                          subtitle: item.label.isEmpty
                              ? null
                              : Text(item.label),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: Text(t.cancel),
              ),
              FilledButton(
                onPressed: selectedApId == null
                    ? null
                    : () => Navigator.of(ctx).pop(true),
                child: Text(t.registerAppointment),
              ),
            ],
          );
        },
      ),
    );

    if (shouldSubmit != true || selectedApId == null) return;

    try {
      await ref.read(appointmentsRepositoryProvider).register(selectedApId!);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(t.appointmentRegistered),
          backgroundColor: AppColors.online,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(t.appointmentRegistrationFailed(e.toString())),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  String? _resolveSelectedSessionType(
    dynamic t,
    dynamic professional, {
    Professional? fromList,
  }) {
    if (_selectedPricingKey == t.phoneCall) return 'phone';
    if (_selectedPricingKey == t.videoCall) return 'video';
    if (_selectedPricingKey == t.textChat) return 'chat';

    final supportsPhone =
        (professional.supportsPhone as bool? ?? false) ||
        (fromList?.supportsPhone ?? false);
    final supportsVideo =
        (professional.supportsVideo as bool? ?? false) ||
        (fromList?.supportsVideo ?? false);
    final supportsChat =
        (professional.supportsChat as bool? ?? false) ||
        (fromList?.supportsChat ?? false);

    if (supportsPhone) return 'phone';
    if (supportsVideo) return 'video';
    if (supportsChat) return 'chat';
    return null;
  }

  Future<void> _startSessionFromPricing(
    dynamic professional, {
    Professional? fromList,
  }) async {
    final t = ref.read(translationsProvider);
    final type = _resolveSelectedSessionType(
      t,
      professional,
      fromList: fromList,
    );
    final normalizedType = normalizeSessionType(type);
    if (type == null || widget.coId == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(t.chooseSessionType),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    if (normalizedType == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(t.chooseSessionType),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final activeSeId = await _recoverRecentSessionId(expectedCoId: widget.coId);
    if (!mounted) return;
    if (activeSeId != null && activeSeId.isNotEmpty) {
      context.push('/session/wait/$normalizedType/$activeSeId/${widget.coId!}');
      return;
    }

    try {
      final launch = await ref
          .read(sessionsRepositoryProvider)
          .createSessionCall(typeCall: normalizedType, coId: widget.coId!);
      if (!mounted) return;
      openLaunchResult(
        context,
        launch,
        fallbackType: normalizedType,
        coId: widget.coId!,
      );
    } on SessionAuthExpiredException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(t.errorMessage(e.toString())),
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
          ),
        );
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
          coId: widget.coId!,
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
          expectedCoId: widget.coId,
        );
        if (!mounted) return;
        if (await tryOpenIfJoinable(recoveredSeId)) return;

        try {
          final freshLaunch = await ref
              .read(sessionsRepositoryProvider)
              .createSessionCall(typeCall: normalizedType, coId: widget.coId!);
          if (!mounted) return;
          openLaunchResult(
            context,
            freshLaunch,
            fallbackType: normalizedType,
            coId: widget.coId!,
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
                  coId: widget.coId!,
                );
            if (!mounted) return;
            openLaunchResult(
              context,
              retriedLaunch,
              fallbackType: normalizedType,
              coId: widget.coId!,
            );
            return;
          } on SessionLaunchException catch (secondError) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(t.errorMessage(secondError.toString())),
                backgroundColor: AppColors.error,
                behavior: SnackBarBehavior.floating,
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
                : t.errorMessage(e.toString()),
          ),
          backgroundColor: AppColors.error,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(t.errorMessage(e.toString())),
          backgroundColor: AppColors.error,
        ),
      );
    }
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

  void _selectPricing(String key) {
    setState(() {
      _selectedPricingKey = key;
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(translationsProvider);
    // If coId is provided, show professional pricing; otherwise show customer pricing
    if (widget.coId != null) {
      final professionalAsync = ref.watch(
        professionalDetailProvider(widget.coId!),
      );
      final listAsync = ref.watch(professionalsListProvider);

      return GradientScaffold(
        appBar: VoyanzAppBar(
          title: Text(
            t.sessionPricing,
            style: GoogleFonts.jost(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
        body: professionalAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.mediumPurple),
          ),
          error: (e, _) => Center(
            child: Text(
              t.errorMessage('$e'),
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ),
          data: (professional) {
            final list = listAsync.asData?.value ?? const <Professional>[];
            Professional? fromList;
            for (final item in list) {
              if (item.coId == widget.coId) {
                fromList = item;
                break;
              }
            }

            return Column(
              children: [
                Expanded(
                  child: _buildSessionPricingList(
                    professional,
                    fromList: fromList,
                    t: t,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _startSessionFromPricing(
                        professional,
                        fromList: fromList,
                      ),
                      icon: const Icon(Icons.play_circle_outline),
                      label: Text(t.startSessionNow),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      );
    } else {
      // Original customer pricing screen
      final pricingAsync = ref.watch(customerPricingProvider);

      return GradientScaffold(
        appBar: VoyanzAppBar(
          title: Text(
            t.pricing,
            style: GoogleFonts.jost(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
        body: pricingAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.mediumPurple),
          ),
          error: (e, _) => Center(
            child: Text(
              t.errorMessage('$e'),
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ),
          data: (pricing) {
            if (pricing.isEmpty) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.payments_outlined,
                      size: 64,
                      color: AppColors.textMuted.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      t.noPricingInfo,
                      style: GoogleFonts.montserrat(
                        color: AppColors.textMuted,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              );
            }
            final entries = pricing.entries.toList();
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _promoCtrl,
                          decoration: InputDecoration(
                            labelText: t.promoCode,
                            prefixIcon: const Icon(Icons.local_offer_outlined),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      FilledButton(
                        onPressed: _applyPromoCode,
                        child: Text(t.applyPromo),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                    itemCount: entries.length,
                    itemBuilder: (_, i) {
                      final entry = entries[i];
                      return _buildPricingTile(
                        title: entry.key,
                        value: entry.value.toString(),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      );
    }
  }

  Widget _buildSessionPricingList(
    dynamic professional, {
    Professional? fromList,
    required dynamic t,
  }) {
    final pricing = <String, String>{};
    final fallback =
        professional.pricePerMinute as double? ?? fromList?.pricePerMinute;
    String formatPrice(double value) {
      final normalized = value > 20 ? value / 100 : value;
      return '€${normalized.toStringAsFixed(2)}/min';
    }

    final phonePrice =
        professional.pricePhonePerMinute as double? ??
        fromList?.pricePhonePerMinute;
    final videoPrice =
        professional.priceVideoPerMinute as double? ??
        fromList?.priceVideoPerMinute;
    final chatPrice =
        professional.priceChatPerMinute as double? ??
        fromList?.priceChatPerMinute;

    final supportsPhone =
        (professional.supportsPhone as bool? ?? false) ||
        (fromList?.supportsPhone ?? false);
    final supportsVideo =
        (professional.supportsVideo as bool? ?? false) ||
        (fromList?.supportsVideo ?? false);
    final supportsChat =
        (professional.supportsChat as bool? ?? false) ||
        (fromList?.supportsChat ?? false);

    if (phonePrice != null) {
      pricing[t.phoneCall] = formatPrice(phonePrice);
    } else if (supportsPhone && fallback != null) {
      pricing[t.phoneCall] = formatPrice(fallback);
    }

    if (videoPrice != null) {
      pricing[t.videoCall] = formatPrice(videoPrice);
    } else if (supportsVideo && fallback != null) {
      pricing[t.videoCall] = formatPrice(fallback);
    }

    if (chatPrice != null) {
      pricing[t.textChat] = formatPrice(chatPrice);
    } else if (supportsChat && fallback != null) {
      pricing[t.textChat] = formatPrice(fallback);
    }

    // Some profiles only provide one generic price without session flags.
    if (pricing.isEmpty && fallback != null) {
      pricing[t.consultation] = formatPrice(fallback);
    }

    if (pricing.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.payments_outlined,
              size: 64,
              color: AppColors.textMuted.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              t.noPricingAvailable,
              style: GoogleFonts.montserrat(
                color: AppColors.textMuted,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    final entries = pricing.entries.toList();
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      itemCount: entries.length,
      itemBuilder: (_, i) {
        final entry = entries[i];
        return _buildPricingTile(title: entry.key, value: entry.value);
      },
    );
  }

  Widget _buildPricingTile({required String title, required String value}) {
    final isSelected = _selectedPricingKey == title;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => _selectPricing(title),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: isSelected
                  ? AppColors.mediumPurple.withValues(alpha: 0.11)
                  : AppColors.surfaceCard,
              border: Border.all(
                color: isSelected
                    ? AppColors.mediumPurple
                    : AppColors.borderSubtle,
                width: isSelected ? 1.6 : 1,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: GoogleFonts.montserrat(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  Text(
                    value,
                    style: GoogleFonts.jost(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: isSelected
                          ? AppColors.textPrimary
                          : AppColors.mediumPurple,
                    ),
                  ),
                  if (isSelected) ...[
                    const SizedBox(width: 10),
                    const Icon(
                      Icons.check_circle,
                      color: AppColors.mediumPurple,
                      size: 18,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AppointmentCandidate {
  final String id;
  final String label;

  const _AppointmentCandidate({required this.id, required this.label});
}
