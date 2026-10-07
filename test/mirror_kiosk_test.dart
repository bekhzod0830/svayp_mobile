import 'dart:io';

import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:swipe/features/mirror/brand/lacoste_brand.dart';
import 'package:swipe/features/mirror/brand/mirror_brand.dart';
import 'package:swipe/features/mirror/data/kiosk_api.dart';
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
  TestWidgetsFlutterBinding.ensureInitialized();

  group('kioskStylesFor — станция LIBAS, по 8 на пол', () {
    test('мужские стили — в порядке карточек, без «Модест» и «Вечерний»', () {
      expect(kioskStylesFor('MALE').map((s) => s.code), [
        'CLASSIC', 'CASUAL', 'BUSINESS', 'SPORT_CHIC', //
        'SMART_CASUAL', 'STREETWEAR', 'MINIMAL', 'PREPPY',
      ]);
    });

    test('женские стили; без пола — женский набор', () {
      expect(kioskStylesFor('FEMALE').map((s) => s.code), [
        'CLASSIC', 'CASUAL', 'MODEST', 'EVENING', //
        'BUSINESS', 'SPORT_CHIC', 'MINIMAL', 'ROMANTIC',
      ]);
      expect(kioskStylesFor(null), hasLength(8));
    });

    test('у каждого стиля, фигуры и гардероба есть картинка и подпись', () {
      for (final g in ['MALE', 'FEMALE']) {
        expect(File(kioskGenderPhoto(g)).existsSync(), isTrue, reason: g);
        for (final st in kioskStylesFor(g)) {
          expect(File(kioskStylePhoto(g, st.code)!).existsSync(), isTrue, reason: '$g ${st.code}');
          expect(kioskStyleDescriptions[st.code], isNotNull, reason: st.code);
        }
        expect(kioskShapes[g], hasLength(4));
        for (final sh in kioskShapes[g]!) {
          expect(File(kioskShapeFigure(g, sh.code)!).existsSync(), isTrue, reason: '$g ${sh.code}');
          expect(kioskShapeDescriptions[sh.code], isNotNull, reason: sh.code);
        }
      }
    });

    test('12 брендов и 12 цветов — коды совпадают с бэкендом', () {
      expect(kioskShopBrands.map((b) => b.code), [
        'BOGGI_MILANO', 'COLINS', 'JACK_JONES', 'DIGEL', 'MARC_O_POLO', 'MEXX',
        'MOTIVI', 'ONLY', 'NAME_IT', 'SELECTED', 'VERO_MODA', 'YAS',
      ]);
      expect(kioskColors.map((c) => c.code), [
        'red', 'pink', 'khaki', 'yellow', 'green', 'blue',
        'navy', 'purple', 'brown', 'grey', 'white', 'black',
      ]);
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
      final codes = lacosteBrand.stylesFor('FEMALE').map((s) => s.code).toList();
      expect(codes, isNot(contains('MODEST')));
      expect(codes, isNot(contains('EVENING')));
      expect(codes, isNot(contains('ROMANTIC')));
      expect(codes, containsAll(['CLASSIC', 'CASUAL', 'BUSINESS', 'SPORT_CHIC']));
    });

    test('подписи: бренд → язык по умолчанию → справочник', () {
      final sporty = kioskStyles.firstWhere((s) => s.code == 'SPORT_CHIC');
      expect(lacosteBrand.styleLabel(sporty, 'ru'), 'Спорт · Теннис');
      expect(lacosteBrand.styleLabel(sporty, 'uz'), 'Sport · Tennis');
      expect(lacosteBrand.styleLabel(sporty, 'en'), 'Sport · Tennis');
      // Языка нет в переименованиях бренда — подпись справочника на этом же языке
      // (не русское переименование на чужом экране).
      expect(lacosteBrand.styleLabel(sporty, 'kk'), sporty.label('kk'));
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

    test('языки бренда', () {
      expect(lacosteBrand.languages, ['ru', 'uz', 'en']);
    });

    test('текст на зелёном читается: контраст onPrimary/primary ≥ 4.5', () {
      final p = lacosteBrand.palette;
      final l1 = p.onPrimary.computeLuminance();
      final l2 = p.primary.computeLuminance();
      final ratio = (math.max(l1, l2) + 0.05) / (math.min(l1, l2) + 0.05);
      expect(ratio, greaterThanOrEqualTo(4.5));
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

    test('подсаженный каталог виден на витрине', () {
      c.seedCatalogForTest(_catalog);
      expect(c.catalogPreview.length, _catalog.length);
    });
  });
}
