import 'package:flutter/widgets.dart';

import 'lacoste_brand.dart';
import 'mirror_brand.dart';

export 'mirror_brand.dart';

/// Активный бренд киоска этой сборки. Следующий бренд — новый файл рядом с
/// `lacoste_brand.dart` и замена этой константы.
const MirrorBrand kMirrorBrand = lacosteBrand;

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

  static MirrorBrand of(BuildContext context) => maybeOf(context) ?? kMirrorBrand;

  static MirrorBrand? maybeOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<MirrorBrandScope>()
      ?.brand;

  @override
  bool updateShouldNotify(MirrorBrandScope oldWidget) =>
      oldWidget.brand.id != brand.id;
}
