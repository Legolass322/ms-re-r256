// File saver stub for web platforms
// This file provides a stub implementation that will never be called
// because web uses the html.Blob approach in results_screen.dart

// Stub File class for web
class File {
  final String path;
  File(this.path);
  Future<void> writeAsString(String data) async {
    throw UnsupportedError('File.writeAsString is not supported on web');
  }
}

Future<String> saveFileToDisk(String data, String filename) {
  throw UnsupportedError('saveFileToDisk is not supported on web');
}

