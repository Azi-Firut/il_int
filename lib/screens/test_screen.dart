
import 'package:flutter/material.dart';
import 'package:il_int/models/init_calibration_class.dart';
import 'package:process_run/shell.dart';
import '../constant.dart';
import '../models/device_fix_class.dart';
import '../models/production_class.dart';
import '../models/test_class.dart';
import '../widgets/answer_from_unit.dart';

class TestScreen extends StatefulWidget {
  const TestScreen({Key? key}) : super(key: key);
  @override
  TestScreenState createState() => TestScreenState();
}

class TestScreenState extends State<TestScreen> {

  final TestClass _testClassKit = TestClass();

  @override
  void initState() {
    super.initState();
  }

  void updateState() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                await _testClassKit.runGetUnitImu(updateState);
              },

              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFAF7907),
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
            /// OPERATION TEXT
            const SizedBox(height: 20),
            UnitResponse(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
