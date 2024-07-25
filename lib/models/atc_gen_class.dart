import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:flutter/services.dart' show rootBundle;
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import '../constant.dart';
import 'data.dart';

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
  var appDirectory;
  String pathToImg='\\assets\\fill_atc\\atc_template\\logo_img_atc\\RESEPI.png';


  void parseFolder(address,updateState) async {
    appDirectory = Directory.current.path;
    print('Il_int work directory => $appDirectory');
    var _address=await address;
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
      List<String> lines = await targetTxtFile.readAsLines();
      listContentTxt = lines.map((line) {
        int colonIndex = line.indexOf(':');
        return colonIndex != -1 ? line.substring(colonIndex + 1).trim() : line;
      }).toList();
      DateTime dateToday=DateTime.now();
      mapListContent = {
        'adressXLSX': '$_address\\ATC_${listContentTxt[0]}.xlsx',
        'D6': listContentTxt.length > 2 ? listContentTxt[0] : '',
        'D7': listContentTxt.length > 3 ? listContentTxt[5] : '',
        'D8': listContentTxt.length > 4 ? listContentTxt[4] : '',
        'D9': listContentTxt.length > 5 ? listContentTxt[6] : '',
        'D10': listContentTxt.length > 5 ? listContentTxt[1] : '',
        'D11': listContentTxt.length > 5 ? listContentTxt[3] : '',
        'E4': '$appDirectory$pathToImg',

        'I87': 'Inertial Labs',
        'I88': '${dateToday.month.toString()}/${dateToday.day.toString()}/${dateToday.year.toString()}',

      };
      print('List strings from Readme.txt => $listContentTxt');
      await copyExcelFile(targetTxtFile.parent.path);

      // Serialize mapListContent to JSON and pass it to the Python script
      String jsonData = jsonEncode(mapListContent);
      await runPythonScript(jsonData);
    } else {
      print('Text file not found.');
      statusOutput = '... Enter Unit Serial Number ...';
    }
    updateState();
  }

  Future<void> copyExcelFile(String saveDirectory) async {
    var file = File(excelFilePath);
    if (await file.exists()) {
      var bytes = await file.readAsBytes();
      var copiedExcelFilePath =
          p.join(saveDirectory, 'ATC_${listContentTxt[0]}.xlsx');
      var copiedExcelFile = File(copiedExcelFilePath);
      await copiedExcelFile.writeAsBytes(bytes);
      print('Excel file has been copied to $saveDirectory');
      statusOutput = '... ATC_${listContentTxt[0]}.xlsx Created ...';
    } else {
      print('Excel file not found.');
      statusOutput = '... Error: I can\'t find the ATC template ...';
    }

  }

  Future<void> runPythonScript(String jsonData) async {
    // Assuming the exe file is located at 'assets/python_script.exe'
    String pythonScriptPath = 'assets/fill_atc/fill_xlsx.exe';

    try {
      var result = await Process.run(pythonScriptPath, [jsonData]);
      if (result.exitCode == 0) {
        print('Python script executed successfully.');
        print('Output: ${result.stdout}');
        statusOutput = '... ATC_${listContentTxt[0]}.xlsx Created ...';
      } else {
        print('Python script execution failed.');
        print('Error: ${result.stderr}');
        statusOutput = '... Error: ${result.stderr} ...';
      }
    } catch (e) {
      print('Error running Python script: $e');
    }
  }
}
