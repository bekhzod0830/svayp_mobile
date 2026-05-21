# Swipe — AI-Powered Fashion Discovery App

Flutter mobile app (iOS + Android) for Tinder-style fashion discovery with AI personalization.

## Build & Run

```bash
flutter pub get                                      # Install dependencies
flutter pub run build_runner build                   # Generate Hive adapters (after model changes)
flutter run                                          # Run development build
flutter run --dart-define=CHARLES_PROXY=<IP>:8888   # Run with Charles proxy for network debugging
flutter build apk --release                          # Build release APK
flutter test                                         # Run tests
```

> **SDK**: Flutter 3.9.2+ / Dart 3.9.2+  
> **App version**: 2.0.1+21, package `uz.swipe.app`

## Architecture

**Modified Clean Architecture** with **ChangeNotifier + Provider** state management.

> ⚠️ `flutter_bloc` is a listed dependency but is **not used** — do not generate BLoC/Cubit code.  
> ⚠️ `injectable` is in dev_dependencies but is **not used** — do not add `@injectable` annotations.

```
lib/
├── app/           # SwipeApp widget, AppRoutes, AppTheme
├── core/          # Cross-feature: DI, networking, constants, services, l10n, analytics
├── features/      # Feature modules (see below)
└── shared/        # Reusable widgets (ProductCard, CustomTextField, LoadingIndicator, etc.)
```

### Feature module structure

```
features/<name>/
├── data/
│   ├── datasources/
│   ├── models/         # Dart models (Hive-backed where persisted locally)
│   └── <name>_service.dart
├── domain/             # Mostly absent — skip unless adding business rules
└── presentation/
    ├── screens/
    └── widgets/
```

## Key Conventions

**Imports**: Always use absolute `package:swipe/...` imports — never relative imports.

**Naming**:
- Screens: `{feature}_screen.dart` → class `{Feature}Screen`
- Services: `{feature}_service.dart` → class `{Feature}Service`
- Models: `{feature}_model.dart` → class `{Feature}Model`
- Generated files: `*.g.dart` (Hive adapters — do not edit manually)

**State management per screen**:
- Local UI state → `StatefulWidget` + `setState()`
- Shared onboarding state → `OnboardingDataManager` (ChangeNotifier, provided via `MultiProvider` in `app.dart`)
- No BLoC; services are injected via `get_it` and called from `setState()` blocks

**Monochrome design**: Colors are defined in `lib/core/constants/app_colors.dart` (black/white/grey only). Product images provide all color. Always use `AppColors` and `AppTypography` constants.

## Navigation

Custom router — no go_router or auto_route.

- Route constants and `onGenerateRoute()` are in [lib/app/routes.dart](lib/app/routes.dart)
- Use `Navigator.pushNamed(context, AppRoutes.routeName)` for navigation
- Pass arguments as typed objects: `Navigator.pushNamed(context, AppRoutes.otpVerification, arguments: phoneNumber)`
- Stack clearing on completion: use `pushNamedAndRemoveUntil`

Route flow: `splash → welcome → phoneAuth → otpVerification → [onboarding flow] → main`

> Onboarding completion is tracked via `SharedPreferences` — see [docs/ONBOARDING_STATE.md](docs/ONBOARDING_STATE.md)

## Dependency Injection

**get_it** only — manual registration in [lib/core/di/service_locator.dart](lib/core/di/service_locator.dart).

```dart
// Access a registered service
final authService = getIt<AuthService>();
```

Register new services in `initializeDependencies()` using `registerLazySingleton<T>()`.

## Networking

**Dio** via `ApiClient` wrapper ([lib/core/network/api_client.dart](lib/core/network/api_client.dart)):
- Base URL: `https://app.svaypai.com/api/v1`
- Auto token refresh on 401 with request queuing
- Proactive refresh if token expires within 60s
- Debug logging via `PrettyDioLogger` (dev only)

```dart
// All API calls go through ApiClient
final apiClient = getIt<ApiClient>();
final response = await apiClient.post(ApiConfig.someEndpoint, data: {...});
```

## Local Storage

| Store | Used For |
|-------|----------|
| Hive | Cart items, liked products, camera roll, language preference |
| SharedPreferences | Auth tokens, onboarding state |

After adding a new Hive model with `@HiveType`/`@HiveField`, run `flutter pub run build_runner build` to regenerate the adapter, then register it in `main.dart`.

## Localization

3 languages: **English, Russian, Uzbek**. Default language: **Russian**.

- ARB source files: `lib/l10n/app_en.arb` (template), `app_ru.arb`, `app_uz.arb`
- Generated: `lib/l10n/app_localizations.dart` (do not edit)
- Access strings: `AppLocalizations.of(context)!.yourKey`
- Add new strings to **all three** ARB files; run `flutter pub get` to regenerate

## Firebase

| Service | Package | Purpose |
|---------|---------|---------|
| Firebase Core | firebase_core | Initialization |
| Firebase Auth | firebase_auth | Phone OTP authentication |
| Firebase Messaging | firebase_messaging | Push notifications (FCM) |
| Firebase Analytics | firebase_analytics | Event tracking via `AnalyticsService` |
| Smartlook | flutter_smartlook | Session recording (disabled by default) |

## Testing

Test coverage is minimal. Run existing tests with `flutter test`.

- Widget tests: [test/widget_test.dart](test/widget_test.dart)
- API tests: [test/auth_api_test.dart](test/auth_api_test.dart)
- `mockito` and `bloc_test` are available but largely unused

## Common Pitfalls

- **Do not use BLoC** — use ChangeNotifier + Provider or StatefulWidget instead
- **Do not use `@injectable`** — register services manually in `service_locator.dart`
- **Do not use relative imports** — always `package:swipe/...`
- **Hive model changes require code gen** — run `build_runner build` after modifying `@HiveType` classes
- **Default locale is Russian** — test UI strings with Russian locale, not English
- **Several onboarding screens are disabled** (commented out in `routes.dart`) — check before adding new screens to the flow
