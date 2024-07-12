import 'dart:convert';
import 'dart:io';
import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'package:process_run/shell.dart';
import '../constant.dart';

class TestClass {
  static final TestClass _instance = TestClass._internal();

  factory TestClass() {
    return _instance;
  }

  TestClass._internal();

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
  String outputCalibration = "";
  String outputCalibration1 = "";String outputCalibration3 = "";String outputCalibration4 = "";String outputCalibration5 = "";String outputCalibration6 = "";String outputCalibration7 = "";
  String _outputCalibration2="";
  String outputBrand = "";
  String keyPath = '';
  String brand = "";
  String calibrationPath = '';
  String decodedString = "";

  // Переменные для путей к plink и pscp
  final String _plinkPath = 'data/flutter_assets/assets/plink.exe';
  //final String _puttyPath = 'data/flutter_assets/assets/putty.exe';
  final String _pscpPath = 'data/flutter_assets/assets/pscp.exe';

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
      outputCalibration = "Procedure started............";
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
      outputCalibration = output;
    } else {
      outputCalibration = "Procedure failed";
    }
    updateState();
  }

  Future<void> checkCalibrationFile(Function updateState) async {
    if (await _createTempKeyFile()) {
      final shell = Shell();
      outputCalibration = "... Looking for the device calibration file ...";
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
      outputCalibration = output;
    } else {
      outputCalibration = "Procedure failed";
    }
    updateState();
  }

  Future<void> restoreCalibration(Function updateState) async {
    if (await _createTempKeyFile()) {
      final shell = Shell();
      outputCalibration = "Procedure started............";
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
      outputCalibration = output;
    } else {
      outputCalibration = "Procedure failed";
    }
    updateState();
  }

  /////////////////////
  Future<void> getDeviceInfo(Function updateState) async {
    if (await _createTempKeyFile()) {
      final shell = Shell();
      outputCalibration = "Procedure started............";
      updateState();
      String output = "";
      try {
        var brandNow = await shell.run('''
          ${_plinkPath} -i "$keyPath" -P 22 root@192.168.12.1 -hostkey "$hostKey" "cat /etc/brand"
          ''');
        var passphraseNow = await shell.run('''
          ${_plinkPath} -i "$keyPath" -P 22 root@192.168.12.1 -hostkey "$hostKey" "cat /etc/passphrase"
          ''');
        var ssidNow = await shell.run('''
          ${_plinkPath} -i "$keyPath" -P 22 root@192.168.12.1 -hostkey "$hostKey" "cat /etc/hostname"
          ''');
        var receiverNow = await shell.run('''
          ${_plinkPath} -i "$keyPath" -P 22 root@192.168.12.1 -hostkey "$hostKey" "cat /etc/payload/receiver"
          ''');
        var scannerNow = await shell.run('''
          ${_plinkPath} -i "$keyPath" -P 22 root@192.168.12.1 -hostkey "$hostKey" "cat /etc/payload/scanner"
          ''');
        var firmwareNow = await shell.run('''
  ${_plinkPath} -i "$keyPath" -P 22 root@192.168.12.1 -hostkey "$hostKey" "head -n 1 /etc/release_notes"
''');

        ////
        // await shell.run('''
        //   ${_plinkPath} -i "$keyPath" -P 22 root@192.168.12.1 -hostkey "$hostKey" "mount -o remount,rw / && echo '${brandNow.outText}' > /etc/brand && exit"
        //   ''');
        // const calibrationAssetPath = 'assets/calibration';
        // await shell.run('''
        // ${_pscpPath} -i "$keyPath" -P 22 "$calibrationAssetPath" root@192.168.12.1:/etc/payload/calibration
        // ''');
        /////////////////
        output =
            " Brand: ${brandNow.outText}\n Password: ${passphraseNow.outText}\n SSID: ${ssidNow.outText}\n Reciever: ${receiverNow.outText}\n Scanner: ${scannerNow.outText}\n Firmware: ${firmwareNow.outText}";
        /////////////////
      } catch (e) {
        output =
            "Failed to copy calibration file: check all conditions before start $e";
      } finally {
        await _deleteTempKeyFile();
      }
      outputCalibration = output;
    } else {
      outputCalibration = "Procedure failed";
    }
    updateState();
  }

/// IMU ///
  String _decodeBinary(String binary) {
    return utf8.decode(binary.codeUnits);
  }

  String _decodeHex(String hex) {
    return String.fromCharCodes(
        hex.replaceAll(RegExp(r'\s+'), '').runes
            .where((r) => r >= 0x30 && r <= 0x39 || r >= 0x41 && r <= 0x46 || r >= 0x61 && r <= 0x66)
            .map((r) => int.parse(String.fromCharCode(r), radix: 16))
    );
  }

  String get outputCalibration2 {
    return _outputCalibration2.length > 50
        ? _outputCalibration2.substring(_outputCalibration2.length - 50)
        : _outputCalibration2;
  }

  set outputCalibration2(String value) {
    _outputCalibration2 = value;
  }

  Future<void> runIMUCommands2(Function updateState) async {
    if (await _createTempKeyFile()) {
      final shell1 = Shell();
      final shell2 = Shell();
      final shell3 = Shell();
      final shell4 = Shell();
      final shell5 = Shell();
      final shell6 = Shell();
      final shell7 = Shell();
      String output = "";
      String output2 = "";



      try {
     //  In the first window, invoke "systemctl stop payload"
        Future.delayed(Duration(seconds: 0), () async {
          try {
            print("======================= 1");
            var result = await shell1.run('''
            ${_plinkPath} -i "$keyPath" -P 22 root@192.168.12.1 -hostkey "$hostKey" "systemctl stop payload"
          ''');
            outputCalibration1=result.outText;
            updateState();
          } catch (e) {
            output = "Command 1 failed: $e\n";
          }

          print("======================= 1 => $output");
        });

        // In the first window, invoke "hexdump -C /dev/ttymxc3"
        Future.delayed(Duration(seconds: 2), () async {

            print("======================= 2");//| head -n 1000
            var result = await shell1.run('''
            ${_plinkPath} -i "$keyPath" -P 22 root@192.168.12.1 -hostkey "$hostKey" "hexdump -C /dev/ttymxc3"
          ''');
            _outputCalibration2=result.outText;
            updateState();

          print("======================= 2 => $output");
        });


      // In the second window, invoke "echo -en '\xaa\x55\x00\x00\x09\x00\xff\x57\x09\x68\x01' >/dev/ttymxc3"
        Future.delayed(Duration(seconds: 4), () async {
          try {
            print("======================= 3");
            var result2 = await shell2.run('''
            ${_plinkPath} -i "$keyPath" root@192.168.12.1 -hostkey "$hostKey" "echo -en '\\xaa\\x55\\x00\\x00\\x09\\x00\\xff\\x57\\x09\\x68\\x01' >/dev/ttymxc3"
          ''');
            //outputCalibration2=result2.outText;
            updateState();
          } catch (e) {
           // output2 = "Command 3 failed: $e\n";
          }
          print("======================= 3 => $output2");
        });

        // In the second window, invoke "stty -F /dev/ttymxc3 921600"
        Future.delayed(Duration(seconds: 6), () async {

            print("======================= 4");
            var result2 = await shell3.run('''
            ${_plinkPath} -i "$keyPath" -P 22 root@192.168.12.1 -hostkey "$hostKey" "stty -F /dev/ttymxc3 921600"
          ''');
            outputCalibration3=result2.outText;
            updateState();

          print("======================= 4 => $output2");
        });

      //  In the second window, invoke "echo -en '\xA5\xA5\x02\x04\x0A\x02\x01\x00\x5D\xFB' >/dev/ttymxc3"
        Future.delayed(Duration(seconds: 8), () async {
          try {
            print("======================= 5");
            var result2 = await shell4.run('''
            ${_plinkPath} -i "$keyPath" -P 22 root@192.168.12.1 -hostkey "$hostKey" "echo -en '\\xA5\\xA5\\x02\\x04\\x0A\\x02\\x01\\x00\\x5D\\xFB' >/dev/ttymxc3"
          ''');
            outputCalibration4=result2.outText;
            updateState();
          } catch (e) {
            output2 = "Command 5 failed: $e\n";
          }
         print("======================= 5 => $output2");
        });

        Future.delayed(Duration(seconds: 10), () async {
          try {
        print("======================= 6");
        var result2 = await shell5.run('''
      ${_plinkPath} -i "$keyPath" root@192.168.12.1 -hostkey "$hostKey" "echo -en '\\xA5\\xA5\\x01\\x02\\x06\\x00\\x53\\x2D' >/dev/ttymxc3"
      ''');
        outputCalibration5=result2.outText;
        updateState();
      } catch (e) {
        output2 = "Command 6 failed: $e\n";
      }
      print("======================= 6 => $output2");

    });
        Future.delayed(Duration(seconds: 11), () async {
          try {
            print("======================= 7");
            var result2 = await shell6.run('''
      ${_plinkPath} -i "$keyPath" root@192.168.12.1 -hostkey "$hostKey" "echo -en '\\xA5\\xA5\\x01\\x02\\x06\\x00\\x53\\x2D' >/dev/ttymxc3"
      ''');
            outputCalibration6=result2.outText;
            updateState();
          } catch (e) {
            output2 = "Command 7 failed: $e\n";
          }
          print("======================= 7 => $output2");

        });
      } catch (e) {
      } finally {
      }
    } else {
      outputCalibration = "Failed to create key file.";
    }

   // updateState();
  }



}
