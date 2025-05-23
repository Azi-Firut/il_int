import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'package:il_int/models/ssh.dart';
import 'package:process_run/shell.dart';
import '../constant.dart';
import '../widgets/answer_from_unit.dart';

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

  String outputBrand = "";

  String brand = "";
  String calibrationPath = '';
  String decodedString = "";

  // Переменные для путей к plink и pscp
  final String _plinkPath = 'data/flutter_assets/assets/plink.exe';
  final String _pscpPath = 'data/flutter_assets/assets/pscp.exe';




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
      if (await createTempKeyFile()) {
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
          await deleteTempKeyFile();
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
    if (await createTempKeyFile()) {
      final shell = Shell();
      pushUnitResponse(0,"Procedure started",updateState:updateState);

      try {
        await shell.run('''
        $_plinkPath -i "$keyPath" -P 22 root@192.168.12.1 -hostkey "$hostKey" "cd /etc/payload && mount -o remount,rw / && rm -rf calibration && mount -o remount,ro / && exit"
        ''');
        pushUnitResponse(1,"Calibration file successfully deleted",updateState:updateState);

      } catch (e) {
        pushUnitResponse(2,"Failed to delete calibration: check all conditions before start",updateState:updateState);
      } finally {
        await deleteTempKeyFile();
      }

    } else {
      pushUnitResponse(2,"Procedure failed",updateState:updateState);

    }
    updateState();
  }

  Future<void> checkCalibrationFile(Function updateState) async {
    if (await createTempKeyFile()) {
      final shell = Shell();
      pushUnitResponse(0,"Looking for the device calibration file",updateState:updateState);

      try {
        var result = await shell.run('''
$_plinkPath -ssh -i "$keyPath" root@192.168.12.1 -hostkey "$hostKey" "test -e /etc/payload/calibration && echo 'Calibration file exists' || (echo 'Calibration file does not exist';)"
''');
        ////////////////////////////////////////////
        if (result.outText == "Calibration file does not exist") {
          restoreCalibration(updateState);
        }
        ////////////////////////////////////////////
        pushUnitResponse(1,result.outText,updateState:updateState);

      } catch (e) {
        pushUnitResponse(2,"Failed to retrieve data from device",updateState:updateState);

      } finally {
        await deleteTempKeyFile();
      }
    } else {
      pushUnitResponse(2,"Procedure failed",updateState:updateState);
    }
    updateState();
  }

  Future<void> restoreCalibration(Function updateState) async {
    if (await createTempKeyFile()) {
      final shell = Shell();
      pushUnitResponse(0,"Procedure started",updateState:updateState);

      try {
        var brandNow = await shell.run('''
          $_plinkPath -i "$keyPath" -P 22 root@192.168.12.1 -hostkey "$hostKey" "cat /etc/brand"
          ''');
        await shell.run('''
          $_plinkPath -i "$keyPath" -P 22 root@192.168.12.1 -hostkey "$hostKey" "mount -o remount,rw / && echo '${brandNow.outText}' > /etc/brand && exit"
          ''');
        const calibrationAssetPath = 'assets/calibration';
        await shell.run('''
        $_pscpPath -i "$keyPath" -P 22 "$calibrationAssetPath" root@192.168.12.1:/etc/payload/calibration 
        ''');
        pushUnitResponse(1,"Calibration file copied successfully",updateState:updateState);
      } catch (e) {
        pushUnitResponse(2,"Failed to copy calibration file:\ncheck all conditions before start",updateState:updateState);

      } finally {
        await deleteTempKeyFile();
      }
    } else {
      pushUnitResponse(2,"Procedure failed",updateState:updateState);
    }
    updateState();
  }

}
