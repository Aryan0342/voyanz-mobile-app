import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:voyanz/core/providers/language_provider.dart';
import 'package:voyanz/core/theme/app_colors.dart';
import 'package:voyanz/core/theme/widgets.dart';
import 'package:voyanz/features/reviews/providers/reviews_provider.dart';

class CustomerAppointmentsScreen extends ConsumerWidget {
  const CustomerAppointmentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider);
    final history = ref.watch(customerHistoryProvider);
    return DefaultTabController(
      length: 2,
      child: GradientScaffold(
        appBar: VoyanzAppBar(
          showBackButton: true,
          title: Text(t.myAppointments),
          bottom: TabBar(
            tabs: [
              Tab(text: t.upcoming),
              Tab(text: t.past),
            ],
          ),
        ),
        body: SafeArea(
          child: history.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Center(
              child: Text(
                _message(error),
                textAlign: TextAlign.center,
                style: GoogleFonts.montserrat(color: AppColors.textSecondary),
              ),
            ),
            data: (items) {
              final appointments = items
                  .whereType<Map<String, dynamic>>()
                  .where(_isAppointment)
                  .toList();
              final now = DateTime.now();
              final upcoming = appointments
                  .where((item) => (_date(item) ?? DateTime(1970)).isAfter(now))
                  .toList();
              final past = appointments
                  .where(
                    (item) => !(_date(item) ?? DateTime(1970)).isAfter(now),
                  )
                  .toList();
              return TabBarView(
                children: [
                  _AppointmentList(
                    items: upcoming,
                    emptyText: t.noUpcomingAppointments,
                  ),
                  _AppointmentList(
                    items: past,
                    emptyText: t.noPastAppointments,
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _AppointmentList extends StatelessWidget {
  final List<Map<String, dynamic>> items;
  final String emptyText;

  const _AppointmentList({required this.items, required this.emptyText});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Text(
            emptyText,
            textAlign: TextAlign.center,
            style: GoogleFonts.montserrat(color: AppColors.textSecondary),
          ),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: items.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (_, index) {
        final item = items[index];
        return AppCard(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              const Icon(
                Icons.event_available,
                color: AppColors.aqua,
                size: 30,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _title(item),
                      style: GoogleFonts.jost(
                        color: AppColors.textPrimary,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      _dateLabel(item),
                      style: GoogleFonts.montserrat(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

bool _isAppointment(Map<String, dynamic> item) {
  final type = (item['type'] ?? item['subtype'] ?? '').toString().toLowerCase();
  final marker = (item['in_what'] ?? '').toString().toLowerCase();
  // The documented customer-history feed is the v1 source for this screen
  // and merges one-to-one sessions with group-session registrations.
  return type == 'session' ||
      type.contains('registration') ||
      type.contains('appointment') ||
      marker.startsWith('registration_');
}

DateTime? _date(Map<String, dynamic> item) {
  for (final key in const [
    'start',
    'ap_date',
    'date',
    'appointment_date',
    'createdAt',
  ]) {
    final raw = item[key]?.toString();
    if (raw == null || raw.isEmpty) continue;
    final parsed = DateTime.tryParse(raw.replaceFirst(' ', 'T'));
    if (parsed != null) return parsed;
  }
  return null;
}

String _dateLabel(Map<String, dynamic> item) {
  final date = _date(item);
  if (date == null) return (item['date'] ?? '').toString();
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  final hour = date.hour.toString().padLeft(2, '0');
  final minute = date.minute.toString().padLeft(2, '0');
  return '$day/$month/${date.year} · $hour:$minute';
}

String _title(Map<String, dynamic> item) {
  return (item['title'] ??
          item['professional_name'] ??
          item['comment'] ??
          item['label'] ??
          'Voyanz')
      .toString();
}

String _message(Object error) =>
    error.toString().replaceFirst(RegExp(r'^Exception:\s*'), '').trim();
