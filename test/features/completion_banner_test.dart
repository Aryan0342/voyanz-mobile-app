import 'package:flutter_test/flutter_test.dart';
import 'package:voyanz/features/professionals/models/professional_profile.dart';
import 'package:voyanz/features/professionals/widgets/profile_completion_banner.dart';

ProfessionalProfile _profile({
  int? score,
  List<String> missing = const [],
  bool isComplete = false,
}) => ProfessionalProfile(
      fullName: 'Pro aryan',
      completionScore: score,
      completionMissing: missing,
      completionIsComplete: isComplete,
    );

void main() {
  group('dashboard completion banner', () {
    test('shows while the server still lists something missing', () {
      expect(
        shouldShowCompletionBanner(
          _profile(score: 64, missing: const ['photo', 'description']),
        ),
        isTrue,
      );
    });

    test('hides once the profile is complete', () {
      expect(
        shouldShowCompletionBanner(_profile(score: 100, isComplete: true)),
        isFalse,
      );
    });

    // A profile that satisfies every rule but is not flagged complete still
    // has nothing to nag about.
    test('hides when nothing is listed as missing', () {
      expect(shouldShowCompletionBanner(_profile(score: 100)), isFalse);
    });

    // Older servers send no checklist; inventing one locally would claim a
    // profile is incomplete on rules the app cannot see.
    test('stays hidden when the server sends no checklist', () {
      expect(shouldShowCompletionBanner(_profile()), isFalse);
    });

    test('stays hidden before the profile loads', () {
      expect(shouldShowCompletionBanner(null), isFalse);
    });
  });
}
