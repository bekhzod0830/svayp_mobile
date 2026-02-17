/// User-related enums matching backend API
/// These enums correspond to the Python enums in app/schemas/schemas.py

// ==================== Gender Enum ====================

enum GenderEnum {
  male('male'),
  female('female');

  final String value;
  const GenderEnum(this.value);

  String get displayName {
    return value[0].toUpperCase() + value.substring(1);
  }

  static GenderEnum? fromString(String? value) {
    if (value == null) return null;
    try {
      return GenderEnum.values.firstWhere(
        (e) => e.value == value.toLowerCase(),
      );
    } catch (_) {
      return null;
    }
  }
}

// ==================== Hijab Preference Enum ====================

enum HijabPreferenceEnum {
  covered('covered'),
  uncovered('uncovered'),
  notApplicable('not_applicable');

  final String value;
  const HijabPreferenceEnum(this.value);

  String get displayName {
    switch (this) {
      case HijabPreferenceEnum.covered:
        return 'Covered';
      case HijabPreferenceEnum.uncovered:
        return 'Uncovered';
      case HijabPreferenceEnum.notApplicable:
        return 'Not Applicable';
    }
  }

  static HijabPreferenceEnum? fromString(String? value) {
    if (value == null) return null;
    try {
      return HijabPreferenceEnum.values.firstWhere(
        (e) => e.value == value.toLowerCase(),
      );
    } catch (_) {
      return null;
    }
  }
}

// ==================== Fit Preference Enum ====================

enum FitPreferenceEnum {
  regular('regular'),
  loose('loose'),
  notApplicable('not_applicable');

  final String value;
  const FitPreferenceEnum(this.value);

  String get displayName {
    switch (this) {
      case FitPreferenceEnum.regular:
        return 'Regular';
      case FitPreferenceEnum.loose:
        return 'Loose';
      case FitPreferenceEnum.notApplicable:
        return 'Not Applicable';
    }
  }

  static FitPreferenceEnum? fromString(String? value) {
    if (value == null) return null;
    try {
      return FitPreferenceEnum.values.firstWhere(
        (e) => e.value == value.toLowerCase(),
      );
    } catch (_) {
      return null;
    }
  }
}

// ==================== Body Type Enum ====================

enum BodyTypeEnum {
  hourglass('hourglass'),
  triangle('triangle'),
  rectangle('rectangle'),
  oval('oval'),
  heart('heart'),
  preferNotToSay('prefer_not_to_say');

  final String value;
  const BodyTypeEnum(this.value);

  String get displayName {
    switch (this) {
      case BodyTypeEnum.hourglass:
        return 'Hourglass';
      case BodyTypeEnum.triangle:
        return 'Triangle';
      case BodyTypeEnum.rectangle:
        return 'Rectangle';
      case BodyTypeEnum.oval:
        return 'Oval';
      case BodyTypeEnum.heart:
        return 'Heart';
      case BodyTypeEnum.preferNotToSay:
        return 'Prefer Not to Say';
    }
  }

  static BodyTypeEnum? fromString(String? value) {
    if (value == null) return null;
    try {
      return BodyTypeEnum.values.firstWhere(
        (e) => e.value == value.toLowerCase(),
      );
    } catch (_) {
      return null;
    }
  }
}

// ==================== Primary Objective Enum ====================

enum PrimaryObjectiveEnum {
  haveOwnStyle('have_own_style'),
  findMyBestFit('find_my_best_fit'),
  aFunSurprise('a_fun_surprise'),
  uniquePieces('unique_pieces'),
  updateMyLook('update_my_look'),
  saveTimeShopping('save_time_shopping'),
  tryNewTrends('try_new_trends'),
  browseAPersonalizedShop('browse_a_personalized_shop');

  final String value;
  const PrimaryObjectiveEnum(this.value);

  String get displayName {
    return value
        .split('_')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  static PrimaryObjectiveEnum? fromString(String? value) {
    if (value == null) return null;
    try {
      return PrimaryObjectiveEnum.values.firstWhere(
        (e) => e.value == value.toLowerCase(),
      );
    } catch (_) {
      return null;
    }
  }
}

// ==================== Event Type Enum ====================

enum EventTypeEnum {
  swipe('swipe'),
  view('view'),
  cartAdd('cart_add'),
  cartRemove('cart_remove'),
  purchase('purchase'),
  review('review'),
  share('share');

  final String value;
  const EventTypeEnum(this.value);

  String get displayName {
    return value
        .split('_')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  static EventTypeEnum? fromString(String? value) {
    if (value == null) return null;
    try {
      return EventTypeEnum.values.firstWhere(
        (e) => e.value == value.toLowerCase(),
      );
    } catch (_) {
      return null;
    }
  }
}

// ==================== Swipe Action Enum ====================

enum SwipeActionEnum {
  like('like'),
  dislike('dislike');

  final String value;
  const SwipeActionEnum(this.value);

  String get displayName {
    return value[0].toUpperCase() + value.substring(1);
  }

  static SwipeActionEnum? fromString(String? value) {
    if (value == null) return null;
    try {
      return SwipeActionEnum.values.firstWhere(
        (e) => e.value == value.toLowerCase(),
      );
    } catch (_) {
      return null;
    }
  }
}

// ==================== Order Status Enum ====================

enum OrderStatusEnum {
  pending('pending'),
  confirmed('confirmed'),
  processing('processing'),
  readyForPickup('ready_for_pickup'),
  pickedUp('picked_up'),
  cancelled('cancelled');

  final String value;
  const OrderStatusEnum(this.value);

  String get displayName {
    return value
        .split('_')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  static OrderStatusEnum? fromString(String? value) {
    if (value == null) return null;
    try {
      return OrderStatusEnum.values.firstWhere(
        (e) => e.value == value.toLowerCase(),
      );
    } catch (_) {
      return null;
    }
  }
}

// ==================== User Role Enum ====================

enum UserRoleEnum {
  client('client'),
  admin('admin'),
  superAdmin('super_admin');

  final String value;
  const UserRoleEnum(this.value);

  String get displayName {
    return value
        .split('_')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  static UserRoleEnum? fromString(String? value) {
    if (value == null) return null;
    try {
      return UserRoleEnum.values.firstWhere(
        (e) => e.value == value.toLowerCase(),
      );
    } catch (_) {
      return null;
    }
  }
}
