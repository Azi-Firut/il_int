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

class Production {
  static final Production _instance = Production._internal();

  factory Production() {
    return _instance;
  }

  Production._internal();

  String? unitNum;
  List<String> listContentTxt = [];
  Map<String, String> mapListContent = {};
  List<List<double>> lidarOffsetsList = [];
  List<List<double>> filtersList = [];
  String ssidFromFolderName = '';
  String ssidNumberFromFolderName = '';

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

  // Map output = {"IMU SN":"","Brand":"","Password":"","SSID default":"","SSID now":"","Receiver":"","Reciever SN":"","Firmware":"","Lidar: ":"","IMU Filter":""};
  //--
  var lidarSerialNumber = '';
  var lidarModel = '';
  var urlToLidar = 'http://192.168.12.1:8001/pandar.cgi?action=get&object=device_info'; // Ouster http://192.168.12.1:8001/config
  String xlsxPath = '';

  // Отправка команды приемнику
  Future<void> sendRecCommand(String command, updateState) async {
    print(command);
    if (await command.isEmpty) {
      pushUnitResponse(
          0, 'Enter the code in the top line', updateState: updateState);
      print('Команда не должна быть пустой');
      return;
    }
    String comm = 'auth $command';
    final url =
        'http://192.168.12.1/cgi-bin/settings?sendreceivercommand:${comm
        .toString()}';

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Cache-Control': 'no-cache',
          'Pragma': 'no-cache',
          'If-Modified-Since': 'Sat, 1 Jan 2000 00:00:00 GMT',
        },
      );

      if (response.statusCode == 200) {
        print('Команда успешно отправлена: $command');
        //print('Ответ сервера: ${response.body}');
        if (response.body.contains('<OK')) {
          pushUnitResponse(
              1, 'Codes installed successfully', updateState: updateState);
        } else {
          pushUnitResponse(2, response.body, updateState: updateState);
        }


        //getReceiverText(updateState);
      } else {
        print('Ошибка: ${response.statusCode}');
        //print('Ответ сервера: ${response.body}');
        pushUnitResponse(2, response.body, updateState: updateState);
      }
    } catch (e) {
      print('Ошибка при отправке команды: $e');
    }
  }

// // Получение текста от приемника
//   Future<void> getReceiverText(updateState) async {
//     const url = 'http://192.168.12.1/cgi-bin/settings?getreceivertext';
//
//     try {
//       final response = await http.get(
//         Uri.parse(url),
//         headers: {
//           'Cache-Control': 'no-cache',
//           'Pragma': 'no-cache',
//           'If-Modified-Since': 'Sat, 1 Jan 2000 00:00:00 GMT',
//         },
//       );
//
//       if (response.statusCode == 200) {
//         print('Получен текст от приемника: ${response.body}');
//         pushUnitResponse(1, response.body,updateState: updateState);
//       } else {
//         print('Ошибка: ${response.statusCode}');
//         print('Ответ сервера: ${response.body}');
//       }
//     } catch (e) {
//       print('Ошибка при получении текста: $e');
//     }
//   }

  /// FOLDER SEARCHER
  Future<String?> searchFolderInIsolate(SearchParams params) async {
    return compute(_searchFolder, params);
  }

  static Future<String?> _searchFolder(SearchParams params) async {
    try {
      final queue = <Directory>[params.dir];
      while (queue.isNotEmpty) {
        final currentDir = queue.removeAt(0);
        final List<FileSystemEntity> entities = currentDir.listSync();
        for (var entity in entities) {
          if (entity is Directory) {
            if (p.basename(entity.path).toLowerCase().contains(
                params.folderName.toLowerCase())) {
              return entity.path;
            }
            queue.add(entity);
          }
        }
      }
    } on FileSystemException catch (e) {
      print("Error during directory search: ${e.message}");
    } catch (e) {
      print("An error occurred: $e");
    }
    return null;
  }

  Future<String?> searchUserFolders(String folderName) async {
    List<Directory> searchDirs = [
      Directory('N:\\!Factory_calibrations_and_tests\\RESEPI\\'),
      Directory('N:\\Discrepancy_Reporting\\Quality Notices\\'),
    ];
    for (Directory dir in searchDirs) {
      String? folderPath = await searchFolderInIsolate(
          SearchParams(dir, folderName));
      if (folderPath != null) {
        return folderPath;
      }
    }
    return null;
  }

  Future<void> openFolder(String folderName, updateState) async {
    if (folderName.isEmpty) {
      pushUnitResponse(
          3, "Please enter a part of folder name", updateState: updateState);
      updateState();
      return;
    }
    pushUnitResponse(0, "Searching for the folder", updateState: updateState);
    updateState();
    String? folderPath = await searchUserFolders(folderName);
    pathToUnitFolder = folderPath;

    pushUnitResponse(1, "Folder opened successfully", updateState: updateState);
    updateState();
    if (folderPath == null) {
      folderPath = await searchFolderInIsolate(
          SearchParams(Directory('ftpPath'), folderName));
    }
    else if (folderPath != null) {
      var shell = Shell();
      try {
        await shell.run('explorer "${p.normalize(folderPath)}"');
      } catch (e) {

      }
    } else {
      pushUnitResponse(2, "Folder not found", updateState: updateState);
      updateState();
    }
  }

  /// FOLDER SEARCHER END
  bool checkUnitConnection(Function updateState) {
    bool connection;
    if (connectedSsid != '' && connectedSsid != "Not connected") {
      connection = true;
      print('== checkUnitConnection: Unit connected');
    } else {
      connection = false;
      pushUnitResponse(0, 'Unit is not connected', updateState: updateState);
      print('== checkUnitConnection: Unit is not connected');
    }
    return connection;
  }

  ///
  Future<void>runGhost(newSSiDname)async{
    print("runGhost == $newSSiDname");
    try{
      if (await createTempKeyFile()) {
        final shell = Shell();
        final result =
        await shell.run('''
         $plinkPath -i "$keyPath" -P 22 root@192.168.12.1 -hostkey "$hostKey" "mount -o remount,rw / && echo '${newSSiDname!.toUpperCase()}' > /etc/hostname && exit"
        ''');
        print(result.map((e) => e.stdout + e.stderr).join('\n'));
       //  pushUnitResponse(1,"SSID successfully updated",updateState:updateState);
        // updateState();
      }
    }
    catch(e){
      print("runGhost == $e");
    }
    finally{await deleteTempKeyFile();}
  }

  // Future<void> runGhost(String? newSSiDname) async {
  //   try {
  //     if (!await createTempKeyFile()) {
  //       print("Ошибка: createTempKeyFile() вернул false");
  //       return;
  //     }
  //     final ssid = newSSiDname?.toUpperCase() ?? '';
  //     try {
  //       var result = await Process.start(
  //         plinkPath,
  //         [
  //         '-i', keyPath,
  //         '-P', '22',
  //         'root@192.168.12.1',
  //         '-hostkey', hostKey,
  //         "mount -o remount,rw / && printf '%s' '${ssid}' > /etc/hostname && exit"
  //       ],);
  //      // print(result.map((e) => e.stdout).join('\n'));
  //     } catch (e, stackTrace) {
  //       print("Ошибка при выполнении команды: $e");
  //       print(stackTrace);
  //     }
  //
  //   } catch (e) {
  //     print("Ошибка в runGhost: $e");
  //     await deleteTempKeyFile();
  //   } finally {
  //     await deleteTempKeyFile();
  //   }
  // }


  Future<void> ultraLiteCamera(Function updateState) async {
    try {
      if (await createTempKeyFile() && checkUnitConnection(updateState)) {
        final shell = Shell();
        final result = await shell.run('''
        $plinkPath -i "$keyPath" -P 22 root@192.168.12.1 -hostkey "$hostKey" "mount -o remount,rw / && echo 'openmv' > /etc/payload/othercams && cat /etc/payload/othercams && exit"
      ''');

        print(result.map((e) => e.stdout + e.stderr).join('\n'));

        // Проверка успешного выполнения
        if (result.any((e) => e.stdout.contains('openmv'))) {
          print("Файл успешно создан и записан");
          pushUnitResponse(1, "Camera file created", updateState: updateState);
          // updateState();
        } else {
          pushUnitResponse(3, "Camera file FAIL", updateState: updateState);
          print("Ошибка: Файл не был создан или запись не удалась");
        }
      }
    } catch (e) {
      print("Ошибка в ultraLiteCamera: $e");
    } finally {
      await deleteTempKeyFile();
    }
  }

  /// ADD CUSTOM SSID
  Future<void> addCustomSSiD(newSSiDname, Function updateState) async {
    print('newSSiDname to ssid == $newSSiDname');
    final pass = ['\"\'"LidarAndINS"\'\"','\"\'"FLIGHTSscan"\'\"'];
    if (await newSSiDname
        .toString()
        .isNotEmpty) {
      //await deleteTempKeyFile();
      if (await createTempKeyFile() && checkUnitConnection(updateState)) {
        final shell = Shell();
        final name = '\"\'"$newSSiDname"\'\" #our_ssid';
        pushUnitResponse(0, "Procedure started", updateState: updateState);
        updateState();
        try {
          await shell.run('''
       ${plinkPath} -i "$keyPath" -P 22 root@192.168.12.1 -hostkey "$hostKey" "cd /etc/wpa_supplicant && mount -o remount,rw / && sed -i 's/^ssid=\".*\"/ssid=$name/' wpa_supplicant-wlan0.conf && exit"
        ''');
          if (await newSSiDname.toString().contains("RESEPI")){
            await shell.run('''
            ${plinkPath} -i "$keyPath" -P 22 root@192.168.12.1 -hostkey "$hostKey" "cd /etc/wpa_supplicant && mount -o remount,rw / && sed -i 's/^psk=\".*\"/psk=${pass[0]}/' wpa_supplicant-wlan0.conf && exit"
          ''');
          print('newSSiPass to pass == ${pass[0]}');
          }
          else if (await newSSiDname.toString().contains("FLIGHT")){
            await shell.run('''
            ${plinkPath} -i "$keyPath" -P 22 root@192.168.12.1 -hostkey "$hostKey" "cd /etc/wpa_supplicant && mount -o remount,rw / && sed -i 's/^psk=\".*\"/psk=${pass[1]}/' wpa_supplicant-wlan0.conf && exit"
          ''');
        print('newSSiPass to pass == ${pass[1]}');
      };
          print('newSSiDname to ssid == $newSSiDname');

          //    Future.delayed(Duration(seconds: 1), () async {
          //      process = await Process.start(
          //        plinkPath,
          //        [
          //          '-i', keyPath,
          //          'root@192.168.12.1',
          //          '-hostkey', hostKey,
          //          'sh', '-c',
          //          'mount -o remount,rw / && sed -i "1s/.*/$newSSiDname/" /etc/hostname && mount -o remount,ro /'
          //        ],
          //      );
          //    });

          pushUnitResponse(
              1, "SSID successfully updated", updateState: updateState);
          updateState();
        } catch (e) {
          print(e);
          pushUnitResponse(
              2, "Failed to update SSID:\ncheck all conditions before start",
              updateState: updateState);
          updateState();
        } finally {
          // process = await Process.start(
          //   plinkPath,
          //   [
          //     '-i', keyPath,
          //     'root@192.168.12.1',
          //     '-hostkey', hostKey,
          //     'sh', '-c',
          //     'mount -o remount,rw / && sed -i "1s/.*/$newSSiDname/" /etc/hostname && mount -o remount,ro /'
          //   ],
          // );

        //  await deleteTempKeyFile();
          await runGhost(newSSiDname);
        }
      } else {
        pushUnitResponse(2, "Procedure failed", updateState: updateState);
        deleteTempKeyFile();
        updateState();
      }
    } else {
      pushUnitResponse(
          3, "Add new SSID to top string", updateState: updateState);
      updateState();
    }
  }

  /// ADD CUSTOM SSID END

  /// ATC GENERATOR
  var _address;
  var dateToday;

  void generateAtc(address, updateState) async {
    listContentTxt = [];
    mapListContent = {};
    lidarOffsetsList = [];
    filtersList = [];
    _address = await address;

    print('========================= parseFolder');
    appDirectory = Directory.current.path;
    print('Il_int work directory => $appDirectory');

    print('addres to folder => $appDirectory');
    unitNum = p
        .basename(_address)
        .split('_')
        .last;
    Directory dir = Directory(_address);
    File? targetTxtFile;
    await for (var entity in dir.list()) {
      if (entity is File &&
          entity.path.contains(unitNum!) &&
          entity.path.endsWith('.txt')) {
        targetTxtFile = entity;
        break;
      }
    }
    if (targetTxtFile != null) {
      // Parse PPK files
      await parsePpkFiles(_address); // ==> 2

      List<String> lines = await targetTxtFile.readAsLines();
      listContentTxt = lines.map((line) {
        int colonIndex = line.indexOf(':');
        return colonIndex != -1 ? line.substring(colonIndex + 1).trim() : line;
      }).toList();
      dateToday = DateTime.now();

      print('List strings from Readme.txt => $listContentTxt');
      print('List strings from Readme.txt => ${targetTxtFile.parent.path}');


      // await Future.delayed(Duration(seconds: 1), () async {});

      /// Generator xlsx

      if (lidarOffsetsList.length < 50) {
        print("lidarOffsetsList.length == ${lidarOffsetsList.length}");
        final fetchDataBase = await getIMUcalVAl(listContentTxt[5]);
        // print('=================== Fetch data final:\n ${fetchDataBase.runtimeType}');
        await generateExcel32(
            targetTxtFile.parent.path,
            _address,
            listContentTxt,
            lidarOffsetsList,
            appDirectory,
            dateToday,
            ssidFromFolderName,
            ssidNumberFromFolderName,
            fetchDataBase);
      } else if (lidarOffsetsList.length > 50) {
        print("lidarOffsetsList.length == ${lidarOffsetsList.length}");
        final fetchDataBase = await getIMUcalVAl(listContentTxt[5]);
        // print('=================== Fetch data final:\n ${fetchDataBase.runtimeType}');
        await generateExcel64(
            targetTxtFile.parent.path,
            _address,
            listContentTxt,
            lidarOffsetsList,
            appDirectory,
            dateToday,
            ssidFromFolderName,
            ssidNumberFromFolderName,
            fetchDataBase);
      }
      pushUnitResponse(
          0, "ATC_${listContentTxt[0]}-${listContentTxt[1]}.xlsx Created",
          updateState: updateState);

      xlsxPath = '${targetTxtFile.parent
          .path}/ATC_${listContentTxt[0]}-${listContentTxt[1]}.xlsx';

      await runPythonScript(xlsxPath, updateState);
    } else {
      print('Text file not found.');
      pushUnitResponse(
          3, "No data found, enter the unit number", updateState: updateState);
      updateState();
    }
  }


  Future<void> runPythonScript(String xlsxPath, updateState) async {
    print('runPythonScript jsonData\n ${xlsxPath}');

    String pythonScriptPath = 'data/flutter_assets/assets/xlsx_to_pdf.exe';
    try {
      var result = await Process.run(pythonScriptPath, [xlsxPath]);
      if (result.exitCode == 0) {
        print('Python script executed successfully.');
        print('Output: ${result.stdout}');
        pushUnitResponse(
            1, "ATC_${listContentTxt[0]}-${listContentTxt[1]}.pdf Created",
            updateState: updateState);

        /// Zip
        if (zip) {
          zipCompress(bDir.path.toString(), bAdr.toString(), updateState);
          pushUnitResponse(0,
              "ATC_${listContentTxt[0]}-${listContentTxt[1]}.pdf Created\nCreating ZIP file started",
              updateState: updateState);
        }

        /// Zip end
        updateState();
      } else {
        print('Python script execution failed.');
        print('Error: ${result.stderr}');
        pushUnitResponse(
            2, "Error:\n${result.stderr}", updateState: updateState);
        updateState();
      }
    } catch (e) {
      print('Error running Python script: $e');
    }
  }

  /// 2
  Future<void> parsePpkFiles(String baseAddress) async {
    print('== 2 parsePpkFiles');
    Directory boresightDir = Directory(p.join(baseAddress, 'Boresight\\'));
    print('== 2 parsePpkFiles boresight dir => $boresightDir');
    bDir = boresightDir;
    bAdr = baseAddress;
    if (await boresightDir.exists()) {
      // /// Zip
      // print("000000 ${boresightDir.path}\n000000 ${baseAddress}");
      // zipCompress(boresightDir.path.toString(),baseAddress.toString());
      // /// Zip end
      await for (var entity in boresightDir.list(recursive: false)) {
        print('== 2 $entity');
        if (entity is Directory) {
          List<List<double>> combinedList = [];

          await for (var subEntity in entity.list(recursive: false)) {
            print('== 2 $subEntity');

            if (subEntity is File && p.basename(subEntity.path) == 'ppk.pcmp') {
              print('Processing file: ${subEntity.path}');
              // Parse the `ppk` file content here
              List<String> offsets = await extractTagContent(
                  subEntity, 'Offsets');
              lidarOffsetsList = await parseTagContent(offsets);

              List<String> filters = await extractTagContent(
                  subEntity, 'Filters');
              filtersList = await parseTagContent(filters);

              combinedList = [...lidarOffsetsList, ...filtersList];

              /// get SSiD from folder name
              String directoryName = p.basename(subEntity.parent.path);
              RegExp regExp = RegExp(r'^[^-]+-[^-]+');
              ssidFromFolderName = regExp.stringMatch(directoryName) ?? '';
              ssidNumberFromFolderName = ssidFromFolderName.split('-')[1];

              print("SSiD from folder name $ssidFromFolderName");
              print("SSiD number from folder name $ssidNumberFromFolderName");
              //
              print("SUBENTITY ${p.basename(subEntity.parent.path)}");
              print("SUBENTITY ${subEntity.path}");
              print('Offsets: $lidarOffsetsList');
              print('Offsets length: ${lidarOffsetsList.length}');
              print('Filters: $filtersList');
              print('Combined: $combinedList');
            }
          }

          // Process ppk.pcpp files after ppk.pcmp files
          await for (var subEntity in entity.list(recursive: false)) {
            if (subEntity is File && p.basename(subEntity.path) == 'ppk.pcpp') {
              print('Processing file: ${subEntity.path}');

              // Parse the `ppk` file content here
              List<String> offsets = await extractTagContent(
                  subEntity, 'Offsets');
              List<List<double>> newOffsets = await parseTagContent(offsets);

              lidarOffsetsList.addAll(newOffsets);
              combinedList.addAll(newOffsets);

              // print('Offsets: $lidarOffsetsList');
              print('Offsets length: ${lidarOffsetsList.length}');
              print('Combined: $combinedList');
            }
          }
          // Parse the Service.log file
          // await for (var subEntity in entity.list(recursive: false)) {
          //   if (subEntity is File && p.basename(subEntity.path) == 'service.log') {
          //     Map<String, String> serviceLogData = await parseServiceLog(subEntity);
          //     print('Service log data: $serviceLogData');
          //   }
          // }

        }
      }
    } else {
      print('Boresight directory not found.');
    }
  }

  ///
  Future<Map<String, String>> parseServiceLog(File file) async {
    Map<String, String> logData = {};
    List<String> lines = await file.readAsLines();
    for (String line in lines) {
      int colonIndex = line.indexOf(':');
      if (colonIndex != -1) {
        String value = line.substring(colonIndex + 1).trim();
        logData[line] = value;
      }
      print(logData);
    }
    return logData;
  }

  /// 4
  Future<List<String>> extractTagContent(File file, String tagName) async {
    List<String> tagContent = [];
    List<String> lines = await file.readAsLines();
    bool isTagSection = false;
    for (String line in lines) {
      if (line.contains('<$tagName')) {
        isTagSection = true;
      } else if (line.contains('</$tagName>')) {
        isTagSection = false;
      } else if (isTagSection) {
        tagContent.add(line.trim());
      }
    }
    return tagContent;
  }

  /// 3
  List<List<double>> parseTagContent(List<String> content) {
    List<List<double>> result = [];
    for (String item in content) {
      RegExp regExp = RegExp(r'[-+]?[0-9]*\.?[0-9]+');
      Iterable<Match> matches = regExp.allMatches(item);
      List<double> values = matches.map((match) =>
          double.parse(match.group(0)!)).toList();
      result.add(values);
    }
    return result;
  }

  /// ATC GENERATOR END

  /// Restart unit
  Future<void> restartUnit() async {
    if (await createTempKeyFile()) {
      print('Рестарт');
      // pushUnitResponse(1,"Final parameters uploaded\nThe unit will be rebooted",updateState);

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
    lidarSerialNumber = '';
    lidarModel = '';
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
      print("jsonMap === $jsonMap");
      lidarSerialNumber = jsonMap['Body']['SN'];
      lidarModel = jsonMap['Body']['Model'];
      if (jsonMap['Body']['Model'] == 'Pandar_ZYNQ') {
        lidarModel = "Hesai XT32";
        jsonMap['Body']['Model'] = 'Hesai XT32';
      }

      unitInfo[2] = "${jsonMap['Body']['Model']} ${jsonMap['Body']['SN']}";
      updateState();
    } catch (e) {
      stringFromLidar = 'Error: $e';
    }
  }

  /// GET LIDAR SN END

  /// GET UNIT INFO

  Future<void> getDeviceInfo(Function updateState) async {
    if (await createTempKeyFile() && checkUnitConnection(updateState)) {
      final shell = Shell();
      output = {
        "IMU SN: ": "",
        "Brand: ": "",
        "Password: ": "",
        "SSID default: ": "",
        "SSID now: ": "",
        "Receiver: ": "",
        "Reciever SN: ": "",
        "Firmware: ": "",
        "Lidar: ": "",
        "IMU Filter: ": ""
      };
      print(output);
      pushUnitResponse(0, output.entries
          .map((entry) => "${entry.key}${entry.value}")
          .join('\n'), updateState: updateState);
      try {
        // Получаем IMU
        output["IMU SN: "] = "${imuNumber}";
        unitInfo[1] = imuNumber;
        // Получаем Lidar SN
        await getLidarSn(updateState);

        // Информация по бренду
        var brandNow = await shell.run('''
        ${plinkPath} -i "$keyPath" -P 22 root@192.168.12.1 -hostkey "$hostKey" "cat /etc/brand"
      ''');
        output["Brand: "] = "${brandNow.outText}";
        unitInfo[0] = brandNow.outText;
        // Пароль
        var passphraseNow = await shell.run('''
        ${plinkPath} -i "$keyPath" -P 22 root@192.168.12.1 -hostkey "$hostKey" "cat /etc/passphrase"
      ''');
        output["Password: "] = "${passphraseNow.outText}";

        // SSID по умолчанию
        var ssidDef = await shell.run('''
        ${plinkPath} -i "$keyPath" -P 22 root@192.168.12.1 -hostkey "$hostKey" "grep '^ssid=' /etc/wpa_supplicant/wpa_supplicant-default.conf | sed 's/^ssid=//' && exit"
      ''');
//         var ssidDef = await shell.run('''
//   ${plinkPath} -i "$keyPath" -P 22 root@192.168.12.1 -hostkey "$hostKey" /etc/hostname"
// ''');
        output["SSID default: "] = "${ssidDef.outText
            .split(' ')
            .first
            .replaceAll('"', '')}";

        // Текущий SSID
        var ssidNow = await shell.run('''
        ${plinkPath} -i "$keyPath" -P 22 root@192.168.12.1 -hostkey "$hostKey" "grep '^ssid=' /etc/wpa_supplicant/wpa_supplicant-wlan0.conf | sed 's/^ssid=//' && exit"
      ''');
        output["SSID now: "] = "${ssidNow.outText
            .split(' ')
            .first
            .replaceAll('"', '')}";

        // Информация о ресивере
        var receiverNow = await shell.run('''
        ${plinkPath} -i "$keyPath" -P 22 root@192.168.12.1 -hostkey "$hostKey" "grep 'Kernel receiver model =' /var/volatile/payload.log | sed 's/^.*Kernel receiver model = //' && exit"
      ''');

        List<String> parts = receiverNow.outText.split(' ');
        unitInfo[3] = "${parts[0]} ${parts[1]} ${parts.last}";
        print('receiver parts ===\n$parts');
        print('receiver code ===\n${parts[2]}');
        var codeCheck = '';
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
        output["Reciever SN: "] = "${receiverNow.outText
            .split(' ')
            .last}";

        // Прошивка
        var firmwareNow = await shell.run('''
        ${plinkPath} -i "$keyPath" -P 22 root@192.168.12.1 -hostkey "$hostKey" "head -n 1 /etc/release_notes"
      ''');
        output["Firmware: "] = "${firmwareNow.outText}";
        output["IMU Filter: "] = "${imuFilter}";

        output["Lidar: "] = "$lidarModel $lidarSerialNumber";
        // unitInfo[2]=lidarSerialNumber;

      } catch (e) {
        pushUnitResponse(2, "Fail: check all conditions before start",
            updateState: updateState);
      } finally {
        await deleteTempKeyFile();
      }

      // Обновляем состояние только после завершения всей операции
      pushUnitResponse(1, output.entries
          .map((entry) => "${entry.key}${entry.value}")
          .join('\n'), updateState: updateState);
      runGetUnitImu(updateState);
      updateState();
    } else {
      pushUnitResponse(2, "Procedure failed", updateState: updateState);
      updateState();
    }
  }

  /// GET IMU NUMBER (PART OF UNIT INFO)


  Future<void> formatUsb(updateState) async {
    pushUnitResponse(0, "Formatting started", updateState: updateState);

    final url = Uri.parse('http://192.168.12.1:/cgi-bin/usb-format');
    final urlhdd = Uri.parse('http://192.168.12.1:/cgi-bin/data-format');
    try {

      final response = await http.get(url);

      var error = response.statusCode == 200
          ? response.body
          : 'Error: ${response.statusCode}';
      pushUnitResponse(2,
          'Error: There is no connection to the unit or there is no USB drive',
          updateState: updateState);
      responseUsb(updateState);
      final responsehdd = await http.get(urlhdd);
    } catch (e) {
      pushUnitResponse(2,
          'Error: There is no connection to the unit or there is no USB drive',
          updateState: updateState);
    }
    finally {
      updateState();
    }
  }

  Future<void> responseUsb(updateState) async {
    final url = Uri.parse('http://192.168.12.1:/cgi-bin/usb-status');
    try {
      final response = await http.get(url);
      print(response
          .toString()
          .length);
      var error = response.statusCode == 200
          ? response.body
          : 'Error: ${response.statusCode}';
      pushUnitResponse(2,
          'Error: There is no connection to the unit or there is no USB drive',
          updateState: updateState);
      if (response
          .toString()
          .length > 15) {
        pushUnitResponse(1, "Formatting complete", updateState: updateState);
      }
    } catch (e) {
      pushUnitResponse(2,
          'Error: There is no connection to the unit or there is no USB drive',
          updateState: updateState);
    }
    finally {
      updateState();
    }
  }

  runGetUnitImu(updateState) async {
    print("RUN GET UNIT IMU");
    counter = 5;
    output["IMU Filter: "] = "Searching";
    output["IMU SN: "] = "Searching";

    pushUnitResponse(1, output.entries
        .map((entry) => "${entry.key}${entry.value}")
        .join('\n'), updateState: updateState);
    if (await fetchTitle() == "RESEPI GEN-II" ||
        await fetchTitle() == "FLIGHTS GEN-II") {
      getImuGen2(updateState);
      print('SWITCH TO GEN2 UMU SEARCH');
    } else {
      getImu(updateState);
    }
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
          [
            '-i',
            keyPath,
            'root@192.168.12.1',
            '-hostkey',
            hostKey,
            "systemctl start payload"
          ],
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

  /// GEN2
  Future<void> getImuGen2(Function updateState) async {
    tempData = "";
    process = null;
    process2 = null;

    if (counter == 0) {
      output["IMU Filter: "] = "Not identified";
      output["IMU SN: "] = "Not identified";
      pushUnitResponse(3, output.entries
          .map((entry) => "${entry.key}${entry.value}")
          .join('\n'), updateState: updateState);
    }
    else if (counter != 0) {
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
                [
                  '-i',
                  keyPath,
                  'root@192.168.12.1',
                  '-hostkey',
                  hostKey,
                  "echo -en '\\xaa\\x55\\x00\\x00\\x07\\x00\\xfe\\x05\\x01' >/dev/ttyLP3"
                ],
              );

              print("GET IMU GEN2 STARTED part 2 (call for imu number)  ");
              Future.delayed(Duration(seconds: 2), () async {
                process2 = await Process.start(
                    plinkPath,
                    [
                      '-i',
                      keyPath,
                      'root@192.168.12.1',
                      '-hostkey',
                      hostKey,
                      "echo -en '\\xaa\\x55\\x00\\x00\\x07\\x00\\x12\\x19\\x00' >/dev/ttyLP3"
                    ]);
                process2 = await Process.start(
                    plinkPath,
                    [
                      '-i',
                      keyPath,
                      'root@192.168.12.1',
                      '-hostkey',
                      hostKey,
                      "echo -en '\\xaa\\x55\\x00\\x00\\x07\\x00\\x12\\x19\\x00' >/dev/ttyLP3"
                    ]);
                process2 = await Process.start(
                    plinkPath,
                    [
                      '-i',
                      keyPath,
                      'root@192.168.12.1',
                      '-hostkey',
                      hostKey,
                      "echo -en '\\xaa\\x55\\x00\\x00\\x07\\x00\\x12\\x19\\x00' >/dev/ttyLP3"
                    ]);
                process2 = await Process.start(
                    plinkPath,
                    [
                      '-i',
                      keyPath,
                      'root@192.168.12.1',
                      '-hostkey',
                      hostKey,
                      "echo -en '\\xaa\\x55\\x00\\x00\\x07\\x00\\x12\\x19\\x00' >/dev/ttyLP3"
                    ]);
                process2 = await Process.start(
                    plinkPath,
                    [
                      '-i',
                      keyPath,
                      'root@192.168.12.1',
                      '-hostkey',
                      hostKey,
                      "echo -en '\\xaa\\x55\\x00\\x00\\x07\\x00\\x12\\x19\\x00' >/dev/ttyLP3"
                    ]);
              });

              Future.delayed(Duration(seconds: 3), () async {
                process.kill();
                process2.kill();
                deleteTempKeyFile();
                print(
                    "GET IMU GEN2 STARTED part 2 (call for imu number) ====\n $tempData ");
                print(
                    "GET IMU GEN2 STARTED part 2 (call for imu number) ====\n ${tempData
                        .length} ");
                getResultFromImuScanGen2(updateState);
              });
            });
          } else {
            output["IMU Filter: "] = "Unit is not connected";
            output["IMU SN: "] = "Unit is not connected";

            pushUnitResponse(3, output.entries
                .map((entry) => "${entry.key}${entry.value}")
                .join('\n'), updateState: updateState);
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
    print('================== 760 result ==================== \n${tempData}');
    String result = _processUnitResponse(tempData)
        .replaceAll('\n', '')
        .replaceAll(' ', '');
    print('================== 762 result ==================== \n${result}');

    RegExp regExpSN = RegExp(r'\.{10,}([A-Za-z0-9]*\d{4,})');
    Match? matchSn = regExpSN.firstMatch(result.toString());

    if (matchSn == null || matchSn
        .group(1)!
        .toString()
        .length < 5 && counter != 0) {
      print('==================  768 Номер не найден  ================= ');
      output["IMU Filter: "] =
      "No result, I\'ll try again ${counter - 1} times";
      output["IMU SN: "] = "No result, I\'ll try again ";

      pushUnitResponse(1, output.entries
          .map((entry) => "${entry.key}${entry.value}")
          .join('\n'), updateState: updateState);

      decrementCounter(updateState);
      await runUnit(updateState);

      Future.delayed(Duration(seconds: 3), () async {
        await getImuGen2(updateState);
        print('==== $counter');
        updateState();
      });
    } else if (counter == 0) {
      print('============ Counter 0 = $counter');
      output["IMU Filter: "] = "Unit is not identified";
      output["IMU SN: "] = "Unit is not identified";

      pushUnitResponse(1, output.entries
          .map((entry) => "${entry.key}${entry.value}")
          .join('\n'), updateState: updateState);
      updateState();

      await deleteTempKeyFile();
      await runUnit(updateState);
    } else if (matchSn != null && counter != 0) { // Выводим найденные номера
      print('Найден номер: ${matchSn.group(1)}');
      String number = matchSn.group(1)!;
      output["IMU SN: "] = number;
      output["IMU Filter: "] = "I didn't even look";
      unitInfo[1] = number.toString();
      pushUnitResponse(1, output.entries
          .map((entry) => "${entry.key}${entry.value}")
          .join('\n'), updateState: updateState);
      updateState();
      print('Найден номер IMU : $number');
      await runUnit(updateState);
      // Получаем номер
      if (RegExp(r'[A-Za-z]$').hasMatch(
          number)) { // Проверяем, если последний символ - буква, удаляем его
        number = number.substring(0, number.length -
            1); // Проверяем, заканчивается ли строка на букву с помощью регулярного выражения
        output["IMU SN: "] = number;
        output["IMU Filter: "] = "I didn't even look";
        unitInfo[1] = number.toString();
        pushUnitResponse(1, output.entries
            .map((entry) => "${entry.key}${entry.value}")
            .join('\n'), updateState: updateState);
        updateState();
        print('Найден номер IMU 2: ${number}');
        await runUnit(updateState);
        updateState();
      }
      updateState();
    }
    await deleteTempKeyFile();
  }

  /// GEN1
  Future<void> getImu(Function updateState) async {
    tempData = "";
    process2 = null;
    process3 = null;
    process4 = null;
    process = null;

    if (counter == 0) {
      output["IMU Filter: "] = "Not identified";
      output["IMU SN: "] = "Not identified";
      pushUnitResponse(3, output.entries
          .map((entry) => "${entry.key}${entry.value}")
          .join('\n'), updateState: updateState);
    }
    else if (counter != 0) {
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
            if (exitCode == 0) {
              print("GET IMU STARTED part 2  ");

              Future.delayed(Duration(seconds: 2), () async {
                /// Imu 210
                process2 = await Process.start(
                  plinkPath,
                  [
                    '-i',
                    keyPath,
                    'root@192.168.12.1',
                    '-hostkey',
                    hostKey,
                    "echo -en '\\xaa\\x55\\x00\\x00\\x07\\x00\\xfe\\x05\\x01' >/dev/ttymxc3"
                  ],
                );
                process2 = await Process.start(
                  plinkPath,
                  [
                    '-i',
                    keyPath,
                    'root@192.168.12.1',
                    '-hostkey',
                    hostKey,
                    "echo -en '\\xaa\\x55\\x00\\x00\\x07\\x00\\x12\\x19\\x00' >/dev/ttymxc3"
                  ],
                );

                ///
                process2 = await Process.start(
                  plinkPath,
                  [
                    '-i',
                    keyPath,
                    'root@192.168.12.1',
                    '-hostkey',
                    hostKey,
                    "echo -en '\\xaa\\x55\\x00\\x00\\x09\\x00\\xff\\x57\\x09\\x68\\x01' >/dev/ttymxc3"
                  ],
                );
              });
              Future.delayed(Duration(seconds: 3), () async {
                process2 = await Process.start(
                  plinkPath,
                  [
                    '-i',
                    keyPath,
                    'root@192.168.12.1',
                    '-hostkey',
                    hostKey,
                    "stty -F /dev/ttymxc3 921600"
                  ],
                );
              });
              Future.delayed(Duration(seconds: 4), () async {
                process2 = await Process.start(
                  plinkPath,
                  [
                    '-i',
                    keyPath,
                    'root@192.168.12.1',
                    '-hostkey',
                    hostKey,
                    "echo -en '\\xA5\\xA5\\x02\\x04\\x0A\\x02\\x01\\x00\\x5D\\xFB' >/dev/ttymxc3"
                  ],
                );
                print("GET IMU STARTED part 2 (stop traffic)  ");

                int exitCode = await process2.exitCode;

                if (exitCode == 0) {
                  print("GET IMU STARTED part 2 (call for imu number)  ");

                  process2 = await Process.start(
                      plinkPath,
                      [
                        '-i',
                        keyPath,
                        'root@192.168.12.1',
                        '-hostkey',
                        hostKey,
                        "echo -en '\\xA5\\xA5\\x01\\x02\\x06\\x00\\x53\\x2D' >/dev/ttymxc3"
                      ]);
                  process2 = await Process.start(
                      plinkPath,
                      [
                        '-i',
                        keyPath,
                        'root@192.168.12.1',
                        '-hostkey',
                        hostKey,
                        "echo -en '\\xA5\\xA5\\x01\\x02\\x06\\x00\\x53\\x2D' >/dev/ttymxc3"
                      ]);
                  process3 = await Process.start(
                      plinkPath,
                      [
                        '-i',
                        keyPath,
                        'root@192.168.12.1',
                        '-hostkey',
                        hostKey,
                        "echo -en '\\xA5\\xA5\\x01\\x02\\x06\\x00\\x53\\x2D' >/dev/ttymxc3"
                      ]);
                  process3 = await Process.start(
                      plinkPath,
                      [
                        '-i',
                        keyPath,
                        'root@192.168.12.1',
                        '-hostkey',
                        hostKey,
                        "echo -en '\\xA5\\xA5\\x01\\x02\\x06\\x00\\x53\\x2D' >/dev/ttymxc3"
                      ]);
                  process4 = await Process.start(
                      plinkPath,
                      [
                        '-i',
                        keyPath,
                        'root@192.168.12.1',
                        '-hostkey',
                        hostKey,
                        "echo -en '\\xA5\\xA5\\x01\\x02\\x06\\x00\\x53\\x2D' >/dev/ttymxc3"
                      ]);
                  process4 = await Process.start(
                      plinkPath,
                      [
                        '-i',
                        keyPath,
                        'root@192.168.12.1',
                        '-hostkey',
                        hostKey,
                        "echo -en '\\xA5\\xA5\\x01\\x02\\x06\\x00\\x53\\x2D' >/dev/ttymxc3"
                      ]);
                  process4 = await Process.start(
                      plinkPath,
                      [
                        '-i',
                        keyPath,
                        'root@192.168.12.1',
                        '-hostkey',
                        hostKey,
                        "echo -en '\\xA5\\xA5\\x01\\x02\\x06\\x00\\x53\\x2D' >/dev/ttymxc3"
                      ]);
                  /////
                  process2 = await Process.start(
                      plinkPath,
                      [
                        '-i',
                        keyPath,
                        'root@192.168.12.1',
                        '-hostkey',
                        hostKey,
                        "echo -en '\\xA5\\xA5\\x02\\x03\\x03\\x01\\x02\\x55\\x84' >/dev/ttymxc3"
                      ]);
                  process2 = await Process.start(
                      plinkPath,
                      [
                        '-i',
                        keyPath,
                        'root@192.168.12.1',
                        '-hostkey',
                        hostKey,
                        "echo -en '\\xA5\\xA5\\x02\\x03\\x03\\x01\\x02\\x55\\x84' >/dev/ttymxc3"
                      ]);
                  process2 = await Process.start(
                      plinkPath,
                      [
                        '-i',
                        keyPath,
                        'root@192.168.12.1',
                        '-hostkey',
                        hostKey,
                        "echo -en '\\xA5\\xA5\\x02\\x03\\x03\\x01\\x02\\x55\\x84' >/dev/ttymxc3"
                      ]);
                  process2 = await Process.start(
                      plinkPath,
                      [
                        '-i',
                        keyPath,
                        'root@192.168.12.1',
                        '-hostkey',
                        hostKey,
                        "echo -en '\\xA5\\xA5\\x02\\x03\\x03\\x01\\x02\\x55\\x84' >/dev/ttymxc3"
                      ]);

                  int exitCode2 = await process2.exitCode;
                  int exitCode4 = await process4.exitCode;

                  if (exitCode2 == 0 && exitCode4 == 0) {
                    getResultFromImuScan(updateState);
                    await deleteTempKeyFile();
                    await process2.kill();
                    await process3.kill();
                    await process4.kill();
                    await process.kill();
                  } else {
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

            pushUnitResponse(3, output.entries
                .map((entry) => "${entry.key}${entry.value}")
                .join('\n'), updateState: updateState);
            //pushUnitResponse(3,"Unit is not connected",updateState);
            await deleteTempKeyFile();
            print('Command failed with exit code: $exitCode');
            //// restart!!
          }
        } finally {}
      } else {}
    }
  }


  getResultFromImuScan(updateState) async {
    // await deleteTempKeyFile();
    print('================== 305 result ==================== \n${tempData}');
    String result = _processUnitResponse(tempData)
        .replaceAll('\n', '')
        .replaceAll(' ', '');
    print('================== 307 result ==================== \n${result}');

    String stringBytes = tempData
        .replaceAllMapped(
        RegExp(r'^\S+\s+([\da-fA-F\s]+)\s+\|.*\|$', multiLine: true), (match) {
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
          pushUnitResponse(1, output.entries
              .map((entry) => "${entry.key}${entry.value}")
              .join('\n'), updateState: updateState);
          updateState();
        }
        if (bytes[i + 2] != '00') {
          output["IMU Filter: "] = "Wrong";
          pushUnitResponse(1, output.entries
              .map((entry) => "${entry.key}${entry.value}")
              .join('\n'), updateState: updateState);
          print('Найдено: 83 01 - следующее не 00');
          updateState();
        }
      }
      updateState();
    }

    // RegExp regExp = RegExp(r'\.([A-Za-z0-9]{5,})\.');// Регулярное выражение для поиска номеров из букв и цифр длиной не менее 5 символов
    // RegExpMatch? match = regExp.firstMatch(result);// Ищем все совпадения

    RegExp regExp = RegExp(r'\.{10,}([A-Za-z0-9]*\d{4,})');
    Match? match = regExp.firstMatch(result.toString());

    print(
        '================== 338  Выводим найденные номера  =======\n${match}');

    if (match == null || match
        .group(1)!
        .toString()
        .length < 5 && counter != 0) {
      print('==================  340 Номер не найден  ================= ');
      output["IMU Filter: "] =
      "No result, I\'ll try again ${counter - 1} times";
      output["IMU SN: "] = "No result, I\'ll try again ";

      pushUnitResponse(1, output.entries
          .map((entry) => "${entry.key}${entry.value}")
          .join('\n'), updateState: updateState);

      decrementCounter(updateState);
      await runUnit(updateState);

      Future.delayed(Duration(seconds: 3), () async {
        await getImu(updateState);
        print('==== $counter');
        updateState();
      });
    } else if (counter == 0) {
      print('============ Counter 0 = $counter');
      output["IMU Filter: "] = "Unit is not identified";
      output["IMU SN: "] = "Unit is not identified";

      pushUnitResponse(1, output.entries
          .map((entry) => "${entry.key}${entry.value}")
          .join('\n'), updateState: updateState);
      updateState();
      //pushUnitResponse(2,"Not all data collected, please reboot the unit",updateState);
      await deleteTempKeyFile();
      await runUnit(updateState);
    } else if (match != null && counter != 0) { // Выводим найденные номера
      print('Найден номер: ${match.group(1)}');
      String number = match.group(1)!;
      output["IMU SN: "] = "${number}";
      unitInfo[1] = number.toString();
      pushUnitResponse(1, output.entries
          .map((entry) => "${entry.key}${entry.value}")
          .join('\n'), updateState: updateState);
      updateState();
      print('Найден номер IMU 1: ${number}');
      // await getDeviceInfo(updateState);
      await runUnit(updateState);
      // Получаем номер
      if (RegExp(r'[A-Za-z]$').hasMatch(
          number)) { // Проверяем, если последний символ - буква, удаляем его
        number = number.substring(0, number.length -
            1); // Проверяем, заканчивается ли строка на букву с помощью регулярного выражения
        output["IMU SN: "] = "${number}";
        unitInfo[1] = number.toString();
        pushUnitResponse(1, output.entries
            .map((entry) => "${entry.key}${entry.value}")
            .join('\n'), updateState: updateState);
        updateState();
        print('Найден номер IMU 2: ${number}');
        // await getDeviceInfo(updateState);
        await runUnit(updateState);
        updateState();
      }
      updateState();
    }
    await deleteTempKeyFile();
    print('Last --- \n${tempData.length > 1000 ? tempData.substring(
        tempData.length - 1000) : tempData}');
  }

  /// GET IMU NUMBER (PART OF UNIT INFO) END

  /// GET UNIT INFO END


  /// UPLOAD CALIBRATION TO UNIT
  ///
  String host = "";

  Future<void> uploadCalibration(Function updateState) async {
    if (await createTempKeyFile()) {
      final shell = Shell();
      pushUnitResponse(0, "Procedure started", updateState: updateState);
      updateState();

      if (await fetchTitle() == "RESEPI GEN-II" ||
          await fetchTitle() == "FLIGHTS GEN-II") {
        host = keyGen2[1];
      } else {
        host = keyGen1[1];
      }

      // String output = "";
      try {
        const calibrationLaserPath = 'temp/boresight';
        const calibrationCameraPath = 'temp/cameras';

        await shell.run('''
        ${plinkPath} -i "$keyPath" -P 22 root@192.168.12.1 -hostkey "$hostKey" "mount -o remount,rw / && echo 'OPEN TO EDIT' > /etc/payload/boresight && exit"
        ''');

        await shell.run('''
        ${plinkPath} -i "$keyPath" -P 22 root@192.168.12.1 -hostkey "$hostKey" "cat /etc/payload/boresight"
        ''');


        await shell.run(
            '''${pscpPath} -batch -hostkey "$host" -i "$keyPath" -P 22 "$calibrationLaserPath" root@192.168.12.1:/etc/payload/boresight''');
        await shell.run(
            '''${pscpPath} -batch -hostkey "$host" -i "$keyPath" -P 22 "$calibrationCameraPath" root@192.168.12.1:/etc/payload/cameras''');

        //  await shell.run('''${pscpPath} -batch -i "$keyPath" -P 22 "$calibrationLaserPath" root@192.168.12.1:/etc/payload/boresight''');
        //  await shell.run('''${pscpPath} -i "$keyPath" -P 22 "$calibrationCameraPath" root@192.168.12.1:/etc/payload/cameras''');

        pushUnitResponse(
            1, "Boresight file copied successfully", updateState: updateState);
        shell.kill();
      } catch (e) {
        pushUnitResponse(2,
            "Failed to copy calibration file: check all conditions before start",
            updateState: updateState);
      } finally {
        await deleteTempKeyFile();
      }
    } else {
      pushUnitResponse(2, "Procedure failed", updateState: updateState);
    }
    updateState();
  }

  Future<void> runCreatePreUploadLaserBoresightFile(_unitFolder,
      updateState) async {
    print("=========== unit folder $_unitFolder");

    await parseBoresight(_unitFolder);
    pushUnitResponse(0, "Searching data files", updateState: updateState);
    if (_unitFolder == "N:\\!Factory_calibrations_and_tests\\RESEPI\\") {
      pushUnitResponse(3, "Enter Unit SN", updateState: updateState);
      updateState();
    }

    // Чтение содержимого ppk.pcmp
    final pcmpFileContent = File('${pathToPPK.path}\/ppk.pcmp')
        .readAsStringSync();

    // Проверяем, существует ли файл ppk.pcpp
    String pcppFileContent = "";
    if (File('${pathToPPK.path}\/ppk.pcpp').existsSync()) {
      pcppFileContent = File('${pathToPPK.path}\/ppk.pcpp').readAsStringSync();
      // Извлечение данных камер
      final cameraOffsetsData = extractCameraData(pcppFileContent);
      // Создание файла cameras
      await createCameraFile(
          '${Directory.current.path}\\temp\\cameras', cameraOffsetsData);
    } else {
      print("File ppk.pcpp not found. Skipping camera data extraction.");
    }

    // Извлечение данных лазеров
    final laserData = extractLaserData(pcmpFileContent);
    final offsetsData = extractOffsetsData(pcmpFileContent);

    // Создание файла boresight
    await createBoresightFile(
        '${Directory.current.path}\\temp\\boresight', laserData, offsetsData);

    // Продолжаем выполнение процедуры загрузки
    await uploadCalibration(updateState);
  }

  Map<String, List<String>> extractCameraData(String xmlContent) {
    final document = XmlDocument.parse(xmlContent);
    final offsets = document
        .findAllElements('Offsets')
        .first;
    final serial = offsets.getAttribute('serial') ?? 'unknown_serial';

    // Извлекаем атрибуты <linear>
    final linear = offsets
        .findElements('linear')
        .first;
    final linearOffsets = '${serial} linear ${linear.getAttribute('x')} ${linear
        .getAttribute('y')} ${linear.getAttribute('z')}';

    // Извлекаем атрибуты <angular>
    final angular = offsets
        .findElements('angular')
        .first;
    final angularOffsets = '${serial} angular ${angular.getAttribute(
        'yaw')} ${angular.getAttribute('pitch')} ${angular.getAttribute(
        'roll')}';

    // Извлекаем атрибуты <lens>
    final lens = offsets
        .findElements('lens')
        .first;
    final lensAttributes = [
      'Saturation', 'Blue', 'RatPolyDen', 'Green', 'Red', 'RatPolyNum',
      'FOV', 'DeltaX', 'DeltaY', 'VignetteDen', 'VignetteNum', 'aspect'
    ];

    // Создаем список записей для каждого атрибута <lens>
    final lensOffsets = lensAttributes.map((attribute) {
      return '${serial} lens ${attribute} ${lens.getAttribute(attribute)}';
    }).toList();

    // Возвращаем карту с результатами
    return {
      'linear': [linearOffsets],
      'angular': [angularOffsets],
      'lens': lensOffsets,
    };
  }

// Функция для создания нового файла cameras
  Future<void> createCameraFile(String filePath,
      Map<String, List<String>> cameraData) async {
    final boresightContent = StringBuffer();

    // Проходим по всем элементам карты и записываем данные в файл
    cameraData.forEach((key, values) {
      for (var value in values) {
        boresightContent.writeln(value); // Значения уже содержат серийный номер
      }
    });

    // Сохраняем данные в файл
    await File(filePath).writeAsString(boresightContent.toString());
  }

  Map<String, String> extractOffsetsData(String xmlContent) {
    final document = XmlDocument.parse(xmlContent);
    final dataFromOffsets = document
        .findAllElements('Offsets')
        .first;

    // Извлекаем атрибуты <linear>
    final linear = dataFromOffsets
        .findElements('linear')
        .first;
    final linearOffsets = '${linear.getAttribute('x')} ${linear.getAttribute(
        'y')} ${linear.getAttribute('z')}';

    // Извлекаем атрибуты <angular>
    final angular = dataFromOffsets
        .findElements('angular')
        .first;
    final angularOffsets = '${angular.getAttribute('yaw')} ${angular
        .getAttribute('pitch')} ${angular.getAttribute('roll')}';

    // Извлекаем атрибуты <priAnt>
    final priAnt = dataFromOffsets
        .findElements('priAnt')
        .first;
    final priAntOffsets = '${priAnt.getAttribute('x')} ${priAnt.getAttribute(
        'y')} ${priAnt.getAttribute('z')}';

    // Возвращаем в виде карты для удобства использования
    return {
      'linear': linearOffsets,
      'angular': angularOffsets,
      'priAnt': priAntOffsets,
    };
  }

// Функция для извлечения данных лазеров из файла ppk.pcmp
  List<Map<String, String>> extractLaserData(String xmlContent) {
    final document = XmlDocument.parse(xmlContent);

    // Получаем первый элемент <Offsets>
    final dataFromOffsets = document
        .findAllElements('Offsets')
        .first;
    final laserOffsets = dataFromOffsets.findAllElements('laser');

    // Возвращаем данные лазеров
    return laserOffsets.map((laser) {
      return {
        'number': laser.getAttribute('number') ?? '',
        'azimuth': laser.getAttribute('azimuth') ?? '',
        'elevation': laser.getAttribute('elevation') ?? '',
      };
    }).toList();
  }

// Функция для создания нового файла boresight
  Future<void> createBoresightFile(String filePath,
      List<Map<String, String>> laserData,
      Map<String, String> offsetsData) async {
    print('filePath == > $filePath');
    final boresightContent = StringBuffer();

    // Записываем параметры linear, angular и priAnt
    boresightContent.writeln('linear ${offsetsData['linear']}');
    boresightContent.writeln('angular ${offsetsData['angular']}');
    boresightContent.writeln('priAnt ${offsetsData['priAnt']}');

    for (var laser in laserData) {
      boresightContent.writeln(
          'laser ${laser['number']} ${laser['azimuth']} ${laser['elevation']}');
    }

    File(filePath).writeAsStringSync(boresightContent.toString());
  }

  Future<void> parseBoresight(String baseAddress) async {
    print('parseBoresight $baseAddress');
    Directory boresightDir = Directory(p.join(baseAddress, 'Boresight\\'));
    print('boresightDir dir => $boresightDir');

    if (await boresightDir.exists()) {
      print('boresightDir dir exist');
      await for (var entity in boresightDir.list(recursive: false)) {
        pathToPPK = entity;
        print('== 2 $entity');
      }
    } else {
      print('Boresight directory not found.');
    }
  }

  /// UPLOAD CALIBRATION TO UNIT END

  /// ADD ATC TO UNIT
  ///
  /// FOLDER SEARCHER
  Future<String?> searchFolderInIsolateATC(SearchParams params) async {
    return compute(_searchFolderATC, params);
  }

  var folderPathAtc = '';
  var atcName = "";

  static Future<String?> _searchFolderATC(SearchParams params) async {
    try {
      final queue = <Directory>[params.dir];
      while (queue.isNotEmpty) {
        final currentDir = queue.removeAt(0);
        final List<FileSystemEntity> entities = currentDir.listSync();
        for (var entity in entities) {
          if (entity is Directory) {
            if (p.basename(entity.path).toLowerCase().contains(
                params.folderName.toLowerCase())) {
              return entity.path;
            }
            queue.add(entity);
          }
        }
      }
    } on FileSystemException catch (e) {
      print("Error during directory search: ${e.message}");
    } catch (e) {
      print("An error occurred: $e");
    }
    return null;
  }

  Future<String?> searchUserFoldersATC(String folderName) async {
    List<Directory> searchDirs = [
      Directory('N:\\!Factory_calibrations_and_tests\\RESEPI\\'),
      Directory('N:\\Discrepancy_Reporting\\Quality Notices\\'),
    ];
    for (Directory dir in searchDirs) {
      String? folderPathAtc = await searchFolderInIsolateATC(
          SearchParams(dir, folderName));
      if (folderPathAtc != null) {
        return folderPathAtc;
      }
    }
    return null;
  }

  Future<String?> findPdfInFolder(String folderPathAtc) async {
    try {
      final directory = Directory(folderPathAtc);
      final List<FileSystemEntity> entities = directory.listSync();
      for (var entity in entities) {
        if (entity is File &&
            p.extension(entity.path).toLowerCase() == '.pdf') {
          return p.basename(entity.path); // Возвращаем имя PDF файла
        }
      }
    } on FileSystemException catch (e) {
      print("Error during file search: ${e.message}");
    } catch (e) {
      print("An error occurred: $e");
    }
    return null; // Если PDF файл не найден
  }

  Future<void> findFolder(String folderName, updateState) async {
    if (folderName.isEmpty) {
      pushUnitResponse(
          3, "Please enter a part of folder name", updateState: updateState);
      updateState();
      return;
    }
    pushUnitResponse(0, "Searching for the folder", updateState: updateState);
    updateState();
    folderPathAtc = (await searchUserFoldersATC(folderName))!;

    if (folderPathAtc != null) {
      pushUnitResponse(
          1, "Folder found successfully", updateState: updateState);
      atcName = (await findPdfInFolder(folderPathAtc))!;
      updateState();
    } else {
      pushUnitResponse(2, "Folder not found", updateState: updateState);
      updateState();
    }
  }
    /// FOLDER SEARCHER END

    ///
    Future<void> uploadAtcToUnit(folderName, Function updateState) async {
      if (await createTempKeyFile() && checkUnitConnection(updateState)) {
        final shell = Shell();
        pushUnitResponse(0, "Procedure started", updateState: updateState);
        updateState();
        //var atcPdfPath = '$pathToUnitFolder/ATC_${listContentTxt[0]}-${listContentTxt[1]}.pdf';
        print('pathToUnitFolder == $pathToUnitFolder');
        if (await fetchTitle() == "RESEPI GEN-II" ||
            await fetchTitle() == "FLIGHTS GEN-II") {
          host = keyGen2[1];
        } else {
          host = keyGen1[1];
        }
        try {
          await findFolder(folderName, updateState);

//         await shell.run('''
//     ${plinkPath} -i "$keyPath" -P 22 root@192.168.12.1 -hostkey "$hostKey" "cd /srv/www && mount -o remount,rw / && sed -i '/LiDAR Service/a <a href=\"img/$atcName\" id=\"Geometry\" target=\"_blank\">Calibration Certificate</a>' /var/volatile/srv/www/index.html"
// ''');
          await shell.run('''
    ${plinkPath} -i "$keyPath" -P 22 root@192.168.12.1 -hostkey "$hostKey" 'sh -c "mount -o remount,rw /"'
''');
          Future.delayed(Duration(seconds: 1), () async {
            await shell.run(
                '''${pscpPath} -hostkey "$host" -i "$keyPath" -P 22 "$folderPathAtc/${atcName
                    .toString()}" root@192.168.12.1:/etc/payload/ATC.pdf''');
          });
          pushUnitResponse(
              1, "ATC file copied to the unit", updateState: updateState);
          Future.delayed(Duration(seconds: 3), () async {
            shell.kill();
            await deleteTempKeyFile();
          });
        } catch (e) {
          pushUnitResponse(
              2, "Failed to copy ATC to the unit", updateState: updateState);
        } finally {

        }
      } else {
        pushUnitResponse(2, "Procedure failed", updateState: updateState);
      }
      updateState();
    }

    ///
    ///
    ///
    ///
    ///
    ///
    ///

  }

/// PART OF FOLDER SEARCHER

  class SearchParams {
  final Directory dir;
  final String folderName;

  SearchParams(this.dir, this.folderName);
}
  /// PART OF FOLDER SEARCHER END

