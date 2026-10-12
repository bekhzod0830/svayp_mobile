import 'package:flutter_test/flutter_test.dart';
import 'package:swipe/features/mirror/data/kiosk_taxonomy.dart';

/// Подсказка размера из образа против ряда размеров модели из каталога:
/// что выделяет карточка вещи.
void main() {
  const numeric = ['34', '36', '38', '40', '42'];
  const letters = ['XS', 'S', 'M', 'L', 'XL'];
  const eu = ['EU_39', 'EU_40', 'EU_41', 'EU_42'];

  test('диапазон выделяет и всё между краями', () {
    expect(kioskRecommendedSizes('36–40', numeric), {1, 2, 3});
    expect(kioskRecommendedSizes('S–M', letters), {1, 2});
    expect(kioskRecommendedSizes('EU_40–EU_41', eu), {1, 2});
  });

  test('любое тире и пробелы вокруг', () {
    expect(kioskRecommendedSizes('36-40', numeric), {1, 2, 3});
    expect(kioskRecommendedSizes('36 — 40', numeric), {1, 2, 3});
  });

  test('один размер', () {
    expect(kioskRecommendedSizes('M', letters), {2});
    expect(kioskRecommendedSizes('42', numeric), {4});
  });

  test('«—» и пусто — размеров нет, ничего не выделяем', () {
    expect(kioskHasSize('—'), isFalse);
    expect(kioskHasSize(''), isFalse);
    expect(kioskHasSize(null), isFalse);
    expect(kioskHasSize('M'), isTrue);
    expect(kioskRecommendedSizes('—', letters), isEmpty);
    expect(kioskRecommendedSizes('M', const []), isEmpty);
  });

  test('край не нашёлся в ряду — выделяем совпавшее', () {
    expect(kioskRecommendedSizes('M–XXL', letters), {2});
    expect(kioskRecommendedSizes('XXL', letters), isEmpty);
  });
}
