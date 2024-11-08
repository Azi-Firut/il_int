import 'dart:io';
import 'dart:ui';
String version = 'v.1.6 (test)';
Map unitResponse = {'step':null,'text':null};
List<String> unitInfo=['','','',''];
Map output = {"IMU SN: ":"","Brand: ":"","Password: ":"","SSID default: ":"","SSID now: ":"","Receiver: ":"","Reciever SN: ":"","Firmware: ":"","Lidar: ":"","IMU Filter: ":""};




String keyPath = '';
String dragAndDropMessage = "Select two files and drop here";
Color textColorGray = Color(0xFFA9A9A9);
var titleText='';
var hostKey ='';
var connectedSsid = '';

   // "ssh-ed25519 255 SHA256:0z+smqD1LNdbBqOoIjFhJWhoxuJFiDtctVLxyssNFYc"; //1
// "ssh-ed25519 255 SHA256:yGWCAcgZRDEAEymGt1Kbe5GXRz3IXU+dQmdXp9mOtqc"; //2
const List keyGen1 =
    ["UHLVUUVFOktIVXBNlVciJ1LKZXTktGRmClsDZSE0yFOiIBlJY2ORzYYSP1zHaGJEyBLWR5pAc3CRwBMjDU2KCkDVuVY3IJ5OcHARpHb2I46IIGS5vCbmDUKIQ2V9tWbWBVuTdDTogVaWR1wUb3CJ0QZWNQtKb3XBlSbnLNzNaCP1rMZXBkKZUHBViIbGHljULUSxpMbmSVzXOiZAzWCkLFBVQULFFVMlUZqYWkMhODaESxYITmW9ZGVEPl0DYmG1sTemBRIHQXQlOPVFNlBVQUGFBJSWKJtUbHFpkKSEJF5OTlDRZHQUUFBZQkZJCSQkRt5IOUI1GYc0TlSBWUI8KORGCI5JUlUBtOM2CF3CZEUpnBNHCdkFYVTVXPa0Fx4XSjLl0OWHXBDDRFSJEYWVTdsOZ3Dp6PeECtpOY1CFsQeCRt0NaEKxRMa0Z9jEUUWM5SaFPI2LNkN50PcXOUwJTQKo3LZjSBtYNTABHVU2SdTYQTK0KVUHMJpBdmCF0ZZSR1MTaWN5lKczXogJMQBpBXQUHFBTSVXFDLOUQhwYUjYNCXajGZLMZEWpzMWkX0yYZEGtGDRTNV3MRmXg1FK2TcwCRTXdYZZ1YJOXcVQU0KWlMY4FaTJl5DUTM09QClNByCaXTZhVdGHUtBTUEFDQOiSBmMYTSQ1YMzWQ3KOGVUwQMTOA1EZjJI1DYWOFkNMmWRlOMzGM1EY2KYxPZjMZmIYmVM5UMDLEwEMDCJmA","ssh-ed25519 255 SHA256:0z+smqD1LNdbBqOoIjFhJWhoxuJFiDtctVLxyssNFYc"];
const List keyGen2 =
["UHGVUCVFFktTVXZNlCciK1LYZXBktGRmJlsNZST0yBOiBBlVY2DRzFYSP1zFaGDEyGLWS5pOc3ERwFMjDU2CCkVVuKY3ZJ5BcHHRpCb2L46VIGK5vTbmUUKWQ2S9tTbWYVuRdDLogMUkYVTHRVWBJPClOB1LYmJxpVYyS1MMaWZ5lFczVogCMwSpBVQUDFBBRTXJWValApIRTmZhMCWEH5vGWVVRJIdGYJtDbHHpkWSEEF5BTlRRZXQUAFBAQUCliCbWXx6ZZEVhBOeUI5UGWUGFBXQUUJCMQkY5aMUmE02VM3UJoSRkAh4QCjIJELTlRFOHR3SUyYTnOhzSSDWhCJRlIBlDK0PthIUXGZoGc3OdTINDLQyFbUFJ5EVWWMrYUFCcrQMWAVuJaGXk3XdGEhLKcVSJhOckSY0KQmWxxPNGCJBINGLt2GTVTIKZWHVEvPWWYRmHcFNNMSMTMA9HClOByNaXNZhPdGWUtQTGUluZZXXM6KIDIEKVQUBFBMQUTlFUTjAE0DRUT42LQlXlLLSWY1ISR0ShiUOEUFrKaULR3JLzBY4KSUKFqDTnUFIUb0ZNBJYXMIrSbWMJiRTVId5PClDByGaXLZhVdGGUtWTUSFDKOiHAxGZGHI1MMmMIyBZDQY2XYjQYyBZDZVmFODSA5YZDZc4MMjVMzXNzUAyPOGBQyTMjAA4AYmTM2IMTNlkO","ssh-ed25519 255 SHA256:yGWCAcgZRDEAEymGt1Kbe5GXRz3IXU+dQmdXp9mOtqc"];

const String ftpPath = "N:\\!Factory_calibrations_and_tests\\RESEPI\\";
//String templateAtcPath = 'assets/fill_atc/atc_template/ATC_TEMP_32.xlsx';

const String initialParamPath = 'N:/Manufacturing/05. RESEPI/parameter_configurations/il_int Calibration parameters/Initial';
const String finalParamPath = 'N:/Manufacturing/05. RESEPI/parameter_configurations/il_int Calibration parameters/Final';
/// Initial param vars
// List<FileSystemEntity> files = [];
// String? selectedFile; // Для хранения пути выбранного файла
// bool showFileList = false; // Управляет показом списка файлов
// var directoryPath = initialParamPath;
///

String templatePath(List<List<double>> lidarOffsetsList){
  String template;
  if(lidarOffsetsList.length>63){
    template='assets/fill_atc/atc_template/ATC_TEMP_64.xlsx';
    print('template ====== ${template}');
  }else{template='assets/fill_atc/atc_template/ATC_TEMP_32.xlsx';
  print('template ====== ${template}');
  }
  return template;

}

String addressToFolder = '';

const Map brandImagesAtc = {'WINGTRA':'\\assets\\fill_atc\\atc_template\\logo_img_atc\\WINGTRA.png',
  'FLIGHTS':'\\assets\\fill_atc\\atc_template\\logo_img_atc\\FLIGHTS.png',
  'MARSS':'\\assets\\fill_atc\\atc_template\\logo_img_atc\\MARSS.png',
  'ML':'\\assets\\fill_atc\\atc_template\\logo_img_atc\\ML.png',
  'PHOENIX':'\\assets\\fill_atc\\atc_template\\logo_img_atc\\PHOENIX.png',
  'Inertial Labs':'\\assets\\fill_atc\\atc_template\\logo_img_atc\\RESEPI.png',
  'STONEX':'\\assets\\fill_atc\\atc_template\\logo_img_atc\\STONEX.png',
  'TERSUS':'\\assets\\fill_atc\\atc_template\\logo_img_atc\\TERSUS.png',
  'TRIDAR':'\\assets\\fill_atc\\atc_template\\logo_img_atc\\TRIDAR.png',
};
/////////////////////////////////////////

Map<String, String> mapOffsetsForAtc(_address,listContentTxt,lidarOffsetsList,appDirectory,dateToday,ssidFromFolderName,ssidNumberFromFolderName){
  Map<String, String> setupForAtc;

  print('lidarOffsetsList.length ====== ${lidarOffsetsList.length}');
  print('lidarOffsetsList.length ====== ${lidarOffsetsList}');


  if(lidarOffsetsList.length > 50){
    Map<String, String> setup64={
      'adressXLSX': '$_address\\ATC_${listContentTxt[0]}-${listContentTxt[1]}.xlsx',
      'D4': listContentTxt.length > 2 ? 'ATC_${listContentTxt[0]}-${listContentTxt[1]}' : '',
      'D5': listContentTxt.length > 2 ? listContentTxt[0] : '',
      'D6': listContentTxt.length > 2 ? listContentTxt[2] : '',
      'D7': listContentTxt.length > 3 ? listContentTxt[1] : '',
      'D8': listContentTxt.length > 4 ? listContentTxt[7] : '',
      'D9': listContentTxt.length > 5 ? listContentTxt[6] : '',
      'D10': listContentTxt.length > 5 ? listContentTxt[8] : '',
      'D11': listContentTxt.length > 5 ? listContentTxt[3] : '',
      'D12': listContentTxt.length > 5 ? listContentTxt[5] : '',
      'D13': ssidFromFolderName,
      'D14': 'F8DC7A$ssidNumberFromFolderName',
// Offset val
      'J25': lidarOffsetsList.isNotEmpty ? '${lidarOffsetsList[0][0]}' : '',
      'J26': lidarOffsetsList.isNotEmpty ? '${lidarOffsetsList[0][1]}' : '',
      'J27': lidarOffsetsList.isNotEmpty ? '${lidarOffsetsList[0][2]}' : '',
      'J28': lidarOffsetsList.length > 1 ? '${lidarOffsetsList[1][0]}' : '',
      'J29': lidarOffsetsList.length > 1 ? '${lidarOffsetsList[1][1]}' : '',
      'J30': lidarOffsetsList.length > 1 ? '${lidarOffsetsList[1][2]}' : '',
// Lidar val
      'I33': lidarOffsetsList.length > 10 ? '${lidarOffsetsList[4][1]}' : '',
      'J33': lidarOffsetsList.length > 10 ? '${lidarOffsetsList[4][2]}' : '',
      'I34': lidarOffsetsList.length > 10 ? '${lidarOffsetsList[5][1]}' : '',
      'J34': lidarOffsetsList.length > 10 ? '${lidarOffsetsList[5][2]}' : '',
      'I35': lidarOffsetsList.length > 10 ? '${lidarOffsetsList[6][1]}' : '',
      'J35': lidarOffsetsList.length > 10 ? '${lidarOffsetsList[6][2]}' : '',
      'I36': lidarOffsetsList.length > 10 ? '${lidarOffsetsList[7][1]}' : '',
      'J36': lidarOffsetsList.length > 10 ? '${lidarOffsetsList[7][2]}' : '',
      'I37': lidarOffsetsList.length > 10 ? '${lidarOffsetsList[8][1]}' : '',
      'J37': lidarOffsetsList.length > 10 ? '${lidarOffsetsList[8][2]}' : '',
      'I38': lidarOffsetsList.length > 10 ? '${lidarOffsetsList[9][1]}' : '',
      'J38': lidarOffsetsList.length > 10 ? '${lidarOffsetsList[9][2]}' : '',
      'I39': lidarOffsetsList.length > 10 ? '${lidarOffsetsList[10][1]}' : '',
      'J39': lidarOffsetsList.length > 10 ? '${lidarOffsetsList[10][2]}' : '',
      'I40': lidarOffsetsList.length > 11 ? '${lidarOffsetsList[11][1]}' : '',
      'J40': lidarOffsetsList.length > 11 ? '${lidarOffsetsList[11][2]}' : '',
      'I41': lidarOffsetsList.length > 12 ? '${lidarOffsetsList[12][1]}' : '',
      'J41': lidarOffsetsList.length > 12 ? '${lidarOffsetsList[12][2]}' : '',
      'I42': lidarOffsetsList.length > 13 ? '${lidarOffsetsList[13][1]}' : '',
      'J42': lidarOffsetsList.length > 13 ? '${lidarOffsetsList[13][2]}' : '',
      'I43': lidarOffsetsList.length > 14 ? '${lidarOffsetsList[14][1]}' : '',
      'J43': lidarOffsetsList.length > 14 ? '${lidarOffsetsList[14][2]}' : '',
      'I44': lidarOffsetsList.length > 15 ? '${lidarOffsetsList[15][1]}' : '',
      'J44': lidarOffsetsList.length > 15 ? '${lidarOffsetsList[15][2]}' : '',
      'I45': lidarOffsetsList.length > 14 ? '${lidarOffsetsList[16][1]}' : '',
      'J45': lidarOffsetsList.length > 14 ? '${lidarOffsetsList[16][2]}' : '',
      'I46': lidarOffsetsList.length > 15 ? '${lidarOffsetsList[17][1]}' : '',
      'J46': lidarOffsetsList.length > 15 ? '${lidarOffsetsList[17][2]}' : '',
      'I47': lidarOffsetsList.length > 16 ? '${lidarOffsetsList[18][1]}' : '',
      'J47': lidarOffsetsList.length > 16 ? '${lidarOffsetsList[18][2]}' : '',
      'I48': lidarOffsetsList.length > 17 ? '${lidarOffsetsList[19][1]}' : '',
      'J48': lidarOffsetsList.length > 17 ? '${lidarOffsetsList[19][2]}' : '',
      'I49': lidarOffsetsList.length > 18 ? '${lidarOffsetsList[20][1]}' : '',
      'J49': lidarOffsetsList.length > 18 ? '${lidarOffsetsList[20][2]}' : '',
      'I50': lidarOffsetsList.length > 19 ? '${lidarOffsetsList[21][1]}' : '',
      'J50': lidarOffsetsList.length > 19 ? '${lidarOffsetsList[21][2]}' : '',
      'I51': lidarOffsetsList.length > 20 ? '${lidarOffsetsList[22][1]}' : '',
      'J51': lidarOffsetsList.length > 20 ? '${lidarOffsetsList[22][2]}' : '',
      'I52': lidarOffsetsList.length > 21 ? '${lidarOffsetsList[23][1]}' : '',
      'J52': lidarOffsetsList.length > 21 ? '${lidarOffsetsList[23][2]}' : '',
      'I53': lidarOffsetsList.length > 22 ? '${lidarOffsetsList[24][1]}' : '',
      'J53': lidarOffsetsList.length > 22 ? '${lidarOffsetsList[24][2]}' : '',
      'I54': lidarOffsetsList.length > 23 ? '${lidarOffsetsList[25][1]}' : '',
      'J54': lidarOffsetsList.length > 23 ? '${lidarOffsetsList[25][2]}' : '',
      'I55': lidarOffsetsList.length > 24 ? '${lidarOffsetsList[26][1]}' : '',
      'J55': lidarOffsetsList.length > 24 ? '${lidarOffsetsList[26][2]}' : '',
      'I56': lidarOffsetsList.length > 25 ? '${lidarOffsetsList[27][1]}' : '',
      'J56': lidarOffsetsList.length > 25 ? '${lidarOffsetsList[27][2]}' : '',
      'I57': lidarOffsetsList.length > 26 ? '${lidarOffsetsList[28][1]}' : '',
      'J57': lidarOffsetsList.length > 26 ? '${lidarOffsetsList[28][2]}' : '',
      'I58': lidarOffsetsList.length > 27 ? '${lidarOffsetsList[29][1]}' : '',
      'J58': lidarOffsetsList.length > 27 ? '${lidarOffsetsList[29][2]}' : '',
      'I59': lidarOffsetsList.length > 28 ? '${lidarOffsetsList[30][1]}' : '',
      'J59': lidarOffsetsList.length > 28 ? '${lidarOffsetsList[30][2]}' : '',
      'I60': lidarOffsetsList.length > 29 ? '${lidarOffsetsList[31][1]}' : '',
      'J60': lidarOffsetsList.length > 29 ? '${lidarOffsetsList[31][2]}' : '',
      'I61': lidarOffsetsList.length > 30 ? '${lidarOffsetsList[32][1]}' : '',
      'J61': lidarOffsetsList.length > 30 ? '${lidarOffsetsList[32][2]}' : '',
      'I62': lidarOffsetsList.length > 31 ? '${lidarOffsetsList[33][1]}' : '',
      'J62': lidarOffsetsList.length > 31 ? '${lidarOffsetsList[33][2]}' : '',
      'I63': lidarOffsetsList.length > 32 ? '${lidarOffsetsList[34][1]}' : '',
      'J63': lidarOffsetsList.length > 32 ? '${lidarOffsetsList[34][2]}' : '',
      'I64': lidarOffsetsList.length > 33 ? '${lidarOffsetsList[35][1]}' : '',
      'J64': lidarOffsetsList.length > 33 ? '${lidarOffsetsList[35][2]}' : '',
      ///
      'I65': lidarOffsetsList.length > 4 ? '${lidarOffsetsList[36][1]}' : '',
      'J65': lidarOffsetsList.length > 4 ? '${lidarOffsetsList[36][2]}' : '',
      'I66': lidarOffsetsList.length > 5 ? '${lidarOffsetsList[37][1]}' : '',
      'J66': lidarOffsetsList.length > 5 ? '${lidarOffsetsList[37][2]}' : '',
      'I67': lidarOffsetsList.length > 6 ? '${lidarOffsetsList[38][1]}' : '',
      'J67': lidarOffsetsList.length > 6 ? '${lidarOffsetsList[38][2]}' : '',
      'I68': lidarOffsetsList.length > 7 ? '${lidarOffsetsList[39][1]}' : '',
      'J68': lidarOffsetsList.length > 7 ? '${lidarOffsetsList[39][2]}' : '',
      'I69': lidarOffsetsList.length > 8 ? '${lidarOffsetsList[40][1]}' : '',
      'J69': lidarOffsetsList.length > 8 ? '${lidarOffsetsList[40][2]}' : '',
      'I70': lidarOffsetsList.length > 9 ? '${lidarOffsetsList[41][1]}' : '',
      'J70': lidarOffsetsList.length > 9 ? '${lidarOffsetsList[41][2]}' : '',
      'I71': lidarOffsetsList.length > 10 ? '${lidarOffsetsList[42][1]}' : '',
      'J71': lidarOffsetsList.length > 10 ? '${lidarOffsetsList[42][2]}' : '',
      'I72': lidarOffsetsList.length > 11 ? '${lidarOffsetsList[43][1]}' : '',
      'J72': lidarOffsetsList.length > 11 ? '${lidarOffsetsList[43][2]}' : '',
      'I73': lidarOffsetsList.length > 12 ? '${lidarOffsetsList[44][1]}' : '',
      'J73': lidarOffsetsList.length > 12 ? '${lidarOffsetsList[44][2]}' : '',
      'I74': lidarOffsetsList.length > 13 ? '${lidarOffsetsList[45][1]}' : '',
      'J74': lidarOffsetsList.length > 13 ? '${lidarOffsetsList[45][2]}' : '',
      'I75': lidarOffsetsList.length > 14 ? '${lidarOffsetsList[46][1]}' : '',
      'J75': lidarOffsetsList.length > 14 ? '${lidarOffsetsList[46][2]}' : '',
      'I76': lidarOffsetsList.length > 15 ? '${lidarOffsetsList[47][1]}' : '',
      'J76': lidarOffsetsList.length > 15 ? '${lidarOffsetsList[47][2]}' : '',
      'I77': lidarOffsetsList.length > 14 ? '${lidarOffsetsList[48][1]}' : '',
      'J77': lidarOffsetsList.length > 14 ? '${lidarOffsetsList[48][2]}' : '',
      'I78': lidarOffsetsList.length > 15 ? '${lidarOffsetsList[49][1]}' : '',
      'J78': lidarOffsetsList.length > 15 ? '${lidarOffsetsList[49][2]}' : '',
      'I79': lidarOffsetsList.length > 16 ? '${lidarOffsetsList[50][1]}' : '',
      'J79': lidarOffsetsList.length > 16 ? '${lidarOffsetsList[50][2]}' : '',
      'I80': lidarOffsetsList.length > 17 ? '${lidarOffsetsList[51][1]}' : '',
      'J80': lidarOffsetsList.length > 17 ? '${lidarOffsetsList[51][2]}' : '',
      'I81': lidarOffsetsList.length > 18 ? '${lidarOffsetsList[52][1]}' : '',
      'J81': lidarOffsetsList.length > 18 ? '${lidarOffsetsList[52][2]}' : '',
      'I82': lidarOffsetsList.length > 19 ? '${lidarOffsetsList[53][1]}' : '',
      'J82': lidarOffsetsList.length > 19 ? '${lidarOffsetsList[53][2]}' : '',
      'I83': lidarOffsetsList.length > 20 ? '${lidarOffsetsList[54][1]}' : '',
      'J83': lidarOffsetsList.length > 20 ? '${lidarOffsetsList[54][2]}' : '',
      'I84': lidarOffsetsList.length > 21 ? '${lidarOffsetsList[55][1]}' : '',
      'J84': lidarOffsetsList.length > 21 ? '${lidarOffsetsList[55][2]}' : '',
      'I85': lidarOffsetsList.length > 22 ? '${lidarOffsetsList[56][1]}' : '',
      'J85': lidarOffsetsList.length > 22 ? '${lidarOffsetsList[56][2]}' : '',
      'I86': lidarOffsetsList.length > 23 ? '${lidarOffsetsList[57][1]}' : '',
      'J86': lidarOffsetsList.length > 23 ? '${lidarOffsetsList[57][2]}' : '',
      'I87': lidarOffsetsList.length > 24 ? '${lidarOffsetsList[58][1]}' : '',
      'J87': lidarOffsetsList.length > 24 ? '${lidarOffsetsList[58][2]}' : '',
      'I88': lidarOffsetsList.length > 25 ? '${lidarOffsetsList[59][1]}' : '',
      'J88': lidarOffsetsList.length > 25 ? '${lidarOffsetsList[59][2]}' : '',
      'I89': lidarOffsetsList.length > 26 ? '${lidarOffsetsList[60][1]}' : '',
      'J89': lidarOffsetsList.length > 26 ? '${lidarOffsetsList[60][2]}' : '',
      'I90': lidarOffsetsList.length > 27 ? '${lidarOffsetsList[61][1]}' : '',
      'J90': lidarOffsetsList.length > 27 ? '${lidarOffsetsList[61][2]}' : '',
      'I91': lidarOffsetsList.length > 28 ? '${lidarOffsetsList[62][1]}' : '',
      'J91': lidarOffsetsList.length > 28 ? '${lidarOffsetsList[62][2]}' : '',
      'I92': lidarOffsetsList.length > 29 ? '${lidarOffsetsList[63][1]}' : '',
      'J92': lidarOffsetsList.length > 29 ? '${lidarOffsetsList[63][2]}' : '',
      'I93': lidarOffsetsList.length > 30 ? '${lidarOffsetsList[64][1]}' : '',
      'J93': lidarOffsetsList.length > 30 ? '${lidarOffsetsList[64][2]}' : '',
      'I94': lidarOffsetsList.length > 31 ? '${lidarOffsetsList[65][1]}' : '',
      'J94': lidarOffsetsList.length > 31 ? '${lidarOffsetsList[65][2]}' : '',
      'I95': lidarOffsetsList.length > 32 ? '${lidarOffsetsList[66][1]}' : '',
      'J95': lidarOffsetsList.length > 32 ? '${lidarOffsetsList[66][2]}' : '',
      'I96': lidarOffsetsList.length > 33 ? '${lidarOffsetsList[67][1]}' : '',
      'J96': lidarOffsetsList.length > 33 ? '${lidarOffsetsList[67][2]}' : '',
// Camera offsets
      'J100': lidarOffsetsList.length > 68 ? '${lidarOffsetsList[68][0]}' : '',
      'J101': lidarOffsetsList.length > 68 ? '${lidarOffsetsList[68][1]}' : '',
      'J102': lidarOffsetsList.length > 68 ? '${lidarOffsetsList[68][2]}' : '',
      'J103': lidarOffsetsList.length > 68 ? '${lidarOffsetsList[69][0]}' : '',
      'J104': lidarOffsetsList.length > 68 ? '${lidarOffsetsList[69][1]}' : '',
      'J105': lidarOffsetsList.length > 68 ? '${lidarOffsetsList[69][2]}' : '',
      'J106': lidarOffsetsList.length > 68 ? '${lidarOffsetsList[71][0]}' : '',
      'J107': lidarOffsetsList.length > 68 ? '${lidarOffsetsList[71][5]}' : '',
      'I107': lidarOffsetsList.length > 68 ? '${lidarOffsetsList[71][4]}' : '',
      'J108': lidarOffsetsList.length > 68 ? '${lidarOffsetsList[71][3]}' : '',
      'I108': lidarOffsetsList.length > 68 ? '${lidarOffsetsList[71][2]}' : '',
// Brand logo
      'E6': '$appDirectory${brandImagesAtc['${listContentTxt[0]}']}',
      'E14': listContentTxt.length > 2 ? listContentTxt[1] : '',
// Bottom signature
      'I120': 'Inertial Labs Calibration Team',
      'I121':
      '${dateToday.month.toString()}/${dateToday.day.toString()}/${dateToday.year.toString()}',
    };
    setupForAtc=setup64;
  }else{

    Map<String, String> setup32={
      'adressXLSX': '$_address\\ATC_${listContentTxt[0]}-${listContentTxt[1]}.xlsx',
      'D4': listContentTxt.length > 2 ? 'ATC_${listContentTxt[0]}-${listContentTxt[1]}' : '',
      'D5': listContentTxt.length > 2 ? listContentTxt[0] : '',
      'D6': listContentTxt.length > 2 ? listContentTxt[2] : '',
      'D7': listContentTxt.length > 3 ? listContentTxt[1] : '',
      'D8': listContentTxt.length > 4 ? listContentTxt[7] : '',
      'D9': listContentTxt.length > 5 ? listContentTxt[6] : '',
      'D10': listContentTxt.length > 5 ? listContentTxt[8] : '',
      'D11': listContentTxt.length > 5 ? listContentTxt[3] : '',
      'D12': listContentTxt.length > 5 ? listContentTxt[5] : '',
      'D13': ssidFromFolderName,
      'D14': 'F8DC7A$ssidNumberFromFolderName',
// Offset val
      'J25': lidarOffsetsList.isNotEmpty ? '${lidarOffsetsList[0][0]}' : '',
      'J26': lidarOffsetsList.isNotEmpty ? '${lidarOffsetsList[0][1]}' : '',
      'J27': lidarOffsetsList.isNotEmpty ? '${lidarOffsetsList[0][2]}' : '',
      'J28': lidarOffsetsList.isNotEmpty ? '${lidarOffsetsList[1][0]}' : '',
      'J29': lidarOffsetsList.isNotEmpty ? '${lidarOffsetsList[1][1]}' : '',
      'J30': lidarOffsetsList.isNotEmpty ? '${lidarOffsetsList[1][2]}' : '',
// Lidar val
      'I33': lidarOffsetsList.isNotEmpty ? '${lidarOffsetsList[4][1]}' : '',
      'J33': lidarOffsetsList.isNotEmpty ? '${lidarOffsetsList[4][2]}' : '',
      'I34': lidarOffsetsList.isNotEmpty ? '${lidarOffsetsList[5][1]}' : '',
      'J34': lidarOffsetsList.isNotEmpty ? '${lidarOffsetsList[5][2]}' : '',
      'I35': lidarOffsetsList.isNotEmpty ? '${lidarOffsetsList[6][1]}' : '',
      'J35': lidarOffsetsList.isNotEmpty ? '${lidarOffsetsList[6][2]}' : '',
      'I36': lidarOffsetsList.isNotEmpty ? '${lidarOffsetsList[7][1]}' : '',
      'J36': lidarOffsetsList.isNotEmpty ? '${lidarOffsetsList[7][2]}' : '',
      'I37': lidarOffsetsList.length > 10 ? '${lidarOffsetsList[8][1]}' : '',
      'J37': lidarOffsetsList.length > 10 ? '${lidarOffsetsList[8][2]}' : '',
      'I38': lidarOffsetsList.length > 10 ? '${lidarOffsetsList[9][1]}' : '',
      'J38': lidarOffsetsList.length > 10 ? '${lidarOffsetsList[9][2]}' : '',
      'I39': lidarOffsetsList.length > 10 ? '${lidarOffsetsList[10][1]}' : '',
      'J39': lidarOffsetsList.length > 10 ? '${lidarOffsetsList[10][2]}' : '',
      'I40': lidarOffsetsList.length > 11 ? '${lidarOffsetsList[11][1]}' : '',
      'J40': lidarOffsetsList.length > 11 ? '${lidarOffsetsList[11][2]}' : '',
      'I41': lidarOffsetsList.length > 12 ? '${lidarOffsetsList[12][1]}' : '',
      'J41': lidarOffsetsList.length > 12 ? '${lidarOffsetsList[12][2]}' : '',
      'I42': lidarOffsetsList.length > 13 ? '${lidarOffsetsList[13][1]}' : '',
      'J42': lidarOffsetsList.length > 13 ? '${lidarOffsetsList[13][2]}' : '',
      'I43': lidarOffsetsList.length > 14 ? '${lidarOffsetsList[14][1]}' : '',
      'J43': lidarOffsetsList.length > 14 ? '${lidarOffsetsList[14][2]}' : '',
      'I44': lidarOffsetsList.length > 15 ? '${lidarOffsetsList[15][1]}' : '',
      'J44': lidarOffsetsList.length > 15 ? '${lidarOffsetsList[15][2]}' : '',
      'I45': lidarOffsetsList.length > 14 ? '${lidarOffsetsList[16][1]}' : '',
      'J45': lidarOffsetsList.length > 14 ? '${lidarOffsetsList[16][2]}' : '',
      'I46': lidarOffsetsList.length > 15 ? '${lidarOffsetsList[17][1]}' : '',
      'J46': lidarOffsetsList.length > 15 ? '${lidarOffsetsList[17][2]}' : '',
      'I47': lidarOffsetsList.length > 16 ? '${lidarOffsetsList[18][1]}' : '',
      'J47': lidarOffsetsList.length > 16 ? '${lidarOffsetsList[18][2]}' : '',
      'I48': lidarOffsetsList.length > 17 ? '${lidarOffsetsList[19][1]}' : '',
      'J48': lidarOffsetsList.length > 17 ? '${lidarOffsetsList[19][2]}' : '',
      'I49': lidarOffsetsList.length > 18 ? '${lidarOffsetsList[20][1]}' : '',
      'J49': lidarOffsetsList.length > 18 ? '${lidarOffsetsList[20][2]}' : '',
      'I50': lidarOffsetsList.length > 19 ? '${lidarOffsetsList[21][1]}' : '',
      'J50': lidarOffsetsList.length > 19 ? '${lidarOffsetsList[21][2]}' : '',
      'I51': lidarOffsetsList.length > 20 ? '${lidarOffsetsList[22][1]}' : '',
      'J51': lidarOffsetsList.length > 20 ? '${lidarOffsetsList[22][2]}' : '',
      'I52': lidarOffsetsList.length > 21 ? '${lidarOffsetsList[23][1]}' : '',
      'J52': lidarOffsetsList.length > 21 ? '${lidarOffsetsList[23][2]}' : '',
      'I53': lidarOffsetsList.length > 22 ? '${lidarOffsetsList[24][1]}' : '',
      'J53': lidarOffsetsList.length > 22 ? '${lidarOffsetsList[24][2]}' : '',
      'I54': lidarOffsetsList.length > 23 ? '${lidarOffsetsList[25][1]}' : '',
      'J54': lidarOffsetsList.length > 23 ? '${lidarOffsetsList[25][2]}' : '',
      'I55': lidarOffsetsList.length > 24 ? '${lidarOffsetsList[26][1]}' : '',
      'J55': lidarOffsetsList.length > 24 ? '${lidarOffsetsList[26][2]}' : '',
      'I56': lidarOffsetsList.length > 25 ? '${lidarOffsetsList[27][1]}' : '',
      'J56': lidarOffsetsList.length > 25 ? '${lidarOffsetsList[27][2]}' : '',
      'I57': lidarOffsetsList.length > 26 ? '${lidarOffsetsList[28][1]}' : '',
      'J57': lidarOffsetsList.length > 26 ? '${lidarOffsetsList[28][2]}' : '',
      'I58': lidarOffsetsList.length > 27 ? '${lidarOffsetsList[29][1]}' : '',
      'J58': lidarOffsetsList.length > 27 ? '${lidarOffsetsList[29][2]}' : '',
      'I59': lidarOffsetsList.length > 28 ? '${lidarOffsetsList[30][1]}' : '',
      'J59': lidarOffsetsList.length > 28 ? '${lidarOffsetsList[30][2]}' : '',
      'I60': lidarOffsetsList.length > 29 ? '${lidarOffsetsList[31][1]}' : '',
      'J60': lidarOffsetsList.length > 29 ? '${lidarOffsetsList[31][2]}' : '',
      'I61': lidarOffsetsList.length > 30 ? '${lidarOffsetsList[32][1]}' : '',
      'J61': lidarOffsetsList.length > 30 ? '${lidarOffsetsList[32][2]}' : '',
      'I62': lidarOffsetsList.length > 31 ? '${lidarOffsetsList[33][1]}' : '',
      'J62': lidarOffsetsList.length > 31 ? '${lidarOffsetsList[33][2]}' : '',
      'I63': lidarOffsetsList.length > 32 ? '${lidarOffsetsList[34][1]}' : '',
      'J63': lidarOffsetsList.length > 32 ? '${lidarOffsetsList[34][2]}' : '',
      'I64': lidarOffsetsList.length > 33 ? '${lidarOffsetsList[35][1]}' : '',
      'J64': lidarOffsetsList.length > 33 ? '${lidarOffsetsList[35][2]}' : '',
// Camera offsets
      'J68': lidarOffsetsList.length > 35 ? '${lidarOffsetsList[36][0]}' : '',
      'J69': lidarOffsetsList.length > 35 ? '${lidarOffsetsList[36][1]}' : '',
      'J70': lidarOffsetsList.length > 35 ? '${lidarOffsetsList[36][2]}' : '',
      'J71': lidarOffsetsList.length > 36 ? '${lidarOffsetsList[37][0]}' : '',
      'J72': lidarOffsetsList.length > 36 ? '${lidarOffsetsList[37][1]}' : '',
      'J73': lidarOffsetsList.length > 36 ? '${lidarOffsetsList[37][2]}' : '',
      'J74': lidarOffsetsList.length > 37 ? '${lidarOffsetsList[39][0]}' : '',
      'J75': lidarOffsetsList.length > 37 ? '${lidarOffsetsList[39][5]}' : '',
      'I75': lidarOffsetsList.length > 37 ? '${lidarOffsetsList[39][4]}' : '',
      'J76': lidarOffsetsList.length > 37 ? '${lidarOffsetsList[39][3]}' : '',
      'I76': lidarOffsetsList.length > 37 ? '${lidarOffsetsList[39][2]}' : '',
// Brand logo
      'E6': '$appDirectory${brandImagesAtc['${listContentTxt[0]}']}',
      'E14': listContentTxt.length > 2 ? listContentTxt[1] : '',
// Bottom signature
      'I88': 'Inertial Labs Calibration Team',
      'I89':
      '${dateToday.month.toString()}/${dateToday.day.toString()}/${dateToday.year.toString()}',
    };

    setupForAtc=setup32;
  }



return setupForAtc;
}