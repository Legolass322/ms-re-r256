class AppConstants {
  // API Configuration
  static const String defaultApiUrl = 'http://localhost:8080/v1';
  static const String prodApiUrl = 'https://api.aria-app.com/v1';

  // Limits
  static const int maxRequirements = 100;
  static const int maxProcessingTimeMs = 5000;

  // File Upload
  static const List<String> supportedFileExtensions = ['csv', 'xlsx', 'xls'];
  static const int maxFileSizeMB = 10;

  // Scoring
  static const double minScore = 1.0;
  static const double maxScore = 10.0;

  // Default Weights
  static const Map<String, double> defaultWeights = {
    'businessValue': 0.3,
    'cost': 0.2,
    'risk': 0.15,
    'urgency': 0.2,
    'stakeholderValue': 0.15,
  };

  // App Info
  static const String appName = 'ARIA';
  static const String appVersion = '1.0.0';
  static const String appDescription =
      'Advanced Requirements Intelligence & Analytics';
}
