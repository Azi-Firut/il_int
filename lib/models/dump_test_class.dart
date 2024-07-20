
import 'dart:convert';
import 'dart:io';
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
  String unitResponse = "";
  var out;


  // Переменные для путей к plink и pscp
  final String _plinkPath = 'data/flutter_assets/assets/plink.exe';

  void init() {
    decodedString = _decodeStringWithRandom(key);
  }


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

  /// IMU ///
  Future<void> runIMUCommands2(Function updateState) async {
    if (await _createTempKeyFile()) {
      final shell1 = Shell();
      final shell2 = Shell();
      final shell3 = Shell();


      try {
        // Future.delayed(Duration(seconds: 0), () async {
        print("======================= 1");
        shell1.run('''
            ${_plinkPath} -i "$keyPath" -P 22 root@192.168.12.1 -hostkey "$hostKey" "systemctl stop payload"
          ''');
        print("======================= 1 End");
        // });

        Future.delayed(Duration(seconds: 1), () async {
          print("======================= 2");
          try {
            var result2 = await shell1.run('''
              ${_plinkPath} -i "$keyPath" -P 22 root@192.168.12.1 -hostkey "$hostKey" "hexdump -C /dev/ttymxc3"
            ''');
            if (result2.isNotEmpty) {
              unitResponse = _processUnitResponse(result2.outText);
              updateState(); // Call updateState here
            } else {
              print("No output from shell2.run");
            }
          } catch (e) {
            print("Error running shell2: $e");
          }
        });

        Future.delayed(Duration(seconds: 2), () async {
          print("======================= 3");
          await shell3.run('''
            ${_plinkPath} -i "$keyPath" root@192.168.12.1 -hostkey "$hostKey" "echo -en '\\xaa\\x55\\x00\\x00\\x09\\x00\\xff\\x57\\x09\\x68\\x01' >/dev/ttymxc3"
          ''');
          print("======================= 3 => END");
        });

        Future.delayed(Duration(seconds: 4), () async {
          print("======================= 4");
          await shell3.run('''
            ${_plinkPath} -i "$keyPath" -P 22 root@192.168.12.1 -hostkey "$hostKey" "stty -F /dev/ttymxc3 921600"
          ''');
          print("======================= 4 => END");
        });

        Future.delayed(Duration(seconds: 6), () async {
          print("======================= 5");
          await shell3.run('''
            ${_plinkPath} -i "$keyPath" -P 22 root@192.168.12.1 -hostkey "$hostKey" "echo -en '\\xA5\\xA5\\x02\\x04\\x0A\\x02\\x01\\x00\\x5D\\xFB' >/dev/ttymxc3"
          ''');
          print("======================= 5 => END");
        });

        Future.delayed(Duration(seconds: 10), () async {
          print("======================= 6");
          await shell3.run('''
            ${_plinkPath} -i "$keyPath" root@192.168.12.1 -hostkey "$hostKey" "echo -en '\\xA5\\xA5\\x01\\x02\\x06\\x00\\x53\\x2D' >/dev/ttymxc3"
          ''');
          print("======================= 6 => END");
        });

        Future.delayed(Duration(seconds: 11), () async {
          print("======================= 6");
          await shell3.run('''
            ${_plinkPath} -i "$keyPath" root@192.168.12.1 -hostkey "$hostKey" "echo -en '\\xA5\\xA5\\x01\\x02\\x06\\x00\\x53\\x2D' >/dev/ttymxc3"
          ''');
          print("======================= 6 => END");
        });

        Future.delayed(Duration(seconds: 15), () async {
          print("======================= 7");
          await shell3.run('''
            ${_plinkPath} -i "$keyPath" root@192.168.12.1 -hostkey "$hostKey" "echo -en '\\xA5\\xA5\\x01\\x02\\x06\\x00\\x53\\x2D' >/dev/ttymxc3 && exit"
          ''');
          print("======================= 7 => END");
          print("======================= 7 => $unitResponse END");
          print("======================= 7 => $out END");
          updateState(); // Call updateState here
          await _deleteTempKeyFile();
        });
      } catch (e) {
        print("Error: $e");
      }
    } else {
      unitResponse = "Failed to create key file.";
      updateState(); // Call updateState here
    }
  }

  String _processUnitResponse(String response) {
    // Remove ".|" from the response
    response = response.replaceAll('.|', '');

    // Split response into lines and get the last 10 lines
    List<String> lines = response.split('\n');
    int start = lines.length > 100 ? lines.length - 100 : 0;
    return lines.sublist(start).join('\n');
  }
}
