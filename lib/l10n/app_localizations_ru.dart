// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appName => 'LIBAS';

  @override
  String get ok => 'ОК';

  @override
  String get cancel => 'Отмена';

  @override
  String get save => 'Сохранить';

  @override
  String get delete => 'Удалить';

  @override
  String get edit => 'Редактировать';

  @override
  String get removedFromLikedItems => 'Удалено из избранного';

  @override
  String get quantity => 'Количество';

  @override
  String get customerReviewPrompt =>
      'Посмотрите, что говорят другие покупатели об этом товаре';

  @override
  String get jan => 'Янв';

  @override
  String get feb => 'Фев';

  @override
  String get mar => 'Мар';

  @override
  String get apr => 'Апр';

  @override
  String get may => 'Май';

  @override
  String get jun => 'Июн';

  @override
  String get jul => 'Июл';

  @override
  String get aug => 'Авг';

  @override
  String get sep => 'Сен';

  @override
  String get oct => 'Окт';

  @override
  String get nov => 'Ноя';

  @override
  String get dec => 'Дек';

  @override
  String get order => 'Заказ';

  @override
  String get trackingNumber => 'Номер отслеживания';

  @override
  String get items => 'Товары';

  @override
  String get products => 'товаров';

  @override
  String get allProducts => 'Все товары';

  @override
  String get total => 'Итого';

  @override
  String get track => 'Отследить';

  @override
  String get reorder => 'Заказать снова';

  @override
  String get trackingComingSoon => 'Отслеживание скоро';

  @override
  String get reorderComingSoon => 'Повторный заказ скоро';

  @override
  String get enterPhoneNumber => 'Введите номер телефона';

  @override
  String get phoneVerificationSubtitle =>
      'Мы отправим вам код подтверждения для проверки номера';

  @override
  String get phoneNumber => 'Номер телефона';

  @override
  String get iAgreeToThe => 'Я согласен с ';

  @override
  String get byContinuingYouAgreeTo => 'Продолжая, вы принимаете наши ';

  @override
  String get agreeToTermsSuffix => '';

  @override
  String get termsOfService => 'Условия обслуживания';

  @override
  String get and => ' и ';

  @override
  String get privacyPolicy => 'Политика конфиденциальности';

  @override
  String get continueButton => 'Продолжить';

  @override
  String get contactSupport => 'Проблемы? Обратитесь в поддержку';

  @override
  String get agreeToTermsError =>
      'Пожалуйста, согласитесь с Условиями и Политикой конфиденциальности';

  @override
  String get otpSendError => 'Не удалось отправить код. Попробуйте еще раз.';

  @override
  String get verifyPhoneNumber => 'Подтвердите свой\nномер телефона';

  @override
  String get enterDigitCode => 'Введите 6-значный код, отправленный на\n';

  @override
  String get completeOtpError => 'Пожалуйста, введите полный код';

  @override
  String get invalidOtpError => 'Неверный код. Попробуйте еще раз.';

  @override
  String get otpSentSuccess => 'Код успешно отправлен';

  @override
  String get resendOtpError =>
      'Не удалось повторно отправить код. Попробуйте еще раз.';

  @override
  String get resendCode => 'Отправить код повторно';

  @override
  String resendCodeIn(int seconds) {
    return 'Отправить код повторно через $seconds сек';
  }

  @override
  String get verify => 'Подтвердить';

  @override
  String get wrongNumber => 'Неправильный номер?';

  @override
  String get serverError502 =>
      'Сервер временно недоступен. Попробуйте через мгновение.';

  @override
  String get serverError503 => 'Сервис временно недоступен. Попробуйте позже.';

  @override
  String get serverError504 =>
      'Время ожидания запроса истекло. Попробуйте позже.';

  @override
  String get serverError500 =>
      'Что-то пошло не так на нашей стороне. Попробуйте позже.';

  @override
  String get serverErrorGeneric =>
      'Произошла ошибка сервера. Попробуйте позже.';

  @override
  String get serverMaintenanceTitle => 'Мы скоро вернёмся';

  @override
  String get serverMaintenanceSubtitle =>
      'Идут технические работы, сервис временно недоступен. Вам не нужно входить заново — пожалуйста, зайдите через несколько минут.';

  @override
  String get tellUsAboutYourself => 'Расскажите\no себе';

  @override
  String get personalizeExperience =>
      'Это поможет нам персонализировать ваш опыт';

  @override
  String get fullName => 'Полное имя';

  @override
  String get enterYourName => 'Введите ваше имя';

  @override
  String get gender => 'Пол';

  @override
  String get male => 'Мужской';

  @override
  String get female => 'Женский';

  @override
  String get dateOfBirth => 'Дата рождения';

  @override
  String get day => 'День';

  @override
  String get month => 'Месяц';

  @override
  String get year => 'Год';

  @override
  String get january => 'Январь';

  @override
  String get february => 'Февраль';

  @override
  String get march => 'Март';

  @override
  String get april => 'Апрель';

  @override
  String get june => 'Июнь';

  @override
  String get july => 'Июль';

  @override
  String get august => 'Август';

  @override
  String get september => 'Сентябрь';

  @override
  String get october => 'Октябрь';

  @override
  String get november => 'Ноябрь';

  @override
  String get december => 'Декабрь';

  @override
  String get selectBirthDate => 'Пожалуйста, выберите дату рождения';

  @override
  String get selectGenderError => 'Пожалуйста, выберите ваш пол';

  @override
  String get selectDateError => 'Пожалуйста, выберите дату рождения';

  @override
  String get saveInfoError =>
      'Не удалось сохранить информацию. Попробуйте еще раз.';

  @override
  String get yourStylePreference => 'Ваши стилевые предпочтения';

  @override
  String get relevantFashionChoices =>
      'Это поможет нам показать вам наиболее подходящие варианты одежды';

  @override
  String get covered => 'Закрытая';

  @override
  String get modestFashionHijab => 'Скромная мода с хиджабом';

  @override
  String get uncovered => 'Открытая';

  @override
  String get traditionalFashionStyles => 'Традиционные стили моды';

  @override
  String get selectPreferenceError => 'Пожалуйста, выберите предпочтение';

  @override
  String get savePreferenceError =>
      'Не удалось сохранить предпочтение. Попробуйте еще раз.';

  @override
  String get primaryObjective => 'Какова ваша основная цель?';

  @override
  String get selectWhatMatters =>
      'Выберите, что наиболее важно для вас при покупке одежды';

  @override
  String get havingOwnStylist => 'Иметь собственного стилиста';

  @override
  String get findBestFit => 'Найти идеальную посадку';

  @override
  String get funSurprise => 'Приятный сюрприз';

  @override
  String get uniquePieces => 'Уникальные вещи';

  @override
  String get updateLook => 'Обновить свой стиль';

  @override
  String get saveTimeShopping => 'Экономить время на покупках';

  @override
  String get tryNewTrends => 'Пробовать новые тренды';

  @override
  String get browsePersonalizedShop =>
      'Просматривать персонализированный магазин';

  @override
  String get selectObjectiveError => 'Пожалуйста, выберите цель';

  @override
  String get saveObjectiveError =>
      'Не удалось сохранить цель. Попробуйте еще раз.';

  @override
  String get fitPreference => 'Предпочтение посадки';

  @override
  String get howDoYouPreferClothesToFit =>
      'Как вы предпочитаете, чтобы одежда сидела?';

  @override
  String get loose => 'Свободно';

  @override
  String get comfortableRelaxedFit => 'Удобная, расслабленная посадка';

  @override
  String get regular => 'Обычно';

  @override
  String get standardComfortableFit => 'Стандартная, удобная посадка';

  @override
  String get tight => 'Обтягивающе';

  @override
  String get formFittingTailoredLook => 'Облегающий, приталенный вид';

  @override
  String get selectFitError => 'Пожалуйста, выберите предпочтение по посадке';

  @override
  String get saveFitError =>
      'Не удалось сохранить предпочтение по посадке. Попробуйте еще раз.';

  @override
  String get sizeProfile => 'Профиль размеров';

  @override
  String get helpUsRecommendPerfectSizes =>
      'Помогите нам рекомендовать идеальные размеры для вас';

  @override
  String get height => 'Рост';

  @override
  String get weight => 'Вес';

  @override
  String get bodyType => 'Тип фигуры';

  @override
  String get selectBodyTypeHelpRecommend =>
      'Выберите тип фигуры, чтобы мы могли порекомендовать наиболее подходящие стили';

  @override
  String get hourglass => 'Песочные часы';

  @override
  String get hourglassDescription => 'Талия - самая узкая часть фигуры';

  @override
  String get triangle => 'Треугольник';

  @override
  String get triangleDescription => 'Бедра шире плеч';

  @override
  String get rectangle => 'Прямоугольник';

  @override
  String get rectangleDescription =>
      'Бедра, плечи и талия одинаковых пропорций';

  @override
  String get oval => 'Овал';

  @override
  String get ovalDescription => 'Бедра и плечи уже талии';

  @override
  String get heart => 'Сердце';

  @override
  String get heartDescription => 'Бедра уже плеч';

  @override
  String get selectBodyTypeError => 'Пожалуйста, выберите тип фигуры';

  @override
  String get saveBodyTypeError =>
      'Не удалось сохранить тип фигуры. Попробуйте еще раз.';

  @override
  String get yourSizes => 'Ваши размеры';

  @override
  String get enterSizesForBetterRecommendations =>
      'Введите ваши размеры для лучших рекомендаций';

  @override
  String get whatSizesTypicallyWear => 'Какие размеры вы обычно носите?';

  @override
  String get helpsShowPerfectlyFittedItems =>
      'Это поможет нам показать идеально подходящие вещи';

  @override
  String get tops => 'Верх';

  @override
  String get bottoms => 'Низ';

  @override
  String get dresses => 'Платья';

  @override
  String get jeanWaist => 'Талия джинсов';

  @override
  String get braBand => 'Объем бюстгальтера';

  @override
  String get braCup => 'Размер чашки';

  @override
  String get shoeSize => 'Размер обуви';

  @override
  String get budgetPreference => 'Предпочтения по бюджету';

  @override
  String get whatsYourIdealPriceRange =>
      'Какой ваш идеальный ценовой диапазон для модных товаров?';

  @override
  String get whatsYourBudgetRange => 'Каков ваш бюджетный диапазон?';

  @override
  String get showItemsWithinPriceRange =>
      'Мы покажем вам товары в вашем ценовом диапазоне';

  @override
  String get budgetFriendly => 'Бюджетный';

  @override
  String get under500k => 'До 500 000 сум';

  @override
  String get moderate => 'Умеренный';

  @override
  String get range500kTo1500k => '500 000 - 1 500 000 сум';

  @override
  String get premium => 'Премиум';

  @override
  String get range1500kTo3000k => '1 500 000 - 3 000 000 сум';

  @override
  String get luxury => 'Люкс';

  @override
  String get over3000k => 'Свыше 3 000 000 сум';

  @override
  String get flexible => 'Гибкий';

  @override
  String get showMeEverything => 'Показать мне всё';

  @override
  String get changeAnytimeInSettings =>
      'Вы можете изменить это в настройках в любое время';

  @override
  String get setBudgetPreferences => 'Установите ваш бюджет\nпредпочтения';

  @override
  String get choosePriceRange =>
      'Выберите ценовой диапазон для каждой категории';

  @override
  String get budgetUnder500k => 'До 500,000 сум';

  @override
  String get budget500kTo1m => '500,000 - 1,000,000 сум';

  @override
  String get budget1mTo1_5m => '1,000,000 - 1,500,000 сум';

  @override
  String get budget1_5mTo2m => '1,500,000 - 2,000,000 сум';

  @override
  String get budget2mPlus => 'Более 2,000,000 сум';

  @override
  String get categoryTops => 'Верхняя одежда';

  @override
  String get categoryBottoms => 'Низ';

  @override
  String get categoryJacketsCoats => 'Куртки и пальто';

  @override
  String get categoryDresses => 'Платья';

  @override
  String get categoryShoes => 'Обувь';

  @override
  String get categoryAccessories => 'Аксессуары';

  @override
  String get categoryJewelry => 'Украшения';

  @override
  String get completeSetup => 'Завершить настройку';

  @override
  String get authenticationRequired =>
      'Требуется аутентификация. Пожалуйста, войдите в систему.';

  @override
  String get pleaseCompleteAllFields =>
      'Пожалуйста, заполните все обязательные поля';

  @override
  String get failedToCreateProfile => 'Не удалось создать профиль';

  @override
  String get styleQuiz => 'Тест стиля';

  @override
  String get skip => 'Пропустить';

  @override
  String get pass => 'Пропустить';

  @override
  String get info => 'Инфо';

  @override
  String get like => 'Нравится';

  @override
  String get analyzingYourStyle => 'Анализируем ваш стиль...';

  @override
  String get gotIt => 'Понятно';

  @override
  String get discoverYourStylePreference =>
      'Откройте для себя свои стилевые предпочтения';

  @override
  String get casualWear => 'Повседневная одежда';

  @override
  String get businessFormal => 'Деловой стиль';

  @override
  String get streetwear => 'Уличный';

  @override
  String get athleticWear => 'Спортивная одежда';

  @override
  String get vintageFashion => 'Винтажная мода';

  @override
  String get minimalist => 'Минималистичный';

  @override
  String get boldPatterns => 'Яркие принты';

  @override
  String get bohemian => 'Богемный';

  @override
  String get elegantEvening => 'Элегантный вечерний';

  @override
  String get smartCasual => 'Умный кэжуал';

  @override
  String get modernChic => 'Современный шик';

  @override
  String get classicStyle => 'Классический стиль';

  @override
  String get trendy => 'Модный';

  @override
  String get sporty => 'Спортивный';

  @override
  String get sophisticated => 'Изысканный';

  @override
  String get comfortable => 'Удобный';

  @override
  String get dressy => 'Нарядный';

  @override
  String get everyday => 'Повседневный';

  @override
  String get weekend => 'Выходной';

  @override
  String get office => 'Офисный';

  @override
  String get evening => 'Вечерний';

  @override
  String get casualChic => 'Кэжуал шик';

  @override
  String get urban => 'Городской';

  @override
  String get contemporary => 'Современный';

  @override
  String get timeless => 'Вневременной';

  @override
  String get fashionForward => 'Авангардный';

  @override
  String get relaxed => 'Расслабленный';

  @override
  String get polished => 'Отполированный';

  @override
  String get effortless => 'Непринужденный';

  @override
  String get statement => 'Яркий';

  @override
  String get selectBudgetError => 'Пожалуйста, выберите ценовой диапазон';

  @override
  String get saveBudgetError =>
      'Не удалось сохранить бюджетное предпочтение. Попробуйте еще раз.';

  @override
  String get completeOnboarding => 'Завершить настройку';

  @override
  String get readyToStartShopping => 'Всё готово! Готовы начать покупки?';

  @override
  String get letsGo => 'Поехали!';

  @override
  String get completionError =>
      'Не удалось завершить настройку. Попробуйте еще раз.';

  @override
  String get youreAllSet => 'Всё готово! 🎉';

  @override
  String get preparingYourFeed => 'Подготовка вашей персональной ленты...';

  @override
  String get startDiscoveringFashion =>
      'Начните открывать\nмоду, созданную для вас';

  @override
  String get startExploring => 'Начать просмотр';

  @override
  String get intentTitle => 'С чего хотите начать?';

  @override
  String get intentSubtitle =>
      'Выберите, с чего начать — всё остальное всегда доступно.';

  @override
  String get intentDiscoverTitle => 'LIBΛS Свайпы';

  @override
  String get intentDiscoverSubtitle => 'Свайпайте и находите образы для вас';

  @override
  String get intentShopSubtitle => 'Покупайте у любимых брендов';

  @override
  String get intentMarketSubtitle => 'Покупайте и продавайте вещи';

  @override
  String get intentClosetSubtitle => 'Организуйте гардероб и примеряйте образы';

  @override
  String get intentFeedSubtitle => 'Вдохновляйтесь образами сообщества';

  @override
  String get add => 'Добавить';

  @override
  String get confirm => 'Подтвердить';

  @override
  String get yes => 'Да';

  @override
  String get no => 'Нет';

  @override
  String get search => 'Поиск';

  @override
  String get filter => 'Фильтр';

  @override
  String get sort => 'Сортировка';

  @override
  String get apply => 'Применить';

  @override
  String get reset => 'Сбросить';

  @override
  String get done => 'Готово';

  @override
  String get next => 'Далее';

  @override
  String get back => 'Назад';

  @override
  String get loading => 'Загрузка...';

  @override
  String get error => 'Ошибка';

  @override
  String get success => 'Успешно';

  @override
  String get tryAgain => 'Попробовать снова';

  @override
  String get close => 'Закрыть';

  @override
  String get dismiss => 'Закрыть';

  @override
  String get welcomeToSwipe => 'Добро пожаловать в LIBAS';

  @override
  String get discoverYourStyle =>
      'Откройте свой идеальный стиль с модными рекомендациями на основе ИИ';

  @override
  String get selectLanguage => 'Выберите язык';

  @override
  String get continueText => 'Продолжить';

  @override
  String get verificationCode => 'Код подтверждения';

  @override
  String get enterVerificationCode =>
      'Введите код подтверждения, отправленный на';

  @override
  String get verifying => 'Проверка...';

  @override
  String get invalidPhoneNumber => 'Неверный номер телефона';

  @override
  String get invalidVerificationCode => 'Неверный код подтверждения';

  @override
  String get discover => 'Открыть';

  @override
  String get forYou => 'Для вас';

  @override
  String get swipeRightToLike => 'Свайп вправо для лайка';

  @override
  String get swipeLeftToPass => 'Свайп влево для пропуска';

  @override
  String get swipeUpToAddToCart => 'Свайп вверх чтобы добавить в корзину';

  @override
  String get addedToCart => 'Добавлено в корзину!';

  @override
  String get viewCart => 'Корзина';

  @override
  String get failedToLoadProducts => 'Не удалось загрузить товары';

  @override
  String get passed => 'Пропущено';

  @override
  String get addedToLiked => 'Добавлено в избранное!';

  @override
  String get liked => 'Избранное';

  @override
  String get likedItems => 'Избранные товары';

  @override
  String get saved => 'Сохранено';

  @override
  String get noLikedItemsYet => 'Пока нет избранных товаров';

  @override
  String get startSwipingAndSave =>
      'Начните свайпать и сохраняйте понравившиеся товары';

  @override
  String get clearAll => 'Очистить все';

  @override
  String get clearedAllLikedItems => 'Все избранные товары удалены';

  @override
  String removedItem(String item) {
    return 'Удален $item';
  }

  @override
  String get undo => 'Отменить';

  @override
  String get undoNotImplemented => 'Функция отмены еще не реализована';

  @override
  String get removeFromLiked => 'Удалить из избранного?';

  @override
  String get removeFromLikedMessage =>
      'Вы уверены, что хотите удалить этот товар из избранного?';

  @override
  String get remove => 'Удалить';

  @override
  String get shop => 'Магазин';

  @override
  String get market => 'Маркет';

  @override
  String get feed => 'Лента';

  @override
  String get marketComingSoon => 'Скоро здесь вы сможете продавать свои вещи';

  @override
  String get visualSearch => 'Поиск';

  @override
  String get categories => 'Категории';

  @override
  String get all => 'Все';

  @override
  String get clothing => 'Одежда';

  @override
  String get shoes => 'Обувь';

  @override
  String get accessories => 'Аксессуары';

  @override
  String get coverage => 'Покрытие';

  @override
  String get searchForClothes => 'Спросите что угодно...';

  @override
  String get trending => 'В тренде';

  @override
  String get newItems => 'Новинки';

  @override
  String get sale => 'Скидки';

  @override
  String get aiScan => 'Визуальный Поиск';

  @override
  String get takePhoto => 'Сделать фото';

  @override
  String get uploadFromLibrary => 'Загрузить из галереи';

  @override
  String get selectArea => 'Выбрать область';

  @override
  String get resetSelection => 'Сбросить';

  @override
  String get searchThisArea => 'Искать в этой области';

  @override
  String get noProductsFound => 'Товары не найдены';

  @override
  String get tryDifferentFilters =>
      'Попробуйте изменить параметры поиска или фильтры';

  @override
  String get tryAdjustingFilters => 'Попробуйте изменить фильтры';

  @override
  String get cart => 'Корзина';

  @override
  String get myCart => 'Моя корзина';

  @override
  String get cartEmpty => 'Ваша корзина пуста';

  @override
  String get startShoppingNow => 'Начать покупки сейчас';

  @override
  String get item => 'Товар';

  @override
  String get subtotal => 'Промежуточный итог';

  @override
  String get tax => 'Налог';

  @override
  String get delivery => 'Доставка';

  @override
  String get proceedToCheckout => 'Перейти к оформлению';

  @override
  String get removeFromCart => 'Удалить из корзины?';

  @override
  String get removeFromCartMessage =>
      'Вы уверены, что хотите удалить этот товар?';

  @override
  String get clearCart => 'Очистить корзину';

  @override
  String get clearCartMessage =>
      'Вы уверены, что хотите удалить все товары из корзины?';

  @override
  String get productDetails => 'Детали товара';

  @override
  String get size => 'Размер';

  @override
  String get selectSize => 'Выберите размер';

  @override
  String get selectSizeAndColor => 'Выберите размер и цвет';

  @override
  String get thatsAllForNow => 'Это все на данный момент!';

  @override
  String get findingMoreItems => 'Мы ищем больше товаров для вас';

  @override
  String get refreshFeed => 'Обновить ленту';

  @override
  String get pleaseSelectSize => 'Пожалуйста, выберите размер';

  @override
  String get pleaseSelectColor => 'Пожалуйста, выберите цвет';

  @override
  String get oneSize => 'Универсальный размер';

  @override
  String get color => 'Цвет';

  @override
  String get selectColor => 'Выберите цвет';

  @override
  String get description => 'Описание';

  @override
  String get reviews => 'Отзывы';

  @override
  String reviewsCount(int count) {
    return '$count отзывов';
  }

  @override
  String get seeAll => 'Смотреть все';

  @override
  String get rating => 'Рейтинг';

  @override
  String get addToCart => 'Добавить в корзину';

  @override
  String get checkAvailability => 'Проверить наличие';

  @override
  String get buyNow => 'Купить сейчас';

  @override
  String get inStock => 'В наличии';

  @override
  String get outOfStock => 'Нет в наличии';

  @override
  String get newLabel => 'НОВЫЙ';

  @override
  String get category => 'Категория';

  @override
  String get subcategory => 'Подкатегория';

  @override
  String get material => 'Материал';

  @override
  String get season => 'Сезон';

  @override
  String get countryOfOrigin => 'Страна производства';

  @override
  String get seller => 'Продавец';

  @override
  String get visitShop => 'Посетить магазин';

  @override
  String get whereToBuy => 'Где купить';

  @override
  String get getDirections => 'Посмотреть на карте';

  @override
  String get viewAllProducts => 'Смотреть все товары';

  @override
  String get availability => 'Наличие';

  @override
  String get fitMatch => 'Соответствие размера';

  @override
  String get styleMatch => 'Соответствие стиля';

  @override
  String get addedToLikedItems => 'Добавлено в избранное';

  @override
  String get similarProducts => 'Похожие товары';

  @override
  String get vsPickCategory => 'Обрезать изображение';

  @override
  String get vsSearchButton => 'Найти';

  @override
  String get vsCatTopwear => 'Верхняя одежда';

  @override
  String get vsCatBottomwear => 'Нижняя одежда';

  @override
  String get vsCatDresses => 'Платья';

  @override
  String get vsCatOuterwear => 'Верхняя одежда';

  @override
  String get vsCatOnePiece => 'Цельная одежда';

  @override
  String get vsCatActivewear => 'Спортивная одежда';

  @override
  String get vsCatAccessories => 'Аксессуары';

  @override
  String get vsCatFootwear => 'Обувь';

  @override
  String get vsCatUnderwear => 'Бельё';

  @override
  String get vsCatModestWear => 'Закрытая одежда';

  @override
  String get vsCatTwoPieceSet => 'Двойки';

  @override
  String get vsCatThreePieceSet => 'Тройки';

  @override
  String get vsCatBodysuits => 'Боди и трико';

  @override
  String get vsCatHomewear => 'Домашняя одежда';

  @override
  String get visualSearchResults => 'Результаты визуального поиска';

  @override
  String get searchResults => 'Результаты поиска';

  @override
  String get sellers => 'Продавцы';

  @override
  String get browseSellers => 'Магазины';

  @override
  String get searchSellers => 'Поиск продавцов...';

  @override
  String get noSellersFound => 'Продавцы не найдены';

  @override
  String get noSellersFoundSubtitle => 'Попробуйте изменить запрос';

  @override
  String get loadingSellers => 'Загрузка продавцов...';

  @override
  String productsCount(int count) {
    return '$count товаров';
  }

  @override
  String get productsFound => 'товаров найдено';

  @override
  String get tryDifferentSearch =>
      'Попробуйте поискать по другим ключевым словам';

  @override
  String get yourSearchImage => 'Ваше изображение для поиска';

  @override
  String get analyzingImageWithAI => 'Ищем похожие стили...';

  @override
  String get aiAnalysis => 'Анализ ИИ';

  @override
  String similarProductsCount(int count) {
    return '$count похожих товаров';
  }

  @override
  String get hijabAppropriate => 'Подходит для хиджаба';

  @override
  String visualSearchFailed(String error) {
    return 'Визуальный поиск не удался: $error';
  }

  @override
  String get visualSearchError =>
      'Что-то пошло не так. Пожалуйста, попробуйте ещё раз.';

  @override
  String get orders => 'Заказы';

  @override
  String get myOrders => 'Мои заказы';

  @override
  String get orderHistory => 'История заказов';

  @override
  String get orderHistoryAppearHere => 'Ваша история заказов появится здесь';

  @override
  String get noOrdersYet => 'Пока нет заказов';

  @override
  String get noOrdersReceivedYet => 'Пока не получено заказов';

  @override
  String get customerOrdersAppearHere =>
      'Здесь будут появляться заказы от покупателей';

  @override
  String get errorLoadingOrders => 'Ошибка загрузки заказов';

  @override
  String get retry => 'Повторить';

  @override
  String get startShoppingToSeeOrders =>
      'Начните делать покупки, чтобы увидеть историю заказов здесь';

  @override
  String get startShopping => 'Начать покупки';

  @override
  String itemsCount(int count) {
    return '$count товаров';
  }

  @override
  String ordersCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count заказов',
      two: '2 заказа',
      one: '1 заказ',
    );
    return '$_temp0';
  }

  @override
  String chatsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count диалогов',
      two: '2 диалога',
      one: '1 диалог',
    );
    return '$_temp0';
  }

  @override
  String get totalAmount => 'Общая сумма';

  @override
  String get viewDetails => 'Посмотреть детали';

  @override
  String get orderNumber => 'Заказ №';

  @override
  String get orderDate => 'Дата заказа';

  @override
  String get orderStatus => 'Статус';

  @override
  String get orderTotal => 'Итого';

  @override
  String get trackOrder => 'Отследить заказ';

  @override
  String get orderDetails => 'Детали заказа';

  @override
  String get cancelOrder => 'Отменить заказ';

  @override
  String get waiting => 'Ожидает подтверждения';

  @override
  String get confirmed => 'Подтвержден';

  @override
  String get processing => 'Обработка';

  @override
  String get shipped => 'Отправлен';

  @override
  String get outForDelivery => 'В пути';

  @override
  String get delivered => 'Доставлен';

  @override
  String get cancelled => 'Отменен';

  @override
  String get created => 'Создан';

  @override
  String get paid => 'Оплачен';

  @override
  String get refunded => 'Возвращён';

  @override
  String get returned => 'Возврат товара';

  @override
  String get readyToShip => 'Готов к отправке';

  @override
  String get readyForPickup => 'Готов к выдаче';

  @override
  String get voided => 'Аннулирован';

  @override
  String get chat => 'Чат';

  @override
  String get noMessagesYet => 'Пока нет сообщений';

  @override
  String get contactSellersFromProduct =>
      'Свяжитесь с продавцами из деталей продукта, чтобы узнать о наличии, размерах и многом другом';

  @override
  String aboutProduct(String productName) {
    return 'О товаре: $productName';
  }

  @override
  String minutesAgo(int minutes) {
    return '$minutes мин назад';
  }

  @override
  String hoursAgo(int hours) {
    return '$hours ч назад';
  }

  @override
  String daysAgo(int days) {
    return '$days дн назад';
  }

  @override
  String get yesterday => 'Вчера';

  @override
  String get chatToday => 'Сегодня';

  @override
  String get chatPresenceOnline => 'онлайн';

  @override
  String get chatPresenceOffline => 'офлайн';

  @override
  String get chatPresenceTyping => 'печатает...';

  @override
  String get chatLastSeenJustNow => 'только что';

  @override
  String chatLastSeenMinutes(int minutes) {
    return '$minutes мин назад';
  }

  @override
  String chatLastSeenHours(int hours) {
    return '$hours ч назад';
  }

  @override
  String chatLastSeenDays(int days) {
    return '$days дн назад';
  }

  @override
  String get chatFailedToLoad => 'Не удалось загрузить чат';

  @override
  String get chatFailedToReload => 'Не удалось обновить чат';

  @override
  String get chatReconnecting =>
      'Переподключение… попробуйте снова через мгновение.';

  @override
  String get chatGoBack => 'Назад';

  @override
  String get chatNotFound => 'Чат не найден';

  @override
  String get chatFailedToLoadProduct =>
      'Не удалось загрузить информацию о товаре';

  @override
  String get interestedInProduct => 'Привет, есть ли в наличии этот продукт?';

  @override
  String get sellerAutoResponse =>
      'Спасибо за ваше сообщение! Я проверю и свяжусь с вами в ближайшее время.';

  @override
  String get typeMessage => 'Введите сообщение...';

  @override
  String get chatAttachPhoto => 'Фото';

  @override
  String get chatAttachLocation => 'Местоположение';

  @override
  String get chatAttachButton => 'Прикрепить';

  @override
  String get chatOpenInMaps => 'Открыть в Картах';

  @override
  String get chatAttachCamera => 'Камера';

  @override
  String get chatAttachGallery => 'Галерея';

  @override
  String get chatAttachGallerySubtitle => 'Выбрать из галереи';

  @override
  String get chatAttachCameraSubtitle => 'Сделать фото';

  @override
  String get chatAttachPickHint => 'Сделайте фото или выберите из галереи';

  @override
  String get chatAttachComingSoon =>
      'Отправка фото и геолокации скоро появится';

  @override
  String get typeAMessage => 'Введите ваше сообщение...';

  @override
  String get newMessage => 'Новое сообщение';

  @override
  String get sendMessage => 'Отправить';

  @override
  String get sizeLabel => 'Размер:';

  @override
  String get qtyLabel => 'Кол-во:';

  @override
  String get checkout => 'Оформление';

  @override
  String get shippingAddress => 'Адрес доставки';

  @override
  String get deliveryAddress => 'Адрес доставки';

  @override
  String get selectAddress => 'Выбрать адрес';

  @override
  String get noAddressSelected => 'Адрес не выбран';

  @override
  String get changeAddress => 'Изменить адрес';

  @override
  String get addNewAddress => 'Добавить новый адрес';

  @override
  String get deliveryMethod => 'Способ доставки';

  @override
  String get customerName => 'Имя покупателя';

  @override
  String get customerPhone => 'Телефон покупателя';

  @override
  String get changeStatus => 'Изменить статус';

  @override
  String get pickupInStore => 'Самовывоз из магазина';

  @override
  String get availableForPickup => 'Доступно для самовывоза';

  @override
  String get standard => 'Стандартный';

  @override
  String get express => 'Экспресс';

  @override
  String get sameDay => 'В тот же день';

  @override
  String businessDays(int min, int max) {
    return 'рабочих дней';
  }

  @override
  String get tashkentOnly => 'Только Ташкент';

  @override
  String get paymentMethod => 'Способ оплаты';

  @override
  String get selectPaymentMethod => 'Выберите способ оплаты';

  @override
  String get noPaymentMethodSelected => 'Способ оплаты не выбран';

  @override
  String get addPayment => 'Добавить платеж';

  @override
  String get changePayment => 'Изменить платеж';

  @override
  String get addPaymentMethod => 'Добавить способ оплаты';

  @override
  String get paymentSelectionComingSoon =>
      'Выбор способа оплаты скоро появится';

  @override
  String get cashOnDelivery => 'Наличными при получении';

  @override
  String get cardPayment => 'Оплата картой';

  @override
  String get pickup => 'Самовывоз';

  @override
  String get payWhenYouReceive => 'Оплата наличными или картой при получении';

  @override
  String get qty => 'Кол-во';

  @override
  String get pleaseSelectDeliveryAddress =>
      'Пожалуйста, выберите адрес доставки';

  @override
  String get pleaseSelectPaymentMethod => 'Пожалуйста, выберите способ оплаты';

  @override
  String get orderSummary => 'Сводка заказа';

  @override
  String orderItems(int count) {
    return '$count позиций в заказе';
  }

  @override
  String get deliveryFee => 'Стоимость доставки';

  @override
  String get placeOrder => 'Оформить заказ';

  @override
  String errorPlacingOrder(String error) {
    return 'Ошибка при оформлении заказа: $error';
  }

  @override
  String get orderPlaced => 'Заказ размещен!';

  @override
  String get orderPlacedSuccessfully => 'Заказ успешно размещен!';

  @override
  String get orderConfirmation => 'Ваш заказ успешно размещен';

  @override
  String get orderConfirmedMessage =>
      'Спасибо за ваш заказ! Мы будем присылать вам обновления по мере выполнения заказа.';

  @override
  String get orderConfirmed => 'Заказ подтвержден';

  @override
  String get orderId => 'ID заказа';

  @override
  String get continueShopping => 'Продолжить покупки';

  @override
  String get estimatedDelivery => 'Ориентировочная доставка';

  @override
  String get addresses => 'Адреса';

  @override
  String get myAddresses => 'Мои адреса';

  @override
  String get noAddressesSaved => 'Пока нет сохраненных адресов';

  @override
  String get noAddresses => 'Нет адресов';

  @override
  String get addDeliveryAddressToContinue =>
      'Добавьте адрес доставки для продолжения';

  @override
  String get addYourFirstAddress =>
      'Добавьте свой первый адрес для быстрого оформления заказа';

  @override
  String get addAddress => 'Добавить адрес';

  @override
  String get editAddress => 'Редактировать адрес';

  @override
  String get deleteAddress => 'Удалить адрес';

  @override
  String get deleteAddressMessage =>
      'Вы уверены, что хотите удалить этот адрес?';

  @override
  String get addressDeleted => 'Адрес удален';

  @override
  String get defaultAddressUpdated => 'Адрес по умолчанию обновлен';

  @override
  String get setDefault => 'Сделать основным';

  @override
  String get contactInformation => 'Контактная информация';

  @override
  String get enterYourFullName => 'Введите ваше полное имя';

  @override
  String get pleaseEnterFullName => 'Пожалуйста, введите ваше полное имя';

  @override
  String get phoneNumberShort => 'Телефон';

  @override
  String get phoneNumberLabel => 'Номер телефона';

  @override
  String get phoneNumberHint => '+998 90 123 45 67';

  @override
  String get pleaseEnterPhoneNumber => 'Пожалуйста, введите номер телефона';

  @override
  String get addressInformation => 'Информация об адресе';

  @override
  String get streetAddress => 'Адрес улицы';

  @override
  String get houseNumberAndStreetName => 'Номер дома и название улицы';

  @override
  String get pleaseEnterStreetAddress => 'Пожалуйста, введите адрес улицы';

  @override
  String get apartmentUnitOptional => 'Квартира/Офис (Необязательно)';

  @override
  String get aptSuiteUnitBuilding => 'Квартира, Офис, Здание';

  @override
  String get addressLine1 => 'Адрес строка 1';

  @override
  String get addressLine2 => 'Адрес строка 2 (Необязательно)';

  @override
  String get city => 'Город';

  @override
  String get selectCity => 'Выберите город';

  @override
  String get region => 'Регион';

  @override
  String get regionDistrict => 'Регион/Район';

  @override
  String get selectRegion => 'Выберите регион';

  @override
  String get postalCode => 'Почтовый индекс';

  @override
  String get postalCodeHint => '100000';

  @override
  String get pleaseEnterPostalCode => 'Пожалуйста, введите почтовый индекс';

  @override
  String get landmarkOptional => 'Ориентир (Необязательно)';

  @override
  String get nearbyLandmarkForDelivery =>
      'Ближайший ориентир для удобной доставки';

  @override
  String get setAsDefault => 'Установить по умолчанию';

  @override
  String get setAsDefaultAddressDescription =>
      'Этот адрес будет использоваться для всех доставок по умолчанию';

  @override
  String get defaultAddress => 'По умолчанию';

  @override
  String get saveAddress => 'Сохранить адрес';

  @override
  String get updateAddress => 'Обновить адрес';

  @override
  String errorSavingAddress(String error) {
    return 'Ошибка сохранения адреса: $error';
  }

  @override
  String get fillAllFields => 'Пожалуйста, заполните все обязательные поля';

  @override
  String get paymentMethods => 'Способы оплаты';

  @override
  String get myPaymentMethods => 'Мои способы оплаты';

  @override
  String get noPaymentMethods => 'Нет добавленных способов оплаты';

  @override
  String get addYourFirstPaymentMethod =>
      'Добавьте способ оплаты для быстрого оформления';

  @override
  String get payOnline => 'Оплата онлайн';

  @override
  String get cardNumber => 'Номер карты';

  @override
  String get cardHolder => 'Имя держателя карты';

  @override
  String get expiryDate => 'Срок действия';

  @override
  String get cvv => 'CVV';

  @override
  String get saveCard => 'Сохранить карту';

  @override
  String get closet => 'Гардероб';

  @override
  String get profile => 'Профиль';

  @override
  String get myProfile => 'Мой профиль';

  @override
  String get editProfile => 'Редактировать профиль';

  @override
  String get editProfileComingSoon =>
      'Функция редактирования профиля скоро появится';

  @override
  String get myQrCode => 'Мой QR-код';

  @override
  String get scanQrForCashback =>
      'Покажите этот QR-код партнерам для получения кэшбэка';

  @override
  String get svaypCardTitle => 'Карта LIBAS';

  @override
  String get svaypCardCashbackDesc => '2% кэшбэк с каждой покупки';

  @override
  String get openQrButton => 'Открыть';

  @override
  String get qrFullScreenHint =>
      'Покажите этот код на кассе и получите 2% кэшбэка';

  @override
  String get qrCashbackPrefix => 'Покажите QR-код кассиру, чтобы получить ';

  @override
  String get qrCashbackHighlight => '2% кэшбэк';

  @override
  String get personalInfo => 'Личная информация';

  @override
  String get account => 'Аккаунт';

  @override
  String get savedItems => 'Сохраненные товары';

  @override
  String get accountSettings => 'Настройки аккаунта';

  @override
  String get language => 'Язык';

  @override
  String get changeLanguage => 'Изменить язык';

  @override
  String get paymentMethodsComingSoon => 'Способы оплаты скоро появятся';

  @override
  String get preferences => 'Предпочтения';

  @override
  String get darkMode => 'Темная тема';

  @override
  String get soundEffects => 'Звуковые эффекты';

  @override
  String get notifications => 'Уведомления';

  @override
  String get notificationsComingSoon => 'Уведомления скоро появятся';

  @override
  String get notificationsReadAll => 'Прочитать все';

  @override
  String get notificationsEmpty => 'Пока нет уведомлений';

  @override
  String get notificationsEmptySubtitle =>
      'Здесь будут обновления заказов, снижения цен и сообщения.';

  @override
  String get notificationsLoadError => 'Не удалось загрузить уведомления';

  @override
  String get stylePreferences => 'Предпочтения стиля';

  @override
  String get stylePreferencesComingSoon =>
      'Стилевые предпочтения скоро появятся';

  @override
  String get support => 'Поддержка';

  @override
  String get helpCenter => 'Центр помощи';

  @override
  String get helpCenterComingSoon => 'Центр помощи скоро появится';

  @override
  String get aboutUs => 'О нас';

  @override
  String get termsAndConditions => 'Условия и положения';

  @override
  String get termsOfServiceComingSoon => 'Условия обслуживания скоро появятся';

  @override
  String get privacyPolicyComingSoon =>
      'Политика конфиденциальности скоро появится';

  @override
  String get helpAndSupport => 'Помощь и поддержка';

  @override
  String get logout => 'Выйти';

  @override
  String get logoutConfirmation => 'Вы уверены, что хотите выйти?';

  @override
  String get logoutMessage => 'Вы уверены, что хотите выйти?';

  @override
  String get deleteAccount => 'Удалить аккаунт';

  @override
  String get deleteAccountConfirmation =>
      'Вы уверены, что хотите навсегда удалить аккаунт? Все ваши данные будут удалены, и это действие невозможно отменить.';

  @override
  String get deleteAccountSuccess => 'Ваш аккаунт был удалён.';

  @override
  String get deleteAccountError =>
      'Не удалось удалить аккаунт. Попробуйте ещё раз.';

  @override
  String get browseAsGuest => 'Войти как гость';

  @override
  String get guest => 'Гость';

  @override
  String get guestPromptTitle => 'Войдите, чтобы продолжить';

  @override
  String get guestPromptMessage =>
      'Создайте бесплатный аккаунт, чтобы сохранять избранное, добавлять товары в корзину и отслеживать заказы.';

  @override
  String get guestPromptSignIn => 'Войти';

  @override
  String get guestPromptContinueBrowsing => 'Продолжить просмотр';

  @override
  String version(String version) {
    return 'Версия $version';
  }

  @override
  String get languageEnglish => 'English';

  @override
  String get languageRussian => 'Русский';

  @override
  String get languageUzbek => 'O\'zbekcha';

  @override
  String get tashkent => 'Ташкент';

  @override
  String get samarkand => 'Самарканд';

  @override
  String get bukhara => 'Бухара';

  @override
  String get andijan => 'Андижан';

  @override
  String get namangan => 'Наманган';

  @override
  String get fergana => 'Фергана';

  @override
  String get nukus => 'Нукус';

  @override
  String get karshi => 'Карши';

  @override
  String get termez => 'Термез';

  @override
  String get urgench => 'Ургенч';

  @override
  String get kokand => 'Коканд';

  @override
  String get jizzakh => 'Джизак';

  @override
  String get standardDelivery => 'Стандартная доставка';

  @override
  String get standardDeliveryDesc => '5-7 рабочих дней';

  @override
  String get expressDelivery => 'Экспресс доставка';

  @override
  String get expressDeliveryDesc => '2-3 рабочих дня';

  @override
  String get sameDayDelivery => 'Доставка в тот же день';

  @override
  String get sameDayDeliveryDesc => 'Заказ до 12:00';

  @override
  String get free => 'Бесплатно';

  @override
  String get bra => 'Бюстгальтер';

  @override
  String get band => 'Обхват';

  @override
  String get cup => 'Чашка';

  @override
  String get swipeRightDescription =>
      'Видите что-то, что вам нравится? Свайпните вправо, чтобы сохранить это в понравившихся товарах.';

  @override
  String get swipeLeftDescription =>
      'Не ваш стиль? Свайпните влево, чтобы увидеть следующий товар.';

  @override
  String get swipeUpToCart => 'Свайп вверх для добавления в корзину';

  @override
  String get swipeUpDescription =>
      'Готовы купить? Свайпните вверх, чтобы мгновенно добавить товар в корзину.';

  @override
  String get skipTutorial => 'Пропустить обучение';

  @override
  String get pants => 'Брюки';

  @override
  String get jackets => 'Куртки';

  @override
  String get colorBlack => 'Черный';

  @override
  String get colorWhite => 'Белый';

  @override
  String get colorGray => 'Серый';

  @override
  String get colorNavy => 'Темно-синий';

  @override
  String get colorBlue => 'Синий';

  @override
  String get colorLightBlue => 'Светло-синий';

  @override
  String get colorDarkBlue => 'Темно-синий';

  @override
  String get colorRed => 'Красный';

  @override
  String get colorPink => 'Розовый';

  @override
  String get colorGreen => 'Зеленый';

  @override
  String get colorBrown => 'Коричневый';

  @override
  String get colorBeige => 'Бежевый';

  @override
  String get colorPurple => 'Фиолетовый';

  @override
  String get colorYellow => 'Желтый';

  @override
  String get colorOrange => 'Оранжевый';

  @override
  String get colorCream => 'Кремовый';

  @override
  String get materialCotton => 'Хлопок';

  @override
  String get materialPolyester => 'Полиэстер';

  @override
  String get materialSilk => 'Шелк';

  @override
  String get materialLinen => 'Лен';

  @override
  String get materialWool => 'Шерсть';

  @override
  String get materialChiffon => 'Шифон';

  @override
  String get materialSatin => 'Атлас';

  @override
  String get materialVelvet => 'Бархат';

  @override
  String get materialDenim => 'Джинса';

  @override
  String get materialLeather => 'Кожа';

  @override
  String get materialSuede => 'Замша';

  @override
  String get materialJersey => 'Джерси';

  @override
  String get materialModal => 'Модал';

  @override
  String get materialRayon => 'Вискоза';

  @override
  String get materialSpandex => 'Спандекс';

  @override
  String get materialLycra => 'Лайкра';

  @override
  String get materialNylon => 'Нейлон';

  @override
  String get materialViscose => 'Вискоза';

  @override
  String get materialBamboo => 'Бамбук';

  @override
  String get materialCashmere => 'Кашемир';

  @override
  String get materialMixed => 'Смешанный';

  @override
  String get seasonSpring => 'Весна';

  @override
  String get seasonSummer => 'Лето';

  @override
  String get seasonFall => 'Осень';

  @override
  String get seasonWinter => 'Зима';

  @override
  String get seasonAllSeason => 'Всесезонный';

  @override
  String get fitLoose => 'Свободный';

  @override
  String get fitRegular => 'Обычный';

  @override
  String get fitSlim => 'Облегающий';

  @override
  String get fitOversized => 'Оверсайз';

  @override
  String get fitSuperSlim => 'Супер облегающий';

  @override
  String get styleCasual => 'Повседневный';

  @override
  String get styleFormal => 'Формальный';

  @override
  String get styleSporty => 'Спортивный';

  @override
  String get styleElegant => 'Элегантный';

  @override
  String get styleModest => 'Скромный';

  @override
  String get occasionDaily => 'Повседневный';

  @override
  String get occasionWork => 'Работа';

  @override
  String get occasionWedding => 'Свадьба';

  @override
  String get occasionParty => 'Вечеринки';

  @override
  String get occasionCasual => 'Повседневно';

  @override
  String get occasionFormal => 'Формальные мероприятия';

  @override
  String get occasionPrayer => 'Молитва';

  @override
  String get preferNotToSay => 'Предпочитаю не говорить';

  @override
  String get notApplicable => 'Не применимо';

  @override
  String get categoryDress => 'Платье';

  @override
  String get categoryHijab => 'Хиджаб';

  @override
  String get categoryAbaya => 'Абая';

  @override
  String get categoryTunic => 'Туника';

  @override
  String get categoryTop => 'Топ';

  @override
  String get categoryBlouse => 'Блузка';

  @override
  String get categoryShirt => 'Рубашка';

  @override
  String get categoryPants => 'Брюки';

  @override
  String get categoryJeans => 'Джинсы';

  @override
  String get categorySkirt => 'Юбка';

  @override
  String get categoryJacket => 'Куртка';

  @override
  String get categoryCoat => 'Пальто';

  @override
  String get categoryCardigan => 'Кардиган';

  @override
  String get categorySweater => 'Свитер';

  @override
  String get categoryActivewear => 'Спортивная одежда';

  @override
  String get categoryJumpsuit => 'Комбинезон';

  @override
  String get categoryScarf => 'Шарф';

  @override
  String get categoryShawl => 'Платок';

  @override
  String get categoryBags => 'Сумки';

  @override
  String get categoryUnderwear => 'Нижнее бельё';

  @override
  String get categoryOuterwear => 'Верхняя одежда';

  @override
  String get categoryTopwear => 'Верх';

  @override
  String get categoryBottomwear => 'Низ';

  @override
  String get categoryOnePiece => 'Платья и цельные изделия';

  @override
  String get categoryIslamicModestWear => 'Исламская одежда';

  @override
  String get categoryFootwear => 'Обувь';

  @override
  String get categoryTwoPieceSet => 'Двойка';

  @override
  String get categoryThreePieceSet => 'Тройка';

  @override
  String get categoryBodysuitsTriko => 'Цельные изделия (Трико)';

  @override
  String get categoryHomewear => 'Домашняя одежда';

  @override
  String get modestyLevel => 'Уровень скромности';

  @override
  String get modestyLevelDescription => 'Как вы предпочитаете покрытие одежды?';

  @override
  String get revealing => 'Открытый';

  @override
  String get selectModestyError =>
      'Пожалуйста, выберите хотя бы один уровень скромности';

  @override
  String get saveModestyError => 'Не удалось сохранить уровень скромности';

  @override
  String get selectOneOrBothPreferences => 'Выберите одно или оба предпочтения';

  @override
  String get selectMultipleOptions => 'Вы можете выбрать несколько вариантов';

  @override
  String get whichColorsAvoid => 'Какие цвета вы хотите избегать?';

  @override
  String get selectColorsAvoid =>
      'Выберите цвета, которые вы предпочитаете не носить';

  @override
  String get colorReds => 'Красные';

  @override
  String get colorPinks => 'Розовые';

  @override
  String get colorOranges => 'Оранжевые';

  @override
  String get colorYellows => 'Жёлтые';

  @override
  String get colorGreens => 'Зелёные';

  @override
  String get colorBlues => 'Синие';

  @override
  String get colorPurples => 'Фиолетовые';

  @override
  String get colorBrowns => 'Коричневые';

  @override
  String get colorBeiges => 'Бежевые';

  @override
  String get colorGrays => 'Серые';

  @override
  String get colorWhites => 'Белые';

  @override
  String get colorBlacks => 'Чёрные';

  @override
  String get styleCategories => 'Категории стиля';

  @override
  String get styleCategoriesDescription =>
      'Выберите стили, которые соответствуют вашей личности';

  @override
  String get casual => 'Повседневный';

  @override
  String get formal => 'Формальный';

  @override
  String get business => 'Деловой';

  @override
  String get elegant => 'Элегантный';

  @override
  String get vintage => 'Винтажный';

  @override
  String get modern => 'Современный';

  @override
  String get classic => 'Классический';

  @override
  String get modest => 'Скромный';

  @override
  String get romantic => 'Романтичный';

  @override
  String get occasions => 'Мероприятия';

  @override
  String get occasionsDescription =>
      'Выберите случаи, для которых вы обычно одеваетесь';

  @override
  String get occasionStudy => 'Учёба';

  @override
  String get occasionReligious => 'Религиозные мероприятия';

  @override
  String get occasionSports => 'Спорт';

  @override
  String get occasionTravel => 'Путешествия';

  @override
  String get occasionOutdoor => 'Активный отдых';

  @override
  String get occasionSpecial => 'Особые случаи';

  @override
  String get brandPreferences => 'Предпочтения брендов';

  @override
  String get brandPreferencesDescription =>
      'Выберите ваши любимые бренды (необязательно)';

  @override
  String get optionalSelection => 'Вы можете пропустить этот шаг';

  @override
  String get selectAtLeastOne => 'Пожалуйста, выберите хотя бы один вариант';

  @override
  String get genericError => 'Произошла ошибка. Попробуйте еще раз.';

  @override
  String get profileInformation => 'Информация профиля';

  @override
  String get personal => 'Личные данные';

  @override
  String get hijabPreference => 'Предпочтение хиджаба';

  @override
  String get age => 'Возраст';

  @override
  String get years => 'лет';

  @override
  String get bodyInformation => 'Информация о теле';

  @override
  String get clothingSizes => 'Размеры одежды';

  @override
  String get topSize => 'Размер верха';

  @override
  String get bottomSize => 'Размер низа';

  @override
  String get dressSize => 'Размер платья';

  @override
  String get jeanWaistSize => 'Размер талии джинсов';

  @override
  String get braSizes => 'Размеры бюстгальтера';

  @override
  String get braBandSize => 'Размер пояса';

  @override
  String get braCupSize => 'Размер чашки';

  @override
  String get stylePreferenceLabel => 'Предпочтение стиля';

  @override
  String get budgetType => 'Тип бюджета';

  @override
  String get shoppingPreferences => 'Предпочтения покупок';

  @override
  String get budget => 'Бюджет';

  @override
  String get completed => 'Завершен';

  @override
  String get notCompleted => 'Не завершен';

  @override
  String get from => 'От';

  @override
  String get upTo => 'До';

  @override
  String get notSet => 'Не установлено';

  @override
  String get enumFemale => 'Женский';

  @override
  String get enumMale => 'Мужской';

  @override
  String get enumHourglass => 'Песочные часы';

  @override
  String get enumTriangle => 'Треугольник';

  @override
  String get enumRectangle => 'Прямоугольник';

  @override
  String get enumOval => 'Овал';

  @override
  String get enumHeart => 'Сердце';

  @override
  String get enumPreferNotToSay => 'Предпочитаю не говорить';

  @override
  String get enumCovered => 'Закрытый';

  @override
  String get enumUncovered => 'Открытый';

  @override
  String get enumNotApplicable => 'Не применимо';

  @override
  String get enumLoose => 'Свободный';

  @override
  String get enumRegular => 'Обычный';

  @override
  String get enumOversized => 'Оверсайз';

  @override
  String get enumSlim => 'Облегающий';

  @override
  String get enumSuperSlim => 'Супер облегающий';

  @override
  String get enumFitted => 'По фигуре';

  @override
  String get enumModerate => 'Умеренный';

  @override
  String get enumRevealing => 'Открытый';

  @override
  String get enumBudget => 'Бюджетный';

  @override
  String get enumPremium => 'Премиум';

  @override
  String get enumLuxury => 'Люкс';

  @override
  String get enumFlexible => 'Гибкий';

  @override
  String get enumCasual => 'Повседневный';

  @override
  String get enumFormal => 'Официальный';

  @override
  String get enumBusiness => 'Деловой';

  @override
  String get enumSporty => 'Спортивный';

  @override
  String get enumElegant => 'Элегантный';

  @override
  String get enumBohemian => 'Богемный';

  @override
  String get enumVintage => 'Винтажный';

  @override
  String get enumModern => 'Современный';

  @override
  String get enumMinimalist => 'Минималистичный';

  @override
  String get enumClassic => 'Классический';

  @override
  String get enumTrendy => 'Трендовый';

  @override
  String get enumModest => 'Скромный';

  @override
  String get enumStreetwear => 'Уличный';

  @override
  String get enumRomantic => 'Романтичный';

  @override
  String get enumEdgy => 'Дерзкий';

  @override
  String get enumPreppy => 'Преппи';

  @override
  String get enumAthleisure => 'Спорт-шик';

  @override
  String get enumChic => 'Шикарный';

  @override
  String get enumGlamorous => 'Гламурный';

  @override
  String get enumSexy => 'Сексуальный';

  @override
  String get enumRetro => 'Ретро';

  @override
  String get enumGrunge => 'Гранж';

  @override
  String get enumGothic => 'Готический';

  @override
  String get enumHippie => 'Хиппи';

  @override
  String get enumArtsy => 'Артистичный';

  @override
  String get enumFeminine => 'Женственный';

  @override
  String get enumMasculine => 'Мужественный';

  @override
  String get enumAndrogynous => 'Андрогинный';

  @override
  String get enumLuxurious => 'Роскошный';

  @override
  String get partnerPortal => 'Партнёрский портал';

  @override
  String get partnerWelcomeBack => 'С возвращением';

  @override
  String get partnerSignInSubtitle =>
      'Войдите, чтобы управлять магазином, отвечать клиентам и начислять кэшбэк.';

  @override
  String get partnerUsernameLabel => 'Имя пользователя или Email';

  @override
  String get partnerUsernameHint => 'Введите имя пользователя или email';

  @override
  String get partnerPasswordLabel => 'Пароль';

  @override
  String get partnerPasswordHint => 'Введите пароль';

  @override
  String get partnerForgotPassword => 'Забыли пароль?';

  @override
  String get partnerSignIn => 'Войти';

  @override
  String get partnerNeedAccess => 'Нужен доступ? Свяжитесь с вашим менеджером.';

  @override
  String get partnerLoginFailed => 'Ошибка входа. Проверьте данные.';

  @override
  String get partnerCashbackTitle => 'Кэшбэк';

  @override
  String get partnerCashbackSubtitle =>
      'Отсканируйте QR-код покупателя, чтобы зарегистрировать продажу и начислить кэшбэк.';

  @override
  String get partnerScanQr => 'Сканировать QR';

  @override
  String get myProducts => 'Мои товары';

  @override
  String get partnerTapToOpenCamera => 'Нажмите, чтобы открыть камеру';

  @override
  String get partnerIdentifyCustomer => 'Определить покупателя';

  @override
  String get partnerSelectProduct => 'Выбрать товар';

  @override
  String get partnerApplyDiscount => 'Применить скидку';

  @override
  String get partnerConfirmCashback => 'Подтвердить кэшбэк';

  @override
  String get partnerRecordCashback => 'Записать кэшбэк';

  @override
  String get partnerProductLabel => 'Товар';

  @override
  String get partnerProductHint => 'Введите название товара или код (SKU)';

  @override
  String get partnerSizeLabel => 'Размер';

  @override
  String get partnerColorLabel => 'Цвет';

  @override
  String get partnerPricingLabel => 'Цена';

  @override
  String get partnerOriginalPriceHint => 'Исходная цена (UZS)';

  @override
  String get partnerDiscountPercent => 'Скидка %';

  @override
  String get partnerDiscountAmount => 'Сумма скидки';

  @override
  String get partnerFinalPriceLabel => 'Итоговая цена: ';

  @override
  String get partnerNotesLabel => 'Примечания (необязательно)';

  @override
  String get partnerNotesHint => 'Дополнительные примечания...';

  @override
  String get partnerCustomerPrefix => 'Покупатель: ';

  @override
  String get partnerPointCamera => 'Наведите камеру на QR-код покупателя';

  @override
  String get partnerCashbackSuccess => 'Кэшбэк записан!';

  @override
  String get partnerEnterProduct => 'Пожалуйста, введите название товара.';

  @override
  String get partnerEnterPrice => 'Пожалуйста, введите исходную цену.';

  @override
  String get partnerCashbackFailed => 'Не удалось записать кэшбэк.';

  @override
  String get partnerVerifyingUser => 'Проверка пользователя...';

  @override
  String get partnerUserNotFound => 'Пользователь не найден. Проверьте QR-код.';

  @override
  String get partnerUserVerified => 'Пользователь успешно подтвержден';

  @override
  String get partnerSelectProducts => 'Выберите товары';

  @override
  String get partnerSearchProducts => 'Поиск товаров...';

  @override
  String get partnerNoProducts => 'Товары не найдены';

  @override
  String get partnerAddProduct => 'Добавить товар';

  @override
  String get partnerProductsSelected => 'товаров выбрано';

  @override
  String get partnerContinue => 'Продолжить';

  @override
  String get partnerRemoveProduct => 'Удалить';

  @override
  String get partnerTotal => 'Итого';

  @override
  String get partnerEnterDiscount => 'Введите скидку для';

  @override
  String get partnerApplyingCashback => 'Применение кэшбэка...';

  @override
  String get partnerSelectAtLeastOne =>
      'Пожалуйста, выберите хотя бы один товар.';

  @override
  String get partnerLoadingProducts => 'Загрузка товаров...';

  @override
  String get points => 'балл';

  @override
  String get shopErrorTitle => 'Ой, что-то пошло не так';

  @override
  String get shopErrorSubtitle =>
      'Не удалось загрузить товары. Проверьте подключение и попробуйте снова.';

  @override
  String get shopRetry => 'Повторить';

  @override
  String get shopLoadingProducts => 'Загрузка товаров...';

  @override
  String get errorGenericTitle => 'Ой, что-то пошло не так';

  @override
  String get errorGenericSubtitle =>
      'Проверьте подключение и попробуйте снова.';

  @override
  String get errorRetry => 'Повторить';

  @override
  String get vsScanningImage => 'Сканирование фото';

  @override
  String get vsIdentifyingStyle => 'Определение стиля';

  @override
  String get vsFindingMatches => 'Поиск совпадений';

  @override
  String get vsAlmostThere => 'Почти готово';

  @override
  String get vsPoweredByAI => 'На основе ИИ';

  @override
  String get vsTutorialDesc =>
      'Нажмите значок камеры в магазине, чтобы найти похожие товары по фото.';

  @override
  String get tutorialWhiteBlouse => 'Белая блузка';

  @override
  String get tutorialLongDress => 'Длинное платье';

  @override
  String get tutorialBeigeShoes => 'Бежевые туфли';

  @override
  String get profileUpdatedSuccess => 'Профиль успешно обновлён';

  @override
  String get mapOpenMap => 'Открыть карту';

  @override
  String get mapOpenInMaps => 'Открыть в картах';

  @override
  String get loadingSellerProducts => 'Загрузка товаров продавца...';

  @override
  String get shops => 'Магазины';

  @override
  String get allShops => 'Все магазины';

  @override
  String get forceUpdateTitle => 'Требуется обновление';

  @override
  String get forceUpdateSubtitle =>
      'Доступна новая версия Libas AI с улучшениями и новыми функциями. Пожалуйста, обновите приложение.';

  @override
  String get forceUpdateButton => 'Обновить';

  @override
  String forceUpdateVersionLabel(String version) {
    return 'Версия $version доступна';
  }

  @override
  String get pressBackAgainToExit => 'Нажмите ещё раз для выхода';

  @override
  String get refresh => 'Обновить';

  @override
  String get tapRefreshToSeeMore =>
      'Нажмите обновить, чтобы увидеть новые товары';

  @override
  String get addToCloset => 'Добавить в гардероб';

  @override
  String get saveToCloset => 'Сохранить';

  @override
  String get closetEmpty => 'Ваш гардероб пуст';

  @override
  String get closetEmptySubtitle =>
      'Добавьте первый предмет, чтобы начать собирать гардероб';

  @override
  String get itemDeleted => 'Предмет удалён';

  @override
  String get selectCategory => 'Категория';

  @override
  String get brandOptional => 'Бренд (необязательно)';

  @override
  String get notesOptional => 'Заметки (необязательно)';

  @override
  String get newItem => 'Новый предмет';

  @override
  String get deleteItemConfirm => 'Убрать этот предмет из гардероба?';

  @override
  String get categoryTshirts => 'Футболки';

  @override
  String get categoryJackets => 'Куртки';

  @override
  String get categoryBlouses => 'Блузки';

  @override
  String get categoryJumpsuits => 'Комбинезоны';

  @override
  String get categorySkirts => 'Юбки';

  @override
  String get categoryShorts => 'Шорты';

  @override
  String get sectionMyOutfits => 'Мои образы';

  @override
  String get sectionUpperBody => 'Верхняя часть';

  @override
  String get sectionLowerBody => 'Нижняя часть';

  @override
  String get outfitsNeedMoreItems =>
      'Добавьте минимум 5 вещей, чтобы создать образы';

  @override
  String get verifyMethodTitle => 'Подтвердите личность';

  @override
  String get verifyMethodSubtitle => 'Выберите способ подтверждения';

  @override
  String get continueWithGoogle => 'Продолжить через Google';

  @override
  String get continueWithApple => 'Продолжить через Apple';

  @override
  String get signInTroubleTelegram =>
      'Проблемы со входом? Напишите нам в Telegram';

  @override
  String get verifyWithSms => 'Подтвердить через SMS';

  @override
  String get signInTitle => 'Войти';

  @override
  String get createAccountTitle => 'Создать аккаунт';

  @override
  String get linkAccountTitle => 'Привяжите аккаунт';

  @override
  String get selectCountry => 'Выберите страну';

  @override
  String get searchCountry => 'Поиск страны или кода';

  @override
  String get noResultsFound => 'Ничего не найдено';
}
