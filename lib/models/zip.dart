import 'dart:io';
import 'package:archive/archive.dart';
import 'package:path/path.dart' as path;

import '../widgets/answer_from_unit.dart';

void zipCompress(String sourceDirPath,String outputZipPath) {
  pushUnitResponse(0,"Creating ZIP file started");
  final sourceDir = Directory(sourceDirPath);
  if (!sourceDir.existsSync()) {
    print('Директория не найдена!');
    pushUnitResponse(2,"Fail to create ZIP file");
    return;
  }

  // Создаём архив
  print('ЗИПУЮ. жди......');
  final archive = Archive();
   // Добавляем файлы и папки в архив
  for (var file in sourceDir.listSync(recursive: true)) {
    final filePath = file.path.replaceFirst(sourceDirPath, '');
    if (file is File) {
      // Чтение файла как байтовый массив
      final fileBytes = file.readAsBytesSync();
      final archiveFile = ArchiveFile(
        filePath,
        fileBytes.length,
        fileBytes,
      );
      archiveFile.compress = true; // Устанавливаем максимальное сжатие
      archive.addFile(archiveFile);
    }
  }

  // Создаём ZIP файл
  pushUnitResponse(0,"Creating ZIP file started");
  final zipData = ZipEncoder().encode(archive, level: Deflate.DEFAULT_COMPRESSION);
  final fileZipPath = path.join(outputZipPath, 'Boresight.zip');
  print('ZIP fileZipPath ==  $fileZipPath');
  File(fileZipPath).writeAsBytesSync(zipData!);

  print('Папка успешно заархивирована в $outputZipPath');
  pushUnitResponse(1,"ATC and ZIP file created");
}

