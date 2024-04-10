import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:process_run/process_run.dart';

import '../constant.dart';

class WiFiadd extends StatefulWidget {
  const WiFiadd({Key? key}) : super(key: key);

  @override
  _WiFiaddState createState() => _WiFiaddState();
}

class _WiFiaddState extends State<WiFiadd> {
  var output;
  @override
  void initState() {
    super.initState();
    wifiSearchPythonScript();
  }

  Future<void> wifiSearchPythonScript() async {
// Создайте объект, содержащий карту паролей и SSID
//     Map<String, String> credentials = {
//       "WINGTRA": "WingtraLidar",
//       "RESEPI": "LidarAndINS",
//       "Pizdaki": "12345678",
//       // Другие пары SSID и паролей
//     };

    final String jsonData = await rootBundle
        .loadString('assets/ssids.json'); // Преобразуйте объект в JSON-строку
    //  final String jsonData = jsonEncode(jsonData2);

    // Преобразуйте объект в JSON-строку
    // String jsonData = jsonEncode(credentials);
    print(jsonData);

    ///
    final dataBytes =
        Uint8List.fromList(utf8.encode(jsonData)); // Конвертация строки в байты
    final stream =
        Stream.fromIterable([dataBytes]); // Создание потока из байтов
    final result = await run(
        'data/flutter_assets/assets/wifi_search/wifi_search.exe',
        stdin: stream); // Путь к вашему EXE скрипту Python Для финальной сборки

    // final result = await run(
    //   'python/wifi_search.py',
    //   stdin: stream, // Передача данных в stdin
    // );

    print(result[0].stderr);
    print(result[0].stdout);
    print(result[0].outText);

    setState(() {
      output = result;
    });
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
        ///////////
        // if (output[0].stdout == '')
        //   const Text(
        //     "No available networks found",
        //     style: TextStyle(
        //       color: Color(0xFF777777),
        //     ),
        //   ),
        /////////////
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
