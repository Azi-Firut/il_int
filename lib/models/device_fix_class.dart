import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'package:process_run/shell.dart';
import '../constant.dart';

class DeviceFix {
  static final DeviceFix _instance = DeviceFix._internal();

  factory DeviceFix() {
    return _instance;
  }

  DeviceFix._internal();

  final List<String> brandsList = [
    "ROCK",
    "SNOOPY",
    "ML",
    "MARSS",
    "TRIDAR",
    "RECON",
    "TERSUS",
    "RESEPI",
    "FLIGHTS",
    "WINGTRA",
    "STONEX"
  ];

  String? selectedBrand;
  String statusOutput = "";
  String outputBrand = "";
  String keyPath = '';
  String brand = "";
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


  Future<void> loadCalibrationFile() async {
    final appDir = Directory.current;
    final tempDir = Directory('${appDir.path}/assets');
    if (!await tempDir.exists()) {
      await tempDir.create(recursive: true);
    }
    final calibrationFile = File('${tempDir.path}/calibration');
    final calibrationData = await rootBundle.load('assets/calibration');
    await calibrationFile.writeAsBytes(calibrationData.buffer.asUint8List());
    calibrationPath = calibrationFile.path;
  }


  Future<void> changeBrand(Function updateState) async {
    if (selectedBrand != null) {
      if (await _createTempKeyFile()) {
        outputBrand = "Procedure started............";
        updateState();
        final shell = Shell();
        try {
          final result = await shell.run('''
       $_plinkPath -i "$keyPath" -P 22 root@192.168.12.1 -hostkey "$hostKey" "mount -o remount,rw / && echo '${selectedBrand!.toUpperCase()}' > /etc/brand && exit"
        ''');

          String combinedOutput =
              result.map((e) => e.stdout + e.stderr).join('\n');

          outputBrand =
              "Brand changed successfully to $selectedBrand\nNow you need to update the firmware on your device to the latest version";
        } catch (e) {
          String errorMessage = e.toString();

          String shellContext = shell.context.toString();

          String combinedErrorOutput =
              "Error: $errorMessage\n \nShell output: $shellContext";

          outputBrand =
              "Failed to change brand: check all conditions before start";
        } finally {
          await _deleteTempKeyFile();
        }
      } else {
        outputBrand = "Procedure failed";
      }
    } else {
      outputBrand = "Please select a brand and ensure the device is connected.";
    }
    updateState();
  }

  Future<void> deleteCalibration(Function updateState) async {
    if (await _createTempKeyFile()) {
      final shell = Shell();
      statusOutput = "Procedure started............";
      updateState();
      String output = "";
      try {
        await shell.run('''
        ${_plinkPath} -i "$keyPath" -P 22 root@192.168.12.1 -hostkey "$hostKey" "cd /etc/payload && mount -o remount,rw / && rm -rf calibration && mount -o remount,ro / && exit"
        ''');
        output = "Calibration file successfully deleted.";
      } catch (e) {
        output =
            "Failed to delete calibration: check all conditions before start";
      } finally {
        await _deleteTempKeyFile();
      }
      statusOutput = output;
    } else {
      statusOutput = "Procedure failed";
    }
    updateState();
  }

  Future<void> checkCalibrationFile(Function updateState) async {
    if (await _createTempKeyFile()) {
      final shell = Shell();
      statusOutput = "... Looking for the device calibration file ...";
      updateState();
      String output = "";
      try {
        var result = await shell.run('''
${_plinkPath} -ssh -i "$keyPath" root@192.168.12.1 -hostkey "$hostKey" "test -e /etc/payload/calibration && echo 'Calibration file exists' || (echo 'Calibration file does not exist';)"
''');
        ////////////////////////////////////////////
        if (result.outText == "Calibration file does not exist") {
          restoreCalibration(updateState);
        }
        ////////////////////////////////////////////
        output = result.outText;
      } catch (e) {
        output = "! Failed to retrieve data from device !";
      } finally {
        await _deleteTempKeyFile();
      }
      statusOutput = output;
    } else {
      statusOutput = "Procedure failed";
    }
    updateState();
  }

  Future<void> restoreCalibration(Function updateState) async {
    if (await _createTempKeyFile()) {
      final shell = Shell();
      statusOutput = "Procedure started............";
      updateState();
      String output = "";
      try {
        var brandNow = await shell.run('''
          ${_plinkPath} -i "$keyPath" -P 22 root@192.168.12.1 -hostkey "$hostKey" "cat /etc/brand"
          ''');
        await shell.run('''
          ${_plinkPath} -i "$keyPath" -P 22 root@192.168.12.1 -hostkey "$hostKey" "mount -o remount,rw / && echo '${brandNow.outText}' > /etc/brand && exit"
          ''');
        const calibrationAssetPath = 'assets/calibration';
        await shell.run('''
        ${_pscpPath} -i "$keyPath" -P 22 "$calibrationAssetPath" root@192.168.12.1:/etc/payload/calibration 
        ''');
        output = "Calibration file copied successfully.";
      } catch (e) {
        output =
        "Failed to copy calibration file: check all conditions before start";
      } finally {
        await _deleteTempKeyFile();
      }
      statusOutput = output;
    } else {
      statusOutput = "Procedure failed";
    }
    updateState();
  }

}
