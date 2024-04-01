import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:process_run/process_run.dart';

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
    // final result = await run(
    //     'data/flutter_assets/assets/wifi_search/wifi_search.exe'); // Путь к вашему EXE скрипту Python Для финальной сборки

    final result =
        await run('python/wifi_search.py'); // Путь к вашему  скрипту Python

    print(result.toString());
    print(result.errText);
    print(result.first.toString());
    print(result.runtimeType);
    print(result[0]);
    print(result[0].toString());
    print(result[0].runtimeType);
    print(result[0].stderr);
    print(result[0].stdout);
    // print(result[0].stdout);

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
          const Text(
            "Wait...",
            style: TextStyle(
              color: Color(0xFF777777),
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
                  style: const TextStyle(
                    color: Color(0xFF777777),
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
