import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cross_file/cross_file.dart';
import 'dart:io';
import 'package:dcat/dcat.dart';
import 'package:desktop_window/desktop_window.dart';
import 'package:il_int/screens/merge_basefile.dart';
import '../constant.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as htmlParser;
import 'package:html/dom.dart' as htmlDom;




class UnitPreShipmentCheck extends StatefulWidget {
  UnitPreShipmentCheck({Key? key}) : super(key: key);
  @override
  _UnitPreShipmentCheckState createState() => _UnitPreShipmentCheckState();
}

class _UnitPreShipmentCheckState extends State<UnitPreShipmentCheck> {
  @override
  void initState() {
    DesktopWindow.setWindowSize(const Size(800, 600));
    DesktopWindow.setMinWindowSize(const Size(800, 600));
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          actions: [
            GestureDetector(
              onTap: () {Navigator.of(context).push(MaterialPageRoute(builder: (context) => MergeBasefile()),);}, // --------------- Merge Base files
              child: const Padding(
                padding: EdgeInsets.only(right: 14.0),
                child: Icon(
                  Icons.south_america_outlined,
                  color: Colors.white,
                  size: 40,
                ),
              ),
            ),
          ],
          shadowColor: Colors.black,
          elevation: 6,
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topRight, // Start direction
                end: Alignment.bottomRight, // End direction
                colors: [
                  Colors.orange, // Start Color
                  Colors.red, // End Color
                ], // Customize your colors here
              ),
            ),
          ),
          centerTitle: true,
          title: const Text(
            'Pre shipment unit check',
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
        ),
        body: MyHomePage(),
      ),
    );
  }
}


//=========================================== PARSER

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String _responseData = 'No data received';

  Future<void> fetchData() async {
    try {
      final response = await http.get(Uri.parse('http://192.168.12.1'));
      if (response.statusCode == 200) {
        setState(() {
          _responseData = response.body;
        });
      } else {
        setState(() {
          _responseData = 'Failed to fetch data. Status code: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _responseData = 'Error: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('HTTP Example'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ElevatedButton(
              onPressed: fetchData,
              child: Text('Fetch Data'),
            ),
            SizedBox(height: 20),
            Text(
              _responseData,
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}