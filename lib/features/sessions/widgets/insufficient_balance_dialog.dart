import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:voyanz/core/l10n/app_translations.dart';
import 'package:voyanz/core/theme/app_colors.dart';
import 'package:voyanz/core/theme/widgets.dart';

Future<void> showInsufficientBalanceDialog(
  BuildContext context,
  AppTranslations t, {
  String? serverMessage,
}) {
  final message = (serverMessage ?? '').trim();
  return showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      backgroundColor: AppColors.surfaceCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        t.insufficientBalance,
        style: GoogleFonts.jost(
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
      ),
      content: Text(
        message.isEmpty ? t.insufficientBalanceMessage : message,
        style: GoogleFonts.montserrat(color: AppColors.textSecondary),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: Text(t.cancel),
        ),
        GradientButton(
          onPressed: () {
            Navigator.pop(dialogContext);
            context.go('/wallet/topup');
          },
          child: Text(t.topUpNow),
        ),
      ],
    ),
  );
}
