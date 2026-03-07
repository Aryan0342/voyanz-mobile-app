import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:voyanz/core/theme/app_colors.dart';
import 'package:voyanz/core/theme/app_gradients.dart';
import 'package:voyanz/features/professionals/models/professional.dart';
import 'package:voyanz/features/professionals/providers/professionals_provider.dart';

class ProfessionalsListScreen extends ConsumerStatefulWidget {
  const ProfessionalsListScreen({super.key});

  @override
  ConsumerState<ProfessionalsListScreen> createState() =>
      _ProfessionalsListScreenState();
}

class _ProfessionalsListScreenState
    extends ConsumerState<ProfessionalsListScreen> {
  final _searchCtrl = TextEditingController();
  String _selectedSpecialty = 'All';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<String> _buildSpecialties(List<Professional> pros) {
    final values = <String>{};
    for (final pro in pros) {
      final value = (pro.specialty ?? '').trim();
      if (value.isNotEmpty) {
        values.add(value);
      }
    }

    final result = values.toList()..sort();
    return ['All', ...result];
  }

  List<Professional> _filterProfessionals(List<Professional> pros) {
    final query = _searchCtrl.text.trim().toLowerCase();
    return pros.where((pro) {
      final bySpecialty =
          _selectedSpecialty == 'All' || pro.specialty == _selectedSpecialty;
      final byQuery =
          query.isEmpty ||
          pro.displayName.toLowerCase().contains(query) ||
          (pro.specialty ?? '').toLowerCase().contains(query);
      return bySpecialty && byQuery;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final professionalsAsync = ref.watch(professionalsListProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Explore',
          style: GoogleFonts.jost(fontSize: 22, fontWeight: FontWeight.w600),
        ),
      ),
      body: professionalsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.rosePink),
        ),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.wifi_off,
                  color: AppColors.textMuted,
                  size: 54,
                ),
                const SizedBox(height: 14),
                Text(
                  'Unable to load explore data',
                  style: GoogleFonts.jost(
                    color: AppColors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '$e',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.montserrat(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 20),
                OutlinedButton.icon(
                  onPressed: () => ref.refresh(professionalsListProvider),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Try Again'),
                ),
              ],
            ),
          ),
        ),
        data: (pros) {
          final specialties = _buildSpecialties(pros);
          if (!specialties.contains(_selectedSpecialty)) {
            _selectedSpecialty = 'All';
          }

          final filteredPros = _filterProfessionals(pros);
          final featuredPros = [
            ...filteredPros.where((p) => p.isOnline == true),
            ...filteredPros.where((p) => p.isOnline != true),
          ].take(5).toList();

          if (pros.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.search_off,
                    size: 64,
                    color: AppColors.textMuted.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No professionals found',
                    style: GoogleFonts.montserrat(
                      color: AppColors.textMuted,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            color: AppColors.rosePink,
            onRefresh: () async {
              ref.invalidate(professionalsListProvider);
              await ref.read(professionalsListProvider.future);
            },
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                    child: _ExploreHero(totalCount: pros.length),
                  ),
                ),

                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                    child: TextField(
                      controller: _searchCtrl,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        hintText: 'Search advisor or specialty',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _searchCtrl.text.isNotEmpty
                            ? IconButton(
                                onPressed: () {
                                  _searchCtrl.clear();
                                  setState(() {});
                                },
                                icon: const Icon(Icons.close),
                              )
                            : null,
                      ),
                    ),
                  ),
                ),

                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 14),
                    child: SizedBox(
                      height: 42,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemBuilder: (context, index) {
                          final specialty = specialties[index];
                          final selected = specialty == _selectedSpecialty;
                          return ChoiceChip(
                            selected: selected,
                            onSelected: (_) =>
                                setState(() => _selectedSpecialty = specialty),
                            label: Text(specialty),
                          );
                        },
                        separatorBuilder: (context, index) =>
                            const SizedBox(width: 10),
                        itemCount: specialties.length,
                      ),
                    ),
                  ),
                ),

                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                    child: _SectionTitle(
                      title: 'Featured Advisors',
                      subtitle: 'Top online professionals ready now',
                    ),
                  ),
                ),

                if (featuredPros.isEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                      child: _EmptyState(
                        message: 'No featured advisors for current filters.',
                      ),
                    ),
                  )
                else
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 170,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                        itemBuilder: (_, i) {
                          final pro = featuredPros[i];
                          return _FeaturedProfessionalCard(
                            professional: pro,
                            onTap: () =>
                                context.push('/professional/${pro.coId}'),
                          );
                        },
                        separatorBuilder: (context, index) =>
                            const SizedBox(width: 12),
                        itemCount: featuredPros.length,
                      ),
                    ),
                  ),

                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
                    child: _SectionTitle(
                      title: 'All Advisors',
                      subtitle: '${filteredPros.length} results',
                    ),
                  ),
                ),

                if (filteredPros.isEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                      child: _EmptyState(
                        message: 'No advisors match your search right now.',
                      ),
                    ),
                  )
                else
                  SliverList.builder(
                    itemCount: filteredPros.length,
                    itemBuilder: (_, i) {
                      final pro = filteredPros[i];
                      return Padding(
                        padding: EdgeInsets.fromLTRB(
                          20,
                          i == 0 ? 12 : 10,
                          20,
                          i == filteredPros.length - 1 ? 24 : 0,
                        ),
                        child: _ProfessionalCard(
                          name: pro.displayName,
                          specialty: pro.specialty,
                          avatarUrl: pro.avatar,
                          isOnline: pro.isOnline == true,
                          rating: pro.rating,
                          pricePerMinute: pro.pricePerMinute,
                          onTap: () =>
                              context.push('/professional/${pro.coId}'),
                        ),
                      );
                    },
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ExploreHero extends StatelessWidget {
  final int totalCount;

  const _ExploreHero({required this.totalCount});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: AppGradients.hero,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.mediumPurple.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              gradient: AppGradients.accent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.explore, color: Colors.white),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Discover Your Guide',
                  style: GoogleFonts.jost(
                    fontSize: 21,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$totalCount advisors available for chat and video sessions',
                  style: GoogleFonts.montserrat(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    height: 1.4,
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

class _SectionTitle extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionTitle({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.jost(
            fontSize: 19,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: GoogleFonts.montserrat(
            fontSize: 12,
            color: AppColors.textMuted,
          ),
        ),
      ],
    );
  }
}

class _FeaturedProfessionalCard extends StatelessWidget {
  final Professional professional;
  final VoidCallback onTap;

  const _FeaturedProfessionalCard({
    required this.professional,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 220,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surfaceCard.withValues(alpha: 0.75),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.mediumPurple.withValues(alpha: 0.15),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppGradients.accent,
              ),
              child: professional.avatar != null
                  ? ClipOval(
                      child: Image.network(
                        professional.avatar!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stack) =>
                            _avatarInitial(),
                      ),
                    )
                  : _avatarInitial(),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    professional.displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.montserrat(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    professional.specialty ?? 'General guidance',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.lora(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.circle,
                        size: 10,
                        color: professional.isOnline == true
                            ? AppColors.online
                            : AppColors.offline,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        professional.isOnline == true ? 'Online' : 'Offline',
                        style: GoogleFonts.montserrat(
                          fontSize: 11,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _avatarInitial() {
    return Center(
      child: Text(
        professional.displayName.isNotEmpty
            ? professional.displayName[0].toUpperCase()
            : '?',
        style: GoogleFonts.jost(
          fontSize: 21,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String message;

  const _EmptyState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.mediumPurple.withValues(alpha: 0.12),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: AppColors.textMuted, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.montserrat(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfessionalCard extends StatelessWidget {
  final String name;
  final String? specialty;
  final String? avatarUrl;
  final bool isOnline;
  final double? rating;
  final double? pricePerMinute;
  final VoidCallback onTap;

  const _ProfessionalCard({
    required this.name,
    this.specialty,
    this.avatarUrl,
    required this.isOnline,
    this.rating,
    this.pricePerMinute,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surfaceCard.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.mediumPurple.withValues(alpha: 0.12),
            ),
          ),
          child: Row(
            children: [
              // ── Avatar with online indicator ──
              Stack(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: AppGradients.accent,
                    ),
                    child: avatarUrl != null
                        ? ClipOval(
                            child: Image.network(
                              avatarUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stack) =>
                                  _initials(),
                            ),
                          )
                        : _initials(),
                  ),
                  Positioned(
                    bottom: 2,
                    right: 2,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isOnline ? AppColors.online : AppColors.offline,
                        border: Border.all(
                          color: AppColors.surfaceCard,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              // ── Info ──
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: GoogleFonts.montserrat(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (specialty != null && specialty!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        specialty!,
                        style: GoogleFonts.lora(
                          fontSize: 13,
                          fontStyle: FontStyle.italic,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                    if (rating != null) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          ...List.generate(5, (i) {
                            return Icon(
                              i < rating!.round()
                                  ? Icons.star
                                  : Icons.star_outline,
                              size: 14,
                              color: AppColors.rosePink,
                            );
                          }),
                          const SizedBox(width: 6),
                          Text(
                            rating!.toStringAsFixed(1),
                            style: GoogleFonts.montserrat(
                              fontSize: 12,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              // ── Price ──
              if (pricePerMinute != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.rosePink.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${pricePerMinute!.toStringAsFixed(0)}€/min',
                    style: GoogleFonts.montserrat(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.rosePink,
                    ),
                  ),
                ),
              const SizedBox(width: 4),
              const Icon(
                Icons.chevron_right,
                color: AppColors.textMuted,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _initials() {
    return Center(
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: GoogleFonts.jost(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }
}
