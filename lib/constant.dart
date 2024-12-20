import 'dart:io';
import 'dart:ui';

import 'package:il_int/models/usb_check.dart';
String version = 'v.2.1 (beta)';
Map unitResponse = {'step':null,'text':null};
List<String> unitInfo=['','','',''];
Map output = {"IMU SN: ":"","Brand: ":"","Password: ":"","SSID default: ":"","SSID now: ":"","Receiver: ":"","Reciever SN: ":"","Firmware: ":"","Lidar: ":"","IMU Filter: ":""};
bool zip = false;

var usbColChanger = Color(0xFF3D3D3D);
String keyPath = '';
String dragAndDropMessage = "Select two files and drop here";
Color textColorGray = Color(0xFFA9A9A9);
var titleText='';
var hostKey ='';
var connectedSsid = '';
var extractedDataVal;

// "ssh-ed25519 255 SHA256:0z+smqD1LNdbBqOoIjFhJWhoxuJFiDtctVLxyssNFYc"; //1
// "ssh-ed25519 255 SHA256:yGWCAcgZRDEAEymGt1Kbe5GXRz3IXU+dQmdXp9mOtqc"; //2
const List keyGen1 =
    ["UHLVUUVFOktIVXBNlVciJ1LKZXTktGRmClsDZSE0yFOiIBlJY2ORzYYSP1zHaGJEyBLWR5pAc3CRwBMjDU2KCkDVuVY3IJ5OcHARpHb2I46IIGS5vCbmDUKIQ2V9tWbWBVuTdDTogVaWR1wUb3CJ0QZWNQtKb3XBlSbnLNzNaCP1rMZXBkKZUHBViIbGHljULUSxpMbmSVzXOiZAzWCkLFBVQULFFVMlUZqYWkMhODaESxYITmW9ZGVEPl0DYmG1sTemBRIHQXQlOPVFNlBVQUGFBJSWKJtUbHFpkKSEJF5OTlDRZHQUUFBZQkZJCSQkRt5IOUI1GYc0TlSBWUI8KORGCI5JUlUBtOM2CF3CZEUpnBNHCdkFYVTVXPa0Fx4XSjLl0OWHXBDDRFSJEYWVTdsOZ3Dp6PeECtpOY1CFsQeCRt0NaEKxRMa0Z9jEUUWM5SaFPI2LNkN50PcXOUwJTQKo3LZjSBtYNTABHVU2SdTYQTK0KVUHMJpBdmCF0ZZSR1MTaWN5lKczXogJMQBpBXQUHFBTSVXFDLOUQhwYUjYNCXajGZLMZEWpzMWkX0yYZEGtGDRTNV3MRmXg1FK2TcwCRTXdYZZ1YJOXcVQU0KWlMY4FaTJl5DUTM09QClNByCaXTZhVdGHUtBTUEFDQOiSBmMYTSQ1YMzWQ3KOGVUwQMTOA1EZjJI1DYWOFkNMmWRlOMzGM1EY2KYxPZjMZmIYmVM5UMDLEwEMDCJmA","ssh-ed25519 255 SHA256:0z+smqD1LNdbBqOoIjFhJWhoxuJFiDtctVLxyssNFYc"];
const List keyGen2 =
    ["UHGVUCVFFktTVXZNlCciK1LYZXBktGRmJlsNZST0yBOiBBlVY2DRzFYSP1zFaGDEyGLWS5pOc3ERwFMjDU2CCkVVuKY3ZJ5BcHHRpCb2L46VIGK5vTbmUUKWQ2S9tTbWYVuRdDLogMUkYVTHRVWBJPClOB1LYmJxpVYyS1MMaWZ5lFczVogCMwSpBVQUDFBBRTXJWValApIRTmZhMCWEH5vGWVVRJIdGYJtDbHHpkWSEEF5BTlRRZXQUAFBAQUCliCbWXx6ZZEVhBOeUI5UGWUGFBXQUUJCMQkY5aMUmE02VM3UJoSRkAh4QCjIJELTlRFOHR3SUyYTnOhzSSDWhCJRlIBlDK0PthIUXGZoGc3OdTINDLQyFbUFJ5EVWWMrYUFCcrQMWAVuJaGXk3XdGEhLKcVSJhOckSY0KQmWxxPNGCJBINGLt2GTVTIKZWHVEvPWWYRmHcFNNMSMTMA9HClOByNaXNZhPdGWUtQTGUluZZXXM6KIDIEKVQUBFBMQUTlFUTjAE0DRUT42LQlXlLLSWY1ISR0ShiUOEUFrKaULR3JLzBY4KSUKFqDTnUFIUb0ZNBJYXMIrSbWMJiRTVId5PClDByGaXLZhVdGGUtWTUSFDKOiHAxGZGHI1MMmMIyBZDQY2XYjQYyBZDZVmFODSA5YZDZc4MMjVMzXNzUAyPOGBQyTMjAA4AYmTM2IMTNlkO","ssh-ed25519 255 SHA256:yGWCAcgZRDEAEymGt1Kbe5GXRz3IXU+dQmdXp9mOtqc"];

const String ftpPath = "N:\\!Factory_calibrations_and_tests\\RESEPI\\";

const String initialParamPath = 'N:/Manufacturing/05. RESEPI/parameter_configurations/il_int Calibration parameters/Initial';
const String finalParamPath = 'N:/Manufacturing/05. RESEPI/parameter_configurations/il_int Calibration parameters/Final';

String addressToFolder = '';

const Map brandImagesAtc = {'WINGTRA':'\\assets\\fill_atc\\atc_template\\logo_img_atc\\WINGTRA.png',
  'FLIGHTS':'\\assets\\fill_atc\\atc_template\\logo_img_atc\\FLIGHTS.png',
  'MARSS':'\\assets\\fill_atc\\atc_template\\logo_img_atc\\MARSS.png',
  'ML':'\\assets\\fill_atc\\atc_template\\logo_img_atc\\ML.png',
  'PHOENIX':'\\assets\\fill_atc\\atc_template\\logo_img_atc\\PHOENIX.png',
  'Inertial Labs':'\\assets\\fill_atc\\atc_template\\logo_img_atc\\Inertial Labs.png',
  'STONEX':'\\assets\\fill_atc\\atc_template\\logo_img_atc\\STONEX.png',
  'TERSUS':'\\assets\\fill_atc\\atc_template\\logo_img_atc\\TERSUS.png',
  'TRIDAR':'\\assets\\fill_atc\\atc_template\\logo_img_atc\\TRIDAR.png',
};
/////////////////////////////////////////
