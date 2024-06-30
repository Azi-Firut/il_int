import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:process_run/shell.dart';
import '../../constant.dart';
import '../models/device_manager.dart';

class DeviceFixScreenTest extends StatefulWidget {
  const DeviceFixScreenTest({Key? key}) : super(key: key);
  @override
  DeviceFixScreenTestState createState() => DeviceFixScreenTestState();
}

class DeviceFixScreenTestState extends State<DeviceFixScreenTest> {
  final DeviceManager _deviceManager = DeviceManager();

  @override
  void initState() {
    super.initState();
    _deviceManager.init();
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
              value: _deviceManager.selectedBrand,
              onChanged: (String? newValue) {
                setState(() {
                  _deviceManager.selectedBrand = newValue;
                });
              },
              items: _deviceManager.brandsList.map((String brand) {
                return DropdownMenuItem<String>(
                  value: brand,
                  child: Text(brand),
                );
              }).toList(),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                await _deviceManager.changeBrand(updateState);
              },
              child: Text('Change Brand'),
            ),
            Text(_deviceManager.outputBrand),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                await _deviceManager.deleteCalibration(updateState);
              },
              child: Text('Delete Calibration'),
            ),
            Text(_deviceManager.outputCalibration),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                await _deviceManager.checkCalibrationFile(updateState);
              },
              child: Text('Check Calibration File'),
            ),
            Text(_deviceManager.outputCalibration),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                await _deviceManager.restoreCalibration(updateState);
              },
              child: Text('Restore Calibration'),
            ),
            Text(_deviceManager.outputCalibration),
          ],
        ),
      ),
    );
  }
}
