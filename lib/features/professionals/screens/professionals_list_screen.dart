import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:voyanz/core/config/env.dart';
import 'package:voyanz/core/theme/app_colors.dart';
import 'package:voyanz/core/theme/app_gradients.dart';
import 'package:voyanz/features/professionals/models/professional.dart';
import 'package:voyanz/features/professionals/providers/professionals_provider.dart';
import 'package:voyanz/core/providers/language_provider.dart';
import 'package:voyanz/core/l10n/language_switcher.dart';

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
  String _selectedType = 'All';
  String _selectedExperience = 'All';
  String _selectedPrice = 'All';
  String _selectedLanguage = 'All';
  bool _favoritesOnly = false;
  final Set<String> _selectedSessionTypes = <String>{};

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
      for (final item in pro.specialties) {
        final text = item.trim();
        if (text.isNotEmpty) values.add(text);
      }
    }

    final result = values.toList()..sort();
    return ['All', ...result];
  }

  List<String> _buildLanguages(List<Professional> pros) {
    final values = <String>{};
    for (final pro in pros) {
      for (final item in pro.languages) {
        final text = item.trim();
        if (text.isNotEmpty) values.add(text);
      }
    }
    final result = values.toList()..sort();
    return ['All', ...result];
  }

  bool _matchesType(Professional pro) {
    switch (_selectedType) {
      case 'Online':
        return pro.isOnline == true;
      case 'Recommended':
        return pro.isRecommended;
      default:
        return true;
    }
  }

  bool _matchesExperience(Professional pro) {
    if (_selectedExperience == 'All') return true;
    final years = pro.experienceYears;
    if (years == null) return false;
    switch (_selectedExperience) {
      case '0-5':
        return years <= 5;
      case '5-10':
        return years > 5 && years <= 10;
      case '10-15':
        return years > 10 && years <= 15;
      case '15+':
        return years > 15;
      default:
        return true;
    }
  }

  bool _matchesPrice(Professional pro) {
    if (_selectedPrice == 'All') return true;
    final price = pro.pricePerMinute;
    if (price == null) return false;
    switch (_selectedPrice) {
      case '<2':
        return price < 2;
      case '2-3':
        return price >= 2 && price < 3;
      case '3-4':
        return price >= 3 && price < 4;
      case '4+':
        return price >= 4;
      default:
        return true;
    }
  }

  bool _matchesSessionTypes(Professional pro) {
    if (_selectedSessionTypes.isEmpty) return true;
    for (final type in _selectedSessionTypes) {
      if (type == 'Phone' && pro.supportsPhone) return true;
      if (type == 'Video' && pro.supportsVideo) return true;
      if (type == 'Chat' && pro.supportsChat) return true;
    }
    return false;
  }

  bool _matchesLanguage(Professional pro) {
    if (_selectedLanguage == 'All') return true;
    return pro.languages.any(
      (l) => l.toLowerCase() == _selectedLanguage.toLowerCase(),
    );
  }

  int _activeFiltersCount() {
    var count = 0;
    if (_selectedType != 'All') count++;
    if (_selectedExperience != 'All') count++;
    if (_selectedPrice != 'All') count++;
    if (_selectedLanguage != 'All') count++;
    if (_favoritesOnly) count++;
    count += _selectedSessionTypes.length;
    if (_selectedSpecialty != 'All') count++;
    return count;
  }

  void _resetFilters() {
    setState(() {
      _selectedType = 'All';
      _selectedExperience = 'All';
      _selectedPrice = 'All';
      _selectedLanguage = 'All';
      _favoritesOnly = false;
      _selectedSessionTypes.clear();
      _selectedSpecialty = 'All';
    });
  }

  List<Professional> _filterProfessionals(
    List<Professional> pros,
    Set<String> favoriteIds,
  ) {
    final query = _searchCtrl.text.trim().toLowerCase();
    return pros.where((pro) {
      final bySpecialty =
          _selectedSpecialty == 'All' ||
          pro.specialty == _selectedSpecialty ||
          pro.specialties.any(
            (s) => s.toLowerCase() == _selectedSpecialty.toLowerCase(),
          );

      final searchableSpecialties = [
        if (pro.specialty != null) pro.specialty!,
        ...pro.specialties,
      ].join(' ').toLowerCase();
      final searchableLanguages = pro.languages.join(' ').toLowerCase();

      final byQuery =
          query.isEmpty ||
          pro.displayName.toLowerCase().contains(query) ||
          searchableSpecialties.contains(query) ||
          searchableLanguages.contains(query);

      final byType = _matchesType(pro);
      final byExperience = _matchesExperience(pro);
      final byPrice = _matchesPrice(pro);
      final bySessionType = _matchesSessionTypes(pro);
      final byLanguage = _matchesLanguage(pro);
      final byFavorites =
          !_favoritesOnly || pro.isFavorite || favoriteIds.contains(pro.coId);

      return bySpecialty &&
          byQuery &&
          byType &&
          byExperience &&
          byPrice &&
          bySessionType &&
          byLanguage &&
          byFavorites;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final professionalsAsync = ref.watch(professionalsListProvider);
    final favoriteIds = ref.watch(favoriteProfessionalIdsProvider);

    final t = ref.watch(translationsProvider);
    return Scaffold(
      appBar: AppBar(
        actions: const [LanguageSwitcherButton(), SizedBox(width: 8)],
        title: Text(
          t.explore,
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
                  t.unableLoadExplore,
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
                  label: Text(t.tryAgain),
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
          final languages = _buildLanguages(pros);
          if (!languages.contains(_selectedLanguage)) {
            _selectedLanguage = 'All';
          }

          final activeFilters = _activeFiltersCount();

          final filteredPros = _filterProfessionals(pros, favoriteIds);
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
                    t.noProfessionalsFound,
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
                        hintText: t.searchAdvisor,
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
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                    child: _FilterPanel(
                      specialties: specialties,
                      selectedSpecialty: _selectedSpecialty,
                      selectedType: _selectedType,
                      selectedExperience: _selectedExperience,
                      selectedPrice: _selectedPrice,
                      selectedLanguage: _selectedLanguage,
                      selectedSessionTypes: _selectedSessionTypes,
                      languages: languages,
                      favoritesOnly: _favoritesOnly,
                      activeFiltersCount: activeFilters,
                      onSpecialtyChanged: (v) =>
                          setState(() => _selectedSpecialty = v),
                      onTypeChanged: (v) => setState(() => _selectedType = v),
                      onExperienceChanged: (v) =>
                          setState(() => _selectedExperience = v),
                      onPriceChanged: (v) => setState(() => _selectedPrice = v),
                      onLanguageChanged: (v) =>
                          setState(() => _selectedLanguage = v),
                      onFavoritesChanged: (v) =>
                          setState(() => _favoritesOnly = v),
                      onToggleSessionType: (value) {
                        setState(() {
                          if (_selectedSessionTypes.contains(value)) {
                            _selectedSessionTypes.remove(value);
                          } else {
                            _selectedSessionTypes.add(value);
                          }
                        });
                      },
                      onReset: _resetFilters,
                    ),
                  ),
                ),

                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                    child: _SectionTitle(
                      title: t.featuredAdvisors,
                      subtitle: t.topProsReadyNow,
                    ),
                  ),
                ),

                if (featuredPros.isEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                      child: _EmptyState(message: t.noFeaturedAdvisors),
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
                      title: t.allAdvisors,
                      subtitle: t.nResults(filteredPros.length),
                    ),
                  ),
                ),

                if (filteredPros.isEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                      child: _EmptyState(message: t.noAdvisorsMatch),
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
                          coId: pro.coId,
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

class _ExploreHero extends ConsumerWidget {
  final int totalCount;

  const _ExploreHero({required this.totalCount});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider);
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
                  t.discoverYourGuide,
                  style: GoogleFonts.jost(
                    fontSize: 21,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  t.nAdvisorsAvailable(totalCount),
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

class _FilterPanel extends ConsumerWidget {
  final List<String> specialties;
  final String selectedSpecialty;
  final String selectedType;
  final String selectedExperience;
  final String selectedPrice;
  final String selectedLanguage;
  final Set<String> selectedSessionTypes;
  final List<String> languages;
  final bool favoritesOnly;
  final int activeFiltersCount;
  final ValueChanged<String> onSpecialtyChanged;
  final ValueChanged<String> onTypeChanged;
  final ValueChanged<String> onExperienceChanged;
  final ValueChanged<String> onPriceChanged;
  final ValueChanged<String> onLanguageChanged;
  final ValueChanged<bool> onFavoritesChanged;
  final ValueChanged<String> onToggleSessionType;
  final VoidCallback onReset;

  const _FilterPanel({
    required this.specialties,
    required this.selectedSpecialty,
    required this.selectedType,
    required this.selectedExperience,
    required this.selectedPrice,
    required this.selectedLanguage,
    required this.selectedSessionTypes,
    required this.languages,
    required this.favoritesOnly,
    required this.activeFiltersCount,
    required this.onSpecialtyChanged,
    required this.onTypeChanged,
    required this.onExperienceChanged,
    required this.onPriceChanged,
    required this.onLanguageChanged,
    required this.onFavoritesChanged,
    required this.onToggleSessionType,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.mediumPurple.withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                t.filters,
                style: GoogleFonts.jost(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: 8),
              if (activeFiltersCount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.rosePink.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    '$activeFiltersCount',
                    style: GoogleFonts.montserrat(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.rosePink,
                    ),
                  ),
                ),
              const Spacer(),
              TextButton.icon(
                onPressed: onReset,
                icon: const Icon(Icons.refresh, size: 16),
                label: Text(t.reset),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ['All', 'Online', 'Recommended']
                .map(
                  (value) => ChoiceChip(
                    label: Text(value),
                    selected: selectedType == value,
                    onSelected: (_) => onTypeChanged(value),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 8),
          if (selectedSpecialty != 'All' ||
              selectedSessionTypes.isNotEmpty ||
              favoritesOnly)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (selectedSpecialty != 'All')
                  InputChip(
                    label: Text(t.specialtyFilterLabel(selectedSpecialty)),
                    onDeleted: () => onSpecialtyChanged('All'),
                  ),
                ...selectedSessionTypes.map(
                  (s) => InputChip(
                    label: Text(s),
                    onDeleted: () => onToggleSessionType(s),
                  ),
                ),
                if (favoritesOnly)
                  InputChip(
                    label: Text(t.favoritesOnly),
                    onDeleted: () => onFavoritesChanged(false),
                  ),
              ],
            ),
          Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              tilePadding: EdgeInsets.zero,
              childrenPadding: const EdgeInsets.only(top: 8),
              iconColor: AppColors.textSecondary,
              collapsedIconColor: AppColors.textSecondary,
              title: Text(
                t.moreFilters,
                style: GoogleFonts.montserrat(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              subtitle: Text(
                t.filterSubtitle,
                style: GoogleFonts.montserrat(
                  fontSize: 11,
                  color: AppColors.textMuted,
                ),
              ),
              children: [
                _FilterSection(
                  title: t.specialties,
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: specialties
                        .take(8)
                        .map(
                          (value) => ChoiceChip(
                            label: Text(
                              value == 'All'
                                  ? t.all
                                  : value == 'Online'
                                  ? t.online
                                  : t.recommended,
                            ),
                            selected: selectedSpecialty == value,
                            onSelected: (_) => onSpecialtyChanged(value),
                          ),
                        )
                        .toList(),
                  ),
                ),
                _FilterSection(
                  title: t.experience,
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: const ['All', '0-5', '5-10', '10-15', '15+']
                        .map(
                          (value) => ChoiceChip(
                            label: Text(value),
                            selected: selectedExperience == value,
                            onSelected: (_) => onExperienceChanged(value),
                          ),
                        )
                        .toList(),
                  ),
                ),
                _FilterSection(
                  title: t.pricingEurMin,
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: const ['All', '<2', '2-3', '3-4', '4+']
                        .map(
                          (value) => ChoiceChip(
                            label: Text(value),
                            selected: selectedPrice == value,
                            onSelected: (_) => onPriceChanged(value),
                          ),
                        )
                        .toList(),
                  ),
                ),
                _FilterSection(
                  title: t.sessionType,
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: ['Chat', 'Phone', 'Video']
                        .map(
                          (value) => FilterChip(
                            label: Text(
                              value == 'Chat'
                                  ? t.textChat
                                  : value == 'Phone'
                                  ? t.phoneCall
                                  : t.videoCall,
                            ),
                            selected: selectedSessionTypes.contains(value),
                            onSelected: (_) => onToggleSessionType(value),
                          ),
                        )
                        .toList(),
                  ),
                ),
                if (languages.length > 1)
                  _FilterSection(
                    title: t.language,
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: languages
                          .take(8)
                          .map(
                            (value) => ChoiceChip(
                              label: Text(value),
                              selected: selectedLanguage == value,
                              onSelected: (_) => onLanguageChanged(value),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                Row(
                  children: [
                    Switch(
                      value: favoritesOnly,
                      onChanged: onFavoritesChanged,
                      activeThumbColor: AppColors.rosePink,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      t.favoritesOnly,
                      style: GoogleFonts.montserrat(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterSection extends StatelessWidget {
  final String title;
  final Widget child;

  const _FilterSection({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.montserrat(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          child,
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
    final imageUrl = _profileImageUrl(
      rawAvatar: professional.avatar,
      seed: professional.coId.isNotEmpty
          ? professional.coId
          : professional.displayName,
    );

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
              child: ClipOval(
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stack) => _avatarInitial(),
                ),
              ),
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
                      const Icon(
                        Icons.star_rounded,
                        size: 14,
                        color: AppColors.rosePink,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        (professional.rating ?? 0).toStringAsFixed(1),
                        style: GoogleFonts.montserrat(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 10),
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
  final String coId;
  final String name;
  final String? specialty;
  final String? avatarUrl;
  final bool isOnline;
  final double? rating;
  final double? pricePerMinute;
  final VoidCallback onTap;

  const _ProfessionalCard({
    required this.coId,
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
    final imageUrl = _profileImageUrl(
      rawAvatar: avatarUrl,
      seed: coId.isNotEmpty ? coId : name,
    );

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
                    child: ClipOval(
                      child: Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stack) => _initials(),
                      ),
                    ),
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
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        ...List.generate(5, (i) {
                          final value = (rating ?? 0).round();
                          return Icon(
                            i < value ? Icons.star : Icons.star_outline,
                            size: 14,
                            color: AppColors.rosePink,
                          );
                        }),
                        const SizedBox(width: 6),
                        Text(
                          (rating ?? 0).toStringAsFixed(1),
                          style: GoogleFonts.montserrat(
                            fontSize: 12,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
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
                    '€${pricePerMinute!.toStringAsFixed(2)}/min',
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
