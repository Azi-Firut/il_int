import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:flutter/services.dart' show rootBundle;
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import '../constant.dart';
import 'data.dart';
import 'package:xml/xml.dart';
class AtcGenerator {
  static final AtcGenerator _instance = AtcGenerator._internal();
  factory AtcGenerator() {
    return _instance;
  }
  AtcGenerator._internal();
  String statusOutput = '';
  String excelFilePath = templateAtcPath; // Exact path to Excel file
  String? unitNum;
  List<String> listContentTxt = [];
  Map<String, String> mapListContent = {};
  List<List<double>> lidarOffsetsList = [];
  var appDirectory;
  String pathToImg =
      '\\assets\\fill_atc\\atc_template\\logo_img_atc\\RESEPI.png';

  void parseFolder(address, updateState) async {
    print('parseFolder');
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
      await parsePpkFiles(_address);
      List<String> lines = await targetTxtFile.readAsLines();
      listContentTxt = lines.map((line) {
        int colonIndex = line.indexOf(':');
        return colonIndex != -1 ? line.substring(colonIndex + 1).trim() : line;
      }).toList();
      DateTime dateToday = DateTime.now();
      mapListContent = {
        'adressXLSX': '$_address\\ATC_${listContentTxt[1]}.xlsx',
        'D4': listContentTxt.length > 2 ? 'ATC_${listContentTxt[1]}' : '',
        'D5': listContentTxt.length > 2 ? listContentTxt[0] : '',
        'D6': listContentTxt.length > 2 ? listContentTxt[2] : '',
        'D7': listContentTxt.length > 3 ? listContentTxt[1] : '',
        'D8': listContentTxt.length > 4 ? listContentTxt[7] : '',
        'D9': listContentTxt.length > 5 ? listContentTxt[6] : '',
        'D10': listContentTxt.length > 5 ? listContentTxt[8] : '',
        'D11': listContentTxt.length > 5 ? listContentTxt[3] : '',
        'D12': listContentTxt.length > 5 ? listContentTxt[5] : '',
        // Offset val
        'J25': '${lidarOffsetsList[0][0]}',
        'J26': '${lidarOffsetsList[0][1]}',
        'J27': '${lidarOffsetsList[0][2]}',
        'J28': '${lidarOffsetsList[1][0]}',
        'J29': '${lidarOffsetsList[1][1]}',
        'J30': '${lidarOffsetsList[1][2]}',
        // Lidar val
    'I33': '${lidarOffsetsList[4][1]}',
    'J33': '${lidarOffsetsList[4][2]}',
    'I34': '${lidarOffsetsList[5][1]}',
    'J34': '${lidarOffsetsList[5][2]}',
    'I35': '${lidarOffsetsList[6][1]}',
    'J35': '${lidarOffsetsList[6][2]}',
    'I36': '${lidarOffsetsList[7][1]}',
    'J36': '${lidarOffsetsList[7][2]}',
    'I37': '${lidarOffsetsList[8][1]}',
    'J37': '${lidarOffsetsList[8][2]}',
    'I38': '${lidarOffsetsList[9][1]}',
    'J38': '${lidarOffsetsList[9][2]}',
    'I39': '${lidarOffsetsList[10][1]}',
    'J39': '${lidarOffsetsList[10][2]}',
    'I40': '${lidarOffsetsList[11][1]}',
    'J40': '${lidarOffsetsList[11][2]}',
    'I41': '${lidarOffsetsList[12][1]}',
    'J41': '${lidarOffsetsList[12][2]}',
    'I42': '${lidarOffsetsList[13][1]}',
    'J42': '${lidarOffsetsList[13][2]}',
    'I43': '${lidarOffsetsList[14][1]}',
    'J43': '${lidarOffsetsList[14][2]}',
    'I44': '${lidarOffsetsList[15][1]}',
    'J44': '${lidarOffsetsList[15][2]}',
    'I45': '${lidarOffsetsList[14][1]}',
    'J45': '${lidarOffsetsList[14][2]}',
    'I46': '${lidarOffsetsList[15][1]}',
    'J46': '${lidarOffsetsList[15][2]}',
    'I47': '${lidarOffsetsList[16][1]}',
    'J47': '${lidarOffsetsList[16][2]}',
    'I48': '${lidarOffsetsList[17][1]}',
    'J48': '${lidarOffsetsList[17][2]}',
    'I49': '${lidarOffsetsList[18][1]}',
    'J49': '${lidarOffsetsList[18][2]}',
    'I50': '${lidarOffsetsList[19][1]}',
    'J50': '${lidarOffsetsList[19][2]}',
    'I51': '${lidarOffsetsList[20][1]}',
    'J51': '${lidarOffsetsList[20][2]}',
    'I52': '${lidarOffsetsList[21][1]}',
    'J52': '${lidarOffsetsList[21][2]}',
    'I53': '${lidarOffsetsList[22][1]}',
    'J53': '${lidarOffsetsList[22][2]}',
    'I54': '${lidarOffsetsList[23][1]}',
    'J54': '${lidarOffsetsList[23][2]}',
    'I55': '${lidarOffsetsList[24][1]}',
    'J55': '${lidarOffsetsList[24][2]}',
    'I56': '${lidarOffsetsList[25][1]}',
    'J56': '${lidarOffsetsList[25][2]}',
    'I57': '${lidarOffsetsList[26][1]}',
    'J57': '${lidarOffsetsList[26][2]}',
    'I58': '${lidarOffsetsList[27][1]}',
    'J58': '${lidarOffsetsList[27][2]}',
    'I59': '${lidarOffsetsList[28][1]}',
    'J59': '${lidarOffsetsList[28][2]}',
    'I60': '${lidarOffsetsList[29][1]}',
    'J60': '${lidarOffsetsList[29][2]}',
    'I61': '${lidarOffsetsList[30][1]}',
    'J61': '${lidarOffsetsList[30][2]}',
    'I62': '${lidarOffsetsList[31][1]}',
    'J62': '${lidarOffsetsList[31][2]}',
    'I63': '${lidarOffsetsList[32][1]}',
    'J63': '${lidarOffsetsList[32][2]}',
    'I64': '${lidarOffsetsList[33][1]}',
    'J64': '${lidarOffsetsList[33][2]}',
    //
    'E6': '$appDirectory${brandImagesAtc['${listContentTxt[0]}']}',
        'E14': listContentTxt.length > 2 ? listContentTxt[1] : '',
        'I88': 'Inertial Labs Calibration Team',
        'I89':
        '${dateToday.month.toString()}/${dateToday.day.toString()}/${dateToday.year.toString()}',
      };
      print('List strings from Readme.txt => $listContentTxt');
      await copyExcelFile(targetTxtFile.parent.path,updateState);
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
  Future<void> copyExcelFile(String saveDirectory,updateState) async {
    print('copyExcelFile');
    var file = File(excelFilePath);
    if (await file.exists()) {
      var bytes = await file.readAsBytes();
      var copiedExcelFilePath =
      p.join(saveDirectory, 'ATC_${listContentTxt[1]}.xlsx');
      var copiedExcelFile = File(copiedExcelFilePath);
      await copiedExcelFile.writeAsBytes(bytes);
      print('Excel file has been copied to $saveDirectory');
      statusOutput = '... ATC_${listContentTxt[1]}.xlsx Created ...';
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
        statusOutput = '... ATC_${listContentTxt[1]}.xlsx Created ...';
      } else {
        print('Python script execution failed.');
        print('Error: ${result.stderr}');
        statusOutput = '... Error: ${result.stderr} ...';
      }
    } catch (e) {
      print('Error running Python script: $e');
    }
  }

  Future<void> parsePpkFiles(String baseAddress) async {
    print('parsePpkFiles');
    Directory boresightDir = Directory(p.join(baseAddress, 'Boresight\\'));
    print('parsePpkFiles => $boresightDir');
    if (await boresightDir.exists()) {
      await for (var entity in boresightDir.list(recursive: true)) {
        if (entity is File && entity.path.endsWith('pcmp')) {
          List<String> offsets = await extractTagContent(entity, 'Offsets');
          lidarOffsetsList = parseTagContent(offsets);

          List<String> filters = await extractTagContent(entity, 'Filters');
          List<List<double>> filtersList = parseTagContent(filters);

          List<List<double>> combinedList = [...lidarOffsetsList, ...filtersList];

          print('Offsets: $lidarOffsetsList');
          print('Filters: $filtersList');
          print('Combined: $combinedList');
        }
      }
    } else {
      print('Boresight directory not found.');
    }
  }

  Future<List<String>> extractTagContent(File file, String tagName) async {
    List<String> tagContent = [];
    List<String> lines = await file.readAsLines();

    bool isTagSection = false;

    for (String line in lines) {
      if (line.contains('<$tagName>')) {
        isTagSection = true;
      } else if (line.contains('</$tagName>')) {
        isTagSection = false;
      } else if (isTagSection) {
        tagContent.add(line.trim());
      }
    }

    return tagContent;
  }

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



}