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
  /// **'LIBAS'**
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

  /// No description provided for @byContinuingYouAgreeTo.
  ///
  /// In en, this message translates to:
  /// **'By continuing, you agree to our '**
  String get byContinuingYouAgreeTo;

  /// No description provided for @agreeToTermsSuffix.
  ///
  /// In en, this message translates to:
  /// **''**
  String get agreeToTermsSuffix;

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

  /// No description provided for @serverError502.
  ///
  /// In en, this message translates to:
  /// **'The server is temporarily unavailable. Please try again in a moment.'**
  String get serverError502;

  /// No description provided for @serverError503.
  ///
  /// In en, this message translates to:
  /// **'Service is currently unavailable. Please try again later.'**
  String get serverError503;

  /// No description provided for @serverError504.
  ///
  /// In en, this message translates to:
  /// **'The request timed out. Please try again later.'**
  String get serverError504;

  /// No description provided for @serverError500.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong on our end. Please try again later.'**
  String get serverError500;

  /// No description provided for @serverErrorGeneric.
  ///
  /// In en, this message translates to:
  /// **'A server error occurred. Please try again later.'**
  String get serverErrorGeneric;

  /// No description provided for @serverMaintenanceTitle.
  ///
  /// In en, this message translates to:
  /// **'We\'ll be right back'**
  String get serverMaintenanceTitle;

  /// No description provided for @serverMaintenanceSubtitle.
  ///
  /// In en, this message translates to:
  /// **'We\'re doing some maintenance and our service is temporarily unavailable. You don\'t need to sign in again — please check back in a few minutes.'**
  String get serverMaintenanceSubtitle;

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

  /// No description provided for @intentTitle.
  ///
  /// In en, this message translates to:
  /// **'What would you like to do?'**
  String get intentTitle;

  /// No description provided for @intentSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Pick a place to start — you can explore everything anytime.'**
  String get intentSubtitle;

  /// No description provided for @intentDiscoverTitle.
  ///
  /// In en, this message translates to:
  /// **'LIBΛS Swipes'**
  String get intentDiscoverTitle;

  /// No description provided for @intentDiscoverSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Swipe to discover styles picked for you'**
  String get intentDiscoverSubtitle;

  /// No description provided for @intentShopSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Browse and buy from top brands'**
  String get intentShopSubtitle;

  /// No description provided for @intentMarketSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Buy and sell pre-loved fashion'**
  String get intentMarketSubtitle;

  /// No description provided for @intentClosetSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Organize your wardrobe and try on looks'**
  String get intentClosetSubtitle;

  /// No description provided for @intentFeedSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Get inspired by community looks'**
  String get intentFeedSubtitle;

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

  /// Label for the try-on button on the discovery product card
  ///
  /// In en, this message translates to:
  /// **'Try it on'**
  String get tryItOn;

  /// Shown when a product has no prepared garment for virtual try-on yet
  ///
  /// In en, this message translates to:
  /// **'Try-on for this item is coming soon'**
  String get tryOnComingSoon;

  /// Title of the tappable banner on the Discovery screen that opens the style-preferences flow
  ///
  /// In en, this message translates to:
  /// **'Personalize your feed'**
  String get personalizeBannerTitle;

  /// No description provided for @personalizeBannerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Answer a few quick questions for recommendations made for you'**
  String get personalizeBannerSubtitle;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @dismiss.
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get dismiss;

  /// No description provided for @welcomeToSwipe.
  ///
  /// In en, this message translates to:
  /// **'Welcome to LIBAS'**
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

  /// No description provided for @market.
  ///
  /// In en, this message translates to:
  /// **'Market'**
  String get market;

  /// No description provided for @feed.
  ///
  /// In en, this message translates to:
  /// **'Feed'**
  String get feed;

  /// No description provided for @marketComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Soon, the place where you can sell your things'**
  String get marketComingSoon;

  /// No description provided for @visualSearch.
  ///
  /// In en, this message translates to:
  /// **'Visual Search'**
  String get visualSearch;

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

  /// No description provided for @takePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take Photo'**
  String get takePhoto;

  /// No description provided for @uploadFromLibrary.
  ///
  /// In en, this message translates to:
  /// **'Upload from Library'**
  String get uploadFromLibrary;

  /// No description provided for @selectArea.
  ///
  /// In en, this message translates to:
  /// **'Select Area'**
  String get selectArea;

  /// No description provided for @resetSelection.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get resetSelection;

  /// No description provided for @searchThisArea.
  ///
  /// In en, this message translates to:
  /// **'Search This Area'**
  String get searchThisArea;

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

  /// No description provided for @subcategory.
  ///
  /// In en, this message translates to:
  /// **'Subcategory'**
  String get subcategory;

  /// No description provided for @material.
  ///
  /// In en, this message translates to:
  /// **'Material'**
  String get material;

  /// No description provided for @season.
  ///
  /// In en, this message translates to:
  /// **'Season'**
  String get season;

  /// No description provided for @countryOfOrigin.
  ///
  /// In en, this message translates to:
  /// **'Country of Origin'**
  String get countryOfOrigin;

  /// No description provided for @seller.
  ///
  /// In en, this message translates to:
  /// **'Seller'**
  String get seller;

  /// No description provided for @visitShop.
  ///
  /// In en, this message translates to:
  /// **'Visit Shop'**
  String get visitShop;

  /// No description provided for @whereToBuy.
  ///
  /// In en, this message translates to:
  /// **'Where to Buy'**
  String get whereToBuy;

  /// No description provided for @getDirections.
  ///
  /// In en, this message translates to:
  /// **'Get Directions'**
  String get getDirections;

  /// No description provided for @viewAllProducts.
  ///
  /// In en, this message translates to:
  /// **'View all products'**
  String get viewAllProducts;

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

  /// No description provided for @vsPickCategory.
  ///
  /// In en, this message translates to:
  /// **'Crop Image'**
  String get vsPickCategory;

  /// No description provided for @vsSearchButton.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get vsSearchButton;

  /// No description provided for @vsCatTopwear.
  ///
  /// In en, this message translates to:
  /// **'Tops'**
  String get vsCatTopwear;

  /// No description provided for @vsCatBottomwear.
  ///
  /// In en, this message translates to:
  /// **'Bottoms'**
  String get vsCatBottomwear;

  /// No description provided for @vsCatDresses.
  ///
  /// In en, this message translates to:
  /// **'Dresses'**
  String get vsCatDresses;

  /// No description provided for @vsCatOuterwear.
  ///
  /// In en, this message translates to:
  /// **'Outerwear'**
  String get vsCatOuterwear;

  /// No description provided for @vsCatOnePiece.
  ///
  /// In en, this message translates to:
  /// **'One Piece'**
  String get vsCatOnePiece;

  /// No description provided for @vsCatActivewear.
  ///
  /// In en, this message translates to:
  /// **'Activewear'**
  String get vsCatActivewear;

  /// No description provided for @vsCatAccessories.
  ///
  /// In en, this message translates to:
  /// **'Accessories'**
  String get vsCatAccessories;

  /// No description provided for @vsCatFootwear.
  ///
  /// In en, this message translates to:
  /// **'Footwear'**
  String get vsCatFootwear;

  /// No description provided for @vsCatUnderwear.
  ///
  /// In en, this message translates to:
  /// **'Underwear'**
  String get vsCatUnderwear;

  /// No description provided for @vsCatModestWear.
  ///
  /// In en, this message translates to:
  /// **'Modest Wear'**
  String get vsCatModestWear;

  /// No description provided for @vsCatTwoPieceSet.
  ///
  /// In en, this message translates to:
  /// **'Two-Piece Set'**
  String get vsCatTwoPieceSet;

  /// No description provided for @vsCatThreePieceSet.
  ///
  /// In en, this message translates to:
  /// **'Three-Piece Set'**
  String get vsCatThreePieceSet;

  /// No description provided for @vsCatBodysuits.
  ///
  /// In en, this message translates to:
  /// **'Bodysuits'**
  String get vsCatBodysuits;

  /// No description provided for @vsCatHomewear.
  ///
  /// In en, this message translates to:
  /// **'Homewear'**
  String get vsCatHomewear;

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

  /// No description provided for @browseSellers.
  ///
  /// In en, this message translates to:
  /// **'Browse Shops'**
  String get browseSellers;

  /// No description provided for @searchSellers.
  ///
  /// In en, this message translates to:
  /// **'Search sellers...'**
  String get searchSellers;

  /// No description provided for @noSellersFound.
  ///
  /// In en, this message translates to:
  /// **'No sellers found'**
  String get noSellersFound;

  /// No description provided for @noSellersFoundSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Try adjusting your search'**
  String get noSellersFoundSubtitle;

  /// No description provided for @loadingSellers.
  ///
  /// In en, this message translates to:
  /// **'Loading sellers...'**
  String get loadingSellers;

  /// No description provided for @productsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} products'**
  String productsCount(int count);

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
  /// **'Searching for similar styles...'**
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

  /// No description provided for @visualSearchError.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get visualSearchError;

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

  /// No description provided for @noOrdersReceivedYet.
  ///
  /// In en, this message translates to:
  /// **'No Orders Received Yet'**
  String get noOrdersReceivedYet;

  /// No description provided for @customerOrdersAppearHere.
  ///
  /// In en, this message translates to:
  /// **'Orders from customers will appear here'**
  String get customerOrdersAppearHere;

  /// No description provided for @errorLoadingOrders.
  ///
  /// In en, this message translates to:
  /// **'Error Loading Orders'**
  String get errorLoadingOrders;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

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

  /// No description provided for @ordersCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 order} other{{count} orders}}'**
  String ordersCount(int count);

  /// No description provided for @chatsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 conversation} other{{count} conversations}}'**
  String chatsCount(int count);

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

  /// No description provided for @waiting.
  ///
  /// In en, this message translates to:
  /// **'Awaiting Confirmation'**
  String get waiting;

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

  /// No description provided for @created.
  ///
  /// In en, this message translates to:
  /// **'Created'**
  String get created;

  /// No description provided for @paid.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get paid;

  /// No description provided for @refunded.
  ///
  /// In en, this message translates to:
  /// **'Refunded'**
  String get refunded;

  /// No description provided for @returned.
  ///
  /// In en, this message translates to:
  /// **'Returned'**
  String get returned;

  /// No description provided for @readyToShip.
  ///
  /// In en, this message translates to:
  /// **'Ready to Ship'**
  String get readyToShip;

  /// No description provided for @readyForPickup.
  ///
  /// In en, this message translates to:
  /// **'Ready for Pickup'**
  String get readyForPickup;

  /// No description provided for @voided.
  ///
  /// In en, this message translates to:
  /// **'Voided'**
  String get voided;

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

  /// No description provided for @chatToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get chatToday;

  /// No description provided for @chatPresenceOnline.
  ///
  /// In en, this message translates to:
  /// **'online'**
  String get chatPresenceOnline;

  /// No description provided for @chatPresenceOffline.
  ///
  /// In en, this message translates to:
  /// **'offline'**
  String get chatPresenceOffline;

  /// No description provided for @chatPresenceTyping.
  ///
  /// In en, this message translates to:
  /// **'typing...'**
  String get chatPresenceTyping;

  /// No description provided for @chatLastSeenJustNow.
  ///
  /// In en, this message translates to:
  /// **'just now'**
  String get chatLastSeenJustNow;

  /// No description provided for @chatLastSeenMinutes.
  ///
  /// In en, this message translates to:
  /// **'last seen {minutes}m ago'**
  String chatLastSeenMinutes(int minutes);

  /// No description provided for @chatLastSeenHours.
  ///
  /// In en, this message translates to:
  /// **'last seen {hours}h ago'**
  String chatLastSeenHours(int hours);

  /// No description provided for @chatLastSeenDays.
  ///
  /// In en, this message translates to:
  /// **'last seen {days}d ago'**
  String chatLastSeenDays(int days);

  /// No description provided for @chatFailedToLoad.
  ///
  /// In en, this message translates to:
  /// **'Failed to load chat'**
  String get chatFailedToLoad;

  /// No description provided for @chatFailedToReload.
  ///
  /// In en, this message translates to:
  /// **'Failed to reload chat'**
  String get chatFailedToReload;

  /// No description provided for @chatReconnecting.
  ///
  /// In en, this message translates to:
  /// **'Reconnecting… please try again in a moment.'**
  String get chatReconnecting;

  /// No description provided for @chatGoBack.
  ///
  /// In en, this message translates to:
  /// **'Go Back'**
  String get chatGoBack;

  /// No description provided for @chatNotFound.
  ///
  /// In en, this message translates to:
  /// **'Chat not found'**
  String get chatNotFound;

  /// No description provided for @chatFailedToLoadProduct.
  ///
  /// In en, this message translates to:
  /// **'Failed to load product details'**
  String get chatFailedToLoadProduct;

  /// No description provided for @interestedInProduct.
  ///
  /// In en, this message translates to:
  /// **'Hi, do you have this product in stock?'**
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

  /// No description provided for @chatAttachPhoto.
  ///
  /// In en, this message translates to:
  /// **'Photo'**
  String get chatAttachPhoto;

  /// No description provided for @chatAttachLocation.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get chatAttachLocation;

  /// No description provided for @chatAttachButton.
  ///
  /// In en, this message translates to:
  /// **'Attach'**
  String get chatAttachButton;

  /// No description provided for @chatOpenInMaps.
  ///
  /// In en, this message translates to:
  /// **'Open in Maps'**
  String get chatOpenInMaps;

  /// No description provided for @chatAttachCamera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get chatAttachCamera;

  /// No description provided for @chatAttachGallery.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get chatAttachGallery;

  /// No description provided for @chatAttachGallerySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose from your photos'**
  String get chatAttachGallerySubtitle;

  /// No description provided for @chatAttachCameraSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Take a new photo'**
  String get chatAttachCameraSubtitle;

  /// No description provided for @chatAttachPickHint.
  ///
  /// In en, this message translates to:
  /// **'Take a photo or choose from your library'**
  String get chatAttachPickHint;

  /// No description provided for @chatAttachComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Photo & location sharing coming soon'**
  String get chatAttachComingSoon;

  /// No description provided for @typeAMessage.
  ///
  /// In en, this message translates to:
  /// **'Type your message...'**
  String get typeAMessage;

  /// No description provided for @newMessage.
  ///
  /// In en, this message translates to:
  /// **'New Message'**
  String get newMessage;

  /// No description provided for @sendMessage.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get sendMessage;

  /// No description provided for @sizeLabel.
  ///
  /// In en, this message translates to:
  /// **'Size:'**
  String get sizeLabel;

  /// No description provided for @qtyLabel.
  ///
  /// In en, this message translates to:
  /// **'Qty:'**
  String get qtyLabel;

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

  /// No description provided for @customerName.
  ///
  /// In en, this message translates to:
  /// **'Customer Name'**
  String get customerName;

  /// No description provided for @customerPhone.
  ///
  /// In en, this message translates to:
  /// **'Customer Phone'**
  String get customerPhone;

  /// No description provided for @changeStatus.
  ///
  /// In en, this message translates to:
  /// **'Change Status'**
  String get changeStatus;

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

  /// No description provided for @cardPayment.
  ///
  /// In en, this message translates to:
  /// **'Card Payment'**
  String get cardPayment;

  /// No description provided for @pickup.
  ///
  /// In en, this message translates to:
  /// **'Pickup'**
  String get pickup;

  /// No description provided for @payWhenYouReceive.
  ///
  /// In en, this message translates to:
  /// **'Pay by cash or card when receiving'**
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

  /// No description provided for @closet.
  ///
  /// In en, this message translates to:
  /// **'Closet'**
  String get closet;

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

  /// No description provided for @myQrCode.
  ///
  /// In en, this message translates to:
  /// **'My QR Code'**
  String get myQrCode;

  /// No description provided for @scanQrForCashback.
  ///
  /// In en, this message translates to:
  /// **'Show this QR code to partners to receive cashback'**
  String get scanQrForCashback;

  /// No description provided for @svaypCardTitle.
  ///
  /// In en, this message translates to:
  /// **'LIBAS Card'**
  String get svaypCardTitle;

  /// No description provided for @svaypCardCashbackDesc.
  ///
  /// In en, this message translates to:
  /// **'Earn 2% cashback on every purchase'**
  String get svaypCardCashbackDesc;

  /// No description provided for @openQrButton.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get openQrButton;

  /// No description provided for @qrFullScreenHint.
  ///
  /// In en, this message translates to:
  /// **'Show this code at checkout to receive 2% cashback'**
  String get qrFullScreenHint;

  /// No description provided for @qrCashbackPrefix.
  ///
  /// In en, this message translates to:
  /// **'Show this QR code to cashier to receive '**
  String get qrCashbackPrefix;

  /// No description provided for @qrCashbackHighlight.
  ///
  /// In en, this message translates to:
  /// **'2% cashback'**
  String get qrCashbackHighlight;

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

  /// No description provided for @soundEffects.
  ///
  /// In en, this message translates to:
  /// **'Sound Effects'**
  String get soundEffects;

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

  /// No description provided for @notificationsReadAll.
  ///
  /// In en, this message translates to:
  /// **'Read all'**
  String get notificationsReadAll;

  /// No description provided for @notificationsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No notifications yet'**
  String get notificationsEmpty;

  /// No description provided for @notificationsEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'You\'ll see order updates, price drops,\nand messages here.'**
  String get notificationsEmptySubtitle;

  /// No description provided for @notificationsLoadError.
  ///
  /// In en, this message translates to:
  /// **'Failed to load notifications'**
  String get notificationsLoadError;

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

  /// No description provided for @deleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete Account'**
  String get deleteAccount;

  /// No description provided for @deleteAccountConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to permanently delete your account? All your data will be lost and this action cannot be undone.'**
  String get deleteAccountConfirmation;

  /// No description provided for @deleteAccountSuccess.
  ///
  /// In en, this message translates to:
  /// **'Your account has been deleted.'**
  String get deleteAccountSuccess;

  /// No description provided for @deleteAccountError.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete account. Please try again.'**
  String get deleteAccountError;

  /// No description provided for @browseAsGuest.
  ///
  /// In en, this message translates to:
  /// **'Browse as Guest'**
  String get browseAsGuest;

  /// No description provided for @guest.
  ///
  /// In en, this message translates to:
  /// **'Guest'**
  String get guest;

  /// No description provided for @guestPromptTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in to continue'**
  String get guestPromptTitle;

  /// No description provided for @guestPromptMessage.
  ///
  /// In en, this message translates to:
  /// **'Create a free account to save favorites, add items to cart, and track your orders.'**
  String get guestPromptMessage;

  /// No description provided for @guestPromptSignIn.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get guestPromptSignIn;

  /// No description provided for @guestPromptContinueBrowsing.
  ///
  /// In en, this message translates to:
  /// **'Continue Browsing'**
  String get guestPromptContinueBrowsing;

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

  /// No description provided for @swipeUpToCart.
  ///
  /// In en, this message translates to:
  /// **'Swipe Up to Add to Cart'**
  String get swipeUpToCart;

  /// No description provided for @swipeUpDescription.
  ///
  /// In en, this message translates to:
  /// **'Ready to buy? Swipe up to instantly add the item to your cart.'**
  String get swipeUpDescription;

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

  /// No description provided for @materialPolyester.
  ///
  /// In en, this message translates to:
  /// **'Polyester'**
  String get materialPolyester;

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

  /// No description provided for @materialSatin.
  ///
  /// In en, this message translates to:
  /// **'Satin'**
  String get materialSatin;

  /// No description provided for @materialVelvet.
  ///
  /// In en, this message translates to:
  /// **'Velvet'**
  String get materialVelvet;

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

  /// No description provided for @materialSuede.
  ///
  /// In en, this message translates to:
  /// **'Suede'**
  String get materialSuede;

  /// No description provided for @materialJersey.
  ///
  /// In en, this message translates to:
  /// **'Jersey'**
  String get materialJersey;

  /// No description provided for @materialModal.
  ///
  /// In en, this message translates to:
  /// **'Modal'**
  String get materialModal;

  /// No description provided for @materialRayon.
  ///
  /// In en, this message translates to:
  /// **'Rayon'**
  String get materialRayon;

  /// No description provided for @materialSpandex.
  ///
  /// In en, this message translates to:
  /// **'Spandex'**
  String get materialSpandex;

  /// No description provided for @materialLycra.
  ///
  /// In en, this message translates to:
  /// **'Lycra'**
  String get materialLycra;

  /// No description provided for @materialNylon.
  ///
  /// In en, this message translates to:
  /// **'Nylon'**
  String get materialNylon;

  /// No description provided for @materialViscose.
  ///
  /// In en, this message translates to:
  /// **'Viscose'**
  String get materialViscose;

  /// No description provided for @materialBamboo.
  ///
  /// In en, this message translates to:
  /// **'Bamboo'**
  String get materialBamboo;

  /// No description provided for @materialCashmere.
  ///
  /// In en, this message translates to:
  /// **'Cashmere'**
  String get materialCashmere;

  /// No description provided for @materialMixed.
  ///
  /// In en, this message translates to:
  /// **'Mixed'**
  String get materialMixed;

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

  /// No description provided for @categoryTopwear.
  ///
  /// In en, this message translates to:
  /// **'Topwear'**
  String get categoryTopwear;

  /// No description provided for @categoryBottomwear.
  ///
  /// In en, this message translates to:
  /// **'Bottomwear'**
  String get categoryBottomwear;

  /// No description provided for @categoryOnePiece.
  ///
  /// In en, this message translates to:
  /// **'One-piece'**
  String get categoryOnePiece;

  /// No description provided for @categoryIslamicModestWear.
  ///
  /// In en, this message translates to:
  /// **'Islamic / Modest Wear'**
  String get categoryIslamicModestWear;

  /// No description provided for @categoryFootwear.
  ///
  /// In en, this message translates to:
  /// **'Footwear'**
  String get categoryFootwear;

  /// No description provided for @categoryTwoPieceSet.
  ///
  /// In en, this message translates to:
  /// **'Two-Piece Set'**
  String get categoryTwoPieceSet;

  /// No description provided for @categoryThreePieceSet.
  ///
  /// In en, this message translates to:
  /// **'Three-Piece Set'**
  String get categoryThreePieceSet;

  /// No description provided for @categoryBodysuitsTriko.
  ///
  /// In en, this message translates to:
  /// **'Bodysuits & Triko'**
  String get categoryBodysuitsTriko;

  /// No description provided for @categoryHomewear.
  ///
  /// In en, this message translates to:
  /// **'Homewear'**
  String get categoryHomewear;

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

  /// No description provided for @partnerPortal.
  ///
  /// In en, this message translates to:
  /// **'Partner Portal'**
  String get partnerPortal;

  /// No description provided for @partnerWelcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get partnerWelcomeBack;

  /// No description provided for @partnerSignInSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in to manage your store, reply to customers and issue cashback.'**
  String get partnerSignInSubtitle;

  /// No description provided for @partnerUsernameLabel.
  ///
  /// In en, this message translates to:
  /// **'Username or Email'**
  String get partnerUsernameLabel;

  /// No description provided for @partnerUsernameHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your username or email'**
  String get partnerUsernameHint;

  /// No description provided for @partnerPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get partnerPasswordLabel;

  /// No description provided for @partnerPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your password'**
  String get partnerPasswordHint;

  /// No description provided for @partnerForgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get partnerForgotPassword;

  /// No description provided for @partnerSignIn.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get partnerSignIn;

  /// No description provided for @partnerNeedAccess.
  ///
  /// In en, this message translates to:
  /// **'Need access? Contact your account manager.'**
  String get partnerNeedAccess;

  /// No description provided for @partnerLoginFailed.
  ///
  /// In en, this message translates to:
  /// **'Login failed. Please check your credentials.'**
  String get partnerLoginFailed;

  /// No description provided for @partnerCashbackTitle.
  ///
  /// In en, this message translates to:
  /// **'Cashback'**
  String get partnerCashbackTitle;

  /// No description provided for @partnerCashbackSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Scan a customer QR code to record a sale and issue cashback.'**
  String get partnerCashbackSubtitle;

  /// No description provided for @partnerScanQr.
  ///
  /// In en, this message translates to:
  /// **'Scan QR'**
  String get partnerScanQr;

  /// No description provided for @myProducts.
  ///
  /// In en, this message translates to:
  /// **'My Products'**
  String get myProducts;

  /// No description provided for @partnerTapToOpenCamera.
  ///
  /// In en, this message translates to:
  /// **'Tap to open camera'**
  String get partnerTapToOpenCamera;

  /// No description provided for @partnerIdentifyCustomer.
  ///
  /// In en, this message translates to:
  /// **'Identify customer'**
  String get partnerIdentifyCustomer;

  /// No description provided for @partnerSelectProduct.
  ///
  /// In en, this message translates to:
  /// **'Select product'**
  String get partnerSelectProduct;

  /// No description provided for @partnerApplyDiscount.
  ///
  /// In en, this message translates to:
  /// **'Apply discount'**
  String get partnerApplyDiscount;

  /// No description provided for @partnerConfirmCashback.
  ///
  /// In en, this message translates to:
  /// **'Confirm cashback'**
  String get partnerConfirmCashback;

  /// No description provided for @partnerRecordCashback.
  ///
  /// In en, this message translates to:
  /// **'Record Cashback'**
  String get partnerRecordCashback;

  /// No description provided for @partnerProductLabel.
  ///
  /// In en, this message translates to:
  /// **'Product'**
  String get partnerProductLabel;

  /// No description provided for @partnerProductHint.
  ///
  /// In en, this message translates to:
  /// **'Enter product name or SKU'**
  String get partnerProductHint;

  /// No description provided for @partnerSizeLabel.
  ///
  /// In en, this message translates to:
  /// **'Size'**
  String get partnerSizeLabel;

  /// No description provided for @partnerColorLabel.
  ///
  /// In en, this message translates to:
  /// **'Color'**
  String get partnerColorLabel;

  /// No description provided for @partnerPricingLabel.
  ///
  /// In en, this message translates to:
  /// **'Pricing'**
  String get partnerPricingLabel;

  /// No description provided for @partnerOriginalPriceHint.
  ///
  /// In en, this message translates to:
  /// **'Original price (UZS)'**
  String get partnerOriginalPriceHint;

  /// No description provided for @partnerDiscountPercent.
  ///
  /// In en, this message translates to:
  /// **'Discount %'**
  String get partnerDiscountPercent;

  /// No description provided for @partnerDiscountAmount.
  ///
  /// In en, this message translates to:
  /// **'Discount amount'**
  String get partnerDiscountAmount;

  /// No description provided for @partnerFinalPriceLabel.
  ///
  /// In en, this message translates to:
  /// **'Final price: '**
  String get partnerFinalPriceLabel;

  /// No description provided for @partnerNotesLabel.
  ///
  /// In en, this message translates to:
  /// **'Notes (optional)'**
  String get partnerNotesLabel;

  /// No description provided for @partnerNotesHint.
  ///
  /// In en, this message translates to:
  /// **'Any additional notes...'**
  String get partnerNotesHint;

  /// No description provided for @partnerCustomerPrefix.
  ///
  /// In en, this message translates to:
  /// **'Customer: '**
  String get partnerCustomerPrefix;

  /// No description provided for @partnerPointCamera.
  ///
  /// In en, this message translates to:
  /// **'Point at the customer\'s QR code'**
  String get partnerPointCamera;

  /// No description provided for @partnerCashbackSuccess.
  ///
  /// In en, this message translates to:
  /// **'Cashback recorded!'**
  String get partnerCashbackSuccess;

  /// No description provided for @partnerEnterProduct.
  ///
  /// In en, this message translates to:
  /// **'Please enter a product name.'**
  String get partnerEnterProduct;

  /// No description provided for @partnerEnterPrice.
  ///
  /// In en, this message translates to:
  /// **'Please enter the original price.'**
  String get partnerEnterPrice;

  /// No description provided for @partnerCashbackFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to record cashback.'**
  String get partnerCashbackFailed;

  /// No description provided for @partnerVerifyingUser.
  ///
  /// In en, this message translates to:
  /// **'Verifying user...'**
  String get partnerVerifyingUser;

  /// No description provided for @partnerUserNotFound.
  ///
  /// In en, this message translates to:
  /// **'User not found. Please check the QR code.'**
  String get partnerUserNotFound;

  /// No description provided for @partnerUserVerified.
  ///
  /// In en, this message translates to:
  /// **'User verified successfully'**
  String get partnerUserVerified;

  /// No description provided for @partnerSelectProducts.
  ///
  /// In en, this message translates to:
  /// **'Select Products'**
  String get partnerSelectProducts;

  /// No description provided for @partnerSearchProducts.
  ///
  /// In en, this message translates to:
  /// **'Search products...'**
  String get partnerSearchProducts;

  /// No description provided for @partnerNoProducts.
  ///
  /// In en, this message translates to:
  /// **'No products found'**
  String get partnerNoProducts;

  /// No description provided for @partnerAddProduct.
  ///
  /// In en, this message translates to:
  /// **'Add Product'**
  String get partnerAddProduct;

  /// No description provided for @partnerProductsSelected.
  ///
  /// In en, this message translates to:
  /// **'products selected'**
  String get partnerProductsSelected;

  /// No description provided for @partnerContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get partnerContinue;

  /// No description provided for @partnerRemoveProduct.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get partnerRemoveProduct;

  /// No description provided for @partnerTotal.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get partnerTotal;

  /// No description provided for @partnerEnterDiscount.
  ///
  /// In en, this message translates to:
  /// **'Enter discount for'**
  String get partnerEnterDiscount;

  /// No description provided for @partnerApplyingCashback.
  ///
  /// In en, this message translates to:
  /// **'Applying cashback...'**
  String get partnerApplyingCashback;

  /// No description provided for @partnerSelectAtLeastOne.
  ///
  /// In en, this message translates to:
  /// **'Please select at least one product.'**
  String get partnerSelectAtLeastOne;

  /// No description provided for @partnerLoadingProducts.
  ///
  /// In en, this message translates to:
  /// **'Loading products...'**
  String get partnerLoadingProducts;

  /// No description provided for @points.
  ///
  /// In en, this message translates to:
  /// **'pts'**
  String get points;

  /// No description provided for @shopErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Oops, something went wrong'**
  String get shopErrorTitle;

  /// No description provided for @shopErrorSubtitle.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t load products. Please check your connection and try again.'**
  String get shopErrorSubtitle;

  /// No description provided for @shopRetry.
  ///
  /// In en, this message translates to:
  /// **'Try Again'**
  String get shopRetry;

  /// No description provided for @shopLoadingProducts.
  ///
  /// In en, this message translates to:
  /// **'Loading products...'**
  String get shopLoadingProducts;

  /// No description provided for @errorGenericTitle.
  ///
  /// In en, this message translates to:
  /// **'Oops, something went wrong'**
  String get errorGenericTitle;

  /// No description provided for @errorGenericSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Please check your connection and try again.'**
  String get errorGenericSubtitle;

  /// No description provided for @errorRetry.
  ///
  /// In en, this message translates to:
  /// **'Try Again'**
  String get errorRetry;

  /// No description provided for @connectionErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'No internet connection'**
  String get connectionErrorTitle;

  /// No description provided for @vsScanningImage.
  ///
  /// In en, this message translates to:
  /// **'Scanning image'**
  String get vsScanningImage;

  /// No description provided for @vsIdentifyingStyle.
  ///
  /// In en, this message translates to:
  /// **'Identifying style'**
  String get vsIdentifyingStyle;

  /// No description provided for @vsFindingMatches.
  ///
  /// In en, this message translates to:
  /// **'Finding matches'**
  String get vsFindingMatches;

  /// No description provided for @vsAlmostThere.
  ///
  /// In en, this message translates to:
  /// **'Almost there'**
  String get vsAlmostThere;

  /// No description provided for @vsPoweredByAI.
  ///
  /// In en, this message translates to:
  /// **'Powered by AI'**
  String get vsPoweredByAI;

  /// No description provided for @vsTutorialDesc.
  ///
  /// In en, this message translates to:
  /// **'Tap the camera icon in the shop to find similar items by photo.'**
  String get vsTutorialDesc;

  /// No description provided for @tutorialWhiteBlouse.
  ///
  /// In en, this message translates to:
  /// **'White Blouse'**
  String get tutorialWhiteBlouse;

  /// No description provided for @tutorialLongDress.
  ///
  /// In en, this message translates to:
  /// **'Long Dress'**
  String get tutorialLongDress;

  /// No description provided for @tutorialBeigeShoes.
  ///
  /// In en, this message translates to:
  /// **'Beige Shoes'**
  String get tutorialBeigeShoes;

  /// No description provided for @profileUpdatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Profile updated successfully'**
  String get profileUpdatedSuccess;

  /// No description provided for @mapOpenMap.
  ///
  /// In en, this message translates to:
  /// **'Open map'**
  String get mapOpenMap;

  /// No description provided for @mapOpenInMaps.
  ///
  /// In en, this message translates to:
  /// **'Open in Maps'**
  String get mapOpenInMaps;

  /// No description provided for @loadingSellerProducts.
  ///
  /// In en, this message translates to:
  /// **'Loading seller products...'**
  String get loadingSellerProducts;

  /// No description provided for @shops.
  ///
  /// In en, this message translates to:
  /// **'Shops'**
  String get shops;

  /// No description provided for @allShops.
  ///
  /// In en, this message translates to:
  /// **'All Shops'**
  String get allShops;

  /// No description provided for @forceUpdateTitle.
  ///
  /// In en, this message translates to:
  /// **'Update Required'**
  String get forceUpdateTitle;

  /// No description provided for @forceUpdateSubtitle.
  ///
  /// In en, this message translates to:
  /// **'A new version of Libas AI is available with exciting new features and improvements. Please update to continue.'**
  String get forceUpdateSubtitle;

  /// No description provided for @forceUpdateButton.
  ///
  /// In en, this message translates to:
  /// **'Update Now'**
  String get forceUpdateButton;

  /// No description provided for @forceUpdateVersionLabel.
  ///
  /// In en, this message translates to:
  /// **'Version {version} available'**
  String forceUpdateVersionLabel(String version);

  /// No description provided for @pressBackAgainToExit.
  ///
  /// In en, this message translates to:
  /// **'Press back again to exit'**
  String get pressBackAgainToExit;

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// No description provided for @tapRefreshToSeeMore.
  ///
  /// In en, this message translates to:
  /// **'Tap refresh to start over and see new products'**
  String get tapRefreshToSeeMore;

  /// No description provided for @addToCloset.
  ///
  /// In en, this message translates to:
  /// **'Add to Closet'**
  String get addToCloset;

  /// No description provided for @saveToCloset.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get saveToCloset;

  /// No description provided for @closetEmpty.
  ///
  /// In en, this message translates to:
  /// **'Your closet is empty'**
  String get closetEmpty;

  /// No description provided for @closetEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Add your first item to start building your wardrobe'**
  String get closetEmptySubtitle;

  /// No description provided for @itemDeleted.
  ///
  /// In en, this message translates to:
  /// **'Item removed'**
  String get itemDeleted;

  /// No description provided for @selectCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get selectCategory;

  /// No description provided for @brandOptional.
  ///
  /// In en, this message translates to:
  /// **'Brand (optional)'**
  String get brandOptional;

  /// No description provided for @notesOptional.
  ///
  /// In en, this message translates to:
  /// **'Notes (optional)'**
  String get notesOptional;

  /// No description provided for @newItem.
  ///
  /// In en, this message translates to:
  /// **'New Item'**
  String get newItem;

  /// No description provided for @deleteItemConfirm.
  ///
  /// In en, this message translates to:
  /// **'Remove this item from your closet?'**
  String get deleteItemConfirm;

  /// No description provided for @categoryTshirts.
  ///
  /// In en, this message translates to:
  /// **'T-Shirts'**
  String get categoryTshirts;

  /// No description provided for @categoryJackets.
  ///
  /// In en, this message translates to:
  /// **'Jackets'**
  String get categoryJackets;

  /// No description provided for @categoryBlouses.
  ///
  /// In en, this message translates to:
  /// **'Blouses'**
  String get categoryBlouses;

  /// No description provided for @categoryJumpsuits.
  ///
  /// In en, this message translates to:
  /// **'Jumpsuits'**
  String get categoryJumpsuits;

  /// No description provided for @categorySkirts.
  ///
  /// In en, this message translates to:
  /// **'Skirts'**
  String get categorySkirts;

  /// No description provided for @categoryShorts.
  ///
  /// In en, this message translates to:
  /// **'Shorts'**
  String get categoryShorts;

  /// No description provided for @sectionMyOutfits.
  ///
  /// In en, this message translates to:
  /// **'My Outfits'**
  String get sectionMyOutfits;

  /// No description provided for @sectionUpperBody.
  ///
  /// In en, this message translates to:
  /// **'Upper Body'**
  String get sectionUpperBody;

  /// No description provided for @sectionLowerBody.
  ///
  /// In en, this message translates to:
  /// **'Lower Body'**
  String get sectionLowerBody;

  /// No description provided for @outfitsNeedMoreItems.
  ///
  /// In en, this message translates to:
  /// **'Add at least 5 items to unlock outfit creation'**
  String get outfitsNeedMoreItems;

  /// No description provided for @verifyMethodTitle.
  ///
  /// In en, this message translates to:
  /// **'Verify your identity'**
  String get verifyMethodTitle;

  /// No description provided for @verifyMethodSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose a verification method'**
  String get verifyMethodSubtitle;

  /// No description provided for @continueWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get continueWithGoogle;

  /// No description provided for @continueWithApple.
  ///
  /// In en, this message translates to:
  /// **'Continue with Apple'**
  String get continueWithApple;

  /// No description provided for @signInTroubleTelegram.
  ///
  /// In en, this message translates to:
  /// **'Having trouble signing in? Contact us on Telegram'**
  String get signInTroubleTelegram;

  /// No description provided for @verifyWithSms.
  ///
  /// In en, this message translates to:
  /// **'Verify with SMS'**
  String get verifyWithSms;

  /// No description provided for @signInTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signInTitle;

  /// No description provided for @createAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get createAccountTitle;

  /// No description provided for @linkAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Link your account'**
  String get linkAccountTitle;

  /// No description provided for @selectCountry.
  ///
  /// In en, this message translates to:
  /// **'Select country'**
  String get selectCountry;

  /// No description provided for @searchCountry.
  ///
  /// In en, this message translates to:
  /// **'Search country or code'**
  String get searchCountry;

  /// No description provided for @noResultsFound.
  ///
  /// In en, this message translates to:
  /// **'No results found'**
  String get noResultsFound;

  /// No description provided for @introSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get introSkip;

  /// No description provided for @introNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get introNext;

  /// No description provided for @introStart.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get introStart;

  /// No description provided for @introSlide1Title.
  ///
  /// In en, this message translates to:
  /// **'Your entire wardrobe — in your phone'**
  String get introSlide1Title;

  /// No description provided for @introSlide1Subtitle.
  ///
  /// In en, this message translates to:
  /// **'Collect your clothes, create outfits and try them on without opening the closet.'**
  String get introSlide1Subtitle;

  /// No description provided for @introSlide2Kicker.
  ///
  /// In en, this message translates to:
  /// **'Closet'**
  String get introSlide2Kicker;

  /// No description provided for @introSlide2Title.
  ///
  /// In en, this message translates to:
  /// **'Create outfits from your own clothes'**
  String get introSlide2Title;

  /// No description provided for @introSlide2Subtitle.
  ///
  /// In en, this message translates to:
  /// **'Upload your clothes, lay them out on a board and build looks like a stylist — drag, swap, combine.'**
  String get introSlide2Subtitle;

  /// No description provided for @introSlide3Kicker.
  ///
  /// In en, this message translates to:
  /// **'Try-on'**
  String get introSlide3Kicker;

  /// No description provided for @introSlide3Title.
  ///
  /// In en, this message translates to:
  /// **'Try it on yourself or on a mannequin'**
  String get introSlide3Title;

  /// No description provided for @introSlide3Subtitle.
  ///
  /// In en, this message translates to:
  /// **'Upload a full-body photo and see how the outfit looks on you.'**
  String get introSlide3Subtitle;

  /// No description provided for @introTryOnMannequin.
  ///
  /// In en, this message translates to:
  /// **'On a mannequin'**
  String get introTryOnMannequin;

  /// No description provided for @introTryOnPhoto.
  ///
  /// In en, this message translates to:
  /// **'On my photo'**
  String get introTryOnPhoto;

  /// No description provided for @introSlide4Kicker.
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get introSlide4Kicker;

  /// No description provided for @introSlide4Title.
  ///
  /// In en, this message translates to:
  /// **'A ready outfit for every day'**
  String get introSlide4Title;

  /// No description provided for @introSlide4Subtitle.
  ///
  /// In en, this message translates to:
  /// **'We\'ll put together looks for your whole week — all that\'s left is to get dressed.'**
  String get introSlide4Subtitle;

  /// No description provided for @introThisWeek.
  ///
  /// In en, this message translates to:
  /// **'This week'**
  String get introThisWeek;

  /// No description provided for @introSlide5Kicker.
  ///
  /// In en, this message translates to:
  /// **'Market'**
  String get introSlide5Kicker;

  /// No description provided for @introSlide5Title.
  ///
  /// In en, this message translates to:
  /// **'Sell and find clothes'**
  String get introSlide5Title;

  /// No description provided for @introSlide5Subtitle.
  ///
  /// In en, this message translates to:
  /// **'Pass on what didn\'t fit and buy outfits from other girls at a nice price.'**
  String get introSlide5Subtitle;

  /// No description provided for @introMarketItemTitle.
  ///
  /// In en, this message translates to:
  /// **'Silk blouse'**
  String get introMarketItemTitle;

  /// No description provided for @introMarketItemMeta.
  ///
  /// In en, this message translates to:
  /// **'Size M · like new'**
  String get introMarketItemMeta;

  /// No description provided for @introMarketItemPrice.
  ///
  /// In en, this message translates to:
  /// **'149 000 so\'m'**
  String get introMarketItemPrice;

  /// No description provided for @introMarketSellerName.
  ///
  /// In en, this message translates to:
  /// **'Aruzhan'**
  String get introMarketSellerName;

  /// No description provided for @introSlide6Kicker.
  ///
  /// In en, this message translates to:
  /// **'Diamonds'**
  String get introSlide6Kicker;

  /// No description provided for @introSlide6Title.
  ///
  /// In en, this message translates to:
  /// **'Diamonds — your creative currency'**
  String get introSlide6Title;

  /// No description provided for @introSlide6Subtitle.
  ///
  /// In en, this message translates to:
  /// **'Diamonds are the in-app currency. They power AI features like outfit generation, styling and virtual try-on. Adding your own clothes is always free!'**
  String get introSlide6Subtitle;

  /// No description provided for @introCoinRowUpload.
  ///
  /// In en, this message translates to:
  /// **'Upload clothes'**
  String get introCoinRowUpload;

  /// No description provided for @introCoinFree.
  ///
  /// In en, this message translates to:
  /// **'Free'**
  String get introCoinFree;

  /// No description provided for @introDiamondUses.
  ///
  /// In en, this message translates to:
  /// **'Looks & try-ons'**
  String get introDiamondUses;

  /// No description provided for @introDiamondFreeLabel.
  ///
  /// In en, this message translates to:
  /// **'Add clothes'**
  String get introDiamondFreeLabel;

  /// No description provided for @introCoinRowOutfit.
  ///
  /// In en, this message translates to:
  /// **'Create an outfit'**
  String get introCoinRowOutfit;

  /// No description provided for @introCoinRowEnhance.
  ///
  /// In en, this message translates to:
  /// **'Enhance a photo'**
  String get introCoinRowEnhance;

  /// No description provided for @introCoinRowTryOn.
  ///
  /// In en, this message translates to:
  /// **'Try on'**
  String get introCoinRowTryOn;

  /// No description provided for @introSlide7Kicker.
  ///
  /// In en, this message translates to:
  /// **'Welcome gift'**
  String get introSlide7Kicker;

  /// No description provided for @introSlide7Title.
  ///
  /// In en, this message translates to:
  /// **'Get {count} diamonds free'**
  String introSlide7Title(int count);

  /// No description provided for @introSlide7Subtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign up and {count} diamonds are already yours.'**
  String introSlide7Subtitle(int count);

  /// No description provided for @introSlide7CoinsCaption.
  ///
  /// In en, this message translates to:
  /// **'coins as a gift'**
  String get introSlide7CoinsCaption;

  /// No description provided for @introSlide7Chip.
  ///
  /// In en, this message translates to:
  /// **'{count} diamonds on your balance'**
  String introSlide7Chip(int count);

  /// No description provided for @introShopKicker.
  ///
  /// In en, this message translates to:
  /// **'Shop'**
  String get introShopKicker;

  /// No description provided for @introShopTitle.
  ///
  /// In en, this message translates to:
  /// **'Swipe products from brands'**
  String get introShopTitle;

  /// No description provided for @introShopSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Swipe right on what you like and order from our partner brands.'**
  String get introShopSubtitle;

  /// No description provided for @introShopItem1Title.
  ///
  /// In en, this message translates to:
  /// **'Women\'s sweatshirt'**
  String get introShopItem1Title;

  /// No description provided for @introShopItem1Size.
  ///
  /// In en, this message translates to:
  /// **'S, M, L'**
  String get introShopItem1Size;

  /// No description provided for @introShopItem1Price.
  ///
  /// In en, this message translates to:
  /// **'160,000 UZS'**
  String get introShopItem1Price;

  /// No description provided for @introShopItem2Title.
  ///
  /// In en, this message translates to:
  /// **'Knit suit with peplum'**
  String get introShopItem2Title;

  /// No description provided for @introShopItem2Size.
  ///
  /// In en, this message translates to:
  /// **'Size M'**
  String get introShopItem2Size;

  /// No description provided for @introShopItem2Price.
  ///
  /// In en, this message translates to:
  /// **'700,000 UZS'**
  String get introShopItem2Price;

  /// No description provided for @introShopItem3Title.
  ///
  /// In en, this message translates to:
  /// **'Elegant sleeveless dress'**
  String get introShopItem3Title;

  /// No description provided for @introShopItem3Size.
  ///
  /// In en, this message translates to:
  /// **'One size'**
  String get introShopItem3Size;

  /// No description provided for @introShopItem3Price.
  ///
  /// In en, this message translates to:
  /// **'400,000 UZS'**
  String get introShopItem3Price;

  /// No description provided for @introShopItem4Title.
  ///
  /// In en, this message translates to:
  /// **'Lace set'**
  String get introShopItem4Title;

  /// No description provided for @introShopItem4Size.
  ///
  /// In en, this message translates to:
  /// **'S M L XL'**
  String get introShopItem4Size;

  /// No description provided for @introShopItem4Price.
  ///
  /// In en, this message translates to:
  /// **'250,000 UZS'**
  String get introShopItem4Price;

  /// No description provided for @introMarketItem1Title.
  ///
  /// In en, this message translates to:
  /// **'Lion trousers'**
  String get introMarketItem1Title;

  /// No description provided for @introMarketItem1Size.
  ///
  /// In en, this message translates to:
  /// **'48 (L)'**
  String get introMarketItem1Size;

  /// No description provided for @introMarketItem1Price.
  ///
  /// In en, this message translates to:
  /// **'200,000 UZS'**
  String get introMarketItem1Price;

  /// No description provided for @introMarketItem2Title.
  ///
  /// In en, this message translates to:
  /// **'Miu Miu slippers'**
  String get introMarketItem2Title;

  /// No description provided for @introMarketItem2Size.
  ///
  /// In en, this message translates to:
  /// **'Size 40'**
  String get introMarketItem2Size;

  /// No description provided for @introMarketItem2Price.
  ///
  /// In en, this message translates to:
  /// **'149,000 UZS'**
  String get introMarketItem2Price;

  /// No description provided for @introMarketItem3Title.
  ///
  /// In en, this message translates to:
  /// **'T-shirt'**
  String get introMarketItem3Title;

  /// No description provided for @introMarketItem3Size.
  ///
  /// In en, this message translates to:
  /// **'Oversize'**
  String get introMarketItem3Size;

  /// No description provided for @introMarketItem3Price.
  ///
  /// In en, this message translates to:
  /// **'100,000 UZS'**
  String get introMarketItem3Price;

  /// No description provided for @introMarketItem4Title.
  ///
  /// In en, this message translates to:
  /// **'Two-piece set'**
  String get introMarketItem4Title;

  /// No description provided for @introMarketItem4Size.
  ///
  /// In en, this message translates to:
  /// **'44 (S)'**
  String get introMarketItem4Size;

  /// No description provided for @introMarketItem4Price.
  ///
  /// In en, this message translates to:
  /// **'350,000 UZS'**
  String get introMarketItem4Price;

  /// No description provided for @introMarketItem5Title.
  ///
  /// In en, this message translates to:
  /// **'YSL heels'**
  String get introMarketItem5Title;

  /// No description provided for @introMarketItem5Size.
  ///
  /// In en, this message translates to:
  /// **'Size 37'**
  String get introMarketItem5Size;

  /// No description provided for @introMarketItem5Price.
  ///
  /// In en, this message translates to:
  /// **'600,000 UZS'**
  String get introMarketItem5Price;

  /// No description provided for @introMarketItem6Title.
  ///
  /// In en, this message translates to:
  /// **'Dress'**
  String get introMarketItem6Title;

  /// No description provided for @introMarketItem6Size.
  ///
  /// In en, this message translates to:
  /// **'Size 44'**
  String get introMarketItem6Size;

  /// No description provided for @introMarketItem6Price.
  ///
  /// In en, this message translates to:
  /// **'199,000 UZS'**
  String get introMarketItem6Price;

  /// No description provided for @introMarketItem7Title.
  ///
  /// In en, this message translates to:
  /// **'Ensemble + veil'**
  String get introMarketItem7Title;

  /// No description provided for @introMarketItem7Size.
  ///
  /// In en, this message translates to:
  /// **'46 (M)'**
  String get introMarketItem7Size;

  /// No description provided for @introMarketItem7Price.
  ///
  /// In en, this message translates to:
  /// **'600,000 UZS'**
  String get introMarketItem7Price;

  /// No description provided for @introSlide6FreeHighlight.
  ///
  /// In en, this message translates to:
  /// **'Adding your own clothes is always free!'**
  String get introSlide6FreeHighlight;

  /// Try-on sheet: option to fit the garment on a mannequin
  ///
  /// In en, this message translates to:
  /// **'On a mannequin'**
  String get tryOnModeMannequin;

  /// Try-on sheet: option to fit the garment on the user's own photo
  ///
  /// In en, this message translates to:
  /// **'On your photo'**
  String get tryOnModeSelf;

  /// No description provided for @tryOnUploadingPhoto.
  ///
  /// In en, this message translates to:
  /// **'Uploading photo…'**
  String get tryOnUploadingPhoto;

  /// No description provided for @tryOnPhotoReady.
  ///
  /// In en, this message translates to:
  /// **'Photo ready — you can try it on'**
  String get tryOnPhotoReady;

  /// No description provided for @tryOnPickPhoto.
  ///
  /// In en, this message translates to:
  /// **'Choose a full-length photo of yourself'**
  String get tryOnPickPhoto;

  /// No description provided for @tryOnPhotoUploadFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t upload the photo. Try another one.'**
  String get tryOnPhotoUploadFailed;

  /// No description provided for @tryOnProcessingTitle.
  ///
  /// In en, this message translates to:
  /// **'Trying it on you…'**
  String get tryOnProcessingTitle;

  /// No description provided for @tryOnProcessingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'AI is finding the perfect fit'**
  String get tryOnProcessingSubtitle;

  /// No description provided for @tryOnFailedDefault.
  ///
  /// In en, this message translates to:
  /// **'The try-on didn\'t work. Please try again.'**
  String get tryOnFailedDefault;

  /// No description provided for @tryOnSomethingWrong.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get tryOnSomethingWrong;

  /// No description provided for @tryOnNeedDiamondsTitle.
  ///
  /// In en, this message translates to:
  /// **'Not enough diamonds'**
  String get tryOnNeedDiamondsTitle;

  /// Try-on: shown when the user lacks diamonds; cost and current balance
  ///
  /// In en, this message translates to:
  /// **'A try-on needs {cost} diamonds, you have {balance}. Top up your balance in the Wardrobe section.'**
  String tryOnNeedDiamondsBody(int cost, int balance);

  /// No description provided for @tryOnNeedDiamondsBodyShort.
  ///
  /// In en, this message translates to:
  /// **'You don\'t have enough diamonds for a try-on. Top up your balance in the Wardrobe section.'**
  String get tryOnNeedDiamondsBodyShort;

  /// No description provided for @tryOnQuotaExceeded.
  ///
  /// In en, this message translates to:
  /// **'You\'ve used all your try-ons for this month. Upgrade to premium for more.'**
  String get tryOnQuotaExceeded;

  /// No description provided for @tryOnConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Try It On?'**
  String get tryOnConfirmTitle;

  /// No description provided for @tryOnTargetMannequin.
  ///
  /// In en, this message translates to:
  /// **'On a mannequin'**
  String get tryOnTargetMannequin;

  /// No description provided for @tryOnTargetSelf.
  ///
  /// In en, this message translates to:
  /// **'On my photo'**
  String get tryOnTargetSelf;

  /// No description provided for @tryOnConfirm.
  ///
  /// In en, this message translates to:
  /// **'Try It On'**
  String get tryOnConfirm;

  /// No description provided for @tryOnUploadPhoto.
  ///
  /// In en, this message translates to:
  /// **'Upload photo'**
  String get tryOnUploadPhoto;

  /// No description provided for @tryOnChangePhoto.
  ///
  /// In en, this message translates to:
  /// **'Change photo'**
  String get tryOnChangePhoto;

  /// No description provided for @tryOnPhotoHint.
  ///
  /// In en, this message translates to:
  /// **'Full-length photo, good lighting, facing the camera'**
  String get tryOnPhotoHint;

  /// No description provided for @tryOnShare.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get tryOnShare;

  /// No description provided for @tryOnMyOutfits.
  ///
  /// In en, this message translates to:
  /// **'My outfits'**
  String get tryOnMyOutfits;

  /// No description provided for @tryOnShareFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t share the image. Please try again.'**
  String get tryOnShareFailed;

  /// Heading of the try-on failure state. The body below it is one of the tryOnFailed* messages, never the raw backend reason.
  ///
  /// In en, this message translates to:
  /// **'Try-on failed'**
  String get tryOnFailedTitle;

  /// No description provided for @tryOnFailedSafety.
  ///
  /// In en, this message translates to:
  /// **'This photo couldn\'t be used — it didn\'t pass our content safety checks. Please try a different photo or outfit.'**
  String get tryOnFailedSafety;

  /// No description provided for @tryOnFailedTimeout.
  ///
  /// In en, this message translates to:
  /// **'This is taking longer than expected. Please try again in a moment.'**
  String get tryOnFailedTimeout;

  /// No description provided for @tryOnFailedBusy.
  ///
  /// In en, this message translates to:
  /// **'Our AI is busy right now. Please wait a moment and try again.'**
  String get tryOnFailedBusy;

  /// No description provided for @tryOnFailedGeneric.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t create your try-on. Please try again.'**
  String get tryOnFailedGeneric;

  /// No description provided for @tryOnStarting.
  ///
  /// In en, this message translates to:
  /// **'Starting try-on...'**
  String get tryOnStarting;

  /// No description provided for @tryOnPhase2.
  ///
  /// In en, this message translates to:
  /// **'Analyzing your outfit...'**
  String get tryOnPhase2;

  /// No description provided for @tryOnPhase3.
  ///
  /// In en, this message translates to:
  /// **'Rendering your look...'**
  String get tryOnPhase3;

  /// No description provided for @tryOnPhase4.
  ///
  /// In en, this message translates to:
  /// **'Adding finishing touches...'**
  String get tryOnPhase4;

  /// No description provided for @tryOnTimeEstimate.
  ///
  /// In en, this message translates to:
  /// **'Usually takes 30–60 seconds'**
  String get tryOnTimeEstimate;

  /// No description provided for @tryOnStyleTip.
  ///
  /// In en, this message translates to:
  /// **'Style Tip'**
  String get tryOnStyleTip;

  /// No description provided for @tryOnProTip.
  ///
  /// In en, this message translates to:
  /// **'Pro Tip'**
  String get tryOnProTip;

  /// No description provided for @tryOnDidYouKnow.
  ///
  /// In en, this message translates to:
  /// **'Did you know?'**
  String get tryOnDidYouKnow;

  /// No description provided for @tryOnTip1.
  ///
  /// In en, this message translates to:
  /// **'Your wardrobe may be hiding dozens of outfits you have never tried.'**
  String get tryOnTip1;

  /// No description provided for @tryOnTip2.
  ///
  /// In en, this message translates to:
  /// **'You do not always need to buy something new to look new.'**
  String get tryOnTip2;

  /// No description provided for @tryOnTip3.
  ///
  /// In en, this message translates to:
  /// **'The best outfits are often built around one key piece.'**
  String get tryOnTip3;

  /// No description provided for @tryOnTip4.
  ///
  /// In en, this message translates to:
  /// **'Core colors: white, black, grey, beige, and navy.'**
  String get tryOnTip4;

  /// No description provided for @tryOnTip5.
  ///
  /// In en, this message translates to:
  /// **'Most people regularly wear only 20% of their wardrobe.'**
  String get tryOnTip5;

  /// No description provided for @tryOnTip6.
  ///
  /// In en, this message translates to:
  /// **'Good style is balance, not quantity.'**
  String get tryOnTip6;

  /// No description provided for @tryOnTip7.
  ///
  /// In en, this message translates to:
  /// **'Contrasting colors attract more attention.'**
  String get tryOnTip7;

  /// No description provided for @tryOnTip8.
  ///
  /// In en, this message translates to:
  /// **'Fashion changes, but good taste stays relevant.'**
  String get tryOnTip8;

  /// No description provided for @mirrorTab.
  ///
  /// In en, this message translates to:
  /// **'Mirror'**
  String get mirrorTab;

  /// No description provided for @mirrorIdleEyebrow.
  ///
  /// In en, this message translates to:
  /// **'LIBAS AI stylist'**
  String get mirrorIdleEyebrow;

  /// No description provided for @mirrorIdleTitle.
  ///
  /// In en, this message translates to:
  /// **'Try on a look'**
  String get mirrorIdleTitle;

  /// No description provided for @mirrorIdleTitleAccent.
  ///
  /// In en, this message translates to:
  /// **'in 30 seconds'**
  String get mirrorIdleTitleAccent;

  /// No description provided for @mirrorCtaCreate.
  ///
  /// In en, this message translates to:
  /// **'Create a look'**
  String get mirrorCtaCreate;

  /// No description provided for @mirrorCtaCatalog.
  ///
  /// In en, this message translates to:
  /// **'Browse the catalog'**
  String get mirrorCtaCatalog;

  /// No description provided for @mirrorFree.
  ///
  /// In en, this message translates to:
  /// **'Free'**
  String get mirrorFree;

  /// No description provided for @mirrorIntroEyebrow.
  ///
  /// In en, this message translates to:
  /// **'Three steps'**
  String get mirrorIntroEyebrow;

  /// No description provided for @mirrorIntroTitle.
  ///
  /// In en, this message translates to:
  /// **'How it works'**
  String get mirrorIntroTitle;

  /// No description provided for @mirrorStep1Title.
  ///
  /// In en, this message translates to:
  /// **'Take a photo of your face'**
  String get mirrorStep1Title;

  /// No description provided for @mirrorStep1Text.
  ///
  /// In en, this message translates to:
  /// **'One photo, right here'**
  String get mirrorStep1Text;

  /// No description provided for @mirrorStep2Title.
  ///
  /// In en, this message translates to:
  /// **'Answer two questions'**
  String get mirrorStep2Title;

  /// No description provided for @mirrorStep2Text.
  ///
  /// In en, this message translates to:
  /// **'Gender and body type'**
  String get mirrorStep2Text;

  /// No description provided for @mirrorStep3Title.
  ///
  /// In en, this message translates to:
  /// **'See your look'**
  String get mirrorStep3Title;

  /// No description provided for @mirrorStep3Text.
  ///
  /// In en, this message translates to:
  /// **'Made of items that are in stock'**
  String get mirrorStep3Text;

  /// No description provided for @mirrorIntroCta.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get mirrorIntroCta;

  /// No description provided for @mirrorPrivacyLong.
  ///
  /// In en, this message translates to:
  /// **'Your face photo is kept for 15 minutes and deleted automatically. We never show your face on the image and sellers never see the photo.'**
  String get mirrorPrivacyLong;

  /// No description provided for @mirrorPrivacyShort.
  ///
  /// In en, this message translates to:
  /// **'The photo is deleted after 15 minutes'**
  String get mirrorPrivacyShort;

  /// No description provided for @mirrorCamAim.
  ///
  /// In en, this message translates to:
  /// **'Place your face inside the circle'**
  String get mirrorCamAim;

  /// No description provided for @mirrorCamLook.
  ///
  /// In en, this message translates to:
  /// **'Look straight into the camera'**
  String get mirrorCamLook;

  /// No description provided for @mirrorCamDone.
  ///
  /// In en, this message translates to:
  /// **'Does it look good?'**
  String get mirrorCamDone;

  /// No description provided for @mirrorCamDoneHint.
  ///
  /// In en, this message translates to:
  /// **'Face is clearly visible, no shadows'**
  String get mirrorCamDoneHint;

  /// No description provided for @mirrorShoot.
  ///
  /// In en, this message translates to:
  /// **'Snap'**
  String get mirrorShoot;

  /// No description provided for @mirrorUpload.
  ///
  /// In en, this message translates to:
  /// **'Upload photo'**
  String get mirrorUpload;

  /// No description provided for @mirrorRetake.
  ///
  /// In en, this message translates to:
  /// **'Retake'**
  String get mirrorRetake;

  /// No description provided for @mirrorDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get mirrorDone;

  /// No description provided for @mirrorCamNoAccess.
  ///
  /// In en, this message translates to:
  /// **'No camera access. Please call a shop assistant'**
  String get mirrorCamNoAccess;

  /// No description provided for @mirrorOpenSettings.
  ///
  /// In en, this message translates to:
  /// **'Open Settings'**
  String get mirrorOpenSettings;

  /// No description provided for @mirrorFaceNotFound.
  ///
  /// In en, this message translates to:
  /// **'I can\'t see a face. Step closer'**
  String get mirrorFaceNotFound;

  /// No description provided for @mirrorFaceMultiple.
  ///
  /// In en, this message translates to:
  /// **'There are several faces in the frame'**
  String get mirrorFaceMultiple;

  /// No description provided for @mirrorFaceCloser.
  ///
  /// In en, this message translates to:
  /// **'Step a little closer'**
  String get mirrorFaceCloser;

  /// No description provided for @mirrorFaceTooDark.
  ///
  /// In en, this message translates to:
  /// **'Too dark — move towards the light'**
  String get mirrorFaceTooDark;

  /// No description provided for @mirrorUploadFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t send the photo. Please try again'**
  String get mirrorUploadFailed;

  /// No description provided for @mirrorBodyTitle.
  ///
  /// In en, this message translates to:
  /// **'Tell us about yourself'**
  String get mirrorBodyTitle;

  /// No description provided for @mirrorBodySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Two answers — and the look will truly fit you.'**
  String get mirrorBodySubtitle;

  /// No description provided for @mirrorGenderLabel.
  ///
  /// In en, this message translates to:
  /// **'Gender'**
  String get mirrorGenderLabel;

  /// No description provided for @mirrorShapeLabel.
  ///
  /// In en, this message translates to:
  /// **'Body type'**
  String get mirrorShapeLabel;

  /// No description provided for @mirrorFemale.
  ///
  /// In en, this message translates to:
  /// **'Female'**
  String get mirrorFemale;

  /// No description provided for @mirrorMale.
  ///
  /// In en, this message translates to:
  /// **'Male'**
  String get mirrorMale;

  /// No description provided for @mirrorDontKnow.
  ///
  /// In en, this message translates to:
  /// **'I don\'t know'**
  String get mirrorDontKnow;

  /// No description provided for @mirrorNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get mirrorNext;

  /// No description provided for @mirrorStyleTitle.
  ///
  /// In en, this message translates to:
  /// **'Which style feels like you?'**
  String get mirrorStyleTitle;

  /// No description provided for @mirrorStyleSubtitle.
  ///
  /// In en, this message translates to:
  /// **'You can pick several.'**
  String get mirrorStyleSubtitle;

  /// No description provided for @mirrorCatalogTitle.
  ///
  /// In en, this message translates to:
  /// **'The whole store'**
  String get mirrorCatalogTitle;

  /// No description provided for @mirrorCatalogSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Mark the pieces you like — we\'ll try them on you.'**
  String get mirrorCatalogSubtitle;

  /// No description provided for @mirrorCatalogNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get mirrorCatalogNext;

  /// No description provided for @mirrorPicked.
  ///
  /// In en, this message translates to:
  /// **'Selected'**
  String get mirrorPicked;

  /// No description provided for @mirrorCatalogEmpty.
  ///
  /// In en, this message translates to:
  /// **'No products with photos yet'**
  String get mirrorCatalogEmpty;

  /// No description provided for @mirrorGenTitle.
  ///
  /// In en, this message translates to:
  /// **'Building your look'**
  String get mirrorGenTitle;

  /// No description provided for @mirrorGen1.
  ///
  /// In en, this message translates to:
  /// **'Reading your facial features'**
  String get mirrorGen1;

  /// No description provided for @mirrorGen2.
  ///
  /// In en, this message translates to:
  /// **'Considering your body type'**
  String get mirrorGen2;

  /// No description provided for @mirrorGen3.
  ///
  /// In en, this message translates to:
  /// **'Picking pieces from the store'**
  String get mirrorGen3;

  /// No description provided for @mirrorGen4.
  ///
  /// In en, this message translates to:
  /// **'Assembling the look'**
  String get mirrorGen4;

  /// No description provided for @mirrorGenAlmost.
  ///
  /// In en, this message translates to:
  /// **'Just a moment, almost ready'**
  String get mirrorGenAlmost;

  /// No description provided for @mirrorGenFailed.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get mirrorGenFailed;

  /// No description provided for @mirrorGenRetry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get mirrorGenRetry;

  /// No description provided for @mirrorGenContinueInApp.
  ///
  /// In en, this message translates to:
  /// **'Or continue in the app via QR'**
  String get mirrorGenContinueInApp;

  /// No description provided for @mirrorCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get mirrorCancel;

  /// No description provided for @mirrorLookUnavailable.
  ///
  /// In en, this message translates to:
  /// **'We can\'t build a full look from what\'s in stock right now'**
  String get mirrorLookUnavailable;

  /// No description provided for @mirrorResultTag.
  ///
  /// In en, this message translates to:
  /// **'Your look'**
  String get mirrorResultTag;

  /// Mirror kiosk: number of items in the generated look
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} item} other{{count} items}}'**
  String mirrorItemsCount(int count);

  /// No description provided for @mirrorQrTitle.
  ///
  /// In en, this message translates to:
  /// **'Take the look with you'**
  String get mirrorQrTitle;

  /// No description provided for @mirrorQrSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Point your camera — the photo, sizes and prices will be saved in the LIBAS app.'**
  String get mirrorQrSubtitle;

  /// No description provided for @mirrorDownload.
  ///
  /// In en, this message translates to:
  /// **'Save photo'**
  String get mirrorDownload;

  /// No description provided for @mirrorDownloadHint.
  ///
  /// In en, this message translates to:
  /// **'Scan the QR — the photo will be saved to your phone'**
  String get mirrorDownloadHint;

  /// No description provided for @mirrorRegenerate.
  ///
  /// In en, this message translates to:
  /// **'Regenerate'**
  String get mirrorRegenerate;

  /// Mirror kiosk: regenerate button with remaining attempts
  ///
  /// In en, this message translates to:
  /// **'Regenerate · {count} left'**
  String mirrorRegenerateLeft(int count);

  /// No description provided for @mirrorContinueInApp.
  ///
  /// In en, this message translates to:
  /// **'Continue in the app'**
  String get mirrorContinueInApp;

  /// No description provided for @mirrorCollect.
  ///
  /// In en, this message translates to:
  /// **'Collect for fitting'**
  String get mirrorCollect;

  /// No description provided for @mirrorBuyTitle.
  ///
  /// In en, this message translates to:
  /// **'What you\'re wearing'**
  String get mirrorBuyTitle;

  /// No description provided for @mirrorBuySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Every piece is in stock right now.'**
  String get mirrorBuySubtitle;

  /// No description provided for @mirrorTotal.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get mirrorTotal;

  /// No description provided for @mirrorSizeLabel.
  ///
  /// In en, this message translates to:
  /// **'Size'**
  String get mirrorSizeLabel;

  /// No description provided for @mirrorInStock.
  ///
  /// In en, this message translates to:
  /// **'in stock'**
  String get mirrorInStock;

  /// No description provided for @mirrorCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'Tell this code to a shop assistant — they will collect the pieces for your fitting'**
  String get mirrorCodeLabel;

  /// No description provided for @mirrorBackToLook.
  ///
  /// In en, this message translates to:
  /// **'Back to the look'**
  String get mirrorBackToLook;

  /// No description provided for @mirrorBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get mirrorBack;

  /// No description provided for @mirrorStillHere.
  ///
  /// In en, this message translates to:
  /// **'Are you still here?'**
  String get mirrorStillHere;

  /// Mirror kiosk: idle warning countdown
  ///
  /// In en, this message translates to:
  /// **'The session will close in {seconds} s'**
  String mirrorStillHereHint(int seconds);

  /// No description provided for @mirrorImHere.
  ///
  /// In en, this message translates to:
  /// **'I\'m here'**
  String get mirrorImHere;

  /// No description provided for @mirrorOfflineTitle.
  ///
  /// In en, this message translates to:
  /// **'No connection'**
  String get mirrorOfflineTitle;

  /// No description provided for @mirrorOfflineHint.
  ///
  /// In en, this message translates to:
  /// **'Please call a shop assistant'**
  String get mirrorOfflineHint;

  /// No description provided for @mirrorDemoBadge.
  ///
  /// In en, this message translates to:
  /// **'Demo mode · the catalog is real, the try-on is simulated'**
  String get mirrorDemoBadge;

  /// No description provided for @promoCode.
  ///
  /// In en, this message translates to:
  /// **'Promo code'**
  String get promoCode;

  /// No description provided for @promoHint.
  ///
  /// In en, this message translates to:
  /// **'Enter the code your blogger gave you.'**
  String get promoHint;

  /// No description provided for @promoApply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get promoApply;

  /// No description provided for @promoSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get promoSkip;

  /// No description provided for @promoOnboardingTitle.
  ///
  /// In en, this message translates to:
  /// **'Got a promo code from a blogger?'**
  String get promoOnboardingTitle;

  /// No description provided for @promoAlreadyAttached.
  ///
  /// In en, this message translates to:
  /// **'A promo code is already linked to your account.'**
  String get promoAlreadyAttached;

  /// Promo: discount still available
  ///
  /// In en, this message translates to:
  /// **'−{percent}% off your first purchase'**
  String promoDiscountActive(int percent);

  /// No description provided for @promoDiscountUsed.
  ///
  /// In en, this message translates to:
  /// **'The discount has already been used.'**
  String get promoDiscountUsed;

  /// No description provided for @promoSuccessTitle.
  ///
  /// In en, this message translates to:
  /// **'Promo code applied'**
  String get promoSuccessTitle;

  /// Promo: bonus coins granted
  ///
  /// In en, this message translates to:
  /// **'+{count} diamonds on your balance'**
  String promoSuccessBonus(int count);

  /// Promo: percent discount granted
  ///
  /// In en, this message translates to:
  /// **'−{percent}% off your first purchase'**
  String promoSuccessDiscount(int percent);

  /// No description provided for @promoSuccessOk.
  ///
  /// In en, this message translates to:
  /// **'Great'**
  String get promoSuccessOk;

  /// No description provided for @promoErrNotFound.
  ///
  /// In en, this message translates to:
  /// **'No such promo code'**
  String get promoErrNotFound;

  /// No description provided for @promoErrExpired.
  ///
  /// In en, this message translates to:
  /// **'This promo code has expired'**
  String get promoErrExpired;

  /// No description provided for @promoErrLimit.
  ///
  /// In en, this message translates to:
  /// **'This promo code is no longer valid'**
  String get promoErrLimit;

  /// No description provided for @promoErrAlready.
  ///
  /// In en, this message translates to:
  /// **'You have already activated a promo code'**
  String get promoErrAlready;

  /// No description provided for @promoErrTooManyAttempts.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Please try again later.'**
  String get promoErrTooManyAttempts;

  /// No description provided for @promoErrGeneric.
  ///
  /// In en, this message translates to:
  /// **'Could not apply the promo code. Please try again.'**
  String get promoErrGeneric;
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
