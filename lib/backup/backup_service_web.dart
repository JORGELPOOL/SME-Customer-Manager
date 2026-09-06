import 'dart:convert';
import 'dart:html' as html;

Future<String> downloadBackup(String jsonContent, String filename) async {
  final bytes = utf8.encode(jsonContent);
  final blob = html.Blob([bytes], 'application/json');
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.AnchorElement(href: url)..setAttribute('download', filename);
  html.document.body?.append(anchor);
  anchor.click();
  anchor.remove();
  html.Url.revokeObjectUrl(url);
  return 'Downloaded $filename to your browser\'s downloads folder.';
}
