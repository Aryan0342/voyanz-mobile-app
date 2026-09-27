import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:voyanz/core/providers/language_provider.dart';
import 'package:voyanz/core/theme/app_colors.dart';
import 'package:voyanz/features/auth/providers/auth_provider.dart';
import 'package:voyanz/features/reviews/models/review_client.dart';
import 'package:voyanz/features/reviews/providers/reviews_provider.dart';

/// What the professional chose, returned when the dialog closes.
class _ProReviewDraft {
  final String clientId;
  final String text;

  const _ProReviewDraft({required this.clientId, required this.text});
}

/// Lets a professional review one of their clients (contract §11.1).
///
/// Mirrors the website: pick a client from `mycustomers`, write a comment, and
/// post with `rv_ispro: 1`. There is no star rating in this direction — the
/// server takes `rv_note` only from a customer reviewing a professional.
///
/// The client list is fetched before the dialog opens so the dialog itself
/// watches no provider, and the dialog owns its `TextEditingController`
/// through a [StatefulWidget]. Disposing the controller straight after
/// `showDialog` returns — while the route is still animating out and the
/// field is still mounted — crashed the app on `_dependents.isEmpty`.
Future<void> showProReviewComposer(BuildContext context, WidgetRef ref) async {
  final t = ref.read(translationsProvider);
  final user = ref.read(authStateProvider).valueOrNull;
  if (user == null || user.coId.isEmpty) return;

  void notify(String message, {bool error = false}) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? AppColors.error : AppColors.online,
      ),
    );
  }

  List<ReviewClient> clients;
  try {
    clients = await ref.read(proReviewClientsProvider.future);
  } catch (_) {
    notify(t.genericErrorRetry, error: true);
    return;
  }
  if (!context.mounted) return;
  if (clients.isEmpty) {
    notify(t.noClientsToReview, error: true);
    return;
  }

  final draft = await showDialog<_ProReviewDraft>(
    context: context,
    builder: (_) => _ProReviewDialog(clients: clients),
  );
  if (draft == null) return;

  try {
    await ref
        .read(reviewsHistoryRepositoryProvider)
        .postProfessionalReview(
          coIdProfessional: user.coId,
          coIdCustomer: draft.clientId,
          text: draft.text,
        );
    ref.invalidate(proWrittenReviewsProvider);
    notify(t.reviewSubmitted);
  } catch (e) {
    notify(
      e.toString().replaceFirst(RegExp(r'^Exception:\s*'), '').trim(),
      error: true,
    );
  }
}

class _ProReviewDialog extends ConsumerStatefulWidget {
  const _ProReviewDialog({required this.clients});

  final List<ReviewClient> clients;

  @override
  ConsumerState<_ProReviewDialog> createState() => _ProReviewDialogState();
}

class _ProReviewDialogState extends ConsumerState<_ProReviewDialog> {
  final _controller = TextEditingController();

  /// Kept as the id, not the object: a refreshed list would hold different
  /// instances and the selection would silently stop matching.
  String? _selectedId;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    if (_selectedId == null) {
      setState(() => _error = ref.read(translationsProvider).clientRequired);
      return;
    }
    final text = _controller.text.trim();
    if (text.isEmpty) {
      setState(
        () => _error = ref.read(translationsProvider).yourCommentRequired,
      );
      return;
    }
    Navigator.of(
      context,
    ).pop(_ProReviewDraft(clientId: _selectedId!, text: text));
  }

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(translationsProvider);

    return AlertDialog(
      backgroundColor: AppColors.surfaceCard,
      title: Text(
        t.reviewAClient,
        style: GoogleFonts.jost(color: Colors.white),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              t.chooseClient,
              style: GoogleFonts.montserrat(
                fontSize: 12,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 6),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 180),
              child: ListView(
                shrinkWrap: true,
                children: widget.clients.map((client) {
                  final isSelected = client.id == _selectedId;
                  return InkWell(
                    onTap: () => setState(() {
                      _selectedId = client.id;
                      _error = null;
                    }),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          Icon(
                            isSelected
                                ? Icons.radio_button_checked
                                : Icons.radio_button_unchecked,
                            size: 18,
                            color: isSelected
                                ? AppColors.brandPink
                                : AppColors.textMuted,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              client.name,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.montserrat(
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _controller,
              maxLines: 4,
              style: GoogleFonts.montserrat(color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: t.yourComment,
                hintStyle: GoogleFonts.montserrat(color: AppColors.textMuted),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(
                _error!,
                style: GoogleFonts.montserrat(
                  fontSize: 12,
                  color: AppColors.error,
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            t.cancel,
            style: GoogleFonts.montserrat(color: AppColors.textSecondary),
          ),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: AppColors.brandPink),
          onPressed: _submit,
          child: Text(t.submitReview),
        ),
      ],
    );
  }
}
