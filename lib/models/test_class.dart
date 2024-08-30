

import 'dart:convert';
import 'dart:io';
import 'dart:io';
import 'package:process_run/shell.dart';
import '../constant.dart';

class TestClass {
  static final TestClass _instance = TestClass._internal();

  factory TestClass() {
    return _instance;
  }

  TestClass._internal();

  String keyPath = '';
  String calibrationPath = '';
  String decodedString = "";
   String unitResponse='';
 //late var out;
  var wrapShellRun;

  //var resultShell1;


  // Переменные для путей к plink и pscp
  final String _plinkPath = 'data/flutter_assets/assets/plink.exe';

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


  String macTo32BitHex(String mac) {
    // Удаляем все незначащие символы (например, дефисы и двоеточия)
    mac = mac.replaceAll(RegExp(r'[^0-9A-Fa-f]'), '');

    // Проверяем, что длина строки корректная для 6 байтов
    if (mac.length != 6) {
      throw ArgumentError('MAC-адрес должен состоять из 6 байтов в формате 12 символов шестнадцатеричного кода.');
    }

    // Преобразуем строку в целое число
    int value = int.parse(mac, radix: 16);

    // Добавляем старший байт (например, 0x7A)
    int result = (0x7A << 24) | value;

    // Преобразуем значение в строку в шестнадцатеричном формате
    String hexString = '0x${result.toRadixString(16).toUpperCase()}';

    return hexString;
  }



  Future<void> getI(Function updateState) async {
    if (await _createTempKeyFile()) {
      // var out;
      // var out2;
      final shellWindow1 = Shell();
      final shellWindow2 = Shell();
      final shellWindow3 = Shell();
      final shellW = Shell().options.stdout;
      try {
        Future.delayed(Duration(seconds: 0), () async {
          shellWindow1.run('''${_plinkPath} -i "$keyPath" -P 22 root@192.168.12.1 -hostkey "$hostKey" "systemctl stop payload"''');

              var out= await shellWindow3.run(
                '''${_plinkPath} -i "$keyPath" -P 22 root@192.168.12.1 -hostkey "$hostKey" "hexdump -C /dev/ttymxc3"''');
              // out2= await shellWindow2.run(
              //    '''${_plinkPath} -i "$keyPath" -P 22 root@192.168.12.1 -hostkey "$hostKey" "cat /dev/ttymxc3"''');

              print("${_processUnitResponse(out.outText)}");
             // print("${out2}");
              unitResponse=_processUnitResponse(out.outText);
             // updateState();

        });

        Future.delayed(Duration(seconds: 3), () async {
          await shellWindow2.run('''${_plinkPath} -i "$keyPath" root@192.168.12.1 -hostkey "$hostKey" "echo -en '\\xaa\\x55\\x00\\x00\\x09\\x00\\xff\\x57\\x09\\x68\\x01' >/dev/ttymxc3"''');
        });
        Future.delayed(Duration(seconds: 4), () async {
          await shellWindow2.run('''${_plinkPath} -i "$keyPath" -P 22 root@192.168.12.1 -hostkey "$hostKey" "stty -F /dev/ttymxc3 921600"''');
        });
        Future.delayed(Duration(seconds: 5), () async {
          await shellWindow2.run('''${_plinkPath} -i "$keyPath" -P 22 root@192.168.12.1 -hostkey "$hostKey" "echo -en '\\xA5\\xA5\\x02\\x04\\x0A\\x02\\x01\\x00\\x5D\\xFB' >/dev/ttymxc3"''');
          await shellWindow2.run('''${_plinkPath} -i "$keyPath" -P 22 root@192.168.12.1 -hostkey "$hostKey" "echo -en '\\xA5\\xA5\\x01\\x02\\x06\\x00\\x53\\x2D' >/dev/ttymxc3"''');
          await shellWindow2.run('''${_plinkPath} -i "$keyPath" -P 22 root@192.168.12.1 -hostkey "$hostKey" "echo -en '\\xA5\\xA5\\x01\\x02\\x06\\x00\\x53\\x2D' >/dev/ttymxc3"''');
          // unitResponse=_processUnitResponse(out.outText);

          // print("${out[0].outText}");
         // print("${out}");
          print("${shellW}");
          // updateState();
        });

      } catch (e) {
      } finally {

      }
    } else {
      unitResponse = "Procedure failed";
    }
    updateState();
  }



String _processUnitResponse(String response) {
  // Remove ".|" from the response
  response = response.replaceAll('.|', '');

  // Split response into lines and get the last 10 lines
  List<String> lines = response.split('\n');
  int start = lines.length > 3 ? lines.length - 3 : 0;
  return lines.sublist(start).join('\n');
}
///
//
//    fun1() async {
//     var resultShell = await shell1.run('''
//             ${_plinkPath} -i "$keyPath" -P 22 root@192.168.12.1 -hostkey "$hostKey" "systemctl stop payload"
//           ''');
//     out2=resultShell;
//   print("======================= 1 => END");
//   }
//
//   fun2(Function updateState) async {
//       print("======================= 2");
//       var resultShell1 =await shell2.run('''
//               ${_plinkPath} -i "$keyPath" -P 22 root@192.168.12.1 -hostkey "$hostKey" "hexdump -C /dev/ttymxc3"
//             ''');
//        print(_processUnitResponse(resultShell1.outText));
//       out=resultShell1;
//       unitResponse = _processUnitResponse(resultShell1.outText);
//       updateState();
//     }
//
//   void fun3() {
//     Future.delayed(Duration(seconds: 4), () async {
//       await shell3.run('''
//             ${_plinkPath} -i "$keyPath" root@192.168.12.1 -hostkey "$hostKey" "echo -en '\\xaa\\x55\\x00\\x00\\x09\\x00\\xff\\x57\\x09\\x68\\x01' >/dev/ttymxc3"
//           ''');
//       print("======================= 3 => END");
//     });}
//
//   void fun4() {
//     Future.delayed(Duration(seconds: 7), () async {
//       await shell3.run('''
//             ${_plinkPath} -i "$keyPath" -P 22 root@192.168.12.1 -hostkey "$hostKey" "stty -F /dev/ttymxc3 921600"
//           ''');
//       print("======================= 4 => END");
//     });}
//
//   void fun5() {
//     Future.delayed(Duration(seconds: 10), () async {
//       await shell3.run('''
//             ${_plinkPath} -i "$keyPath" -P 22 root@192.168.12.1 -hostkey "$hostKey" "echo -en '\\xA5\\xA5\\x02\\x04\\x0A\\x02\\x01\\x00\\x5D\\xFB' >/dev/ttymxc3"
//           ''');
//       print("======================= 5 => END");
//     });}
//
//   void fun6() {
//     Future.delayed(Duration(seconds: 13), () async {
//       await shell3.run('''
//             ${_plinkPath} -i "$keyPath" root@192.168.12.1 -hostkey "$hostKey" "echo -en '\\xA5\\xA5\\x01\\x02\\x06\\x00\\x53\\x2D' >/dev/ttymxc3"
//           ''');
//       print("======================= 6 => END");
//     });}
//
//   void fun7(updateState) {
//     Future.delayed(Duration(seconds: 14), () async {
//       await shell3.run('''
//             ${_plinkPath} -i "$keyPath" root@192.168.12.1 -hostkey "$hostKey" "echo -en '\\xA5\\xA5\\x01\\x02\\x06\\x00\\x53\\x2D' >/dev/ttymxc3"
//           ''');
//       print("======================= 7 => END");
//     });}
//
//   Future<void> fun8(updateState) async {
//     Future.delayed(Duration(seconds: 15), () async {
//       var result = await shell3.run('''
//             ${_plinkPath} -i "$keyPath" root@192.168.12.1 -hostkey "$hostKey" "echo -en '\\xA5\\xA5\\x01\\x02\\x06\\x00\\x53\\x2D' >/dev/ttymxc3"
//           ''');
//       out=result;
//       //out2=_processUnitResponse(resultShell1.asStream().toString());
//       print("======================= 8 => END");
//     });}
//
//   void fun9(updateState) {
//     Future.delayed(Duration(seconds: 16), () async {
//       print("======================= 9");
//
//       print("-------------out--------------");
//
//
//       print(out.toString());
//       print(out.outText);
//       print(out.length);
//       print(shell2);
//       // print(out);
//       print(out[0].stdout);
//       print("-------------out2--------------");
//       print(out2.toString());
//       print(out2.length);
//       print(out2.outText);
//       print(out2[0].stdout);
//
//       print(unitResponse);
//
//      shell1.kill();
//      shell2.kill();
//      shell3.kill();
//       updateState();
//       _deleteTempKeyFile();
//       print("======================= 9 => END");
//     });}
//
//   Future<void> funRunImuParse(Function updateState) async {
//     _createTempKeyFile();
//     allrun(updateState);
//    }
//
//   void allrun(updateState) {
//     Future.delayed(Duration(seconds: 2), () async{
//       fun1();
//     fun2(updateState);
//     fun3();
//     fun4();
//     fun5();
//     fun6();
//     fun7(updateState);
//     fun8(updateState);
//     fun9(updateState);
//     print("======================= START");
//     });   }
//
//   String _processUnitResponse(String response) {
//     // Remove ".|" from the response
//     response = response.replaceAll('.|', '');
//
//     // Split response into lines and get the last 10 lines
//     List<String> lines = response.split('\n');
//     int start = lines.length > 10 ? lines.length - 10 : 0;
//     return lines.sublist(start).join('\n');
//   }


  // /// IMU ///
  // Future<void> runIMUCommands2(Function updateState) async {
  //   if (await _createTempKeyFile()) {
  //     try {
  //       Future.delayed(Duration(seconds: 0), () async {
  //           shell1.run('''
  //           ${_plinkPath} -i "$keyPath" -P 22 root@192.168.12.1 -hostkey "$hostKey" "systemctl stop payload"
  //         ''');
  //           print("======================= 1 => END");
  //       });
  //       Future.delayed(Duration(seconds: 1), () async {
  //         print("======================= 2");
  //          var resultShell1 = await shell1.run('''
  //             ${_plinkPath} -i "$keyPath" -P 22 root@192.168.12.1 -hostkey "$hostKey" "hexdump -C /dev/ttymxc3"
  //           ''');
  //         print(resultShell1.outText);
  //         print('${resultShell1[0].stdout}');
  //          out=resultShell1[0].outText;
  //          out2=resultShell1[0].stdout;
  //          unitResponse = _processUnitResponse(resultShell1.outText);
  //         updateState();
  //       });
  //
  //       Future.delayed(Duration(seconds: 4), () async {
  //         await shell3.run('''
  //           ${_plinkPath} -i "$keyPath" root@192.168.12.1 -hostkey "$hostKey" "echo -en '\\xaa\\x55\\x00\\x00\\x09\\x00\\xff\\x57\\x09\\x68\\x01' >/dev/ttymxc3"
  //         ''');
  //         print("======================= 3 => END");
  //       });
  //
  //       Future.delayed(Duration(seconds: 7), () async {
  //         await shell3.run('''
  //           ${_plinkPath} -i "$keyPath" -P 22 root@192.168.12.1 -hostkey "$hostKey" "stty -F /dev/ttymxc3 921600"
  //         ''');
  //         print("======================= 4 => END");
  //       });
  //
  //       Future.delayed(Duration(seconds: 10), () async {
  //         await shell3.run('''
  //           ${_plinkPath} -i "$keyPath" -P 22 root@192.168.12.1 -hostkey "$hostKey" "echo -en '\\xA5\\xA5\\x02\\x04\\x0A\\x02\\x01\\x00\\x5D\\xFB' >/dev/ttymxc3"
  //         ''');
  //         print("======================= 5 => END");
  //       });
  //
  //       Future.delayed(Duration(seconds: 13), () async {
  //         await shell3.run('''
  //           ${_plinkPath} -i "$keyPath" root@192.168.12.1 -hostkey "$hostKey" "echo -en '\\xA5\\xA5\\x01\\x02\\x06\\x00\\x53\\x2D' >/dev/ttymxc3"
  //         ''');
  //         await shell3.run('''
  //           ${_plinkPath} -i "$keyPath" root@192.168.12.1 -hostkey "$hostKey" "echo -en '\\xA5\\xA5\\x01\\x02\\x06\\x00\\x53\\x2D' >/dev/ttymxc3"
  //         ''');
  //         print("======================= 6 => END");
  //       });
  //
  //       Future.delayed(Duration(seconds: 14), () async {
  //         await shell3.run('''
  //           ${_plinkPath} -i "$keyPath" root@192.168.12.1 -hostkey "$hostKey" "echo -en '\\xA5\\xA5\\x01\\x02\\x06\\x00\\x53\\x2D' >/dev/ttymxc3"
  //         ''');
  //         await shell3.run('''
  //           ${_plinkPath} -i "$keyPath" root@192.168.12.1 -hostkey "$hostKey" "echo -en '\\xA5\\xA5\\x01\\x02\\x06\\x00\\x53\\x2D' >/dev/ttymxc3"
  //         ''');
  //         print("======================= 6 => END");
  //       });
  //
  //       Future.delayed(Duration(seconds: 15), () async {
  //         print("======================= 8 => ${unitResponse.runtimeType} END");
  //         print("======================= 8 => $unitResponse END");
  //         print("======================= 8 => ${out.runtimeType} $out END");
  //         print("======================= 8 => ${out2.runtimeType} $out2 END");
  //
  //         updateState();
  //         await _deleteTempKeyFile();
  //       });
  //     } catch (e) {
  //       print("Error: $e");
  //     }
  //   } else {
  //     updateState(); // Call updateState here
  //   }
  // }
  //
  // String _processUnitResponse(String response) {
  //   // Remove ".|" from the response
  //   response = response.replaceAll('.|', '');
  //
  //   // Split response into lines and get the last 10 lines
  //   List<String> lines = response.split('\n');
  //   int start = lines.length > 100 ? lines.length - 100 : 0;
  //   return lines.sublist(start).join('\n');
  // }
}
