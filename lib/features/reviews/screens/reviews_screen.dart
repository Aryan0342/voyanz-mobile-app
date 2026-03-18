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
                      style: GoogleFonts.montserrat(
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
                              child: Text('$v ⭐'),
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
          error: (e, st) {
            return Center(
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
                    style: GoogleFonts.montserrat(
                      color: AppColors.textSecondary,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    t.errorMessage(e.toString()),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.montserrat(
                      color: AppColors.textMuted,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      ref.invalidate(
                        widget.isProfessional
                            ? professionalReviewsProvider
                            : customerReviewsProvider,
                      );
                    },
                    icon: const Icon(Icons.refresh),
                    label: Text(t.retry),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.rosePink,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
          data: (items) {
            // Filter items safely, excluding non-Map items
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

            // Calculate statistics
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
                  // ── Header with stats ──
                  SliverToBoxAdapter(
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
                          const SizedBox(height: 20),
                          _RatingOverviewCard(
                            avgRating: avgRating.toDouble(),
                            totalReviews: totalReviews,
                          ),
                        ],
                      ),
                    ),
                  ),
                  // ── Filter chips ──
                  SliverToBoxAdapter(
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
                            label: '5 ⭐',
                            isSelected: _selectedFilter == '5',
                            onTap: () => setState(() => _selectedFilter = '5'),
                          ),
                          const SizedBox(width: 8),
                          _FilterChip(
                            label: '4 ⭐',
                            isSelected: _selectedFilter == '4',
                            onTap: () => setState(() => _selectedFilter = '4'),
                          ),
                          const SizedBox(width: 8),
                          _FilterChip(
                            label: '3 ⭐',
                            isSelected: _selectedFilter == '3',
                            onTap: () => setState(() => _selectedFilter = '3'),
                          ),
                          const SizedBox(width: 8),
                          _FilterChip(
                            label: '2 ⭐',
                            isSelected: _selectedFilter == '2',
                            onTap: () => setState(() => _selectedFilter = '2'),
                          ),
                          const SizedBox(width: 8),
                          _FilterChip(
                            label: '1 ⭐',
                            isSelected: _selectedFilter == '1',
                            onTap: () => setState(() => _selectedFilter = '1'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 16)),
                  // ── Reviews list ──
                  if (filteredItems.isEmpty)
                    SliverFillRemaining(
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.filter_list_off,
                              size: 56,
                              color: AppColors.textMuted.withValues(alpha: 0.5),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              t.noReviewsFound,
                              style: GoogleFonts.montserrat(
                                color: AppColors.textMuted,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                      sliver: SliverList.builder(
                        itemCount: filteredItems.length,
                        itemBuilder: (context, i) {
                          final r = filteredItems[i];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _ReviewCard(review: r),
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

  const _RatingOverviewCard({
    required this.avgRating,
    required this.totalReviews,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider);
    return Container(
      decoration: BoxDecoration(
        gradient: AppGradients.accent,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.rosePink.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          // Big rating number
          Column(
            children: [
              Text(
                avgRating.toStringAsFixed(1),
                style: GoogleFonts.jost(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Row(
                children: List.generate(
                  5,
                  (i) => Icon(
                    Icons.star,
                    size: 16,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                t.nReviews(totalReviews),
                style: GoogleFonts.montserrat(
                  fontSize: 13,
                  color: Colors.white.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
          const SizedBox(width: 32),
          // Star breakdown (placeholder)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _RatingBar(label: '5', value: 0.8),
                const SizedBox(height: 6),
                _RatingBar(label: '4', value: 0.6),
                const SizedBox(height: 6),
                _RatingBar(label: '3', value: 0.3),
                const SizedBox(height: 6),
                _RatingBar(label: '2', value: 0.1),
                const SizedBox(height: 6),
                _RatingBar(label: '1', value: 0.05),
              ],
            ),
          ),
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
    return Row(
      children: [
        Text(
          label,
          style: GoogleFonts.montserrat(
            fontSize: 12,
            color: Colors.white.withValues(alpha: 0.9),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 6),
        const Icon(Icons.star, size: 12, color: Colors.white70),
        const SizedBox(width: 8),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: value,
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              valueColor: AlwaysStoppedAnimation(
                Colors.white.withValues(alpha: 0.9),
              ),
              minHeight: 6,
            ),
          ),
        ),
      ],
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
          style: GoogleFonts.montserrat(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
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
    final t = ProviderScope.containerOf(
      context,
      listen: false,
    ).read(translationsProvider);
    final rating = double.tryParse(review['re_rating']?.toString() ?? '') ?? 0;
    final comment = review['re_comment']?.toString() ?? '';
    final date = review['re_date']?.toString() ?? '';
    final reviewerName = review['reviewer_name']?.toString() ?? t.anonymous;

    return GlassCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Avatar
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppGradients.accent,
                ),
                child: Center(
                  child: Text(
                    reviewerName.isNotEmpty
                        ? reviewerName[0].toUpperCase()
                        : '?',
                    style: GoogleFonts.jost(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Name & date
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      reviewerName,
                      style: GoogleFonts.montserrat(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      date,
                      style: GoogleFonts.montserrat(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              // Rating
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  gradient: AppGradients.accent,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.rosePink.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.star, size: 16, color: Colors.white),
                    const SizedBox(width: 4),
                    Text(
                      rating.toStringAsFixed(1),
                      style: GoogleFonts.montserrat(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (comment.isNotEmpty) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.deepIndigo.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                comment,
                style: GoogleFonts.lora(
                  fontSize: 14,
                  height: 1.6,
                  color: AppColors.textSecondary,
                  fontStyle: FontStyle.italic,
                ),
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
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppGradients.accent.scale(0.3),
            ),
            child: const Icon(
              Icons.star_outline,
              size: 56,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            t.noReviewsYet,
            style: GoogleFonts.jost(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48),
            child: Text(
              isProfessional
                  ? t.reviewsFromClientsWillAppear
                  : t.reviewsFromConsultationsWillAppear,
              textAlign: TextAlign.center,
              style: GoogleFonts.montserrat(
                fontSize: 14,
                color: AppColors.textMuted,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
