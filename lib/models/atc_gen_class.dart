import 'dart:convert';
import 'dart:io';
//import 'dart:nativewrappers/_internal/vm/lib/core_patch.dart';
import 'package:path/path.dart' as p;
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
  //var address=addressToFolder;
  //var address = context.read<Data>().getUnitAddressForAtc;
  // var address = context.watch<Data>()..getUnitAddressForAtc;
  // String address =
  //     'C:\\Users\\Zver\\Desktop\\atc_gen\\RECEPI_RCP-L36A4776'; // Example path
  String excelFilePath = templateAtcPath; // Exact path to Excel file
  String? unitNum;
  List<String> listContentTxt = [];
  Map<String, String> mapListContent = {};

  void parseFolder(address) async {
    unitNum = p.basename(address).split('_').last;
    Directory dir = Directory(address);
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
      mapListContent = {
        'adressXLSX': '$address\\ATC_${listContentTxt[0]}.xlsx',
        'D6': listContentTxt.length > 2 ? listContentTxt[0] : '',
        'D7': listContentTxt.length > 3 ? listContentTxt[5] : '',
        'D8': listContentTxt.length > 4 ? listContentTxt[4] : '',
        'D9': listContentTxt.length > 5 ? listContentTxt[6] : '',
        'D10': listContentTxt.length > 5 ? listContentTxt[1] : '',
        'D11': listContentTxt.length > 5 ? listContentTxt[3] : '',
      };
      await copyExcelFile(targetTxtFile.parent.path);

      // Serialize mapListContent to JSON and pass it to the Python script
      String jsonData = jsonEncode(mapListContent);
      await runPythonScript(jsonData);
    } else {
      print('Text file not found.');
    }
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
    } else {
      print('Excel file not found.');
    }
  }

  Future<void> runPythonScript(String jsonData) async {
    // Assuming the exe file is located at 'assets/python_script.exe'
    String pythonScriptPath = 'assets/fill_xlsx.exe';

    try {
      var result = await Process.run(pythonScriptPath, [jsonData]);
      if (result.exitCode == 0) {
        print('Python script executed successfully.');
        print('Output: ${result.stdout}');
      } else {
        print('Python script execution failed.');
        print('Error: ${result.stderr}');
      }
    } catch (e) {
      print('Error running Python script: $e');
    }
  }
}
