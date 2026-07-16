/// All analytics event names and parameter keys used across the app.
/// Centralizing them prevents typos and makes refactoring easier.
abstract class AnalyticsEvents {
  AnalyticsEvents._();

  // ─── Auth ─────────────────────────────────────────────────────────────────
  /// User opened the phone number entry screen
  static const String authScreenOpened = 'auth_screen_opened';

  /// User tapped "Send OTP" button
  static const String otpRequested = 'otp_requested';

  /// OTP was sent successfully
  static const String otpSentSuccess = 'otp_sent_success';

  /// OTP request failed
  static const String otpSentFailure = 'otp_sent_failure';

  /// User opened the OTP verification screen
  static const String otpScreenOpened = 'otp_screen_opened';

  /// User tapped "Verify" / submitted OTP
  static const String otpSubmitted = 'otp_submitted';

  /// OTP verified successfully — new user (registration)
  static const String registrationCompleted = 'registration_completed';

  /// OTP verified successfully — existing user (login)
  static const String loginCompleted = 'login_completed';

  /// OTP verification failed
  static const String otpVerificationFailed = 'otp_verification_failed';

  /// User tapped "Resend OTP"
  static const String otpResendTapped = 'otp_resend_tapped';

  // ─── Intro carousel (pre-auth marketing onboarding) ───────────────────────
  /// Carousel opened (first slide shown).
  static const String introViewed = 'intro_viewed';

  /// A slide became visible. Params: {slide: '1'..'7'}.
  static const String introSlideViewed = 'intro_slide_viewed';

  /// "Skip" tapped (jumps to the gift slide). Params: {from_slide}.
  static const String introSkipped = 'intro_skipped';

  /// "Start" tapped on the last slide — user proceeds to phone auth.
  static const String introCompleted = 'intro_completed';

  /// Welcome gift dialog shown after registration.
  static const String welcomeGiftPopupViewed = 'welcome_gift_popup_viewed';

  // ─── Onboarding ───────────────────────────────────────────────────────────
  /// All onboarding steps finished — user reached the completion screen.
  static const String onboardingCompleted = 'onboarding_completed';

  // ─── Onboarding step viewed events (one unique event per screen) ──────────
  static const String onboardingBasicInfoViewed      = 'ob_basic_info_viewed';
  static const String onboardingHijabPrefViewed      = 'ob_hijab_pref_viewed';
  static const String onboardingFitPrefViewed        = 'ob_fit_pref_viewed';
  static const String onboardingModestyViewed        = 'ob_modesty_viewed';
  static const String onboardingSizeProfileViewed    = 'ob_size_profile_viewed';
  static const String onboardingStyleQuizViewed      = 'ob_style_quiz_viewed';
  static const String onboardingAvoidedItemsViewed   = 'ob_avoided_items_viewed';
  static const String onboardingAvoidedShoesViewed   = 'ob_avoided_shoes_viewed';
  static const String onboardingAvoidedPrintsViewed  = 'ob_avoided_prints_viewed';
  static const String onboardingTutorialViewed       = 'ob_tutorial_viewed';
  static const String onboardingCompletionViewed     = 'ob_completion_viewed';
  static const String onboardingIntentViewed         = 'ob_intent_viewed';
  static const String onboardingIntentSelected       = 'ob_intent_selected';

  // ─── Onboarding step completed events (one unique event per screen) ───────
  static const String onboardingBasicInfoCompleted     = 'ob_basic_info_done';
  static const String onboardingHijabPrefCompleted     = 'ob_hijab_pref_done';
  static const String onboardingFitPrefCompleted       = 'ob_fit_pref_done';
  static const String onboardingModestyCompleted       = 'ob_modesty_done';
  static const String onboardingSizeProfileCompleted   = 'ob_size_profile_done';
  static const String onboardingStyleQuizCompleted     = 'ob_style_quiz_done';
  static const String onboardingAvoidedItemsCompleted  = 'ob_avoided_items_done';
  static const String onboardingAvoidedShoesCompleted  = 'ob_avoided_shoes_done';
  static const String onboardingAvoidedPrintsCompleted = 'ob_avoided_prints_done';
  static const String onboardingTutorialCompleted      = 'ob_tutorial_done';

  // ─── Main / Discover ──────────────────────────────────────────────────────
  static const String productSwiped = 'product_swiped';
  static const String productLiked = 'product_liked';
  static const String productDisliked = 'product_disliked';
  static const String productDetailOpened = 'product_detail_opened';
  static const String swipeUndo = 'swipe_undo';
  static const String feedExhausted = 'feed_exhausted';

  // ─── Product Detail ───────────────────────────────────────────────────────
  static const String productAddedToCart = 'product_added_to_cart';
  static const String productSizeSelected = 'product_size_selected';
  static const String productColorSelected = 'product_color_selected';
  static const String productExternalLinkTapped = 'product_external_link_tapped';
  static const String sellerProfileOpened = 'seller_profile_opened';
  static const String chatWithSellerStarted = 'chat_with_seller_started';

  // ─── Shop ─────────────────────────────────────────────────────────────────
  static const String searchInitiated = 'search_initiated';
  static const String categoryFilterSelected = 'category_filter_selected';
  static const String sellerFilterApplied = 'seller_filter_applied';
  static const String visualSearchOpened = 'visual_search_opened';

  // ─── Cart & Checkout ──────────────────────────────────────────────────────
  static const String cartOpened = 'cart_opened';
  static const String cartItemRemoved = 'cart_item_removed';
  static const String cartQuantityChanged = 'cart_quantity_changed';
  static const String checkoutStarted = 'checkout_started';
  static const String orderPlaced = 'order_placed';

  // ─── Liked ────────────────────────────────────────────────────────────────
  static const String likedItemRemoved = 'liked_item_removed';

  // ─── Chat ─────────────────────────────────────────────────────────────────
  static const String chatConversationOpened = 'chat_conversation_opened';
  static const String messageSent = 'message_sent';

  // ─── Profile ──────────────────────────────────────────────────────────────
  static const String languageChanged = 'language_changed';
  static const String themeChanged = 'theme_changed';
  static const String logoutTapped = 'logout_tapped';

  // ─── Navigation ───────────────────────────────────────────────────────────
  static const String tabSelected = 'tab_selected';

  // ─── Wardrobe / Closet ──────────────────────────────────────────────────────
  /// User added an item to their closet/wardrobe
  static const String closetItemAdded = 'closet_item_added';

  // ─── Parameter keys ───────────────────────────────────────────────────────
  static const String paramStep = 'step';
  static const String paramScreen = 'screen';
  static const String paramMethod = 'method';
  static const String paramSuccess = 'success';
  static const String paramErrorCode = 'error_code';
  static const String paramProductId = 'product_id';
  static const String paramDirection = 'direction';
  static const String paramCategory = 'category';
  static const String paramBrand = 'brand';
  static const String paramPrice = 'price';
  static const String paramSize = 'size';
  static const String paramColor = 'color';
  static const String paramQuantity = 'quantity';
  static const String paramSellerId = 'seller_id';
  static const String paramTabName = 'tab_name';
  static const String paramLanguage = 'language';
  static const String paramTheme = 'theme';
  static const String paramCartTotal = 'cart_total';
  static const String paramItemCount = 'item_count';
  static const String paramDeliveryMethod = 'delivery_method';
  static const String paramNewQuantity = 'new_quantity';
}
