import 'dart:convert';
import 'dart:io';

import 'package:il_int/models/ssh.dart';
import 'package:process_run/shell.dart';

import '../constant.dart';
import '../widgets/answer_from_unit.dart';

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

  String scanner = "";
  String calibrationPath = '';



  Future<void> changeReceiver(Function updateState) async {
    if (await createTempKeyFile()) {
      pushUnitResponse(0,"Procedure started",updateState:updateState);

      final shell = Shell();
      try {
        await shell.run('''
       $plinkPath -i "$keyPath" -P 22 root@192.168.12.1 -hostkey "$hostKey" "mount -o remount,rw / && echo novatel >/etc/payload/receiver && exit"
        ''');
        pushUnitResponse(1,"Scanner changed successfully to $selectedScanner",updateState:updateState);

      } catch (e) {

        pushUnitResponse(2,"Failed to change: check all conditions before start",updateState:updateState);

      } finally {
        await deleteTempKeyFile();
      }
    } else {
      pushUnitResponse(2,"Procedure failed",updateState:updateState);

    }

    updateState();
  }

  Future<void> changeScanner(Function updateState) async {
    if (selectedScanner != null) {
      if (await createTempKeyFile()) {
        pushUnitResponse(0,"Procedure started",updateState:updateState);

        final shell = Shell();
        try {
          final result = await shell.run('''
       $plinkPath -i "$keyPath" -P 22 root@192.168.12.1 -hostkey "$hostKey" "mount -o remount,rw / && echo '${selectedScanner!}' >/etc/payload/scanner && exit"
        ''');

          String combinedOutput =
              result.map((e) => e.stdout + e.stderr).join('\n');
          pushUnitResponse(1,"Scanner changed successfully to $selectedScanner",updateState:updateState);

        } catch (e) {
          String errorMessage = e.toString();

          String shellContext = shell.context.toString();

          String combinedErrorOutput =
              "Error: $errorMessage\n \nShell output: $shellContext";
          pushUnitResponse(2,"Failed to change: check all conditions before start",updateState:updateState);
 } finally {
          await deleteTempKeyFile();
        }
      } else {
        pushUnitResponse(2,"Procedure failed",updateState:updateState);

      }
    } else {
      pushUnitResponse(3,"Please select a scanner and ensure the device is connected",updateState:updateState);
    }
    updateState();
  }
}
