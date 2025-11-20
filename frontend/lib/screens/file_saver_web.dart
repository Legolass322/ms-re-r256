// File saver for web platforms using dart:html
import 'dart:convert';
import 'dart:typed_data';
import 'dart:html' as html;

Future<String> saveTextFile(
  String data,
  String filename, {
  String mimeType = 'text/plain',
}) async {
  final bytes = Uint8List.fromList(utf8.encode(data));
  return saveBytesFile(bytes, filename, mimeType: mimeType);
}

Future<String> saveBytesFile(
  Uint8List bytes,
  String filename, {
  String mimeType = 'application/octet-stream',
}) async {
  final blob = html.Blob([bytes], mimeType);
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.AnchorElement(href: url)
    ..setAttribute('download', filename)
    ..click();
  html.Url.revokeObjectUrl(url);
  return filename;
}