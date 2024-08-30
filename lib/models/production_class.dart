import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:process_run/shell.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../constant.dart';

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
        var brandNow = await shell.run('''
          ${_plinkPath} -i "$keyPath" -P 22 root@192.168.12.1 -hostkey "$hostKey" "cat /etc/brand"
          ''');
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
        // var receiverNow = await shell.run('''
        //  ${_plinkPath} -i "$keyPath" -P 22 root@192.168.12.1 -hostkey "$hostKey" "cd /var/volatile && mount -o remount,rw / && grep 'Kernel receiver model =' payload.log | sed 's/^.*Kernel receiver model = //' && exit"
        // ''');
        var scannerNow = await shell.run('''
          ${_plinkPath} -i "$keyPath" -P 22 root@192.168.12.1 -hostkey "$hostKey" "cat /etc/payload/scanner"
          ''');
        var firmwareNow = await shell.run('''
           ${_plinkPath} -i "$keyPath" -P 22 root@192.168.12.1 -hostkey "$hostKey" "head -n 1 /etc/release_notes"
          ''');
        ///////////////// output
        output =
        " Brand: ${brandNow.outText}\n SSID default: ${ssidDef.outText.split(' ').first.replaceAll('"', '')}\n SSID now: ${ssidNow.outText.split(' ').first.replaceAll('"', '')}\n Password: ${passphraseNow.outText}\n Firmware: ${firmwareNow.outText}\n Reciever: ${receiverNow.outText}\n Reciever SN: ${receiverNow.outText.split(' ').last}\n Scanner: ${scannerNow.outText}";
      } catch (e) {
        output =
        "Failed to copy calibration file: check all conditions before start $e";
      } finally {
        await _deleteTempKeyFile();
      }
      statusOutput = output;
    } else {
      statusOutput = "Procedure failed";
    }
    updateState();
  }
  /// GET UNIT INFO END


}

  /// PART OF FOLDER SEARCHER
class SearchParams {
  final Directory dir;
  final String folderName;

  SearchParams(this.dir, this.folderName);
}
  /// PART OF FOLDER SEARCHER END