import 'package:flutter_test/flutter_test.dart';
import 'package:voyanz/features/professionals/models/professional.dart';

void main() {
  group('Voyanz professional payload parsing', () {
    test('uses the public display name and complete directory metadata', () {
      final professional = Professional.fromJson({
        'co_id': 52,
        'co_fullname': 'Melli',
        'co_name': 'vogt',
        'co_description': 'A production biography.',
        'co_specialities': ['Tarot', 'Love'],
        'co_tools': ['Cards'],
        'co_languages': ['French', 'English'],
        'co_price_phone': 180,
        'co_price_chat': 160,
        'co_use_phone': 1,
        'co_use_chat': 1,
      });

      expect(professional.displayName, 'Melli');
      expect(professional.bio, 'A production biography.');
      expect(professional.specialties, ['Tarot', 'Love']);
      expect(professional.tools, ['Cards']);
      expect(professional.languages, ['French', 'English']);
      expect(professional.pricePhonePerMinute, 1.8);
      expect(professional.priceChatPerMinute, 1.6);
      expect(professional.supportsPhone, isTrue);
      expect(professional.supportsChat, isTrue);
    });

    test('enriches the compact detail response from directory data', () {
      final compact = ProfessionalDetail.fromJson({
        'co_id': 24,
        'co_fullname': 'Anges',
        'co_type': 'professional',
      });
      final directory = Professional.fromJson({
        'co_id': 24,
        'co_fullname': 'Anges',
        'co_description': 'Always-on AI guidance.',
        'co_specialities': ['Spiritual guidance'],
        'co_tools': ['Artificial intelligence'],
        'co_languages': ['French'],
        'co_isassistant': 1,
      });

      final enriched = compact.withListFallback(directory);

      expect(enriched.displayName, 'Anges');
      expect(enriched.description, 'Always-on AI guidance.');
      expect(enriched.specialty, 'Spiritual guidance');
      expect(enriched.specialties, ['Spiritual guidance']);
      expect(enriched.tools, ['Artificial intelligence']);
      expect(enriched.languages, ['French']);
      expect(enriched.isAssistant, isTrue);
    });
  });
}
