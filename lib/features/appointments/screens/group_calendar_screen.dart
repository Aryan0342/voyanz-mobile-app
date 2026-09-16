import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:voyanz/core/providers/language_provider.dart';
import 'package:voyanz/core/theme/app_colors.dart';
import 'package:voyanz/core/theme/widgets.dart';
import 'package:voyanz/features/appointments/providers/appointments_provider.dart';
import 'package:voyanz/features/reviews/providers/reviews_provider.dart';
import 'package:voyanz/features/sessions/widgets/insufficient_balance_dialog.dart';

class GroupCalendarScreen extends ConsumerWidget {
  const GroupCalendarScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider);
    final sessions = ref.watch(publicVideoSessionsProvider);
    return GradientScaffold(
      appBar: VoyanzAppBar(showBackButton: true, title: Text(t.groupCalendar)),
      body: SafeArea(
        child: sessions.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(child: Text(_clean(error))),
          data: (items) => RefreshIndicator(
            onRefresh: () => ref.refresh(publicVideoSessionsProvider.future),
            child: items.isEmpty
                ? ListView(
                    children: [
                      const SizedBox(height: 180),
                      Center(child: Text(t.noGroupSessions)),
                    ],
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(20),
                    itemCount: items.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 14),
                    itemBuilder: (_, index) =>
                        _GroupSessionCard(item: items[index]),
                  ),
          ),
        ),
      ),
    );
  }
}

class _GroupSessionCard extends ConsumerStatefulWidget {
  final Map<String, dynamic> item;

  const _GroupSessionCard({required this.item});

  @override
  ConsumerState<_GroupSessionCard> createState() => _GroupSessionCardState();
}

class _GroupSessionCardState extends ConsumerState<_GroupSessionCard> {
  bool _loading = false;

  Future<void> _register() async {
    final t = ref.read(translationsProvider);
    final props = widget.item['extendedProps'] is Map<String, dynamic>
        ? widget.item['extendedProps'] as Map<String, dynamic>
        : const <String, dynamic>{};
    final apId = (props['ap_id'] ?? widget.item['id'])?.toString() ?? '';
    if (apId.isEmpty) return;
    setState(() => _loading = true);
    try {
      await ref.read(appointmentsRepositoryProvider).register(apId);
      ref.invalidate(customerHistoryProvider);
      ref.invalidate(publicVideoSessionsProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(t.appointmentRegistered),
          backgroundColor: AppColors.online,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      final message = _clean(error);
      if (message.toUpperCase().contains('INSUFFICIENT_BALANCE') ||
          message.toLowerCase().contains('solde insuffisant')) {
        await showInsufficientBalanceDialog(context, t, serverMessage: message);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(translationsProvider);
    final props = widget.item['extendedProps'] is Map<String, dynamic>
        ? widget.item['extendedProps'] as Map<String, dynamic>
        : const <String, dynamic>{};
    return AppCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            (widget.item['title'] ?? t.groupSession).toString(),
            style: GoogleFonts.jost(
              color: AppColors.textPrimary,
              fontSize: 19,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${_date(widget.item['start'])} · ${(props['professional_name'] ?? '').toString()}',
            style: GoogleFonts.montserrat(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 6),
          Text(
            (props['ap_pricef'] ?? '').toString(),
            style: GoogleFonts.montserrat(
              color: AppColors.aqua,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _loading ? null : _register,
              child: Text(
                _loading ? t.loadingAppointments : t.registerAppointment,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _date(dynamic value) {
  final parsed = DateTime.tryParse(
    value?.toString().replaceFirst(' ', 'T') ?? '',
  );
  if (parsed == null) return value?.toString() ?? '';
  return '${parsed.day.toString().padLeft(2, '0')}/'
      '${parsed.month.toString().padLeft(2, '0')}/${parsed.year} '
      '${parsed.hour.toString().padLeft(2, '0')}:'
      '${parsed.minute.toString().padLeft(2, '0')}';
}

String _clean(Object error) =>
    error.toString().replaceFirst(RegExp(r'^Exception:\s*'), '').trim();
