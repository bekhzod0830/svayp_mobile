/// Localized display names for enums
/// Provides translated names based on the current locale
///
/// Usage:
/// ```dart
/// final l10n = AppLocalizations.of(context)!;
/// final sizeName = SizeEnum.m.getLocalizedName(l10n); // Returns translated size
/// ```

import 'package:swipe/l10n/app_localizations.dart';
import '../constants/product_enums.dart';
import '../constants/user_enums.dart';

/// Extension for SizeEnum localization
extension SizeEnumLocalization on SizeEnum {
  String getLocalizedName(AppLocalizations l10n) {
    // Sizes are generally universal and don't need translation
    // But we can add specific translations if needed
    return displayName;
  }
}

/// Extension for ColorEnum localization
extension ColorEnumLocalization on ColorEnum {
  String getLocalizedName(AppLocalizations l10n) {
    switch (this) {
      case ColorEnum.black:
        return l10n.colorBlack;
      case ColorEnum.white:
        return l10n.colorWhite;
      case ColorEnum.gray:
      case ColorEnum.grey:
        return l10n.colorGray;
      case ColorEnum.navy:
        return l10n.colorNavy;
      case ColorEnum.blue:
        return l10n.colorBlue;
      case ColorEnum.lightBlue:
        return l10n.colorLightBlue;
      case ColorEnum.darkBlue:
        return l10n.colorDarkBlue;
      case ColorEnum.red:
        return l10n.colorRed;
      case ColorEnum.pink:
        return l10n.colorPink;
      case ColorEnum.green:
        return l10n.colorGreen;
      case ColorEnum.brown:
        return l10n.colorBrown;
      case ColorEnum.beige:
        return l10n.colorBeige;
      case ColorEnum.purple:
        return l10n.colorPurple;
      case ColorEnum.yellow:
        return l10n.colorYellow;
      case ColorEnum.orange:
        return l10n.colorOrange;
      case ColorEnum.cream:
        return l10n.colorCream;
      default:
        return displayName; // Fallback to English display name
    }
  }
}

/// Extension for MaterialEnum localization
extension MaterialEnumLocalization on MaterialEnum {
  String getLocalizedName(AppLocalizations l10n) {
    switch (this) {
      case MaterialEnum.cotton:
        return l10n.materialCotton;
      case MaterialEnum.silk:
        return l10n.materialSilk;
      case MaterialEnum.linen:
        return l10n.materialLinen;
      case MaterialEnum.wool:
        return l10n.materialWool;
      case MaterialEnum.chiffon:
        return l10n.materialChiffon;
      case MaterialEnum.denim:
        return l10n.materialDenim;
      case MaterialEnum.leather:
        return l10n.materialLeather;
      default:
        return displayName;
    }
  }
}

/// Extension for SeasonEnum localization
extension SeasonEnumLocalization on SeasonEnum {
  String getLocalizedName(AppLocalizations l10n) {
    switch (this) {
      case SeasonEnum.spring:
        return l10n.seasonSpring;
      case SeasonEnum.summer:
        return l10n.seasonSummer;
      case SeasonEnum.fall:
      case SeasonEnum.autumn:
        return l10n.seasonFall;
      case SeasonEnum.winter:
        return l10n.seasonWinter;
      case SeasonEnum.allSeason:
        return l10n.seasonAllSeason;
    }
  }
}

/// Extension for FitTypeEnum localization
extension FitTypeEnumLocalization on FitTypeEnum {
  String getLocalizedName(AppLocalizations l10n) {
    switch (this) {
      case FitTypeEnum.loose:
        return l10n.fitLoose;
      case FitTypeEnum.regular:
        return l10n.fitRegular;
      case FitTypeEnum.slim:
        return l10n.fitSlim;
      case FitTypeEnum.oversized:
        return l10n.fitOversized;
      default:
        return displayName;
    }
  }
}

/// Extension for StyleCategoryEnum localization
extension StyleCategoryEnumLocalization on StyleCategoryEnum {
  String getLocalizedName(AppLocalizations l10n) {
    switch (this) {
      case StyleCategoryEnum.casual:
        return l10n.styleCasual;
      case StyleCategoryEnum.formal:
        return l10n.styleFormal;
      case StyleCategoryEnum.sporty:
        return l10n.styleSporty;
      case StyleCategoryEnum.elegant:
        return l10n.styleElegant;
      case StyleCategoryEnum.modest:
        return l10n.styleModest;
      default:
        return displayName;
    }
  }
}

/// Extension for OccasionEnum localization
extension OccasionEnumLocalization on OccasionEnum {
  String getLocalizedName(AppLocalizations l10n) {
    switch (this) {
      case OccasionEnum.daily:
        return l10n.occasionDaily;
      case OccasionEnum.work:
        return l10n.occasionWork;
      case OccasionEnum.wedding:
        return l10n.occasionWedding;
      case OccasionEnum.party:
        return l10n.occasionParty;
      case OccasionEnum.casual:
        return l10n.occasionCasual;
      case OccasionEnum.formal:
        return l10n.occasionFormal;
      case OccasionEnum.prayer:
        return l10n.occasionPrayer;
      default:
        return displayName;
    }
  }
}

/// Extension for BodyTypeEnum localization
extension BodyTypeEnumLocalization on BodyTypeEnum {
  String getLocalizedName(AppLocalizations l10n) {
    switch (this) {
      case BodyTypeEnum.hourglass:
        return l10n.hourglass;
      case BodyTypeEnum.triangle:
        return l10n.triangle;
      case BodyTypeEnum.rectangle:
        return l10n.rectangle;
      case BodyTypeEnum.oval:
        return l10n.oval;
      case BodyTypeEnum.heart:
        return l10n.heart;
      case BodyTypeEnum.preferNotToSay:
        return l10n.preferNotToSay;
    }
  }
}

/// Extension for HijabPreferenceEnum localization
extension HijabPreferenceEnumLocalization on HijabPreferenceEnum {
  String getLocalizedName(AppLocalizations l10n) {
    switch (this) {
      case HijabPreferenceEnum.covered:
        return l10n.covered;
      case HijabPreferenceEnum.uncovered:
        return l10n.uncovered;
      case HijabPreferenceEnum.notApplicable:
        return l10n.notApplicable;
    }
  }
}

/// Extension for FitPreferenceEnum localization
extension FitPreferenceEnumLocalization on FitPreferenceEnum {
  String getLocalizedName(AppLocalizations l10n) {
    switch (this) {
      case FitPreferenceEnum.regular:
        return l10n.regular;
      case FitPreferenceEnum.loose:
        return l10n.loose;
      case FitPreferenceEnum.notApplicable:
        return l10n.notApplicable;
    }
  }
}

/// Extension for CategoryEnum localization
extension CategoryEnumLocalization on CategoryEnum {
  String getLocalizedName(AppLocalizations l10n) {
    switch (this) {
      case CategoryEnum.dress:
        return l10n.categoryDress;
      case CategoryEnum.hijab:
        return l10n.categoryHijab;
      case CategoryEnum.abaya:
        return l10n.categoryAbaya;
      case CategoryEnum.tunic:
        return l10n.categoryTunic;
      case CategoryEnum.top:
        return l10n.categoryTop;
      case CategoryEnum.blouse:
        return l10n.categoryBlouse;
      case CategoryEnum.shirt:
        return l10n.categoryShirt;
      case CategoryEnum.pants:
        return l10n.categoryPants;
      case CategoryEnum.jeans:
        return l10n.categoryJeans;
      case CategoryEnum.skirt:
        return l10n.categorySkirt;
      case CategoryEnum.jacket:
        return l10n.categoryJacket;
      case CategoryEnum.coat:
        return l10n.categoryCoat;
      case CategoryEnum.cardigan:
        return l10n.categoryCardigan;
      case CategoryEnum.sweater:
        return l10n.categorySweater;
      case CategoryEnum.activewear:
        return l10n.categoryActivewear;
      case CategoryEnum.jumpsuit:
        return l10n.categoryJumpsuit;
      case CategoryEnum.scarf:
        return l10n.categoryScarf;
      case CategoryEnum.shawl:
        return l10n.categoryShawl;
      case CategoryEnum.accessories:
        return l10n.categoryAccessories;
      case CategoryEnum.shoes:
        return l10n.categoryShoes;
      case CategoryEnum.bags:
        return l10n.categoryBags;
      case CategoryEnum.jewelry:
        return l10n.categoryJewelry;
      case CategoryEnum.underwear:
        return l10n.categoryUnderwear;
      case CategoryEnum.outerwear:
        return l10n.categoryOuterwear;
    }
  }
}

/// Extension for SubcategoryEnum localization
/// Note: Subcategories use displayName as they are more specific
/// Add translations if needed for specific subcategories
extension SubcategoryEnumLocalization on SubcategoryEnum {
  String getLocalizedName(AppLocalizations l10n) {
    // Most subcategories can use their displayName
    // Add specific translations here if needed
    return displayName;
  }
}
