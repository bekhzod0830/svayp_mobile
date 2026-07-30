import 'package:flutter_test/flutter_test.dart';
import 'package:swipe/features/mirror/data/kiosk_models.dart';
import 'package:swipe/features/mirror/data/kiosk_taxonomy.dart';

void main() {
  group('kioskMoney', () {
    test('groups digits by three with spaces, ценник style', () {
      expect(kioskMoney(1250000, 'ru'), '1 250 000 сум');
      expect(kioskMoney(999, 'ru'), '999 сум');
      expect(kioskMoney(120000, 'uz'), '120 000 soʻm');
      expect(kioskMoney(0, 'ru'), '0 сум');
    });
  });

  group('KioskLook.fromJson', () {
    test('parses full payload', () {
      final look = KioskLook.fromJson({
        'lookId': 'l1',
        'status': 'COMPLETED',
        'resultImageUrl': 'https://x/y.jpg',
        'items': [
          {
            'productId': 'p1',
            'title': 'Dress',
            'size': 'M–L',
            'price': 120000,
            'currency': 'UZS',
          }
        ],
        'totalPrice': 120000,
        'regenerateCount': 1,
        'canRegenerate': true,
      });
      expect(look.status, KioskLookStatus.completed);
      expect(look.isTerminal, isTrue);
      expect(look.items.single.size, 'M–L');
      expect(look.localResultPath, isNull);
    });

    test('local demo result path round-trips through file:// marker', () {
      final look = KioskLook.fromJson({
        'lookId': 'l2',
        'status': 'COMPLETED',
        'resultImageUrl': 'file:///tmp/face.jpg',
      });
      expect(look.localResultPath, '/tmp/face.jpg');
    });

    test('unknown status maps to unknown, defaults are safe', () {
      final look = KioskLook.fromJson(const {'lookId': 'l3', 'status': 'WAT'});
      expect(look.status, KioskLookStatus.unknown);
      expect(look.isTerminal, isFalse);
      expect(look.items, isEmpty);
      expect(look.canRegenerate, isTrue);
    });
  });

  group('taxonomy', () {
    test('shape lists depend on gender and labels resolve per language', () {
      expect(kioskShapes['FEMALE']!.map((s) => s.code), contains('HOURGLASS'));
      expect(kioskShapes['MALE']!.map((s) => s.code), isNot(contains('PEAR')));
      expect(kioskStyles.first.label('uz'), 'Klassika');
      expect(kioskCategories.first.code, isNull);
    });
  });
}
