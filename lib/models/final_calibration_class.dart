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


class FinalParamListWidget extends StatefulWidget {
  final String directoryPath;

  final Function recolState;

  const FinalParamListWidget({Key? key, required this.directoryPath,required this.recolState}) : super(key: key);

  @override
  _FinalParamListWidgetState createState() => _FinalParamListWidgetState();
}

class _FinalParamListWidgetState extends State<FinalParamListWidget> {

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
      context.read<Data>().pushResponse("Error reading file: $e");
      return 'Ошибка при чтении файла.';
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

  void parseFinalTxt(filePathToInitFile) async {

    // Путь к файлу
    String filePath = filePathToInitFile;
      try {
      // Чтение файла и получение списка строк
      List<String> lines = await File(filePath).readAsLines();
      uploadFinalToUnit(lines);
      // Вывод строк в консоль
      for (var line in lines) {
        print(line);
      }
    } catch (e) {
      context.read<Data>().pushResponse("Error reading file: $e");
      print('Ошибка при чтении файла: $e');
    }
  }

  Future<void> restartUnit() async {
    if (await createTempKeyFile()) {
      print('Рестарт');
           pushUnitResponse(1,"Final parameters uploaded\nThe unit will be rebooted",updateState:widget.recolState);
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
      finally {
        pushUnitResponse(1,"Final parameters uploaded\nThe unit will be rebooted",updateState:widget.recolState);
        updateState();
      }
    }
  }

  // void wingtraLidarInject(lidarFovToInject) async {
  //   var urlSetAngleRangeFix = 'http://192.168.12.1:8001/pandar.cgi?action=set&object=lidar_data&key=lidar_range';
  //   int fovMin = int.parse(lidarFovToInject.split(' ').first);
  //   int fovMax = int.parse(lidarFovToInject.split(' ').last);
  //   int fovAngleTimesTen(int angle) => angle * 10;
  //   // Подготовка данных для отправки
  //   var data = [
  //     fovAngleTimesTen(fovMin),
  //     fovAngleTimesTen(fovMax)
  //   ];
  //   var jsonData = jsonEncode({
  //     'angle_setting_method': 0, // всегда 0
  //     'lidar_range': data
  //   });
  //
  //   try {
  //     // Отправляем POST запрос
  //     final response = await http.post(
  //       Uri.parse(urlSetAngleRangeFix),
  //       headers: {'Content-Type': 'application/json'},
  //       body: jsonData,
  //     );
  //     print('=====  ${response}');
  //     if (response.statusCode == 200) {
  //       // Если запрос был успешным, можем обработать результат
  //       print('Данные успешно отправлены!');
  //       print('Ответ сервера: ${response.body}');
  //     } else {
  //       // Если произошла ошибка
  //       print('Ошибка: ${response.statusCode}');
  //       print('Ответ сервера: ${response.body}');
  //     }
  //   } catch (e) {
  //     print('Ошибка при чтении файла: $e');
  //   }
  // }

  void uploadFinalToUnit(List<String> lines) async {
    pushUnitResponse(0,"The procedure started",updateState:widget.recolState);
    updateState();
       if (await lines.isNotEmpty) {
           if (await createTempKeyFile()) {
            var process;
        try {
          print('uploadFinalToUnit => ${lines.length}');
          print('uploadFinalToUnit => ${lines[3].split(' ').first}');
          if(lines[2].trim() != '#'){
           process = await Process.start(
            plinkPath,
            ['-i', keyPath, 'root@192.168.12.1', '-hostkey', hostKey, "cd /etc/payload && mount -o remount,rw / && echo '${lines[2]}\n' > FOV && exit"],
          );}
          if(lines[3].trim() != '#'){
           process = await Process.start(
            plinkPath,
            ['-i', keyPath, 'root@192.168.12.1', '-hostkey', hostKey, 'cd /etc/payload && mount -o remount,rw / && sed -i \'s/^' + lines[3].split(' ').first + '.*/' + lines[3] + '/\' boresight && exit'],
          );}
          if(lines[4].trim() != '#'){
            process = await Process.start(
              plinkPath,
              ['-i', keyPath, 'root@192.168.12.1', '-hostkey', hostKey, "cd /etc/payload && mount -o remount,rw / && echo '${lines[4]}\n${lines[5]}' > cameras && exit"],
            );}
          if(lines[6].trim() != '#'){
            process = await Process.start(
              plinkPath,
              ['-i', keyPath, 'root@192.168.12.1', '-hostkey', hostKey, 'cd /etc/payload && mount -o remount,rw / && sed -i \'s/^' + lines[6].split(' ').first + '.*/' + lines[6] + '/\' config && exit'],
            );}
          if(lines[7].trim() != '#'){
            process = await Process.start(
              plinkPath,
              ['-i', keyPath, 'root@192.168.12.1', '-hostkey', hostKey, 'cd /etc/payload && mount -o remount,rw / && sed -i \'s/^' + lines[7].split(' ').first + '.*/' + lines[7] + '/\' config && exit'],
            );}
          if(lines[8].trim() != '#'){
            process = await Process.start(
              plinkPath,
              ['-i', keyPath, 'root@192.168.12.1', '-hostkey', hostKey, 'cd /etc/payload && mount -o remount,rw / && sed -i \'s/^' + lines[8].split(' ').first + '.*/' + lines[8] + '/\' config && exit'],
            );}
          if(lines[9].trim() != '#'){
            process = await Process.start(
              plinkPath,
              ['-i', keyPath, 'root@192.168.12.1', '-hostkey', hostKey, 'cd /etc/payload && mount -o remount,rw / && sed -i \'s/^' + lines[9].split(' ').first + '.*/' + lines[9] + '/\' config && exit'],
            );}
          if(lines[10].trim() != '#'){
            process = await Process.start(
              plinkPath,
              ['-i', keyPath, 'root@192.168.12.1', '-hostkey', hostKey, 'cd /etc/payload && mount -o remount,rw / && sed -i \'s/^' + lines[10].split(' ').first + '.*/' + lines[10] + '/\' config && exit'],
            );}

          // try {
          //   if (lines.length >= 12 && lines[12].split(' ').first.trim() == "WINGTRA") {
          //     print("${lines[12]}\n${lines[13]} run lidar injection");
          //     wingtraLidarInject(lines[13]);
          //
          //   } else {
          //     print("Not matched: '${lines[12].split(' ').first.trim()}'");
          //   }
          // } catch (e) {
          //   print("Error: $e");
          // }


          // Вывод стандартного вывода процесса
          process.stdout.transform(SystemEncoding().decoder).listen((data) {
            print('stdout: $data');
          });
          // Вывод стандартной ошибки процесса
          process.stderr.transform(SystemEncoding().decoder).listen((data) {
            context.read<Data>().pushResponse(data);
          });
          // Ожидание завершения процесса
          var exitCode = await process.exitCode;
          print('Process exited with code $exitCode');
          if(exitCode == 1){
            pushUnitResponse(2,"Failed to upload final parameters:\ncheck all conditions before start",updateState:widget.recolState);
            updateState();
          }else if(exitCode == 0){
            pushUnitResponse(1,"Final parameters uploaded",updateState:widget.recolState);
            updateState();
            await Future.delayed(Duration(seconds: 1), () async {
              restartUnit();
            });

            process.kill();
          }
          else{
            process.kill();
          }
        } catch (e) {
      } finally {
          await deleteTempKeyFile();
        }
      } else {
        pushUnitResponse(2,"Procedure failed",updateState:widget.recolState);
        updateState();
      }
    }else{
    }
  }

  void uploadFile() {
    pushUnitResponse(0,"The procedure started",updateState:widget.recolState);
  //  updateState();
    if (_selectedFile != null) {
      pushUnitResponse(0,"The procedure started",updateState:widget.recolState);
   //   updateState();
      parseFinalTxt(_selectedFile);
      pushUnitResponse(0,"The procedure started",updateState:widget.recolState);
   //   updateState();
      setState(() {
        _files.clear(); // Очищаем список файлов
        _selectedFile = null; // Сбрасываем выбор файла
        _showFileList = false; // Скрываем список
        pushUnitResponse(0,"The procedure started",updateState:widget.recolState);
    //    updateState();
       });
      pushUnitResponse(0,"The procedure started",updateState:widget.recolState);
     // updateState();
    } else {
      pushUnitResponse(3,"Parameter file not selected",updateState:widget.recolState);
   // updateState();
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
              backgroundColor: const Color(0xFF015E17),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            child: Text(
              _showFileList ? 'Close tab' : 'Final Parameters',
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
                                pushUnitResponse(0,"The procedure started",updateState:updateState);
                               // updateState();
                                Navigator.of(context).pop(); // Закрываем диалог
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF259D3F),
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
              onPressed:() {uploadFile();}, // Вызов общего метода
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF259D3F),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              child: Text(
                'Upload Final parameters',
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
