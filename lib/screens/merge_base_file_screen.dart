import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cross_file/cross_file.dart';
import 'dart:io';
import 'package:dcat/dcat.dart';
import '../constant.dart';

class MergeBaseFiles extends StatefulWidget {
  const MergeBaseFiles({Key? key}) : super(key: key);

  @override
  _MergeBaseFilesState createState() => _MergeBaseFilesState();
}

class _MergeBaseFilesState extends State<MergeBaseFiles> {
  bool _dragging = false;
  Offset? offset;
  late XFile firstDrag;
  late XFile secondDrag;
  final List<XFile> listX = [];
  String dragAndDropMessage = "Drop folder of yor project here ";
  var nextCopyPath = '';

  void processFolder(filePath) async {
    final folderPath = filePath;
    final folderName = folderPath.split(Platform.pathSeparator).last;

    // Извлекаем дату и время из названия папки
    final regex = RegExp(r'\d{4}-\d{2}-\d{2}-\d{2}');
    final match = regex.firstMatch(folderName);
    if (match == null) {
      setState(() {
        dragAndDropMessage = "Date and time not found in folder name ";
      });
      return;
    }

    final dateTimeString = match.group(0)!;
    final dateParts = dateTimeString.split('-');

    final year = dateParts[0];
    final month = dateParts[1];
    final day = dateParts[2];
    final hour = dateParts[3];

    // Путь к папке RTCM3_BL_East
    final targetBasePath = 'N:\\RTCM3_BL_East\\$year\\$month\\$day';
    final targetDir = Directory(targetBasePath);

    if (!await targetDir.exists()) {
      setState(() {
        dragAndDropMessage = "Destination folder not found: $targetBasePath";
      });
      return;
    }

    // Ищем нужный файл в целевой папке
    final targetFileName = 'bl-$year-$month-$day-$hour-00.bin';
    final files = targetDir.listSync();

    File? targetFile;
    File? nextFile;
    bool foundTarget = false;

    for (var file in files) {
      if (file is File && file.path.contains(targetFileName)) {
        targetFile = file;
        foundTarget = true;
      } else if (foundTarget && file is File) {
        nextFile = file;
        break;
      }
    }

    if (targetFile == null) {
      setState(() {
        dragAndDropMessage = "Could not find file: $targetFileName";
      });
      return;
    }

    // Копируем файлы в папку data внутри исходной папки
    final dataDir = Directory('${folderPath}\\data');
    if (!await dataDir.exists()) {
      await dataDir.create();
    }

    final targetCopyPath = '${dataDir.path}\\${targetFile.path.split(Platform.pathSeparator).last}';
    await targetFile.copy(targetCopyPath);
    setState(() {
      dragAndDropMessage = "File copied: ${targetCopyPath}";
    });

    // Объединяем файлы в один с названием basefile
    final baseFile = File('${dataDir.path}\\basefile');
    final baseSink = baseFile.openWrite();

    // Записываем содержимое targetCopyPath
    await File(targetCopyPath).openRead().pipe(baseSink);

    if (nextFile != null) {
      nextCopyPath = '';
      nextCopyPath = '${dataDir.path}\\${nextFile.path.split(Platform.pathSeparator).last}';
      await nextFile.copy(nextCopyPath);
      listX.add(XFile(targetCopyPath));
      listX.add(XFile(nextCopyPath));
      merge();


      setState(() {
        dragAndDropMessage += "\nFile copied: ${nextCopyPath}";
      });

      // Записываем содержимое nextCopyPath
      await File(nextCopyPath).openRead().pipe(baseSink);
    } else {
      ///
      //закидуем адреса двух файлов драг енд дроп


      setState(() {
        dragAndDropMessage += "\n______________________________________";
      });
    }

    // Закрываем поток записи
    await baseSink.close();

    setState(() {
      dragAndDropMessage += "\nThe files are merged into ${baseFile.path}.";
    });
  }

  Future<void> merge() async {
    if (listX.length == 2) {
      var slot0 = listX[0].name.split("-");
      slot0.removeLast();
      var slot0Val = int.parse(slot0[slot0.length - 1]);
      var slot1 = listX[1].name.split("-");
      slot1.removeLast();
      var slot1Val = int.parse(slot1[slot1.length - 1]);

      if (slot0Val < slot1Val) {
        firstDrag = listX[0];
        secondDrag = listX[1];
      } else {
        firstDrag = listX[1];
        secondDrag = listX[0];
      }

      print('--------  ${slot0Val}');
      print('--------  ${slot0Val.runtimeType}');
    }

    String outputPath = listX[0].path;
    List<String> putiy = outputPath.split("\\");
    putiy.removeLast();
    putiy.add('basefile');
    var directoryPath = putiy.join("/");

    print('Output directory --------  ${directoryPath}');

    final result = await cat(
        [firstDrag.path, secondDrag.path], File(directoryPath).openWrite());
    if (result.isFailure) {
      for (final error in result.errors) {
        print('Error: ${error.message}');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DropTarget(
      onDragDone: (detail) async {
        setState(() async {
          listX.clear(); // Clear previous files
          for (final file in detail.files) {
            if (await FileSystemEntity.isDirectory(file.path)) {
              processFolder(file.path);
          debugPrint('You have dropped a folder: ${file.path}');
          } else {
          listX.add(file);
          debugPrint('${file.name}\n'
          '${file.path}\n'
          '${file.readAsBytes().toString()}\n'
          '${detail.files}\n');
          }
          }
          if (listX.length == 2) {
          merge();
          }
        });
      },
      onDragUpdated: (details) {
        setState(() {
          offset = details.localPosition;
        });
      },
      onDragEntered: (detail) {
        setState(() {
          _dragging = true;
          offset = detail.localPosition;
          if (offset != null && listX.length == 0) {
            dragAndDropMessage = "Drop it";
          } else {
            dragAndDropMessage = "Select two files and drop here";
          }
        });
      },
      onDragExited: (detail) {
        setState(() {
          _dragging = false;
          offset = null;
        });
      },
      child: Container(
        height: MediaQuery.of(context).size.height - 32,
        color: _dragging ? Color(0xF00A4FC) : Colors.transparent,
        child: Stack(
          children: [
            if (listX.isEmpty)
              Center(
                child: Text(
                  dragAndDropMessage,
                  style: TextStyle(
                    color: textColorGray,
                  ),
                ),
              ),
            if (listX.length == 1)
              Center(
                child: Text(
                  textAlign: TextAlign.center,
                  "${listX[0].path}\nAnd the second file please",
                  style: TextStyle(
                    color: textColorGray,
                  ),
                ),
              ),
            if (listX.length == 2)
              Center(
                child: Text(
                  "${listX.map((e) => e.path).join("\n")}\n\nThese two files are merged\nAll the best to you!",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: textColorGray,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
