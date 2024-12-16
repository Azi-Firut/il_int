import 'dart:convert';
import 'dart:io';
import 'package:il_int/models/ssh.dart';
import 'package:il_int/models/toXl32.dart';
import 'package:il_int/models/toXl64.dart';
import 'package:il_int/models/zip.dart';
import 'package:il_int/widgets/answer_from_unit.dart';
import 'package:path/path.dart' as p;
import 'package:process_run/shell.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../constant.dart';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';

import 'data.dart';
import 'get_imu_val.dart';

class TestGen2 {
  static final TestGen2 _instance = TestGen2._internal();

  factory TestGen2() {
    return _instance;
  }

  TestGen2._internal();

  String? unitNum;
  List<String> listContentTxt = [];
  Map<String, String> mapListContent = {};
  List<List<double>> lidarOffsetsList = [];
  List<List<double>> filtersList = [];
  String ssidFromFolderName='';
  String ssidNumberFromFolderName='';
  //--
  var appDirectory;
  var tempDir;
  var pathToUnitFolder;
  var pathToPPK;
  var bDir;
  var bAdr;

  //--
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
  String xlsxPath = '';





  /// Restart unit
  Future<void> restartUnit() async {
    if (await createTempKeyFile()) {
      print('Рестарт');
      // pushUnitResponse(1,"Final parameters uploaded\nThe unit will be rebooted",updateState);

      try {
        var processRestartUnit = await Process.start(
          plinkPath,
          ['-i', keyPath, 'root@192.168.12.1', '-hostkey', hostKey, "systemctl restart payload"],
        );
        await Future.delayed(Duration(seconds: 1), () async {
          processRestartUnit.kill();
          await deleteTempKeyFile();
        });
      } catch (e) {}
      finally {
        // pushUnitResponse(1,"Final parameters uploaded\nThe unit will be rebooted",updateState);

      }
    }
  }

  /// GET UNIT INFO END

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
      if(jsonMap['Body']['Model']=='Pandar_ZYNQ'){
        lidarModel = "Hesai XT32";
        jsonMap['Body']['Model']='Hesai XT32';
      }

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
          .join('\n'),updateState:updateState);
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
        pushUnitResponse(2,"Fail: check all conditions before start",updateState:updateState);
      } finally {
        await deleteTempKeyFile();
      }

      // Обновляем состояние только после завершения всей операции
      pushUnitResponse(1,output.entries
          .map((entry) => "${entry.key}${entry.value}")
          .join('\n'),updateState:updateState);
      runGetUnitImuGen2(updateState);
      updateState();
    } else {
      pushUnitResponse(2,"Procedure failed",updateState:updateState);
      updateState();
    }
  }

  /// GET IMU NUMBER GEN 2 (PART OF UNIT INFO)

  runGetUnitImuGen2(updateState){
    print("RUN GET UNIT IMU GEN 2");
    counter=5;
    output["IMU Filter: "] = "Searching";
    output["IMU SN: "] = "Searching";

    pushUnitResponse(1,output.entries
        .map((entry) => "${entry.key}${entry.value}")
        .join('\n'),updateState:updateState);
    getImuGen2(updateState);
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


  Future<void> getImuGen2(Function updateState) async {
    tempData = "";
    process=null;
    process2=null;

    if ( counter == 0) {
      output["IMU Filter: "] = "Not identified";
      output["IMU SN: "] = "Not identified";
      pushUnitResponse(3,output.entries
          .map((entry) => "${entry.key}${entry.value}")
          .join('\n'),updateState:updateState);
    }
    else if ( counter != 0) {
      if (await createTempKeyFile()) {
        // pushUnitResponse(0,"Searching",updateState);
        try {
          print("GET IMU GEN2 STARTED part 1  ");
          process = await Process.start(
            plinkPath,
            [
              '-i',
              keyPath,
              'root@192.168.12.1',
              '-hostkey',
              hostKey,
              "stty -F /dev/ttyLP3 921600"
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
                "hexdump -C /dev/ttyLP3"
              ],
            );
            /// Осторожно рекурсия
            process.stdout.transform(utf8.decoder).listen((data) async {
              outputBuffer.write(data);
              //print('DATA \n${data}');
              tempData = data;
            });
            process.stderr.transform(utf8.decoder).listen((data) {
              print("Ошибка: $data");
            });

            /// GET IMU STARTED part 2

            print("GET IMU GEN2  part 2 ");

              Future.delayed(Duration(seconds: 1), () async {
                process2 = await Process.start(
                  plinkPath,
                  ['-i', keyPath, 'root@192.168.12.1', '-hostkey', hostKey, "echo -en '\\xaa\\x55\\x00\\x00\\x07\\x00\\xfe\\x05\\x01' >/dev/ttyLP3"],
                );

                print("GET IMU GEN2 STARTED part 2 (call for imu number)  ");
                Future.delayed(Duration(seconds: 2), () async {
                process2 = await Process.start(
                    plinkPath,
                    ['-i', keyPath, 'root@192.168.12.1', '-hostkey', hostKey, "echo -en '\\xaa\\x55\\x00\\x00\\x07\\x00\\x12\\x19\\x00' >/dev/ttyLP3"]);
                process2 = await Process.start(
                    plinkPath,
                    ['-i', keyPath, 'root@192.168.12.1', '-hostkey', hostKey, "echo -en '\\xaa\\x55\\x00\\x00\\x07\\x00\\x12\\x19\\x00' >/dev/ttyLP3"]);
                process2 = await Process.start(
                    plinkPath,
                    ['-i', keyPath, 'root@192.168.12.1', '-hostkey', hostKey, "echo -en '\\xaa\\x55\\x00\\x00\\x07\\x00\\x12\\x19\\x00' >/dev/ttyLP3"]);
                process2 = await Process.start(
                    plinkPath,
                    ['-i', keyPath, 'root@192.168.12.1', '-hostkey', hostKey, "echo -en '\\xaa\\x55\\x00\\x00\\x07\\x00\\x12\\x19\\x00' >/dev/ttyLP3"]);
                process2 = await Process.start(
                    plinkPath,
                    ['-i', keyPath, 'root@192.168.12.1', '-hostkey', hostKey, "echo -en '\\xaa\\x55\\x00\\x00\\x07\\x00\\x12\\x19\\x00' >/dev/ttyLP3"]);

                });

                Future.delayed(Duration(seconds: 3), () async {
                  process.kill();
                  process2.kill();
                  deleteTempKeyFile();
                print("GET IMU GEN2 STARTED part 2 (call for imu number) ====\n $tempData ");
                print("GET IMU GEN2 STARTED part 2 (call for imu number) ====\n ${tempData.length} ");
                  getResultFromImuScanGen2(updateState);
                });
              });
          } else {
            output["IMU Filter: "] = "Unit is not connected";
            output["IMU SN: "] = "Unit is not connected";

            pushUnitResponse(3,output.entries
                .map((entry) => "${entry.key}${entry.value}")
                .join('\n'),updateState:updateState);
            //pushUnitResponse(3,"Unit is not connected",updateState);
            await deleteTempKeyFile();
            print('Command failed with exit code: $exitCode');
            //// restart!!
          }
        } finally {}
      } else {}
    }
  }


  getResultFromImuScanGen2(updateState) async {
    print('================== 305 result ==================== \n${tempData}');
    String result = _processUnitResponse(tempData).replaceAll('\n', '').replaceAll(' ', '');
    print('================== 307 result ==================== \n${result}');

    RegExp regExpSN = RegExp(r'\.{10,}([A-Za-z0-9]*\d{4,})');
    Match? matchSn = regExpSN.firstMatch(result.toString());

    if(matchSn==null || matchSn.group(1)!.toString().length < 5 && counter != 0){
      print('==================  340 Номер не найден  ================= ');
      output["IMU Filter: "] = "No result, I\'ll try again ${counter-1} times";
      output["IMU SN: "] = "No result, I\'ll try again ";

      pushUnitResponse(1,output.entries
          .map((entry) => "${entry.key}${entry.value}")
          .join('\n'),updateState:updateState);

      decrementCounter(updateState);
      await runUnit(updateState);

      Future.delayed(Duration(seconds: 3), () async {
        await getImuGen2(updateState);
        print('==== $counter');
        updateState();
      });

    } else if(counter == 0){
      print('============ Counter 0 = $counter');
      output["IMU Filter: "] = "Unit is not identified";
      output["IMU SN: "] = "Unit is not identified";

      pushUnitResponse(1,output.entries
          .map((entry) => "${entry.key}${entry.value}")
          .join('\n'),updateState:updateState);
      updateState();

      await deleteTempKeyFile();
      await runUnit(updateState);
    } else if (matchSn != null && counter!= 0) {// Выводим найденные номера
      print('Найден номер: ${matchSn.group(1)}');
      String number = matchSn.group(1)!;
      output["IMU SN: "] = number;
      output["IMU Filter: "] = "I didn't even look";
      unitInfo[1]=number.toString();
      pushUnitResponse(1,output.entries
          .map((entry) => "${entry.key}${entry.value}")
          .join('\n'),updateState:updateState);
      updateState();
      print('Найден номер IMU : $number');
      await runUnit(updateState);
      // Получаем номер
      if (RegExp(r'[A-Za-z]$').hasMatch(number)) {// Проверяем, если последний символ - буква, удаляем его
        number = number.substring(0, number.length - 1);// Проверяем, заканчивается ли строка на букву с помощью регулярного выражения
        output["IMU SN: "] = number;
        output["IMU Filter: "] = "I didn't even look";
        unitInfo[1]=number.toString();
        pushUnitResponse(1,output.entries
            .map((entry) => "${entry.key}${entry.value}")
            .join('\n'),updateState:updateState);
        updateState();
        print('Найден номер IMU 2: ${number}');
        await runUnit(updateState);
        updateState();
      }
      updateState();
    }
    await deleteTempKeyFile();
  }

  /// GET IMU NUMBER GEN 2(PART OF UNIT INFO) END



}
