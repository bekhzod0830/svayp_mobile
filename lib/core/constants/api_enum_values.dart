/// API Enum Values
/// This file documents all valid enum values expected by the backend API
/// All values must be sent in UPPERCASE to match backend enums

class ApiEnumValues {
  // Gender
  static const gender = ['FEMALE'];

  // Body Types
  static const bodyTypes = [
    'HOURGLASS',
    'TRIANGLE',
    'RECTANGLE',
    'OVAL',
    'HEART',
    'PREFER_NOT_TO_SAY',
  ];

  // Hijab Preferences
  static const hijabPreferences = ['COVERED', 'UNCOVERED', 'NOT_APPLICABLE'];

  // Fit Types (fitPreference)
  static const fitTypes = [
    'LOOSE',
    'REGULAR',
    'OVERSIZED',
    'SLIM',
    'SUPER_SLIM',
    'FITTED',
  ];

  // Style Preferences (stylePreference)
  static const stylePreferences = ['COVERED', 'MODERATE', 'REVEALING'];

  // Primary Objectives
  static const primaryObjectives = [
    'HAVE_OWN_STYLE',
    'FIND_MY_BEST_FIT',
    'A_FUN_SURPRISE',
    'UNIQUE_PIECES',
    'UPDATE_MY_LOOK',
    'SAVE_TIME_SHOPPING',
    'TRY_NEW_TRENDS',
    'BROWSE_A_PERSONALIZED_SHOP',
  ];

  // Budget Types
  static const budgetTypes = [
    'BUDGET', // 0 - 500,000 UZS
    'MODERATE', // 500,000 - 1,500,000 UZS
    'PREMIUM', // 1,500,000 - 3,000,000 UZS
    'LUXURY', // 3,000,000+ UZS
    'FLEXIBLE', // Any price range
  ];

  // Clothing Sizes
  static const clothingSizes = [
    'XXS',
    'XS',
    'S',
    'M',
    'L',
    'XL',
    'XXL',
    'XXXL',
  ];

  // Shoe Sizes
  static const shoeSizes = [
    'EU_34',
    'EU_35',
    'EU_36',
    'EU_37',
    'EU_38',
    'EU_39',
    'EU_40',
    'EU_41',
    'EU_42',
    'EU_43',
    'EU_44',
    'EU_45',
  ];

  // Pants Sizes (for bottomSize and jeanWaistSize)
  static const pantsSizes = [
    'SIZE_24',
    'SIZE_25',
    'SIZE_26',
    'SIZE_27',
    'SIZE_28',
    'SIZE_29',
    'SIZE_30',
    'SIZE_32',
    'SIZE_34',
    'SIZE_36',
    'SIZE_38',
    'SIZE_40',
    'SIZE_42',
    'SIZE_44',
    'SIZE_46',
    'SIZE_48',
  ];

  // Bra Band Sizes (EU)
  static const braBandSizes = [
    'EU_60',
    'EU_65',
    'EU_70',
    'EU_75',
    'EU_80',
    'EU_85',
    'EU_90',
    'EU_95',
    'EU_100',
    'EU_105',
    'EU_110',
    'EU_115',
    'EU_120',
  ];

  // Bra Types
  static const braTypes = [
    'TRAINING',
    'T_SHIRT',
    'SPORTS',
    'PUSH_UP',
    'BALCONETTE',
    'STRAPLESS',
    'WIRELESS',
    'UNDERWIRE',
    'BRALETTE',
    'MINIMIZER',
    'FULL_COVERAGE',
  ];

  // Bra Cup Sizes
  static const braCupSizes = [
    'AA',
    'A',
    'B',
    'C',
    'D',
    'E',
    'F',
    'G',
    'H',
    'I',
    'J',
    'K',
  ];

  // Bra Support Levels
  static const braSupportLevels = ['LIGHT', 'MEDIUM', 'HIGH'];

  // Patterns
  static const patterns = [
    'SOLID',
    'STRIPED',
    'FLORAL',
    'POLKA_DOT',
    'CHECKERED',
    'PLAIN',
    'ANIMAL_PRINT',
    'GEOMETRIC',
    'ABSTRACT',
    'PAISLEY',
    'EMBROIDERED',
    'LACE',
    'TIE_DYE',
    'CAMOUFLAGE',
    'HERRINGBONE',
  ];

  // Clothing Items
  static const clothingItems = [
    'DRESS',
    'HIJAB',
    'ABAYA',
    'TUNIC',
    'BLOUSE',
    'SHIRT',
    'T_SHIRT',
    'TOP',
    'PANTS',
    'JEANS',
    'SKIRT',
    'CARDIGAN',
    'JACKET',
    'COAT',
    'SWEATER',
    'JUMPSUIT',
    'SHORTS',
    'LEGGINGS',
    'SCARF',
    'SHAWL',
    'VEST',
    'KIMONO',
  ];

  // Style Tags (styleCategories)
  static const styleTags = [
    'CASUAL',
    'FORMAL',
    'BUSINESS',
    'SPORTY',
    'ELEGANT',
    'BOHEMIAN',
    'VINTAGE',
    'MODERN',
    'MINIMALIST',
    'CLASSIC',
    'TRENDY',
    'MODEST',
    'STREETWEAR',
    'ROMANTIC',
    'EDGY',
    'PREPPY',
    'ATHLEISURE',
    'CHIC',
    'GLAMOROUS',
    'REVEALING',
    'SEXY',
    'RETRO',
    'GRUNGE',
    'GOTHIC',
    'HIPPIE',
    'ARTSY',
    'FEMININE',
    'MASCULINE',
    'ANDROGYNOUS',
    'LUXURIOUS',
  ];
}
