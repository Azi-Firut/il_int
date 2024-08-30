// import 'dart:convert';
// import 'dart:io';
// import 'package:path/path.dart' as p;
// import '../constant.dart';
//
//
// class AtcGenerator {
//   static final AtcGenerator _instance = AtcGenerator._internal();
//   factory AtcGenerator() {
//     return _instance;
//   }
//   AtcGenerator._internal();
//   String statusOutput = '';
//   String excelFilePath = templateAtcPath; // Exact path to Excel file
//   String? unitNum;
//   List<String> listContentTxt = [];
//   Map<String, String> mapListContent = {};
//   List<List<double>> lidarOffsetsList = [];
//   List<List<double>> filtersList = [];
//   var appDirectory;
//
//   /// 1
//   void parseFolder(address, updateState) async {
//     listContentTxt = [];
//     mapListContent = {};
//     lidarOffsetsList = [];
//     filtersList = [];
//
//     print('== 1 parseFolder');
//     appDirectory = Directory.current.path;
//     print('Il_int work directory => $appDirectory');
//     var _address = await address;
//     unitNum = p.basename(_address).split('_').last;
//     Directory dir = Directory(_address);
//     File? targetTxtFile;
//     await for (var entity in dir.list()) {
//       if (entity is File &&
//           entity.path.contains(unitNum!) &&
//           entity.path.endsWith('.txt')) {
//         targetTxtFile = entity;
//         break;
//       }
//     }
//     if (targetTxtFile != null) {
//       // Parse PPK files
//       await parsePpkFiles(_address); // ==> 2
//
//       List<String> lines = await targetTxtFile.readAsLines();
//       listContentTxt = lines.map((line) {
//         int colonIndex = line.indexOf(':');
//         return colonIndex != -1 ? line.substring(colonIndex + 1).trim() : line;
//       }).toList();
//       DateTime dateToday = DateTime.now();
//       mapListContent =  mapOffsetsForAtc(_address,listContentTxt,lidarOffsetsList,appDirectory,dateToday);
//
//       print('List strings from Readme.txt => $listContentTxt');
//       await copyExcelFile(targetTxtFile.parent.path, updateState);
//       // Serialize mapListContent to JSON and pass it to the Python script
//       String jsonData = jsonEncode(mapListContent);
//
//
//       // Fill exel file
//       await runPythonScript(jsonData);
//     } else {
//       print('Text file not found.');
//       statusOutput = '... Text file not found ...';
//     }
//     updateState();
//   }
//
//   Future<void> copyExcelFile(String saveDirectory, updateState) async {
//     print('copyExcelFile');
//     var file = File(templatePath(lidarOffsetsList));
//     if (await file.exists()) {
//       var bytes = await file.readAsBytes();
//       var copiedExcelFilePath =
//       p.join(saveDirectory, 'ATC_${listContentTxt[1]}.xlsx');
//       var copiedExcelFile = File(copiedExcelFilePath);
//       await copiedExcelFile.writeAsBytes(bytes);
//       print('Excel file has been copied to $saveDirectory');
//       statusOutput = '... ATC_${listContentTxt[1]}.xlsx Created ...';
//     } else {
//       print('Excel file not found.');
//       statusOutput = '... Error: I can\'t find the ATC template ...';
//     }
//     updateState();
//   }
//
//   Future<void> runPythonScript(String jsonData) async {
//     print('runPythonScript');
//     // Assuming the exe file is located at 'assets/python_script.exe'
//     String pythonScriptPath = 'assets/fill_atc/fill_xlsx.exe';
//     try {
//       var result = await Process.run(pythonScriptPath, [jsonData]);
//       if (result.exitCode == 0) {
//         print('Python script executed successfully.');
//         print('Output: ${result.stdout}');
//         statusOutput = '... ATC_${listContentTxt[1]}.xlsx Created ...';
//       } else {
//         print('Python script execution failed.');
//         print('Error: ${result.stderr}');
//         statusOutput = '... Error: ${result.stderr} ...';
//       }
//     } catch (e) {
//       print('Error running Python script: $e');
//     }
//   }
//
//   /// 2
//   Future<void> parsePpkFiles(String baseAddress) async {
//     print('== 2 parsePpkFiles');
//     Directory boresightDir = Directory(p.join(baseAddress, 'Boresight\\'));
//     print('== 2 parsePpkFiles => $boresightDir');
//
//     if (await boresightDir.exists()) {
//       await for (var entity in boresightDir.list(recursive: false)) {
//         print('== 2 $entity');
//         if (entity is Directory) {
//           List<List<double>> combinedList = [];
//
//           await for (var subEntity in entity.list(recursive: false)) {
//             print('== 2 $subEntity');
//
//             if (subEntity is File && p.basename(subEntity.path) == 'ppk.pcmp') {
//               print('Processing file: ${subEntity.path}');
//               // Parse the `ppk` file content here
//               List<String> offsets = await extractTagContent(subEntity, 'Offsets');
//               lidarOffsetsList = await parseTagContent(offsets);
//
//               List<String> filters = await extractTagContent(subEntity, 'Filters');
//               filtersList = await parseTagContent(filters);
//
//               combinedList = [...lidarOffsetsList, ...filtersList];
//
//               print('Offsets: $lidarOffsetsList');
//               print('Offsets length: ${lidarOffsetsList.length}');
//               print('Filters: $filtersList');
//               print('Combined: $combinedList');
//             }
//           }
//
//           // Process ppk.pcpp files after ppk.pcmp files
//           await for (var subEntity in entity.list(recursive: false)) {
//             if (subEntity is File && p.basename(subEntity.path) == 'ppk.pcpp') {
//               print('Processing file: ${subEntity.path}');
//               // Parse the `ppk` file content here
//               List<String> offsets = await extractTagContent(subEntity, 'Offsets');
//               List<List<double>> newOffsets = await parseTagContent(offsets);
//
//               lidarOffsetsList.addAll(newOffsets);
//               combinedList.addAll(newOffsets);
//
//               // print('Offsets: $lidarOffsetsList');
//               print('Offsets length: ${lidarOffsetsList.length}');
//               print('Combined: $combinedList');
//             }
//           }
//         }
//       }
//       // Parse the Service.log file
//        File serviceLogFile = File(p.join(baseAddress, 'Service.log'));
//          if (await serviceLogFile.exists()) {
//         print('Processing Service.log: ${serviceLogFile.path}');
//         Map<String, String> serviceLogData = await parseServiceLog(serviceLogFile);
//         print('Service log data: $serviceLogData');
//           } else {
//         print('Service.log file not found.');
//          }
//
//
//     } else {
//       print('Boresight directory not found.');
//     }
//   }
//   ///
//   Future<Map<String, String>> parseServiceLog(File file) async {
//     Map<String, String> logData = {};
//     List<String> lines = await file.readAsLines();
//
//     for (String line in lines) {
//       int colonIndex = line.indexOf(':');
//       if (colonIndex != -1) {
//         String value = line.substring(colonIndex + 1).trim();
//         logData[line] = value;
//       }
//       print(logData);
//     }
//
//     return logData;
//      }
//   /// 4
//   Future<List<String>> extractTagContent(File file, String tagName) async {
//     List<String> tagContent = [];
//     List<String> lines = await file.readAsLines();
//
//     bool isTagSection = false;
//
//     for (String line in lines) {
//       if (line.contains('<$tagName')) {
//         isTagSection = true;
//       } else if (line.contains('</$tagName>')) {
//         isTagSection = false;
//       } else if (isTagSection) {
//         tagContent.add(line.trim());
//       }
//     }
//
//     return tagContent;
//   }
//   /// 3
//   List<List<double>> parseTagContent(List<String> content) {
//     List<List<double>> result = [];
//
//     for (String item in content) {
//       RegExp regExp = RegExp(r'[-+]?[0-9]*\.?[0-9]+');
//       Iterable<Match> matches = regExp.allMatches(item);
//       List<double> values = matches.map((match) => double.parse(match.group(0)!)).toList();
//       result.add(values);
//     }
//
//     return result;
//   }
// }
