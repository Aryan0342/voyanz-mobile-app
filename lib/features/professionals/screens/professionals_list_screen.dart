import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:voyanz/core/config/env.dart';
import 'package:voyanz/core/l10n/app_translations.dart';
import 'package:voyanz/core/theme/app_colors.dart';
import 'package:voyanz/core/theme/app_gradients.dart';
import 'package:voyanz/core/theme/widgets.dart';
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

  // `co_avatar` is normally empty: the canonical cover is exposed through
  // this endpoint for both human professionals and Voyanz AI assistants.
  final encodedSeed = Uri.encodeComponent(seed);
  return '${EnvConfig.current.baseUrl}/api/1.0/image/$encodedSeed/400/400/cover';
}

class ProfessionalsListScreen extends ConsumerStatefulWidget {
  final bool favoritesOnly;

  const ProfessionalsListScreen({super.key, this.favoritesOnly = false});

  @override
  ConsumerState<ProfessionalsListScreen> createState() =>
      _ProfessionalsListScreenState();
}

class _ProfessionalsListScreenState
    extends ConsumerState<ProfessionalsListScreen> {
  final _searchCtrl = TextEditingController();
  Timer? _searchDebounce;
  String _serverSearchQuery = '';
  String _selectedSpecialty = 'All';
  String _selectedType = 'All';
  String _selectedExperience = 'All';
  String _selectedPrice = 'All';
  String _selectedLanguage = 'All';
  bool _favoritesOnly = false;
  final Set<String> _selectedSessionTypes = <String>{};

  @override
  void initState() {
    super.initState();
    _favoritesOnly = widget.favoritesOnly;
    // Debounced server-side search (API_REST §10.1 `search` param).
    _searchCtrl.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      final query = _searchCtrl.text.trim();
      if (query == _serverSearchQuery) return;
      setState(() => _serverSearchQuery = query);
    });
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchCtrl.removeListener(_onSearchChanged);
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
        return pro.isAvailableNow;
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
    final professionalsAsync = widget.favoritesOnly
        ? ref.watch(favoriteProfessionalsProvider)
        : ref.watch(professionalsListProvider(_serverSearchQuery));
    final favoriteIds = ref.watch(favoriteProfessionalIdsProvider);

    final t = ref.watch(translationsProvider);
    return Scaffold(
      backgroundColor: AppColors.deepIndigo,
      appBar: AppBar(
        backgroundColor: AppColors.darkPurple,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text(
          widget.favoritesOnly ? t.favoritesOnly : t.explore,
          style: GoogleFonts.jost(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        actions: [
          if (!widget.favoritesOnly)
            IconButton(
              tooltip: t.favoritesOnly,
              onPressed: () => context.push('/favorites'),
              icon: const Icon(Icons.favorite_outline),
            ),
          if (!widget.favoritesOnly)
            IconButton(
              tooltip: t.groupCalendar,
              onPressed: () => context.push('/group-calendar'),
              icon: const Icon(Icons.groups_outlined),
            ),
          const LanguageSwitcherButton(),
          const SizedBox(width: 8),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.darkPurple,
              AppColors.deepIndigo,
              Color(0xFF321451),
            ],
          ),
        ),
        child: professionalsAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.mediumPurple),
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
                    onPressed: () => ref.refresh(
                      professionalsListProvider(_serverSearchQuery),
                    ),
                    icon: const Icon(Icons.refresh),
                    label: Text(t.tryAgain),
                  ),
                ],
              ),
            ),
          ),
          data: (pros) {
            final humanPros = pros.where((p) => !p.isAssistant).toList();
            final filteredPros = _filterProfessionals(humanPros, favoriteIds);
            if (pros.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: GlassCard(
                    padding: const EdgeInsets.fromLTRB(22, 26, 22, 24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 94,
                          height: 94,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            gradient: LinearGradient(
                              colors: [
                                AppColors.mediumPurple.withValues(alpha: 0.16),
                                AppColors.aqua.withValues(alpha: 0.11),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: const Icon(
                            Icons.explore_outlined,
                            size: 42,
                            color: AppColors.deepIndigo,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          t.noProfessionalsFound,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.jost(
                            fontSize: 30,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          t.noProfessionalsSubtitle,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.montserrat(
                            fontSize: 15,
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

            return RefreshIndicator(
              color: AppColors.mediumPurple,
              onRefresh: () async {
                if (widget.favoritesOnly) {
                  ref.invalidate(favoriteProfessionalsProvider);
                  await ref.read(favoriteProfessionalsProvider.future);
                } else {
                  ref.invalidate(professionalsListProvider(_serverSearchQuery));
                  await ref.read(
                    professionalsListProvider(_serverSearchQuery).future,
                  );
                }
              },
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: _RevealIn(
                      delayMs: 20,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 10, 24, 0),
                        child: _ExploreHero(totalCount: humanPros.length),
                      ),
                    ),
                  ),

                  SliverToBoxAdapter(
                    child: _RevealIn(
                      delayMs: 70,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                        child: Column(
                          children: [
                            TextField(
                              controller: _searchCtrl,
                              style: GoogleFonts.montserrat(
                                color: Colors.white,
                              ),
                              onChanged: (_) => setState(() {}),
                              decoration: InputDecoration(
                                hintText: t.searchAdvisor,
                                hintStyle: GoogleFonts.montserrat(
                                  color: Colors.white60,
                                ),
                                prefixIcon: const Icon(
                                  Icons.search,
                                  color: Colors.white70,
                                ),
                                filled: true,
                                fillColor: Colors.white.withValues(alpha: 0.09),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: Colors.white.withValues(alpha: 0.18),
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: AppColors.brandPink,
                                    width: 1.5,
                                  ),
                                ),
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
                            const SizedBox(height: 10),
                            SizedBox(
                              width: double.infinity,
                              height: 48,
                              child: FilledButton.icon(
                                onPressed: () {
                                  FocusScope.of(context).unfocus();
                                  setState(
                                    () => _serverSearchQuery = _searchCtrl.text
                                        .trim(),
                                  );
                                },
                                icon: const Icon(Icons.search),
                                label: Text(t.search),
                                style: FilledButton.styleFrom(
                                  backgroundColor: AppColors.brandPink,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  ..._buildProfessionalSections(context, filteredPros, t),

                  if (filteredPros.isEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                        child: _EmptyState(message: t.noAdvisorsMatch),
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

  List<Widget> _buildProfessionalSections(
    BuildContext context,
    List<Professional> professionals,
    dynamic t,
  ) {
    if (professionals.isEmpty) return const [];

    final online = professionals.where((p) => p.isAvailableNow).toList();
    final onlineIds = online.map((p) => p.coId).toSet();
    final recommended = professionals
        .where((p) => p.isRecommended && !onlineIds.contains(p.coId))
        .toList();

    final sections = <({String title, List<Professional> items})>[
      if (online.isNotEmpty) (title: t.onlineNow, items: online),
      if (recommended.isNotEmpty)
        (title: t.featuredAdvisors, items: recommended),
      (title: t.allAdvisors, items: professionals),
    ];

    final slivers = <Widget>[];
    var animationIndex = 0;
    for (final section in sections) {
      slivers.add(
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 22, 24, 0),
            child: _SectionTitle(
              title: section.title,
              subtitle: t.nResults(section.items.length),
            ),
          ),
        ),
      );
      slivers.add(
        SliverList.builder(
          itemCount: section.items.length,
          itemBuilder: (_, index) {
            final pro = section.items[index];
            animationIndex += 1;
            return _RevealIn(
              delayMs: 180 + (animationIndex * 24),
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  20,
                  index == 0 ? 12 : 10,
                  20,
                  index == section.items.length - 1 ? 8 : 0,
                ),
                child: _ProfessionalCard(
                  professional: pro,
                  translations: t,
                  onTap: () => context.push('/professional/${pro.coId}'),
                ),
              ),
            );
          },
        ),
      );
    }
    slivers.add(const SliverToBoxAdapter(child: SizedBox(height: 16)));
    return slivers;
  }

  Professional? _pickQuickCandidate(
    List<Professional> pros, {
    bool supportsVideo = false,
    bool supportsPhone = false,
    bool supportsChat = false,
  }) {
    bool supports(Professional pro) {
      if (supportsVideo && !pro.supportsVideo) return false;
      if (supportsPhone && !pro.supportsPhone) return false;
      if (supportsChat && !pro.supportsChat) return false;
      return true;
    }

    Professional? best;
    for (final pro in pros) {
      if (!supports(pro)) continue;
      if (best == null) {
        best = pro;
        continue;
      }

      final bestOnline = best.isAvailableNow;
      final currentOnline = pro.isAvailableNow;
      if (currentOnline && !bestOnline) {
        best = pro;
        continue;
      }

      final bestRating = best.rating ?? 0;
      final currentRating = pro.rating ?? 0;
      if (currentRating > bestRating) {
        best = pro;
      }
    }

    return best;
  }

  void _openQuickCandidate(
    BuildContext context,
    Professional? candidate,
    String fallbackMessage,
  ) {
    if (candidate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(fallbackMessage),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    context.push('/professional/${candidate.coId}');
  }
}

class _QuickSessionTestPanel extends ConsumerWidget {
  final Professional? quickVideoCandidate;
  final Professional? quickPhoneCandidate;
  final Professional? quickChatCandidate;
  final void Function(BuildContext context, Professional? candidate, String msg)
  onQuickOpen;

  const _QuickSessionTestPanel({
    required this.quickVideoCandidate,
    required this.quickPhoneCandidate,
    required this.quickChatCandidate,
    required this.onQuickOpen,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.mediumPurple.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.mediumPurple.withValues(alpha: 0.18),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t.quickSessionTest,
            style: GoogleFonts.jost(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            t.quickSessionTestHint,
            style: GoogleFonts.montserrat(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => onQuickOpen(
                    context,
                    quickVideoCandidate,
                    t.noVideoTestCandidate,
                  ),
                  icon: const Icon(Icons.videocam_outlined),
                  label: Text(t.videoCall),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => onQuickOpen(
                    context,
                    quickPhoneCandidate,
                    t.noPhoneTestCandidate,
                  ),
                  icon: const Icon(Icons.phone_in_talk_outlined),
                  label: Text(t.phoneCall),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => onQuickOpen(
                    context,
                    quickChatCandidate,
                    t.noChatTestCandidate,
                  ),
                  icon: const Icon(Icons.chat_bubble_outline),
                  label: Text(t.textChat),
                ),
              ),
            ],
          ),
        ],
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
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF5A176C), Color(0xFF9B3366), Color(0xFF311552)],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white24),
        boxShadow: [
          BoxShadow(
            color: AppColors.brandPink.withValues(alpha: 0.16),
            blurRadius: 26,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t.discoverYourGuide,
            textAlign: TextAlign.center,
            style: GoogleFonts.lora(
              fontSize: 29,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            t.nAdvisorsAvailable(totalCount),
            textAlign: TextAlign.center,
            style: GoogleFonts.montserrat(
              fontSize: 13,
              color: Colors.white70,
              fontWeight: FontWeight.w500,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroTag extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color tone;
  final Color? bgColor;

  const _HeroTag({
    required this.icon,
    required this.label,
    required this.tone,
    this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor ?? tone.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: tone),
          const SizedBox(width: 5),
          Text(
            label,
            style: GoogleFonts.montserrat(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: tone,
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
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderSubtle),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                t.filters,
                style: GoogleFonts.jost(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              if (activeFiltersCount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.mediumPurple.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    '$activeFiltersCount',
                    style: GoogleFonts.montserrat(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.deepIndigo,
                    ),
                  ),
                ),
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
                    label: Text(
                      value == 'All'
                          ? t.all
                          : value == 'Online'
                          ? t.online
                          : t.recommended,
                    ),
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
                    label: Text(
                      s == 'Chat'
                          ? t.textChat
                          : s == 'Phone'
                          ? t.phoneCall
                          : s == 'Video'
                          ? t.videoCall
                          : s,
                    ),
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
                            label: Text(value == 'All' ? t.all : value),
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
                      activeThumbColor: AppColors.mediumPurple,
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
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: GoogleFonts.montserrat(fontSize: 12, color: Colors.white60),
        ),
      ],
    );
  }
}

class _FeaturedProfessionalCard extends ConsumerWidget {
  final Professional professional;
  final VoidCallback onTap;

  const _FeaturedProfessionalCard({
    required this.professional,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider);
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
          color: const Color(0xFF261846),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 64,
              height: 92,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                gradient: AppGradients.accent,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
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
                      color: Colors.white,
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
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        size: 14,
                        color: AppColors.mediumPurple,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        (professional.rating ?? 0).toStringAsFixed(1),
                        style: GoogleFonts.montserrat(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(
                        Icons.circle,
                        size: 10,
                        color: professional.isAvailableNow
                            ? AppColors.online
                            : AppColors.offline,
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          professional.isAvailableNow ? t.online : t.offline,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.montserrat(
                            fontSize: 11,
                            color: Colors.white60,
                          ),
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
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSubtle),
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
  final Professional professional;
  final AppTranslations translations;
  final VoidCallback onTap;

  const _ProfessionalCard({
    required this.professional,
    required this.translations,
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
    final availability = professional.availabilityText?.trim();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF261846),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white12),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: 230,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stack) => _initials(),
                    ),
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Color(0xE8140B2D)],
                          stops: [0.42, 1],
                        ),
                      ),
                    ),
                    Positioned(
                      right: 14,
                      top: 14,
                      child: Icon(
                        professional.isFavorite
                            ? Icons.favorite
                            : Icons.favorite_border,
                        color: professional.isFavorite
                            ? AppColors.brandPink
                            : Colors.white,
                      ),
                    ),
                    Positioned(
                      left: 16,
                      right: 16,
                      bottom: 14,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            professional.displayName,
                            style: GoogleFonts.lora(
                              fontSize: 25,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 7),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              if (professional.isVerified)
                                _ProfileBadge(
                                  icon: Icons.verified_outlined,
                                  label: translations.profileVerified,
                                ),
                              _ProfileBadge(
                                icon: Icons.mark_email_read_outlined,
                                label: translations.emailVerified,
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Container(
                                width: 9,
                                height: 9,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: professional.isAvailableNow
                                      ? AppColors.online
                                      : AppColors.offline,
                                ),
                              ),
                              const SizedBox(width: 7),
                              ...List.generate(5, (i) {
                                final value = (professional.rating ?? 0)
                                    .round();
                                return Icon(
                                  i < value ? Icons.star : Icons.star_outline,
                                  size: 16,
                                  color: AppColors.gold,
                                );
                              }),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (professional.bio != null &&
                        professional.bio!.trim().isNotEmpty) ...[
                      Text(
                        professional.bio!.trim(),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.montserrat(
                          color: Colors.white70,
                          fontSize: 12,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 9,
                      ),
                      decoration: BoxDecoration(
                        color: professional.isAvailableNow
                            ? AppColors.online.withValues(alpha: 0.14)
                            : Colors.white.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(99),
                        border: Border.all(
                          color: professional.isAvailableNow
                              ? AppColors.online.withValues(alpha: 0.45)
                              : Colors.white12,
                        ),
                      ),
                      child: Text(
                        availability != null && availability.isNotEmpty
                            ? availability
                            : professional.isAvailableNow
                            ? translations.availableNow
                            : translations.viewAvailability,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.montserrat(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        if (professional.supportsChat)
                          Expanded(
                            child: _SessionButton(
                              icon: Icons.chat_bubble_outline,
                              label: translations.tabChat,
                              price: professional.priceChatPerMinute,
                              onTap: onTap,
                            ),
                          ),
                        if (professional.supportsChat &&
                            (professional.supportsPhone ||
                                professional.supportsVideo))
                          const SizedBox(width: 7),
                        if (professional.supportsPhone)
                          Expanded(
                            child: _SessionButton(
                              icon: Icons.phone_outlined,
                              label: translations.call,
                              price: professional.pricePhonePerMinute,
                              onTap: onTap,
                            ),
                          ),
                        if (professional.supportsPhone &&
                            professional.supportsVideo)
                          const SizedBox(width: 7),
                        if (professional.supportsVideo)
                          Expanded(
                            child: _SessionButton(
                              icon: Icons.videocam_outlined,
                              label: translations.video,
                              price: professional.priceVideoPerMinute,
                              onTap: onTap,
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
      ),
    );
  }

  Widget _initials() {
    return Center(
      child: Text(
        professional.displayName.isNotEmpty
            ? professional.displayName[0].toUpperCase()
            : '?',
        style: GoogleFonts.jost(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _ProfileBadge extends StatelessWidget {
  final IconData icon;
  final String label;

  const _ProfileBadge({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.42),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.online),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.montserrat(
              color: Colors.white,
              fontSize: 9,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _SessionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final double? price;
  final VoidCallback onTap;

  const _SessionButton({
    required this.icon,
    required this.label,
    required this.price,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 9),
        side: BorderSide(color: AppColors.brandPink.withValues(alpha: 0.7)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 17, color: Colors.white),
          const SizedBox(height: 3),
          Text(
            label,
            style: GoogleFonts.montserrat(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (price != null)
            Text(
              price == 0 ? 'Free' : '€${price!.toStringAsFixed(2)}/min',
              maxLines: 1,
              style: GoogleFonts.montserrat(color: Colors.white60, fontSize: 8),
            ),
        ],
      ),
    );
  }
}

class _AiAssistantsSection extends ConsumerWidget {
  final String search;

  const _AiAssistantsSection({required this.search});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final aiAsync = ref.watch(aiAssistantsProvider(search));

    return aiAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (ais) {
        if (ais.isEmpty) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.mediumPurple, AppColors.aqua],
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.auto_awesome,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Try for free, 24/7!',
                          style: GoogleFonts.jost(
                            fontSize: 19,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'AI-powered guidance, always available',
                          style: GoogleFonts.montserrat(
                            fontSize: 12,
                            color: Colors.white60,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              SizedBox(
                height: 130,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemBuilder: (_, i) =>
                      _AiAssistantCard(professional: ais[i], index: i),
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemCount: ais.length,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _AiAssistantCard extends StatelessWidget {
  final Professional professional;
  final int index;

  const _AiAssistantCard({required this.professional, required this.index});

  @override
  Widget build(BuildContext context) {
    final imageUrl = _profileImageUrl(
      rawAvatar: professional.avatar,
      seed: professional.coId.isNotEmpty
          ? professional.coId
          : professional.displayName,
    );

    return GestureDetector(
      onTap: () => context.push('/professional/${professional.coId}'),
      child: Container(
        width: 140,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFF261846),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.mediumPurple.withValues(alpha: 0.15),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.mediumPurple.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        AppColors.mediumPurple.withValues(alpha: 0.8),
                        AppColors.aqua.withValues(alpha: 0.8),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: ClipOval(
                    child: Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Center(
                        child: Text(
                          professional.displayName.isNotEmpty
                              ? professional.displayName[0].toUpperCase()
                              : '?',
                          style: GoogleFonts.jost(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: AppColors.mediumPurple,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    child: const Icon(
                      Icons.auto_awesome,
                      size: 10,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              professional.displayName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: GoogleFonts.jost(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 3),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.aqua.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(99),
              ),
              child: Text(
                'Free',
                style: GoogleFonts.montserrat(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ],
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
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: Duration(milliseconds: 360 + delayMs),
      curve: Curves.easeOutCubic,
      builder: (context, value, builtChild) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 16 * (1 - value)),
            child: builtChild,
          ),
        );
      },
      child: child,
    );
  }
}
