# BuyWater

A Flutter e-commerce mobile application for water delivery services in Jamaica.

![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)
![License](https://img.shields.io/badge/License-MIT-green.svg?style=for-the-badge)

## Features

- **User Authentication** - Sign in, register, and password recovery
- **Product Catalog** - Browse water products across 6 categories
- **Shopping Cart** - Add products, adjust quantities, view totals
- **Order Management** - Track orders, view order history
- **User Profile** - Manage addresses and account settings
- **Demo Mode** - Try the app without creating an account

## Product Categories

1. **Bottled Water** - Spring water, alkaline water, sparkling water
2. **Gallon Jugs** - 3-gallon and 5-gallon refillable containers
3. **Dispensers** - Hot & cold dispensers, countertop models, manual pumps
4. **Filters** - Home filtration systems and replacement cartridges
5. **Accessories** - Bottle carriers, insulated bottles
6. **Ice** - Party ice bags and crushed ice

## Screenshots

| Welcome Screen | Home Screen | Product Detail |
|:--------------:|:-----------:|:--------------:|
| Welcome page with login options | Product catalog with categories | Product information and reviews |

## Getting Started

### Prerequisites

- Flutter SDK (3.9.2 or higher)
- Dart SDK
- Android Studio / VS Code
- Android SDK for Android builds
- Xcode for iOS builds (macOS only)

### Installation

1. Clone the repository:
```bash
git clone https://github.com/kopi111/buywater-app.git
cd buywater-app
```

2. Install dependencies:
```bash
flutter pub get
```

3. Run the app:
```bash
# For web
flutter run -d chrome

# For Android
flutter run -d android

# For iOS (macOS only)
flutter run -d ios
```

### Building APK

```bash
flutter build apk --release
```

The APK will be available at `build/app/outputs/flutter-apk/app-release.apk`

## Project Structure

```
lib/
├── config/
│   ├── app_config.dart      # App configuration
│   └── theme.dart           # Theme and styling
├── models/
│   ├── address.dart         # Address model
│   ├── cart.dart            # Cart and cart item models
│   ├── order.dart           # Order model
│   ├── product.dart         # Product and category models
│   └── user.dart            # User model
├── providers/
│   ├── auth_provider.dart   # Authentication state
│   ├── cart_provider.dart   # Shopping cart state
│   ├── order_provider.dart  # Order management state
│   └── product_provider.dart # Product catalog state
├── screens/
│   ├── auth/                # Login, register, forgot password
│   ├── cart/                # Shopping cart screen
│   ├── checkout/            # Checkout flow screens
│   ├── home/                # Home screen
│   ├── orders/              # Order list and details
│   ├── product/             # Product list and details
│   └── profile/             # User profile
├── services/
│   ├── api_service.dart     # HTTP client
│   ├── auth_service.dart    # Authentication service
│   ├── demo_data_service.dart # Demo mode data
│   ├── order_service.dart   # Order service
│   ├── payment_service.dart # Payment processing
│   └── product_service.dart # Product service
├── utils/
│   └── helpers.dart         # Utility functions
├── widgets/
│   └── product_card.dart    # Reusable product card widget
└── main.dart                # App entry point
```

## Technologies Used

- **Flutter** - Cross-platform UI framework
- **Provider** - State management
- **Dio** - HTTP client
- **Shared Preferences** - Local storage
- **Cached Network Image** - Image caching

## Currency

All prices are displayed in **Jamaican Dollars (JMD)**.

## Demo Mode

Click "Try Demo Version" on the welcome screen to explore the app with sample data:
- 14 pre-loaded products
- Demo user account
- Sample addresses
- Order history

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License.

## Contact

- GitHub: [@kopi111](https://github.com/kopi111)

---

Made with Flutter
