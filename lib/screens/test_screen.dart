import 'package:flutter/material.dart';
import 'package:il_int/models/device_fix_class.dart';
import 'package:il_int/models/production_class.dart';
import 'package:il_int/models/test_class2.dart';

import 'package:il_int/widgets/answer_from_unit.dart';
import 'package:provider/provider.dart';
import '../constant.dart';

import '../models/create_readme_class.dart';
import '../models/data.dart';
import '../models/test_get_imu_number_g1.dart';




class TestScreen extends StatefulWidget {
  const TestScreen({super.key});

  @override
  TestScreenState createState() => TestScreenState();
}

class TestScreenState extends State<TestScreen> {
final TestGetImuNumberG1 _getImuNumberG1 = TestGetImuNumberG1();
  final Test _testGetUnitInfo = Test();
  final TextEditingController _controller = TextEditingController();
  final ReadMeClass _readMeClassKit = ReadMeClass();

  bool _isSelectedCreateZip = false;
  var statusOutput= "";
  ///
  void updateState() {
    setState(() {
      var test = unitResponse;
      test;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              'TEST',
              style: TextStyle(
                fontSize: 24,
                color: Color(0xFFFFFFFF),
              ),
            ),
            TextField(
              style: const TextStyle(
                color: Colors.grey,
              ),
              textCapitalization: TextCapitalization.characters,
              controller: _controller,
              decoration: const InputDecoration(
                hintText: 'Enter Unit Serial Number',
                hintStyle: TextStyle(color: Colors.grey),
              ),
            ),
            const SizedBox(height: 20),
/// G1 get imu
            ElevatedButton(
              onPressed: () async {
                await _getImuNumberG1.genSwitchToGetImuNumber(updateState);
              },

              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF258346),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              child: const Text(
                'Get Unit Imu G1',
                style: TextStyle(
                  color: Color(0xFFFFFFFF),
                ),
              ),
            ),
            const SizedBox(height: 20),
///
            ///
            ElevatedButton(
              onPressed: () async {
                await _getImuNumberG1.getImuG1_01(updateState);
              },

              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF258346),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              child: const Text(
                '1',
                style: TextStyle(
                  color: Color(0xFFFFFFFF),
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                await _getImuNumberG1.getImuG1_02(updateState);
              },

              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF258346),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              child: const Text(
                '2',
                style: TextStyle(
                  color: Color(0xFFFFFFFF),
                ),
              ),
            ),
            // const SizedBox(height: 20),
            // ElevatedButton(
            //   onPressed: () async {
            //     await _getImuNumberG1.getImuG1_03(updateState);
            //   },
            //
            //   style: ElevatedButton.styleFrom(
            //     backgroundColor: const Color(0xFF258346),
            //     shape: RoundedRectangleBorder(
            //       borderRadius: BorderRadius.circular(3),
            //     ),
            //   ),
            //   child: const Text(
            //     '3',
            //     style: TextStyle(
            //       color: Color(0xFFFFFFFF),
            //     ),
            //   ),
            // ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                await _getImuNumberG1.getImuG1_04(updateState);
              },

              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF258346),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              child: const Text(
                '4',
                style: TextStyle(
                  color: Color(0xFFFFFFFF),
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                await _getImuNumberG1.getImuG1_05(updateState);
              },

              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF258346),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              child: const Text(
                '5',
                style: TextStyle(
                  color: Color(0xFFFFFFFF),
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                await _getImuNumberG1.getImuG1_06(updateState);
              },

              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF258346),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              child: const Text(
                '6',
                style: TextStyle(
                  color: Color(0xFFFFFFFF),
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                await _getImuNumberG1.getImuG1_07(updateState);
              },

              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF258346),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              child: const Text(
                '7',
                style: TextStyle(
                  color: Color(0xFFFFFFFF),
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                await _getImuNumberG1.getImuG1_08(updateState);
              },

              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF258346),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              child: const Text(
                '8',
                style: TextStyle(
                  color: Color(0xFFFFFFFF),
                ),
              ),
            ),
            const SizedBox(height: 20),
            ///
            ///
            ElevatedButton(
              onPressed: () async {
              //  await _testGetUnitInfo.getDeviceInfo(updateState);
                await _testGetUnitInfo.getImuGen2(updateState);
              },

              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4E7DE2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              child: const Text(
                'Get Unit Information',
                style: TextStyle(
                  color: Color(0xFFFFFFFF),
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                await _testGetUnitInfo.runUnit(updateState);
              },

              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5B5B5B),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              child: const Text(
                'Run',
                style: TextStyle(
                  color: Color(0xFFFFFFFF),
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
              //  await _productionFunctionKit.uploadAtcToUnit(updateState);
              },

              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5B5B5B),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              child: const Text(
                'Atc menu',
                style: TextStyle(
                  color: Color(0xFFFFFFFF),
                ),
              ),
            ),
            const SizedBox(height: 20),

            /// OPERATION TEXT
            UnitResponse(),
            const SizedBox(height: 20),
            if (output["IMU SN: "] != null && RegExp(r'\d').hasMatch(output["IMU SN: "]!)
            // &&
            // output["Reciever SN: "] != null && RegExp(r'\d').hasMatch(output["Reciever SN: "]!)&&
            //     output["Lidar: "] != null && RegExp(r'\d').hasMatch(output["Lidar: "]!)
            )
              ElevatedButton(
                onPressed: () async {
                  await _readMeClassKit.createFoldersAndFile(updateState);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5B5B5B),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                child: const Text(
                  'Create Readme file',
                  style: TextStyle(
                    color: Color(0xFFFFFFFF),
                  ),
                ),
              ),
            // SelectableText(
            //     ("${context.watch<Data>().getUnitResponse}"),
            //   style: const TextStyle(
            //     color: Colors.grey,
            //   ),
            // ),

          ],
        ),
      ),
    );
  }
}
