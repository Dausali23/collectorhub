# CollectorHub

A Flutter marketplace app for collectors featuring real-time eBay price integration, Firebase backend, and comprehensive trading features.

## Features

- 🔍 **Real-time Market Pricing** - Integrated with eBay API for current market values
- 🛒 **Marketplace** - Buy, sell, and trade collectibles
- 💬 **In-app Chat** - Communicate with other collectors
- 🔔 **Real-time Bidding** - Live auction functionality
- 📱 **Cross-platform** - iOS and Android support
- 🔐 **Secure Authentication** - Firebase Auth integration

## Getting Started

### Prerequisites

- Flutter SDK (latest stable version)
- Firebase project setup
- eBay Developer Account

### Setup Instructions

1. **Clone the repository:**
   ```bash
   git clone https://github.com/Dausali23/collectorhub.git
   cd collectorhub
   ```

2. **Install dependencies:**
   ```bash
   flutter pub get
   ```

3. **Configure eBay API:**
   - Copy `lib/config/secrets.dart.template` to `lib/config/secrets.dart`
   - Get your eBay API credentials from [eBay Developer Program](https://developer.ebay.com)
   - Update `secrets.dart` with your actual credentials:
   ```dart
   class Secrets {
     static const String ebayAppId = 'YOUR_EBAY_APP_ID';
     static const String ebayDevId = 'YOUR_EBAY_DEV_ID';  
     static const String ebayClientSecret = 'YOUR_EBAY_CLIENT_SECRET';
   }
   ```

4. **Configure Firebase:**
   - Add your `google-services.json` (Android) and `GoogleService-Info.plist` (iOS)
   - Update Firebase configuration in `firebase_options.dart`

5. **Run the app:**
   ```bash
   flutter run
   ```

## eBay API Integration

This app integrates with eBay's Browse API to provide real-time market pricing for collectibles. The integration includes:

- **Automatic price fetching** when creating listings
- **Category-specific searches** for accurate pricing
- **Caching system** to optimize API usage
- **Graceful fallbacks** if API is unavailable

### API Usage Monitoring

You can monitor your eBay API usage through:
- eBay Developer Portal → API Explorer
- Built-in rate limit checking in the app
- Response headers showing remaining calls

## Project Structure

```
lib/
├── config/
│   ├── api_config.dart        # eBay API configuration
│   ├── secrets.dart           # API credentials (not tracked)
│   └── secrets.dart.template  # Template for API setup
├── models/                    # Data models
├── screens/                   # UI screens
├── services/                  # API and business logic
│   ├── ebay_api_service.dart # eBay integration
│   ├── ebay_auth_service.dart # eBay OAuth handling
│   └── firestore_service.dart # Firebase integration
└── widgets/                   # Reusable UI components
```

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Resources

- [eBay Developer Program](https://developer.ebay.com)
- [Firebase Documentation](https://firebase.google.com/docs)
- [Flutter Documentation](https://docs.flutter.dev/)
