import 'package:flutter/widgets.dart';

import 'lacoste_brand.dart';
import 'libas_brand.dart';
import 'mirror_brand.dart';

export 'mirror_brand.dart';

/// Оформления, между которыми продавец выбирает на старте киоска (экран
/// выбора и шит настройки). Новый бренд — новый файл рядом с
/// `lacoste_brand.dart` и строка в этом списке.
const List<MirrorBrand> kMirrorBrands = [libasBrand, lacosteBrand];

/// Оформление по умолчанию: пока продавец ничего не выбрал, и для оверлеев,
/// которые не видят [MirrorBrandScope].
const MirrorBrand kMirrorBrand = libasBrand;

/// Бренд по сохранённому id; неизвестный id — [kMirrorBrand].
MirrorBrand mirrorBrandById(String? id) =>
    kMirrorBrands.firstWhere((b) => b.id == id, orElse: () => kMirrorBrand);

/// Бренд для поддерева киоска.
///
/// [of] откатывается на [kMirrorBrand], когда scope не найден: шиты и
/// системные диалоги строятся в оверлее корневого Navigator'а, выше
/// MirrorTab, и этот InheritedWidget им не виден.
class MirrorBrandScope extends InheritedWidget {
  const MirrorBrandScope({
    super.key,
    required this.brand,
    required super.child,
  });

  final MirrorBrand brand;

  static MirrorBrand of(BuildContext context) =>
      maybeOf(context) ?? kMirrorBrand;

  static MirrorBrand? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<MirrorBrandScope>()?.brand;

  @override
  bool updateShouldNotify(MirrorBrandScope oldWidget) =>
      oldWidget.brand.id != brand.id;
}
