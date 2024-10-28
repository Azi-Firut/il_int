import 'dart:convert';
import 'dart:io';
import 'package:il_int/models/ssh.dart';
import 'package:il_int/widgets/answer_from_unit.dart';
import 'package:path/path.dart' as p;
import 'package:process_run/shell.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../constant.dart';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';

import 'data.dart';

class TestClass {
  static final TestClass _instance = TestClass._internal();

  factory TestClass() {
    return _instance;
  }

  TestClass._internal();

  var process;
  var process2;
  var process3;
  var process4;
  var imuNumber='';
  var imuFilter='';
  var tempData='';
  var counter= 5;
  // Map output = {"IMU SN":"","Brand":"","Password":"","SSID default":"","SSID now":"","Receiver":"","Reciever SN":"","Firmware":"","Lidar: ":"","IMU Filter":""};
  //--
  var lidarSerialNumber='';
  var lidarModel='';
  var urlToLidar ='http://192.168.12.1:8001/pandar.cgi?action=get&object=device_info';

  /// GET LIDAR SN
  // Функция для отправки запроса
  Future<void> getLidarSn(updateState) async {
    lidarSerialNumber='';
    lidarModel='';
    final url = Uri.parse(urlToLidar);
    var stringFromLidar;
    try {
      final response = await http.get(url);
      stringFromLidar = response.statusCode == 200
          ? response.body
          : 'Error: ${response.statusCode}';
      // Преобразуем строку JSON в объект Dart (Map)
      Map<String, dynamic> jsonMap = jsonDecode(stringFromLidar);
      // Получаем значение поля SN
      print(jsonMap);
      lidarSerialNumber = jsonMap['Body']['SN'];
      lidarModel = jsonMap['Body']['Model'];

      unitInfo[2]="${jsonMap['Body']['Model']} ${jsonMap['Body']['SN']}";
      updateState();
    } catch (e) {
      stringFromLidar = 'Error: $e';
    }
  }
  /// GET LIDAR SN END

  /// GET UNIT INFO

  Future<void> getDeviceInfo(Function updateState) async {
    if (await createTempKeyFile()) {
      final shell = Shell();
      output = {"IMU SN: ":"","Brand: ":"","Password: ":"","SSID default: ":"","SSID now: ":"","Receiver: ":"","Reciever SN: ":"","Firmware: ":"","Lidar: ":"","IMU Filter: ":""};
      print(output);
      pushUnitResponse(0,output.entries
          .map((entry) => "${entry.key}${entry.value}")
          .join('\n'),updateState);
      try {
        // Получаем IMU
        output["IMU SN: "] = "${imuNumber}";
        unitInfo[1]=imuNumber;
        // Получаем Lidar SN
        await getLidarSn(updateState);

        // Информация по бренду
        var brandNow = await shell.run('''
        ${plinkPath} -i "$keyPath" -P 22 root@192.168.12.1 -hostkey "$hostKey" "cat /etc/brand"
      ''');
        output["Brand: "] = "${brandNow.outText}";
        unitInfo[0]=brandNow.outText;
        // Пароль
        var passphraseNow = await shell.run('''
        ${plinkPath} -i "$keyPath" -P 22 root@192.168.12.1 -hostkey "$hostKey" "cat /etc/passphrase"
      ''');
        output["Password: "] ="${passphraseNow.outText}";

        // SSID по умолчанию
        var ssidDef = await shell.run('''
        ${plinkPath} -i "$keyPath" -P 22 root@192.168.12.1 -hostkey "$hostKey" "grep '^ssid=' /etc/wpa_supplicant/wpa_supplicant-default.conf | sed 's/^ssid=//' && exit"
      ''');
        output["SSID default: "] = "${ssidDef.outText.split(' ').first.replaceAll('"', '')}";

        // Текущий SSID
        var ssidNow = await shell.run('''
        ${plinkPath} -i "$keyPath" -P 22 root@192.168.12.1 -hostkey "$hostKey" "grep '^ssid=' /etc/wpa_supplicant/wpa_supplicant-wlan0.conf | sed 's/^ssid=//' && exit"
      ''');
        output["SSID now: "] = "${ssidNow.outText.split(' ').first.replaceAll('"', '')}";

        // Информация о ресивере
        var receiverNow = await shell.run('''
        ${plinkPath} -i "$keyPath" -P 22 root@192.168.12.1 -hostkey "$hostKey" "grep 'Kernel receiver model =' /var/volatile/payload.log | sed 's/^.*Kernel receiver model = //' && exit"
      ''');

        List<String> parts = receiverNow.outText.split(' ');
        unitInfo[3] = "${parts[0]} ${parts[1]} ${parts.last}";

        output["Receiver: "] = "${parts[0]} ${parts[1]}";
        output["Reciever SN: "] = "${receiverNow.outText.split(' ').last}";

        // Прошивка
        var firmwareNow = await shell.run('''
        ${plinkPath} -i "$keyPath" -P 22 root@192.168.12.1 -hostkey "$hostKey" "head -n 1 /etc/release_notes"
      ''');
        output["Firmware: "] = "${firmwareNow.outText}";
        output["IMU Filter: "] = "${imuFilter}";

        output["Lidar: "] = "$lidarModel $lidarSerialNumber";
       // unitInfo[2]=lidarSerialNumber;

      } catch (e) {
        pushUnitResponse(2,"Fail: check all conditions before start",updateState);
      } finally {
        await deleteTempKeyFile();
      }

      // Обновляем состояние только после завершения всей операции
      pushUnitResponse(1,output.entries
          .map((entry) => "${entry.key}${entry.value}")
          .join('\n'),updateState);
      runGetUnitImu(updateState);
      updateState();
    } else {
      pushUnitResponse(2,"Procedure failed",updateState);
      updateState();
    }
  }

  /// GET IMU NUMBER (PART OF UNIT INFO)


  Future<void> formatUsb(updateState) async {
    pushUnitResponse(0,"Formatting started",updateState);
    final url = Uri.parse('http://192.168.12.1:/cgi-bin/usb-format');
    try {
      final response = await http.get(url);
      var error = response.statusCode == 200
          ? response.body
          : 'Error: ${response.statusCode}';
      pushUnitResponse(2,'Error: There is no connection to the unit or there is no USB drive',updateState);
      responseUsb(updateState);
    } catch (e) {
      pushUnitResponse(2,'Error: There is no connection to the unit or there is no USB drive',updateState);
    }
    finally {updateState();}
  }

  Future<void> responseUsb(updateState) async {
    final url = Uri.parse('http://192.168.12.1:/cgi-bin/usb-status');
    try {
      final response = await http.get(url);
      print(response.toString().length);
      var error = response.statusCode == 200
          ? response.body
          : 'Error: ${response.statusCode}';
      pushUnitResponse(2,'Error: There is no connection to the unit or there is no USB drive',updateState);
      if(response.toString().length > 15){
        pushUnitResponse(1,"Formatting complete",updateState);
      }
    } catch (e) {
      pushUnitResponse(2,'Error: There is no connection to the unit or there is no USB drive',updateState);
    }
    finally {updateState();}
  }

  runGetUnitImu(updateState){
    print("RUN GET UNIT IMU");
    counter=5;
    output["IMU Filter: "] = "Searching";
    output["IMU SN: "] = "Searching";

    pushUnitResponse(1,output.entries
        .map((entry) => "${entry.key}${entry.value}")
        .join('\n'),updateState);
    getImu(updateState);
    updateState();
  }

  void decrementCounter(Function updateState) {
    if (counter > 0) {
      counter--;
      print("------- counter $counter");
      updateState();
    }
  }

  Future<void> runUnit(Function updateState) async {
    if (await createTempKeyFile()) {
      try {
        var processRunUnit = await Process.start(
          plinkPath,
          ['-i', keyPath, 'root@192.168.12.1', '-hostkey', hostKey, "systemctl start payload"],
        );
        await Future.delayed(Duration(seconds: 1), () async {
          processRunUnit.kill();
          await deleteTempKeyFile();
          updateState();
        });
      } catch (e) {}
      finally {}
    }
  }

  String _processUnitResponse(String response) {

    // Use a regular expression to match the part with ASCII characters after the hex values
    RegExp regExp = RegExp(r'\|(.+)\|');
    Iterable<Match> matches = regExp.allMatches(response);
    print('_processUnitResponse: ${matches}');
    // Extract the matched ASCII parts
    List<String> asciiParts = [];
    for (var match in matches) {
      asciiParts.add(match.group(1) ?? '');
    }

    // Split response into lines and get the last 300 lines
    List<String> lines = response.split('\n');
    int start = lines.length > 1000 ? lines.length - 1000 : 0;

    return lines.sublist(start).map((line) {
      // Apply the regular expression to each line and extract ASCII characters
      RegExp matchAscii = RegExp(r'\|([^\|]+)\|');
      var match = matchAscii.firstMatch(line);
      return match?.group(1) ?? '';
    }).join('\n');
  }

  Future<void> getImu(Function updateState) async {
    tempData = "";
    process2=null;
    process3=null;
    process4=null;
    process=null;
    if ( counter == 0) {
      output["IMU Filter: "] = "Not identified";
      output["IMU SN: "] = "Not identified";
      pushUnitResponse(3,output.entries
          .map((entry) => "${entry.key}${entry.value}")
          .join('\n'),updateState);

       }
    else if ( counter != 0) {
      if (await createTempKeyFile()) {
       // pushUnitResponse(0,"Searching",updateState);
        try {
          print("GET IMU STARTED part 1  ");
          process = await Process.start(
            plinkPath,
            [
              '-i',
              keyPath,
              'root@192.168.12.1',
              '-hostkey',
              hostKey,
              "systemctl stop payload"
            ],
          );
          var stderrStream = process.stderr.transform(utf8.decoder).listen((
              data) {
            print('Stderr: $data'); // Log any errors here
          });
          int exitCode = await process.exitCode;
          await stderrStream.cancel();

          if (exitCode == 0) {
            print("tempData 0 : $tempData");
            StringBuffer outputBuffer = StringBuffer();
            process = await Process.start(
              plinkPath,
              [
                '-i',
                keyPath,
                'root@192.168.12.1',
                '-hostkey',
                hostKey,
                "hexdump -C /dev/ttymxc3"
              ],
            );
            /// Осторожно рекурсия
            process.stdout.transform(utf8.decoder).listen((data) async {
              outputBuffer.write(data);
              tempData = data;
            });
            process.stderr.transform(utf8.decoder).listen((data) {
              print("Ошибка: $data");
            });
            print("tempData: $tempData");
            /// GET IMU STARTED part 2
            if (exitCode==0){
              print("GET IMU STARTED part 2  ");

                Future.delayed(Duration(seconds: 2), () async {

                  process2 = await Process.start(
                    plinkPath,
                    ['-i', keyPath, 'root@192.168.12.1', '-hostkey', hostKey, "echo -en '\\xaa\\x55\\x00\\x00\\x09\\x00\\xff\\x57\\x09\\x68\\x01' >/dev/ttymxc3"],
                  );
                });
                Future.delayed(Duration(seconds: 3), () async {
                  process2 = await Process.start(
                    plinkPath,
                    ['-i', keyPath, 'root@192.168.12.1', '-hostkey', hostKey, "stty -F /dev/ttymxc3 921600"],
                  );
                });
                Future.delayed(Duration(seconds: 4), () async {
                  process2 = await Process.start(
                    plinkPath,
                    ['-i', keyPath, 'root@192.168.12.1', '-hostkey', hostKey, "echo -en '\\xA5\\xA5\\x02\\x04\\x0A\\x02\\x01\\x00\\x5D\\xFB' >/dev/ttymxc3"],
                  );
                  print("GET IMU STARTED part 2 (stop traffic)  ");

                  int exitCode = await process2.exitCode;

                  if (exitCode == 0 ){
                    print("GET IMU STARTED part 2 (call for imu number)  ");

                    process2 = await Process.start(
                        plinkPath,
                        ['-i', keyPath, 'root@192.168.12.1', '-hostkey', hostKey, "echo -en '\\xA5\\xA5\\x01\\x02\\x06\\x00\\x53\\x2D' >/dev/ttymxc3"]);
                    process2 = await Process.start(
                        plinkPath,
                        ['-i', keyPath, 'root@192.168.12.1', '-hostkey', hostKey, "echo -en '\\xA5\\xA5\\x01\\x02\\x06\\x00\\x53\\x2D' >/dev/ttymxc3"]);
                    process3 = await Process.start(
                        plinkPath,
                        ['-i', keyPath, 'root@192.168.12.1', '-hostkey', hostKey, "echo -en '\\xA5\\xA5\\x01\\x02\\x06\\x00\\x53\\x2D' >/dev/ttymxc3"]);
                    process3 = await Process.start(
                        plinkPath,
                        ['-i', keyPath, 'root@192.168.12.1', '-hostkey', hostKey, "echo -en '\\xA5\\xA5\\x01\\x02\\x06\\x00\\x53\\x2D' >/dev/ttymxc3"]);
                    process4 = await Process.start(
                        plinkPath,
                        ['-i', keyPath, 'root@192.168.12.1', '-hostkey', hostKey, "echo -en '\\xA5\\xA5\\x01\\x02\\x06\\x00\\x53\\x2D' >/dev/ttymxc3"]);
                    process4 = await Process.start(
                        plinkPath,
                        ['-i', keyPath, 'root@192.168.12.1', '-hostkey', hostKey, "echo -en '\\xA5\\xA5\\x01\\x02\\x06\\x00\\x53\\x2D' >/dev/ttymxc3"]);
                    process4 = await Process.start(
                        plinkPath,
                        ['-i', keyPath, 'root@192.168.12.1', '-hostkey', hostKey, "echo -en '\\xA5\\xA5\\x01\\x02\\x06\\x00\\x53\\x2D' >/dev/ttymxc3"]);
                   /////
                    process2 = await Process.start(
                        plinkPath,
                        ['-i', keyPath, 'root@192.168.12.1', '-hostkey', hostKey, "echo -en '\\xA5\\xA5\\x02\\x03\\x03\\x01\\x02\\x55\\x84' >/dev/ttymxc3"]);
                    process2 = await Process.start(
                        plinkPath,
                        ['-i', keyPath, 'root@192.168.12.1', '-hostkey', hostKey, "echo -en '\\xA5\\xA5\\x02\\x03\\x03\\x01\\x02\\x55\\x84' >/dev/ttymxc3"]);
                    process2 = await Process.start(
                        plinkPath,
                        ['-i', keyPath, 'root@192.168.12.1', '-hostkey', hostKey, "echo -en '\\xA5\\xA5\\x02\\x03\\x03\\x01\\x02\\x55\\x84' >/dev/ttymxc3"]);
                    process2 = await Process.start(
                        plinkPath,
                        ['-i', keyPath, 'root@192.168.12.1', '-hostkey', hostKey, "echo -en '\\xA5\\xA5\\x02\\x03\\x03\\x01\\x02\\x55\\x84' >/dev/ttymxc3"]);

                    int exitCode2 = await process2.exitCode;
                    int exitCode4 = await process4.exitCode;

                    if(exitCode2==0 && exitCode4==0){
                      getResultFromImuScan(updateState);
                      await deleteTempKeyFile();
                      await process2.kill();
                      await process3.kill();
                      await process4.kill();
                      await process.kill();
                    }else{
                      await deleteTempKeyFile();
                      await runUnit(updateState);
                      //await getDeviceInfo(updateState);
                      await process2.kill();
                      await process3.kill();
                      await process4.kill();
                      await process.kill();
                    }
                  }
                });
            }
          } else {
            output["IMU Filter: "] = "Unit is not connected";
            output["IMU SN: "] = "Unit is not connected";

            pushUnitResponse(3,output.entries
                .map((entry) => "${entry.key}${entry.value}")
                .join('\n'),updateState);
            //pushUnitResponse(3,"Unit is not connected",updateState);
            await deleteTempKeyFile();
            print('Command failed with exit code: $exitCode');
            //// restart!!
          }
        } finally {}
      } else {}
    }
  }


  // Future<void> getImu2(Function updateState) async {
  //
  //   if (await createTempKeyFile()) {
  //     print("GET IMU STARTED part 2  ");
  //     try {
  //       Future.delayed(Duration(seconds: 2), () async {
  //
  //         process2 = await Process.start(
  //           plinkPath,
  //           ['-i', keyPath, 'root@192.168.12.1', '-hostkey', hostKey, "echo -en '\\xaa\\x55\\x00\\x00\\x09\\x00\\xff\\x57\\x09\\x68\\x01' >/dev/ttymxc3"],
  //         );
  //       });
  //       Future.delayed(Duration(seconds: 3), () async {
  //         process2 = await Process.start(
  //           plinkPath,
  //           ['-i', keyPath, 'root@192.168.12.1', '-hostkey', hostKey, "stty -F /dev/ttymxc3 921600"],
  //         );
  //       });
  //       Future.delayed(Duration(seconds: 4), () async {
  //         process2 = await Process.start(
  //           plinkPath,
  //           ['-i', keyPath, 'root@192.168.12.1', '-hostkey', hostKey, "echo -en '\\xA5\\xA5\\x02\\x04\\x0A\\x02\\x01\\x00\\x5D\\xFB' >/dev/ttymxc3"],
  //         );
  //         print("GET IMU STARTED part 2 (stop traffic)  ");
  //
  //         int exitCode = await process2.exitCode;
  //
  //         if (exitCode == 0 ){
  //           print("GET IMU STARTED part 2 (call for imu number)  ");
  //
  //           process2 = await Process.start(
  //               plinkPath,
  //               ['-i', keyPath, 'root@192.168.12.1', '-hostkey', hostKey, "echo -en '\\xA5\\xA5\\x01\\x02\\x06\\x00\\x53\\x2D' >/dev/ttymxc3"]);
  //           print('1 --- \n${tempData.length > 312 ? tempData.substring(tempData.length - 312) : tempData}');
  //           process2 = await Process.start(
  //               plinkPath,
  //               ['-i', keyPath, 'root@192.168.12.1', '-hostkey', hostKey, "echo -en '\\xA5\\xA5\\x01\\x02\\x06\\x00\\x53\\x2D' >/dev/ttymxc3"]);
  //           print('2 --- \n${tempData.length > 312 ? tempData.substring(tempData.length - 312) : tempData}');
  //           process3 = await Process.start(
  //               plinkPath,
  //               ['-i', keyPath, 'root@192.168.12.1', '-hostkey', hostKey, "echo -en '\\xA5\\xA5\\x01\\x02\\x06\\x00\\x53\\x2D' >/dev/ttymxc3"]);
  //           print('3 --- \n${tempData.length > 312 ? tempData.substring(tempData.length - 312) : tempData}');
  //           process3 = await Process.start(
  //               plinkPath,
  //               ['-i', keyPath, 'root@192.168.12.1', '-hostkey', hostKey, "echo -en '\\xA5\\xA5\\x01\\x02\\x06\\x00\\x53\\x2D' >/dev/ttymxc3"]);
  //           print('4 --- \n${tempData.length > 312 ? tempData.substring(tempData.length - 312) : tempData}');
  //           process4 = await Process.start(
  //               plinkPath,
  //               ['-i', keyPath, 'root@192.168.12.1', '-hostkey', hostKey, "echo -en '\\xA5\\xA5\\x01\\x02\\x06\\x00\\x53\\x2D' >/dev/ttymxc3"]);
  //           print('5 --- \n${tempData.length > 312 ? tempData.substring(tempData.length - 312) : tempData}');
  //           process4 = await Process.start(
  //               plinkPath,
  //               ['-i', keyPath, 'root@192.168.12.1', '-hostkey', hostKey, "echo -en '\\xA5\\xA5\\x01\\x02\\x06\\x00\\x53\\x2D' >/dev/ttymxc3"]);
  //           print('6 --- \n${tempData.length > 312 ? tempData.substring(tempData.length - 312) : tempData}');
  //           process4 = await Process.start(
  //               plinkPath,
  //               ['-i', keyPath, 'root@192.168.12.1', '-hostkey', hostKey, "echo -en '\\xA5\\xA5\\x01\\x02\\x06\\x00\\x53\\x2D' >/dev/ttymxc3"]);
  //           print('7 --- \n${tempData.length > 312 ? tempData.substring(tempData.length - 312) : tempData}');
  //           /////
  //           process2 = await Process.start(
  //               plinkPath,
  //               ['-i', keyPath, 'root@192.168.12.1', '-hostkey', hostKey, "echo -en '\\xA5\\xA5\\x02\\x03\\x03\\x01\\x02\\x55\\x84' >/dev/ttymxc3"]);
  //           print('8 --- \n${tempData.length > 312 ? tempData.substring(tempData.length - 312) : tempData}');
  //           process2 = await Process.start(
  //               plinkPath,
  //               ['-i', keyPath, 'root@192.168.12.1', '-hostkey', hostKey, "echo -en '\\xA5\\xA5\\x02\\x03\\x03\\x01\\x02\\x55\\x84' >/dev/ttymxc3"]);
  //           print('9 --- \n${tempData.length > 312 ? tempData.substring(tempData.length - 312) : tempData}');
  //           process2 = await Process.start(
  //               plinkPath,
  //               ['-i', keyPath, 'root@192.168.12.1', '-hostkey', hostKey, "echo -en '\\xA5\\xA5\\x02\\x03\\x03\\x01\\x02\\x55\\x84' >/dev/ttymxc3"]);
  //           print('10 --- \n${tempData.length > 312 ? tempData.substring(tempData.length - 312) : tempData}');
  //           process2 = await Process.start(
  //               plinkPath,
  //               ['-i', keyPath, 'root@192.168.12.1', '-hostkey', hostKey, "echo -en '\\xA5\\xA5\\x02\\x03\\x03\\x01\\x02\\x55\\x84' >/dev/ttymxc3"]);
  //           print('11 --- \n${tempData.length > 312 ? tempData.substring(tempData.length - 312) : tempData}');
  //
  //           int exitCode2 = await process2.exitCode;
  //           int exitCode4 = await process4.exitCode;
  //
  //           if(exitCode2==0 && exitCode4==0){
  //             getResultFromImuScan(updateState);
  //             await deleteTempKeyFile();
  //             // print('========== TEST  $tempData');
  //             await process2.kill();
  //             await process3.kill();
  //             await process4.kill();
  //             await process.kill();
  //           }else{
  //             await deleteTempKeyFile();
  //             await runUnit(updateState);
  //             await getDeviceInfo(updateState);
  //             await process2.kill();
  //             await process3.kill();
  //             await process4.kill();
  //             await process.kill();
  //           }
  //         }
  //       });
  //     } finally {}
  //   }
  // }

  getResultFromImuScan(updateState) async {
   // await deleteTempKeyFile();
    print('================== 305 result ==================== \n${tempData}');
    String result = _processUnitResponse(tempData).replaceAll('\n', '').replaceAll(' ', '');
    print('================== 307 result ==================== \n${result}');

    String stringBytes = tempData
        .replaceAllMapped(RegExp(r'^\S+\s+([\da-fA-F\s]+)\s+\|.*\|$', multiLine: true), (match) {
      return match.group(1)?.replaceAll(RegExp(r'\s{2,}'), ' ').trim() ?? '';
    }).replaceAll('\n', ' ');

    print('================== 314 bytes =====================  \n$stringBytes');
    // Соединяем строки в одну строку
    // Преобразуем строку в список байтов
    List<String> bytes = stringBytes.split(' ');
    // Ищем комбинацию 83 01 и проверяем следующий байт
   // imuFilter='';
    for (int i = 0; i < bytes.length - 2; i++) {
      if (bytes[i] == '83' && bytes[i + 1] == '01') {
        if (bytes[i + 2] == '00') {
          output["IMU Filter: "] = "Correct";

          print('Найдено: 83 01 - следующее значение 00');
          pushUnitResponse(1,output.entries
              .map((entry) => "${entry.key}${entry.value}")
              .join('\n'),updateState);
          updateState();
        } if (bytes[i + 2] != '00') {
          output["IMU Filter: "] = "Wrong";
          pushUnitResponse(1,output.entries
              .map((entry) => "${entry.key}${entry.value}")
              .join('\n'),updateState);
          print('Найдено: 83 01 - следующее не 00');
          updateState();
        }
      }
      updateState();
    }

    RegExp regExp = RegExp(r'\.([A-Za-z0-9]{5,})\.');// Регулярное выражение для поиска номеров из букв и цифр длиной не менее 5 символов
    RegExpMatch? match = regExp.firstMatch(result);// Ищем все совпадения

    print('================== 338  Выводим найденные номера  =======\n${match}');

    if(match==null || match.group(1)!.toString().length < 5 && counter != 0){
      print('==================  340 Номер не найден  ================= ');
      output["IMU Filter: "] = "No result, I\'ll try again ${counter-1} times";
      output["IMU SN: "] = "No result, I\'ll try again ${counter-1} times";

      pushUnitResponse(1,output.entries
          .map((entry) => "${entry.key}${entry.value}")
          .join('\n'),updateState);;

      decrementCounter(updateState);
      await runUnit(updateState);

      Future.delayed(Duration(seconds: 3), () async {
        await getImu(updateState);
        print('==== $counter');
        updateState();
      });

    } else if(counter == 0){
      print('============ Counter 0 = $counter');
      output["IMU Filter: "] = "Unit is not identified";
      output["IMU SN: "] = "Unit is not identified";

      pushUnitResponse(1,output.entries
          .map((entry) => "${entry.key}${entry.value}")
          .join('\n'),updateState);
      updateState();
      //pushUnitResponse(2,"Not all data collected, please reboot the unit",updateState);
      await deleteTempKeyFile();
      await runUnit(updateState);
    } else if (match != null && counter!= 0) {// Выводим найденные номера
      print('Найден номер: ${match.group(1)}');
      String number = match.group(1)!;
      output["IMU SN: "] = "${number}";
      unitInfo[1]=number.toString();
      pushUnitResponse(1,output.entries
          .map((entry) => "${entry.key}${entry.value}")
          .join('\n'),updateState);
      updateState();
      print('Найден номер IMU 1: ${number}');
     // await getDeviceInfo(updateState);
      await runUnit(updateState);
      // Получаем номер
      if (RegExp(r'[A-Za-z]$').hasMatch(number)) {// Проверяем, если последний символ - буква, удаляем его
        number = number.substring(0, number.length - 1);// Проверяем, заканчивается ли строка на букву с помощью регулярного выражения
        output["IMU SN: "] = "${number}";
        unitInfo[1]=number.toString();
        pushUnitResponse(1,output.entries
            .map((entry) => "${entry.key}${entry.value}")
            .join('\n'),updateState);
        updateState();
        print('Найден номер IMU 2: ${number}');
       // await getDeviceInfo(updateState);
        await runUnit(updateState);
        updateState();
      }
      updateState();
    }
    await deleteTempKeyFile();
    print('Last --- \n${tempData.length > 1000 ? tempData.substring(tempData.length - 1000) : tempData}');

  }

  /// GET IMU NUMBER (PART OF UNIT INFO) END

}



