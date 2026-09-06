import 'dart:io';
import 'package:path_provider/path_provider.dart';

Future<String> downloadBackup(String jsonContent, String filename) async {
  final dir = await getApplicationDocumentsDirectory();
  final file = File('${dir.path}/$filename');
  await file.writeAsString(jsonContent);
  return 'Saved backup to ${file.path}';
}
