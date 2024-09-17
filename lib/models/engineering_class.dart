import 'dart:convert';
import 'dart:io';

import 'package:process_run/shell.dart';

import '../constant.dart';

class Engineering {
  static final Engineering _instance = Engineering._internal();

  factory Engineering() {
    return _instance;
  }

  Engineering._internal();

  final List<String> scannerList = [
    "hesai",
    "velodyne",
    "scanner",
    "livox 3,1"
  ];

  String? selectedScanner;
  String statusOutput = "";
  String outputScanner = "";
  String keyPath = '';
  String scanner = "";
  String calibrationPath = '';
  String decodedString = "";

  // Переменные для путей к plink и pscp
  final String _plinkPath = 'data/flutter_assets/assets/plink.exe';
  final String _pscpPath = 'data/flutter_assets/assets/pscp.exe';

  /// SSH KIT

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
    return await keyFile.exists();
  }

  Future<void> _deleteTempKeyFile() async {
    final keyFile = File(keyPath);
    if (await keyFile.exists()) {
      try {
        await keyFile.delete();
        print("The procedure is completed.");
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

  /// SSH KIT END

  Future<void> changeReceiver(Function updateState) async {
    if (await _createTempKeyFile()) {
      outputScanner = "Procedure started............";
      updateState();
      final shell = Shell();
      try {
        await shell.run('''
       $_plinkPath -i "$keyPath" -P 22 root@192.168.12.1 -hostkey "$hostKey" "mount -o remount,rw / && echo novatel >/etc/payload/receiver && exit"
        ''');

        outputScanner = "Scanner changed successfully to $selectedScanner";
      } catch (e) {
        outputScanner = "Failed to change: check all conditions before start";
      } finally {
        await _deleteTempKeyFile();
      }
    } else {
      outputScanner = "Procedure failed";
    }

    updateState();
  }

  Future<void> changeScanner(Function updateState) async {
    if (selectedScanner != null) {
      if (await _createTempKeyFile()) {
        outputScanner = "Procedure started............";
        updateState();
        final shell = Shell();
        try {
          final result = await shell.run('''
       $_plinkPath -i "$keyPath" -P 22 root@192.168.12.1 -hostkey "$hostKey" "mount -o remount,rw / && echo '${selectedScanner!}' >/etc/payload/scanner && exit"
        ''');

          String combinedOutput =
              result.map((e) => e.stdout + e.stderr).join('\n');

          outputScanner = "Scanner changed successfully to $selectedScanner";
        } catch (e) {
          String errorMessage = e.toString();

          String shellContext = shell.context.toString();

          String combinedErrorOutput =
              "Error: $errorMessage\n \nShell output: $shellContext";

          outputScanner = "Failed to change: check all conditions before start";
        } finally {
          await _deleteTempKeyFile();
        }
      } else {
        outputScanner = "Procedure failed";
      }
    } else {
      outputScanner =
          "Please select a scanner and ensure the device is connected.";
    }
    updateState();
  }
}
