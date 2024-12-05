//
// import 'package:flutter/material.dart';
// //import 'api_service.dart';
// import 'package:http/http.dart' as http;
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:html/parser.dart' show parse;
//
//
//
//   bool isLoading = false;
//
//   Future<void> handleLogin() async {
//
//     isLoading = true;
//     final username = "jbet90";
//     final password = "042590jcb";
//     final success = await login(username, password);
//   }
//
//   String baseUrl = 'http://10.4.0.2';
//   List<String> extractedData = [];
//   List<String> itemsList=[];
//
//   // Логин пользователя
//   Future<bool> login(String username, String password) async {
//     final loginUrl = Uri.parse('$baseUrl/login');
//
//     try {
//       final response = await http.post(
//         loginUrl,
//         headers: {
//           'Content-Type': 'application/x-www-form-urlencoded',
//           'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36',
//         },
//         body: {
//           'username': username,
//           'password': password,
//         },
//       );
//
//       print('Login response status: ${response.statusCode}');
//       print('Login response headers: ${response.headers}');
//
//       if (response.statusCode == 302) {
//         final cookies = response.headers['set-cookie'];
//         if (cookies != null) {
//           await saveCookies(cookies);
//           return true;
//         } else {
//           print('No cookies received.');
//         }
//       } else {
//         print('Login failed with status code: ${response.statusCode}');
//       }
//     } catch (e) {
//       print('Login error: $e');
//     }
//     return false;
//   }
//
//   // Сохранение cookies
//   Future<void> saveCookies(String cookies) async {
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.setString('cookies', cookies);
//   }
//
//   // Получение сохраненных cookies
//   Future<String?> getSavedCookies() async {
//     final prefs = await SharedPreferences.getInstance();
//     return prefs.getString('cookies');
//   }
//
//   // Получение данных с сервера
//   Future<void> fetchData() async {
//     final cookies = await getSavedCookies();
//
//     if (cookies == null) {
//       print('No valid session. Please log in.');
//       return;
//     }
//
//     final url = Uri.parse('$baseUrl/?query=L36E1341'); // Убедитесь, что URL правильный
//     try {
//       final response = await http.get(
//         url,
//         headers: {
//           'Cookie': cookies,
//           'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36',
//         },
//       );
//
//       if (response.statusCode == 200) {
//         // Парсим HTML ответ
//         var document = parse(response.body);
//         //  print(document.outerHtml);
//
//         // Извлекаем все данные из <td class="text-success">
//         var dataval = document.querySelectorAll('td.text-success');
//         var elements = document.querySelectorAll('tbody');
//
//
//           var values=dataval.map((e) => e.text.trim()).toList();
//           extractedData = elements.map((e) => e.text.trim()).toList();
//           itemsList = extractedData[50].split(RegExp(r'\s{2,}'));
//           print("====== ${values.length}");
//           print("====== ${extractedData.length}");
//           print("====== $itemsList");
//
//           //  print("====== ${extractedData[50]}"); // imu and all data what we need
//
//       } else {
//         print('Failed to fetch data: ${response.statusCode}');
//       }
//     } catch (e) {
//       print('Fetch data error: $e');
//     }
//   }
//
//
//  //   fetchData(); // Получаем данные при загрузке экрана
//
//
//
//


import 'package:flutter/material.dart';
//import 'package:html/dom.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:html/parser.dart' show parse;

import '../constant.dart';



  ///  handleLogin(); // Пытаемся авторизоваться при старте приложения
///

Future <dynamic> getIMUcalVAl(imuSerialNumber) async {
  final baseUrl = 'http://10.4.0.2';
  final loginUrl = Uri.parse('$baseUrl/login');
  List<String> itemsList ;
  var success;

  Future<void> saveCookies(String cookies) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('cookies', cookies);
  }

  Future<bool> login(String username, String password) async {


    try {
      final response = await http.post(
        loginUrl,
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36',
        },
        body: {
          'username': username,
          'password': password,
        },
      );

      if (response.statusCode == 302) {
        final cookies = response.headers['set-cookie'];
        if (cookies != null) {
          await saveCookies(cookies);
          return true;
        }
      }
    } catch (e) {
      print('Login error: $e');
    }
    return false;
  }

  Future<void> handleLogin() async {
    final username = "jbet90";
    final password = "042590jcb";
    success = await login(username, password);
  }

 handleLogin();





  Future<dynamic> getSavedCookies() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('cookies');
  }

  Future<dynamic> fetchData() async {
    final cookies = await getSavedCookies();
    //List<String> itemsList = ['','']; // Устанавливаем значение по умолчанию
var pazuzu;
    if (cookies == null) {
      print('No valid session. Please log in.');
      return pazuzu; // Возвращаем пустой результат
    }

    final url = Uri.parse('$baseUrl/?query=$imuSerialNumber');
    try {
      final response = await http.get(
        url,
        headers: {
          'Cookie': cookies,
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36',
        },
      );

      if (response.statusCode == 200) {
        var document = parse(response.body);
        var table = document.getElementById("results");
         pazuzu = table?.children[2].children[0].children ;
        print('====== data in response. ${pazuzu}');
       // var elements = document.querySelectorAll('tbody');
       // var dataval = document.querySelectorAll('td.text-success');

        if (pazuzu!.isNotEmpty && pazuzu.length < 51) {
         // final extractedData = elements.map((e) => e.text.trim()).toList();
         // itemsList = extractedData[50].split(RegExp(r'\s{2,}')); // Парсим данные
         // extractedDataVal = dataval.map((e) => e.text.trim()).toList();
         // print('=================== Fetch data values 1:\n ${extractedDataVal}');
         // print('=================== Fetch data 1:\n ${itemsList}');
        } else {
          print('Insufficient data in response.');
        }
      } else {
        print('Failed to fetch data: ${response.statusCode}');
      }
    } catch (e) {
      print('Fetch data error: $e');
    }

    return pazuzu; // Возвращаем itemsList в любом случае
    // print('------------------\n${pazuzu?[8].text.trim()}');
  }



  return fetchData();
}






