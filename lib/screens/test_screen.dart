import 'package:flutter/material.dart';
import 'package:il_int/models/device_fix_class.dart';
import 'package:il_int/models/final_calibration_class.dart';
import 'package:il_int/models/init_calibration_class.dart';
import 'package:il_int/models/test_class_widget.dart';
import 'package:il_int/widgets/answer_from_unit.dart';
import 'package:provider/provider.dart';
import '../constant.dart';
import '../models/create_readme_class.dart';
import '../models/data.dart';

import '../models/production_class.dart';


class TestScreen extends StatefulWidget {
  const TestScreen({super.key});

  @override
  TestScreenState createState() => TestScreenState();
}

class TestScreenState extends State<TestScreen> {

  final Production _productionFunctionKit = Production();
  final TextEditingController _controller = TextEditingController();
   final ReadMeClass _readMeClassKit = ReadMeClass();

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
            ElevatedButton(
              onPressed: () async {
                await _productionFunctionKit.openFolder(_controller.text.trim(),updateState);
                // setState(() {}); // Update UI with the new status message
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5B5B5B),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              child: const Text(
                'Get Unit Folder',
                style: TextStyle(
                  color: Color(0xFFFFFFFF),
                ),
              ),
            ),
            const SizedBox(height: 20),
          InitialParamListWidget(directoryPath: initialParamPath,),
          //   InitialParam(),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                await _productionFunctionKit.runCreatePreUploadLaserBoresightFile(await _productionFunctionKit.searchUserFolders(_controller.text.trim()),updateState);
                // setState(() {}); // Update UI with the new status message
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5B5B5B),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              child: const Text(
                'Upload calibration',
                style: TextStyle(
                  color: Color(0xFFFFFFFF),
                ),
              ),
            ),
            const SizedBox(height: 20),
            FinalParamListWidget(directoryPath: finalParamPath),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                await _productionFunctionKit.getDeviceInfo(updateState);
              },

              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5B5B5B),
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
