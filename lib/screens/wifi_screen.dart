import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../constant.dart';
import '../models/device_fix_class.dart';

////////////////////////////////////////////////
class WiFiadd extends StatefulWidget {
  const WiFiadd({Key? key}) : super(key: key);

  @override
  WiFiaddState createState() => WiFiaddState();
}

class WiFiaddState extends State<WiFiadd> {
  var output = null;
  var out = "";
  String brand = "";
  final DeviceFix _deviceFixFunctionKit = DeviceFix();

  void updateState() {
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    wifiSearchPythonScript();
  }

  String connectedSsid = '';
  Future<void> checkConnectedWifiWindows() async {
    try {
      // Execute 'netsh wlan show interfaces' to get the current WiFi connection details
      ProcessResult result =
          await Process.run('netsh', ['wlan', 'show', 'interfaces']);

      if (result.exitCode == 0) {
        // The command was successful, now process the output
        String output = result.stdout;

        // Look for the SSID line in the command output
        RegExp ssidRegExp = RegExp(r"SSID\s*: (.+)");
        Match? match = ssidRegExp.firstMatch(output);

        if (match != null) {
          String ssid = match.group(1)?.trim() ?? 'Unknown SSID';

          print('Currently connected to: $ssid');
          setState(() {
            connectedSsid = ssid;
          });
        } else {
          connectedSsid = 'No WiFi SSID found. Not connected to any WiFi.';
          print('No WiFi SSID found. Not connected to any WiFi.');
        }
      } else {
        print('Error executing command: ${result.stderr}');
      }
    } catch (e) {
      print('Error retrieving WiFi SSID: $e');
    }
  }

  Future<void> wifiSearchPythonScript() async {
    // Load JSON data from assets
    final String rawJsonData = await rootBundle.loadString('assets/ssids.json');

    // Convert the JSON to a single line string
    final jsonData = json.encode(json.decode(rawJsonData));
    print(jsonData);

    // Convert the JSON string to bytes
    final dataBytes = Uint8List.fromList(utf8.encode(jsonData));

    // Start the external process (your .exe)
    final process = await Process.start(
        'data/flutter_assets/assets/wifi_search/wifi_search.exe',
        [] // Arguments if needed
        );

    // Write to the process input
    process.stdin.add(dataBytes);
    await process.stdin.close(); // Close the input stream after writing

    // Collect the output from stdout
    String out = await process.stdout.transform(utf8.decoder).join();
    // Process and filter duplicates
    List<String> outputLines = out.split('\n');
    Set<String> uniqueLines = {}; // Use a set to store unique lines

    for (String line in outputLines) {
      line = line.trim(); // Trim spaces/newlines
      if (line.isNotEmpty && !uniqueLines.contains(line)) {
        uniqueLines.add(line); // Add to set if it's not a duplicate
      }
    }
    if (out.isNotEmpty) {
      checkConnectedWifiWindows();
      _deviceFixFunctionKit.checkCalibrationFile(updateState);
      if (_deviceFixFunctionKit.statusOutput ==
          "Calibration file does not exist") {
        _deviceFixFunctionKit.restoreCalibration(updateState);
        setState(() {});
      }
    }

    setState(() {
      output = uniqueLines.join('\n');
      print('Output: $output');
      print('Output length: ${output.length}');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (output == null)
          SelectableText(
            "Wait...",
            style: TextStyle(
              color: textColorGray,
            ),
          ),
        if (output != null && output.isNotEmpty && output != null)
          Padding(
            padding: const EdgeInsets.only(top: 18.0),
            child: Column(
              children: [
                SelectableText(
                  "${output}\n\nConnected to $connectedSsid",
                  style: TextStyle(
                    color: textColorGray,
                  ),
                ),
                const SizedBox(
                  height: 10,
                ),
                Text(
                  _deviceFixFunctionKit.statusOutput,
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
                      backgroundColor: const Color(0xFF02567E),
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
