import 'package:flutter/material.dart';
import 'package:il_int/models/ssh.dart';
import 'package:il_int/screens/prod_screen.dart';
import 'dart:io';
import 'package:provider/provider.dart';
import '../constant.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../widgets/answer_from_unit.dart';
import 'data.dart';


class InitialParamListWidget extends StatefulWidget {
  final String directoryPath;

  final Function recolState;


  const InitialParamListWidget({Key? key, required this.directoryPath, required this.recolState}) : super(key: key);

  @override
  _InitialParamListWidgetState createState() => _InitialParamListWidgetState();
}

class _InitialParamListWidgetState extends State<InitialParamListWidget> {
  List<FileSystemEntity> _files = [];
  String? _selectedFile; // Для хранения пути выбранного файла
  bool _showFileList = false; // Управляет показом списка файлов




  @override
  void initState() {
    super.initState();
    _listFiles(); // Загружаем файлы при инициализации
  }
  void updateState() {
    setState(() {});
  }

  Future<void> _listFiles() async {
    final dir = Directory(widget.directoryPath);

    if (await dir.exists()) {
      setState(() {
        // Фильтруем только файлы с расширением .txt
        _files = dir.listSync().where((file) => file.path.endsWith('.txt')).toList();
      });
    } else {
      setState(() {
        _files = [];
      });
      print('Directory does not exist');
    }
  }

  // Метод для чтения содержимого файла
  Future<String> _readFileContent(String path) async {
    try {
      final file = File(path);
      return await file.readAsString();
    } catch (e) {
      return 'Fail to read file';
    }
  }

  // Метод для обработки выбора файла
  void _onFileSelected(String? filePath) {
    setState(() {
      _selectedFile = filePath;
    });
  }

  // Метод для переключения отображения списка файлов
  void _toggleFileList() {
    setState(() {
      _showFileList = !_showFileList;
      if (_showFileList) {
        _listFiles(); // Загружаем файлы при показе списка
      }
    });
  }

  void parseInitTxt(filePathToInitFile) async {
    // Путь к файлу
    String filePath = filePathToInitFile;

    try {
      // Чтение файла и получение списка строк
      List<String> lines = await File(filePath).readAsLines();
      uploadInitialToUnit(lines);
      // Вывод строк в консоль
      for (var line in lines) {
        print(line);
      }
    } catch (e) {
      pushUnitResponse(2,"Fail to read file",updateState: widget.recolState);
    }
  }

  void wingtraLidarInject(lidarFovToInject) async {
    var urlSetAngleRangeFix = 'http://192.168.12.1:8001/pandar.cgi?action=set&object=lidar_data&key=lidar_range';
    int fovMin = int.parse(lidarFovToInject.split(' ').first);
    int fovMax = int.parse(lidarFovToInject.split(' ').last);
    int fovAngleTimesTen(int angle) => angle * 10;
    // Подготовка данных для отправки
    var data = [
      fovAngleTimesTen(fovMin),
      fovAngleTimesTen(fovMax)
    ];
    var jsonData = jsonEncode({
      'angle_setting_method': 0, // всегда 0
      'lidar_range': data
    });

    try {
      // Отправляем POST запрос
      final response = await http.post(
        Uri.parse(urlSetAngleRangeFix),
        headers: {'Content-Type': 'application/json'},
        body: jsonData,
      );
      print('=====  ${response}');
      if (response.statusCode == 200) {
        // Если запрос был успешным, можем обработать результат
        print('Данные успешно отправлены!');
        print('Ответ сервера: ${response.body}');
      } else {
        // Если произошла ошибка
        print('Ошибка: ${response.statusCode}');
        print('Ответ сервера: ${response.body}');
      }
    } catch (e) {
        print('Ошибка при чтении файла: $e');
    }
  }
// void trowToGui(step,text)async{
//     pushUnitResponse(step,text,updateState);
// }

  void uploadInitialToUnit(List<String> lines) async {

    pushUnitResponse(0,"The procedure started",updateState: widget.recolState);
    updateState();
    //trowToGui(0, "TEST");

    if (await lines.isNotEmpty) {
      pushUnitResponse(0,"The procedure started",updateState: widget.recolState);
      updateState();
      if (await createTempKeyFile()) {
        try {
          print('===[1]=== ${lines.length}');

          var process = await Process.start(
            plinkPath,
            ['-i', keyPath, 'root@192.168.12.1', '-hostkey', hostKey, "cd /etc/payload && mount -o remount,rw / && echo '${lines[4]}\n${lines[5]}' > cameras && exit"],
          );
           process = await Process.start(
            plinkPath,
            ['-i', keyPath, 'root@192.168.12.1', '-hostkey', hostKey, "cd /etc/payload && mount -o remount,rw / && echo '${lines[3]}\n' > boresight && exit"],
          );
          process = await Process.start(
            plinkPath,
            ['-i', keyPath, 'root@192.168.12.1', '-hostkey', hostKey, "cd /etc/payload && mount -o remount,rw / && echo '${lines[2]}\n' > FOV && exit"],
          );
          process = await Process.start(
            plinkPath,
            ['-i', keyPath, 'root@192.168.12.1', '-hostkey', hostKey, "cd /etc/payload && mount -o remount,rw / && echo '${lines[6]}\n${lines[7]}\n${lines[8]}\n${lines[9]}\n${lines[10]}\n' > config && exit"],
          );

          Future<void> restartUnit() async {
            if (await createTempKeyFile()) {
              pushUnitResponse(1,"Initial parameters uploaded\nThe unit will be rebooted",updateState: widget.recolState);
              updateState();
              try {
                var processRestartUnit = await Process.start(
                  plinkPath,
                  ['-i', keyPath, 'root@192.168.12.1', '-hostkey', hostKey, "systemctl restart payload"],
                );
                await Future.delayed(Duration(seconds: 1), () async {
                  processRestartUnit.kill();
                  await deleteTempKeyFile();
                });
              } catch (e) {}
              finally {}
            }
          }

          try {
            if (lines.length >= 12 && lines[12].split(' ').first.trim() == "WINGTRA") {
              print("${lines[12]}\n${lines[13]} run lidar injection");
              wingtraLidarInject(lines[13]);

            } else {
              print("Not matched: '${lines[12].split(' ').first.trim()}'");
            }
          } catch (e) {
            print("Error: $e");
          }

          // Вывод стандартного вывода процесса
          process.stdout.transform(SystemEncoding().decoder).listen((data) {
            print('stdout: $data');
          });

          // Вывод стандартной ошибки процесса
          process.stderr.transform(SystemEncoding().decoder).listen((data) {
            print('stderr: $data');
          });

          // Ожидание завершения процесса
          var exitCode = await process.exitCode;
          print('Process exited with code $exitCode');
          if(exitCode == 1){
            pushUnitResponse(2,"Failed to upload initial parameters:\ncheck all conditions before start",updateState: widget.recolState);
            updateState();
          }else{
            restartUnit();
            process.kill();
          }
        } catch (e) { pushUnitResponse(2,"Procedure failed\n$e",updateState: widget.recolState);
        } finally {
         await deleteTempKeyFile();
        }
      } else {
        pushUnitResponse(2,"Procedure failed",updateState: widget.recolState);
        updateState();
      }
    }else{
    }
}

  void uploadFile() {
    if (_selectedFile != null) {
      parseInitTxt(_selectedFile);
      setState(() {
        _files.clear(); // Очищаем список файлов
        _selectedFile = null; // Сбрасываем выбор файла
        _showFileList = false; // Скрываем список
     });
    } else {
      pushUnitResponse(3,"Parameter file is not selected",updateState: widget.recolState);
      print('Файл не выбран');
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ElevatedButton(
            onPressed: _toggleFileList,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF02567E),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            child: Text(
              _showFileList ? 'Close tab' : 'Initial Parameters',
              style: const TextStyle(
                color: Color(0xFFFFFFFF),
              ),
            ),
          ),
          _showFileList
              ? ListView.builder(
            shrinkWrap: true,
            itemCount: _files.length,
            itemBuilder: (context, index) {
              FileSystemEntity file = _files[index];
              String fileName = file.path.split('\\').last;
              return ListTile(
                contentPadding: EdgeInsets.all(1),
                title: SelectableText(
                  fileName,
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFFADACAC),
                  ),
                ),
                trailing: Radio<String>(
                  overlayColor: MaterialStateProperty.resolveWith(
                          (states) => Colors.black12),
                  fillColor: MaterialStateProperty.resolveWith(
                          (states) => Color(0xFF885F2E)),
                  value: file.path,
                  groupValue: _selectedFile,
                  onChanged: _onFileSelected,
                ),
                onTap: () {
                  _readFileContent(file.path).then((content) {
                    // Устанавливаем выбранный файл как просматриваемый файл
                    setState(() {
                      _selectedFile = file.path;
                    });

                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          backgroundColor: Color(0xFF222223),
                          title: const Center(
                            child: Text(
                              'Configuration file preview',
                              style: TextStyle(
                                fontSize: 18,
                                color: Color(0xFFADACAC),
                              ),
                            ),
                          ),
                          content: SingleChildScrollView(
                            child: SelectableText(
                              content,
                              style: TextStyle(
                                fontSize: 14,
                                color: Color(0xFFADACAC),
                              ),
                            ),
                          ),
                          actions: [
                            TextButton(
                              child: Text(
                                'Upload',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFFFFFFFF),
                                ),
                              ),
                              onPressed: () {
                                // Загружаем выбранный файл
                                uploadFile();
                                Navigator.of(context).pop(); // Закрываем диалог
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF3F941B),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    );
                  });
                },
              );
            },
          )
              : Container(),
          if (_showFileList)
            ElevatedButton(
              onPressed: uploadFile, // Вызов общего метода
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3F941B),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              child: Text(
                'Upload Initial parameters',
                style: TextStyle(
                  color: Color(0xFFFFFFFF),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
