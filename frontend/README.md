# ARIA Frontend - Flutter Application

Modern, minimalistic Flutter application for AI-powered requirements prioritization.

## 🎨 Design

Apple-inspired minimalistic UI with:
- Clean, modern interface
- iOS-style colors and typography
- Smooth animations and transitions
- Responsive layout for web and mobile

## 🚀 Quick Start

### Prerequisites

- Flutter SDK 3.24.3 or higher
- Dart SDK 3.5.3 or higher

### Installation

```bash
# Navigate to frontend directory
cd frontend

# Install dependencies
flutter pub get

# Run on web
flutter run -d chrome

# Run on mobile/desktop
flutter run
```

### Code Generation

When you modify models with `@JsonSerializable`:

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

## 📁 Project Structure

```
frontend/
├── lib/
│   ├── api/              # API client
│   ├── bloc/             # State management (BLoC)
│   ├── models/           # Data models
│   ├── screens/          # UI screens
│   ├── theme/            # Design system
│   ├── utils/            # Utilities
│   └── main.dart         # Entry point
├── web/                  # Web assets
├── pubspec.yaml          # Dependencies
└── build.yaml            # Build configuration
```

## 🔌 API Configuration

Update the backend API URL in `lib/api/aria_api_client.dart`:

```dart
AriaApiClient(
  baseUrl: 'https://your-backend-url.com/v1',
)
```

Or in `lib/utils/constants.dart`:

```dart
static const String prodApiUrl = 'https://your-backend-url.com/v1';
```

## 📱 Features

### Requirements Input
- **File Upload**: CSV/Excel files (max 100 requirements)
- **Manual Entry**: Intuitive form interface with validation

### Prioritization
- AI-powered analysis with weighted scoring
- Real-time progress indicators
- Session-based processing

### Visualization
- **List View**: Sorted by priority rank
- **Chart View**: Interactive bar charts
- Detailed requirement information

### Export
- CSV format for spreadsheet analysis
- HTML reports for sharing

## 🏗️ Tech Stack

- **Framework**: Flutter 3.24.3
- **State Management**: BLoC Pattern
- **HTTP Client**: Dio
- **Charts**: FL Chart
- **File Handling**: file_picker, csv
- **Serialization**: json_serializable

## 🎨 Theme System

### Colors
```dart
Primary: #007AFF (iOS Blue)
Secondary: #5856D6 (iOS Purple)
Accent: #34C759 (iOS Green)
Background: #F2F2F7
```

### Typography
San Francisco-style fonts with negative letter spacing for modern look.

### Spacing
8px grid system: XS(4), S(8), M(16), L(24), XL(32), XXL(48)

## 🧪 Development

### Run in Debug Mode
```bash
flutter run --debug
```

### Build for Production

**Web:**
```bash
flutter build web
```

**iOS:**
```bash
flutter build ios
```

**Android:**
```bash
flutter build apk
```

**macOS:**
```bash
flutter build macos
```

## 📊 Dependencies

Key packages:
- `flutter_bloc ^8.1.6` - State management
- `dio ^5.4.3` - HTTP client
- `fl_chart ^0.68.0` - Charts
- `file_picker ^8.0.0` - File selection
- `json_annotation ^4.9.0` - JSON serialization
- `equatable ^2.0.5` - Value equality

See `pubspec.yaml` for complete list.

## 🐛 Troubleshooting

### "No backend connection"
- Ensure backend API is running
- Check API URL configuration
- Verify network connectivity

### Code generation errors
```bash
flutter pub run build_runner clean
flutter pub run build_runner build --delete-conflicting-outputs
```

### Dependency issues
```bash
flutter clean
flutter pub get
```

## 📚 Documentation

- [Main Project README](../README.md)
- [Quick Start Guide](../QUICKSTART.md)
- [Project Summary](../PROJECT_SUMMARY.md)
- [Backend Integration](../backend/README.md)

## 🎯 Next Steps

1. Configure backend API URL
2. Test connection with health check endpoint
3. Upload sample CSV or create requirements manually
4. View AI-powered prioritization results
5. Export and share results

---

**Built with ❤️ using Flutter**
