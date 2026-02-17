/// Product-related enums matching backend API
/// These enums correspond to the Python enums in app/schemas/schemas.py

// ==================== Size Enum ====================

enum SizeEnum {
  // Standard sizes
  xxs('xxs'),
  xs('xs'),
  s('s'),
  m('m'),
  l('l'),
  xl('xl'),
  xxl('xxl'),
  xxxl('xxxl'),

  // Numeric sizes for pants/jeans
  size24('24'),
  size25('25'),
  size26('26'),
  size27('27'),
  size28('28'),
  size29('29'),
  size30('30'),
  size31('31'),
  size32('32'),
  size34('34'),
  size36('36'),
  size38('38'),
  size40('40'),
  size42('42'),
  size44('44'),
  size46('46'),
  size48('48'),

  // Children sizes
  size2t('2t'),
  size3t('3t'),
  size4t('4t'),
  size5t('5t'),
  size6('6'),
  size7('7'),
  size8('8'),
  size10('10'),
  size12('12'),
  size14('14'),
  size16('16'),

  // Universal
  oneSize('one_size'),
  freeSize('free_size');

  final String value;
  const SizeEnum(this.value);

  /// Get display name for UI
  String get displayName {
    switch (this) {
      case SizeEnum.xxs:
        return 'XXS';
      case SizeEnum.xs:
        return 'XS';
      case SizeEnum.s:
        return 'S';
      case SizeEnum.m:
        return 'M';
      case SizeEnum.l:
        return 'L';
      case SizeEnum.xl:
        return 'XL';
      case SizeEnum.xxl:
        return 'XXL';
      case SizeEnum.xxxl:
        return 'XXXL';
      case SizeEnum.oneSize:
        return 'One Size';
      case SizeEnum.freeSize:
        return 'Free Size';
      case SizeEnum.size2t:
        return '2T';
      case SizeEnum.size3t:
        return '3T';
      case SizeEnum.size4t:
        return '4T';
      case SizeEnum.size5t:
        return '5T';
      default:
        return value.toUpperCase();
    }
  }

  static SizeEnum? fromString(String? value) {
    if (value == null) return null;
    try {
      return SizeEnum.values.firstWhere((e) => e.value == value.toLowerCase());
    } catch (_) {
      return null;
    }
  }
}

// ==================== Color Enum ====================

enum ColorEnum {
  // Basic colors
  black('black'),
  white('white'),
  gray('gray'),
  grey('grey'),

  // Blues
  navy('navy'),
  blue('blue'),
  lightBlue('light_blue'),
  darkBlue('dark_blue'),
  royalBlue('royal_blue'),
  skyBlue('sky_blue'),
  turquoise('turquoise'),
  teal('teal'),

  // Reds & Pinks
  red('red'),
  burgundy('burgundy'),
  maroon('maroon'),
  pink('pink'),
  lightPink('light_pink'),
  hotPink('hot_pink'),
  rose('rose'),

  // Greens
  green('green'),
  olive('olive'),
  darkGreen('dark_green'),
  lightGreen('light_green'),
  mint('mint'),
  emerald('emerald'),

  // Browns & Neutrals
  brown('brown'),
  tan('tan'),
  beige('beige'),
  cream('cream'),
  khaki('khaki'),
  camel('camel'),

  // Purples
  purple('purple'),
  lavender('lavender'),
  violet('violet'),
  lilac('lilac'),

  // Yellows & Oranges
  yellow('yellow'),
  mustard('mustard'),
  gold('gold'),
  orange('orange'),
  peach('peach'),
  coral('coral'),

  // Others
  multiColor('multi_color'),
  floral('floral'),
  printed('printed');

  final String value;
  const ColorEnum(this.value);

  String get displayName {
    return value
        .split('_')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  static ColorEnum? fromString(String? value) {
    if (value == null) return null;
    try {
      return ColorEnum.values.firstWhere((e) => e.value == value.toLowerCase());
    } catch (_) {
      return null;
    }
  }
}

// ==================== Material Enum ====================

enum MaterialEnum {
  cotton('cotton'),
  polyester('polyester'),
  silk('silk'),
  linen('linen'),
  wool('wool'),
  chiffon('chiffon'),
  satin('satin'),
  velvet('velvet'),
  denim('denim'),
  leather('leather'),
  suede('suede'),
  jersey('jersey'),
  modal('modal'),
  rayon('rayon'),
  spandex('spandex'),
  lycra('lycra'),
  nylon('nylon'),
  viscose('viscose'),
  bamboo('bamboo'),
  cashmere('cashmere'),
  mixed('mixed');

  final String value;
  const MaterialEnum(this.value);

  String get displayName {
    return value[0].toUpperCase() + value.substring(1);
  }

  static MaterialEnum? fromString(String? value) {
    if (value == null) return null;
    try {
      return MaterialEnum.values.firstWhere(
        (e) => e.value == value.toLowerCase(),
      );
    } catch (_) {
      return null;
    }
  }
}

// ==================== Season Enum ====================

enum SeasonEnum {
  spring('spring'),
  summer('summer'),
  fall('fall'),
  autumn('autumn'),
  winter('winter'),
  allSeason('all_season');

  final String value;
  const SeasonEnum(this.value);

  String get displayName {
    return value == 'all_season'
        ? 'All Season'
        : value[0].toUpperCase() + value.substring(1);
  }

  static SeasonEnum? fromString(String? value) {
    if (value == null) return null;
    try {
      return SeasonEnum.values.firstWhere(
        (e) => e.value == value.toLowerCase(),
      );
    } catch (_) {
      return null;
    }
  }
}

// ==================== Fit Type Enum ====================

enum FitTypeEnum {
  loose('loose'),
  regular('regular'),
  slim('slim'),
  oversized('oversized'),
  fitted('fitted'),
  relaxed('relaxed'),
  tailored('tailored');

  final String value;
  const FitTypeEnum(this.value);

  String get displayName {
    return value[0].toUpperCase() + value.substring(1);
  }

  static FitTypeEnum? fromString(String? value) {
    if (value == null) return null;
    try {
      return FitTypeEnum.values.firstWhere(
        (e) => e.value == value.toLowerCase(),
      );
    } catch (_) {
      return null;
    }
  }
}

// ==================== Length Enum ====================

enum LengthEnum {
  maxi('maxi'),
  midi('midi'),
  kneeLength('knee_length'),
  aboveKnee('above_knee'),
  ankle('ankle'),
  floorLength('floor_length'),
  mini('mini'),
  teaLength('tea_length');

  final String value;
  const LengthEnum(this.value);

  String get displayName {
    return value
        .split('_')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  static LengthEnum? fromString(String? value) {
    if (value == null) return null;
    try {
      return LengthEnum.values.firstWhere(
        (e) => e.value == value.toLowerCase(),
      );
    } catch (_) {
      return null;
    }
  }
}

// ==================== Sleeve Length Enum ====================

enum SleeveLengthEnum {
  full('full'),
  long('long'),
  threeQuarter('three_quarter'),
  half('half'),
  short('short'),
  sleeveless('sleeveless'),
  cap('cap');

  final String value;
  const SleeveLengthEnum(this.value);

  String get displayName {
    return value == 'three_quarter'
        ? '3/4 Sleeve'
        : value[0].toUpperCase() + value.substring(1);
  }

  static SleeveLengthEnum? fromString(String? value) {
    if (value == null) return null;
    try {
      return SleeveLengthEnum.values.firstWhere(
        (e) => e.value == value.toLowerCase(),
      );
    } catch (_) {
      return null;
    }
  }
}

// ==================== Coverage Level Enum ====================

enum CoverageLevelEnum {
  full('full'),
  modest('modest'),
  moderate('moderate'),
  standard('standard');

  final String value;
  const CoverageLevelEnum(this.value);

  String get displayName {
    return value[0].toUpperCase() + value.substring(1);
  }

  static CoverageLevelEnum? fromString(String? value) {
    if (value == null) return null;
    try {
      return CoverageLevelEnum.values.firstWhere(
        (e) => e.value == value.toLowerCase(),
      );
    } catch (_) {
      return null;
    }
  }
}

// ==================== Gender Target Enum ====================

enum GenderTargetEnum {
  male('male'),
  female('female'),
  unisex('unisex'),
  kids('kids'),
  boys('boys'),
  girls('girls');

  final String value;
  const GenderTargetEnum(this.value);

  String get displayName {
    return value[0].toUpperCase() + value.substring(1);
  }

  static GenderTargetEnum? fromString(String? value) {
    if (value == null) return null;
    try {
      return GenderTargetEnum.values.firstWhere(
        (e) => e.value == value.toLowerCase(),
      );
    } catch (_) {
      return null;
    }
  }
}

// ==================== Age Group Enum ====================

enum AgeGroupEnum {
  adult('adult'),
  teen('teen'),
  kids('kids'),
  toddler('toddler'),
  infant('infant');

  final String value;
  const AgeGroupEnum(this.value);

  String get displayName {
    return value[0].toUpperCase() + value.substring(1);
  }

  static AgeGroupEnum? fromString(String? value) {
    if (value == null) return null;
    try {
      return AgeGroupEnum.values.firstWhere(
        (e) => e.value == value.toLowerCase(),
      );
    } catch (_) {
      return null;
    }
  }
}

// ==================== Style Tag Enum ====================

enum StyleTagEnum {
  casual('casual'),
  formal('formal'),
  business('business'),
  sporty('sporty'),
  elegant('elegant'),
  bohemian('bohemian'),
  vintage('vintage'),
  modern('modern'),
  minimalist('minimalist'),
  classic('classic'),
  trendy('trendy'),
  modest('modest'),
  streetwear('streetwear'),
  romantic('romantic'),
  edgy('edgy'),
  preppy('preppy'),
  athleisure('athleisure'),
  chic('chic'),
  glamorous('glamorous');

  final String value;
  const StyleTagEnum(this.value);

  String get displayName {
    return value[0].toUpperCase() + value.substring(1);
  }

  static StyleTagEnum? fromString(String? value) {
    if (value == null) return null;
    try {
      return StyleTagEnum.values.firstWhere(
        (e) => e.value == value.toLowerCase(),
      );
    } catch (_) {
      return null;
    }
  }
}

// ==================== Occasion Enum ====================

enum OccasionEnum {
  daily('daily'),
  work('work'),
  wedding('wedding'),
  eid('eid'),
  ramadan('ramadan'),
  casual('casual'),
  formal('formal'),
  party('party'),
  evening('evening'),
  brunch('brunch'),
  dateNight('date_night'),
  beach('beach'),
  travel('travel'),
  prayer('prayer'),
  sports('sports'),
  gym('gym'),
  outdoor('outdoor'),
  religious('religious'),
  specialOccasion('special_occasion');

  final String value;
  const OccasionEnum(this.value);

  String get displayName {
    return value
        .split('_')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  static OccasionEnum? fromString(String? value) {
    if (value == null) return null;
    try {
      return OccasionEnum.values.firstWhere(
        (e) => e.value == value.toLowerCase(),
      );
    } catch (_) {
      return null;
    }
  }
}

// ==================== Pattern Enum ====================

enum PatternEnum {
  solid('solid'),
  striped('striped'),
  floral('floral'),
  polkaDot('polka_dot'),
  checkered('checkered'),
  plaid('plaid'),
  animalPrint('animal_print'),
  geometric('geometric'),
  abstract('abstract'),
  paisley('paisley'),
  embroidered('embroidered'),
  lace('lace'),
  tieDye('tie_dye'),
  camouflage('camouflage'),
  herringbone('herringbone');

  final String value;
  const PatternEnum(this.value);

  String get displayName {
    return value
        .split('_')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  static PatternEnum? fromString(String? value) {
    if (value == null) return null;
    try {
      return PatternEnum.values.firstWhere(
        (e) => e.value == value.toLowerCase(),
      );
    } catch (_) {
      return null;
    }
  }
}

// ==================== Clothing Item Enum ====================

enum ClothingItemEnum {
  dress('dress'),
  hijab('hijab'),
  abaya('abaya'),
  tunic('tunic'),
  blouse('blouse'),
  shirt('shirt'),
  tShirt('t_shirt'),
  top('top'),
  pants('pants'),
  jeans('jeans'),
  skirt('skirt'),
  cardigan('cardigan'),
  jacket('jacket'),
  coat('coat'),
  sweater('sweater'),
  jumpsuit('jumpsuit'),
  shorts('shorts'),
  leggings('leggings'),
  scarf('scarf'),
  shawl('shawl'),
  vest('vest'),
  kimono('kimono');

  final String value;
  const ClothingItemEnum(this.value);

  String get displayName {
    return value
        .split('_')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  static ClothingItemEnum? fromString(String? value) {
    if (value == null) return null;
    try {
      return ClothingItemEnum.values.firstWhere(
        (e) => e.value == value.toLowerCase(),
      );
    } catch (_) {
      return null;
    }
  }
}

// ==================== Style Category Enum ====================

enum StyleCategoryEnum {
  casual('casual'),
  formal('formal'),
  business('business'),
  sporty('sporty'),
  elegant('elegant'),
  bohemian('bohemian'),
  vintage('vintage'),
  modern('modern'),
  minimalist('minimalist'),
  classic('classic'),
  trendy('trendy'),
  modest('modest'),
  streetwear('streetwear'),
  romantic('romantic'),
  edgy('edgy'),
  preppy('preppy'),
  athleisure('athleisure');

  final String value;
  const StyleCategoryEnum(this.value);

  String get displayName {
    return value[0].toUpperCase() + value.substring(1);
  }

  static StyleCategoryEnum? fromString(String? value) {
    if (value == null) return null;
    try {
      return StyleCategoryEnum.values.firstWhere(
        (e) => e.value == value.toLowerCase(),
      );
    } catch (_) {
      return null;
    }
  }
}

// ==================== Category Enum ====================

enum CategoryEnum {
  dress('dress'),
  hijab('hijab'),
  abaya('abaya'),
  tunic('tunic'),
  top('top'),
  blouse('blouse'),
  shirt('shirt'),
  pants('pants'),
  jeans('jeans'),
  skirt('skirt'),
  jacket('jacket'),
  coat('coat'),
  cardigan('cardigan'),
  sweater('sweater'),
  activewear('activewear'),
  jumpsuit('jumpsuit'),
  scarf('scarf'),
  shawl('shawl'),
  accessories('accessories'),
  shoes('shoes'),
  bags('bags'),
  jewelry('jewelry'),
  underwear('underwear'),
  outerwear('outerwear');

  final String value;
  const CategoryEnum(this.value);

  String get displayName {
    return value[0].toUpperCase() + value.substring(1);
  }

  static CategoryEnum? fromString(String? value) {
    if (value == null) return null;
    try {
      return CategoryEnum.values.firstWhere(
        (e) => e.value == value.toLowerCase(),
      );
    } catch (_) {
      return null;
    }
  }
}

// ==================== Subcategory Enum ====================

enum SubcategoryEnum {
  // Dress subcategories
  maxiDress('maxi_dress'),
  midiDress('midi_dress'),
  miniDress('mini_dress'),
  casualDress('casual_dress'),
  formalDress('formal_dress'),
  eveningDress('evening_dress'),
  shirtDress('shirt_dress'),
  wrapDress('wrap_dress'),
  aLineDress('a_line_dress'),

  // Hijab subcategories
  squareHijab('square_hijab'),
  rectangleHijab('rectangle_hijab'),
  instantHijab('instant_hijab'),
  turban('turban'),
  underscarf('underscarf'),
  prayerHijab('prayer_hijab'),

  // Abaya subcategories
  openAbaya('open_abaya'),
  closedAbaya('closed_abaya'),
  kimonoAbaya('kimono_abaya'),
  butterflyAbaya('butterfly_abaya'),
  umbrellaAbaya('umbrella_abaya'),

  // Top subcategories
  tShirt('t_shirt'),
  tankTop('tank_top'),
  cropTop('crop_top'),
  peplumTop('peplum_top'),
  tunicTop('tunic_top'),

  // Pants subcategories
  straightPants('straight_pants'),
  wideLegPants('wide_leg_pants'),
  palazzoPants('palazzo_pants'),
  cigarettePants('cigarette_pants'),
  cargoPants('cargo_pants'),

  // Jeans subcategories
  skinnyJeans('skinny_jeans'),
  straightJeans('straight_jeans'),
  bootcutJeans('bootcut_jeans'),
  momJeans('mom_jeans'),
  boyfriendJeans('boyfriend_jeans'),
  wideLegJeans('wide_leg_jeans'),

  // Skirt subcategories
  pencilSkirt('pencil_skirt'),
  aLineSkirt('a_line_skirt'),
  pleatedSkirt('pleated_skirt'),
  maxiSkirt('maxi_skirt'),
  midiSkirt('midi_skirt'),
  miniSkirt('mini_skirt'),

  // Jacket subcategories
  denimJacket('denim_jacket'),
  leatherJacket('leather_jacket'),
  bomberJacket('bomber_jacket'),
  blazer('blazer'),
  trenchCoat('trench_coat'),

  // Activewear subcategories
  sportsBra('sports_bra'),
  leggings('leggings'),
  sportsTop('sports_top'),
  sportsSet('sports_set'),
  tracksuit('tracksuit'),

  // Accessories
  belt('belt'),
  hat('hat'),
  cap('cap'),
  gloves('gloves'),
  socks('socks'),

  // Generic
  other('other');

  final String value;
  const SubcategoryEnum(this.value);

  String get displayName {
    // Convert snake_case to Title Case
    return value
        .split('_')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  static SubcategoryEnum? fromString(String? value) {
    if (value == null) return null;
    try {
      return SubcategoryEnum.values.firstWhere(
        (e) => e.value == value.toLowerCase(),
      );
    } catch (_) {
      return null;
    }
  }
}
