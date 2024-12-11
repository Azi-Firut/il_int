
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart' hide Column;
import 'package:path_provider/path_provider.dart';

import '../constant.dart';
import 'get_imu_val.dart';


  Future<void> generateExcel32(saveDirectory,_address,listContentTxt,lidarOffsetsList,appDirectory,dateToday,ssidFromFolderName,ssidNumberFromFolderName,fetchDataBase) async {
    //Create a Excel document.
  //  List<String> fetchDataBase = await getIMUcalVAl(listContentTxt[5]);
    //Creating a workbook.
    final Workbook workbook = Workbook();
    //Accessing via index
    final Worksheet sheet = workbook.worksheets[0];
    sheet.pageSetup.fitToPagesWide = 1;
    sheet.pageSetup.topMargin=0;
    sheet.pageSetup.leftMargin=0;
    sheet.pageSetup.rightMargin=0;
    sheet.pageSetup.bottomMargin=0;
    sheet.showGridlines = false;

sheet.name="Calibration Certificate";
   // sheet.getRangeByName('A1:K100').autoFit();
    // Enable calculation for worksheet.
    //sheet.enableSheetCalculations();
    var bcol="#b6b6b8"; //#575859
    sheet.getRangeByName('A1:K100').cellStyle.fontName = 'Arial';
    //sheet.getRangeByName('A1:K100').cellStyle.borders.all.color = bcol;
   // sheet.getRangeByName('A1:K100').cellStyle.borders.top.color = bcol;
   // sheet.getRangeByName('A1:K100').cellStyle.borders.left.color = bcol;
   // sheet.getRangeByName('A1:K100').cellStyle.borders.right.color = bcol;
   // sheet.getRangeByName('A1:K100').cellStyle.borders.bottom.color = bcol;

    //Set data in the worksheet.
    sheet.getRangeByName('A1').columnWidth = 4;
    sheet.getRangeByName('B1').columnWidth = 4;
    sheet.getRangeByName('C1').columnWidth = 27;
    sheet.getRangeByName('D1').columnWidth = 52;
    sheet.getRangeByName('E1').columnWidth = 10;
    sheet.getRangeByName('F1').columnWidth = 21;
    sheet.getRangeByName('G1').columnWidth = 14;
    sheet.getRangeByName('H1').columnWidth = 16;
    sheet.getRangeByName('I1').columnWidth = 17;
    sheet.getRangeByName('J1').columnWidth = 18;
    sheet.getRangeByName('K1').columnWidth = 4;

    sheet.getRangeByName('A1:K1').cellStyle.backColor = '#FFFFFF';
    sheet.getRangeByName('A1:K1').merge();
   // sheet.getRangeByName('B4:D6').merge();
    // MY
    sheet.getRangeByName('A2:K2').merge();
    sheet.getRangeByName('A2').setText('Certificate of Calibration and Boresighting');
    sheet.getRangeByName('A2').cellStyle.fontSize = 16;
    sheet.getRangeByName('A2').cellStyle.hAlign=HAlignType.center;
    sheet.getRangeByName('A2').cellStyle.bold=true;

    sheet.getRangeByName('A3:K3').cellStyle.backColor = '#FFFFFF';
    sheet.getRangeByName('A3:K3').merge();
    sheet.getRangeByName('B4:J14').merge();
     sheet.getRangeByName('D5:D13').cellStyle.borders.all.lineStyle = LineStyle.none;

    sheet.getRangeByName('B4:D14').merge();
  //  sheet.getRangeByName('B4:D14').cellStyle.borders.all.lineStyle = LineStyle.thin;
    sheet.getRangeByName('B4:C4').merge();
    sheet.getRangeByName('B4').setText('  Document Number');
    sheet.getRangeByName('D4').setText(listContentTxt[0].isNotEmpty ? 'ATC_${listContentTxt[0]}-${listContentTxt[1]}' : '');
    sheet.getRangeByName('B5:C5').merge();
    sheet.getRangeByName('B5').setText('  Supplier');
    sheet.getRangeByName('D5').setText(listContentTxt[0].isNotEmpty ? listContentTxt[0] : '');
    sheet.getRangeByName('B6:C6').merge();
    sheet.getRangeByName('B6').setText('  Model');
    sheet.getRangeByName('D6').setText(listContentTxt[2].isNotEmpty ? listContentTxt[2] : '');
    sheet.getRangeByName('B7:C7').merge();
    sheet.getRangeByName('B7').setText('  Unit Serial Number');
    sheet.getRangeByName('D7').setText(listContentTxt[1].isNotEmpty ? listContentTxt[1] : '');
    sheet.getRangeByName('B8:C8').merge();
    sheet.getRangeByName('B8').setText('  GNSS');
    sheet.getRangeByName('D8').setText(listContentTxt[7].isNotEmpty ? listContentTxt[7] : '');
    sheet.getRangeByName('B9:C9').merge();
    sheet.getRangeByName('B9').setText('  LiDAR');
    sheet.getRangeByName('D9').setText(listContentTxt[6].isNotEmpty ? listContentTxt[6] : '');
    sheet.getRangeByName('B10:C10').merge();
    sheet.getRangeByName('B10').setText('  Camera');
    sheet.getRangeByName('D10').setText(listContentTxt[8].isNotEmpty ? listContentTxt[8] : '');
    sheet.getRangeByName('B11:C11').merge();
    sheet.getRangeByName('B11').setText('  Build Number');
    sheet.getRangeByName('D11').setText(listContentTxt[3].isNotEmpty ? listContentTxt[3] : '');
    sheet.getRangeByName('B12:C12').merge();
    sheet.getRangeByName('B12').setText('  IMU Number');
    sheet.getRangeByName('D12').setText(listContentTxt[5].isNotEmpty ? listContentTxt[5] : '');
    sheet.getRangeByName('B13:C13').merge();
    sheet.getRangeByName('B13').setText('  Wifi SSID');
    sheet.getRangeByName('D13').setText(ssidFromFolderName);
    sheet.getRangeByName('B14:C14').merge();
    sheet.getRangeByName('B14').setText('  Unit MAC Address');
    sheet.getRangeByName('D14').setText('F8DC7A$ssidNumberFromFolderName');

    sheet.getRangeByName('E4:J13').merge();
    // Загружаем изображение из assets
   // print("Image data from toXL32 \n $appDirectory\n${brandImagesAtc['${listContentTxt[0]}']}");
   final ByteData imageData = await rootBundle.load('assets/${listContentTxt[0]}.png');
    final Uint8List imageBytes = imageData.buffer.asUint8List();

    // Добавляем изображение в ячейку E4
    final Picture picture = sheet.pictures.addStream(4, 5, imageBytes); // 4 = строка E4, 5 = столбец E4
    picture.lastRow = 13; // Определяем конечный диапазон строк (по необходимости)
    picture.lastColumn = 11; // Определяем конечный диапазон столбцов (по необходимости)

    sheet.getRangeByName('E4').cellStyle.hAlign=HAlignType.center;
    sheet.getRangeByName('E14:J14').merge();
    sheet.getRangeByName('E14').cellStyle.hAlign=HAlignType.center;
    sheet.getRangeByName('E14').cellStyle.bold=true;
    sheet.getRangeByName('E14').setText(listContentTxt[1].isNotEmpty ? listContentTxt[1] : '');

    // Цвета ячеек
    sheet.getRangeByName('E20:E22').cellStyle.backColor = '#f9fafb';
    sheet.getRangeByName('E24:E26').cellStyle.backColor = '#f9fafb';
    sheet.getRangeByName('E28:E32').cellStyle.backColor = '#f9fafb';
    sheet.getRangeByName('E35:E40').cellStyle.backColor = '#f9fafb';
    sheet.getRangeByName('E43:E75').cellStyle.backColor = '#f9fafb';
    sheet.getRangeByName('E78:E86').cellStyle.backColor = '#f9fafb';
    sheet.getRangeByName('E89:E96').cellStyle.backColor = '#f9fafb';
    sheet.getRangeByName('F20:F22').cellStyle.backColor = '#f2f5f7';
    sheet.getRangeByName('F24:F26').cellStyle.backColor = '#f2f5f7';
    sheet.getRangeByName('F28:F32').cellStyle.backColor = '#f2f5f7';
    sheet.getRangeByName('F35:F40').cellStyle.backColor = '#f2f5f7';
    sheet.getRangeByName('F43:F75').cellStyle.backColor = '#f2f5f7';
    sheet.getRangeByName('F78:F86').cellStyle.backColor = '#f2f5f7';
    sheet.getRangeByName('F89:F96').cellStyle.backColor = '#f2f5f7';
    sheet.getRangeByName('G20:G22').cellStyle.backColor = '#ecf0f4';
    sheet.getRangeByName('G24:G26').cellStyle.backColor = '#ecf0f4';
    sheet.getRangeByName('G28:G32').cellStyle.backColor = '#ecf0f4';
    sheet.getRangeByName('G35:G40').cellStyle.backColor = '#ecf0f4';
    sheet.getRangeByName('G43:G75').cellStyle.backColor = '#ecf0f4';
    sheet.getRangeByName('G78:G86').cellStyle.backColor = '#ecf0f4';
    sheet.getRangeByName('G89:G96').cellStyle.backColor = '#ecf0f4';
    sheet.getRangeByName('H20:H22').cellStyle.backColor = '#d7f7ee';
    sheet.getRangeByName('H24:H26').cellStyle.backColor = '#d7f7ee';
    sheet.getRangeByName('H28:H32').cellStyle.backColor = '#d7f7ee';
    sheet.getRangeByName('H35:H40').cellStyle.backColor = '#d7f7ee';
    sheet.getRangeByName('H43:H75').cellStyle.backColor = '#d7f7ee';
    sheet.getRangeByName('H78:H86').cellStyle.backColor = '#d7f7ee';
    sheet.getRangeByName('H89:H96').cellStyle.backColor = '#d7f7ee';

    // Определяем диапазон из четырёх ячеек ( B4:J14 )
    final Range rangeBorderBottom = sheet.getRangeByName('B14:J14');
    final Range rangeBorderTop = sheet.getRangeByName('B4:J4');
    final Range rangeBorderLeft = sheet.getRangeByName('B4:B14');
    final Range rangeBorderRight = sheet.getRangeByName('J4:J14');
    // Устанавливаем внешний стиль границы
    rangeBorderTop.cellStyle.borders.top.lineStyle = LineStyle.thin;
    rangeBorderBottom.cellStyle.borders.bottom.lineStyle = LineStyle.thin;
    rangeBorderLeft.cellStyle.borders.left.lineStyle = LineStyle.thin;
    rangeBorderRight.cellStyle.borders.right.lineStyle = LineStyle.thin;
    //rangeBorder.cellStyle.borders.all.color = '#000000'; // Цвет рамки (чёрный)

    // Определяем диапазон из четырёх ячеек ( B16:J86 )
    final Range rangeBorderBottom2 = sheet.getRangeByName('B96:J96');
    final Range rangeBorderTop2 = sheet.getRangeByName('B16:J16');
    final Range rangeBorderLeft2 = sheet.getRangeByName('B16:B96');
    final Range rangeBorderRight2 = sheet.getRangeByName('J16:J96');
    // Устанавливаем внешний стиль границы
    rangeBorderTop2.cellStyle.borders.top.lineStyle = LineStyle.thin;
    rangeBorderBottom2.cellStyle.borders.bottom.lineStyle = LineStyle.thin;
    rangeBorderLeft2.cellStyle.borders.left.lineStyle = LineStyle.thin;
    rangeBorderRight2.cellStyle.borders.right.lineStyle = LineStyle.thin;
    //rangeBorder.cellStyle.borders.all.color = '#000000'; // Цвет рамки (чёрный)

    sheet.getRangeByName('B16:J16').cellStyle.hAlign=HAlignType.center;
    sheet.getRangeByName('B16:J16').cellStyle.borders.all.lineStyle = LineStyle.thin;
    sheet.getRangeByName('B16:J16').cellStyle.bold=true;
    sheet.getRangeByName('B16:D16').merge();
    sheet.getRangeByName('B16').setText('Measured/checked parameter');
    sheet.getRangeByName('E16').setText('Unit');
    sheet.getRangeByName('F16').setText('Criteria');
    sheet.getRangeByName('G16').setText('Test Results');
    sheet.getRangeByName('H16').setText('Compliance');
    sheet.getRangeByName('I16:J16').merge();
    sheet.getRangeByName('I16').setText('Calibrated Offsets');

    sheet.getRangeByName('B17:D17').merge();
    sheet.getRangeByName('B18:D18').merge();
    sheet.getRangeByName('B17:J17').cellStyle.bold=true;
    sheet.getRangeByName('B17:J18').cellStyle.hAlign=HAlignType.center;
    sheet.getRangeByName('B17').setText('Inertial Measurement Unit');

    sheet.getRangeByName('B18').setText('IMU Type: ${fetchDataBase[3].text.trim()}');
    //sheet.getRangeByName('C19').cellStyle.backColor = '#333F4F';
    // Все ячеки центр текст
    sheet.getRangeByName('E20:J96').cellStyle.hAlign=HAlignType.center;
//
    sheet.getRangeByName('C19:D19').merge();
    sheet.getRangeByName('C19').cellStyle.bold=true;
    sheet.getRangeByName('C19').setText('Accelerometer');
    sheet.getRangeByName('C20:D20').merge();
    sheet.getRangeByName('C20').setText('Bias in-run stability (Allan Variance)');
    sheet.getRangeByName('I20').setText(fetchDataBase.length >= 20 ? fetchDataBase[34].text.trim() : '');
    sheet.getRangeByName('E20').setText('mg');
    sheet.getRangeByName('F20').setText('0.02');
    sheet.getRangeByName('C21:D21').merge();
    sheet.getRangeByName('C21').setText('Noise. Velocity Random Walk (VRW)');
    sheet.getRangeByName('I21').setText(fetchDataBase.length >= 20 ? fetchDataBase[35].text.trim() : '');
    sheet.getRangeByName('E21').setText('m/sec/√hr');
    sheet.getRangeByName('F21').setText('0.045');
    sheet.getRangeByName('C22:D22').merge();
    sheet.getRangeByName('C22').setText('Scale Factor (STD, over temperature range)');
    sheet.getRangeByName('I22').setText(fetchDataBase.length >= 20 ? fetchDataBase[26].text.trim() : '');
    sheet.getRangeByName('E22').setText('ppm');
    sheet.getRangeByName('F22').setText('100');
    sheet.getRangeByName('C23').cellStyle.bold=true;
    sheet.getRangeByName('C23').setText('Gyroscope');
    sheet.getRangeByName('C24:D24').merge();
    sheet.getRangeByName('C24').setText('Bias in-run stability (Allan Variance)');
    sheet.getRangeByName('I24').setText(fetchDataBase.length >= 20 ? fetchDataBase[30].text.trim() : '');
    sheet.getRangeByName('E24').setText('deg/hr'); // fetchDataBase[2]
    sheet.getRangeByName('F24').setText('2');
    sheet.getRangeByName('C25:D25').merge();
    sheet.getRangeByName('C25').setText('Noise. Angle Random Walk (ARW)');
    sheet.getRangeByName('E25').setText('deg/√hr');
    sheet.getRangeByName('I25').setText(fetchDataBase.length >= 20 ? fetchDataBase[31].text.trim() : '');
    sheet.getRangeByName('F25').setText('0.23');
    sheet.getRangeByName('C26:D26').merge();
    sheet.getRangeByName('C26').setText('Scale Factor (STD, over temperature range)');
    sheet.getRangeByName('I26').setText(fetchDataBase.length >= 20 ? fetchDataBase[22].text.trim() : '');
    // (extractedDataVal.length >= 22 ? 'extractedDataVal[29]' : '')
    sheet.getRangeByName('E26').setText('ppm');
    sheet.getRangeByName('F26').setText('600');
    sheet.getRangeByName('G24:G26').setText('Pass');
    sheet.getRangeByName('G20:G22').setText('Pass');
    sheet.getRangeByName('H24:H26').setText('Comply');
    sheet.getRangeByName('H20:H22').setText('Comply');


    sheet.getRangeByName('B27:D27').merge();
    sheet.getRangeByName('B27:D27').cellStyle.bold=true;
    sheet.getRangeByName('B27:D27').cellStyle.hAlign=HAlignType.center;
    sheet.getRangeByName('B27').setText('PPK Trajectory Generation');
    sheet.getRangeByName('C28:D28').merge();
    sheet.getRangeByName('C28').setText('GNSS position quality');
    sheet.getRangeByName('F28:F32').setText('Pass/Fail');
    sheet.getRangeByName('G28:G32').setText('Pass');
    sheet.getRangeByName('H28:H32').setText('Comply');
    sheet.getRangeByName('C29:D29').merge();
    sheet.getRangeByName('C29').setText('Antenna lever arm misclosure');
    sheet.getRangeByName('E28:E29').setText('m');
    sheet.getRangeByName('E30:E32').setText('arcmin');
    sheet.getRangeByName('C30:D30').merge();
    sheet.getRangeByName('C30').setText('Forward/Reverse Attitude Separation Heading');
    sheet.getRangeByName('C31:D31').merge();
    sheet.getRangeByName('C31').setText('Forward/Reverse Attitude Separation Pitch');
    sheet.getRangeByName('C32:D32').merge();
    sheet.getRangeByName('C32').setText('Forward/Reverse Attitude Separation Roll');

    sheet.getRangeByName('B33:D33').merge();
    sheet.getRangeByName('B33:D33').cellStyle.bold=true;
    sheet.getRangeByName('B33:D33').cellStyle.hAlign=HAlignType.center;
    sheet.getRangeByName('B33').setText('Lidar Boresighting');
    sheet.getRangeByName('C34:D34').merge();
    sheet.getRangeByName('C34').setText('Flight test #1');
    sheet.getRangeByName('C35:D35').merge();
    sheet.getRangeByName('C35').setText('IMU-Lidar Linear Offset X');
    sheet.getRangeByName('I35').setText(lidarOffsetsList[0].isNotEmpty ? '${lidarOffsetsList[0][0]}' : '');
    sheet.getRangeByName('I35:J35').merge();
    sheet.getRangeByName('E35:E37').setText('m');
    sheet.getRangeByName('F35:F40').setText('Complete/Incomplete');
    sheet.getRangeByName('E38:E40').setText('deg');
    sheet.getRangeByName('G35:G40').setText('Complete');
    sheet.getRangeByName('H35:H40').setText('Comply');

    sheet.getRangeByName('C36:D36').merge();
    sheet.getRangeByName('C36').setText('IMU-Lidar Linear Offset Y');
    sheet.getRangeByName('I36').setText(lidarOffsetsList[0].isNotEmpty ? '${lidarOffsetsList[0][1]}' : '');
    sheet.getRangeByName('I36:J36').merge();
    sheet.getRangeByName('C37:D37').merge();
    sheet.getRangeByName('C37').setText('IMU-Lidar Linear Offset Z');
    sheet.getRangeByName('I37').setText(lidarOffsetsList[0].isNotEmpty ? '${lidarOffsetsList[0][2]}' : '');
    sheet.getRangeByName('I37:J37').merge();
    sheet.getRangeByName('C38:D38').merge();
    sheet.getRangeByName('C38').setText('IMU-Lidar Angular Offset Yaw');
    sheet.getRangeByName('I38').setText(lidarOffsetsList[1].isNotEmpty ? '${lidarOffsetsList[1][0]}' : '');
    sheet.getRangeByName('I38:J38').merge();
    sheet.getRangeByName('C39:D39').merge();
    sheet.getRangeByName('C39').setText('IMU-Lidar Angular Offset Pitch');
    sheet.getRangeByName('I39').setText(lidarOffsetsList[1].isNotEmpty ? '${lidarOffsetsList[1][1]}' : '');
    sheet.getRangeByName('I39:J39').merge();
    sheet.getRangeByName('C40:D40').merge();
    sheet.getRangeByName('C40').setText('IMU-Lidar Angular Offset Roll');
    sheet.getRangeByName('I40').setText(lidarOffsetsList[1].isNotEmpty ? '${lidarOffsetsList[1][2]}' : '');
    sheet.getRangeByName('I40:J40').merge();




    sheet.getRangeByName('B17:J40').cellStyle.borders.bottom.lineStyle = LineStyle.thin;
    sheet.getRangeByName('B17:J40').cellStyle.borders.bottom.color = bcol;
    sheet.getRangeByName('I20:J20').merge();
    sheet.getRangeByName('I21:J21').merge();
    sheet.getRangeByName('I22:J22').merge();
    sheet.getRangeByName('I23:J23').merge();
    sheet.getRangeByName('I24:J24').merge();
    sheet.getRangeByName('I25:J25').merge();
    sheet.getRangeByName('I26:J26').merge();
    //sheet.getRangeByName('B25:J30').cellStyle.hAlign=HAlignType.center;


/// Lasers
    sheet.getRangeByName('B42:J95').cellStyle.borders.bottom.lineStyle = LineStyle.thin;
    sheet.getRangeByName('B42:J95').cellStyle.borders.bottom.color = bcol;
      for (int i = 43; i <= 74; i++) {
          sheet.getRangeByName('B$i').setText('${i - 43}');
      }

    sheet.getRangeByName('I74').setText(lidarOffsetsList.length >= 35 ? '${lidarOffsetsList[35][1]}' : '');
    sheet.getRangeByName('J74').setText(lidarOffsetsList.length >= 35 ? '${lidarOffsetsList[35][2]}' : '');
    sheet.getRangeByName('I73').setText(lidarOffsetsList.length >= 34 ? '${lidarOffsetsList[34][1]}' : '');
    sheet.getRangeByName('J73').setText(lidarOffsetsList.length >= 34 ? '${lidarOffsetsList[34][2]}' : '');
    sheet.getRangeByName('I72').setText(lidarOffsetsList.length >= 33 ? '${lidarOffsetsList[33][1]}' : '');
    sheet.getRangeByName('J72').setText(lidarOffsetsList.length >= 33 ? '${lidarOffsetsList[33][2]}' : '');
    sheet.getRangeByName('I71').setText(lidarOffsetsList.length >= 32 ? '${lidarOffsetsList[32][1]}' : '');
    sheet.getRangeByName('J71').setText(lidarOffsetsList.length >= 32 ? '${lidarOffsetsList[32][2]}' : '');
    sheet.getRangeByName('I70').setText(lidarOffsetsList.length >= 31 ? '${lidarOffsetsList[31][1]}' : '');
    sheet.getRangeByName('J70').setText(lidarOffsetsList.length >= 31 ? '${lidarOffsetsList[31][2]}' : '');
    sheet.getRangeByName('I69').setText(lidarOffsetsList.length >= 30 ? '${lidarOffsetsList[30][1]}' : '');
    sheet.getRangeByName('J69').setText(lidarOffsetsList.length >= 30 ? '${lidarOffsetsList[30][2]}' : '');
    sheet.getRangeByName('I68').setText(lidarOffsetsList.length >= 29 ? '${lidarOffsetsList[29][1]}' : '');
    sheet.getRangeByName('J68').setText(lidarOffsetsList.length >= 29 ? '${lidarOffsetsList[29][2]}' : '');
    sheet.getRangeByName('I67').setText(lidarOffsetsList.length >= 28 ? '${lidarOffsetsList[28][1]}' : '');
    sheet.getRangeByName('J67').setText(lidarOffsetsList.length >= 28 ? '${lidarOffsetsList[28][2]}' : '');
    sheet.getRangeByName('I66').setText(lidarOffsetsList.length >= 27 ? '${lidarOffsetsList[27][1]}' : '');
    sheet.getRangeByName('J66').setText(lidarOffsetsList.length >= 27 ? '${lidarOffsetsList[27][2]}' : '');
    sheet.getRangeByName('I65').setText(lidarOffsetsList.length >= 26 ? '${lidarOffsetsList[26][1]}' : '');
    sheet.getRangeByName('J65').setText(lidarOffsetsList.length >= 26 ? '${lidarOffsetsList[26][2]}' : '');
    sheet.getRangeByName('I64').setText(lidarOffsetsList.length >= 25 ? '${lidarOffsetsList[25][1]}' : '');
    sheet.getRangeByName('J64').setText(lidarOffsetsList.length >= 25 ? '${lidarOffsetsList[25][2]}' : '');
    sheet.getRangeByName('I63').setText(lidarOffsetsList.length >= 25 ? '${lidarOffsetsList[24][1]}' : '');
    sheet.getRangeByName('J63').setText(lidarOffsetsList.length >= 25 ? '${lidarOffsetsList[24][2]}' : '');
    sheet.getRangeByName('I62').setText(lidarOffsetsList.length >= 25 ? '${lidarOffsetsList[23][1]}' : '');
    sheet.getRangeByName('J62').setText(lidarOffsetsList.length >= 25 ? '${lidarOffsetsList[23][2]}' : '');
    sheet.getRangeByName('I61').setText(lidarOffsetsList.length >= 22 ? '${lidarOffsetsList[22][1]}' : '');
    sheet.getRangeByName('J61').setText(lidarOffsetsList.length >= 22 ? '${lidarOffsetsList[22][2]}' : '');
    sheet.getRangeByName('I60').setText(lidarOffsetsList.length >= 21 ? '${lidarOffsetsList[21][1]}' : '');
    sheet.getRangeByName('J60').setText(lidarOffsetsList.length >= 21 ? '${lidarOffsetsList[21][2]}' : '');
    sheet.getRangeByName('I59').setText(lidarOffsetsList.length >= 20 ? '${lidarOffsetsList[20][1]}' : '');
    sheet.getRangeByName('J59').setText(lidarOffsetsList.length >= 20 ? '${lidarOffsetsList[20][2]}' : '');
    sheet.getRangeByName('I58').setText(lidarOffsetsList.length >= 19 ? '${lidarOffsetsList[19][1]}' : '');
    sheet.getRangeByName('J58').setText(lidarOffsetsList.length >= 19 ? '${lidarOffsetsList[19][2]}' : '');
    sheet.getRangeByName('I57').setText(lidarOffsetsList.length >= 18 ? '${lidarOffsetsList[18][1]}' : '');
    sheet.getRangeByName('J57').setText(lidarOffsetsList.length >= 18 ? '${lidarOffsetsList[18][2]}' : '');
    sheet.getRangeByName('I56').setText(lidarOffsetsList.length >= 17 ? '${lidarOffsetsList[17][1]}' : '');
    sheet.getRangeByName('J56').setText(lidarOffsetsList.length >= 17 ? '${lidarOffsetsList[17][2]}' : '');
    sheet.getRangeByName('I55').setText(lidarOffsetsList.length >= 16 ? '${lidarOffsetsList[16][1]}' : '');
    sheet.getRangeByName('J55').setText(lidarOffsetsList.length >= 16 ? '${lidarOffsetsList[16][2]}' : '');
    sheet.getRangeByName('I54').setText(lidarOffsetsList.length >= 15 ? '${lidarOffsetsList[15][1]}' : '');
    sheet.getRangeByName('J54').setText(lidarOffsetsList.length >= 15 ? '${lidarOffsetsList[15][2]}' : '');
    sheet.getRangeByName('I53').setText(lidarOffsetsList.length >= 14 ? '${lidarOffsetsList[14][1]}' : '');
    sheet.getRangeByName('J53').setText(lidarOffsetsList.length >= 14 ? '${lidarOffsetsList[14][2]}' : '');
    sheet.getRangeByName('I52').setText(lidarOffsetsList.length >= 13 ? '${lidarOffsetsList[13][1]}' : '');
    sheet.getRangeByName('J52').setText(lidarOffsetsList.length >= 13 ? '${lidarOffsetsList[13][2]}' : '');
    sheet.getRangeByName('I51').setText(lidarOffsetsList.length >= 12 ? '${lidarOffsetsList[12][1]}' : '');
    sheet.getRangeByName('J51').setText(lidarOffsetsList.length >= 12 ? '${lidarOffsetsList[12][2]}' : '');
    sheet.getRangeByName('I50').setText(lidarOffsetsList.length >= 11 ? '${lidarOffsetsList[11][1]}' : '');
    sheet.getRangeByName('J50').setText(lidarOffsetsList.length >= 11 ? '${lidarOffsetsList[11][2]}' : '');
    sheet.getRangeByName('I49').setText(lidarOffsetsList.length >= 10 ? '${lidarOffsetsList[10][1]}' : '');
    sheet.getRangeByName('J49').setText(lidarOffsetsList.length >= 10 ? '${lidarOffsetsList[10][2]}' : '');
    sheet.getRangeByName('I48').setText(lidarOffsetsList.length >= 9 ? '${lidarOffsetsList[9][1]}' : '');
    sheet.getRangeByName('J48').setText(lidarOffsetsList.length >= 9 ? '${lidarOffsetsList[9][2]}' : '');
    sheet.getRangeByName('I47').setText(lidarOffsetsList.length >= 8 ? '${lidarOffsetsList[8][1]}' : '');
    sheet.getRangeByName('J47').setText(lidarOffsetsList.length >= 8 ? '${lidarOffsetsList[8][2]}' : '');
    sheet.getRangeByName('I46').setText(lidarOffsetsList.length >= 7 ? '${lidarOffsetsList[7][1]}' : '');
    sheet.getRangeByName('J46').setText(lidarOffsetsList.length >= 7 ? '${lidarOffsetsList[7][2]}' : '');
    sheet.getRangeByName('I45').setText(lidarOffsetsList.length >= 6 ? '${lidarOffsetsList[6][1]}' : '');
    sheet.getRangeByName('J45').setText(lidarOffsetsList.length >= 6 ? '${lidarOffsetsList[6][2]}' : '');
    sheet.getRangeByName('I44').setText(lidarOffsetsList.length >= 5 ? '${lidarOffsetsList[5][1]}' : '');
    sheet.getRangeByName('J44').setText(lidarOffsetsList.length >= 5 ? '${lidarOffsetsList[5][2]}' : '');
    sheet.getRangeByName('I43').setText(lidarOffsetsList.length >= 4 ? '${lidarOffsetsList[4][1]}' : '');
    sheet.getRangeByName('J43').setText(lidarOffsetsList.length >= 4 ? '${lidarOffsetsList[4][2]}' : '');
      // sheet.getRangeByName('B43').setText('0');
      // sheet.getRangeByName('B44').setText('1');
    sheet.getRangeByName('C43:C74').setText('Laser');
      sheet.getRangeByName('I42').setText('Azimuth');
      sheet.getRangeByName('J42').setText('Elevation Offset');
      sheet.getRangeByName('C75').setText('Laser Scale Factor Error');
      sheet.getRangeByName('E43:E75').setText('deg');
      sheet.getRangeByName('F43:F75').setText('Complete/Incomplete');
      sheet.getRangeByName('G43:G75').setText('Complete');
      sheet.getRangeByName('H43:H75').setText('Comply');
    sheet.getRangeByName('B43:B74').cellStyle.hAlign=HAlignType.center;
/// Camera
      sheet.getRangeByName('B76:D76').merge();
      sheet.getRangeByName('B76:D76').cellStyle.bold=true;
      sheet.getRangeByName('B76:D76').cellStyle.hAlign=HAlignType.center;
      sheet.getRangeByName('B76').setText('Camera Boresighting');
      sheet.getRangeByName('C77').setText('Flight test #1');
      sheet.getRangeByName('C78:D78').merge();
      sheet.getRangeByName('C78').setText('IMU-Camera Linear Offset X');
    sheet.getRangeByName('I78').setText(lidarOffsetsList.length > 36 ? '${lidarOffsetsList[36][0]}' : '');
    sheet.getRangeByName('I78:J78').merge();
      sheet.getRangeByName('E78:E80').setText('m');
      sheet.getRangeByName('F78:F86').setText('Complete/Incomplete');
      sheet.getRangeByName('G78:G86').setText('Complete');
      sheet.getRangeByName('H78:H86').setText('Comply');
      sheet.getRangeByName('C79:D79').merge();
      sheet.getRangeByName('C79').setText('IMU-Camera Linear Offset Y');
    sheet.getRangeByName('I79').setText(lidarOffsetsList.length > 36 ? '${lidarOffsetsList[36][1]}' : '');
    sheet.getRangeByName('I79:J79').merge();
      sheet.getRangeByName('C80:D80').merge();
      sheet.getRangeByName('C80').setText('IMU-Camera Linear Offset Z');
    sheet.getRangeByName('I80').setText(lidarOffsetsList.length > 36 ? '${lidarOffsetsList[36][2]}' : '');
    sheet.getRangeByName('I80:J80').merge();
      sheet.getRangeByName('C81:D81').merge();
      sheet.getRangeByName('C81').setText('IMU-Camera Angular Offset Yaw');
    sheet.getRangeByName('I81').setText(lidarOffsetsList.length > 36 ? '${lidarOffsetsList[37][0]}' : '');
    sheet.getRangeByName('I81:J81').merge();
      sheet.getRangeByName('E81:E83').setText('deg');
      sheet.getRangeByName('C82:D82').merge();
      sheet.getRangeByName('C82').setText('IMU-Camera Angular Offset Pitch');
    sheet.getRangeByName('I82').setText(lidarOffsetsList.length > 36 ? '${lidarOffsetsList[37][1]}' : '');
    sheet.getRangeByName('I82:J82').merge();
      sheet.getRangeByName('C83:D83').merge();
      sheet.getRangeByName('C83').setText('IMU-Camera Angular Offset Roll');
    sheet.getRangeByName('I83').setText(lidarOffsetsList.length > 36 ? '${lidarOffsetsList[37][2]}' : '');
    sheet.getRangeByName('I83:J83').merge();
      sheet.getRangeByName('C84:D84').merge();
      sheet.getRangeByName('C84').setText('Camera Focal Length');
    sheet.getRangeByName('I84').setText(lidarOffsetsList.length > 36 ? '${lidarOffsetsList[39][0]}' : '');
    sheet.getRangeByName('I84:J84').merge();
      sheet.getRangeByName('E84:E86').setText('mm');
      sheet.getRangeByName('C85:D85').merge();
      sheet.getRangeByName('C85').setText('Camera Delta X / Delta Y');
    sheet.getRangeByName('I85').setText(lidarOffsetsList.length > 36 ? '${lidarOffsetsList[39][5]}' : '');
    sheet.getRangeByName('J85').setText(lidarOffsetsList.length > 36 ? '${lidarOffsetsList[39][4]}' : '');
      sheet.getRangeByName('C86:D86').merge();
      sheet.getRangeByName('C86').setText('Camera Rational Numerator / Denominator');
    sheet.getRangeByName('I86').setText(lidarOffsetsList.length > 36 ? '${lidarOffsetsList[39][3]}' : '');
    sheet.getRangeByName('J86').setText(lidarOffsetsList.length > 36 ? '${lidarOffsetsList[39][2]}' : '');
      sheet.getRangeByName('C87').cellStyle.bold=true;
      sheet.getRangeByName('C87').setText('Review');
      sheet.getRangeByName('C88').setText('Flight test #1');
      sheet.getRangeByName('C89:D89').merge();
      sheet.getRangeByName('C89').setText('Lidar Roof Alignment check');
      sheet.getRangeByName('F89:F95').setText('Complete/Incomplete');
      sheet.getRangeByName('G89:G95').setText('Complete');
      sheet.getRangeByName('H89:H96').setText('Comply');
      sheet.getRangeByName('C90:D90').merge();
      sheet.getRangeByName('C90').setText('Lidar Powerline Alignment check');
      sheet.getRangeByName('C91:D91').merge();
      sheet.getRangeByName('C91').setText('Lidar Ground Alignment');
      sheet.getRangeByName('C92:D92').merge();
      sheet.getRangeByName('C92').setText('Lidar Boresighting Algorithm');
      sheet.getRangeByName('C93:D93').merge();
      sheet.getRangeByName('C93').setText('Camera Roof Alignment');
      sheet.getRangeByName('C94:D94').merge();
      sheet.getRangeByName('C94').setText('Camera Powerline Alignment');
      sheet.getRangeByName('C95:D95').merge();
      sheet.getRangeByName('C95').setText('Camera Road Alignment');
      sheet.getRangeByName('C96:D96').merge();
      sheet.getRangeByName('C96').setText('Single Pass Lidar Point Cloud Accuracy');
      sheet.getRangeByName('E96').setText('sm');
      sheet.getRangeByName('F96').setText('3-5 PPK; 5-7 RTK');
      sheet.getRangeByName('G96').setText('3-5 PPK');
/// Sign
    sheet.getRangeByName('I98:J98').merge();
    sheet.getRangeByName('I99:J99').merge();
    sheet.getRangeByName('H98').setText('Test Engineer');
    sheet.getRangeByName('I98').setText('Inertial Labs Calibration Team');
    sheet.getRangeByName('H99').setText('Date');
    sheet.getRangeByName('I98:I99').cellStyle.hAlign=HAlignType.right;
    sheet.getRangeByName('I99').dateTime = DateTime.now();
    sheet.getRangeByName('I99').numberFormat =
    r'[$-x-sysdate]mmmm dd, yyyy';
    // Определяем диапазон из четырёх ячеек ( B16:J86 )
    final Range rangeBorderBottom9 = sheet.getRangeByName('H99:J99');
    final Range rangeBorderTop9 = sheet.getRangeByName('H98:J98');
    final Range rangeBorderLeft9 = sheet.getRangeByName('H98:H99');
    final Range rangeBorderRight9 = sheet.getRangeByName('J98:J99');
    // Устанавливаем внешний стиль границы
    rangeBorderTop9.cellStyle.borders.top.lineStyle = LineStyle.thin;
    rangeBorderBottom9.cellStyle.borders.bottom.lineStyle = LineStyle.thin;
    rangeBorderLeft9.cellStyle.borders.left.lineStyle = LineStyle.thin;
    rangeBorderRight9.cellStyle.borders.right.lineStyle = LineStyle.thin;
    //rangeBorder.cellStyle.borders.all.color = '#000000'; // Цвет рамки (чёрный)

///


    // Сохраняем файл Excel (XLSX)
    final List<int> xlsxBytes = workbook.saveAsStream(); // Сохраняем в формате XLSX

    // Сохраняем файл PDF (для этого нужно вызвать saveAsPdf)
   // final List<int> pdfBytes = workbook.saveAsStream();

    // Освобождаем ресурсы
    workbook.dispose();

    // Получаем директорию для сохранения
   // final directory = await getApplicationDocumentsDirectory();
    final xlsxPath = '$saveDirectory/ATC_${listContentTxt[0]}-${listContentTxt[1]}.xlsx';
    //final pdfPath = '${directory.path}/Calibration Certificate.pdf';
    //print("xlsxPath ==> \n$xlsxPath");

    // Создаем файлы для XLSX и PDF
    final File xlsxFile = File(xlsxPath);
    //final File pdfFile = File(pdfPath);

    // Записываем байты в файлы
    await xlsxFile.writeAsBytes(xlsxBytes);
    //await pdfFile.writeAsBytes(pdfBytes);


    // ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    //   content: Text('File saved at \n$xlsxFile'),
    // ));


  }
