import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:swipe/features/mirror/brand/lacoste_brand.dart';
import 'package:swipe/features/mirror/brand/mirror_brand.dart';
import 'package:swipe/features/mirror/data/kiosk_api.dart';
import 'package:swipe/features/mirror/data/kiosk_cover_looks.dart';
import 'package:swipe/features/mirror/data/kiosk_demo.dart';
import 'package:swipe/features/mirror/data/kiosk_models.dart';
import 'package:swipe/features/mirror/data/kiosk_taxonomy.dart';
import 'package:swipe/features/mirror/presentation/mirror_session_controller.dart';

KioskCatalogItem _item(
  String id,
  String category, {
  bool withImage = true,
  int price = 1000,
}) =>
    KioskCatalogItem(
      id: id,
      title: id,
      category: category,
      price: price,
      currency: 'UZS',
      imageUrl: withImage ? 'https://img.test/$id.jpg' : null,
    );

/// Каталог: 2 верха с фото (+1 без), 2 низа, 2 цельных, 2 пары обуви,
/// аксессуар — из него собираются ровно 4 образа (2 пары + 2 цельных).
final _catalog = <KioskCatalogItem>[
  _item('t1', 'TOPWEAR'),
  _item('t2', 'TOPWEAR'),
  _item('t3', 'TOPWEAR', withImage: false),
  _item('b1', 'BOTTOMWEAR'),
  _item('b2', 'BOTTOMWEAR'),
  _item('d1', 'DRESSES'),
  _item('d2', 'TWO_PIECE_SET'),
  _item('s1', 'FOOTWEAR'),
  _item('s2', 'FOOTWEAR'),
  _item('a1', 'ACCESSORIES'),
];

void main() {
  group('kioskStylesFor', () {
    test('мужчине не показываем «Модест» и «Вечерний»', () {
      final codes = kioskStylesFor('MALE').map((s) => s.code).toList();
      expect(codes, isNot(contains('MODEST_CHIC')));
      expect(codes, isNot(contains('EVENING')));
      expect(codes, containsAll(['CLASSIC', 'CASUAL', 'OFFICE_SMART', 'SPORTY']));
    });

    test('женщине и без пола — все шесть', () {
      expect(kioskStylesFor('FEMALE'), hasLength(6));
      expect(kioskStylesFor(null), hasLength(6));
    });
  });

  group('KioskSession.menswearAvailable', () {
    test('бэкенд сказал «мужского нет» — кнопку прячем', () {
      final s = KioskSession.fromJson({'sessionId': 'x', 'menswearAvailable': false});
      expect(s.menswearAvailable, isFalse);
    });

    test('старый бэкенд без поля — ведём себя как раньше', () {
      expect(KioskSession.fromJson({'sessionId': 'x'}).menswearAvailable, isTrue);
    });
  });

  group('отказы бэкенда не уходят в демо', () {
    test('KIOSK_LOOK_UNAVAILABLE — это «нет образа», а не сбой пайплайна', () {
      // Бэкенд шлёт код с префиксом; раньше сравнивали без него, и отказ
      // уходил в демо, которое показывает снятое фото вместо образа.
      expect(MirrorSessionController.isLookUnavailable('KIOSK_LOOK_UNAVAILABLE'), isTrue);
      expect(MirrorSessionController.isBusinessRefusal('KIOSK_LOOK_UNAVAILABLE'), isTrue);
    });

    test('лимиты — тоже честный отказ', () {
      expect(MirrorSessionController.isBusinessRefusal('KIOSK_REGENERATE_LIMIT'), isTrue);
      expect(MirrorSessionController.isBusinessRefusal('KIOSK_RATE_LIMIT'), isTrue);
    });

    test('обычный сбой — не бизнес-отказ: человеку показываем «Повторить»', () {
      expect(MirrorSessionController.isBusinessRefusal('FAILED'), isFalse);
      expect(MirrorSessionController.isBusinessRefusal(null), isFalse);
    });
  });

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

    test('kioskSlotOf: категории → слоты как на бэкенде', () {
      expect(kioskSlotOf('TOPWEAR'), 'TOP');
      expect(kioskSlotOf('BOTTOMWEAR'), 'BOTTOM');
      expect(kioskSlotOf('DRESSES'), 'FULL');
      expect(kioskSlotOf('ONE_PIECE'), 'FULL');
      expect(kioskSlotOf('TWO_PIECE_SET'), 'FULL');
      expect(kioskSlotOf('FOOTWEAR'), 'SHOES');
      expect(kioskSlotOf('ACCESSORIES'), 'OTHER');
      expect(kioskSlotOf(null), 'OTHER');
    });
  });

  group('MirrorBrand · Lacoste', () {
    test('скрытые стили не показываются, остальные — из справочника', () {
      final codes = lacosteBrand.styles.map((s) => s.code).toList();
      expect(codes, isNot(contains('MODEST_CHIC')));
      expect(codes, isNot(contains('EVENING')));
      expect(codes, containsAll(['CLASSIC', 'CASUAL', 'OFFICE_SMART', 'SPORTY']));
    });

    test('подписи: бренд → язык по умолчанию → справочник', () {
      final sporty = kioskStyles.firstWhere((s) => s.code == 'SPORTY');
      expect(lacosteBrand.styleLabel(sporty, 'ru'), 'Спорт · Теннис');
      expect(lacosteBrand.styleLabel(sporty, 'uz'), 'Sport · Tennis');
      // Незнакомый язык — откат на язык бренда по умолчанию.
      expect(lacosteBrand.styleLabel(sporty, 'en'), 'Спорт · Теннис');
      // Не переименованная категория — подпись справочника.
      final dresses = kioskCategories.firstWhere((c) => c.code == 'DRESSES');
      expect(lacosteBrand.categoryLabel(dresses, 'uz'), dresses.label('uz'));
      // «Все» (code == null) переименовать нельзя.
      expect(lacosteBrand.categoryLabel(kioskCategories.first, 'ru'), 'Все');
    });

    test('бренд, скрывший все стили, всё равно показывает полный список', () {
      final everythingHidden = MirrorBrand(
        id: 'x',
        name: 'x',
        wordmark: 'X',
        palette: lacosteBrand.palette,
        type: lacosteBrand.type,
        shape: lacosteBrand.shape,
        hiddenStyles: kioskStyles.map((s) => s.code!).toSet(),
      );
      expect(everythingHidden.styles.length, kioskStyles.length);
    });

    test('фразы постера откатываются на язык по умолчанию', () {
      expect(lacosteBrand.phrasesFor('uz'), isNotEmpty);
      expect(lacosteBrand.phrasesFor('en'), lacosteBrand.phrasesFor('ru'));
      expect(lacosteBrand.languages, ['ru', 'uz']);
    });

    test('текст на зелёном читается: контраст onPrimary/primary ≥ 4.5', () {
      final p = lacosteBrand.palette;
      final l1 = p.onPrimary.computeLuminance();
      final l2 = p.primary.computeLuminance();
      final ratio = (math.max(l1, l2) + 0.05) / (math.min(l1, l2) + 0.05);
      expect(ratio, greaterThanOrEqualTo(4.5));
    });
  });

  group('composeCoverLooks', () {
    test('образ — цельная вещь или верх+низ; без повторов и вещей без фото', () {
      final looks = composeCoverLooks(_catalog, seed: 7);
      expect(looks.length, 4);
      final seen = <String>{};
      for (final look in looks) {
        final isFull = look.full != null;
        final isPair = look.top != null && look.bottom != null;
        expect(isFull ^ isPair, isTrue, reason: 'либо цельная, либо пара');
        for (final item in look.items) {
          expect(item.imageUrl, isNotNull);
          expect(seen.add(item.id), isTrue, reason: '${item.id} повторяется');
        }
        expect(look.items.map((i) => i.id), isNot(contains('a1')));
        expect(look.totalPrice, look.items.length * 1000);
      }
    });

    test('порядок детерминирован зерном', () {
      List<String> ids(int seed) => composeCoverLooks(_catalog, seed: seed)
          .map((l) => l.items.map((i) => i.id).join(','))
          .toList();
      expect(ids(3), ids(3));
    });

    test('count ограничивает; пустой каталог и одна обувь — пусто', () {
      expect(composeCoverLooks(_catalog, count: 1).length, 1);
      expect(composeCoverLooks(const []), isEmpty);
      expect(composeCoverLooks([_item('s1', 'FOOTWEAR')]), isEmpty);
    });
  });

  group('MirrorSessionController', () {
    late MirrorSessionController c;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final api = KioskApi(prefs);
      c = MirrorSessionController(
        api: api,
        demo: KioskDemoService(api, prefs),
        prefs: prefs,
        analytics: (_, __) {},
      );
    });

    tearDown(() => c.dispose());

    test('stepIndex: ветка «создать» начинается с камеры, интро нет', () {
      c.path = MirrorPath.create;
      const expected = {
        MirrorScreen.idle: 0,
        MirrorScreen.camera: 0,
        MirrorScreen.catalog: 0,
        MirrorScreen.gender: 1,
        MirrorScreen.shape: 1,
        MirrorScreen.style: 2,
        MirrorScreen.generating: 3,
        MirrorScreen.result: 3,
        MirrorScreen.buy: 3,
      };
      for (final e in expected.entries) {
        c.screen = e.key;
        expect(c.stepIndex, e.value, reason: e.key.name);
      }
    });

    test('stepIndex: ветка «каталог»', () {
      c.path = MirrorPath.catalog;
      const expected = {
        MirrorScreen.idle: 0,
        MirrorScreen.catalog: 0,
        MirrorScreen.camera: 1,
        MirrorScreen.gender: 2,
        MirrorScreen.shape: 2,
        MirrorScreen.style: 2,
        MirrorScreen.generating: 3,
        MirrorScreen.result: 3,
        MirrorScreen.buy: 3,
      };
      for (final e in expected.entries) {
        c.screen = e.key;
        expect(c.stepIndex, e.value, reason: e.key.name);
      }
    });

    test('назад с камеры: «создать» — на постер, «каталог» — в каталог', () async {
      c.path = MirrorPath.catalog;
      c.screen = MirrorScreen.camera;
      c.goBack();
      expect(c.screen, MirrorScreen.catalog);

      c.path = MirrorPath.create;
      c.screen = MirrorScreen.camera;
      c.goBack();
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(c.screen, MirrorScreen.idle);
    });

    test('язык покупателя — из бренда, сброс возвращает его', () async {
      expect(c.shopperLang, lacosteBrand.defaultLang);
      c.setShopperLang('uz');
      expect(c.shopperLang, 'uz');
      await c.hardReset('manual');
      expect(c.shopperLang, lacosteBrand.defaultLang);
    });

    test('подсаженный каталог даёт образы для постера', () {
      expect(c.coverLooks, isEmpty);
      c.seedCatalogForTest(_catalog);
      expect(c.coverLooks, isNotEmpty);
      expect(c.catalogPreview.length, _catalog.length);
    });
  });
}
