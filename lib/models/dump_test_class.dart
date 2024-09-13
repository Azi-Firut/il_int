

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:logger/logger.dart';
import 'package:process_run/shell.dart';
import '../constant.dart';

class TestClass {
  static final TestClass _instance = TestClass._internal();

  factory TestClass() {
    return _instance;
  }

  TestClass._internal();

  String keyPath = '';
  String calibrationPath = '';
  String decodedString = "";
  String unitResponse='';
  List<ProcessResult> out=[];


  // Переменные для путей к plink и pscp
  final String _plinkPath = 'data/flutter_assets/assets/plink.exe';


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

  Future<bool> _createTempKeyFile() async {
    decodedString = _decodeStringWithRandom(key);
    final appDir = Directory.current;
    final tempDir = Directory('${appDir.path}/temp');
    if (!await tempDir.exists()) {
      await tempDir.create(recursive: true);
    }
    final keyFile = File('${tempDir.path}/resepi_login.ppk');
    await keyFile.writeAsString(decodedString);
    keyPath = keyFile.path;
    print("The procedure create K.");
    return await keyFile.exists();
  }

  Future<void> _deleteTempKeyFile() async {
    final keyFile = File(keyPath);
    if (await keyFile.exists()) {
      try {
        await keyFile.delete();
        print("The procedure is completed K.");
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


  var process;
  var process2;
  var test='';
  var test2='';


  Future<void> runUnit(Function updateState) async {
    if (await _createTempKeyFile()) {
      try {
        var processRunUnit = await Process.start(
          _plinkPath,
          ['-i', keyPath, 'root@192.168.12.1', '-hostkey', hostKey, "systemctl start payload"],
        );
        await Future.delayed(Duration(seconds: 1), () async {
          processRunUnit.kill();
        });
      } catch (e) {
      } finally {
        await _deleteTempKeyFile();
        updateState;
      }
    }
  }

  Future<void> getI(Function updateState) async {
    if (await _createTempKeyFile()) {
      try {
        getI2(updateState);
        print("--------------------------------------------------   1  ");
        process = await Process.start(
          _plinkPath,
          ['-i', keyPath, 'root@192.168.12.1', '-hostkey', hostKey, "systemctl stop payload"],
        );
        //fun1.kill();
        await Future.delayed(Duration(seconds: 1), () async {
          print("--------------------------------------------------   2  ");
          StringBuffer outputBuffer = StringBuffer();
          process = await Process.start(
            _plinkPath,
            ['-i', keyPath, 'root@192.168.12.1', '-hostkey', hostKey, "hexdump -C /dev/ttymxc3"],
          );
          //  Слушаем стандартный вывод (stdout)
          process.stdout.transform(utf8.decoder).listen((data) {
            outputBuffer.write(data);
            test2=data;
          });
          // Слушаем ошибки (stderr)
          process.stderr.transform(utf8.decoder).listen((data) {
            print("Ошибка: $data");
          });
        });
      } finally {
        updateState();
      }
    } else {
      updateState();
    }
  }


  Future<void> getI2(Function updateState) async {
    if (await _createTempKeyFile()) {
      try {
        Future.delayed(Duration(seconds: 2), () async {
          process2 = await Process.start(
            _plinkPath,
            ['-i', keyPath, 'root@192.168.12.1', '-hostkey', hostKey, "echo -en '\\xaa\\x55\\x00\\x00\\x09\\x00\\xff\\x57\\x09\\x68\\x01' >/dev/ttymxc3"],
          );
        });
        Future.delayed(Duration(seconds: 3), () async {
          process2 = await Process.start(
            _plinkPath,
            ['-i', keyPath, 'root@192.168.12.1', '-hostkey', hostKey, "stty -F /dev/ttymxc3 921600"],
          );
        });
        Future.delayed(Duration(seconds: 4), () async {
          process2 = await Process.start(
            _plinkPath,
            ['-i', keyPath, 'root@192.168.12.1', '-hostkey', hostKey, "echo -en '\\xA5\\xA5\\x02\\x04\\x0A\\x02\\x01\\x00\\x5D\\xFB' >/dev/ttymxc3"],
          );
          print("--------------------------------------------------   STOP  ");
        });
        await Future.delayed(Duration(seconds: 4), () async {
          print("--------------------------------------------------   DATA CALL  ");
          process2 = await Process.start(
              _plinkPath,
              ['-i', keyPath, 'root@192.168.12.1', '-hostkey', hostKey, "echo -en '\\xA5\\xA5\\x01\\x02\\x06\\x00\\x53\\x2D' >/dev/ttymxc3"]);
          process2 = await Process.start(
              _plinkPath,
              ['-i', keyPath, 'root@192.168.12.1', '-hostkey', hostKey, "echo -en '\\xA5\\xA5\\x01\\x02\\x06\\x00\\x53\\x2D' >/dev/ttymxc3"]);
          process2 = await Process.start(
              _plinkPath,
              ['-i', keyPath, 'root@192.168.12.1', '-hostkey', hostKey, "echo -en '\\xA5\\xA5\\x01\\x02\\x06\\x00\\x53\\x2D' >/dev/ttymxc3"]);
          process2 = await Process.start(
              _plinkPath,
              ['-i', keyPath, 'root@192.168.12.1', '-hostkey', hostKey, "echo -en '\\xA5\\xA5\\x01\\x02\\x06\\x00\\x53\\x2D' >/dev/ttymxc3"]);
          print("--------------------------------------------------   DATA CALL  ");
        });

        Future.delayed(Duration(seconds: 6), () async {
          await _deleteTempKeyFile();
          await process2.kill();
          updateState();
          String result = _processUnitResponse(test2).replaceAll('\n', '').replaceAll(' ', '');
          print('======================================= \\/\n${result}');

          // Регулярное выражение для поиска номеров из букв и цифр длиной не менее 5 символов
          RegExp regExp = RegExp(r'\.([A-Za-z0-9]{5,})\.');
          // Ищем все совпадения
          RegExpMatch? match = regExp.firstMatch(result);
          // Выводим найденные номера
          if (match != null) {
            print('Найден номер: ${match.group(1)}');
            test="${match.group(1)}";
            updateState;
            runUnit(updateState);
          } else {
            print('Номер не найден');
            await process.kill();
            runUnit(updateState);
            Future.delayed(Duration(seconds: 3), () async {
              getI(updateState);
            });
          }
          await process.kill();
        });
      } finally {
      }
    } else {
    }
  }


  String _processUnitResponse(String response) {

    // Use a regular expression to match the part with ASCII characters after the hex values
    RegExp regExp = RegExp(r'\|(.+)\|');
    Iterable<Match> matches = regExp.allMatches(response);

    // Extract the matched ASCII parts
    List<String> asciiParts = [];
    for (var match in matches) {
      asciiParts.add(match.group(1) ?? '');
    }

    // Split response into lines and get the last 300 lines
    List<String> lines = response.split('\n');
    int start = lines.length > 1000 ? lines.length - 1000 : 0;

    return lines.sublist(start).map((line) {
      // Apply the regular expression to each line and extract ASCII characters
      RegExp matchAscii = RegExp(r'\|([^\|]+)\|');
      var match = matchAscii.firstMatch(line);
      return match?.group(1) ?? '';
    }).join('\n');
  }



///////////////////////////////////////////////////

}
