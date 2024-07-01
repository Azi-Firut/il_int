import 'dart:convert';
import 'dart:io';
import '../models/device_manager.dart';
import 'device_fix_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:process_run/process_run.dart';
import '../constant.dart';
import 'package:process_run/shell.dart';
////////////////////////////////////////////////
class WiFiadd extends StatefulWidget {
  const WiFiadd({Key? key}) : super(key: key);

  @override
  WiFiaddState createState() => WiFiaddState();
}

class WiFiaddState extends State<WiFiadd> {
  var output;
  var _output2="";
  String brand = "";
  final DeviceManager _deviceManager = DeviceManager();

  void updateState() {
    setState(() {});
  }


  @override
  void initState() {
    super.initState();
    wifiSearchPythonScript();

  }

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

    if (output != null && output.isNotEmpty && output[0].stdout != null){
      _deviceManager.checkCalibrationFile(updateState);
      if(_deviceManager.outputCalibration=="Calibration file does not exist"){_deviceManager.restoreCalibration(updateState);
      setState(() {

      });
      }
    }



    setState(() {
      output = result;
    });
    //checkCalibrationFile();
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
                  "${_deviceManager.outputCalibration}",
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
