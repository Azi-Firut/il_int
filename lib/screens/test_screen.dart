
import 'package:flutter/material.dart';
import 'package:process_run/shell.dart';
import '../models/device_fix_class.dart';
import '../models/production_class.dart';
import '../models/test_class.dart';

class TestScreen extends StatefulWidget {
  const TestScreen({Key? key}) : super(key: key);
  @override
  TestScreenState createState() => TestScreenState();
}

class TestScreenState extends State<TestScreen> {
  final TestClass _testManager = TestClass();
  final DeviceFix _deviceFixFunctionKit = DeviceFix();
  final Production _productionFunctionKit = Production();

  @override
  void initState() {
    super.initState();
    _testManager.init();
    _deviceFixFunctionKit.init();
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
              value: _deviceFixFunctionKit.selectedBrand,
              onChanged: (String? newValue) {
                setState(() {
                  _deviceFixFunctionKit.selectedBrand = newValue;
                });
              },
              items: _deviceFixFunctionKit.brandsList.map((String brand) {
                return DropdownMenuItem<String>(
                  value: brand,
                  child: Text(brand),
                );
              }).toList(),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                await _deviceFixFunctionKit.changeBrand(updateState);
              },
              child: Text('Change Brand'),
            ),
            Text(_deviceFixFunctionKit.outputBrand),
            //SizedBox(height: 20),
            // ElevatedButton(
            //   onPressed: () async {
            //     await _deviceManager.addCustomSSiD(updateState);
            //   },
            //   child: Text('Rename SSid'),
            // ),
            // ElevatedButton(
            //   onPressed: () async {
            //     await _deviceManager.restoreWpaSSid(updateState);
            //   },
            //   child: Text('Restore SSid default'),
            // ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                await _deviceFixFunctionKit.deleteCalibration(updateState);
              },
              child: Text('Delete Calibration'),
            ),
            //Text(_deviceManager.outputCalibration),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                await _deviceFixFunctionKit.checkCalibrationFile(updateState);
              },
              child: Text('Check Calibration File'),
            ),
            //Text(_deviceManager.outputCalibration),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                await _deviceFixFunctionKit.restoreCalibration(updateState);
              },
              child: Text('Restore Calibration'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                await _productionFunctionKit.getDeviceInfo(updateState);
              },
              child: Text('Get device info'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                await _testManager.getI(updateState);
              },
              child: Text('IMU'),
            ),
            Container(child: Text(_deviceFixFunctionKit.statusOutput),color: Colors.blueGrey,),
            Container(color: Colors.redAccent,
              child: Column(
                children: [
                 Text(_testManager.unitResponse),
                //  Text(_testManager.outputCalibration2),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
