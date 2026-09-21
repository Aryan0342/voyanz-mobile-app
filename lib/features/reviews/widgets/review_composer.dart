import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:voyanz/core/providers/language_provider.dart';
import 'package:voyanz/core/theme/app_colors.dart';
import 'package:voyanz/features/auth/providers/auth_provider.dart';
import 'package:voyanz/features/professionals/models/professional.dart';
import 'package:voyanz/features/reviews/data/reviews_history_data_source.dart';
import 'package:voyanz/features/reviews/providers/reviews_provider.dart';

Future<void> showReviewComposer(
  BuildContext context,
  WidgetRef ref,
  Professional professional,
) async {
  final t = ref.read(translationsProvider);
  var rating = 5;
  final controller = TextEditingController();
  final submit = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        backgroundColor: AppColors.surfaceCard,
        title: Text(
          t.writeReview,
          style: GoogleFonts.jost(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              professional.displayName,
              style: GoogleFonts.montserrat(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<int>(
              initialValue: rating,
              decoration: InputDecoration(labelText: t.yourRating),
              items: [5, 4, 3, 2, 1]
                  .map(
                    (value) => DropdownMenuItem(
                      value: value,
                      child: Text(t.starCount(value)),
                    ),
                  )
                  .toList(),
              onChanged: (value) => setState(() => rating = value ?? rating),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              maxLines: 4,
              decoration: InputDecoration(labelText: t.yourComment),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(t.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(t.submitReview),
          ),
        ],
      ),
    ),
  );
  if (submit != true || !context.mounted) {
    controller.dispose();
    return;
  }

  try {
    final user = ref.read(authStateProvider).valueOrNull;
    await ref.read(reviewsHistoryRepositoryProvider).postReview({
      'co_id_professional': professional.coId,
      if (user != null) 'co_id_customer': user.coId,
      'rv_note': rating,
      'rv_text': controller.text.trim(),
    });
    ref.invalidate(customerReviewsProvider);
    ref.invalidate(reviewEligibilityProvider(professional.coId));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(t.reviewSubmitted),
          backgroundColor: AppColors.online,
        ),
      );
    }
  } catch (error) {
    if (context.mounted) {
      // Show the server's own sentence as-is (API_REST §11.1); anything else
      // gets a fully localized message, never a half-translated one.
      final serverMessage = error is ReviewSubmitException
          ? error.serverMessage
          : null;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            serverMessage ?? t.reviewSubmitFailed(t.genericErrorRetry),
          ),
          backgroundColor: AppColors.error,
        ),
      );
    }
  } finally {
    controller.dispose();
  }
}
