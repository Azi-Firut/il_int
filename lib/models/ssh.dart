import 'dart:convert';
import 'dart:io';
import 'package:html/parser.dart';

import '../constant.dart';
import 'package:http/http.dart' as http;

String decodedString = "";
var tempDir;
//String keyPath = '';
const String plinkPath = 'data/flutter_assets/assets/plink.exe';
const String pscpPath = 'data/flutter_assets/assets/pscp.exe';
var ssidCompare='';

Future<String?> fetchTitle() async {
  ssidCompare=connectedSsid;
  final url = Uri.parse('http://192.168.12.1/');
  final response = await http.get(url);

  if (response.statusCode == 200) {
    // Парсинг HTML
    var document = parse(response.body);
    var titleElement = document.getElementsByTagName('title').first;
    print('получениe данных: ${titleElement.text}');
    titleText = titleElement.text;
    return titleElement.text; // Вернет текст внутри <title>
  } else {
    print('Ошибка при получении данных: ${response.statusCode}');
    return null;
  }
}


Future<void> getVersion() async {
if(ssidCompare != connectedSsid){
  await fetchTitle();
} else {}

 // titleText  = (await fetchTitle().toString());
  print('Текст внутри <title>: $titleText');
}


String decodeStringWithRandom(String input) {
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
  await getVersion();
  print("$titleText");
 // titleText = await getVersion();
if(await titleText == "RESEPI GEN-II") {
  print('K2');
  var key = keyGen2;
  decodedString = decodeStringWithRandom(key[0]);
  hostKey = key[1];
  final appDir = Directory.current;
  tempDir = Directory('${appDir.path}/temp');
  if (!await tempDir.exists()) {
    await tempDir.create(recursive: true);
  }
  final keyFile = File('${tempDir.path}/resepi_login.ppk');
  await keyFile.writeAsString(decodedString);
  keyPath = keyFile.path;
  print("OPEN");
  return await keyFile.exists();
  }else{var key = keyGen1;
print('K1');
  decodedString = decodeStringWithRandom(key[0]);
hostKey = key[1];
  final appDir = Directory.current;
  tempDir = Directory('${appDir.path}/temp');
  if (!await tempDir.exists()) {
  await tempDir.create(recursive: true);
}
final keyFile = File('${tempDir.path}/resepi_login.ppk');
await keyFile.writeAsString(decodedString);
keyPath = keyFile.path;
print("OPEN \n$key");
return await keyFile.exists();}
}

Future<void> deleteTempKeyFile() async {
  final keyFile = File(keyPath);
  if (await keyFile.exists()) {
    try {
      await keyFile.delete();
      print("CLOSE");
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
