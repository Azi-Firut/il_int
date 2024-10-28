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

class ReadMeClass {
  static final ReadMeClass _instance = ReadMeClass._internal();

  factory ReadMeClass() {
    return _instance;
  }

  ReadMeClass._internal();

  createFoldersAndFile(updateState) async {

    String imu=unitInfo[1];
    String lidar=unitInfo[2];
    String supplier=unitInfo[0].trim();
    String gnss=unitInfo[3];
    print ('createFoldersAndFile -- unitInfo \n$unitInfo');
    // Путь к основной папке
    String basePath = 'N:/!Factory_calibrations_and_tests/RESEPI';
    String supplierFolderPath = '$basePath/$supplier';

    // Проверяем, существует ли папка для поставщика, если нет, создаем её
    Directory supplierDirectory = Directory(supplierFolderPath);
    if (!await supplierDirectory.exists()) {
      await supplierDirectory.create(recursive: true);
    }

    // Путь к папке "Тест"
    String testFolderPath = '$supplierFolderPath\\$supplier-$imu';
    Directory testDirectory = Directory(testFolderPath);
    if (!await testDirectory.exists()) {
      await testDirectory.create(recursive: true);
    }

    // Путь к папке "Boresight"
    String boresightFolderPath = '$testFolderPath\\Boresight';
    Directory boresightDirectory = Directory(boresightFolderPath);
    if (!await boresightDirectory.exists()) {
      await boresightDirectory.create(recursive: true);
    }

    // Путь к текстовому файлу
    String filePath = '$testFolderPath\\$supplier-$imu.txt';
    File file = File(filePath);

    // Содержание файла
    String fileContent = '''
Supplier:      $supplier
Unit SN:       ??????
Model:         ??????         ( RESEPI , RECON-XT , RESEPI GEN2 , FLIGHTS Scan , Wingtra LIDAR ) 
Build Number:  ??????
Motherboard:   9V; up to 45V
IMU:           $imu
Lidar:         $lidar
GNSS:          $gnss
Camera:        ADTI; lens 2.8/16     ( ABSENT , ADTI; lens 2.8/16 , Sony ILX-LR1, 18mm lens ) 
Other:         SKYPORT               ( ABSENT , SKYPORT )
Boresight:     COMPLETE
''';

    // Записываем данные в файл
    await file.writeAsString(fileContent);

    // Открываем файл после создания
    Process.run('notepad.exe', [filePath]);
  }

}



