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
  String ssidFromFolderName='';
  String ssidNumberFromFolderName='';

 // String keyPath = '';

  var appDirectory;
  var tempDir;
  var pathToUnitFolder;
  var pathToPPK;

  // /// SSH KIT
  //
  // String _decodeStringWithRandom(String input) {
  //   StringBuffer cleaned = StringBuffer();
  //   for (int i = 0; i < input.length; i++) {
  //     if (i % 3 != 2) {
  //       cleaned.write(input[i]);
  //     }
  //   }
  //   List<int> bytes = base64Decode(cleaned.toString());
  //   String decodedString = utf8.decode(bytes);
  //   return decodedString;
  // }
  //
  // Future<bool> _createTempKeyFile() async {
  //   decodedString = _decodeStringWithRandom(key);
  //   final appDir = Directory.current;
  //   tempDir = Directory('${appDir.path}/temp');
  //   if (!await tempDir.exists()) {
  //     await tempDir.create(recursive: true);
  //   }
  //   final keyFile = File('${tempDir.path}/resepi_login.ppk');
  //   await keyFile.writeAsString(decodedString);
  //   keyPath = keyFile.path;
  //   return await keyFile.exists();
  // }
  //
  // Future<void> _deleteTempKeyFile() async {
  //   final keyFile = File(keyPath);
  //   if (await keyFile.exists()) {
  //     try {
  //       await keyFile.delete();
  //       print("The procedure is completed.");
  //     } catch (e) {
  //       print("Failed : $e");
  //       await Future.delayed(Duration(seconds: 1));
  //       try {
  //         await keyFile.delete();
  //         print("Retry procedure.");
  //       } catch (retryException) {
  //         print("Procedure failed : $retryException");
  //       }
  //     }
  //   }
  // }
  // /// SSH KIT END

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
            if (p.basename(entity.path).toLowerCase().contains(params.folderName.toLowerCase())) {
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
      String? folderPath = await searchFolderInIsolate(SearchParams(dir, folderName));
      if (folderPath != null) {
        return folderPath;
      }
    }
    return null;
  }

  Future<void> openFolder(String folderName,updateState) async {
    if (folderName.isEmpty) {
      pushUnitResponse(3,"Please enter a part of folder name",updateState);
      updateState();
      return;
    }
    pushUnitResponse(0,"Searching for the folder",updateState);
    updateState();
    String? folderPath = await searchUserFolders(folderName);
    pathToUnitFolder = folderPath;
    //print('pathToUnitFolder = $pathToUnitFolder');
    pushUnitResponse(1,"Folder opened successfully",updateState);
    updateState();
    if (folderPath == null) {
      folderPath = await searchFolderInIsolate(SearchParams(Directory('ftpPath'), folderName));
    }
    else if (folderPath != null) {
      var shell = Shell();
      try {
        await shell.run('explorer "${p.normalize(folderPath)}"');
       // pathToUnitFolder=("${p.normalize(folderPath)}");
       // shell.kill();
       // print('pathToUnitFolder = $pathToUnitFolder');
      } catch (e) {
        // statusOutput = 'Error opening the folder: $e';
      }
    } else {
      pushUnitResponse(2,"Folder not found",updateState);
      updateState();
    }
  }
  /// FOLDER SEARCHER END

  /// ADD CUSTOM SSID
  Future<void> addCustomSSiD(newSSiDname,Function updateState) async {
    if (await newSSiDname.toString().isNotEmpty) {
      await deleteTempKeyFile();
      if (await createTempKeyFile()) {
        final shell = Shell();
        final name = '\"\'"$newSSiDname"\'\" #our_ssid';
        pushUnitResponse(0,"Procedure started",updateState);
        updateState();
        try {
          await shell.run('''
       ${plinkPath} -i "$keyPath" -P 22 root@192.168.12.1 -hostkey "$hostKey" "cd /etc/wpa_supplicant && mount -o remount,rw / && sed -i 's/^ssid=\".*\"/ssid=$name/' wpa_supplicant-wlan0.conf && exit"
        ''');
          pushUnitResponse(1,"SSID successfully updated",updateState);
          updateState();
        } catch (e) {
          pushUnitResponse(2,"Failed to update SSID:\ncheck all conditions before start",updateState);
          updateState();
        } finally {
          await deleteTempKeyFile();
        }
      } else {
        pushUnitResponse(2,"Procedure failed",updateState);
        updateState();
      }
    }else{
      pushUnitResponse(3,"Add new SSID to top string",updateState);
      updateState();
    }
  }
  /// ADD CUSTOM SSID END

  /// ATC GENERATOR
  void parseFolder(address, updateState) async {
    listContentTxt = [];
    mapListContent = {};
    lidarOffsetsList = [];
    filtersList = [];

    print('========================= parseFolder');
    appDirectory = Directory.current.path;
    print('Il_int work directory => $appDirectory');
    var _address = await address;
    unitNum = p.basename(_address).split('_').last;
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
      DateTime dateToday = DateTime.now();
      mapListContent =  mapOffsetsForAtc(_address,listContentTxt,lidarOffsetsList,appDirectory,dateToday,ssidFromFolderName,ssidNumberFromFolderName);

      print('List strings from Readme.txt => $listContentTxt');
      await copyExcelFile(targetTxtFile.parent.path, updateState);
      // Serialize mapListContent to JSON and pass it to the Python script
      String jsonData = jsonEncode(mapListContent);


      // Fill exel file
      await runPythonScript(jsonData, updateState);
    } else {
      print('Text file not found.');
      pushUnitResponse(3,"No data found, enter the unit number",updateState);
      updateState();
    }
  }

  Future<void> copyExcelFile(String saveDirectory, updateState) async {
    print('copyExcelFile');
    var file = File(templatePath(lidarOffsetsList));
    if (await file.exists()) {
      var bytes = await file.readAsBytes();
      var copiedExcelFilePath =
      p.join(saveDirectory, 'ATC_${listContentTxt[0]}-${listContentTxt[1]}.xlsx');
      var copiedExcelFile = File(copiedExcelFilePath);
      await copiedExcelFile.writeAsBytes(bytes);
      print('Excel file has been copied to $saveDirectory');
      pushUnitResponse(1,"ATC_${listContentTxt[0]}-${listContentTxt[1]}.xlsx Created",updateState);
      updateState();
    } else {
      print('Excel file not found.');
      pushUnitResponse(2,"Error:\ncan\'t find the ATC template",updateState);
      updateState();
    }
  }

  Future<void> runPythonScript(String jsonData, updateState) async {
    print('runPythonScript');
    // Assuming the exe file is located at 'assets/python_script.exe'
    String pythonScriptPath = 'assets/fill_atc/fill_xlsx.exe';
    try {
      var result = await Process.run(pythonScriptPath, [jsonData]);
      if (result.exitCode == 0) {
        print('Python script executed successfully.');
        print('Output: ${result.stdout}');
        pushUnitResponse(1,"ATC_${listContentTxt[0]}-${listContentTxt[1]}.pdf Created",updateState);
        updateState();
      } else {
        print('Python script execution failed.');
        print('Error: ${result.stderr}');
        pushUnitResponse(2,"Error:\n${result.stderr}",updateState);
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

    if (await boresightDir.exists()) {
      await for (var entity in boresightDir.list(recursive: false)) {
        print('== 2 $entity');
        if (entity is Directory) {
          List<List<double>> combinedList = [];

          await for (var subEntity in entity.list(recursive: false)) {
            print('== 2 $subEntity');

            if (subEntity is File && p.basename(subEntity.path) == 'ppk.pcmp') {
              print('Processing file: ${subEntity.path}');
              // Parse the `ppk` file content here
              List<String> offsets = await extractTagContent(subEntity, 'Offsets');
              lidarOffsetsList = await parseTagContent(offsets);

              List<String> filters = await extractTagContent(subEntity, 'Filters');
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
              List<String> offsets = await extractTagContent(subEntity, 'Offsets');
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
      List<double> values = matches.map((match) => double.parse(match.group(0)!)).toList();
      result.add(values);
    }
    return result;
  }
  /// ATC GENERATOR END
///
  ///
  ///
  /// GET UNIT INFO

  Future<void> getDeviceInfo(Function updateState) async {
    if (await createTempKeyFile()) {
      final shell = Shell();
      String output = "";

      try {
        //output += "Data collection in progress\n";

        // Получаем IMU
        // await getImu(updateState);
        output += "IMU SN: ${imuNumber}\n";

        // Получаем Lidar SN
        await getLidarSn(updateState);
        output += "Lidar SN: ${lidarSerialNumber}\n";

        // Информация по бренду
        var brandNow = await shell.run('''
        ${plinkPath} -i "$keyPath" -P 22 root@192.168.12.1 -hostkey "$hostKey" "cat /etc/brand"
      ''');
        output += "Brand: ${brandNow.outText}\n";

        // Пароль
        var passphraseNow = await shell.run('''
        ${plinkPath} -i "$keyPath" -P 22 root@192.168.12.1 -hostkey "$hostKey" "cat /etc/passphrase"
      ''');
        output += "Password: ${passphraseNow.outText}\n";

        // SSID по умолчанию
        var ssidDef = await shell.run('''
        ${plinkPath} -i "$keyPath" -P 22 root@192.168.12.1 -hostkey "$hostKey" "grep '^ssid=' /etc/wpa_supplicant/wpa_supplicant-default.conf | sed 's/^ssid=//' && exit"
      ''');
        output += "SSID default: ${ssidDef.outText.split(' ').first.replaceAll('"', '')}\n";

        // Текущий SSID
        var ssidNow = await shell.run('''
        ${plinkPath} -i "$keyPath" -P 22 root@192.168.12.1 -hostkey "$hostKey" "grep '^ssid=' /etc/wpa_supplicant/wpa_supplicant-wlan0.conf | sed 's/^ssid=//' && exit"
      ''');
        output += "SSID now: ${ssidNow.outText.split(' ').first.replaceAll('"', '')}\n";

        // Информация о ресивере
        var receiverNow = await shell.run('''
        ${plinkPath} -i "$keyPath" -P 22 root@192.168.12.1 -hostkey "$hostKey" "grep 'Kernel receiver model =' /var/volatile/payload.log | sed 's/^.*Kernel receiver model = //' && exit"
      ''');
        output += "Receiver: ${receiverNow.outText}\n";
        output += "Reciever SN: ${receiverNow.outText.split(' ').last}\n";
        // Прошивка
        var firmwareNow = await shell.run('''
        ${plinkPath} -i "$keyPath" -P 22 root@192.168.12.1 -hostkey "$hostKey" "head -n 1 /etc/release_notes"
      ''');
        output += "Firmware: ${firmwareNow.outText}\n";
        output += "IMU Filter: ${imuFilter}\n";
      } catch (e) {
        pushUnitResponse(2,"Fail: check all conditions before start",updateState);
      } finally {
        await deleteTempKeyFile();
      }

      // Обновляем состояние только после завершения всей операции

      pushUnitResponse(1,output,updateState);
      updateState();
    } else {
      pushUnitResponse(2,"Procedure failed",updateState);
      updateState();
    }
  }

  /// GET IMU NUMBER (PART OF UNIT INFO)
  var process;
  var process2;
  var process3;
  var process4;
  var imuNumber='';
  var imuFilter='';
  var tempData='';
  var counter= 5;

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

  runGetUnitImu(updateState){
    print("------- runGetUnitImu");
    counter=5;
    imuNumber='';
    imuFilter='';
    pushUnitResponse(10,"",updateState);
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

  Future<void> getImu(Function updateState) async {
    process2=null;
    process3=null;
    process4=null;
    process=null;
    if ( counter == 0) {
      imuNumber='Not identified';
      imuFilter='Not identified';
      getDeviceInfo(updateState);
    }
    else if ( counter != 0) {
      if (await createTempKeyFile()) {
        pushUnitResponse(0,"Searching",updateState);
        try {
          print("----------getImu   1  ");
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
          print('Command executed successfully! #1');
          // Check exit code
          if (exitCode == 0) {
            print('Command #1 exitCode: 0');
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
            process.stdout.transform(utf8.decoder).listen((data) {
              outputBuffer.write(data);
              tempData = "";
              tempData = data;
              //print("-------- getImu 1 data $data");
            });
            process.stderr.transform(utf8.decoder).listen((data) {
              print("Ошибка: $data");
            });
            ///
            getImu2(updateState);
          } else {
            pushUnitResponse(3,"Unit is not connected",updateState);
            await deleteTempKeyFile();
            print('Command failed with exit code: $exitCode');
            restartUnit();
            //// restart!!
          }
        } finally {}} else {}
    }
  }


  Future<void> getImu2(Function updateState) async {

    if (await createTempKeyFile()) {
      print("--------------------------------------------------getImu   2  ");
      try {
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
          print("--------------------------------------------------   STOP  ");
        });
        await Future.delayed(Duration(seconds: 5), () async {
          print("--------------------------------------------------   DATA CALL  ");
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


          Future.delayed(Duration(seconds: 1), () async {

            String result = _processUnitResponse(tempData).replaceAll('\n', '').replaceAll(' ', '');

            print('================== Result search ==================== \n${result}');
            String stringBytes = tempData
                .replaceAllMapped(RegExp(r'^\S+\s+([\da-fA-F\s]+)\s+\|.*\|$', multiLine: true), (match) {
              return match.group(1)?.replaceAll(RegExp(r'\s{2,}'), ' ').trim() ?? '';
            })
                .replaceAll('\n', ' ');
            print('================== BYTE founded =====================  \n$stringBytes');
            // Соединяем строки в одну строку
            // Преобразуем строку в список байтов
            List<String> bytes = stringBytes.split(' ');
            // Ищем комбинацию 83 01 и проверяем следующий байт
            imuFilter='';
            for (int i = 0; i < bytes.length - 2; i++) {
              if (bytes[i] == '83' && bytes[i + 1] == '01') {
                if (bytes[i + 2] == '00') {
                  imuFilter='Correct';
                  print('Найдено: 83 01 - следующее значение 00');
                  updateState();
                } if (bytes[i + 2] != '00') {
                  imuFilter='Wrong';
                  print('Найдено: 83 01 - следующее не 00');
                  updateState();
                }
              }
              updateState();
            }

            print('================== UMU search  ===================== \\/\n${result}');

            RegExp regExp = RegExp(r'\.([A-Za-z0-9]{5,})\.');// Регулярное выражение для поиска номеров из букв и цифр длиной не менее 5 символов
            RegExpMatch? match = regExp.firstMatch(result);// Ищем все совпадения

            print('================== Выводим найденные номера  ======= \\/\n${match}');
            if(match==null || match.group(1)!.toString().length < 5 && counter != 0){
              print('================== Номер не найден  ================= ');
              pushUnitResponse(3,"No result, I'll try again ${counter-1} times",updateState);
              decrementCounter(updateState);
              await runUnit(updateState);
              Future.delayed(Duration(seconds: 3), () async {
                await getImu(updateState);
                print('==== $counter');
                updateState();
              });
            }
            else if(counter == 0){
              print('============ Counter 0 = $counter');
              pushUnitResponse(2,"Not all data collected, please reboot the unit",updateState);
              deleteTempKeyFile();
              await runUnit(updateState);
            }
            else if (match != null && counter!= 0) {// Выводим найденные номера
              print('Найден номер: ${match.group(1)}');
              String number = match.group(1)!;
              imuNumber = "${number}";
              print('Найден номер IMU 1: ${number}');
              await getDeviceInfo(updateState);
              await runUnit(updateState);
              // Получаем номер
              if (RegExp(r'[A-Za-z]$').hasMatch(number)) {// Проверяем, если последний символ - буква, удаляем его
                number = number.substring(0, number.length - 1);// Проверяем, заканчивается ли строка на букву с помощью регулярного выражения
                imuNumber = "${number}";
                print('Найден номер IMU 2: ${number}');
                await getDeviceInfo(updateState);
                await runUnit(updateState);
                updateState();
              }
              updateState();
            }
            // test = tempData;
            await deleteTempKeyFile();
            print('========== TEST  $tempData');
            await process2.kill();
            await process3.kill();
            await process4.kill();
            await process.kill();

          });
        });

      } finally { }
    }
  }

  String _processUnitResponse(String response) {

    // Use a regular expression to match the part with ASCII characters after the hex values
    RegExp regExp = RegExp(r'\|(.+)\|');
    Iterable<Match> matches = regExp.allMatches(response);

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
  /// GET IMU NUMBER (PART OF UNIT INFO) END

  /// GET LIDAR SN
  var lidarSerialNumber;
  var lidarModel;
  var urlToLidar ='http://192.168.12.1:8001/pandar.cgi?action=get&object=device_info';
  // Функция для отправки запроса
  Future<void> getLidarSn(updateState) async {
    final url = Uri.parse(urlToLidar);
    var stringFromLidar;
    try {
      final response = await http.get(url);
      stringFromLidar = response.statusCode == 200
          ? response.body
          : 'Error: ${response.statusCode}';
      print("======== Lidar SN: ${stringFromLidar.runtimeType}");
      print("======== Lidar SN: $stringFromLidar");
      // Преобразуем строку JSON в объект Dart (Map)
      Map<String, dynamic> jsonMap = jsonDecode(stringFromLidar);
      // Получаем значение поля SN
      lidarSerialNumber = jsonMap['Body']['SN'];
      lidarModel = jsonMap['Body']['Model'];
      print('LIDAR SN: $lidarSerialNumber');
      print('LIDAR MODEL: $lidarModel');
      updateState();
    } catch (e) {
      stringFromLidar = 'Error: $e';
    }

  }
  /// GET LIDAR SN END

  /// GET UNIT INFO END


  /// UPLOAD CALIBRATION TO UNIT
  Future<void> uploadCalibration(Function updateState) async {
    if (await createTempKeyFile()) {
      final shell = Shell();
      pushUnitResponse(0,"Procedure started",updateState);
      updateState();
      String output = "";
      try {
        const calibrationLaserPath = 'temp/boresight';
        const calibrationCameraPath = 'temp/cameras';

        await shell.run('''
        ${plinkPath} -i "$keyPath" -P 22 root@192.168.12.1 -hostkey "$hostKey" "mount -o remount,rw / && echo 'OPEN TO EDIT' > /etc/payload/boresight && exit"
        ''');

        await shell.run('''
        ${plinkPath} -i "$keyPath" -P 22 root@192.168.12.1 -hostkey "$hostKey" "cat /etc/payload/boresight"
        ''');

        await shell.run('''${pscpPath} -i "$keyPath" -P 22 "$calibrationLaserPath" root@192.168.12.1:/etc/payload/boresight''');
        await shell.run('''${pscpPath} -i "$keyPath" -P 22 "$calibrationCameraPath" root@192.168.12.1:/etc/payload/cameras''');

        pushUnitResponse(1,"Boresight file copied successfully",updateState);
        shell.kill();
      } catch (e) {
        pushUnitResponse(2,"Failed to copy calibration file: check all conditions before start",updateState);
        } finally {
        await deleteTempKeyFile();
      }

    } else {
      pushUnitResponse(2,"Procedure failed",updateState);

    }
    updateState();
  }

  Future<void> runCreatePreUploadLaserBoresightFile(_unitFolder, updateState) async {
    print("=========== unit folder $_unitFolder");

    await parseBoresight(_unitFolder);
    pushUnitResponse(0,"Searching data files",updateState);
    if (_unitFolder == "N:\\!Factory_calibrations_and_tests\\RESEPI\\") {
      pushUnitResponse(3,"Enter Unit SN",updateState);
      updateState();
    }

    // Чтение содержимого ppk.pcmp
    final pcmpFileContent = File('${pathToPPK.path}\/ppk.pcmp').readAsStringSync();

    // Проверяем, существует ли файл ppk.pcpp
    String pcppFileContent = "";
    if (File('${pathToPPK.path}\/ppk.pcpp').existsSync()) {
      pcppFileContent = File('${pathToPPK.path}\/ppk.pcpp').readAsStringSync();
      // Извлечение данных камер
      final cameraOffsetsData = extractCameraData(pcppFileContent);
      // Создание файла cameras
      await createCameraFile('${Directory.current.path}\\temp\\cameras', cameraOffsetsData);
    } else {
      print("File ppk.pcpp not found. Skipping camera data extraction.");
    }

    // Извлечение данных лазеров
    final laserData = extractLaserData(pcmpFileContent);
    final offsetsData = extractOffsetsData(pcmpFileContent);

    // Создание файла boresight
    await createBoresightFile('${Directory.current.path}\\temp\\boresight', laserData, offsetsData);

    // Продолжаем выполнение процедуры загрузки
    await uploadCalibration(updateState);
  }

  Map<String, List<String>> extractCameraData(String xmlContent) {
    final document = XmlDocument.parse(xmlContent);
    final offsets = document.findAllElements('Offsets').first;
    final serial = offsets.getAttribute('serial') ?? 'unknown_serial';

    // Извлекаем атрибуты <linear>
    final linear = offsets.findElements('linear').first;
    final linearOffsets = '${serial} linear ${linear.getAttribute('x')} ${linear.getAttribute('y')} ${linear.getAttribute('z')}';

    // Извлекаем атрибуты <angular>
    final angular = offsets.findElements('angular').first;
    final angularOffsets = '${serial} angular ${angular.getAttribute('yaw')} ${angular.getAttribute('pitch')} ${angular.getAttribute('roll')}';

    // Извлекаем атрибуты <lens>
    final lens = offsets.findElements('lens').first;
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
  Future<void> createCameraFile(String filePath, Map<String, List<String>> cameraData) async {
    final boresightContent = StringBuffer();

    // Проходим по всем элементам карты и записываем данные в файл
    cameraData.forEach((key, values) {
      for (var value in values) {
        boresightContent.writeln(value);  // Значения уже содержат серийный номер
      }
    });

    // Сохраняем данные в файл
    await File(filePath).writeAsString(boresightContent.toString());
  }

  Map<String, String> extractOffsetsData(String xmlContent) {
    final document = XmlDocument.parse(xmlContent);
    final dataFromOffsets = document.findAllElements('Offsets').first;

    // Извлекаем атрибуты <linear>
    final linear = dataFromOffsets.findElements('linear').first;
    final linearOffsets = '${linear.getAttribute('x')} ${linear.getAttribute('y')} ${linear.getAttribute('z')}';

    // Извлекаем атрибуты <angular>
    final angular = dataFromOffsets.findElements('angular').first;
    final angularOffsets = '${angular.getAttribute('yaw')} ${angular.getAttribute('pitch')} ${angular.getAttribute('roll')}';

    // Извлекаем атрибуты <priAnt>
    final priAnt = dataFromOffsets.findElements('priAnt').first;
    final priAntOffsets = '${priAnt.getAttribute('x')} ${priAnt.getAttribute('y')} ${priAnt.getAttribute('z')}';

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
    final dataFromOffsets = document.findAllElements('Offsets').first;
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
  Future<void> createBoresightFile(String filePath, List<Map<String, String>> laserData, Map<String, String> offsetsData) async {
    print('filePath == > $filePath');
    final boresightContent = StringBuffer();

    // Записываем параметры linear, angular и priAnt
    boresightContent.writeln('linear ${offsetsData['linear']}');
    boresightContent.writeln('angular ${offsetsData['angular']}');
    boresightContent.writeln('priAnt ${offsetsData['priAnt']}');

    for (var laser in laserData) {
      boresightContent.writeln('laser ${laser['number']} ${laser['azimuth']} ${laser['elevation']}');
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
///
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

