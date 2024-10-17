import 'dart:convert';
import 'dart:io';
import '../constant.dart';

String decodedString = "";
var tempDir;
//String keyPath = '';
const String plinkPath = 'data/flutter_assets/assets/plink.exe';
const String pscpPath = 'data/flutter_assets/assets/pscp.exe';

String _decodeStringWithRandom(String input) {
  StringBuffer cleaned = StringBuffer();
  for (int i = 0; i < input.length; i++) {
    if (i % 3 != 2) {
      cleaned.write(input[i]);
    }
  }
  List<int> bytes = base64Decode(cleaned.toString());
  String decodedString = utf8.decode(bytes);
  return decodedString;
}

Future<bool> createTempKeyFile() async {
  decodedString = _decodeStringWithRandom(key);
  final appDir = Directory.current;
  tempDir = Directory('${appDir.path}/temp');
  if (!await tempDir.exists()) {
    await tempDir.create(recursive: true);
  }
  final keyFile = File('${tempDir.path}/resepi_login.ppk');
  await keyFile.writeAsString(decodedString);
  keyPath = keyFile.path;
  return await keyFile.exists();
}

Future<void> deleteTempKeyFile() async {
  final keyFile = File(keyPath);
  if (await keyFile.exists()) {
    try {
      await keyFile.delete();
      print("The procedure is completed. K");
    } catch (e) {
      print("Failed : $e");
      await Future.delayed(Duration(seconds: 1));
      try {
        await keyFile.delete();
        print("Retry procedure.");
      } catch (retryException) {
        print("Procedure failed : $retryException");
      }
    }
  }
}
