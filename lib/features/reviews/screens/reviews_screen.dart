import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:voyanz/core/providers/language_provider.dart';
import 'package:voyanz/core/theme/app_colors.dart';
import 'package:voyanz/core/theme/app_gradients.dart';
import 'package:voyanz/core/theme/widgets.dart';
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
      final value =
          double.tryParse(review['re_rating']?.toString() ?? '')?.round() ?? 0;
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
    final targetCoIdCtrl = TextEditingController();
    final sessionIdCtrl = TextEditingController();

    final shouldSubmit = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
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
                const SizedBox(height: 10),
                TextField(
                  controller: targetCoIdCtrl,
                  decoration: InputDecoration(
                    labelText: t.reviewTargetCoidHint,
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: sessionIdCtrl,
                  decoration: InputDecoration(labelText: t.reviewSessionIdHint),
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
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(t.submitReview),
            ),
          ],
        ),
      ),
    );

    if (shouldSubmit != true) return;

    try {
      final body = <String, dynamic>{
        're_rating': rating,
        're_comment': commentCtrl.text.trim(),
        if (targetCoIdCtrl.text.trim().isNotEmpty) ...{
          'co_id': targetCoIdCtrl.text.trim(),
          'co_target_id': targetCoIdCtrl.text.trim(),
        },
        if (sessionIdCtrl.text.trim().isNotEmpty) ...{
          'se_id': sessionIdCtrl.text.trim(),
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
          content: Text(t.reviewSubmitFailed(e.toString())),
          backgroundColor: AppColors.error,
        ),
      );
    }
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
            child: CircularProgressIndicator(color: AppColors.rosePink),
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
                  t.errorMessage(e.toString()),
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
              return _EmptyState(isProfessional: widget.isProfessional);
            }

            final filteredItems = _selectedFilter == 'All'
                ? validItems
                : validItems.where((item) {
                    final rating =
                        double.tryParse(item['re_rating']?.toString() ?? '') ??
                        0;
                    final filterValue = int.tryParse(_selectedFilter) ?? 0;
                    return rating.round() == filterValue;
                  }).toList();

            final totalReviews = validItems.length;
            final avgRating = totalReviews > 0
                ? validItems.fold<double>(
                        0,
                        (sum, item) =>
                            sum +
                            (double.tryParse(
                                  item['re_rating']?.toString() ?? '',
                                ) ??
                                0),
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
                        padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.isProfessional ? t.myReviews : t.reviews,
                              style: GoogleFonts.jost(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              t.nReviews(totalReviews),
                              style: GoogleFonts.manrope(
                                fontSize: 13,
                                color: AppColors.textMuted,
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
    return GlassCard(
      padding: const EdgeInsets.all(18),
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
                  AppColors.rosePink,
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
          gradient: isSelected ? AppGradients.accent : null,
          color: isSelected
              ? null
              : AppColors.surfaceCard.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppColors.rosePink.withValues(alpha: 0.5)
                : AppColors.mediumPurple.withValues(alpha: 0.15),
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

class _ReviewCard extends StatelessWidget {
  final Map<String, dynamic> review;

  const _ReviewCard({required this.review});

  @override
  Widget build(BuildContext context) {
    final rating = double.tryParse(review['re_rating']?.toString() ?? '') ?? 0;
    final comment = review['re_comment']?.toString() ?? '';
    final author =
        review['co_fullname']?.toString() ??
        review['co_name']?.toString() ??
        review['name']?.toString() ??
        'Anonymous';
    final date = review['re_date']?.toString() ?? '';

    return GlassCard(
      padding: const EdgeInsets.all(16),
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
              Text(
                rating.toStringAsFixed(1),
                style: GoogleFonts.manrope(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.rosePink,
                ),
              ),
            ],
          ),
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

class _EmptyState extends ConsumerWidget {
  final bool isProfessional;

  const _EmptyState({this.isProfessional = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.star_border_rounded,
            size: 64,
            color: AppColors.textMuted,
          ),
          const SizedBox(height: 12),
          Text(
            t.noReviewsYet,
            style: GoogleFonts.jost(
              fontSize: 20,
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
              color: AppColors.textMuted,
              height: 1.4,
            ),
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
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: Duration(milliseconds: 340 + delayMs),
      curve: Curves.easeOutCubic,
      builder: (context, value, builtChild) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 12 * (1 - value)),
            child: builtChild,
          ),
        );
      },
      child: child,
    );
  }
}
