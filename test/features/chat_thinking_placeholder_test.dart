import 'package:flutter_test/flutter_test.dart';
import 'package:voyanz/features/chat/models/chat_models.dart';

ChatMessage _msg(String raw, {String html = '', String type = 'text'}) =>
    ChatMessage.fromJson({
      'chme_id': 1,
      'chgr_id': 678,
      'co_id': 20,
      'chme_type': type,
      'chme_text_raw': raw,
      'chme_text': html,
    });

void main() {
  // Amaury, 2026-09-21: the server's thinking label is fr/en only; the app
  // must detect it and show its own translation.
  group('AI thinking placeholder', () {
    test('the exact production placeholder frame is detected', () {
      // chat_message_new captured from voyanz.com on 2026-09-21: HTML only,
      // no chme_text_raw, marked with the chat-ai-thinking class.
      final placeholder = ChatMessage.fromJson({
        'chme_id': 1801,
        'co_id': 23,
        'chgr_id': 683,
        'chme_type': 'text',
        'chme_text':
            '<p class="mb-0 chat-ai-thinking"><span class="chat-ai-thinking-dots" '
            'aria-hidden="true"></span><span class="chat-ai-thinking-label">'
            'Notre voyante IA réfléchit…</span></p>',
        'createdAt': '2026-09-21 20:02:14',
        'contact': {'co_id': 23, 'co_type': 'professional', 'co_isassistant': 1},
      });
      expect(placeholder.isAiThinking, isTrue);
    });

    test('the class alone marks it, whatever the label language', () {
      final m = ChatMessage.fromJson({
        'chme_id': 3,
        'chme_type': 'text',
        'chme_text': '<p class="chat-ai-thinking"><span>Pensando</span></p>',
      });
      expect(m.isAiThinking, isTrue);
    });

    test('French label seen in production is detected', () {
      expect(_msg('Notre voyante IA réfléchit…').isAiThinking, isTrue);
    });

    test('English label and dot variants are detected', () {
      expect(_msg('Our AI psychic is thinking...').isAiThinking, isTrue);
      expect(_msg('Notre voyante IA réfléchit').isAiThinking, isTrue);
    });

    test('HTML-only label is detected', () {
      // An empty chme_text_raw falls back to the HTML text.
      final emptyRaw = _msg('', html: '<p><em>Notre voyante IA réfléchit…</em></p>');
      expect(emptyRaw.isAiThinking, isTrue);
      expect(emptyRaw.content, 'Notre voyante IA réfléchit…');
      final htmlOnly = ChatMessage.fromJson({
        'chme_id': 2,
        'chme_type': 'text',
        'chme_text': '<p><em>Notre voyante IA réfléchit…</em></p>',
      });
      expect(htmlOnly.isAiThinking, isTrue);
    });

    test('a real AI answer is never mistaken for the placeholder', () {
      expect(
        _msg(
          "Bonjour ! Je suis ici pour vous guider à travers les messages "
          "angéliques. Si vous le souhaitez, partagez un aspect de votre vie.",
        ).isAiThinking,
        isFalse,
      );
      expect(_msg('Elle réfléchit beaucoup à votre question, et voici ma réponse détaillée pour vous.').isAiThinking, isFalse);
      expect(_msg('Bonjour').isAiThinking, isFalse);
    });

    test('images are never placeholders', () {
      expect(_msg('Notre voyante IA réfléchit…', type: 'image').isAiThinking, isFalse);
    });
  });

  group('conversation preview', () {
    test('an empty sender name leaves no stray colon', () {
      final g = ChatGroup.fromJson({
        'chgr_id': 683,
        'lastmessage': ' : Bonjour, je regarde ce que vous vivez',
      });
      expect(g.lastMessage, 'Bonjour, je regarde ce que vous vivez');
    });

    test('a named sender is kept', () {
      final g = ChatGroup.fromJson({'chgr_id': 1, 'lastmessage': 'Asad : Hola'});
      expect(g.lastMessage, 'Asad : Hola');
    });
  });
}
