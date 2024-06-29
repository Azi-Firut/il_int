import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:process_run/shell.dart';
import '../constant.dart';

class DeviceFixScreen extends StatefulWidget {
  const DeviceFixScreen({Key? key}) : super(key: key);
  @override
  DeviceFixScreenState createState() => DeviceFixScreenState();
}

class DeviceFixScreenState extends State<DeviceFixScreen> {
  final _brands = [
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
  String? _selectedBrand;
  String _outputCalibration = "";
  String _outputBrand = "";
  String _imuOutput = "";
  String _keyPath = '';
  String brand = "";
  String _calibrationPath = '';
  String _decodedString = "";

  // Переменные для путей к plink и pscp
  final String _plinkPath = 'data/flutter_assets/assets/plink.exe';
  final String _pscpPath = 'data/flutter_assets/assets/pscp.exe';

  @override
  void initState() {
    super.initState();
    loadCalibrationFile();
    checkCalibrationFile();
    _decodedString = decodeStringWithRandom(key);
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

  Future<void> loadCalibrationFile() async {
    final appDir = Directory.current;
    final tempDir = Directory('${appDir.path}/assets');
    if (!await tempDir.exists()) {
      await tempDir.create(recursive: true);
    }
    final calibrationFile = File('${tempDir.path}/calibration');
    final calibrationData = await rootBundle.load('assets/calibration');
    await calibrationFile.writeAsBytes(calibrationData.buffer.asUint8List());
    setState(() {
      _calibrationPath = calibrationFile.path;
    });
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

  // Future<void> _sendCommand() async {
  //   var shell = Shell();
  //   var hostKey =
  //       "ssh-ed25519 255 SHA256:0z+smqD1LNdbBqOoIjFhJWhoxuJFiDtctVLxyssNFYc";
  //
  //   try {
  //     // Establish SSH connection with pre-confirmed host key
  //     var result = await shell
  //         .run('$_plinkPath -ssh root@192.168.12.1 -hostkey "$hostKey"');
  //
  //     // Run the actual command
  //     result = await shell.run('$_plinkPath -ssh root@192.168.12.1');
  //
  //     // Check if there is any output and handle it
  //     if (result.outText.isNotEmpty) {
  //       print('Command output: ${result.outText}');
  //     }
  //
  //     setState(() {
  //       _output = result.outText;
  //     });
  //   } catch (e) {
  //     setState(() {
  //       _output = 'Error: $e';
  //     });
  //   }
  // }

  void _changeBrand() async {
    if (_selectedBrand != null) {
      if (await _createTempKeyFile()) {
        _outputBrand = "Procedure started............";
        final shell = Shell();
        try {
          final result = await shell.run('''
       $_plinkPath -i "$_keyPath" -P 22 root@192.168.12.1 -hostkey "$hostKey" "mount -o remount,rw / && echo '${_selectedBrand!.toUpperCase()}' > /etc/brand && exit"
        ''');

          String combinedOutput =
              result.map((e) => e.stdout + e.stderr).join('\n');

          setState(() {
            _outputBrand =
                "Brand changed successfully to $_selectedBrand\nNow you need to update the firmware on your device to the latest version";
          });
        } catch (e) {
          String errorMessage = e.toString();

          String shellContext = shell.context.toString();

          String combinedErrorOutput =
              "Error: $errorMessage\n \nShell output: $shellContext";

          setState(() {
            _outputBrand =
                "Failed to change brand: check all conditions before start";
            // _output2 = combinedErrorOutput;
          });
        } finally {
          await _deleteTempKeyFile();
        }
      } else {
        setState(() {
          _outputBrand = "Procedure failed";
        });
      }
    } else {
      setState(() {
        _outputBrand =
            "Please select a brand and ensure the device is connected.";
      });
    }
  }

  void _deleteCalibration() async {
    if (await _createTempKeyFile()) {
      final shell = Shell();
      _outputCalibration = "Procedure started............";
      String output = "";
      try {
        await shell.run('''
        ${_plinkPath} -i "$_keyPath" -P 22 root@192.168.12.1 -hostkey "$hostKey" "cd /etc/payload && mount -o remount,rw / && rm -rf calibration && mount -o remount,ro / && exit"
        ''');
        output = "Calibration file successfully deleted.";
      } catch (e) {
        output = "Failed to delete calibration: $e";
      } finally {
        await _deleteTempKeyFile();
      }
      setState(() {
        _outputCalibration = output;
      });
    } else {
      setState(() {
        _outputCalibration = "Procedure failed";
      });
    }
  }

  void checkCalibrationFile() async {
    if (await _createTempKeyFile()) {
      final shell = Shell();
      _outputCalibration = "... Looking for the device calibration file ...";
      String output = "";
      try {
        var result = await shell.run('''
${_plinkPath} -ssh -i "$_keyPath" root@192.168.12.1 -hostkey "$hostKey" "test -e /etc/payload/calibration && echo 'Calibration file exists' || (echo 'Calibration file does not exist';)"
''');

        /// Оставить (выводит лист файлов с юнита).
//         var result = await shell.run('''
// ${_plinkPath} -ssh -i "$_keyPath" root@192.168.12.1 hostkey "$hostKey" "test -e /etc/payload/calibration && echo 'Calibration file exists' || (echo 'Calibration file does not exist'; ls -l /etc/payload/)"
// ''');
        output = "${result.outText}";
      } catch (e) {
        output = "! Failed to retrieve data from device !";
      } finally {
        await _deleteTempKeyFile();
      }
      setState(() {
        _outputCalibration = output;
      });
    } else {
      setState(() {
        _outputCalibration = "Procedure failed";
      });
    }
  }

  void restoreCalibration() async {
    if (await _createTempKeyFile()) {
      final shell = Shell();
      _outputCalibration = "Procedure started............";
      String output = "";
      try {
        var _brandNow = await shell.run('''
          ${_plinkPath} -i "$_keyPath" -P 22 root@192.168.12.1 -hostkey "$hostKey" "cat /etc/brand"
          ''');
        await shell.run('''
          ${_plinkPath} -i "$_keyPath" -P 22 root@192.168.12.1 -hostkey "$hostKey" "mount -o remount,rw / && echo '${_brandNow.outText}' > /etc/brand && exit"
          ''');
        const calibrationAssetPath = 'assets/calibration';
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
        _outputCalibration = output;
      });
    } else {
      setState(() {
        _outputCalibration = "Procedure failed";
      });
    }
  }

  // String _decodeBinary(String binary) {
  //   return utf8.decode(binary.codeUnits);
  // }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ElevatedButton(
        //   onPressed: _sendCommand,
        //   child: Text('Send Command'),
        // ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Flexible(
                fit: FlexFit.loose,
                child: Text(
                  "Turn on the device and connect to it using Wi-Fi. Make sure the connection is established.",
                  style: TextStyle(
                    color: textColorGray,
                  ),
                ),
              ),
            ],
          ),
        ),

        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Flexible(
                fit: FlexFit.loose,
                child: Text(
                  "To change the device brand, select the brand from the list and click Change Brand.",
                  style: TextStyle(
                    color: textColorGray,
                  ),
                ),
              ),
            ],
          ),
        ),
        Container(
          width: 155,
          height: 40,
          padding: EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
          decoration: BoxDecoration(
            color: Colors.orange,
            borderRadius: BorderRadius.circular(3.0),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                spreadRadius: 1,
                blurRadius: 5,
                offset: Offset(0, 3), // changes position of shadow
              ),
            ],
          ),
          child: DropdownButton<String?>(
            dropdownColor: Colors.orange,
            value: _selectedBrand,
            hint: Text(
              'Select Brand',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14.0,
              ),
            ),
            icon: Icon(Icons.arrow_drop_down, color: Colors.white),
            iconSize: 24,
            isExpanded: true,
            underline: SizedBox(),
            onChanged: (String? newValue) {
              setState(() {
                _selectedBrand = newValue;
              });
            },
            items: _brands.map<DropdownMenuItem<String?>>((String value) {
              return DropdownMenuItem<String?>(
                value: value,
                child: Text(
                  value,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14.0,
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 18.0),
          child: ElevatedButton(
            onPressed: _changeBrand,
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF02567E),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            child: const Text(
              'Change Brand',
              style: TextStyle(
                color: Color(0xFFFFFFFF),
              ),
            ),
          ),
        ),
        Padding(
          padding:
              const EdgeInsets.only(left: 8.0, right: 8, bottom: 16, top: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                fit: FlexFit.loose,
                child: Text(
                  _outputBrand,
                  style: TextStyle(
                    color: textColorGray,
                  ),
                ),
              ),
            ],
          ),
        ),
        ///////////////////////////////////////////////////////////////////////
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Flexible(
                fit: FlexFit.loose,
                child: Text(
                  "To delete or restore the calibration file on the device, use the buttons below.",
                  style: TextStyle(
                    color: textColorGray,
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: ElevatedButton(
            onPressed: _deleteCalibration,
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF02567E),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            child: const Text(
              'Delete Calibration',
              style: TextStyle(
                color: Color(0xFFFFFFFF),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 18.0),
          child: ElevatedButton(
            onPressed: restoreCalibration,
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF02567E),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            child: const Text(
              'Restore Calibration',
              style: TextStyle(
                color: Color(0xFFFFFFFF),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            _outputCalibration,
            style: TextStyle(
              color: textColorGray,
            ),
          ),
        ),
        // Padding(
        //   padding: const EdgeInsets.all(8.0),
        //   child: Text(
        //     _output2,
        //     style: TextStyle(
        //       color: textColorGray,
        //     ),
        //   ),
        // ),
      ],
    );
  }
}

//
// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart' show rootBundle;
// import 'package:process_run/shell.dart';
// import 'dart:io';
//
// import '../constant.dart';
//
// class DeviceFixScreen extends StatefulWidget {
//   const DeviceFixScreen({Key? key}) : super(key: key);
//   @override
//   _DeviceFixScreenState createState() => _DeviceFixScreenState();
// }
//
// class _DeviceFixScreenState extends State<DeviceFixScreen> {
//   final _brands = [
//     "ROCK",
//     "SNOOPY",
//     "ML",
//     "MARSS",
//     "TRIDAR",
//     "RECON",
//     "TERSUS",
//     "RESEPI",
//     "FLIGHTS",
//     "WINGTRA",
//     "STONEX"
//   ];
//   String? _selectedBrand;
//   String _output = "";
//   String _imuOutput = "";
//   String _keyPath = '';
//   String brand = "";
//   String _calibrationPath = '';
//   String _decodedString = "";
//   final String _key =
//       "UHLVUUVFOktIVXBNlVciJ1LKZXTktGRmClsDZSE0yFOiIBlJY2ORzYYSP1zHaGJEyBLWR5pAc3CRwBMjDU2KCkDVuVY3IJ5OcHARpHb2I46IIGS5vCbmDUKIQ2V9tWbWBVuTdDTogVaWR1wUb3CJ0QZWNQtKb3XBlSbnLNzNaCP1rMZXBkKZUHBViIbGHljULUSxpMbmSVzXOiZAzWCkLFBVQULFFVMlUZqYWkMhODaESxYITmW9ZGVEPl0DYmG1sTemBRIHQXQlOPVFNlBVQUGFBJSWKJtUbHFpkKSEJF5OTlDRZHQUUFBZQkZJCSQkRt5IOUI1GYc0TlSBWUI8KORGCI5JUlUBtOM2CF3CZEUpnBNHCdkFYVTVXPa0Fx4XSjLl0OWHXBDDRFSJEYWVTdsOZ3Dp6PeECtpOY1CFsQeCRt0NaEKxRMa0Z9jEUUWM5SaFPI2LNkN50PcXOUwJTQKo3LZjSBtYNTABHVU2SdTYQTK0KVUHMJpBdmCF0ZZSR1MTaWN5lKczXogJMQBpBXQUHFBTSVXFDLOUQhwYUjYNCXajGZLMZEWpzMWkX0yYZEGtGDRTNV3MRmXg1FK2TcwCRTXdYZZ1YJOXcVQU0KWlMY4FaTJl5DUTM09QClNByCaXTZhVdGHUtBTUEFDQOiSBmMYTSQ1YMzWQ3KOGVUwQMTOA1EZjJI1DYWOFkNMmWRlOMzGM1EY2KYxPZjMZmIYmVM5UMDLEwEMDCJmA";
//   @override
//   void initState() {
//     super.initState();
//     _loadCalibrationFile();
//     _decodedString = decodeStringWithRandom(_key);
//   }
//
//   String decodeStringWithRandom(String input) {
//     StringBuffer cleaned = StringBuffer();
//     for (int i = 0; i < input.length; i++) {
//       if (i % 3 != 2) {
//         cleaned.write(input[i]);
//       }
//     }
//     List<int> bytes = base64Decode(cleaned.toString());
//     String decodedString = utf8.decode(bytes);
//     return decodedString;
//   }
//
//   Future<void> _loadCalibrationFile() async {
//     // Путь к корневой директории приложения
//     final appDir = Directory.current;
//     // Путь для хранения файла калибровки в корне приложения
//     final tempDir = Directory('${appDir.path}/assets');
//     if (!await tempDir.exists()) {
//       await tempDir.create(recursive: true);
//     }
//     // Путь к файлу калибровки в корневой директории
//     final calibrationFile = File('${tempDir.path}/calibration');
//     // Загружаем файл калибровки из assets и записываем его в корневую папку
//     final calibrationData = await rootBundle.load('assets/calibration');
//     await calibrationFile.writeAsBytes(calibrationData.buffer.asUint8List());
//     setState(() {
//       _calibrationPath =
//           calibrationFile.path; // Устанавливаем путь к файлу калибровки
//     });
//   }
//
//   Future<bool> _createTempKeyFile() async {
//     // Путь к корневой директории приложения
//     final appDir = Directory.current;
//     // Путь для хранения ключа в корне приложения
//     final tempDir = Directory('${appDir.path}/temp');
//     if (!await tempDir.exists()) {
//       await tempDir.create(recursive: true);
//     }
//     // Путь к файлу ключа в корневой директории
//     final keyFile = File('${tempDir.path}/resepi_login.ppk');
//     // Записываем ключ в корневую папку
//     await keyFile.writeAsString(_decodedString);
//     setState(() {
//       _keyPath = keyFile.path; // Устанавливаем путь к ключу
//     });
//     return await keyFile.exists();
//   }
//
//   Future<void> _deleteTempKeyFile() async {
//     final keyFile = File(_keyPath);
//     if (await keyFile.exists()) {
//       try {
//         await keyFile.delete();
//         print("Temp key file deleted successfully.");
//       } catch (e) {
//         print("Failed to delete temp key file: $e");
//         await Future.delayed(Duration(seconds: 1));
//         // Retry deleting the key file
//         try {
//           await keyFile.delete();
//           print("Retry: Temp key file deleted successfully.");
//         } catch (retryException) {
//           print("Retry failed to delete temp key file: $retryException");
//         }
//       }
//     }
//   }
//
//   void _changeBrand() async {
//     if (_selectedBrand != null) {
//       if (await _createTempKeyFile()) {
//         final shell = Shell();
//         try {
//           await shell.run('''
//           plink.exe -i "$_keyPath" root@192.168.12.1 "mount -o remount,rw / && echo '${_selectedBrand!.toUpperCase()}' > /etc/brand && exit"
//           ''');
//           setState(() {
//             _output = "Brand changed successfully to $_selectedBrand";
//           });
//         } catch (e) {
//           setState(() {
//             _output = "Failed to change brand: $e";
//           });
//         } finally {
//           await _deleteTempKeyFile();
//         }
//       } else {
//         setState(() {
//           _output = "Failed to create key file.";
//         });
//       }
//     } else {
//       setState(() {
//         _output = "Please select a brand and ensure the key file is loaded.";
//       });
//     }
//   }
//
//   void _deleteCalibration() async {
//     if (await _createTempKeyFile()) {
//       final shell = Shell();
//       String output = "";
//       try {
//         await shell.run('''
//         plink.exe -i "$_keyPath" root@192.168.12.1 "cd /etc/payload && mount -o remount,rw / && rm -rf calibration && mount -o remount,ro / && exit"
//         ''');
//         output = "Calibration file successfully deleted.";
//       } catch (e) {
//         output = "Failed to delete calibration: $e";
//       } finally {
//         await _deleteTempKeyFile();
//       }
//       setState(() {
//         _output = output;
//       });
//     } else {
//       setState(() {
//         _output = "Failed to create key file.";
//       });
//     }
//   }
//
//   void _restoreCalibration() async {
//     if (await _createTempKeyFile()) {
//       final shell = Shell();
//       String output = "";
//       try {
//         var _brandNow = await shell.run('''
//           plink.exe -i "$_keyPath" root@192.168.12.1 "cat /etc/brand"
//           ''');
//         await shell.run('''
//           plink.exe -i "$_keyPath" root@192.168.12.1 "mount -o remount,rw / && echo '${_brandNow.outText}' > /etc/brand && exit"
//           ''');
//         // Путь к файлу calibration в папке assets вашего проекта
//         final calibrationAssetPath = 'assets/calibration';
//         // Копирование файла calibration на удаленное устройство
//         await shell.run('''
//         pscp -i "$_keyPath" -P 22 "$calibrationAssetPath" root@192.168.12.1:/etc/payload/calibration
//         ''');
//         output = "Calibration file copied successfully.";
//       } catch (e) {
//         output = "Failed to copy calibration file: $e";
//       } finally {
//         await _deleteTempKeyFile();
//       }
//       setState(() {
//         _imuOutput = brand;
//         _output = output;
//       });
//     } else {
//       setState(() {
//         _output = "Failed to create key file.";
//       });
//     }
//   }
//
//   String _decodeBinary(String binary) {
//     return utf8.decode(binary.codeUnits);
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       children: [
//         Padding(
//           padding: const EdgeInsets.all(8.0),
//           child: Row(
//             children: [
//               Flexible(
//                 fit: FlexFit.loose,
//                 child: Text(
//                   "For this part of the application to work correctly, additional installed programs are required (plink and pscp).",
//                   style: TextStyle(
//                     color: textColorGray,
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//         Padding(
//           padding: const EdgeInsets.all(8.0),
//           child: Row(
//             children: [
//               Flexible(
//                 fit: FlexFit.loose,
//                 child: Text(
//                   "Turn on the device and connect to it using Wi-Fi. Make sure the connection is established.",
//                   style: TextStyle(
//                     color: textColorGray,
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//         Padding(
//           padding: const EdgeInsets.all(8.0),
//           child: Row(
//             children: [
//               Flexible(
//                 fit: FlexFit.loose,
//                 child: Text(
//                   "To change the device brand, select the brand from the list and click Change Brand.",
//                   style: TextStyle(
//                     color: textColorGray,
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//         Container(
//           width: 155,
//           height: 40,
//           padding: EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
//           decoration: BoxDecoration(
//             color: Colors.orange,
//             borderRadius: BorderRadius.circular(3.0),
//             boxShadow: [
//               BoxShadow(
//                 color: Colors.black.withOpacity(0.5),
//                 spreadRadius: 1,
//                 blurRadius: 5,
//                 offset: Offset(0, 3), // changes position of shadow
//               ),
//             ],
//           ),
//           child: DropdownButton<String?>(
//             dropdownColor: Colors.orange,
//             value: _selectedBrand,
//             hint: Text(
//               'Select Brand',
//               style: TextStyle(
//                 color: Colors.white,
//                 fontSize: 14.0,
//               ),
//             ),
//             icon: Icon(Icons.arrow_drop_down, color: Colors.white),
//             iconSize: 24,
//             isExpanded: true,
//             underline: SizedBox(),
//             onChanged: (String? newValue) {
//               setState(() {
//                 _selectedBrand = newValue;
//               });
//             },
//             items: _brands.map<DropdownMenuItem<String?>>((String value) {
//               return DropdownMenuItem<String?>(
//                 value: value,
//                 child: Text(
//                   value,
//                   style: TextStyle(
//                     color: Colors.white,
//                     fontSize: 14.0,
//                   ),
//                 ),
//               );
//             }).toList(),
//           ),
//         ),
//
//         ///
//         Padding(
//           padding: const EdgeInsets.only(top: 18.0),
//           child: ElevatedButton(
//             onPressed: _changeBrand,
//             style: ElevatedButton.styleFrom(
//               backgroundColor: Color(0xFF02567E),
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(3),
//               ),
//             ),
//             child: const Text(
//               'Change Brand',
//               style: TextStyle(
//                 color: Color(0xFFFFFFFF),
//               ),
//             ),
//           ),
//         ),
//
//         ///
//         Padding(
//           padding: const EdgeInsets.all(8.0),
//           child: Row(
//             children: [
//               Flexible(
//                 fit: FlexFit.loose,
//                 child: Text(
//                   "To delete or restore the calibration file on the device, use the buttons below.",
//                   style: TextStyle(
//                     color: textColorGray,
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//
//         ///
//         Padding(
//           padding: const EdgeInsets.only(top: 18.0),
//           child: ElevatedButton(
//             onPressed: _deleteCalibration,
//             style: ElevatedButton.styleFrom(
//               backgroundColor: Color(0xFF02567E),
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(3),
//               ),
//             ),
//             child: const Text(
//               'Delete Calibration',
//               style: TextStyle(
//                 color: Color(0xFFFFFFFF),
//               ),
//             ),
//           ),
//         ),
//
//         ///
//         Padding(
//           padding: const EdgeInsets.only(top: 18.0),
//           child: ElevatedButton(
//             onPressed: _restoreCalibration,
//             style: ElevatedButton.styleFrom(
//               backgroundColor: Color(0xFF02567E),
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(3),
//               ),
//             ),
//             child: const Text(
//               'Restore Calibration',
//               style: TextStyle(
//                 color: Color(0xFFFFFFFF),
//               ),
//             ),
//           ),
//         ),
//
//         ///
//         Padding(
//           padding: const EdgeInsets.all(8.0),
//           child: Text(
//             _output,
//             style: TextStyle(
//               color: textColorGray,
//             ),
//           ),
//         ),
//
//         // Скрываемый текст
//         // Padding(
//         //   padding: const EdgeInsets.all(8.0),
//         //   child: Text(
//         //     _keyPath, //_output,//_imuOutput,//_keyPath
//         //     style: TextStyle(
//         //       color: textColorGray,
//         //     ),
//         //   ),
//         // ),
//       ],
//     );
//   }
// }
