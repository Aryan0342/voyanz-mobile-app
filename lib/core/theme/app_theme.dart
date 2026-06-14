import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:voyanz/core/theme/app_colors.dart';

/// Light, polished ThemeData used across the app.
abstract final class AppTheme {
  static ThemeData get dark {
    const radius = 16.0;
    final baseText = GoogleFonts.manropeTextTheme(ThemeData.light().textTheme);

    final textTheme = baseText.copyWith(
      displayLarge: GoogleFonts.jost(
        fontSize: 38,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        letterSpacing: 0,
        height: 1.08,
      ),
      displayMedium: GoogleFonts.jost(
        fontSize: 30,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        letterSpacing: 0,
        height: 1.12,
      ),
      headlineLarge: GoogleFonts.jost(
        fontSize: 27,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        letterSpacing: 0,
      ),
      headlineMedium: GoogleFonts.jost(
        fontSize: 23,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        letterSpacing: 0,
      ),
      headlineSmall: GoogleFonts.jost(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        letterSpacing: 0,
      ),
      titleLarge: GoogleFonts.jost(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        letterSpacing: 0,
      ),
      titleMedium: GoogleFonts.manrope(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        letterSpacing: 0,
      ),
      titleSmall: GoogleFonts.manrope(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: AppColors.textSecondary,
        letterSpacing: 0,
      ),
      bodyLarge: GoogleFonts.manrope(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: AppColors.textPrimary,
        letterSpacing: 0,
        height: 1.45,
      ),
      bodyMedium: GoogleFonts.manrope(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: AppColors.textSecondary,
        letterSpacing: 0,
        height: 1.42,
      ),
      bodySmall: GoogleFonts.manrope(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: AppColors.textMuted,
        letterSpacing: 0,
        height: 1.35,
      ),
      labelLarge: GoogleFonts.manrope(
        fontSize: 14,
        fontWeight: FontWeight.w800,
        color: AppColors.textPrimary,
        letterSpacing: 0,
      ),
      labelMedium: GoogleFonts.manrope(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: AppColors.textSecondary,
        letterSpacing: 0,
      ),
      labelSmall: GoogleFonts.manrope(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: AppColors.textMuted,
        letterSpacing: 0,
      ),
    );

    final roundedShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radius),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.canvas,
      textTheme: textTheme,
      fontFamily: GoogleFonts.manrope().fontFamily,
      splashFactory: InkSparkle.splashFactory,
      visualDensity: VisualDensity.adaptivePlatformDensity,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
        },
      ),
      colorScheme: const ColorScheme.light(
        primary: AppColors.mediumPurple,
        onPrimary: Colors.white,
        secondary: AppColors.magentaRose,
        onSecondary: Colors.white,
        tertiary: AppColors.aqua,
        onTertiary: Colors.white,
        surface: AppColors.surfaceCard,
        onSurface: AppColors.textPrimary,
        surfaceContainerHighest: AppColors.surfaceElevated,
        outline: AppColors.borderSubtle,
        error: AppColors.error,
        onError: Colors.white,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleSpacing: 0,
        toolbarHeight: kToolbarHeight,
        titleTextStyle: GoogleFonts.jost(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
          letterSpacing: 0,
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        shadowColor: Colors.transparent,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surfaceCard,
        indicatorColor: AppColors.mediumPurple.withValues(alpha: 0.14),
        elevation: 0,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return GoogleFonts.manrope(
            fontSize: 11,
            fontWeight: selected ? FontWeight.w800 : FontWeight.w700,
            color: selected ? AppColors.deepIndigo : AppColors.textMuted,
            letterSpacing: 0,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? AppColors.mediumPurple : AppColors.textMuted,
            size: selected ? 23 : 22,
          );
        }),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surfaceCard,
        elevation: 2,
        shadowColor: Colors.black.withValues(alpha: 0.10),
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: AppColors.borderSubtle),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceCard,
        hintStyle: textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
        labelStyle: textTheme.bodyMedium?.copyWith(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w700,
        ),
        floatingLabelStyle: textTheme.bodySmall?.copyWith(
          color: AppColors.mediumPurple,
          fontWeight: FontWeight.w800,
        ),
        prefixIconColor: AppColors.textMuted,
        suffixIconColor: AppColors.textMuted,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: const BorderSide(color: AppColors.borderSubtle),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: const BorderSide(color: AppColors.borderSubtle),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: const BorderSide(color: AppColors.mediumPurple, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: const BorderSide(color: AppColors.error, width: 1.6),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.mediumPurple,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.surfaceLight,
          disabledForegroundColor: AppColors.textMuted,
          minimumSize: const Size(52, 50),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          elevation: 2,
          shadowColor: AppColors.mediumPurple.withValues(alpha: 0.20),
          shape: roundedShape,
          textStyle: textTheme.labelLarge?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.mediumPurple,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.surfaceLight,
          disabledForegroundColor: AppColors.textMuted,
          minimumSize: const Size(52, 50),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          elevation: 2,
          shadowColor: AppColors.mediumPurple.withValues(alpha: 0.20),
          shape: roundedShape,
          textStyle: textTheme.labelLarge?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.deepIndigo,
          minimumSize: const Size(52, 50),
          side: const BorderSide(color: AppColors.borderStrong),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          shape: roundedShape,
          textStyle: textTheme.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.mediumPurple,
          minimumSize: const Size(44, 42),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          shape: roundedShape,
          textStyle: textTheme.labelLarge,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          disabledForegroundColor: AppColors.textMuted,
          minimumSize: const Size(42, 42),
          padding: const EdgeInsets.all(10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.mediumPurple,
        foregroundColor: Colors.white,
        elevation: 5,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceCard,
        selectedColor: AppColors.mediumPurple.withValues(alpha: 0.11),
        disabledColor: AppColors.surfaceLight,
        labelStyle: textTheme.labelMedium?.copyWith(color: AppColors.textSecondary),
        secondaryLabelStyle: textTheme.labelMedium?.copyWith(
          color: AppColors.mediumPurple,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        side: const BorderSide(color: AppColors.borderSubtle),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return AppColors.mediumPurple.withValues(alpha: 0.11);
            }
            return AppColors.surfaceCard;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return AppColors.deepIndigo;
            }
            return AppColors.textSecondary;
          }),
          side: WidgetStateProperty.all(
            const BorderSide(color: AppColors.borderSubtle),
          ),
          shape: WidgetStateProperty.all(roundedShape),
          textStyle: WidgetStateProperty.all(textTheme.labelMedium),
        ),
      ),
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        titleTextStyle: textTheme.titleMedium,
        subtitleTextStyle: textTheme.bodySmall,
        iconColor: AppColors.textMuted,
        shape: roundedShape,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.deepIndigo,
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        behavior: SnackBarBehavior.floating,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surfaceCard,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        titleTextStyle: textTheme.headlineSmall,
        contentTextStyle: textTheme.bodyMedium,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surfaceCard,
        modalBackgroundColor: AppColors.surfaceCard,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        showDragHandle: true,
        dragHandleColor: AppColors.textMuted,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.mediumPurple,
        linearTrackColor: AppColors.surfaceLight,
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: AppColors.mediumPurple,
        selectionColor: AppColors.mediumPurple.withValues(alpha: 0.22),
        selectionHandleColor: AppColors.mediumPurple,
      ),
      switchTheme: SwitchThemeData(
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.mediumPurple.withValues(alpha: 0.28);
          }
          return AppColors.surfaceLight;
        }),
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.mediumPurple;
          }
          return AppColors.textMuted;
        }),
      ),
      checkboxTheme: CheckboxThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        side: const BorderSide(color: AppColors.borderStrong),
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.mediumPurple;
          }
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(Colors.white),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.borderSubtle,
        space: 1,
      ),
      iconTheme: const IconThemeData(color: AppColors.textSecondary, size: 24),
    );
  }
}
