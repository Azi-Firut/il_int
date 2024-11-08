import 'dart:io';
import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'File Finder',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: FileFinderScreen(),
    );
  }
}

class FileFinderScreen extends StatefulWidget {
  @override
  _FileFinderScreenState createState() => _FileFinderScreenState();
}

class _FileFinderScreenState extends State<FileFinderScreen> {
  final TextEditingController _folderController = TextEditingController();
  String _statusMessage = 'Введите адрес папки и нажмите "Найти файлы"';

  void _processFolder() async {
    final folderPath = _folderController.text;
    final folderName = folderPath.split(Platform.pathSeparator).last;

    // Извлекаем дату и время из названия папки
    final regex = RegExp(r'\d{4}-\d{2}-\d{2}-\d{2}');
    final match = regex.firstMatch(folderName);
    if (match == null) {
      setState(() {
        _statusMessage = "Дата и время не найдены в названии папки.";
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
        _statusMessage = "Не найдена целевая папка: $targetBasePath";
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
        _statusMessage = "Не удалось найти файл: $targetFileName";
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
      _statusMessage = "Скопирован файл: ${targetCopyPath}";
    });

    // Объединяем файлы в один с названием basefile
    final baseFile = File('${dataDir.path}\\basefile');
    final baseSink = baseFile.openWrite();

    // Записываем содержимое targetCopyPath
    await File(targetCopyPath).openRead().pipe(baseSink);

    if (nextFile != null) {
      final nextCopyPath = '${dataDir.path}\\${nextFile.path.split(Platform.pathSeparator).last}';
      await nextFile.copy(nextCopyPath);
      setState(() {
        _statusMessage += "\nСкопирован следующий файл: ${nextCopyPath}";
      });

      // Записываем содержимое nextCopyPath
      await File(nextCopyPath).openRead().pipe(baseSink);
    } else {
      setState(() {
        _statusMessage += "\nСледующий файл не найден, объединяем только targetCopyPath.";
      });
    }

    // Закрываем поток записи
    await baseSink.close();

    setState(() {
      _statusMessage += "\nФайлы объединены в ${baseFile.path}.";
    });
  }




  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('File Finder'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _folderController,
              decoration: InputDecoration(
                labelText: 'Адрес папки',
                hintText: 'Введите полный адрес папки...',
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _processFolder,
              child: Text('Найти файлы'),
            ),
            SizedBox(height: 20),
            Text(
              _statusMessage,
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
