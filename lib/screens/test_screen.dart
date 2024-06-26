import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:process_run/shell.dart';
import '../../constant.dart';
import '../models/device_manager.dart';
import '../models/test_class.dart';

class TestScreen extends StatefulWidget {
  const TestScreen({Key? key}) : super(key: key);
  @override
  TestScreenState createState() => TestScreenState();
}

class TestScreenState extends State<TestScreen> {
  final TestClass _testManager = TestClass();

  @override
  void initState() {
    super.initState();
    _testManager.init();
  }

  void updateState() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButton<String>(
              hint: Text("Select Brand"),
              value: _testManager.selectedBrand,
              onChanged: (String? newValue) {
                setState(() {
                  _testManager.selectedBrand = newValue;
                });
              },
              items: _testManager.brandsList.map((String brand) {
                return DropdownMenuItem<String>(
                  value: brand,
                  child: Text(brand),
                );
              }).toList(),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                await _testManager.changeBrand(updateState);
              },
              child: Text('Change Brand'),
            ),
            Text(_testManager.outputBrand),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                await _testManager.deleteCalibration(updateState);
              },
              child: Text('Delete Calibration'),
            ),
            //Text(_testManager.outputCalibration),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                await _testManager.checkCalibrationFile(updateState);
              },
              child: Text('Check Calibration File'),
            ),
            //Text(_testManager.outputCalibration),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                await _testManager.restoreCalibration(updateState);
              },
              child: Text('Restore Calibration'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                await _testManager.getDeviceInfo(updateState);
              },
              child: Text('Get device info'),
            ),
            Text(_testManager.outputCalibration),
          ],
        ),
      ),
    );
  }
}
