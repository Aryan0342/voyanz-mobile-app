import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:voyanz/core/config/env.dart';
import 'package:voyanz/core/providers/language_provider.dart';
import 'package:voyanz/core/theme/app_colors.dart';
import 'package:voyanz/core/theme/widgets.dart';
import 'package:voyanz/features/account/providers/account_provider.dart';
import 'package:voyanz/features/auth/providers/auth_provider.dart';
import 'package:voyanz/core/utils/string_utils.dart';
import 'package:voyanz/features/professionals/models/professional_profile.dart';
import 'package:voyanz/features/professionals/providers/catalog_items_provider.dart';
import 'package:voyanz/features/professionals/providers/professional_account_provider.dart';

/// The professional's public profile (contract P1).
///
/// The whole object is rewritten on every save — the server does not merge —
/// so the screen always sends every field it knows about.
class ProfessionalProfileEditScreen extends ConsumerStatefulWidget {
  const ProfessionalProfileEditScreen({super.key});

  @override
  ConsumerState<ProfessionalProfileEditScreen> createState() =>
      _ProfessionalProfileEditScreenState();
}

class _ProfessionalProfileEditScreenState
    extends ConsumerState<ProfessionalProfileEditScreen> {
  static const _maxCategories = 5;
  static const _maxSpecialities = 5;
  static const _minDescription = 50;

  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _phonePriceCtrl = TextEditingController();
  final _videoPriceCtrl = TextEditingController();
  final _chatPriceCtrl = TextEditingController();

  DateTime? _activityStarted;
  bool _usePhone = false;
  bool _useVideo = false;
  bool _useChat = false;
  final Set<String> _tools = {};
  final Set<String> _specialities = {};
  final Set<String> _languages = {};

  bool _loaded = false;
  bool _saving = false;
  bool _uploadingPhoto = false;
  int _photoVersion = 0;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _phonePriceCtrl.dispose();
    _videoPriceCtrl.dispose();
    _chatPriceCtrl.dispose();
    super.dispose();
  }

  void _fill(ProfessionalProfile profile) {
    if (_loaded) return;
    _loaded = true;
    _nameCtrl.text = profile.fullName;
    _descCtrl.text = profile.description;
    _usePhone = profile.usePhone;
    _useVideo = profile.useVideo;
    _useChat = profile.useChat;
    _tools.addAll(profile.tools);
    _specialities.addAll(profile.specialities);
    _languages.addAll(profile.languages);
    _activityStarted = DateTime.tryParse(profile.activityStarted);
    _phonePriceCtrl.text = _euros(profile.pricePhoneCents);
    _videoPriceCtrl.text = _euros(profile.priceVideoCents);
    _chatPriceCtrl.text = _euros(profile.priceChatCents);
  }

  String _euros(int cents) =>
      cents <= 0 ? '' : (cents / 100).toStringAsFixed(2);

  /// Prices go out in euros per minute; the server stores cents (P1).
  double? _priceOf(TextEditingController ctrl) {
    final text = ctrl.text.trim().replaceAll(',', '.');
    if (text.isEmpty) return null;
    return double.tryParse(text);
  }

  void _toast(String message, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? AppColors.error : AppColors.online,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _pickPhoto() async {
    final t = ref.read(translationsProvider);
    final coId = ref.read(authStateProvider).valueOrNull?.coId;
    if (coId == null || _uploadingPhoto) return;

    try {
      // Resize on device before upload, as the contract asks.
      final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (picked == null) return;

      setState(() => _uploadingPhoto = true);
      final bytes = await File(picked.path).readAsBytes();
      final mime = picked.path.toLowerCase().endsWith('.png')
          ? 'png'
          : picked.path.toLowerCase().endsWith('.webp')
          ? 'webp'
          : 'jpeg';
      await ref
          .read(accountRepositoryProvider)
          .uploadProfileImage(
            coId,
            'data:image/$mime;base64,${base64Encode(bytes)}',
          );
      ref.invalidate(professionalProfileProvider);
      if (!mounted) return;
      // Cache-buster, so the new photo actually shows (P1).
      setState(() => _photoVersion = DateTime.now().millisecondsSinceEpoch);
      _toast(t.photoUpdated);
    } catch (e) {
      _toast(_clean(e), error: true);
    } finally {
      if (mounted) setState(() => _uploadingPhoto = false);
    }
  }

  String _clean(Object error) =>
      error.toString().replaceFirst(RegExp(r'^Exception:\s*'), '').trim();

  Future<void> _save() async {
    final t = ref.read(translationsProvider);
    final coId = ref.read(authStateProvider).valueOrNull?.coId;
    if (coId == null) return;

    final description = _descCtrl.text.trim();
    if (description.isNotEmpty && description.length < _minDescription) {
      return _toast(t.descriptionTooShort(_minDescription), error: true);
    }

    setState(() => _saving = true);
    try {
      // Every field, every time: the server replaces the whole profile.
      await ref.read(accountRepositoryProvider).updateProDescription(coId, {
        'co_fullname': _nameCtrl.text.trim(),
        'co_description': description,
        'co_activity_started': _activityStarted == null
            ? ''
            : _activityStarted!.toIso8601String().split('T').first,
        'co_use_phone': _usePhone,
        'co_use_video': _useVideo,
        'co_use_chat': _useChat,
        'co_price_phone': _priceOf(_phonePriceCtrl) ?? 0,
        'co_price_video': _priceOf(_videoPriceCtrl) ?? 0,
        'co_price_chat': _priceOf(_chatPriceCtrl) ?? 0,
        'co_languages': _languages.toList(),
        'co_tools': _tools.toList(),
        'co_specialities': _specialities.toList(),
      });
      ref.invalidate(professionalProfileProvider);
      await ref.read(authStateProvider.notifier).refreshUser();
      _toast(t.profileUpdated);
    } catch (e) {
      _toast(_clean(e), error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _toggle(Set<String> target, String key, int max) {
    setState(() {
      if (target.contains(key)) {
        target.remove(key);
      } else if (target.length < max) {
        target.add(key);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(translationsProvider);
    final catalog = ref.watch(catalogItemsProvider);
    final profileAsync = ref.watch(professionalProfileProvider);
    final coId = ref.watch(authStateProvider).valueOrNull?.coId ?? '';

    return GradientScaffold(
      appBar: VoyanzAppBar(
        title: Text(
          t.myProfile,
          style: GoogleFonts.lora(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: profileAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.mediumPurple),
        ),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              _clean(e),
              textAlign: TextAlign.center,
              style: GoogleFonts.montserrat(color: AppColors.textSecondary),
            ),
          ),
        ),
        data: (profile) {
          _fill(profile);
          return SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
              children: [
                _completionCard(t, profile),
                const SizedBox(height: 18),
                _photoCard(t, profile, coId),
                const SizedBox(height: 18),
                _Section(
                  title: t.yourProfile,
                  children: [
                    TextField(
                      controller: _nameCtrl,
                      decoration: InputDecoration(labelText: t.displayedName),
                    ),
                    const SizedBox(height: 12),
                    _DateField(
                      label: t.activityStartedLabel,
                      value: _activityStarted,
                      onPick: (date) => setState(() => _activityStarted = date),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _descCtrl,
                      maxLines: 6,
                      decoration: InputDecoration(
                        labelText: t.descriptionOptional,
                        helperText: t.descriptionMinChars(_minDescription),
                        helperMaxLines: 2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                _Section(
                  title: t.sessionTypesAndPrices,
                  children: [
                    _PriceRow(
                      label: t.phoneCall,
                      enabled: _usePhone,
                      controller: _phonePriceCtrl,
                      onToggle: (v) => setState(() => _usePhone = v),
                    ),
                    _PriceRow(
                      label: t.videoCall,
                      enabled: _useVideo,
                      controller: _videoPriceCtrl,
                      onToggle: (v) => setState(() => _useVideo = v),
                    ),
                    _PriceRow(
                      label: t.textChat,
                      enabled: _useChat,
                      controller: _chatPriceCtrl,
                      onToggle: (v) => setState(() => _useChat = v),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      t.priceGuidance,
                      style: GoogleFonts.montserrat(
                        fontSize: 11,
                        height: 1.4,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                _ChipSection(
                  title: t.categoriesMax(_maxCategories),
                  items: catalog.tools,
                  selected: _tools,
                  onTap: (key) => _toggle(_tools, key, _maxCategories),
                  emptyHint: t.catalogUnavailable,
                ),
                const SizedBox(height: 18),
                _ChipSection(
                  title: t.specialitiesMax(_maxSpecialities),
                  items: catalog.specialities,
                  selected: _specialities,
                  onTap: (key) =>
                      _toggle(_specialities, key, _maxSpecialities),
                  emptyHint: t.catalogUnavailable,
                ),
                const SizedBox(height: 18),
                _ChipSection(
                  title: t.spokenLanguages,
                  items: catalog.languages,
                  selected: _languages,
                  onTap: (key) => _toggle(_languages, key, 99),
                  emptyHint: t.catalogUnavailable,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _saving ? null : _save,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.brandPink,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(t.save),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _completionCard(dynamic t, ProfessionalProfile profile) {
    final checks = <String, bool>{
      t.checklistPhoto: profile.hasPhoto,
      t.checklistDescription: profile.description.length >= _minDescription,
      t.checklistCategories: profile.tools.isNotEmpty,
      t.checklistSpecialities: profile.specialities.isNotEmpty,
      t.checklistPrice: profile.hasAnyPrice,
      t.checklistLanguages: profile.languages.isNotEmpty,
    };
    final done = checks.values.where((v) => v).length;

    return _Section(
      title: t.catalogueChecklist,
      children: [
        Text(
          profile.active ? t.profileActive : t.profilePendingActivation,
          style: GoogleFonts.montserrat(
            fontSize: 12,
            height: 1.4,
            color: profile.active ? AppColors.online : AppColors.warning,
          ),
        ),
        const SizedBox(height: 12),
        LinearProgressIndicator(
          value: done / checks.length,
          backgroundColor: AppColors.surfaceElevated,
          color: AppColors.brandPink,
        ),
        const SizedBox(height: 12),
        ...checks.entries.map(
          (entry) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              children: [
                Icon(
                  entry.value
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_unchecked,
                  size: 16,
                  color: entry.value ? AppColors.online : AppColors.textMuted,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    entry.key,
                    style: GoogleFonts.montserrat(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _photoCard(dynamic t, ProfessionalProfile profile, String coId) {
    final url =
        '${EnvConfig.current.baseUrl}/api/1.0/image/$coId/400/400/cover'
        '?d=$_photoVersion';

    return _Section(
      title: t.profilePhoto,
      children: [
        Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: profile.hasPhoto || _photoVersion > 0
                  ? Image.network(
                      url,
                      width: 72,
                      height: 72,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => _photoPlaceholder(),
                    )
                  : _photoPlaceholder(),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _uploadingPhoto ? null : _pickPhoto,
                icon: _uploadingPhoto
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.photo_camera_outlined),
                label: Text(t.choosePhoto),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.rosePink,
                  side: const BorderSide(color: AppColors.rosePink),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _photoPlaceholder() => Container(
    width: 72,
    height: 72,
    color: AppColors.surfaceElevated,
    child: const Icon(Icons.person, color: AppColors.textMuted),
  );
}

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _Section({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.jost(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  final String label;
  final bool enabled;
  final TextEditingController controller;
  final ValueChanged<bool> onToggle;

  const _PriceRow({
    required this.label,
    required this.enabled,
    required this.controller,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.montserrat(
                fontSize: 13,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          SizedBox(
            width: 96,
            child: TextField(
              controller: controller,
              enabled: enabled,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
              ],
              decoration: const InputDecoration(
                suffixText: '€/min',
                isDense: true,
              ),
            ),
          ),
          Switch(value: enabled, onChanged: onToggle),
        ],
      ),
    );
  }
}

class _ChipSection extends StatelessWidget {
  final String title;
  final List<CatalogItem> items;
  final Set<String> selected;
  final ValueChanged<String> onTap;
  final String emptyHint;

  const _ChipSection({
    required this.title,
    required this.items,
    required this.selected,
    required this.onTap,
    required this.emptyHint,
  });

  @override
  Widget build(BuildContext context) {
    return _Section(
      title: title,
      children: [
        // With no catalog there is nothing to choose from, but the values
        // already on the profile are still sent back untouched when the
        // professional saves, so show them read-only rather than leaving the
        // section looking empty.
        if (items.isEmpty) ...[
          Text(
            emptyHint,
            style: GoogleFonts.montserrat(
              fontSize: 12,
              color: AppColors.textMuted,
            ),
          ),
          if (selected.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: selected.map((key) {
                return Chip(
                  label: Text(humanizeSlug(key)),
                  backgroundColor: AppColors.surfaceElevated,
                  labelStyle: GoogleFonts.montserrat(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                  side: BorderSide(
                    color: AppColors.textMuted.withValues(alpha: 0.35),
                  ),
                );
              }).toList(),
            ),
          ],
        ] else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: items.map((item) {
              final isSelected = selected.contains(item.key);
              return FilterChip(
                label: Text(item.label),
                selected: isSelected,
                onSelected: (_) => onTap(item.key),
                backgroundColor: AppColors.surfaceElevated,
                selectedColor: AppColors.brandPink.withValues(alpha: 0.28),
                labelStyle: GoogleFonts.montserrat(
                  fontSize: 12,
                  color: AppColors.textPrimary,
                ),
                side: BorderSide(
                  color: isSelected
                      ? AppColors.brandPink
                      : AppColors.borderSubtle,
                ),
              );
            }).toList(),
          ),
      ],
    );
  }
}

class _DateField extends StatelessWidget {
  final String label;
  final DateTime? value;
  final ValueChanged<DateTime> onPick;

  const _DateField({
    required this.label,
    required this.value,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    final text = value == null
        ? ''
        : value!.toIso8601String().split('T').first;
    return InkWell(
      onTap: () async {
        final now = DateTime.now();
        final picked = await showDatePicker(
          context: context,
          initialDate: value ?? DateTime(now.year - 5),
          firstDate: DateTime(1970),
          lastDate: now,
        );
        if (picked != null) onPick(picked);
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: const Icon(Icons.calendar_today_outlined, size: 18),
        ),
        child: Text(
          text,
          style: GoogleFonts.montserrat(color: AppColors.textPrimary),
        ),
      ),
    );
  }
}
