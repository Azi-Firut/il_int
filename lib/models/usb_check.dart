import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../constant.dart';


    usbColor({String? dir}) async {

    Color usbButtonColor=Color(0xFF3D3D3D);
    String unitIp = '192.168.12.1';

    final url = dir != null
        ? 'http://$unitIp/cgi-bin/dir?$dir'
        : 'http://$unitIp/cgi-bin/dir?';

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Cache-Control': 'no-cache',
          'Pragma': 'no-cache',
          'If-Modified-Since': 'Sat, 1 Jan 2000 00:00:00 GMT',
        },
      );

      if (response.statusCode == 200) {
        final decodedResponse = json.decode(response.body) as Map<String, dynamic>;
        //debugPrint('Ответ сервера: $decodedResponse');
        //debugPrint('${decodedResponse}');
        if (decodedResponse['names'][0] != '' && decodedResponse['names'] != null
           ) {
          usbColChanger = Color(0xFF941919);

         // print('USB is not empty');

        } else {
         // print('Неизвестный формат ответа от сервера');
          usbColChanger = Color(0xFF3D3D3D);
        }
      } else {
       // print('Ошибка: ${response.statusCode}');
        usbColChanger = Color(0xFF3D3D3D);
      }
    } catch (e) {
     // print('Ошибка обработки ответа: $e');
      usbColChanger = Color(0xFF3D3D3D);
    } finally {

    }

  }


