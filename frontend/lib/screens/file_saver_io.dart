// File saver for non-web platforms using dart:io
// This file is only imported for non-web platforms
import 'dart:io';
import 'package:path_provider/path_provider.dart';

Future<String> saveFileToDisk(String data, String filename) async {
  final directory = await getApplicationDocumentsDirectory();
  final file = File('${directory.path}/$filename');
  await file.writeAsString(data);
  return file.path;
}

