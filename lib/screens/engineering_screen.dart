import 'package:flutter/material.dart';
import 'package:il_int/models/engineering_class.dart';

import '../constant.dart';
import '../models/device_fix_class.dart';
import '../models/production_class.dart';
import '../widgets/answer_from_unit.dart';

class EngineeringScreen extends StatefulWidget {
  const EngineeringScreen({Key? key}) : super(key: key);

  @override
  EngineeringScreenState createState() => EngineeringScreenState();
}

class EngineeringScreenState extends State<EngineeringScreen> {
  final DeviceFix _deviceFixFunctionKit = DeviceFix();
  final Engineering _engineeringKit = Engineering();
  final Production _productionFunctionKit = Production();

  @override
  void initState() {
    super.initState();
    // _deviceFixFunctionKit.init();
    _deviceFixFunctionKit.checkCalibrationFile(updateState);
  }

  void updateState() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ElevatedButton(
        //   onPressed: _sendCommand,
        //   child: Text('Send Command'),
        // ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Flexible(
                fit: FlexFit.loose,
                child: Text(
                  "Turn on the device and connect to it using Wi-Fi. Make sure the connection is established.",
                  style: TextStyle(
                    color: textColorGray,
                  ),
                ),
              ),
            ],
          ),
        ),

        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Flexible(
                fit: FlexFit.loose,
                child: Text(
                  "To change the device brand, select the brand from the list and click Change Brand.",
                  style: TextStyle(
                    color: textColorGray,
                  ),
                ),
              ),
            ],
          ),
        ),
        Container(
          width: 155,
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
          decoration: BoxDecoration(
            color: Colors.orange,
            borderRadius: BorderRadius.circular(3.0),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                spreadRadius: 1,
                blurRadius: 5,
                offset: Offset(0, 3), // changes position of shadow
              ),
            ],
          ),
          child: DropdownButton<String?>(
            dropdownColor: Colors.orange,
            value: _deviceFixFunctionKit.selectedBrand,
            hint: const Text(
              'Select Brand',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14.0,
              ),
            ),
            icon: Icon(Icons.arrow_drop_down, color: Colors.white),
            iconSize: 24,
            isExpanded: true,
            underline: SizedBox(),
            onChanged: (String? newValue) {
              setState(() {
                _deviceFixFunctionKit.selectedBrand = newValue;
              });
            },
            items: _deviceFixFunctionKit.brandsList
                .map<DropdownMenuItem<String?>>((String value) {
              return DropdownMenuItem<String?>(
                value: value,
                child: Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14.0,
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 18.0),
          child: ElevatedButton(
            onPressed: () async {
              await _deviceFixFunctionKit.changeBrand(updateState);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF02567E),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            child: const Text(
              'Change Brand',
              style: TextStyle(
                color: Color(0xFFFFFFFF),
              ),
            ),
          ),
        ),
        Padding(
          padding:
              const EdgeInsets.only(left: 8.0, right: 8, bottom: 16, top: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                fit: FlexFit.loose,
                child: Text(
                  _deviceFixFunctionKit.outputBrand,
                  style: TextStyle(
                    color: textColorGray,
                  ),
                ),
              ),
            ],
          ),
        ),
///////////////////////////////////////////////////
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Flexible(
                fit: FlexFit.loose,
                child: Text(
                  "To change the device scanner, select the brand from the list and click Change",
                  style: TextStyle(
                    color: textColorGray,
                  ),
                ),
              ),
            ],
          ),
        ),
        Container(
          width: 155,
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
          decoration: BoxDecoration(
            color: Colors.orange,
            borderRadius: BorderRadius.circular(3.0),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                spreadRadius: 1,
                blurRadius: 5,
                offset: Offset(0, 3), // changes position of shadow
              ),
            ],
          ),
          child: DropdownButton<String?>(
            dropdownColor: Colors.orange,
            value: _engineeringKit.selectedScanner,
            hint: const Text(
              'Select Scanner',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14.0,
              ),
            ),
            icon: Icon(Icons.arrow_drop_down, color: Colors.white),
            iconSize: 24,
            isExpanded: true,
            underline: SizedBox(),
            onChanged: (String? newValue) {
              setState(() {
                _engineeringKit.selectedScanner = newValue;
              });
            },
            items: _engineeringKit.scannerList
                .map<DropdownMenuItem<String?>>((String value) {
              return DropdownMenuItem<String?>(
                value: value,
                child: Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14.0,
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 18.0),
          child: ElevatedButton(
            onPressed: () async {
              await _engineeringKit.changeScanner(updateState);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF02567E),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            child: const Text(
              'Change Scanner',
              style: TextStyle(
                color: Color(0xFFFFFFFF),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 18.0),
          child: ElevatedButton(
            onPressed: () async {
              await _engineeringKit.changeReceiver(updateState);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF02567E),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            child: const Text(
              'Receiver to novatel',
              style: TextStyle(
                color: Color(0xFFFFFFFF),
              ),
            ),
          ),
        ),

        ///////////////////////////////////////////////////////////////////////
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Flexible(
                fit: FlexFit.loose,
                child: Text(
                  "To delete or restore the calibration file on the device, use the buttons below.",
                  style: TextStyle(
                    color: textColorGray,
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: ElevatedButton(
            onPressed: () async {
              await _deviceFixFunctionKit.deleteCalibration(updateState);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF02567E),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            child: const Text(
              'Delete Calibration',
              style: TextStyle(
                color: Color(0xFFFFFFFF),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 18.0),
          child: ElevatedButton(
            onPressed: () async {
              await _deviceFixFunctionKit.restoreCalibration(updateState);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF02567E),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            child: const Text(
              'Restore Calibration',
              style: TextStyle(
                color: Color(0xFFFFFFFF),
              ),
            ),
          ),
        ),

        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: () async {
            await _productionFunctionKit.getDeviceInfo(updateState);
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
        const SizedBox(height: 20),
        UnitResponse(),


        // Padding(
        //   padding: const EdgeInsets.all(8.0),
        //   child: Text(
        //     _output2,
        //     style: TextStyle(
        //       color: textColorGray,
        //     ),
        //   ),
        // ),
      ],
    );
  }
}
