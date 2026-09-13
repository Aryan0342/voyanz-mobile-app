import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voyanz/core/theme/app_colors.dart';
import 'package:voyanz/core/theme/app_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Voyanz theme uses the website dark brand system', () {
    final theme = AppTheme.dark;

    expect(theme.brightness, Brightness.dark);
    expect(theme.scaffoldBackgroundColor, AppColors.canvas);
    expect(theme.colorScheme.surface, AppColors.surfaceCard);
    expect(theme.colorScheme.onSurface, AppColors.textPrimary);
    expect(theme.inputDecorationTheme.fillColor, AppColors.surfaceCard);
    expect(theme.dialogTheme.backgroundColor, AppColors.surfaceCard);
    expect(theme.bottomSheetTheme.backgroundColor, AppColors.surfaceCard);
  });
}
