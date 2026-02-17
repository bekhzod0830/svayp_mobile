# Swipe - AI-Powered Fashion Discovery App# swipe



A revolutionary fashion discovery mobile application that combines Tinder-like swipe mechanics with AI-powered personalization.A new Flutter project.



## 🚀 Project Status## Getting Started



**Phase:** Initial Development  This project is a starting point for a Flutter application.

**Version:** 1.0.0+1  

**Last Updated:** October 24, 2025A few resources to get you started if this is your first Flutter project:



## ✅ Completed- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)

- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

### Project Setup

- ✅ Flutter project initialized with clean architectureFor help getting started with Flutter development, view the

- ✅ Folder structure organized (presentation/domain/data layers)[online documentation](https://docs.flutter.dev/), which offers tutorials,

- ✅ Dependencies installed (BLoC, Dio, Hive, Firebase, etc.)samples, guidance on mobile development, and a full API reference.

- ✅ Core configurations created
- ✅ Design system implemented (colors, typography, theme)
- ✅ Utilities and validators created
- ✅ App routing structure defined

### Design System
- ✅ Monochrome color palette (#000000 - #FFFFFF)
- ✅ Typography system (Display, Heading, Body, Caption styles)
- ✅ Theme configuration (Light theme with Material 3)
- ✅ Component styling (Buttons, Cards, Inputs, etc.)

## 🎨 Design Philosophy

**Sophisticated | Minimalist | Modern | Confident | Timeless**

- Monochrome black & white color scheme
- Let product images provide color
- Bold typography and strong visual hierarchy
- Clean, uncluttered interfaces

## 🏗️ Architecture

**Clean Architecture** with **BLoC Pattern**

```
features/
└── feature_name/
    ├── presentation/     # UI, Widgets, BLoC
    ├── domain/           # Business Logic
    └── data/             # Data Sources
```

## 📱 Key Features (Planned)

- [ ] Phone authentication (SMS OTP)
- [ ] AI-powered style quiz (20 swipe questions)
- [ ] Infinite swipe feed with personalization
- [ ] Real-time AI learning from swipes
- [ ] Shopping cart & checkout
- [ ] Order tracking
- [ ] User profile management

## 🚀 Getting Started

### Prerequisites
- Flutter SDK 3.9.2+
- Dart 3.9.2+
- Android Studio / Xcode

### Installation

```bash
# Navigate to project
cd /Users/bekhzod_tokhirjonov/Desktop/Swipe/swipe

# Install dependencies
flutter pub get

# Run the app
flutter run

# Analyze code
flutter analyze
```

## 📂 Project Structure

```
lib/
├── app/                  # App configuration & theme
├── core/                 # Core utilities & constants
├── features/             # Feature modules (onboarding, discover, etc.)
├── shared/               # Shared widgets
└── main.dart            # Entry point
```

## 🔧 Key Dependencies

- `flutter_bloc` - State management
- `dio` - HTTP client
- `hive` - Local storage
- `firebase_auth` - Authentication
- `cached_network_image` - Image caching
- `lottie` - Animations
- `card_swiper` - Swipe mechanics

## 🎯 Next Steps

1. Build reusable UI components
2. Implement splash & welcome screens
3. Create onboarding flow with Firebase auth
4. Develop swipeable card stack widget
5. Build main discover feed
6. Integrate backend API

## 📖 Documentation

- [Product Requirements](../.github/Readme.md)
- [Design System](../.github/design_system.md)
- [AI/ML Specifications](../.github/ai_ml_tech_specs.md)
- [Screen Specs](../.github/screens.md)

---

**Built with ❤️ using Flutter**
