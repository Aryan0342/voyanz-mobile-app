import 'package:flutter_test/flutter_test.dart';
import 'package:voyanz/features/auth/models/user.dart';

// WEBSOCKET §6: co_online is 1 = online, 0 = offline, 2 = busy. The pro
// dashboard switch is seeded from it.
void main() {
  group('User.online', () {
    test('reads co_online as an int', () {
      expect(User.fromJson({'co_id': 139, 'co_online': 1}).online, 1);
      expect(User.fromJson({'co_id': 139, 'co_online': 0}).online, 0);
      expect(User.fromJson({'co_id': 139, 'co_online': 2}).online, 2);
    });

    test('reads string and alternative keys', () {
      expect(User.fromJson({'co_id': 139, 'co_online': '1'}).online, 1);
      expect(User.fromJson({'co_id': 139, 'is_online': 1}).online, 1);
    });

    test('is null when the backend omits it', () {
      expect(User.fromJson({'co_id': 184}).online, isNull);
    });

    test('copyWith keeps it', () {
      final u = User.fromJson({'co_id': 139, 'co_online': 1});
      expect(u.copyWith(credit: 10).online, 1);
    });
  });
}
