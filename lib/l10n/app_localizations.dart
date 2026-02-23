import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ru.dart';
import 'app_localizations_uz.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ru'),
    Locale('uz'),
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'SVAYP'**
  String get appName;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @removedFromLikedItems.
  ///
  /// In en, this message translates to:
  /// **'Removed from liked items'**
  String get removedFromLikedItems;

  /// No description provided for @quantity.
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String get quantity;

  /// No description provided for @customerReviewPrompt.
  ///
  /// In en, this message translates to:
  /// **'See what other customers are saying about this product'**
  String get customerReviewPrompt;

  /// No description provided for @jan.
  ///
  /// In en, this message translates to:
  /// **'Jan'**
  String get jan;

  /// No description provided for @feb.
  ///
  /// In en, this message translates to:
  /// **'Feb'**
  String get feb;

  /// No description provided for @mar.
  ///
  /// In en, this message translates to:
  /// **'Mar'**
  String get mar;

  /// No description provided for @apr.
  ///
  /// In en, this message translates to:
  /// **'Apr'**
  String get apr;

  /// No description provided for @may.
  ///
  /// In en, this message translates to:
  /// **'May'**
  String get may;

  /// No description provided for @jun.
  ///
  /// In en, this message translates to:
  /// **'Jun'**
  String get jun;

  /// No description provided for @jul.
  ///
  /// In en, this message translates to:
  /// **'Jul'**
  String get jul;

  /// No description provided for @aug.
  ///
  /// In en, this message translates to:
  /// **'Aug'**
  String get aug;

  /// No description provided for @sep.
  ///
  /// In en, this message translates to:
  /// **'Sep'**
  String get sep;

  /// No description provided for @oct.
  ///
  /// In en, this message translates to:
  /// **'Oct'**
  String get oct;

  /// No description provided for @nov.
  ///
  /// In en, this message translates to:
  /// **'Nov'**
  String get nov;

  /// No description provided for @dec.
  ///
  /// In en, this message translates to:
  /// **'Dec'**
  String get dec;

  /// No description provided for @order.
  ///
  /// In en, this message translates to:
  /// **'Order'**
  String get order;

  /// No description provided for @trackingNumber.
  ///
  /// In en, this message translates to:
  /// **'Tracking Number'**
  String get trackingNumber;

  /// No description provided for @items.
  ///
  /// In en, this message translates to:
  /// **'Items'**
  String get items;

  /// No description provided for @products.
  ///
  /// In en, this message translates to:
  /// **'products'**
  String get products;

  /// No description provided for @allProducts.
  ///
  /// In en, this message translates to:
  /// **'All Products'**
  String get allProducts;

  /// No description provided for @total.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get total;

  /// No description provided for @track.
  ///
  /// In en, this message translates to:
  /// **'Track'**
  String get track;

  /// No description provided for @reorder.
  ///
  /// In en, this message translates to:
  /// **'Reorder'**
  String get reorder;

  /// No description provided for @trackingComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Tracking coming soon'**
  String get trackingComingSoon;

  /// No description provided for @reorderComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Reorder coming soon'**
  String get reorderComingSoon;

  /// No description provided for @enterPhoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter your phone number'**
  String get enterPhoneNumber;

  /// No description provided for @phoneVerificationSubtitle.
  ///
  /// In en, this message translates to:
  /// **'We\'ll send you a verification code to confirm your number'**
  String get phoneVerificationSubtitle;

  /// No description provided for @phoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phoneNumber;

  /// No description provided for @iAgreeToThe.
  ///
  /// In en, this message translates to:
  /// **'I agree to the '**
  String get iAgreeToThe;

  /// No description provided for @termsOfService.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get termsOfService;

  /// No description provided for @and.
  ///
  /// In en, this message translates to:
  /// **' and '**
  String get and;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// No description provided for @continueButton.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueButton;

  /// No description provided for @contactSupport.
  ///
  /// In en, this message translates to:
  /// **'Having trouble? Contact support'**
  String get contactSupport;

  /// No description provided for @agreeToTermsError.
  ///
  /// In en, this message translates to:
  /// **'Please agree to Terms & Privacy Policy'**
  String get agreeToTermsError;

  /// No description provided for @otpSendError.
  ///
  /// In en, this message translates to:
  /// **'Failed to send OTP. Please try again.'**
  String get otpSendError;

  /// No description provided for @verifyPhoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Verify your\nphone number'**
  String get verifyPhoneNumber;

  /// No description provided for @enterDigitCode.
  ///
  /// In en, this message translates to:
  /// **'Enter the 6-digit code sent to\n'**
  String get enterDigitCode;

  /// No description provided for @completeOtpError.
  ///
  /// In en, this message translates to:
  /// **'Please enter complete OTP code'**
  String get completeOtpError;

  /// No description provided for @invalidOtpError.
  ///
  /// In en, this message translates to:
  /// **'Invalid OTP. Please try again.'**
  String get invalidOtpError;

  /// No description provided for @otpSentSuccess.
  ///
  /// In en, this message translates to:
  /// **'OTP sent successfully'**
  String get otpSentSuccess;

  /// No description provided for @resendOtpError.
  ///
  /// In en, this message translates to:
  /// **'Failed to resend OTP. Please try again.'**
  String get resendOtpError;

  /// No description provided for @resendCode.
  ///
  /// In en, this message translates to:
  /// **'Resend Code'**
  String get resendCode;

  /// No description provided for @resendCodeIn.
  ///
  /// In en, this message translates to:
  /// **'Resend code in {seconds} seconds'**
  String resendCodeIn(int seconds);

  /// No description provided for @verify.
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get verify;

  /// No description provided for @wrongNumber.
  ///
  /// In en, this message translates to:
  /// **'Wrong number?'**
  String get wrongNumber;

  /// No description provided for @tellUsAboutYourself.
  ///
  /// In en, this message translates to:
  /// **'Tell us about\nyourself'**
  String get tellUsAboutYourself;

  /// No description provided for @personalizeExperience.
  ///
  /// In en, this message translates to:
  /// **'This helps us personalize your experience'**
  String get personalizeExperience;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get fullName;

  /// No description provided for @enterYourName.
  ///
  /// In en, this message translates to:
  /// **'Enter your name'**
  String get enterYourName;

  /// No description provided for @gender.
  ///
  /// In en, this message translates to:
  /// **'Gender'**
  String get gender;

  /// No description provided for @male.
  ///
  /// In en, this message translates to:
  /// **'Male'**
  String get male;

  /// No description provided for @female.
  ///
  /// In en, this message translates to:
  /// **'Female'**
  String get female;

  /// No description provided for @dateOfBirth.
  ///
  /// In en, this message translates to:
  /// **'Date of Birth'**
  String get dateOfBirth;

  /// No description provided for @day.
  ///
  /// In en, this message translates to:
  /// **'Day'**
  String get day;

  /// No description provided for @month.
  ///
  /// In en, this message translates to:
  /// **'Month'**
  String get month;

  /// No description provided for @year.
  ///
  /// In en, this message translates to:
  /// **'Year'**
  String get year;

  /// No description provided for @january.
  ///
  /// In en, this message translates to:
  /// **'January'**
  String get january;

  /// No description provided for @february.
  ///
  /// In en, this message translates to:
  /// **'February'**
  String get february;

  /// No description provided for @march.
  ///
  /// In en, this message translates to:
  /// **'March'**
  String get march;

  /// No description provided for @april.
  ///
  /// In en, this message translates to:
  /// **'April'**
  String get april;

  /// No description provided for @june.
  ///
  /// In en, this message translates to:
  /// **'June'**
  String get june;

  /// No description provided for @july.
  ///
  /// In en, this message translates to:
  /// **'July'**
  String get july;

  /// No description provided for @august.
  ///
  /// In en, this message translates to:
  /// **'August'**
  String get august;

  /// No description provided for @september.
  ///
  /// In en, this message translates to:
  /// **'September'**
  String get september;

  /// No description provided for @october.
  ///
  /// In en, this message translates to:
  /// **'October'**
  String get october;

  /// No description provided for @november.
  ///
  /// In en, this message translates to:
  /// **'November'**
  String get november;

  /// No description provided for @december.
  ///
  /// In en, this message translates to:
  /// **'December'**
  String get december;

  /// No description provided for @selectBirthDate.
  ///
  /// In en, this message translates to:
  /// **'Please select your date of birth'**
  String get selectBirthDate;

  /// No description provided for @selectGenderError.
  ///
  /// In en, this message translates to:
  /// **'Please select your gender'**
  String get selectGenderError;

  /// No description provided for @selectDateError.
  ///
  /// In en, this message translates to:
  /// **'Please select your date of birth'**
  String get selectDateError;

  /// No description provided for @saveInfoError.
  ///
  /// In en, this message translates to:
  /// **'Failed to save info. Please try again.'**
  String get saveInfoError;

  /// No description provided for @yourStylePreference.
  ///
  /// In en, this message translates to:
  /// **'Your Style Preference'**
  String get yourStylePreference;

  /// No description provided for @relevantFashionChoices.
  ///
  /// In en, this message translates to:
  /// **'This helps us show you the most relevant fashion choices'**
  String get relevantFashionChoices;

  /// No description provided for @covered.
  ///
  /// In en, this message translates to:
  /// **'Covered'**
  String get covered;

  /// No description provided for @modestFashionHijab.
  ///
  /// In en, this message translates to:
  /// **'Modest fashion with Hijab'**
  String get modestFashionHijab;

  /// No description provided for @uncovered.
  ///
  /// In en, this message translates to:
  /// **'Uncovered'**
  String get uncovered;

  /// No description provided for @traditionalFashionStyles.
  ///
  /// In en, this message translates to:
  /// **'Traditional fashion styles'**
  String get traditionalFashionStyles;

  /// No description provided for @selectPreferenceError.
  ///
  /// In en, this message translates to:
  /// **'Please select your preference'**
  String get selectPreferenceError;

  /// No description provided for @savePreferenceError.
  ///
  /// In en, this message translates to:
  /// **'Failed to save preference. Please try again.'**
  String get savePreferenceError;

  /// No description provided for @primaryObjective.
  ///
  /// In en, this message translates to:
  /// **'What\'s your primary objective?'**
  String get primaryObjective;

  /// No description provided for @selectWhatMatters.
  ///
  /// In en, this message translates to:
  /// **'Select what matters most to you when shopping for fashion'**
  String get selectWhatMatters;

  /// No description provided for @havingOwnStylist.
  ///
  /// In en, this message translates to:
  /// **'Having my own Stylist'**
  String get havingOwnStylist;

  /// No description provided for @findBestFit.
  ///
  /// In en, this message translates to:
  /// **'Find my best fit'**
  String get findBestFit;

  /// No description provided for @funSurprise.
  ///
  /// In en, this message translates to:
  /// **'A fun surprise'**
  String get funSurprise;

  /// No description provided for @uniquePieces.
  ///
  /// In en, this message translates to:
  /// **'Unique pieces'**
  String get uniquePieces;

  /// No description provided for @updateLook.
  ///
  /// In en, this message translates to:
  /// **'Update my look'**
  String get updateLook;

  /// No description provided for @saveTimeShopping.
  ///
  /// In en, this message translates to:
  /// **'Save time shopping'**
  String get saveTimeShopping;

  /// No description provided for @tryNewTrends.
  ///
  /// In en, this message translates to:
  /// **'Try new trends'**
  String get tryNewTrends;

  /// No description provided for @browsePersonalizedShop.
  ///
  /// In en, this message translates to:
  /// **'Browse a personalized shop'**
  String get browsePersonalizedShop;

  /// No description provided for @selectObjectiveError.
  ///
  /// In en, this message translates to:
  /// **'Please select an objective'**
  String get selectObjectiveError;

  /// No description provided for @saveObjectiveError.
  ///
  /// In en, this message translates to:
  /// **'Failed to save objective. Please try again.'**
  String get saveObjectiveError;

  /// No description provided for @fitPreference.
  ///
  /// In en, this message translates to:
  /// **'Fit Preference'**
  String get fitPreference;

  /// No description provided for @howDoYouPreferClothesToFit.
  ///
  /// In en, this message translates to:
  /// **'How do you prefer your clothes to fit?'**
  String get howDoYouPreferClothesToFit;

  /// No description provided for @loose.
  ///
  /// In en, this message translates to:
  /// **'Loose'**
  String get loose;

  /// No description provided for @comfortableRelaxedFit.
  ///
  /// In en, this message translates to:
  /// **'Comfortable, relaxed fit'**
  String get comfortableRelaxedFit;

  /// No description provided for @regular.
  ///
  /// In en, this message translates to:
  /// **'Regular'**
  String get regular;

  /// No description provided for @standardComfortableFit.
  ///
  /// In en, this message translates to:
  /// **'Standard, comfortable fit'**
  String get standardComfortableFit;

  /// No description provided for @tight.
  ///
  /// In en, this message translates to:
  /// **'Tight'**
  String get tight;

  /// No description provided for @formFittingTailoredLook.
  ///
  /// In en, this message translates to:
  /// **'Form-fitting, tailored look'**
  String get formFittingTailoredLook;

  /// No description provided for @selectFitError.
  ///
  /// In en, this message translates to:
  /// **'Please select a fit preference'**
  String get selectFitError;

  /// No description provided for @saveFitError.
  ///
  /// In en, this message translates to:
  /// **'Failed to save fit preference. Please try again.'**
  String get saveFitError;

  /// No description provided for @sizeProfile.
  ///
  /// In en, this message translates to:
  /// **'Size Profile'**
  String get sizeProfile;

  /// No description provided for @helpUsRecommendPerfectSizes.
  ///
  /// In en, this message translates to:
  /// **'Help us recommend the perfect sizes for you'**
  String get helpUsRecommendPerfectSizes;

  /// No description provided for @height.
  ///
  /// In en, this message translates to:
  /// **'Height'**
  String get height;

  /// No description provided for @weight.
  ///
  /// In en, this message translates to:
  /// **'Weight'**
  String get weight;

  /// No description provided for @bodyType.
  ///
  /// In en, this message translates to:
  /// **'Body Type'**
  String get bodyType;

  /// No description provided for @selectBodyTypeHelpRecommend.
  ///
  /// In en, this message translates to:
  /// **'Select your body type to help us recommend the most flattering styles'**
  String get selectBodyTypeHelpRecommend;

  /// No description provided for @hourglass.
  ///
  /// In en, this message translates to:
  /// **'Hourglass'**
  String get hourglass;

  /// No description provided for @hourglassDescription.
  ///
  /// In en, this message translates to:
  /// **'Waist is the narrowest part of frame'**
  String get hourglassDescription;

  /// No description provided for @triangle.
  ///
  /// In en, this message translates to:
  /// **'Triangle'**
  String get triangle;

  /// No description provided for @triangleDescription.
  ///
  /// In en, this message translates to:
  /// **'Hips are broader than shoulders'**
  String get triangleDescription;

  /// No description provided for @rectangle.
  ///
  /// In en, this message translates to:
  /// **'Rectangle'**
  String get rectangle;

  /// No description provided for @rectangleDescription.
  ///
  /// In en, this message translates to:
  /// **'Hips, shoulders and waist are the same proportion'**
  String get rectangleDescription;

  /// No description provided for @oval.
  ///
  /// In en, this message translates to:
  /// **'Oval'**
  String get oval;

  /// No description provided for @ovalDescription.
  ///
  /// In en, this message translates to:
  /// **'Hips and shoulders are narrower than waist'**
  String get ovalDescription;

  /// No description provided for @heart.
  ///
  /// In en, this message translates to:
  /// **'Heart'**
  String get heart;

  /// No description provided for @heartDescription.
  ///
  /// In en, this message translates to:
  /// **'Hips are narrower than shoulders'**
  String get heartDescription;

  /// No description provided for @selectBodyTypeError.
  ///
  /// In en, this message translates to:
  /// **'Please select your body type'**
  String get selectBodyTypeError;

  /// No description provided for @saveBodyTypeError.
  ///
  /// In en, this message translates to:
  /// **'Failed to save body type. Please try again.'**
  String get saveBodyTypeError;

  /// No description provided for @yourSizes.
  ///
  /// In en, this message translates to:
  /// **'Your Sizes'**
  String get yourSizes;

  /// No description provided for @enterSizesForBetterRecommendations.
  ///
  /// In en, this message translates to:
  /// **'Enter your sizes for better recommendations'**
  String get enterSizesForBetterRecommendations;

  /// No description provided for @whatSizesTypicallyWear.
  ///
  /// In en, this message translates to:
  /// **'What sizes do you typically wear?'**
  String get whatSizesTypicallyWear;

  /// No description provided for @helpsShowPerfectlyFittedItems.
  ///
  /// In en, this message translates to:
  /// **'This helps us show you perfectly fitted items'**
  String get helpsShowPerfectlyFittedItems;

  /// No description provided for @tops.
  ///
  /// In en, this message translates to:
  /// **'Tops'**
  String get tops;

  /// No description provided for @bottoms.
  ///
  /// In en, this message translates to:
  /// **'Bottoms'**
  String get bottoms;

  /// No description provided for @dresses.
  ///
  /// In en, this message translates to:
  /// **'Dresses'**
  String get dresses;

  /// No description provided for @jeanWaist.
  ///
  /// In en, this message translates to:
  /// **'Jean Waist'**
  String get jeanWaist;

  /// No description provided for @braBand.
  ///
  /// In en, this message translates to:
  /// **'Bra Band'**
  String get braBand;

  /// No description provided for @braCup.
  ///
  /// In en, this message translates to:
  /// **'Bra Cup'**
  String get braCup;

  /// No description provided for @shoeSize.
  ///
  /// In en, this message translates to:
  /// **'Shoe Size'**
  String get shoeSize;

  /// No description provided for @budgetPreference.
  ///
  /// In en, this message translates to:
  /// **'Budget Preference'**
  String get budgetPreference;

  /// No description provided for @whatsYourIdealPriceRange.
  ///
  /// In en, this message translates to:
  /// **'What\'s your ideal price range for fashion items?'**
  String get whatsYourIdealPriceRange;

  /// No description provided for @whatsYourBudgetRange.
  ///
  /// In en, this message translates to:
  /// **'What\'s your budget range?'**
  String get whatsYourBudgetRange;

  /// No description provided for @showItemsWithinPriceRange.
  ///
  /// In en, this message translates to:
  /// **'We\'ll show you items within your price range'**
  String get showItemsWithinPriceRange;

  /// No description provided for @budgetFriendly.
  ///
  /// In en, this message translates to:
  /// **'Budget Friendly'**
  String get budgetFriendly;

  /// No description provided for @under500k.
  ///
  /// In en, this message translates to:
  /// **'Under 500,000 UZS'**
  String get under500k;

  /// No description provided for @moderate.
  ///
  /// In en, this message translates to:
  /// **'Moderate'**
  String get moderate;

  /// No description provided for @range500kTo1500k.
  ///
  /// In en, this message translates to:
  /// **'500,000 - 1,500,000 UZS'**
  String get range500kTo1500k;

  /// No description provided for @premium.
  ///
  /// In en, this message translates to:
  /// **'Premium'**
  String get premium;

  /// No description provided for @range1500kTo3000k.
  ///
  /// In en, this message translates to:
  /// **'1,500,000 - 3,000,000 UZS'**
  String get range1500kTo3000k;

  /// No description provided for @luxury.
  ///
  /// In en, this message translates to:
  /// **'Luxury'**
  String get luxury;

  /// No description provided for @over3000k.
  ///
  /// In en, this message translates to:
  /// **'Over 3,000,000 UZS'**
  String get over3000k;

  /// No description provided for @flexible.
  ///
  /// In en, this message translates to:
  /// **'Flexible'**
  String get flexible;

  /// No description provided for @showMeEverything.
  ///
  /// In en, this message translates to:
  /// **'Show me everything'**
  String get showMeEverything;

  /// No description provided for @changeAnytimeInSettings.
  ///
  /// In en, this message translates to:
  /// **'You can change this anytime in settings'**
  String get changeAnytimeInSettings;

  /// No description provided for @setBudgetPreferences.
  ///
  /// In en, this message translates to:
  /// **'Set your budget\npreferences'**
  String get setBudgetPreferences;

  /// No description provided for @choosePriceRange.
  ///
  /// In en, this message translates to:
  /// **'Choose your price range for each category'**
  String get choosePriceRange;

  /// No description provided for @budgetUnder500k.
  ///
  /// In en, this message translates to:
  /// **'Under 500,000 UZS'**
  String get budgetUnder500k;

  /// No description provided for @budget500kTo1m.
  ///
  /// In en, this message translates to:
  /// **'500,000 to 1,000,000 UZS'**
  String get budget500kTo1m;

  /// No description provided for @budget1mTo1_5m.
  ///
  /// In en, this message translates to:
  /// **'1,000,000 to 1,500,000 UZS'**
  String get budget1mTo1_5m;

  /// No description provided for @budget1_5mTo2m.
  ///
  /// In en, this message translates to:
  /// **'1,500,000 to 2,000,000 UZS'**
  String get budget1_5mTo2m;

  /// No description provided for @budget2mPlus.
  ///
  /// In en, this message translates to:
  /// **'2,000,000+ UZS'**
  String get budget2mPlus;

  /// No description provided for @categoryTops.
  ///
  /// In en, this message translates to:
  /// **'Tops'**
  String get categoryTops;

  /// No description provided for @categoryBottoms.
  ///
  /// In en, this message translates to:
  /// **'Bottoms'**
  String get categoryBottoms;

  /// No description provided for @categoryJacketsCoats.
  ///
  /// In en, this message translates to:
  /// **'Jackets & Coats'**
  String get categoryJacketsCoats;

  /// No description provided for @categoryDresses.
  ///
  /// In en, this message translates to:
  /// **'Dresses'**
  String get categoryDresses;

  /// No description provided for @categoryShoes.
  ///
  /// In en, this message translates to:
  /// **'Shoes'**
  String get categoryShoes;

  /// No description provided for @categoryAccessories.
  ///
  /// In en, this message translates to:
  /// **'Accessories'**
  String get categoryAccessories;

  /// No description provided for @categoryJewelry.
  ///
  /// In en, this message translates to:
  /// **'Jewelry'**
  String get categoryJewelry;

  /// No description provided for @completeSetup.
  ///
  /// In en, this message translates to:
  /// **'Complete Setup'**
  String get completeSetup;

  /// No description provided for @authenticationRequired.
  ///
  /// In en, this message translates to:
  /// **'Authentication required. Please login first.'**
  String get authenticationRequired;

  /// No description provided for @pleaseCompleteAllFields.
  ///
  /// In en, this message translates to:
  /// **'Please complete all required fields'**
  String get pleaseCompleteAllFields;

  /// No description provided for @failedToCreateProfile.
  ///
  /// In en, this message translates to:
  /// **'Failed to create profile'**
  String get failedToCreateProfile;

  /// No description provided for @styleQuiz.
  ///
  /// In en, this message translates to:
  /// **'Style Quiz'**
  String get styleQuiz;

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// No description provided for @pass.
  ///
  /// In en, this message translates to:
  /// **'Pass'**
  String get pass;

  /// No description provided for @info.
  ///
  /// In en, this message translates to:
  /// **'Info'**
  String get info;

  /// No description provided for @like.
  ///
  /// In en, this message translates to:
  /// **'Like'**
  String get like;

  /// No description provided for @analyzingYourStyle.
  ///
  /// In en, this message translates to:
  /// **'Analyzing your style...'**
  String get analyzingYourStyle;

  /// No description provided for @gotIt.
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get gotIt;

  /// No description provided for @discoverYourStylePreference.
  ///
  /// In en, this message translates to:
  /// **'Discover your style preference'**
  String get discoverYourStylePreference;

  /// No description provided for @casualWear.
  ///
  /// In en, this message translates to:
  /// **'Casual Wear'**
  String get casualWear;

  /// No description provided for @businessFormal.
  ///
  /// In en, this message translates to:
  /// **'Business Formal'**
  String get businessFormal;

  /// No description provided for @streetwear.
  ///
  /// In en, this message translates to:
  /// **'Streetwear'**
  String get streetwear;

  /// No description provided for @athleticWear.
  ///
  /// In en, this message translates to:
  /// **'Athletic Wear'**
  String get athleticWear;

  /// No description provided for @vintageFashion.
  ///
  /// In en, this message translates to:
  /// **'Vintage Fashion'**
  String get vintageFashion;

  /// No description provided for @minimalist.
  ///
  /// In en, this message translates to:
  /// **'Minimalist'**
  String get minimalist;

  /// No description provided for @boldPatterns.
  ///
  /// In en, this message translates to:
  /// **'Bold Patterns'**
  String get boldPatterns;

  /// No description provided for @bohemian.
  ///
  /// In en, this message translates to:
  /// **'Bohemian'**
  String get bohemian;

  /// No description provided for @elegantEvening.
  ///
  /// In en, this message translates to:
  /// **'Elegant Evening'**
  String get elegantEvening;

  /// No description provided for @smartCasual.
  ///
  /// In en, this message translates to:
  /// **'Smart Casual'**
  String get smartCasual;

  /// No description provided for @modernChic.
  ///
  /// In en, this message translates to:
  /// **'Modern Chic'**
  String get modernChic;

  /// No description provided for @classicStyle.
  ///
  /// In en, this message translates to:
  /// **'Classic Style'**
  String get classicStyle;

  /// No description provided for @trendy.
  ///
  /// In en, this message translates to:
  /// **'Trendy'**
  String get trendy;

  /// No description provided for @sporty.
  ///
  /// In en, this message translates to:
  /// **'Sporty'**
  String get sporty;

  /// No description provided for @sophisticated.
  ///
  /// In en, this message translates to:
  /// **'Sophisticated'**
  String get sophisticated;

  /// No description provided for @comfortable.
  ///
  /// In en, this message translates to:
  /// **'Comfortable'**
  String get comfortable;

  /// No description provided for @dressy.
  ///
  /// In en, this message translates to:
  /// **'Dressy'**
  String get dressy;

  /// No description provided for @everyday.
  ///
  /// In en, this message translates to:
  /// **'Everyday'**
  String get everyday;

  /// No description provided for @weekend.
  ///
  /// In en, this message translates to:
  /// **'Weekend'**
  String get weekend;

  /// No description provided for @office.
  ///
  /// In en, this message translates to:
  /// **'Office'**
  String get office;

  /// No description provided for @evening.
  ///
  /// In en, this message translates to:
  /// **'Evening'**
  String get evening;

  /// No description provided for @casualChic.
  ///
  /// In en, this message translates to:
  /// **'Casual Chic'**
  String get casualChic;

  /// No description provided for @urban.
  ///
  /// In en, this message translates to:
  /// **'Urban'**
  String get urban;

  /// No description provided for @contemporary.
  ///
  /// In en, this message translates to:
  /// **'Contemporary'**
  String get contemporary;

  /// No description provided for @timeless.
  ///
  /// In en, this message translates to:
  /// **'Timeless'**
  String get timeless;

  /// No description provided for @fashionForward.
  ///
  /// In en, this message translates to:
  /// **'Fashion Forward'**
  String get fashionForward;

  /// No description provided for @relaxed.
  ///
  /// In en, this message translates to:
  /// **'Relaxed'**
  String get relaxed;

  /// No description provided for @polished.
  ///
  /// In en, this message translates to:
  /// **'Polished'**
  String get polished;

  /// No description provided for @effortless.
  ///
  /// In en, this message translates to:
  /// **'Effortless'**
  String get effortless;

  /// No description provided for @statement.
  ///
  /// In en, this message translates to:
  /// **'Statement'**
  String get statement;

  /// No description provided for @selectBudgetError.
  ///
  /// In en, this message translates to:
  /// **'Please select a budget range'**
  String get selectBudgetError;

  /// No description provided for @saveBudgetError.
  ///
  /// In en, this message translates to:
  /// **'Failed to save budget preference. Please try again.'**
  String get saveBudgetError;

  /// No description provided for @completeOnboarding.
  ///
  /// In en, this message translates to:
  /// **'Complete Setup'**
  String get completeOnboarding;

  /// No description provided for @readyToStartShopping.
  ///
  /// In en, this message translates to:
  /// **'You\'re all set! Ready to start shopping?'**
  String get readyToStartShopping;

  /// No description provided for @letsGo.
  ///
  /// In en, this message translates to:
  /// **'Let\'s Go!'**
  String get letsGo;

  /// No description provided for @completionError.
  ///
  /// In en, this message translates to:
  /// **'Failed to complete setup. Please try again.'**
  String get completionError;

  /// No description provided for @youreAllSet.
  ///
  /// In en, this message translates to:
  /// **'You\'re All Set! 🎉'**
  String get youreAllSet;

  /// No description provided for @preparingYourFeed.
  ///
  /// In en, this message translates to:
  /// **'Preparing your personalized feed...'**
  String get preparingYourFeed;

  /// No description provided for @startDiscoveringFashion.
  ///
  /// In en, this message translates to:
  /// **'Start discovering\nfashion made for you'**
  String get startDiscoveringFashion;

  /// No description provided for @startExploring.
  ///
  /// In en, this message translates to:
  /// **'Start Exploring'**
  String get startExploring;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @filter.
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get filter;

  /// No description provided for @sort.
  ///
  /// In en, this message translates to:
  /// **'Sort'**
  String get sort;

  /// No description provided for @apply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get apply;

  /// No description provided for @reset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get reset;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @success.
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get success;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try Again'**
  String get tryAgain;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @welcomeToSwipe.
  ///
  /// In en, this message translates to:
  /// **'Welcome to SVAYP'**
  String get welcomeToSwipe;

  /// No description provided for @discoverYourStyle.
  ///
  /// In en, this message translates to:
  /// **'Discover your perfect style with AI-powered fashion recommendations'**
  String get discoverYourStyle;

  /// No description provided for @selectLanguage.
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get selectLanguage;

  /// No description provided for @continueText.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueText;

  /// No description provided for @verificationCode.
  ///
  /// In en, this message translates to:
  /// **'Verification Code'**
  String get verificationCode;

  /// No description provided for @enterVerificationCode.
  ///
  /// In en, this message translates to:
  /// **'Enter the verification code sent to'**
  String get enterVerificationCode;

  /// No description provided for @verifying.
  ///
  /// In en, this message translates to:
  /// **'Verifying...'**
  String get verifying;

  /// No description provided for @invalidPhoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Invalid phone number'**
  String get invalidPhoneNumber;

  /// No description provided for @invalidVerificationCode.
  ///
  /// In en, this message translates to:
  /// **'Invalid verification code'**
  String get invalidVerificationCode;

  /// No description provided for @discover.
  ///
  /// In en, this message translates to:
  /// **'Discover'**
  String get discover;

  /// No description provided for @forYou.
  ///
  /// In en, this message translates to:
  /// **'For You'**
  String get forYou;

  /// No description provided for @swipeRightToLike.
  ///
  /// In en, this message translates to:
  /// **'Swipe Right to Like'**
  String get swipeRightToLike;

  /// No description provided for @swipeLeftToPass.
  ///
  /// In en, this message translates to:
  /// **'Swipe Left to Pass'**
  String get swipeLeftToPass;

  /// No description provided for @swipeUpToAddToCart.
  ///
  /// In en, this message translates to:
  /// **'Swipe up to add to cart'**
  String get swipeUpToAddToCart;

  /// No description provided for @addedToCart.
  ///
  /// In en, this message translates to:
  /// **'Added to cart!'**
  String get addedToCart;

  /// No description provided for @viewCart.
  ///
  /// In en, this message translates to:
  /// **'View Cart'**
  String get viewCart;

  /// No description provided for @failedToLoadProducts.
  ///
  /// In en, this message translates to:
  /// **'Failed to load products'**
  String get failedToLoadProducts;

  /// No description provided for @passed.
  ///
  /// In en, this message translates to:
  /// **'Passed'**
  String get passed;

  /// No description provided for @addedToLiked.
  ///
  /// In en, this message translates to:
  /// **'Added to liked!'**
  String get addedToLiked;

  /// No description provided for @liked.
  ///
  /// In en, this message translates to:
  /// **'Liked'**
  String get liked;

  /// No description provided for @likedItems.
  ///
  /// In en, this message translates to:
  /// **'Liked Items'**
  String get likedItems;

  /// No description provided for @saved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get saved;

  /// No description provided for @noLikedItemsYet.
  ///
  /// In en, this message translates to:
  /// **'No Liked Items Yet'**
  String get noLikedItemsYet;

  /// No description provided for @startSwipingAndSave.
  ///
  /// In en, this message translates to:
  /// **'Start swiping and save items you love'**
  String get startSwipingAndSave;

  /// No description provided for @clearAll.
  ///
  /// In en, this message translates to:
  /// **'Clear All'**
  String get clearAll;

  /// No description provided for @clearedAllLikedItems.
  ///
  /// In en, this message translates to:
  /// **'Cleared all liked items'**
  String get clearedAllLikedItems;

  /// No description provided for @removedItem.
  ///
  /// In en, this message translates to:
  /// **'Removed {item}'**
  String removedItem(String item);

  /// No description provided for @undo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get undo;

  /// No description provided for @undoNotImplemented.
  ///
  /// In en, this message translates to:
  /// **'Undo feature not implemented yet'**
  String get undoNotImplemented;

  /// No description provided for @removeFromLiked.
  ///
  /// In en, this message translates to:
  /// **'Remove from liked?'**
  String get removeFromLiked;

  /// No description provided for @removeFromLikedMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to remove this item from your liked collection?'**
  String get removeFromLikedMessage;

  /// No description provided for @remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// No description provided for @shop.
  ///
  /// In en, this message translates to:
  /// **'Shop'**
  String get shop;

  /// No description provided for @categories.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get categories;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @clothing.
  ///
  /// In en, this message translates to:
  /// **'Clothing'**
  String get clothing;

  /// No description provided for @shoes.
  ///
  /// In en, this message translates to:
  /// **'Shoes'**
  String get shoes;

  /// No description provided for @accessories.
  ///
  /// In en, this message translates to:
  /// **'Accessories'**
  String get accessories;

  /// No description provided for @coverage.
  ///
  /// In en, this message translates to:
  /// **'Coverage'**
  String get coverage;

  /// No description provided for @searchForClothes.
  ///
  /// In en, this message translates to:
  /// **'Ask me anything...'**
  String get searchForClothes;

  /// No description provided for @trending.
  ///
  /// In en, this message translates to:
  /// **'Trending'**
  String get trending;

  /// No description provided for @newItems.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get newItems;

  /// No description provided for @sale.
  ///
  /// In en, this message translates to:
  /// **'Sale'**
  String get sale;

  /// No description provided for @aiScan.
  ///
  /// In en, this message translates to:
  /// **'Visual Search'**
  String get aiScan;

  /// No description provided for @noProductsFound.
  ///
  /// In en, this message translates to:
  /// **'No products found'**
  String get noProductsFound;

  /// No description provided for @tryDifferentFilters.
  ///
  /// In en, this message translates to:
  /// **'Try adjusting your search or filters'**
  String get tryDifferentFilters;

  /// No description provided for @tryAdjustingFilters.
  ///
  /// In en, this message translates to:
  /// **'Try adjusting your filters'**
  String get tryAdjustingFilters;

  /// No description provided for @cart.
  ///
  /// In en, this message translates to:
  /// **'Shopping Cart'**
  String get cart;

  /// No description provided for @myCart.
  ///
  /// In en, this message translates to:
  /// **'My Cart'**
  String get myCart;

  /// No description provided for @cartEmpty.
  ///
  /// In en, this message translates to:
  /// **'Your cart is empty'**
  String get cartEmpty;

  /// No description provided for @startShoppingNow.
  ///
  /// In en, this message translates to:
  /// **'Start shopping now'**
  String get startShoppingNow;

  /// No description provided for @item.
  ///
  /// In en, this message translates to:
  /// **'Item'**
  String get item;

  /// No description provided for @subtotal.
  ///
  /// In en, this message translates to:
  /// **'Subtotal'**
  String get subtotal;

  /// No description provided for @tax.
  ///
  /// In en, this message translates to:
  /// **'Tax'**
  String get tax;

  /// No description provided for @delivery.
  ///
  /// In en, this message translates to:
  /// **'Delivery'**
  String get delivery;

  /// No description provided for @proceedToCheckout.
  ///
  /// In en, this message translates to:
  /// **'Proceed to Checkout'**
  String get proceedToCheckout;

  /// No description provided for @removeFromCart.
  ///
  /// In en, this message translates to:
  /// **'Remove from cart?'**
  String get removeFromCart;

  /// No description provided for @removeFromCartMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to remove this item?'**
  String get removeFromCartMessage;

  /// No description provided for @clearCart.
  ///
  /// In en, this message translates to:
  /// **'Clear Cart'**
  String get clearCart;

  /// No description provided for @clearCartMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to clear all items from your cart?'**
  String get clearCartMessage;

  /// No description provided for @productDetails.
  ///
  /// In en, this message translates to:
  /// **'Product Details'**
  String get productDetails;

  /// No description provided for @size.
  ///
  /// In en, this message translates to:
  /// **'Size'**
  String get size;

  /// No description provided for @selectSize.
  ///
  /// In en, this message translates to:
  /// **'Select Size'**
  String get selectSize;

  /// No description provided for @selectSizeAndColor.
  ///
  /// In en, this message translates to:
  /// **'Select Size & Color'**
  String get selectSizeAndColor;

  /// No description provided for @thatsAllForNow.
  ///
  /// In en, this message translates to:
  /// **'That\'s All for Now!'**
  String get thatsAllForNow;

  /// No description provided for @findingMoreItems.
  ///
  /// In en, this message translates to:
  /// **'We\'re finding more items you\'ll love'**
  String get findingMoreItems;

  /// No description provided for @refreshFeed.
  ///
  /// In en, this message translates to:
  /// **'Refresh Feed'**
  String get refreshFeed;

  /// No description provided for @pleaseSelectSize.
  ///
  /// In en, this message translates to:
  /// **'Please select a size'**
  String get pleaseSelectSize;

  /// No description provided for @pleaseSelectColor.
  ///
  /// In en, this message translates to:
  /// **'Please select a color'**
  String get pleaseSelectColor;

  /// No description provided for @oneSize.
  ///
  /// In en, this message translates to:
  /// **'One Size'**
  String get oneSize;

  /// No description provided for @color.
  ///
  /// In en, this message translates to:
  /// **'Color'**
  String get color;

  /// No description provided for @selectColor.
  ///
  /// In en, this message translates to:
  /// **'Select Color'**
  String get selectColor;

  /// No description provided for @description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// No description provided for @reviews.
  ///
  /// In en, this message translates to:
  /// **'Reviews'**
  String get reviews;

  /// No description provided for @reviewsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} reviews'**
  String reviewsCount(int count);

  /// No description provided for @seeAll.
  ///
  /// In en, this message translates to:
  /// **'See All'**
  String get seeAll;

  /// No description provided for @rating.
  ///
  /// In en, this message translates to:
  /// **'Rating'**
  String get rating;

  /// No description provided for @addToCart.
  ///
  /// In en, this message translates to:
  /// **'Add to Cart'**
  String get addToCart;

  /// No description provided for @checkAvailability.
  ///
  /// In en, this message translates to:
  /// **'Check Availability'**
  String get checkAvailability;

  /// No description provided for @buyNow.
  ///
  /// In en, this message translates to:
  /// **'Buy Now'**
  String get buyNow;

  /// No description provided for @inStock.
  ///
  /// In en, this message translates to:
  /// **'In Stock'**
  String get inStock;

  /// No description provided for @outOfStock.
  ///
  /// In en, this message translates to:
  /// **'Out of Stock'**
  String get outOfStock;

  /// No description provided for @newLabel.
  ///
  /// In en, this message translates to:
  /// **'NEW'**
  String get newLabel;

  /// No description provided for @category.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category;

  /// No description provided for @seller.
  ///
  /// In en, this message translates to:
  /// **'Seller'**
  String get seller;

  /// No description provided for @availability.
  ///
  /// In en, this message translates to:
  /// **'Availability'**
  String get availability;

  /// No description provided for @fitMatch.
  ///
  /// In en, this message translates to:
  /// **'Fit Match'**
  String get fitMatch;

  /// No description provided for @styleMatch.
  ///
  /// In en, this message translates to:
  /// **'Style Match'**
  String get styleMatch;

  /// No description provided for @addedToLikedItems.
  ///
  /// In en, this message translates to:
  /// **'Added to liked items'**
  String get addedToLikedItems;

  /// No description provided for @similarProducts.
  ///
  /// In en, this message translates to:
  /// **'Similar Products'**
  String get similarProducts;

  /// No description provided for @visualSearch.
  ///
  /// In en, this message translates to:
  /// **'Visual Search'**
  String get visualSearch;

  /// No description provided for @visualSearchResults.
  ///
  /// In en, this message translates to:
  /// **'Visual Search Results'**
  String get visualSearchResults;

  /// No description provided for @searchResults.
  ///
  /// In en, this message translates to:
  /// **'Search Results'**
  String get searchResults;

  /// No description provided for @sellers.
  ///
  /// In en, this message translates to:
  /// **'Sellers'**
  String get sellers;

  /// No description provided for @productsFound.
  ///
  /// In en, this message translates to:
  /// **'products found'**
  String get productsFound;

  /// No description provided for @tryDifferentSearch.
  ///
  /// In en, this message translates to:
  /// **'Try searching with different keywords'**
  String get tryDifferentSearch;

  /// No description provided for @yourSearchImage.
  ///
  /// In en, this message translates to:
  /// **'Your Search Image'**
  String get yourSearchImage;

  /// No description provided for @analyzingImageWithAI.
  ///
  /// In en, this message translates to:
  /// **'Analyzing image with AI...\nThis may take a few seconds'**
  String get analyzingImageWithAI;

  /// No description provided for @aiAnalysis.
  ///
  /// In en, this message translates to:
  /// **'AI Analysis'**
  String get aiAnalysis;

  /// No description provided for @similarProductsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} Similar Products'**
  String similarProductsCount(int count);

  /// No description provided for @hijabAppropriate.
  ///
  /// In en, this message translates to:
  /// **'Hijab Appropriate'**
  String get hijabAppropriate;

  /// No description provided for @visualSearchFailed.
  ///
  /// In en, this message translates to:
  /// **'Visual search failed: {error}'**
  String visualSearchFailed(String error);

  /// No description provided for @orders.
  ///
  /// In en, this message translates to:
  /// **'Orders'**
  String get orders;

  /// No description provided for @myOrders.
  ///
  /// In en, this message translates to:
  /// **'My Orders'**
  String get myOrders;

  /// No description provided for @orderHistory.
  ///
  /// In en, this message translates to:
  /// **'Order History'**
  String get orderHistory;

  /// No description provided for @orderHistoryAppearHere.
  ///
  /// In en, this message translates to:
  /// **'Your order history will appear here'**
  String get orderHistoryAppearHere;

  /// No description provided for @noOrdersYet.
  ///
  /// In en, this message translates to:
  /// **'No Orders Yet'**
  String get noOrdersYet;

  /// No description provided for @startShoppingToSeeOrders.
  ///
  /// In en, this message translates to:
  /// **'Start shopping to see your order history here'**
  String get startShoppingToSeeOrders;

  /// No description provided for @startShopping.
  ///
  /// In en, this message translates to:
  /// **'Start Shopping'**
  String get startShopping;

  /// No description provided for @itemsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} items'**
  String itemsCount(int count);

  /// No description provided for @totalAmount.
  ///
  /// In en, this message translates to:
  /// **'Total Amount'**
  String get totalAmount;

  /// No description provided for @viewDetails.
  ///
  /// In en, this message translates to:
  /// **'View Details'**
  String get viewDetails;

  /// No description provided for @orderNumber.
  ///
  /// In en, this message translates to:
  /// **'Order #'**
  String get orderNumber;

  /// No description provided for @orderDate.
  ///
  /// In en, this message translates to:
  /// **'Order Date'**
  String get orderDate;

  /// No description provided for @orderStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get orderStatus;

  /// No description provided for @orderTotal.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get orderTotal;

  /// No description provided for @trackOrder.
  ///
  /// In en, this message translates to:
  /// **'Track Order'**
  String get trackOrder;

  /// No description provided for @orderDetails.
  ///
  /// In en, this message translates to:
  /// **'Order Details'**
  String get orderDetails;

  /// No description provided for @cancelOrder.
  ///
  /// In en, this message translates to:
  /// **'Cancel Order'**
  String get cancelOrder;

  /// No description provided for @pending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pending;

  /// No description provided for @confirmed.
  ///
  /// In en, this message translates to:
  /// **'Confirmed'**
  String get confirmed;

  /// No description provided for @processing.
  ///
  /// In en, this message translates to:
  /// **'Processing'**
  String get processing;

  /// No description provided for @shipped.
  ///
  /// In en, this message translates to:
  /// **'Shipped'**
  String get shipped;

  /// No description provided for @outForDelivery.
  ///
  /// In en, this message translates to:
  /// **'Out for Delivery'**
  String get outForDelivery;

  /// No description provided for @delivered.
  ///
  /// In en, this message translates to:
  /// **'Delivered'**
  String get delivered;

  /// No description provided for @cancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get cancelled;

  /// No description provided for @chat.
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get chat;

  /// No description provided for @noMessagesYet.
  ///
  /// In en, this message translates to:
  /// **'No Messages Yet'**
  String get noMessagesYet;

  /// No description provided for @contactSellersFromProduct.
  ///
  /// In en, this message translates to:
  /// **'Contact sellers from product details to ask about availability, sizes, and more'**
  String get contactSellersFromProduct;

  /// No description provided for @aboutProduct.
  ///
  /// In en, this message translates to:
  /// **'About: {productName}'**
  String aboutProduct(String productName);

  /// No description provided for @minutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{minutes}m ago'**
  String minutesAgo(int minutes);

  /// No description provided for @hoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{hours}h ago'**
  String hoursAgo(int hours);

  /// No description provided for @daysAgo.
  ///
  /// In en, this message translates to:
  /// **'{days}d ago'**
  String daysAgo(int days);

  /// No description provided for @yesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get yesterday;

  /// No description provided for @interestedInProduct.
  ///
  /// In en, this message translates to:
  /// **'Hello! I\'m interested in this product. Is it available?'**
  String get interestedInProduct;

  /// No description provided for @sellerAutoResponse.
  ///
  /// In en, this message translates to:
  /// **'Thank you for your message! I\'ll check and get back to you shortly.'**
  String get sellerAutoResponse;

  /// No description provided for @typeMessage.
  ///
  /// In en, this message translates to:
  /// **'Type a message...'**
  String get typeMessage;

  /// No description provided for @sendMessage.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get sendMessage;

  /// No description provided for @checkout.
  ///
  /// In en, this message translates to:
  /// **'Checkout'**
  String get checkout;

  /// No description provided for @shippingAddress.
  ///
  /// In en, this message translates to:
  /// **'Shipping Address'**
  String get shippingAddress;

  /// No description provided for @deliveryAddress.
  ///
  /// In en, this message translates to:
  /// **'Delivery Address'**
  String get deliveryAddress;

  /// No description provided for @selectAddress.
  ///
  /// In en, this message translates to:
  /// **'Select Address'**
  String get selectAddress;

  /// No description provided for @noAddressSelected.
  ///
  /// In en, this message translates to:
  /// **'No address selected'**
  String get noAddressSelected;

  /// No description provided for @changeAddress.
  ///
  /// In en, this message translates to:
  /// **'Change Address'**
  String get changeAddress;

  /// No description provided for @addNewAddress.
  ///
  /// In en, this message translates to:
  /// **'Add New Address'**
  String get addNewAddress;

  /// No description provided for @deliveryMethod.
  ///
  /// In en, this message translates to:
  /// **'Delivery Method'**
  String get deliveryMethod;

  /// No description provided for @pickupInStore.
  ///
  /// In en, this message translates to:
  /// **'Pick up in store'**
  String get pickupInStore;

  /// No description provided for @availableForPickup.
  ///
  /// In en, this message translates to:
  /// **'Available for pickup'**
  String get availableForPickup;

  /// No description provided for @standard.
  ///
  /// In en, this message translates to:
  /// **'Standard'**
  String get standard;

  /// No description provided for @express.
  ///
  /// In en, this message translates to:
  /// **'Express'**
  String get express;

  /// No description provided for @sameDay.
  ///
  /// In en, this message translates to:
  /// **'Same Day'**
  String get sameDay;

  /// No description provided for @businessDays.
  ///
  /// In en, this message translates to:
  /// **'business days'**
  String businessDays(int min, int max);

  /// No description provided for @tashkentOnly.
  ///
  /// In en, this message translates to:
  /// **'Tashkent only'**
  String get tashkentOnly;

  /// No description provided for @paymentMethod.
  ///
  /// In en, this message translates to:
  /// **'Payment Method'**
  String get paymentMethod;

  /// No description provided for @selectPaymentMethod.
  ///
  /// In en, this message translates to:
  /// **'Select Payment Method'**
  String get selectPaymentMethod;

  /// No description provided for @noPaymentMethodSelected.
  ///
  /// In en, this message translates to:
  /// **'No payment method selected'**
  String get noPaymentMethodSelected;

  /// No description provided for @addPayment.
  ///
  /// In en, this message translates to:
  /// **'Add Payment'**
  String get addPayment;

  /// No description provided for @changePayment.
  ///
  /// In en, this message translates to:
  /// **'Change Payment'**
  String get changePayment;

  /// No description provided for @addPaymentMethod.
  ///
  /// In en, this message translates to:
  /// **'Add Payment Method'**
  String get addPaymentMethod;

  /// No description provided for @paymentSelectionComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Payment selection feature coming soon'**
  String get paymentSelectionComingSoon;

  /// No description provided for @cashOnDelivery.
  ///
  /// In en, this message translates to:
  /// **'Cash on Delivery'**
  String get cashOnDelivery;

  /// No description provided for @payWhenYouReceive.
  ///
  /// In en, this message translates to:
  /// **'Pay when you receive your order'**
  String get payWhenYouReceive;

  /// No description provided for @qty.
  ///
  /// In en, this message translates to:
  /// **'Qty'**
  String get qty;

  /// No description provided for @pleaseSelectDeliveryAddress.
  ///
  /// In en, this message translates to:
  /// **'Please select a delivery address'**
  String get pleaseSelectDeliveryAddress;

  /// No description provided for @pleaseSelectPaymentMethod.
  ///
  /// In en, this message translates to:
  /// **'Please select a payment method'**
  String get pleaseSelectPaymentMethod;

  /// No description provided for @orderSummary.
  ///
  /// In en, this message translates to:
  /// **'Order Summary'**
  String get orderSummary;

  /// No description provided for @orderItems.
  ///
  /// In en, this message translates to:
  /// **'{count} order items'**
  String orderItems(int count);

  /// No description provided for @deliveryFee.
  ///
  /// In en, this message translates to:
  /// **'Delivery Fee'**
  String get deliveryFee;

  /// No description provided for @placeOrder.
  ///
  /// In en, this message translates to:
  /// **'Place Order'**
  String get placeOrder;

  /// No description provided for @errorPlacingOrder.
  ///
  /// In en, this message translates to:
  /// **'Error placing order: {error}'**
  String errorPlacingOrder(String error);

  /// No description provided for @orderPlaced.
  ///
  /// In en, this message translates to:
  /// **'Order Placed!'**
  String get orderPlaced;

  /// No description provided for @orderPlacedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Order placed successfully!'**
  String get orderPlacedSuccessfully;

  /// No description provided for @orderConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Your order has been successfully placed'**
  String get orderConfirmation;

  /// No description provided for @orderConfirmedMessage.
  ///
  /// In en, this message translates to:
  /// **'Thank you for your order! We\'ll send you updates as your order progresses.'**
  String get orderConfirmedMessage;

  /// No description provided for @orderConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Order Confirmed'**
  String get orderConfirmed;

  /// No description provided for @orderId.
  ///
  /// In en, this message translates to:
  /// **'Order ID'**
  String get orderId;

  /// No description provided for @continueShopping.
  ///
  /// In en, this message translates to:
  /// **'Continue Shopping'**
  String get continueShopping;

  /// No description provided for @estimatedDelivery.
  ///
  /// In en, this message translates to:
  /// **'Estimated Delivery'**
  String get estimatedDelivery;

  /// No description provided for @addresses.
  ///
  /// In en, this message translates to:
  /// **'Addresses'**
  String get addresses;

  /// No description provided for @myAddresses.
  ///
  /// In en, this message translates to:
  /// **'My Addresses'**
  String get myAddresses;

  /// No description provided for @noAddressesSaved.
  ///
  /// In en, this message translates to:
  /// **'No addresses saved yet'**
  String get noAddressesSaved;

  /// No description provided for @noAddresses.
  ///
  /// In en, this message translates to:
  /// **'No Addresses'**
  String get noAddresses;

  /// No description provided for @addDeliveryAddressToContinue.
  ///
  /// In en, this message translates to:
  /// **'Add a delivery address to continue'**
  String get addDeliveryAddressToContinue;

  /// No description provided for @addYourFirstAddress.
  ///
  /// In en, this message translates to:
  /// **'Add your first address for faster checkout'**
  String get addYourFirstAddress;

  /// No description provided for @addAddress.
  ///
  /// In en, this message translates to:
  /// **'Add Address'**
  String get addAddress;

  /// No description provided for @editAddress.
  ///
  /// In en, this message translates to:
  /// **'Edit Address'**
  String get editAddress;

  /// No description provided for @deleteAddress.
  ///
  /// In en, this message translates to:
  /// **'Delete Address'**
  String get deleteAddress;

  /// No description provided for @deleteAddressMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this address?'**
  String get deleteAddressMessage;

  /// No description provided for @addressDeleted.
  ///
  /// In en, this message translates to:
  /// **'Address deleted'**
  String get addressDeleted;

  /// No description provided for @defaultAddressUpdated.
  ///
  /// In en, this message translates to:
  /// **'Default address updated'**
  String get defaultAddressUpdated;

  /// No description provided for @setDefault.
  ///
  /// In en, this message translates to:
  /// **'Set Default'**
  String get setDefault;

  /// No description provided for @contactInformation.
  ///
  /// In en, this message translates to:
  /// **'Contact Information'**
  String get contactInformation;

  /// No description provided for @enterYourFullName.
  ///
  /// In en, this message translates to:
  /// **'Enter your full name'**
  String get enterYourFullName;

  /// No description provided for @pleaseEnterFullName.
  ///
  /// In en, this message translates to:
  /// **'Please enter your full name'**
  String get pleaseEnterFullName;

  /// No description provided for @phoneNumberShort.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phoneNumberShort;

  /// No description provided for @phoneNumberLabel.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phoneNumberLabel;

  /// No description provided for @phoneNumberHint.
  ///
  /// In en, this message translates to:
  /// **'+998 90 123 45 67'**
  String get phoneNumberHint;

  /// No description provided for @pleaseEnterPhoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Please enter your phone number'**
  String get pleaseEnterPhoneNumber;

  /// No description provided for @addressInformation.
  ///
  /// In en, this message translates to:
  /// **'Address Information'**
  String get addressInformation;

  /// No description provided for @streetAddress.
  ///
  /// In en, this message translates to:
  /// **'Street Address'**
  String get streetAddress;

  /// No description provided for @houseNumberAndStreetName.
  ///
  /// In en, this message translates to:
  /// **'House number and street name'**
  String get houseNumberAndStreetName;

  /// No description provided for @pleaseEnterStreetAddress.
  ///
  /// In en, this message translates to:
  /// **'Please enter street address'**
  String get pleaseEnterStreetAddress;

  /// No description provided for @apartmentUnitOptional.
  ///
  /// In en, this message translates to:
  /// **'Apartment/Unit (Optional)'**
  String get apartmentUnitOptional;

  /// No description provided for @aptSuiteUnitBuilding.
  ///
  /// In en, this message translates to:
  /// **'Apt, Suite, Unit, Building'**
  String get aptSuiteUnitBuilding;

  /// No description provided for @addressLine1.
  ///
  /// In en, this message translates to:
  /// **'Address Line 1'**
  String get addressLine1;

  /// No description provided for @addressLine2.
  ///
  /// In en, this message translates to:
  /// **'Address Line 2 (Optional)'**
  String get addressLine2;

  /// No description provided for @city.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get city;

  /// No description provided for @selectCity.
  ///
  /// In en, this message translates to:
  /// **'Select City'**
  String get selectCity;

  /// No description provided for @region.
  ///
  /// In en, this message translates to:
  /// **'Region'**
  String get region;

  /// No description provided for @regionDistrict.
  ///
  /// In en, this message translates to:
  /// **'Region/District'**
  String get regionDistrict;

  /// No description provided for @selectRegion.
  ///
  /// In en, this message translates to:
  /// **'Select Region'**
  String get selectRegion;

  /// No description provided for @postalCode.
  ///
  /// In en, this message translates to:
  /// **'Postal Code'**
  String get postalCode;

  /// No description provided for @postalCodeHint.
  ///
  /// In en, this message translates to:
  /// **'100000'**
  String get postalCodeHint;

  /// No description provided for @pleaseEnterPostalCode.
  ///
  /// In en, this message translates to:
  /// **'Please enter postal code'**
  String get pleaseEnterPostalCode;

  /// No description provided for @landmarkOptional.
  ///
  /// In en, this message translates to:
  /// **'Landmark (Optional)'**
  String get landmarkOptional;

  /// No description provided for @nearbyLandmarkForDelivery.
  ///
  /// In en, this message translates to:
  /// **'Nearby landmark for easier delivery'**
  String get nearbyLandmarkForDelivery;

  /// No description provided for @setAsDefault.
  ///
  /// In en, this message translates to:
  /// **'Set as default address'**
  String get setAsDefault;

  /// No description provided for @setAsDefaultAddressDescription.
  ///
  /// In en, this message translates to:
  /// **'This address will be used for all deliveries by default'**
  String get setAsDefaultAddressDescription;

  /// No description provided for @defaultAddress.
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get defaultAddress;

  /// No description provided for @saveAddress.
  ///
  /// In en, this message translates to:
  /// **'Save Address'**
  String get saveAddress;

  /// No description provided for @updateAddress.
  ///
  /// In en, this message translates to:
  /// **'Update Address'**
  String get updateAddress;

  /// No description provided for @errorSavingAddress.
  ///
  /// In en, this message translates to:
  /// **'Error saving address: {error}'**
  String errorSavingAddress(String error);

  /// No description provided for @fillAllFields.
  ///
  /// In en, this message translates to:
  /// **'Please fill all required fields'**
  String get fillAllFields;

  /// No description provided for @paymentMethods.
  ///
  /// In en, this message translates to:
  /// **'Payment Methods'**
  String get paymentMethods;

  /// No description provided for @myPaymentMethods.
  ///
  /// In en, this message translates to:
  /// **'My Payment Methods'**
  String get myPaymentMethods;

  /// No description provided for @noPaymentMethods.
  ///
  /// In en, this message translates to:
  /// **'No payment methods added'**
  String get noPaymentMethods;

  /// No description provided for @addYourFirstPaymentMethod.
  ///
  /// In en, this message translates to:
  /// **'Add a payment method for quick checkout'**
  String get addYourFirstPaymentMethod;

  /// No description provided for @payOnline.
  ///
  /// In en, this message translates to:
  /// **'Pay Online'**
  String get payOnline;

  /// No description provided for @cardNumber.
  ///
  /// In en, this message translates to:
  /// **'Card Number'**
  String get cardNumber;

  /// No description provided for @cardHolder.
  ///
  /// In en, this message translates to:
  /// **'Cardholder Name'**
  String get cardHolder;

  /// No description provided for @expiryDate.
  ///
  /// In en, this message translates to:
  /// **'Expiry Date'**
  String get expiryDate;

  /// No description provided for @cvv.
  ///
  /// In en, this message translates to:
  /// **'CVV'**
  String get cvv;

  /// No description provided for @saveCard.
  ///
  /// In en, this message translates to:
  /// **'Save Card'**
  String get saveCard;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @myProfile.
  ///
  /// In en, this message translates to:
  /// **'My Profile'**
  String get myProfile;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfile;

  /// No description provided for @editProfileComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Edit profile feature coming soon'**
  String get editProfileComingSoon;

  /// No description provided for @personalInfo.
  ///
  /// In en, this message translates to:
  /// **'Personal Information'**
  String get personalInfo;

  /// No description provided for @account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// No description provided for @savedItems.
  ///
  /// In en, this message translates to:
  /// **'Saved Items'**
  String get savedItems;

  /// No description provided for @accountSettings.
  ///
  /// In en, this message translates to:
  /// **'Account Settings'**
  String get accountSettings;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @changeLanguage.
  ///
  /// In en, this message translates to:
  /// **'Change Language'**
  String get changeLanguage;

  /// No description provided for @paymentMethodsComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Payment methods feature coming soon'**
  String get paymentMethodsComingSoon;

  /// No description provided for @preferences.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get preferences;

  /// No description provided for @darkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get darkMode;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @notificationsComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Notifications feature coming soon'**
  String get notificationsComingSoon;

  /// No description provided for @stylePreferences.
  ///
  /// In en, this message translates to:
  /// **'Style Preferences'**
  String get stylePreferences;

  /// No description provided for @stylePreferencesComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Style preferences feature coming soon'**
  String get stylePreferencesComingSoon;

  /// No description provided for @support.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get support;

  /// No description provided for @helpCenter.
  ///
  /// In en, this message translates to:
  /// **'Help Center'**
  String get helpCenter;

  /// No description provided for @helpCenterComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Help center feature coming soon'**
  String get helpCenterComingSoon;

  /// No description provided for @aboutUs.
  ///
  /// In en, this message translates to:
  /// **'About Us'**
  String get aboutUs;

  /// No description provided for @termsAndConditions.
  ///
  /// In en, this message translates to:
  /// **'Terms & Conditions'**
  String get termsAndConditions;

  /// No description provided for @termsOfServiceComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Terms of service feature coming soon'**
  String get termsOfServiceComingSoon;

  /// No description provided for @privacyPolicyComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Privacy policy feature coming soon'**
  String get privacyPolicyComingSoon;

  /// No description provided for @helpAndSupport.
  ///
  /// In en, this message translates to:
  /// **'Help & Support'**
  String get helpAndSupport;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @logoutConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to logout?'**
  String get logoutConfirmation;

  /// No description provided for @logoutMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to logout?'**
  String get logoutMessage;

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Version {version}'**
  String version(String version);

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageRussian.
  ///
  /// In en, this message translates to:
  /// **'Русский'**
  String get languageRussian;

  /// No description provided for @languageUzbek.
  ///
  /// In en, this message translates to:
  /// **'O\'zbekcha'**
  String get languageUzbek;

  /// No description provided for @tashkent.
  ///
  /// In en, this message translates to:
  /// **'Tashkent'**
  String get tashkent;

  /// No description provided for @samarkand.
  ///
  /// In en, this message translates to:
  /// **'Samarkand'**
  String get samarkand;

  /// No description provided for @bukhara.
  ///
  /// In en, this message translates to:
  /// **'Bukhara'**
  String get bukhara;

  /// No description provided for @andijan.
  ///
  /// In en, this message translates to:
  /// **'Andijan'**
  String get andijan;

  /// No description provided for @namangan.
  ///
  /// In en, this message translates to:
  /// **'Namangan'**
  String get namangan;

  /// No description provided for @fergana.
  ///
  /// In en, this message translates to:
  /// **'Fergana'**
  String get fergana;

  /// No description provided for @nukus.
  ///
  /// In en, this message translates to:
  /// **'Nukus'**
  String get nukus;

  /// No description provided for @karshi.
  ///
  /// In en, this message translates to:
  /// **'Karshi'**
  String get karshi;

  /// No description provided for @termez.
  ///
  /// In en, this message translates to:
  /// **'Termez'**
  String get termez;

  /// No description provided for @urgench.
  ///
  /// In en, this message translates to:
  /// **'Urgench'**
  String get urgench;

  /// No description provided for @kokand.
  ///
  /// In en, this message translates to:
  /// **'Kokand'**
  String get kokand;

  /// No description provided for @jizzakh.
  ///
  /// In en, this message translates to:
  /// **'Jizzakh'**
  String get jizzakh;

  /// No description provided for @standardDelivery.
  ///
  /// In en, this message translates to:
  /// **'Standard Delivery'**
  String get standardDelivery;

  /// No description provided for @standardDeliveryDesc.
  ///
  /// In en, this message translates to:
  /// **'5-7 business days'**
  String get standardDeliveryDesc;

  /// No description provided for @expressDelivery.
  ///
  /// In en, this message translates to:
  /// **'Express Delivery'**
  String get expressDelivery;

  /// No description provided for @expressDeliveryDesc.
  ///
  /// In en, this message translates to:
  /// **'2-3 business days'**
  String get expressDeliveryDesc;

  /// No description provided for @sameDayDelivery.
  ///
  /// In en, this message translates to:
  /// **'Same Day Delivery'**
  String get sameDayDelivery;

  /// No description provided for @sameDayDeliveryDesc.
  ///
  /// In en, this message translates to:
  /// **'Order before 12 PM'**
  String get sameDayDeliveryDesc;

  /// No description provided for @free.
  ///
  /// In en, this message translates to:
  /// **'Free'**
  String get free;

  /// No description provided for @bra.
  ///
  /// In en, this message translates to:
  /// **'Bra'**
  String get bra;

  /// No description provided for @band.
  ///
  /// In en, this message translates to:
  /// **'Band'**
  String get band;

  /// No description provided for @cup.
  ///
  /// In en, this message translates to:
  /// **'Cup'**
  String get cup;

  /// No description provided for @swipeRightDescription.
  ///
  /// In en, this message translates to:
  /// **'See something you love? Swipe right to save it to your liked items.'**
  String get swipeRightDescription;

  /// No description provided for @swipeLeftDescription.
  ///
  /// In en, this message translates to:
  /// **'Not your style? Swipe left to see the next item.'**
  String get swipeLeftDescription;

  /// No description provided for @skipTutorial.
  ///
  /// In en, this message translates to:
  /// **'Skip Tutorial'**
  String get skipTutorial;

  /// No description provided for @pants.
  ///
  /// In en, this message translates to:
  /// **'Pants'**
  String get pants;

  /// No description provided for @jackets.
  ///
  /// In en, this message translates to:
  /// **'Jackets'**
  String get jackets;

  /// No description provided for @colorBlack.
  ///
  /// In en, this message translates to:
  /// **'Black'**
  String get colorBlack;

  /// No description provided for @colorWhite.
  ///
  /// In en, this message translates to:
  /// **'White'**
  String get colorWhite;

  /// No description provided for @colorGray.
  ///
  /// In en, this message translates to:
  /// **'Gray'**
  String get colorGray;

  /// No description provided for @colorNavy.
  ///
  /// In en, this message translates to:
  /// **'Navy'**
  String get colorNavy;

  /// No description provided for @colorBlue.
  ///
  /// In en, this message translates to:
  /// **'Blue'**
  String get colorBlue;

  /// No description provided for @colorLightBlue.
  ///
  /// In en, this message translates to:
  /// **'Light Blue'**
  String get colorLightBlue;

  /// No description provided for @colorDarkBlue.
  ///
  /// In en, this message translates to:
  /// **'Dark Blue'**
  String get colorDarkBlue;

  /// No description provided for @colorRed.
  ///
  /// In en, this message translates to:
  /// **'Red'**
  String get colorRed;

  /// No description provided for @colorPink.
  ///
  /// In en, this message translates to:
  /// **'Pink'**
  String get colorPink;

  /// No description provided for @colorGreen.
  ///
  /// In en, this message translates to:
  /// **'Green'**
  String get colorGreen;

  /// No description provided for @colorBrown.
  ///
  /// In en, this message translates to:
  /// **'Brown'**
  String get colorBrown;

  /// No description provided for @colorBeige.
  ///
  /// In en, this message translates to:
  /// **'Beige'**
  String get colorBeige;

  /// No description provided for @colorPurple.
  ///
  /// In en, this message translates to:
  /// **'Purple'**
  String get colorPurple;

  /// No description provided for @colorYellow.
  ///
  /// In en, this message translates to:
  /// **'Yellow'**
  String get colorYellow;

  /// No description provided for @colorOrange.
  ///
  /// In en, this message translates to:
  /// **'Orange'**
  String get colorOrange;

  /// No description provided for @colorCream.
  ///
  /// In en, this message translates to:
  /// **'Cream'**
  String get colorCream;

  /// No description provided for @materialCotton.
  ///
  /// In en, this message translates to:
  /// **'Cotton'**
  String get materialCotton;

  /// No description provided for @materialSilk.
  ///
  /// In en, this message translates to:
  /// **'Silk'**
  String get materialSilk;

  /// No description provided for @materialLinen.
  ///
  /// In en, this message translates to:
  /// **'Linen'**
  String get materialLinen;

  /// No description provided for @materialWool.
  ///
  /// In en, this message translates to:
  /// **'Wool'**
  String get materialWool;

  /// No description provided for @materialChiffon.
  ///
  /// In en, this message translates to:
  /// **'Chiffon'**
  String get materialChiffon;

  /// No description provided for @materialDenim.
  ///
  /// In en, this message translates to:
  /// **'Denim'**
  String get materialDenim;

  /// No description provided for @materialLeather.
  ///
  /// In en, this message translates to:
  /// **'Leather'**
  String get materialLeather;

  /// No description provided for @seasonSpring.
  ///
  /// In en, this message translates to:
  /// **'Spring'**
  String get seasonSpring;

  /// No description provided for @seasonSummer.
  ///
  /// In en, this message translates to:
  /// **'Summer'**
  String get seasonSummer;

  /// No description provided for @seasonFall.
  ///
  /// In en, this message translates to:
  /// **'Fall/Autumn'**
  String get seasonFall;

  /// No description provided for @seasonWinter.
  ///
  /// In en, this message translates to:
  /// **'Winter'**
  String get seasonWinter;

  /// No description provided for @seasonAllSeason.
  ///
  /// In en, this message translates to:
  /// **'All Season'**
  String get seasonAllSeason;

  /// No description provided for @fitLoose.
  ///
  /// In en, this message translates to:
  /// **'Loose'**
  String get fitLoose;

  /// No description provided for @fitRegular.
  ///
  /// In en, this message translates to:
  /// **'Regular'**
  String get fitRegular;

  /// No description provided for @fitSlim.
  ///
  /// In en, this message translates to:
  /// **'Slim'**
  String get fitSlim;

  /// No description provided for @fitOversized.
  ///
  /// In en, this message translates to:
  /// **'Oversized'**
  String get fitOversized;

  /// No description provided for @fitSuperSlim.
  ///
  /// In en, this message translates to:
  /// **'Super Slim'**
  String get fitSuperSlim;

  /// No description provided for @styleCasual.
  ///
  /// In en, this message translates to:
  /// **'Casual'**
  String get styleCasual;

  /// No description provided for @styleFormal.
  ///
  /// In en, this message translates to:
  /// **'Formal'**
  String get styleFormal;

  /// No description provided for @styleSporty.
  ///
  /// In en, this message translates to:
  /// **'Sporty'**
  String get styleSporty;

  /// No description provided for @styleElegant.
  ///
  /// In en, this message translates to:
  /// **'Elegant'**
  String get styleElegant;

  /// No description provided for @styleModest.
  ///
  /// In en, this message translates to:
  /// **'Modest'**
  String get styleModest;

  /// No description provided for @occasionDaily.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get occasionDaily;

  /// No description provided for @occasionWork.
  ///
  /// In en, this message translates to:
  /// **'Work'**
  String get occasionWork;

  /// No description provided for @occasionWedding.
  ///
  /// In en, this message translates to:
  /// **'Wedding'**
  String get occasionWedding;

  /// No description provided for @occasionParty.
  ///
  /// In en, this message translates to:
  /// **'Parties'**
  String get occasionParty;

  /// No description provided for @occasionCasual.
  ///
  /// In en, this message translates to:
  /// **'Casual'**
  String get occasionCasual;

  /// No description provided for @occasionFormal.
  ///
  /// In en, this message translates to:
  /// **'Formal Events'**
  String get occasionFormal;

  /// No description provided for @occasionPrayer.
  ///
  /// In en, this message translates to:
  /// **'Prayer'**
  String get occasionPrayer;

  /// No description provided for @preferNotToSay.
  ///
  /// In en, this message translates to:
  /// **'Prefer not to say'**
  String get preferNotToSay;

  /// No description provided for @notApplicable.
  ///
  /// In en, this message translates to:
  /// **'Not applicable'**
  String get notApplicable;

  /// No description provided for @categoryDress.
  ///
  /// In en, this message translates to:
  /// **'Dress'**
  String get categoryDress;

  /// No description provided for @categoryHijab.
  ///
  /// In en, this message translates to:
  /// **'Hijab'**
  String get categoryHijab;

  /// No description provided for @categoryAbaya.
  ///
  /// In en, this message translates to:
  /// **'Abaya'**
  String get categoryAbaya;

  /// No description provided for @categoryTunic.
  ///
  /// In en, this message translates to:
  /// **'Tunic'**
  String get categoryTunic;

  /// No description provided for @categoryTop.
  ///
  /// In en, this message translates to:
  /// **'Top'**
  String get categoryTop;

  /// No description provided for @categoryBlouse.
  ///
  /// In en, this message translates to:
  /// **'Blouse'**
  String get categoryBlouse;

  /// No description provided for @categoryShirt.
  ///
  /// In en, this message translates to:
  /// **'Shirt'**
  String get categoryShirt;

  /// No description provided for @categoryPants.
  ///
  /// In en, this message translates to:
  /// **'Pants'**
  String get categoryPants;

  /// No description provided for @categoryJeans.
  ///
  /// In en, this message translates to:
  /// **'Jeans'**
  String get categoryJeans;

  /// No description provided for @categorySkirt.
  ///
  /// In en, this message translates to:
  /// **'Skirt'**
  String get categorySkirt;

  /// No description provided for @categoryJacket.
  ///
  /// In en, this message translates to:
  /// **'Jacket'**
  String get categoryJacket;

  /// No description provided for @categoryCoat.
  ///
  /// In en, this message translates to:
  /// **'Coat'**
  String get categoryCoat;

  /// No description provided for @categoryCardigan.
  ///
  /// In en, this message translates to:
  /// **'Cardigan'**
  String get categoryCardigan;

  /// No description provided for @categorySweater.
  ///
  /// In en, this message translates to:
  /// **'Sweater'**
  String get categorySweater;

  /// No description provided for @categoryActivewear.
  ///
  /// In en, this message translates to:
  /// **'Activewear'**
  String get categoryActivewear;

  /// No description provided for @categoryJumpsuit.
  ///
  /// In en, this message translates to:
  /// **'Jumpsuit'**
  String get categoryJumpsuit;

  /// No description provided for @categoryScarf.
  ///
  /// In en, this message translates to:
  /// **'Scarf'**
  String get categoryScarf;

  /// No description provided for @categoryShawl.
  ///
  /// In en, this message translates to:
  /// **'Shawl'**
  String get categoryShawl;

  /// No description provided for @categoryBags.
  ///
  /// In en, this message translates to:
  /// **'Bags'**
  String get categoryBags;

  /// No description provided for @categoryUnderwear.
  ///
  /// In en, this message translates to:
  /// **'Underwear'**
  String get categoryUnderwear;

  /// No description provided for @categoryOuterwear.
  ///
  /// In en, this message translates to:
  /// **'Outerwear'**
  String get categoryOuterwear;

  /// No description provided for @modestyLevel.
  ///
  /// In en, this message translates to:
  /// **'Modesty Level'**
  String get modestyLevel;

  /// No description provided for @modestyLevelDescription.
  ///
  /// In en, this message translates to:
  /// **'How would you prefer your clothing coverage?'**
  String get modestyLevelDescription;

  /// No description provided for @revealing.
  ///
  /// In en, this message translates to:
  /// **'Revealing'**
  String get revealing;

  /// No description provided for @selectModestyError.
  ///
  /// In en, this message translates to:
  /// **'Please select at least one modesty level'**
  String get selectModestyError;

  /// No description provided for @saveModestyError.
  ///
  /// In en, this message translates to:
  /// **'Failed to save modesty level'**
  String get saveModestyError;

  /// No description provided for @selectOneOrBothPreferences.
  ///
  /// In en, this message translates to:
  /// **'Select one or both preferences'**
  String get selectOneOrBothPreferences;

  /// No description provided for @selectMultipleOptions.
  ///
  /// In en, this message translates to:
  /// **'You can select multiple options'**
  String get selectMultipleOptions;

  /// No description provided for @whichColorsAvoid.
  ///
  /// In en, this message translates to:
  /// **'Which colors do you want to avoid?'**
  String get whichColorsAvoid;

  /// No description provided for @selectColorsAvoid.
  ///
  /// In en, this message translates to:
  /// **'Select colors you prefer not to wear'**
  String get selectColorsAvoid;

  /// No description provided for @colorReds.
  ///
  /// In en, this message translates to:
  /// **'Reds'**
  String get colorReds;

  /// No description provided for @colorPinks.
  ///
  /// In en, this message translates to:
  /// **'Pinks'**
  String get colorPinks;

  /// No description provided for @colorOranges.
  ///
  /// In en, this message translates to:
  /// **'Oranges'**
  String get colorOranges;

  /// No description provided for @colorYellows.
  ///
  /// In en, this message translates to:
  /// **'Yellows'**
  String get colorYellows;

  /// No description provided for @colorGreens.
  ///
  /// In en, this message translates to:
  /// **'Greens'**
  String get colorGreens;

  /// No description provided for @colorBlues.
  ///
  /// In en, this message translates to:
  /// **'Blues'**
  String get colorBlues;

  /// No description provided for @colorPurples.
  ///
  /// In en, this message translates to:
  /// **'Purples'**
  String get colorPurples;

  /// No description provided for @colorBrowns.
  ///
  /// In en, this message translates to:
  /// **'Browns'**
  String get colorBrowns;

  /// No description provided for @colorBeiges.
  ///
  /// In en, this message translates to:
  /// **'Beiges'**
  String get colorBeiges;

  /// No description provided for @colorGrays.
  ///
  /// In en, this message translates to:
  /// **'Grays'**
  String get colorGrays;

  /// No description provided for @colorWhites.
  ///
  /// In en, this message translates to:
  /// **'Whites'**
  String get colorWhites;

  /// No description provided for @colorBlacks.
  ///
  /// In en, this message translates to:
  /// **'Blacks'**
  String get colorBlacks;

  /// No description provided for @styleCategories.
  ///
  /// In en, this message translates to:
  /// **'Style Categories'**
  String get styleCategories;

  /// No description provided for @styleCategoriesDescription.
  ///
  /// In en, this message translates to:
  /// **'Choose the styles that match your personality'**
  String get styleCategoriesDescription;

  /// No description provided for @casual.
  ///
  /// In en, this message translates to:
  /// **'Casual'**
  String get casual;

  /// No description provided for @formal.
  ///
  /// In en, this message translates to:
  /// **'Formal'**
  String get formal;

  /// No description provided for @business.
  ///
  /// In en, this message translates to:
  /// **'Business'**
  String get business;

  /// No description provided for @elegant.
  ///
  /// In en, this message translates to:
  /// **'Elegant'**
  String get elegant;

  /// No description provided for @vintage.
  ///
  /// In en, this message translates to:
  /// **'Vintage'**
  String get vintage;

  /// No description provided for @modern.
  ///
  /// In en, this message translates to:
  /// **'Modern'**
  String get modern;

  /// No description provided for @classic.
  ///
  /// In en, this message translates to:
  /// **'Classic'**
  String get classic;

  /// No description provided for @modest.
  ///
  /// In en, this message translates to:
  /// **'Modest'**
  String get modest;

  /// No description provided for @romantic.
  ///
  /// In en, this message translates to:
  /// **'Romantic'**
  String get romantic;

  /// No description provided for @occasions.
  ///
  /// In en, this message translates to:
  /// **'Occasions'**
  String get occasions;

  /// No description provided for @occasionsDescription.
  ///
  /// In en, this message translates to:
  /// **'Select the occasions you typically dress for'**
  String get occasionsDescription;

  /// No description provided for @occasionStudy.
  ///
  /// In en, this message translates to:
  /// **'Study'**
  String get occasionStudy;

  /// No description provided for @occasionReligious.
  ///
  /// In en, this message translates to:
  /// **'Religious Events'**
  String get occasionReligious;

  /// No description provided for @occasionSports.
  ///
  /// In en, this message translates to:
  /// **'Sports'**
  String get occasionSports;

  /// No description provided for @occasionTravel.
  ///
  /// In en, this message translates to:
  /// **'Travel'**
  String get occasionTravel;

  /// No description provided for @occasionOutdoor.
  ///
  /// In en, this message translates to:
  /// **'Outdoor Activities'**
  String get occasionOutdoor;

  /// No description provided for @occasionSpecial.
  ///
  /// In en, this message translates to:
  /// **'Special Occasions'**
  String get occasionSpecial;

  /// No description provided for @brandPreferences.
  ///
  /// In en, this message translates to:
  /// **'Brand Preferences'**
  String get brandPreferences;

  /// No description provided for @brandPreferencesDescription.
  ///
  /// In en, this message translates to:
  /// **'Choose your favorite brands (optional)'**
  String get brandPreferencesDescription;

  /// No description provided for @optionalSelection.
  ///
  /// In en, this message translates to:
  /// **'You can skip this step'**
  String get optionalSelection;

  /// No description provided for @selectAtLeastOne.
  ///
  /// In en, this message translates to:
  /// **'Please select at least one option'**
  String get selectAtLeastOne;

  /// No description provided for @genericError.
  ///
  /// In en, this message translates to:
  /// **'An error occurred. Please try again.'**
  String get genericError;

  /// No description provided for @profileInformation.
  ///
  /// In en, this message translates to:
  /// **'Profile Information'**
  String get profileInformation;

  /// No description provided for @personal.
  ///
  /// In en, this message translates to:
  /// **'Personal'**
  String get personal;

  /// No description provided for @hijabPreference.
  ///
  /// In en, this message translates to:
  /// **'Hijab Preference'**
  String get hijabPreference;

  /// No description provided for @age.
  ///
  /// In en, this message translates to:
  /// **'Age'**
  String get age;

  /// No description provided for @years.
  ///
  /// In en, this message translates to:
  /// **'years'**
  String get years;

  /// No description provided for @bodyInformation.
  ///
  /// In en, this message translates to:
  /// **'Body Information'**
  String get bodyInformation;

  /// No description provided for @clothingSizes.
  ///
  /// In en, this message translates to:
  /// **'Clothing Sizes'**
  String get clothingSizes;

  /// No description provided for @topSize.
  ///
  /// In en, this message translates to:
  /// **'Top Size'**
  String get topSize;

  /// No description provided for @bottomSize.
  ///
  /// In en, this message translates to:
  /// **'Bottom Size'**
  String get bottomSize;

  /// No description provided for @dressSize.
  ///
  /// In en, this message translates to:
  /// **'Dress Size'**
  String get dressSize;

  /// No description provided for @jeanWaistSize.
  ///
  /// In en, this message translates to:
  /// **'Jean Waist Size'**
  String get jeanWaistSize;

  /// No description provided for @braSizes.
  ///
  /// In en, this message translates to:
  /// **'Bra Sizes'**
  String get braSizes;

  /// No description provided for @braBandSize.
  ///
  /// In en, this message translates to:
  /// **'Band Size'**
  String get braBandSize;

  /// No description provided for @braCupSize.
  ///
  /// In en, this message translates to:
  /// **'Cup Size'**
  String get braCupSize;

  /// No description provided for @stylePreferenceLabel.
  ///
  /// In en, this message translates to:
  /// **'Style Preference'**
  String get stylePreferenceLabel;

  /// No description provided for @budgetType.
  ///
  /// In en, this message translates to:
  /// **'Budget Type'**
  String get budgetType;

  /// No description provided for @shoppingPreferences.
  ///
  /// In en, this message translates to:
  /// **'Shopping Preferences'**
  String get shoppingPreferences;

  /// No description provided for @budget.
  ///
  /// In en, this message translates to:
  /// **'Budget'**
  String get budget;

  /// No description provided for @completed.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completed;

  /// No description provided for @notCompleted.
  ///
  /// In en, this message translates to:
  /// **'Not Completed'**
  String get notCompleted;

  /// No description provided for @from.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get from;

  /// No description provided for @upTo.
  ///
  /// In en, this message translates to:
  /// **'Up to'**
  String get upTo;

  /// No description provided for @notSet.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get notSet;

  /// No description provided for @enumFemale.
  ///
  /// In en, this message translates to:
  /// **'Female'**
  String get enumFemale;

  /// No description provided for @enumMale.
  ///
  /// In en, this message translates to:
  /// **'Male'**
  String get enumMale;

  /// No description provided for @enumHourglass.
  ///
  /// In en, this message translates to:
  /// **'Hourglass'**
  String get enumHourglass;

  /// No description provided for @enumTriangle.
  ///
  /// In en, this message translates to:
  /// **'Triangle'**
  String get enumTriangle;

  /// No description provided for @enumRectangle.
  ///
  /// In en, this message translates to:
  /// **'Rectangle'**
  String get enumRectangle;

  /// No description provided for @enumOval.
  ///
  /// In en, this message translates to:
  /// **'Oval'**
  String get enumOval;

  /// No description provided for @enumHeart.
  ///
  /// In en, this message translates to:
  /// **'Heart'**
  String get enumHeart;

  /// No description provided for @enumPreferNotToSay.
  ///
  /// In en, this message translates to:
  /// **'Prefer not to say'**
  String get enumPreferNotToSay;

  /// No description provided for @enumCovered.
  ///
  /// In en, this message translates to:
  /// **'Covered'**
  String get enumCovered;

  /// No description provided for @enumUncovered.
  ///
  /// In en, this message translates to:
  /// **'Uncovered'**
  String get enumUncovered;

  /// No description provided for @enumNotApplicable.
  ///
  /// In en, this message translates to:
  /// **'Not Applicable'**
  String get enumNotApplicable;

  /// No description provided for @enumLoose.
  ///
  /// In en, this message translates to:
  /// **'Loose'**
  String get enumLoose;

  /// No description provided for @enumRegular.
  ///
  /// In en, this message translates to:
  /// **'Regular'**
  String get enumRegular;

  /// No description provided for @enumOversized.
  ///
  /// In en, this message translates to:
  /// **'Oversized'**
  String get enumOversized;

  /// No description provided for @enumSlim.
  ///
  /// In en, this message translates to:
  /// **'Slim'**
  String get enumSlim;

  /// No description provided for @enumSuperSlim.
  ///
  /// In en, this message translates to:
  /// **'Super Slim'**
  String get enumSuperSlim;

  /// No description provided for @enumFitted.
  ///
  /// In en, this message translates to:
  /// **'Fitted'**
  String get enumFitted;

  /// No description provided for @enumModerate.
  ///
  /// In en, this message translates to:
  /// **'Moderate'**
  String get enumModerate;

  /// No description provided for @enumRevealing.
  ///
  /// In en, this message translates to:
  /// **'Revealing'**
  String get enumRevealing;

  /// No description provided for @enumBudget.
  ///
  /// In en, this message translates to:
  /// **'Budget'**
  String get enumBudget;

  /// No description provided for @enumPremium.
  ///
  /// In en, this message translates to:
  /// **'Premium'**
  String get enumPremium;

  /// No description provided for @enumLuxury.
  ///
  /// In en, this message translates to:
  /// **'Luxury'**
  String get enumLuxury;

  /// No description provided for @enumFlexible.
  ///
  /// In en, this message translates to:
  /// **'Flexible'**
  String get enumFlexible;

  /// No description provided for @enumCasual.
  ///
  /// In en, this message translates to:
  /// **'Casual'**
  String get enumCasual;

  /// No description provided for @enumFormal.
  ///
  /// In en, this message translates to:
  /// **'Formal'**
  String get enumFormal;

  /// No description provided for @enumBusiness.
  ///
  /// In en, this message translates to:
  /// **'Business'**
  String get enumBusiness;

  /// No description provided for @enumSporty.
  ///
  /// In en, this message translates to:
  /// **'Sporty'**
  String get enumSporty;

  /// No description provided for @enumElegant.
  ///
  /// In en, this message translates to:
  /// **'Elegant'**
  String get enumElegant;

  /// No description provided for @enumBohemian.
  ///
  /// In en, this message translates to:
  /// **'Bohemian'**
  String get enumBohemian;

  /// No description provided for @enumVintage.
  ///
  /// In en, this message translates to:
  /// **'Vintage'**
  String get enumVintage;

  /// No description provided for @enumModern.
  ///
  /// In en, this message translates to:
  /// **'Modern'**
  String get enumModern;

  /// No description provided for @enumMinimalist.
  ///
  /// In en, this message translates to:
  /// **'Minimalist'**
  String get enumMinimalist;

  /// No description provided for @enumClassic.
  ///
  /// In en, this message translates to:
  /// **'Classic'**
  String get enumClassic;

  /// No description provided for @enumTrendy.
  ///
  /// In en, this message translates to:
  /// **'Trendy'**
  String get enumTrendy;

  /// No description provided for @enumModest.
  ///
  /// In en, this message translates to:
  /// **'Modest'**
  String get enumModest;

  /// No description provided for @enumStreetwear.
  ///
  /// In en, this message translates to:
  /// **'Streetwear'**
  String get enumStreetwear;

  /// No description provided for @enumRomantic.
  ///
  /// In en, this message translates to:
  /// **'Romantic'**
  String get enumRomantic;

  /// No description provided for @enumEdgy.
  ///
  /// In en, this message translates to:
  /// **'Edgy'**
  String get enumEdgy;

  /// No description provided for @enumPreppy.
  ///
  /// In en, this message translates to:
  /// **'Preppy'**
  String get enumPreppy;

  /// No description provided for @enumAthleisure.
  ///
  /// In en, this message translates to:
  /// **'Athleisure'**
  String get enumAthleisure;

  /// No description provided for @enumChic.
  ///
  /// In en, this message translates to:
  /// **'Chic'**
  String get enumChic;

  /// No description provided for @enumGlamorous.
  ///
  /// In en, this message translates to:
  /// **'Glamorous'**
  String get enumGlamorous;

  /// No description provided for @enumSexy.
  ///
  /// In en, this message translates to:
  /// **'Sexy'**
  String get enumSexy;

  /// No description provided for @enumRetro.
  ///
  /// In en, this message translates to:
  /// **'Retro'**
  String get enumRetro;

  /// No description provided for @enumGrunge.
  ///
  /// In en, this message translates to:
  /// **'Grunge'**
  String get enumGrunge;

  /// No description provided for @enumGothic.
  ///
  /// In en, this message translates to:
  /// **'Gothic'**
  String get enumGothic;

  /// No description provided for @enumHippie.
  ///
  /// In en, this message translates to:
  /// **'Hippie'**
  String get enumHippie;

  /// No description provided for @enumArtsy.
  ///
  /// In en, this message translates to:
  /// **'Artsy'**
  String get enumArtsy;

  /// No description provided for @enumFeminine.
  ///
  /// In en, this message translates to:
  /// **'Feminine'**
  String get enumFeminine;

  /// No description provided for @enumMasculine.
  ///
  /// In en, this message translates to:
  /// **'Masculine'**
  String get enumMasculine;

  /// No description provided for @enumAndrogynous.
  ///
  /// In en, this message translates to:
  /// **'Androgynous'**
  String get enumAndrogynous;

  /// No description provided for @enumLuxurious.
  ///
  /// In en, this message translates to:
  /// **'Luxurious'**
  String get enumLuxurious;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ru', 'uz'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ru':
      return AppLocalizationsRu();
    case 'uz':
      return AppLocalizationsUz();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
