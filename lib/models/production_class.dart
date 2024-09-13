import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:process_run/shell.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../constant.dart';
import 'package:http/http.dart' as http;

class Production {
  static final Production _instance = Production._internal();

  factory Production() {
    return _instance;
  }

  // void init() {
  //   decodedString = _decodeStringWithRandom(key);
  //   print('init decodedString');
  // }
  Production._internal();

  String statusOutput = '';
 // String excelFilePath = templateAtcPath; // Exact path to Excel file
  String? unitNum;
  List<String> listContentTxt = [];
  Map<String, String> mapListContent = {};
  List<List<double>> lidarOffsetsList = [];
  List<List<double>> filtersList = [];
  String ssidFromFolderName='';
  String ssidNumberFromFolderName='';
  String decodedString = "";
  String keyPath = '';
  final String _plinkPath = 'data/flutter_assets/assets/plink.exe';
  final String _pscpPath = 'data/flutter_assets/assets/pscp.exe';
  var appDirectory;

  /// SSH KIT

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
    decodedString = _decodeStringWithRandom(key);
    final appDir = Directory.current;
    final tempDir = Directory('${appDir.path}/temp');
    if (!await tempDir.exists()) {
      await tempDir.create(recursive: true);
    }
    final keyFile = File('${tempDir.path}/resepi_login.ppk');
    await keyFile.writeAsString(decodedString);
    keyPath = keyFile.path;
    return await keyFile.exists();
  }

  Future<void> _deleteTempKeyFile() async {
    final keyFile = File(keyPath);
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
  /// SSH KIT END

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
      statusOutput = 'Please enter a folder name.';
      return;
    }
    statusOutput = 'Searching for the folder...';
    updateState();
    String? folderPath = await searchUserFolders(folderName);
    if (folderPath == null) {
      folderPath = await searchFolderInIsolate(SearchParams(Directory('ftpPath'), folderName));
    }
    if (folderPath != null) {
      var shell = Shell();
      try {
        await shell.run('explorer "${p.normalize(folderPath)}"');
        statusOutput = 'Folder opened successfully.';
      } catch (e) {
        // statusOutput = 'Error opening the folder: $e';
      }
    } else {
      statusOutput = 'Folder not found.';
    }
    updateState();
  }
  /// FOLDER SEARCHER END

  /// ADD CUSTOM SSID
  Future<void> addCustomSSiD(newSSiDname,Function updateState) async {
    if (await newSSiDname.toString().isNotEmpty) {
      await _deleteTempKeyFile();
      if (await _createTempKeyFile()) {
        final shell = Shell();
        final name = '\"\'"$newSSiDname"\'\" #our_ssid';
        statusOutput = "Procedure started............";
        updateState();
        String output = "";
        try {
          await shell.run('''
       ${_plinkPath} -i "$keyPath" -P 22 root@192.168.12.1 -hostkey "$hostKey" "cd /etc/wpa_supplicant && mount -o remount,rw / && sed -i 's/^ssid=\".*\"/ssid=$name/' wpa_supplicant-wlan0.conf && exit"
        ''');
          output = "SSID successfully updated.";
        } catch (e) {
          output =
          "Failed to update SSID: check all conditions before start";
        } finally {
          await _deleteTempKeyFile();
        }
        statusOutput = output;
      } else {
        statusOutput = "Procedure failed";
      }
    }else{
    }
    updateState();
  }
  /// ADD CUSTOM SSID END

  /// ATC GENERATOR
  void parseFolder(address, updateState) async {
    listContentTxt = [];
    mapListContent = {};
    lidarOffsetsList = [];
    filtersList = [];

    print('== 1 parseFolder');
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
      await runPythonScript(jsonData);
    } else {
      print('Text file not found.');
      statusOutput = '... Text file not found ...';
    }
    updateState();
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
      statusOutput = '... ATC_${listContentTxt[0]}-${listContentTxt[1]}.xlsx Created ...';
    } else {
      print('Excel file not found.');
      statusOutput = '... Error: I can\'t find the ATC template ...';
    }
    updateState();
  }

  Future<void> runPythonScript(String jsonData) async {
    print('runPythonScript');
    // Assuming the exe file is located at 'assets/python_script.exe'
    String pythonScriptPath = 'assets/fill_atc/fill_xlsx.exe';
    try {
      var result = await Process.run(pythonScriptPath, [jsonData]);
      if (result.exitCode == 0) {
        print('Python script executed successfully.');
        print('Output: ${result.stdout}');
        statusOutput = '... ATC_${listContentTxt[0]}-${listContentTxt[1]}.xlsx Created ...';
      } else {
        print('Python script execution failed.');
        print('Error: ${result.stderr}');
        statusOutput = '... Error: ${result.stderr} ...';
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

  /// GET UNIT INFO
  Future<void> getDeviceInfo(Function updateState) async {
    if (await _createTempKeyFile()) {
      final shell = Shell();
      statusOutput = "Procedure started............";
      updateState();

      String output = "";
      try {
        statusOutput = "Data collection in progress";
        await getImu(updateState);  // предполагается, что imuNumber будет инициализирован здесь
        await getLidarSn(updateState); // Lidar SN
        // Ожидание заполнения imuNumber


        var brandNow = await shell.run('''
        ${_plinkPath} -i "$keyPath" -P 22 root@192.168.12.1 -hostkey "$hostKey" "cat /etc/brand"
        ''');

        // Далее идет получение остальных данных

        var passphraseNow = await shell.run('''
        ${_plinkPath} -i "$keyPath" -P 22 root@192.168.12.1 -hostkey "$hostKey" "cat /etc/passphrase"
        ''');

        var ssidDef = await shell.run('''
        ${_plinkPath} -i "$keyPath" -P 22 root@192.168.12.1 -hostkey "$hostKey" "cd /etc/wpa_supplicant && mount -o remount,rw / && grep '^ssid=' wpa_supplicant-default.conf | sed 's/^ssid=//' && exit"
        ''');

        var ssidNow = await shell.run('''
        ${_plinkPath} -i "$keyPath" -P 22 root@192.168.12.1 -hostkey "$hostKey" "cd /etc/wpa_supplicant && mount -o remount,rw / && grep '^ssid=' wpa_supplicant-wlan0.conf | sed 's/^ssid=//' && exit"
        ''');

        var receiverNow = await shell.run('''
        ${_plinkPath} -i "$keyPath" -P 22 root@192.168.12.1 -hostkey "$hostKey" "cd /var/volatile && mount -o remount,rw / && grep 'Kernel receiver model =' payload.log | sed 's/^.*Kernel receiver model = //' && exit"
        ''');

        var scannerNow = await shell.run('''
        ${_plinkPath} -i "$keyPath" -P 22 root@192.168.12.1 -hostkey "$hostKey" "cat /etc/payload/scanner"
        ''');

        var firmwareNow = await shell.run('''
         ${_plinkPath} -i "$keyPath" -P 22 root@192.168.12.1 -hostkey "$hostKey" "head -n 1 /etc/release_notes"
        ''');
        while (imuNumber == null || imuNumber.isEmpty) {
          await Future.delayed(Duration(milliseconds: 100)); // небольшая задержка
        }
        // Формирование строки после того, как все данные собраны
        output =
        " Brand: ${brandNow.outText}\n SSID default: ${ssidDef.outText.split(' ').first.replaceAll('"', '')}\n SSID now: ${ssidNow.outText.split(' ').first.replaceAll('"', '')}\n Password: ${passphraseNow.outText}\n Firmware: ${firmwareNow.outText}\n Reciever: ${receiverNow.outText}\n Reciever SN: ${receiverNow.outText.split(' ').last}\n IMU SN: ${imuNumber}\n Filter is: ${imuFilter}\n Lidar SN: ${lidarSerialNumber}\n Lidar model: ${lidarModel}\n Scanner: ${scannerNow.outText}";
        updateState();

      } catch (e) {
        output =
        "Fail: check all conditions before start";
      } finally {
        await _deleteTempKeyFile();
      }
      statusOutput = output;
    } else {
      statusOutput = "Procedure failed";
    }
    updateState();
  }

  /// GET IMU NUMBER (PART OF UNIT INFO)
  var process;
  var process2;
  var imuNumber='';
  var imuFilter='';
  var tempData='';


  Future<void> runUnit(Function updateState) async {
    if (await _createTempKeyFile()) {
      try {
        var processRunUnit = await Process.start(
          _plinkPath,
          ['-i', keyPath, 'root@192.168.12.1', '-hostkey', hostKey, "systemctl start payload"],
        );
        await Future.delayed(Duration(seconds: 1), () async {
          processRunUnit.kill();
        });
      } catch (e) {
      } finally {
        await _deleteTempKeyFile();
        updateState;
      }
    }
  }

  Future<void> getImu(Function updateState) async {
    if (await _createTempKeyFile()) {
      try {
        getImu2(updateState);
        print("--------------------------------------------------   1  ");
        process = await Process.start(
          _plinkPath,
          ['-i', keyPath, 'root@192.168.12.1', '-hostkey', hostKey, "systemctl stop payload"],
        );
        //fun1.kill();
        await Future.delayed(Duration(seconds: 1), () async {
          print("--------------------------------------------------   2  ");
          StringBuffer outputBuffer = StringBuffer();
          process = await Process.start(
            _plinkPath,
            ['-i', keyPath, 'root@192.168.12.1', '-hostkey', hostKey, "hexdump -C /dev/ttymxc3"],
          );
          //  Слушаем стандартный вывод (stdout)
          process.stdout.transform(utf8.decoder).listen((data) {
            outputBuffer.write(data);
            tempData=data;
          });
          // Слушаем ошибки (stderr)
          process.stderr.transform(utf8.decoder).listen((data) {
            print("Ошибка: $data");
          });
        });
      } finally {
        updateState();
      }
    } else {
      updateState();
    }
  }


  Future<void> getImu2(Function updateState) async {
    if (await _createTempKeyFile()) {
      try {
        Future.delayed(Duration(seconds: 2), () async {
          process2 = await Process.start(
            _plinkPath,
            ['-i', keyPath, 'root@192.168.12.1', '-hostkey', hostKey, "echo -en '\\xaa\\x55\\x00\\x00\\x09\\x00\\xff\\x57\\x09\\x68\\x01' >/dev/ttymxc3"],
          );
        });
        Future.delayed(Duration(seconds: 3), () async {
          process2 = await Process.start(
            _plinkPath,
            ['-i', keyPath, 'root@192.168.12.1', '-hostkey', hostKey, "stty -F /dev/ttymxc3 921600"],
          );
        });
        Future.delayed(Duration(seconds: 4), () async {
          process2 = await Process.start(
            _plinkPath,
            ['-i', keyPath, 'root@192.168.12.1', '-hostkey', hostKey, "echo -en '\\xA5\\xA5\\x02\\x04\\x0A\\x02\\x01\\x00\\x5D\\xFB' >/dev/ttymxc3"],
          );
          print("--------------------------------------------------   STOP  ");
        });
        await Future.delayed(Duration(seconds: 4), () async {
          print("--------------------------------------------------   DATA CALL  ");
          process2 = await Process.start(
              _plinkPath,
              ['-i', keyPath, 'root@192.168.12.1', '-hostkey', hostKey, "echo -en '\\xA5\\xA5\\x01\\x02\\x06\\x00\\x53\\x2D' >/dev/ttymxc3"]);
          process2 = await Process.start(
              _plinkPath,
              ['-i', keyPath, 'root@192.168.12.1', '-hostkey', hostKey, "echo -en '\\xA5\\xA5\\x01\\x02\\x06\\x00\\x53\\x2D' >/dev/ttymxc3"]);
          process2 = await Process.start(
              _plinkPath,
              ['-i', keyPath, 'root@192.168.12.1', '-hostkey', hostKey, "echo -en '\\xA5\\xA5\\x01\\x02\\x06\\x00\\x53\\x2D' >/dev/ttymxc3"]);
          process2 = await Process.start(
              _plinkPath,
              ['-i', keyPath, 'root@192.168.12.1', '-hostkey', hostKey, "echo -en '\\xA5\\xA5\\x01\\x02\\x06\\x00\\x53\\x2D' >/dev/ttymxc3"]);
          /////
          process2 = await Process.start(
              _plinkPath,
              ['-i', keyPath, 'root@192.168.12.1', '-hostkey', hostKey, "echo -en '\\xA5\\xA5\\x02\\x03\\x03\\x01\\x02\\x55\\x84' >/dev/ttymxc3"]);
          process2 = await Process.start(
              _plinkPath,
              ['-i', keyPath, 'root@192.168.12.1', '-hostkey', hostKey, "echo -en '\\xA5\\xA5\\x02\\x03\\x03\\x01\\x02\\x55\\x84' >/dev/ttymxc3"]);
          process2 = await Process.start(
              _plinkPath,
              ['-i', keyPath, 'root@192.168.12.1', '-hostkey', hostKey, "echo -en '\\xA5\\xA5\\x02\\x03\\x03\\x01\\x02\\x55\\x84' >/dev/ttymxc3"]);
          process2 = await Process.start(
              _plinkPath,
              ['-i', keyPath, 'root@192.168.12.1', '-hostkey', hostKey, "echo -en '\\xA5\\xA5\\x02\\x03\\x03\\x01\\x02\\x55\\x84' >/dev/ttymxc3"]);

          print("--------------------------------------------------   DATA CALL  ");
        });

        Future.delayed(Duration(seconds: 6), () async {
          await _deleteTempKeyFile();
          await process2.kill();
          updateState();
          String result = _processUnitResponse(tempData).replaceAll('\n', '').replaceAll(' ', '');
          print('================== BYTE search====================== |/\n${tempData}');

          // Убираем левую колонку (адреса), правую колонку (символы в |...|), и двойные пробелы между байтами
          String stringBytes = tempData
              .replaceAllMapped(RegExp(r'^\S+\s+([\da-fA-F\s]+)\s+\|.*\|$', multiLine: true), (match) {
            return match.group(1)?.replaceAll(RegExp(r'\s{2,}'), ' ').trim() ?? '';
          })
              .replaceAll('\n', ' ');
          print('Найдено stringBytes: \n$stringBytes');
          // Соединяем строки в одну строку
          // Преобразуем строку в список байтов
          List<String> bytes = stringBytes.split(' ');
          print('Найдено bytes: \n$bytes');
          // Ищем комбинацию 83 01 и проверяем следующий байт
          for (int i = 0; i < bytes.length - 2; i++) {
            if (bytes[i] == '83' && bytes[i + 1] == '01') {
              if (bytes[i + 2] == '00') {
                imuFilter='Correct';
                print('Найдено: 83 01 - следующее значение 00');
                updateState();
              } else {
                print('Найдено: 83 01, но следующее значение не 00, а ${bytes[i + 2]}');
                imuFilter='Wrong';
                updateState();
              }
            }else{
            }
            updateState();
          }


          print('================== UMU search  ===================== \\/\n${result}');
          // Регулярное выражение для поиска номеров из букв и цифр длиной не менее 5 символов
          RegExp regExp = RegExp(r'\.([A-Za-z0-9]{5,})\.');
          // Ищем все совпадения
          RegExpMatch? match = regExp.firstMatch(result);
          // Выводим найденные номера
          if (match != null) {
            print('Найден номер: ${match.group(1)}');
            String number = match.group(1)!; // Получаем номер

            // Проверяем, если последний символ - буква, удаляем его
            if (RegExp(r'[A-Za-z]$').hasMatch(number)) {
              // Проверяем, заканчивается ли строка на букву с помощью регулярного выражения
              number = number.substring(0, number.length - 1);
              imuNumber = "${number}";
              updateState;
              print('Найден номер IMU: ${number}');
            }

           // imuNumber="${match.group(1)}";
            updateState;
            runUnit(updateState);
          } else {
            print('Номер не найден');
            await process.kill();
            runUnit(updateState);
            Future.delayed(Duration(seconds: 3), () async {
              getImu(updateState);
            });
          }
          await process.kill();
        });
      } finally {
      }
    } else {
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
      updateState;
    } catch (e) {
      stringFromLidar = 'Error: $e';
    }

  }
/// GET LIDAR SN END

  /// GET UNIT INFO END
}

  /// PART OF FOLDER SEARCHER
class SearchParams {
  final Directory dir;
  final String folderName;

  SearchParams(this.dir, this.folderName);
}
  /// PART OF FOLDER SEARCHER END

