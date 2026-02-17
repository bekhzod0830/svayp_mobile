/// User-related enums matching backend API

/// Gender enum
enum Gender {
  female('FEMALE');

  final String value;
  const Gender(this.value);
}

/// Body Type enum
enum BodyType {
  hourglass('HOURGLASS'),
  triangle('TRIANGLE'),
  rectangle('RECTANGLE'),
  oval('OVAL'),
  heart('HEART'),
  preferNotToSay('PREFER_NOT_TO_SAY');

  final String value;
  const BodyType(this.value);
}

/// Hijab Preference enum
enum HijabPreference {
  covered('COVERED'),
  uncovered('UNCOVERED'),
  notApplicable('NOT_APPLICABLE');

  final String value;
  const HijabPreference(this.value);
}

/// Fit Type enum
enum FitType {
  loose('LOOSE'),
  regular('REGULAR'),
  oversized('OVERSIZED'),
  slim('SLIM'),
  superSlim('SUPER_SLIM'),
  fitted('FITTED');

  final String value;
  const FitType(this.value);
}

/// Style Preference enum
enum StylePreference {
  covered('COVERED'),
  moderate('MODERATE'),
  revealing('REVEALING');

  final String value;
  const StylePreference(this.value);
}

/// Primary Objective enum
enum PrimaryObjective {
  haveOwnStyle('HAVE_OWN_STYLE'),
  findMyBestFit('FIND_MY_BEST_FIT'),
  aFunSurprise('A_FUN_SURPRISE'),
  uniquePieces('UNIQUE_PIECES'),
  updateMyLook('UPDATE_MY_LOOK'),
  saveTimeShopping('SAVE_TIME_SHOPPING'),
  tryNewTrends('TRY_NEW_TRENDS'),
  browseAPersonalizedShop('BROWSE_A_PERSONALIZED_SHOP');

  final String value;
  const PrimaryObjective(this.value);
}

/// Budget Type enum
enum BudgetType {
  budget('BUDGET'),
  moderate('MODERATE'),
  premium('PREMIUM'),
  luxury('LUXURY'),
  flexible('FLEXIBLE');

  final String value;
  const BudgetType(this.value);
}

/// Clothing Size enum
enum ClothingSize {
  xxs('XXS'),
  xs('XS'),
  s('S'),
  m('M'),
  l('L'),
  xl('XL'),
  xxl('XXL'),
  xxxl('XXXL');

  final String value;
  const ClothingSize(this.value);
}

/// Shoe Size enum
enum ShoeSize {
  eu34('EU_34'),
  eu35('EU_35'),
  eu36('EU_36'),
  eu37('EU_37'),
  eu38('EU_38'),
  eu39('EU_39'),
  eu40('EU_40'),
  eu41('EU_41'),
  eu42('EU_42'),
  eu43('EU_43'),
  eu44('EU_44'),
  eu45('EU_45');

  final String value;
  const ShoeSize(this.value);
}

/// Pants Size enum (for bottomSize and jeanWaistSize)
enum PantsSize {
  size24('SIZE_24'),
  size25('SIZE_25'),
  size26('SIZE_26'),
  size27('SIZE_27'),
  size28('SIZE_28'),
  size29('SIZE_29'),
  size30('SIZE_30'),
  size32('SIZE_32'),
  size34('SIZE_34'),
  size36('SIZE_36'),
  size38('SIZE_38'),
  size40('SIZE_40'),
  size42('SIZE_42'),
  size44('SIZE_44'),
  size46('SIZE_46'),
  size48('SIZE_48');

  final String value;
  const PantsSize(this.value);
}

/// Bra Band Size EU enum
enum BraBandSizeEU {
  eu60('EU_60'),
  eu65('EU_65'),
  eu70('EU_70'),
  eu75('EU_75'),
  eu80('EU_80'),
  eu85('EU_85'),
  eu90('EU_90'),
  eu95('EU_95'),
  eu100('EU_100'),
  eu105('EU_105'),
  eu110('EU_110'),
  eu115('EU_115'),
  eu120('EU_120');

  final String value;
  const BraBandSizeEU(this.value);
}

/// Bra Type enum
enum BraType {
  training('TRAINING'),
  tShirt('T_SHIRT'),
  sports('SPORTS'),
  pushUp('PUSH_UP'),
  balconette('BALCONETTE'),
  strapless('STRAPLESS'),
  wireless('WIRELESS'),
  underwire('UNDERWIRE'),
  bralette('BRALETTE'),
  minimizer('MINIMIZER'),
  fullCoverage('FULL_COVERAGE');

  final String value;
  const BraType(this.value);
}

/// Bra Cup Size enum
enum BraCupSize {
  aa('AA'),
  a('A'),
  b('B'),
  c('C'),
  d('D'),
  e('E'),
  f('F'),
  g('G'),
  h('H'),
  i('I'),
  j('J'),
  k('K');

  final String value;
  const BraCupSize(this.value);
}

/// Bra Support Level enum
enum BraSupportLevel {
  light('LIGHT'),
  medium('MEDIUM'),
  high('HIGH');

  final String value;
  const BraSupportLevel(this.value);
}

/// Pattern enum
enum Pattern {
  solid('SOLID'),
  striped('STRIPED'),
  floral('FLORAL'),
  polkaDot('POLKA_DOT'),
  checkered('CHECKERED'),
  plain('PLAIN'),
  animalPrint('ANIMAL_PRINT'),
  geometric('GEOMETRIC'),
  abstract('ABSTRACT'),
  paisley('PAISLEY'),
  embroidered('EMBROIDERED'),
  lace('LACE'),
  tieDye('TIE_DYE'),
  camouflage('CAMOUFLAGE'),
  herringbone('HERRINGBONE');

  final String value;
  const Pattern(this.value);
}

/// Clothing Item enum
enum ClothingItem {
  dress('DRESS'),
  hijab('HIJAB'),
  abaya('ABAYA'),
  tunic('TUNIC'),
  blouse('BLOUSE'),
  shirt('SHIRT'),
  tShirt('T_SHIRT'),
  top('TOP'),
  pants('PANTS'),
  jeans('JEANS'),
  skirt('SKIRT'),
  cardigan('CARDIGAN'),
  jacket('JACKET'),
  coat('COAT'),
  sweater('SWEATER'),
  jumpsuit('JUMPSUIT'),
  shorts('SHORTS'),
  leggings('LEGGINGS'),
  scarf('SCARF'),
  shawl('SHAWL'),
  vest('VEST'),
  kimono('KIMONO');

  final String value;
  const ClothingItem(this.value);
}

/// Style Tag enum
enum StyleTag {
  casual('CASUAL'),
  formal('FORMAL'),
  business('BUSINESS'),
  sporty('SPORTY'),
  elegant('ELEGANT'),
  bohemian('BOHEMIAN'),
  vintage('VINTAGE'),
  modern('MODERN'),
  minimalist('MINIMALIST'),
  classic('CLASSIC'),
  trendy('TRENDY'),
  modest('MODEST'),
  streetwear('STREETWEAR'),
  romantic('ROMANTIC'),
  edgy('EDGY'),
  preppy('PREPPY'),
  athleisure('ATHLEISURE'),
  chic('CHIC'),
  glamorous('GLAMOROUS'),
  revealing('REVEALING'),
  sexy('SEXY'),
  retro('RETRO'),
  grunge('GRUNGE'),
  gothic('GOTHIC'),
  hippie('HIPPIE'),
  artsy('ARTSY'),
  feminine('FEMININE'),
  masculine('MASCULINE'),
  androgynous('ANDROGYNOUS'),
  luxurious('LUXURIOUS');

  final String value;
  const StyleTag(this.value);
}
