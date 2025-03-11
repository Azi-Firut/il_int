import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:html/parser.dart';
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

class TestGetImuNumberG1 {
  static final TestGetImuNumberG1 _instance = TestGetImuNumberG1._internal();

  factory TestGetImuNumberG1() {
    return _instance;
  }

  TestGetImuNumberG1._internal();

//  =VARS=
  String? unitNum;
  List<String> listContentTxt = [];
  Map<String, String> mapListContent = {};
  List<List<double>> lidarOffsetsList = [];
  List<List<double>> filtersList = [];
  String ssidFromFolderName = '';
  String ssidNumberFromFolderName = '';
  StreamSubscription? subscription;
  StringBuffer outputBuffer = StringBuffer();

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
  var imuNumber = '';
  var imuFilter = '';
  var tempData = '';
  var counter = 5;
  var lidarSerialNumber = '';
  var lidarModel = '';
  var urlToLidar = 'http://192.168.12.1:8001/pandar.cgi?action=get&object=device_info';


  //////////////////////////////////////////////////////////////

  /// Restart unit
  Future<void> _restartUnit() async {
    if (await createTempKeyFile()) {
      print('Рестарт');
      try {
        var processRestartUnit = await Process.start(
          plinkPath,
          [
            '-i',
            keyPath,
            'root@192.168.12.1',
            '-hostkey',
            hostKey,
            "systemctl restart payload"
          ],
        );
        await Future.delayed(const Duration(seconds: 1), () async {
          processRestartUnit.kill();
          await deleteTempKeyFile();
        });
      }
      finally {
      }
    }
  }
  /// Reboot unit
  Future<void> _rebootUnit() async {
    if (await createTempKeyFile()) {
      print('Перезагрузка');
      try {
        var processRestartUnit = await Process.start(
          plinkPath,
          [
            '-i',
            keyPath,
            'root@192.168.12.1',
            '-hostkey',
            hostKey,
            "systemctl reboot payload"
          ],
        );
        await Future.delayed(const Duration(seconds: 1), () async {
          processRestartUnit.kill();
          await deleteTempKeyFile();
        });
      }
      finally {
      }
    }
  }
  /// Run unit
  Future<void> _startUnit(Function updateState) async {
    if (await createTempKeyFile()) {
      print('Запуск устройства');
      try {
        var processRunUnit = await Process.start(
          plinkPath,
          [
            '-i',
            keyPath,
            'root@192.168.12.1',
            '-hostkey',
            hostKey,
            "systemctl start payload"
          ],
        );
        await Future.delayed(const Duration(seconds: 1), () async {
          processRunUnit.kill();
          await deleteTempKeyFile();
          updateState();
        });
      }
      finally {}
    }
  }
  ///////////////////////////////////////////////////////////////

  void _decrementCounter(Function updateState) {
    if (counter > 0) {
      counter--;
      print("Counter = $counter");
      updateState();
    }
  }


  /// Check WiFi connection with unit
  bool _checkUnitConnection(Function updateState){
    bool connection;
    if (connectedSsid != '' && connectedSsid != "Not connected") {
      connection= true;
      print('UnitConnection: Unit connected');
    } else {
      connection= false;
      pushUnitResponse(0, 'Unit is not connected', updateState: updateState);
      print('UnitConnection: Unit is not connected');
    }
    return connection;
  }
  ///////////////////////////////////////////////////////////////

  // ENTRY POINT FROM SCREEN ____________________________________
  genSwitchToGetImuNumber(updateState) async {  // ENTRY POINT FROM SCREEN
    if (_checkUnitConnection(updateState)) {
      print("RUN GET UNIT IMU");
      counter = 5;
      output["IMU Filter: "] = "Searching";
      output["IMU SN: "] = "Searching";

      pushUnitResponse(1, output.entries
          .map((entry) => "${entry.key}${entry.value}")
          .join('\n'), updateState: updateState);
      if (await fetchTitle() == "RESEPI GEN-II" ||
          await fetchTitle() == "FLIGHTS GEN-II") {
        //getImuGen2(updateState);
        print('SWITCH TO GEN2 UMU SEARCH');
      } else {
        _getImuGen1(updateState);
        print('SWITCH TO GEN1 UMU SEARCH');
      }
      updateState();
    } else {
      pushUnitResponse(0, 'Unit is not connected', updateState: updateState);
    }
  }
  //_____________________________________________________________

  _getResultFromImuScan(updateState) async {
    String result = _processDataFromUnit(tempData).replaceAll('\n', '').replaceAll(' ', '');
    String stringBytes = tempData
        .replaceAllMapped(RegExp(r'^\S+\s+([\da-fA-F\s]+)\s+\|.*\|$', multiLine: true), (match) {
      return match.group(1)?.replaceAll(RegExp(r'\s{2,}'), ' ').trim() ?? '';
    }).replaceAll('\n', ' ');
    List<String> bytes = stringBytes.split(' ');
    for (int i = 0; i < bytes.length - 2; i++) {
      if (bytes[i] == '83' && bytes[i + 1] == '01') {
        if (bytes[i + 2] == '00') {
          output["IMU Filter: "] = "Correct";
          pushUnitResponse(1,output.entries
              .map((entry) => "${entry.key}${entry.value}")
              .join('\n'),updateState:updateState);
          updateState();
        } if (bytes[i + 2] != '00') {
          output["IMU Filter: "] = "Wrong";
          pushUnitResponse(1,output.entries
              .map((entry) => "${entry.key}${entry.value}")
              .join('\n'),updateState:updateState);
          print('Найдено: 83 01 - следующее не 00');
          updateState();
        }
      }
      updateState();
    }
    // ----
    RegExp regExp = RegExp(r'\.{10,}([A-Za-z0-9]*\d{4,})');
    Match? match = regExp.firstMatch(result.toString());
    if(match==null || match.group(1)!.toString().length < 5 && counter != 0){
      output["IMU Filter: "] = "No result, I'll try again ${counter-1} times";
      output["IMU SN: "] = "No result, I'll try again ";
      pushUnitResponse(1,output.entries
          .map((entry) => "${entry.key}${entry.value}")
          .join('\n'),updateState:updateState);
      _decrementCounter(updateState);
      await _startUnit(updateState);
      Future.delayed(const Duration(seconds: 3), () async {
        await _getImuGen1(updateState);
        print('==== $counter');
        updateState();
      });
    } else if(counter == 0){
      output["IMU Filter: "] = "Unit is not identified";
      output["IMU SN: "] = "Unit is not identified";
      pushUnitResponse(1,output.entries
          .map((entry) => "${entry.key}${entry.value}")
          .join('\n'),updateState:updateState);
      updateState();
      await deleteTempKeyFile();
      await _startUnit(updateState);
    } else if (counter!= 0) {
      print('Найден номер: ${match.group(1)}');
      String number = match.group(1)!;
      output["IMU SN: "] = number;
      unitInfo[1]=number.toString();
      pushUnitResponse(1,output.entries
          .map((entry) => "${entry.key}${entry.value}")
          .join('\n'),updateState:updateState);
      updateState();
      print('Найден номер IMU 1: $number');
      await _startUnit(updateState);
      if (RegExp(r'[A-Za-z]$').hasMatch(number)) {
        number = number.substring(0, number.length - 1);
        output["IMU SN: "] = number;
        unitInfo[1]=number.toString();
        pushUnitResponse(1,output.entries
            .map((entry) => "${entry.key}${entry.value}")
            .join('\n'),updateState:updateState);
        updateState();
        print('Найден номер IMU 2: $number');
        await _startUnit(updateState);
        updateState();
      }
      updateState();
    }
    await deleteTempKeyFile();
    print('Last --- \n${tempData.length > 1000 ? tempData.substring(tempData.length - 1000) : tempData}');

  }
  //=============================================================

  Future<void> _getLidarSn(updateState) async {
    lidarSerialNumber='';
    lidarModel='';
    final url = Uri.parse(urlToLidar);
    String stringFromLidar;
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

  Future<void> getDeviceInfo(Function updateState) async {
    if (await createTempKeyFile() && _checkUnitConnection(updateState)) {
      final shell = Shell();
      output = {"IMU SN: ":"","Brand: ":"","Password: ":"","SSID default: ":"","SSID now: ":"","Receiver: ":"","Reciever SN: ":"","Firmware: ":"","Lidar: ":"","IMU Filter: ":""};
      print(output);
      pushUnitResponse(0,output.entries
          .map((entry) => "${entry.key}${entry.value}")
          .join('\n'),updateState:updateState);
      try {
        // Получаем IMU
        output["IMU SN: "] = imuNumber;
        unitInfo[1]=imuNumber;
        // Получаем Lidar SN
        await _getLidarSn(updateState);

        // Информация по бренду
        var brandNow = await shell.run('''
        $plinkPath -i "$keyPath" -P 22 root@192.168.12.1 -hostkey "$hostKey" "cat /etc/brand"
      ''');
        output["Brand: "] = brandNow.outText;
        unitInfo[0]=brandNow.outText;
        // Пароль
        var passphraseNow = await shell.run('''
        $plinkPath -i "$keyPath" -P 22 root@192.168.12.1 -hostkey "$hostKey" "cat /etc/passphrase"
      ''');
        output["Password: "] =passphraseNow.outText;

        // SSID по умолчанию
        var ssidDef = await shell.run('''
        $plinkPath -i "$keyPath" -P 22 root@192.168.12.1 -hostkey "$hostKey" "grep '^ssid=' /etc/wpa_supplicant/wpa_supplicant-default.conf | sed 's/^ssid=//' && exit"
      ''');
//         var ssidDef = await shell.run('''
//   ${plinkPath} -i "$keyPath" -P 22 root@192.168.12.1 -hostkey "$hostKey" /etc/hostname"
// ''');
        output["SSID default: "] = ssidDef.outText.split(' ').first.replaceAll('"', '');

        // Текущий SSID
        var ssidNow = await shell.run('''
        $plinkPath -i "$keyPath" -P 22 root@192.168.12.1 -hostkey "$hostKey" "grep '^ssid=' /etc/wpa_supplicant/wpa_supplicant-wlan0.conf | sed 's/^ssid=//' && exit"
      ''');
        output["SSID now: "] = ssidNow.outText.split(' ').first.replaceAll('"', '');

        // Информация о ресивере
        var receiverNow = await shell.run('''
        $plinkPath -i "$keyPath" -P 22 root@192.168.12.1 -hostkey "$hostKey" "grep 'Kernel receiver model =' /var/volatile/payload.log | sed 's/^.*Kernel receiver model = //' && exit"
      ''');

        List<String> parts = receiverNow.outText.split(' ');
        unitInfo[3] = "${parts[0]} ${parts[1]} ${parts.last}";
        print('receiver parts ===\n$parts');
        print('receiver code ===\n${parts[2]}');
        var codeCheck ='';
        if (parts[1].contains('OEM7720') && parts[2] == 'FDDRZNTBN') {
          codeCheck = 'CODE CORRECT';
        } else if (parts[1].contains('OEM7720') && parts[2] != 'FDDRZNTBN') {
          codeCheck = 'CODE WRONG !!!';
        } else if (parts[2].contains('GSNNNNNNN')) {
          codeCheck = 'CODE MISSING !!!';
        } else {
          codeCheck = '';
        }


        output["Receiver: "] = "${parts[0]} ${parts[1]} $codeCheck";
        output["Reciever SN: "] = receiverNow.outText.split(' ').last;

        // Прошивка
        var firmwareNow = await shell.run('''
        $plinkPath -i "$keyPath" -P 22 root@192.168.12.1 -hostkey "$hostKey" "head -n 1 /etc/release_notes"
      ''');
        output["Firmware: "] = firmwareNow.outText;
        output["IMU Filter: "] = imuFilter;

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
      genSwitchToGetImuNumber(updateState);
      updateState();
    } else {
      pushUnitResponse(2,"Procedure failed",updateState:updateState);
      updateState();
    }
  }

  String _processDataFromUnit(String response) {

    // Use a regular expression to match the part with ASCII characters after the hex values
    RegExp regExp = RegExp(r'\|(.+)\|');
    Iterable<Match> matches = regExp.allMatches(response);
    print('_processDataFromUnit: $matches');
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

  Future<void> _getImuGen1(Function updateState) async {
    tempData = "";
    process = null;
    process2 = null;
    if (_checkUnitConnection(updateState) && counter != 0) {
      if (await createTempKeyFile()) {
        if (await getImuG1_01(updateState) == 0) {
          Future.delayed(const Duration(milliseconds: 100), () async {
            await getImuG1_02(updateState); // collect data
            Future.delayed(const Duration(milliseconds: 10), () async {
               await getImuG1_03(updateState); // IMU KERNEL-210
              Future.delayed(const Duration(milliseconds: 10), () async {
               if (await getImuG1_04(updateState) == 0) { // 3012-HF
                 Future.delayed(const Duration(milliseconds: 10), () async {
                   if (await getImuG1_05(updateState) == 0) { // 921600 switch
                     Future.delayed(const Duration(milliseconds: 10), () async {
                       if (await getImuG1_06(updateState) ==0) { // - traffic should stop
                         Future.delayed(
                             const Duration(milliseconds: 10), () async {
                           if (await getImuG1_07(updateState) == 0) {
                             Future.delayed(
                                 const Duration(milliseconds: 10), () async {
                               if (await getImuG1_07(updateState) == 0) {
                                 await getImuG1_07(updateState); // request
                                 if (await getImuG1_07(updateState) == 0) {
                                   Future.delayed(
                                       const Duration(
                                           milliseconds: 100), () async {
                                     await getImuG1_08(updateState);
                                   });
                                 }
                               }
                             });
                           }
                         });
                       }
                     });
                   }
                 });
               }
              });
            });
          });
        }
      }
    }
    else if (counter == 0){
      output["IMU Filter: "] = "Not identified";
      output["IMU SN: "] = "Not identified";
      pushUnitResponse(3,output.entries
          .map((entry) => "${entry.key}${entry.value}")
          .join('\n'),updateState:updateState);
    }
    else {
      pushUnitResponse(0, 'Unit is not connected', updateState: updateState);
    }
  } // Main function to get imu sn

  Future<int> getImuG1_01(Function updateState) async {
   // await createTempKeyFile();
    print("_getImuG1_01 : START");
    try{
     process =
      await Process.run(
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
     return process.exitCode;
    }catch(e){
      print(e);
      return process.exitCode;
    }finally{
      print("_getImuG1_01 : DONE");
    }
  }

  Future<void> getImuG1_02(Function updateState) async {
    print("_getImuG1_02 : START");
    try{
    // StringBuffer outputBuffer = StringBuffer();
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
      // process.stdout.transform(utf8.decoder).listen((data) async {
      //   outputBuffer.write(data);
      //   tempData = data;
      //   print("_getImuG1_02 : TEMPDATA \n$tempData");
      // });
    }catch(e){
      print(e);
    }finally{
      print("_getImuG1_02 : DONE");
    }
  }

  Future<void> getImuG1_03(Function updateState) async {
    print("_getImuG1_03 : START");
    try{
      process2 = await Process.start(
        plinkPath,
        ['-i', keyPath, 'root@192.168.12.1', '-hostkey', hostKey, "echo -en '\\xaa\\x55\\x00\\x00\\x07\\x00\\xfe\\x05\\x01' >/dev/ttymxc3"],
      );
      process2 = await Process.start(
        plinkPath,
        ['-i', keyPath, 'root@192.168.12.1', '-hostkey', hostKey, "echo -en '\\xaa\\x55\\x00\\x00\\x07\\x00\\x12\\x19\\x00' >/dev/ttymxc3"],
      );
    }catch(e){
      print(e);
    }finally{
      print("_getImuG1_03 : DONE");
    }
  }

  Future<int> getImuG1_04(Function updateState) async {
    print("_getImuG1_04 : START");
    try{
       process2 =
       await Process.run(
        plinkPath,
        ['-i', keyPath, 'root@192.168.12.1', '-hostkey', hostKey, "echo -en '\\xaa\\x55\\x00\\x00\\x09\\x00\\xff\\x57\\x09\\x68\\x01' >/dev/ttymxc3"],
      );
       return process2.exitCode;
    }catch(e){
      print(e);
      return process2.exitCode;
    }finally{
      print("_getImuG1_04 : DONE");
    }
  }

  Future<int> getImuG1_05(Function updateState) async {
    print("_getImuG1_05 : START");
    try{
      process3 =
      await Process.run(
        plinkPath,
        ['-i', keyPath, 'root@192.168.12.1', '-hostkey', hostKey, "stty -F /dev/ttymxc3 921600 raw -echo"], //
      );
      return process3.exitCode;
    }catch(e){
      print(e);
      return process3.exitCode;
    }finally{
      print("_getImuG1_05 : DONE");
    }
  }

  Future<int> getImuG1_06(Function updateState) async {
    print("_getImuG1_06 : START");
    try{
      process2 =
      await Process.run(
        plinkPath,
        ['-i', keyPath, 'root@192.168.12.1', '-hostkey', hostKey, "echo -en '\\xA5\\xA5\\x02\\x04\\x0A\\x02\\x01\\x00\\x5D\\xFB' >/dev/ttymxc3"],
      );
      StringBuffer outputBuffer = StringBuffer();
      process.stdout.transform(utf8.decoder).listen((data) async {
        outputBuffer.write(data);
        tempData = data;
        print("_getImuG1_02 : TEMPDATA \n$tempData");
      });
      return process2.exitCode;
          }catch(e){
      print(e);
      return process2.exitCode;
    }finally{
      print("_getImuG1_06 : DONE");
    }
  }

  Future<int> getImuG1_07(Function updateState) async {
    print("_getImuG1_07 : START");
    try{

      process2 =
      await Process.start(
          plinkPath,
          ['-i', keyPath, 'root@192.168.12.1', '-hostkey', hostKey, "echo -en '\\xA5\\xA5\\x01\\x02\\x06\\x00\\x53\\x2D' >/dev/ttymxc3"],
    );

      print("_getImuG1_07 DATA: START");
      return process2.exitCode;
    }catch(e){
      print(e);
      return process2.exitCode;
    }finally{
      print("_getImuG1_07 : DONE");
    }
  }

  Future<void> getImuG1_08(Function updateState) async {
    print("_getImuG1_08 : START");
    try{
      // var processedData = _processDataFromUnit(
      //     tempData); // process data
      // print(
      //     '== processedData ==\n$processedData');
      _getResultFromImuScan(updateState);
    }catch(e){
      print(e);
    }finally{
      deleteTempKeyFile();


      Future.delayed(Duration(seconds: 1), () async {
        await process.kill();
        await process2.kill();
        // await process3.kill();
       // _startUnit(updateState);
      });
      print("_getImuG1_08 : DONE");
    }
  }

/// END
}



