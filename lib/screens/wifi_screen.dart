import 'dart:convert';
import 'dart:io';
import 'device_fix_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:process_run/process_run.dart';
import '../constant.dart';
import 'package:process_run/shell.dart';

class WiFiadd extends StatefulWidget {
  const WiFiadd({Key? key}) : super(key: key);

  @override
  WiFiaddState createState() => WiFiaddState();
}

class WiFiaddState extends State<WiFiadd> {
  var output;
  var _output2;
  String _decodedString = "";
  String? _selectedBrand;
  String _output = "";
  String _outputBrand = "";
  String _imuOutput = "";
  String _keyPath = '';
  String brand = "";
  String _calibrationPath = '';
  final String _key =
      "UHLVUUVFOktIVXBNlVciJ1LKZXTktGRmClsDZSE0yFOiIBlJY2ORzYYSP1zHaGJEyBLWR5pAc3CRwBMjDU2KCkDVuVY3IJ5OcHARpHb2I46IIGS5vCbmDUKIQ2V9tWbWBVuTdDTogVaWR1wUb3CJ0QZWNQtKb3XBlSbnLNzNaCP1rMZXBkKZUHBViIbGHljULUSxpMbmSVzXOiZAzWCkLFBVQULFFVMlUZqYWkMhODaESxYITmW9ZGVEPl0DYmG1sTemBRIHQXQlOPVFNlBVQUGFBJSWKJtUbHFpkKSEJF5OTlDRZHQUUFBZQkZJCSQkRt5IOUI1GYc0TlSBWUI8KORGCI5JUlUBtOM2CF3CZEUpnBNHCdkFYVTVXPa0Fx4XSjLl0OWHXBDDRFSJEYWVTdsOZ3Dp6PeECtpOY1CFsQeCRt0NaEKxRMa0Z9jEUUWM5SaFPI2LNkN50PcXOUwJTQKo3LZjSBtYNTABHVU2SdTYQTK0KVUHMJpBdmCF0ZZSR1MTaWN5lKczXogJMQBpBXQUHFBTSVXFDLOUQhwYUjYNCXajGZLMZEWpzMWkX0yYZEGtGDRTNV3MRmXg1FK2TcwCRTXdYZZ1YJOXcVQU0KWlMY4FaTJl5DUTM09QClNByCaXTZhVdGHUtBTUEFDQOiSBmMYTSQ1YMzWQ3KOGVUwQMTOA1EZjJI1DYWOFkNMmWRlOMzGM1EY2KYxPZjMZmIYmVM5UMDLEwEMDCJmA";
  var hostKey =
      "ssh-ed25519 255 SHA256:0z+smqD1LNdbBqOoIjFhJWhoxuJFiDtctVLxyssNFYc";
  // Переменные для путей к plink и pscp
  final String _plinkPath = 'data/flutter_assets/assets/plink.exe';
  final String _pscpPath = 'data/flutter_assets/assets/pscp.exe';

  @override
  void initState() {
    super.initState();
    wifiSearchPythonScript();
    checkCalibrationFile();
  }
  ////////////////////////////////////////////////////////////////////////////
  void _restoreCalibration() async {
    if (await _createTempKeyFile()) {
      final shell = Shell();
      _output = "Procedure started............";
      String output = "";
      try {
        var _brandNow = await shell.run('''
          ${_plinkPath} -i "$_keyPath" -P 22 root@192.168.12.1 -hostkey "$hostKey" "cat /etc/brand"
          ''');
        await shell.run('''
          ${_plinkPath} -i "$_keyPath" -P 22 root@192.168.12.1 -hostkey "$hostKey" "mount -o remount,rw / && echo '${_brandNow.outText}' > /etc/brand && exit"
          ''');
        final calibrationAssetPath = 'assets/calibration';
        await shell.run('''
        ${_pscpPath} -i "$_keyPath" -P 22 "$calibrationAssetPath" root@192.168.12.1:/etc/payload/calibration 
        ''');
        output = "Calibration file copied successfully.";
      } catch (e) {
        output = "Failed to copy calibration file: $e";
      } finally {
        await _deleteTempKeyFile();
      }
      setState(() {
        _imuOutput = brand;
        _output = output;
      });
    } else {
      setState(() {
        _output = "Procedure failed";
      });
    }
  }

  String _decodeBinary(String binary) {
    return utf8.decode(binary.codeUnits);
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
  Future<bool> _createTempKeyFile() async {
    final appDir = Directory.current;
    final tempDir = Directory('${appDir.path}/temp');
    if (!await tempDir.exists()) {
      await tempDir.create(recursive: true);
    }
    final keyFile = File('${tempDir.path}/resepi_login.ppk');
    await keyFile.writeAsString(_decodedString);
    setState(() {
      _keyPath = keyFile.path;
    });
    return await keyFile.exists();
  }

  Future<void> _deleteTempKeyFile() async {
    final keyFile = File(_keyPath);
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
  void checkCalibrationFile() async {
    if (await _createTempKeyFile()) {
      var output2;
      final shell = Shell();
      _output2 = "... Looking for the device calibration file ...";
           try {
        var result = await shell.run('''
        ${_plinkPath} -ssh -i "$_keyPath" root@192.168.12.1 -hostkey "$hostKey" "test -e /etc/payload/calibration && echo 'Calibration file exists' || (echo 'Calibration file does not exist';)"
          ''');
        /// Оставить (выводит лист файлов с юнита).
//         var result = await shell.run('''
// ${_plinkPath} -ssh -i "$_keyPath" root@192.168.12.1 -hostkey "$hostKey" "test -e /etc/payload/calibration && echo 'Calibration file exists' || (echo 'Calibration file does not exist'; ls -l /etc/payload/)"
// ''');
        output2 = "${result.outText}";
      } catch (e) {
        output2 = "! Failed to retrieve data from device !";
      } finally {
        await _deleteTempKeyFile();
      }
      setState(() {
        _output2 = output2;
        if(_output2== 'Calibration file does not exist'){
          _restoreCalibration();
        }
      });
    } else {
      setState(() {
        _output2 = "Procedure failed";
      });
    }
  }
///////////////////////////////////////////////////////////////////////////////
  Future<void> wifiSearchPythonScript() async {
    final String jsonData = await rootBundle
        .loadString('assets/ssids.json'); // Преобразуйте объект в JSON-строку

    print(jsonData);
    // final wifiExe = "assets/wifi_search.exe";

    ///
    final dataBytes =
        Uint8List.fromList(utf8.encode(jsonData)); // Конвертация строки в байты
    final stream =
        Stream.fromIterable([dataBytes]); // Создание потока из байтов
    final result = await run(
        'data/flutter_assets/assets/wifi_search/wifi_search.exe',
        // 'assets/wifi_search.exe',
        //  wifiExe,
        stdin: stream); // Путь к вашему EXE скрипту Python Для финальной сборки

    print(result[0].stderr);
    print(result[0].stdout);
    print(result[0].outText);

    setState(() {
      output = result;
    });
    checkCalibrationFile();
    // print(result.stderr);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (output == null)
          Text(
            "Wait...",
            style: TextStyle(
              color: textColorGray,
            ),
          ),
        if (output != null && output.isNotEmpty && output[0].stdout != null)
          Padding(
            padding: const EdgeInsets.only(top: 18.0),
            child: Column(
              children: [
                Text(
                  "${output[0].stdout}",
                  style: TextStyle(
                    color: textColorGray,
                  ),
                ),
                Text(
                  "${_output2}",
                  style: TextStyle(
                    color: textColorGray,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 18.0),
                  child: ElevatedButton(
                    onPressed: () {
                      wifiSearchPythonScript();
                      setState(() {
                        output = null;
                      });
                      // Call the method to scan again
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF02567E),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    child: const Text(
                      'Scan again',
                      style: TextStyle(
                        color: Color(0xFFFFFFFF),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
