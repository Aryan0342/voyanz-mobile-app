import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:voyanz/core/config/env.dart';
import 'package:voyanz/core/providers/language_provider.dart';
import 'package:voyanz/core/theme/app_colors.dart';
import 'package:voyanz/core/theme/app_gradients.dart';
import 'package:voyanz/core/theme/widgets.dart';
import 'package:voyanz/features/auth/providers/auth_provider.dart';
import 'package:voyanz/features/professionals/models/professional.dart';
import 'package:voyanz/features/professionals/providers/professionals_provider.dart';
import 'package:voyanz/features/reviews/providers/reviews_provider.dart';

class ReviewsScreen extends ConsumerStatefulWidget {
  final bool isProfessional;

  const ReviewsScreen({super.key, this.isProfessional = false});

  @override
  ConsumerState<ReviewsScreen> createState() => _ReviewsScreenState();
}

class _ReviewsScreenState extends ConsumerState<ReviewsScreen> {
  String _selectedFilter = 'All';

  Map<int, int> _buildRatingBreakdown(List<Map<String, dynamic>> reviews) {
    final result = <int, int>{1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
    for (final review in reviews) {
      final value = _reviewRating(review).round();
      if (value >= 1 && value <= 5) {
        result[value] = (result[value] ?? 0) + 1;
      }
    }
    return result;
  }

  Future<void> _submitReview() async {
    final t = ref.read(translationsProvider);
    double rating = 5;
    final commentCtrl = TextEditingController();
    Professional? selectedProfessional;
    Map<String, dynamic>? selectedSession;

    final shouldSubmit = await showDialog<bool>(
      context: context,
      builder: (ctx) => Consumer(
        builder: (ctx, ref, _) {
          final professionalsAsync = ref.watch(professionalsListProvider(''));
          final historyAsync = ref.watch(customerHistoryProvider);

          final professionals =
              professionalsAsync.valueOrNull ??
              const <Professional>[];
          final historyItems =
              historyAsync.valueOrNull ??
              const <dynamic>[];

          return StatefulBuilder(
            builder: (ctx, setDialogState) {
              final sessionsForPro = _sessionsForProfessional(
                historyItems,
                selectedProfessional,
              );

              return AlertDialog(
              backgroundColor: AppColors.surfaceCard,
              title: Text(
                t.writeReview,
                style: GoogleFonts.jost(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          t.yourRating,
                          style: GoogleFonts.manrope(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        DropdownButton<double>(
                          value: rating,
                          items: [5, 4, 3, 2, 1]
                              .map(
                                (v) => DropdownMenuItem<double>(
                                  value: v.toDouble(),
                                  child: Text('$v star'),
                                ),
                              )
                              .toList(),
                          onChanged: (v) {
                            if (v != null) {
                              setDialogState(() => rating = v);
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: commentCtrl,
                      maxLines: 4,
                      decoration: InputDecoration(labelText: t.yourComment),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      t.reviewProfessionalLabel,
                      style: GoogleFonts.manrope(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 6),
                    _buildProfessionalPicker(
                      t: t,
                      professionals: professionals,
                      loading: professionalsAsync.isLoading,
                      error: professionalsAsync.hasError,
                      selected: selectedProfessional,
                      onChanged: (pro) {
                        setDialogState(() {
                          selectedProfessional = pro;
                          selectedSession = null;
                        });
                      },
                    ),
                    if (selectedProfessional != null) ...[
                      const SizedBox(height: 14),
                      Text(
                        t.reviewSessionLabel,
                        style: GoogleFonts.manrope(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 6),
                      _buildSessionPicker(
                        t: t,
                        sessions: sessionsForPro,
                        selected: selectedSession,
                        onChanged: (session) {
                          setDialogState(() => selectedSession = session);
                        },
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: Text(t.cancel),
                ),
                FilledButton(
                  onPressed: () {
                    if (selectedProfessional == null) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        SnackBar(
                          content: Text(t.selectProfessional),
                          backgroundColor: AppColors.error,
                        ),
                      );
                      return;
                    }
                    Navigator.of(ctx).pop(true);
                  },
                  child: Text(t.submitReview),
                ),
              ],
            );
          },
        );
      },
    ),
  );

    if (shouldSubmit != true) return;

    try {
      if (selectedProfessional == null) return;
      final currentUser = ref.read(authStateProvider).valueOrNull;
      final body = <String, dynamic>{
        'co_id_professional': selectedProfessional!.coId,
        'rv_note': rating.toInt(),
        'rv_text': commentCtrl.text.trim(),
        if (currentUser != null && currentUser.coId.isNotEmpty) ...{
          'co_id_customer': currentUser.coId,
        },
        if (selectedSession != null) ...{
          'se_id':
              (selectedSession!['se_id'] ?? selectedSession!['id'])?.toString(),
        },
      };

      await ref.read(reviewsHistoryRepositoryProvider).postReview(body);
      ref.invalidate(
        widget.isProfessional
            ? professionalReviewsProvider
            : customerReviewsProvider,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(t.reviewSubmitted),
          backgroundColor: AppColors.online,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(t.reviewSubmitFailed('Please try again.')),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Widget _buildProfessionalPicker({
    required dynamic t,
    required List<Professional> professionals,
    required bool loading,
    required bool error,
    required Professional? selected,
    required ValueChanged<Professional?> onChanged,
  }) {
    if (loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 10),
        child: Center(
          child: CircularProgressIndicator(
            color: AppColors.mediumPurple,
            strokeWidth: 2.5,
          ),
        ),
      );
    }

    if (error || professionals.isEmpty) {
      return Text(
        t.noProfessionalsAvailable,
        style: GoogleFonts.manrope(
          fontSize: 13,
          color: AppColors.textMuted,
        ),
      );
    }

    return DropdownButtonHideUnderline(
      child: DropdownButtonFormField<Professional>(
        isExpanded: true,
        value: selected,
        decoration: InputDecoration(
          hintText: t.selectProfessional,
          filled: true,
          fillColor: AppColors.surfaceElevated,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 6,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
        ),
        icon: const Icon(
          Icons.keyboard_arrow_down_rounded,
          color: AppColors.textMuted,
        ),
        items: professionals.map((pro) {
          final imageUrl = _profileImageUrl(
            rawAvatar: pro.avatar,
            seed: pro.coId.isNotEmpty ? pro.coId : pro.displayName,
          );
          return DropdownMenuItem<Professional>(
            value: pro,
            child: SizedBox(
              height: 40,
              child: Row(
                children: [
                  _Avatar(
                    imageUrl: imageUrl,
                    name: pro.displayName,
                    size: 28,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          pro.displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.manrope(
                            fontSize: 13,
                            height: 1.15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        if ((pro.specialty ?? '').isNotEmpty)
                          Text(
                            pro.specialty!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.manrope(
                              fontSize: 10.5,
                              height: 1.15,
                              color: AppColors.textSecondary,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildSessionPicker({
    required dynamic t,
    required List<Map<String, dynamic>> sessions,
    required Map<String, dynamic>? selected,
    required ValueChanged<Map<String, dynamic>?> onChanged,
  }) {
    if (sessions.isEmpty) {
      return Text(
        t.noSessionsForProfessional,
        style: GoogleFonts.manrope(
          fontSize: 13,
          color: AppColors.textMuted,
        ),
      );
    }

    return DropdownButtonHideUnderline(
      child: DropdownButtonFormField<Map<String, dynamic>>(
        isExpanded: true,
        value: selected,
        decoration: InputDecoration(
          hintText: t.selectSession,
          filled: true,
          fillColor: AppColors.surfaceElevated,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 6,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
        ),
        icon: const Icon(
          Icons.keyboard_arrow_down_rounded,
          color: AppColors.textMuted,
        ),
        items: sessions.map((session) {
          final type = _sessionTypeLabel(session);
          final date = _sessionDateLabel(session);
          return DropdownMenuItem<Map<String, dynamic>>(
            value: session,
            child: SizedBox(
              height: 40,
              child: Row(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: AppColors.mediumPurple.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      _sessionIcon(type),
                      size: 16,
                      color: AppColors.mediumPurple,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          type.isEmpty ? t.session : type,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.manrope(
                            fontSize: 13,
                            height: 1.15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        if (date.isNotEmpty)
                          Text(
                            date,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.manrope(
                              fontSize: 11,
                              height: 1.15,
                              color: AppColors.textMuted,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(translationsProvider);
    final reviewsAsync = ref.watch(
      widget.isProfessional
          ? professionalReviewsProvider
          : customerReviewsProvider,
    );

    return GradientScaffold(
      floatingActionButton: widget.isProfessional
          ? null
          : FloatingActionButton.extended(
              onPressed: _submitReview,
              icon: const Icon(Icons.rate_review_outlined),
              label: Text(t.writeReview),
            ),
      body: SafeArea(
        child: reviewsAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.mediumPurple),
          ),
          error: (e, st) => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 48,
                  color: AppColors.error,
                ),
                const SizedBox(height: 16),
                Text(
                  t.failedLoadReviews,
                  style: GoogleFonts.manrope(
                    color: AppColors.textSecondary,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'An error occurred. Please try again.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.manrope(
                    color: AppColors.textMuted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          data: (items) {
            final validItems = items
                .where((item) => item is Map<String, dynamic>)
                .cast<Map<String, dynamic>>()
                .toList();

            if (validItems.isEmpty) {
              return CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: _RevealIn(
                      delayMs: 20,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 12, 24, 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.isProfessional ? t.myReviews : t.reviews,
                              style: GoogleFonts.jost(
                                fontSize: 30,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              t.nReviews(0),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.manrope(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _EmptyState(isProfessional: widget.isProfessional),
                  ),
                ],
              );
            }

            final filteredItems = _selectedFilter == 'All'
                ? validItems
                : validItems.where((item) {
                    final rating = _reviewRating(item);
                    final filterValue = int.tryParse(_selectedFilter) ?? 0;
                    return rating.round() == filterValue;
                  }).toList();

            final totalReviews = validItems.length;
            final avgRating = totalReviews > 0
                ? validItems.fold<double>(
                        0,
                        (sum, item) => sum + _reviewRating(item),
                      ) /
                      totalReviews
                : 0;
            final breakdown = _buildRatingBreakdown(validItems);

            return RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(
                  widget.isProfessional
                      ? professionalReviewsProvider
                      : customerReviewsProvider,
                );
              },
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: _RevealIn(
                      delayMs: 20,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.isProfessional ? t.myReviews : t.reviews,
                              style: GoogleFonts.jost(
                                fontSize: 30,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              t.nReviews(totalReviews),
                              style: GoogleFonts.manrope(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 20),
                            _RatingOverviewCard(
                              avgRating: avgRating.toDouble(),
                              totalReviews: totalReviews,
                              breakdown: breakdown,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: _RevealIn(
                      delayMs: 70,
                      child: SizedBox(
                        height: 50,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          children: [
                            _FilterChip(
                              label: t.all,
                              isSelected: _selectedFilter == 'All',
                              onTap: () =>
                                  setState(() => _selectedFilter = 'All'),
                            ),
                            const SizedBox(width: 8),
                            _FilterChip(
                              label: '5 star',
                              isSelected: _selectedFilter == '5',
                              onTap: () =>
                                  setState(() => _selectedFilter = '5'),
                            ),
                            const SizedBox(width: 8),
                            _FilterChip(
                              label: '4 star',
                              isSelected: _selectedFilter == '4',
                              onTap: () =>
                                  setState(() => _selectedFilter = '4'),
                            ),
                            const SizedBox(width: 8),
                            _FilterChip(
                              label: '3 star',
                              isSelected: _selectedFilter == '3',
                              onTap: () =>
                                  setState(() => _selectedFilter = '3'),
                            ),
                            const SizedBox(width: 8),
                            _FilterChip(
                              label: '2 star',
                              isSelected: _selectedFilter == '2',
                              onTap: () =>
                                  setState(() => _selectedFilter = '2'),
                            ),
                            const SizedBox(width: 8),
                            _FilterChip(
                              label: '1 star',
                              isSelected: _selectedFilter == '1',
                              onTap: () =>
                                  setState(() => _selectedFilter = '1'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 16)),
                  if (filteredItems.isEmpty)
                    SliverFillRemaining(
                      child: Center(
                        child: Text(
                          t.noReviewsFound,
                          style: GoogleFonts.manrope(
                            color: AppColors.textMuted,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                      sliver: SliverList.builder(
                        itemCount: filteredItems.length,
                        itemBuilder: (context, i) {
                          final review = filteredItems[i];
                          return _RevealIn(
                            delayMs: 110 + (i * 24),
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _ReviewCard(review: review),
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

List<Map<String, dynamic>> _sessionsForProfessional(
  List<dynamic> historyItems,
  Professional? professional,
) {
  final result = <Map<String, dynamic>>[];
  if (professional == null) return result;

  final pro = professional;
  final normalizedProName = _normalizeName(pro.displayName);
  final proLastName = (pro.lastName ?? '').trim().toLowerCase();
  final proId = pro.coId;

  for (final item in historyItems) {
    if (item is! Map<String, dynamic>) continue;
    if (!_isSessionHistoryItem(item)) continue;

    final matchesById = _historyProfessionalIds(item).any(
      (id) => id.isNotEmpty &&
          (id == proId || id.replaceFirst(RegExp(r'^0+'), '') == proId),
    );
    if (matchesById) {
      result.add(item);
      continue;
    }

    final matchesByName = _historyProfessionalNames(item).any((name) {
      final normalized = _normalizeName(name);
      if (normalized.isEmpty) return false;
      if (normalized == normalizedProName) return true;
      if (proLastName.isNotEmpty && normalized.contains(proLastName)) {
        return true;
      }
      return false;
    });
    if (matchesByName) {
      result.add(item);
    }
  }
  return result;
}

String _normalizeName(String? value) {
  final normalized = (value ?? '')
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'\s+'), ' ')
      .replaceAll(RegExp(r'[^\p{L}\p{N} ]', unicode: true), '')
      .trim();
  return normalized;
}

bool _isSessionHistoryItem(Map<String, dynamic> item) {
  final type = (item['type'] ?? '').toString().toLowerCase();
  if (type.isNotEmpty) return type == 'session';
  return item.containsKey('se_id') ||
      item.containsKey('se_status') ||
      item.containsKey('se_date') ||
      (item['subtype']?.toString().isNotEmpty ?? false);
}

List<String> _historyProfessionalIds(Map<String, dynamic> item) {
  const keys = [
    'co_id',
    'coId',
    'co_target_id',
    'co_id_professional',
    'professional_id',
    'pro_id',
    'co_id_pro',
  ];
  final ids = <String>[];
  for (final key in keys) {
    final value = item[key];
    if (value == null) continue;
    final text = value.toString().trim();
    if (text.isNotEmpty) ids.add(text);
  }
  return ids;
}

List<String> _historyProfessionalNames(Map<String, dynamic> item) {
  const keys = [
    'comment',
    'title',
    'co_fullname',
    'co_full_name',
    'co_name',
    'co_lastname',
    'name',
    'professional_name',
  ];
  final names = <String>[];
  for (final key in keys) {
    final value = item[key];
    if (value == null) continue;
    final text = value.toString().trim();
    if (text.isNotEmpty) names.add(text);
  }
  return names;
}

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

  final encodedSeed = Uri.encodeComponent(seed);
  return 'https://i.pravatar.cc/300?u=voyanz-$encodedSeed';
}

String _sessionTypeLabel(Map<String, dynamic> session) {
  final raw = (session['se_type'] ??
          session['session_type'] ??
          session['type_call'] ??
          session['call_type'] ??
          session['subtype'] ??
          session['type'])
      ?.toString() ??
      '';
  return raw.trim();
}

IconData _sessionIcon(String type) {
  switch (type.toLowerCase()) {
    case 'phone':
    case 'phone call':
      return Icons.phone_in_talk_outlined;
    case 'chat':
    case 'text chat':
      return Icons.chat_bubble_outline;
    case 'video':
    case 'video call':
      return Icons.videocam_outlined;
    default:
      return Icons.videocam_outlined;
  }
}

String _sessionDateLabel(Map<String, dynamic> session) {
  final raw = (session['se_date'] ??
          session['date'] ??
          session['session_date'] ??
          session['start_at'])
      ?.toString() ??
      '';
  if (raw.isEmpty) return '';
  final normalized = raw.replaceFirst(' ', 'T');
  final parsed = DateTime.tryParse(normalized);
  if (parsed == null) return raw;
  final mm = parsed.month.toString().padLeft(2, '0');
  final dd = parsed.day.toString().padLeft(2, '0');
  final hh = parsed.hour.toString().padLeft(2, '0');
  final min = parsed.minute.toString().padLeft(2, '0');
  return '${parsed.year}-$mm-$dd $hh:$min';
}

class _Avatar extends StatelessWidget {
  final String imageUrl;
  final String name;
  final double size;

  const _Avatar({
    required this.imageUrl,
    required this.name,
    this.size = 36,
  });

  @override
  Widget build(BuildContext context) {
    final initial =
        name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : '?';
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: AppGradients.accent,
      ),
      clipBehavior: Clip.antiAlias,
      child: Image.network(
        imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stack) => Center(
          child: Text(
            initial,
            style: GoogleFonts.jost(
              fontSize: size * 0.42,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

class _RatingOverviewCard extends ConsumerWidget {
  final double avgRating;
  final int totalReviews;
  final Map<int, int> breakdown;

  const _RatingOverviewCard({
    required this.avgRating,
    required this.totalReviews,
    required this.breakdown,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider);
    return AppCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                avgRating.toStringAsFixed(1),
                style: GoogleFonts.jost(
                  fontSize: 40,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  t.nReviews(totalReviews),
                  style: GoogleFonts.manrope(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...[5, 4, 3, 2, 1].map((v) {
            final count = breakdown[v] ?? 0;
            final ratio = totalReviews == 0
                ? 0.0
                : count.toDouble() / totalReviews;
            return _RatingBar(label: '$v', value: ratio);
          }),
        ],
      ),
    );
  }
}

class _RatingBar extends StatelessWidget {
  final String label;
  final double value;

  const _RatingBar({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
            width: 42,
            child: Text(
              '$label star',
              style: GoogleFonts.manrope(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                minHeight: 7,
                value: value,
                backgroundColor: AppColors.surfaceElevated,
                valueColor: const AlwaysStoppedAnimation<Color>(
                  AppColors.gold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.mediumPurple : AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: isSelected ? Colors.transparent : AppColors.borderSubtle,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.manrope(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
            color: isSelected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _ReviewCard extends ConsumerWidget {
  final Map<String, dynamic> review;

  const _ReviewCard({required this.review});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(authStateProvider).valueOrNull;
    final rating = _reviewRating(review);
    final comment = _reviewText(review);
    final author = _reviewAuthor(review, currentUserName: _userDisplayName(currentUser));
    final date = _reviewDate(review);

    return AppCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  author,
                  style: GoogleFonts.jost(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.star_rounded, size: 16, color: AppColors.gold),
                  const SizedBox(width: 4),
                  Text(
                    rating.toStringAsFixed(1),
                    style: GoogleFonts.manrope(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.gold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (_reviewSubject(review).isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              _reviewSubject(review),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.manrope(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.textMuted,
              ),
            ),
          ],
          const SizedBox(height: 6),
          if (comment.isNotEmpty)
            Text(
              comment,
              style: GoogleFonts.manrope(
                fontSize: 13,
                height: 1.4,
                color: AppColors.textSecondary,
              ),
            ),
          if (date.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              date,
              style: GoogleFonts.manrope(
                fontSize: 11,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

double _reviewRating(Map<String, dynamic> review) {
  return double.tryParse(
        (review['rv_note'] ?? review['re_rating'] ?? '').toString(),
      ) ??
      0;
}

String _reviewText(Map<String, dynamic> review) {
  return (review['rv_text'] ?? review['re_comment'] ?? '').toString();
}

String _reviewAuthor(Map<String, dynamic> review, {String? currentUserName}) {
  // Pro side: the reviewer is the customer, provided as a nested object.
  final customer = review['customer'];
  if (customer is Map<String, dynamic>) {
    final name =
        customer['co_fullname']?.toString() ?? customer['co_name']?.toString() ?? '';
    if (name.isNotEmpty) return name;
  }
  // Customer side: the reviewer is the logged-in user. The API does not
  // repeat the customer profile inside customer-review items, so fall back to
  // the current user's display name.
  if (currentUserName != null && currentUserName.isNotEmpty) {
    return currentUserName;
  }
  final professional = review['professional'];
  if (professional is Map<String, dynamic>) {
    final name = professional['co_fullname']?.toString() ??
        professional['co_name']?.toString() ??
        '';
    if (name.isNotEmpty) return name;
  }
  return review['co_fullname']?.toString() ??
      review['co_name']?.toString() ??
      review['name']?.toString() ??
      'Anonymous';
}

String _userDisplayName(dynamic user) {
  if (user == null) return '';
  final full = '${user.firstName ?? ''} ${user.lastName ?? ''}'.trim();
  if (full.isNotEmpty) return full;
  final email = (user.email ?? '').toString();
  if (email.contains('@')) return email.split('@').first;
  return '';
}

/// Returns the professional the review is about (nested `professional` object),
/// so the customer-side card still shows who was reviewed.
String _reviewSubject(Map<String, dynamic> review) {
  final professional = review['professional'];
  if (professional is Map<String, dynamic>) {
    final name = professional['co_fullname']?.toString() ??
        professional['co_name']?.toString() ??
        '';
    if (name.isNotEmpty) return name;
  }
  return '';
}

String _reviewDate(Map<String, dynamic> review) {
  return (review['createdAt'] ?? review['re_date'] ?? '').toString();
}

class _EmptyState extends ConsumerWidget {
  final bool isProfessional;

  const _EmptyState({this.isProfessional = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider);
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 10, 24, 28),
      child: Center(
        child: AppCard(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  color: AppColors.mediumPurple.withValues(alpha: 0.1),
                ),
                child: const Icon(
                  Icons.star_border_rounded,
                  size: 32,
                  color: AppColors.mediumPurple,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                t.noReviewsYet,
                textAlign: TextAlign.center,
                style: GoogleFonts.jost(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isProfessional
                    ? t.reviewsFromClientsWillAppear
                    : t.reviewsFromConsultationsWillAppear,
                textAlign: TextAlign.center,
                style: GoogleFonts.manrope(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
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
      duration: Duration(milliseconds: 320 + delayMs),
      offset: const Offset(0, 10),
      child: child,
    );
  }
}

