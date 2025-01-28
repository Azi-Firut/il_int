import 'package:flutter/material.dart';
import 'package:il_int/models/device_fix_class.dart';
import 'package:il_int/models/final_calibration_class.dart';
import 'package:il_int/models/usb_check.dart';
import 'package:il_int/widgets/answer_from_unit.dart';
import 'package:provider/provider.dart';
import '../constant.dart';
import '../models/create_readme_class.dart';
import '../models/data.dart';
import '../models/init_calibration_class.dart';
import '../models/production_class.dart';


class ProdScreen extends StatefulWidget {
  const ProdScreen({super.key});

  @override
  ProdScreenState createState() => ProdScreenState();
}

class ProdScreenState extends State<ProdScreen> {
 //var usbColChanger ;

  final Production _productionFunctionKit = Production();
  final TextEditingController _controller = TextEditingController();
  final DeviceFix _deviceFixFunctionKit = DeviceFix();
  final ReadMeClass _readMeClassKit = ReadMeClass();

  bool _isSelectedCreateZip = false;
  var statusOutput= "";
///
  ///

  ///
  void updateState() {
    setState(() {
      usbColor();
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
                backgroundColor: const Color(0xFF02567E),
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
            ElevatedButton(
              onPressed: () async {
                await _productionFunctionKit.addCustomSSiD(_controller.text.trim(),updateState);
                // setState(() {}); // Update UI with the new status message
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFAF7907),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              child: const Text(
                'Add custom SSiD',
                style: TextStyle(
                  color: Color(0xFFFFFFFF),
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.only(left: 25,right: 5),
                backgroundColor: const Color(0xFF02567E),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              onPressed: () {
                _productionFunctionKit.generateAtc(_productionFunctionKit.searchUserFolders(_controller.text.trim()),updateState);
                zip=_isSelectedCreateZip;
                // Оставляем пустым для переключения только на чекбоксе
              },
              child: Container(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Center(
                      child: Text('Create ATC and Boresight.zip',
                        style: TextStyle(
                          color: Color(0xFFFFFFFF),
                        ),),
                    ),
                    const SizedBox(width: 10),
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Checkbox(
                          value: _isSelectedCreateZip,
                          shape: CircleBorder(),
                          side: BorderSide(
                            color: _isSelectedCreateZip ? Colors.transparent : Colors.grey,
                            width: 2,
                          ),
                          activeColor: Colors.transparent, // Убираем стандартную заливку
                          checkColor: Colors.transparent, // Убираем стандартную галочку
                          onChanged: (value) {
                            setState(() {
                              _isSelectedCreateZip = value ?? false;
                            });
                          },
                        ),
                        if (_isSelectedCreateZip)
                          Container(
                            width: 15, // Размер цветного круга
                            height: 15,
                            decoration: BoxDecoration(
                              color: Colors.white, // Цвет заполненного круга
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () async {
                    _productionFunctionKit.formatUsb(updateState);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: usbColChanger,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  child: const Text(
                    'Format USB',
                    style: TextStyle(
                      color: Color(0xFFFFFFFF),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 16.0),
                  child: ElevatedButton(
                    onPressed: () async {
                      await _productionFunctionKit.sendRecCommand(_controller.text,updateState);
                      _controller.text="";
                    },

                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF532F98),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    child: const Text(
                      'Upload GNSS code',
                      style: TextStyle(
                        color: Color(0xFFFFFFFF),
                      ),
                    ),
                  ),
                ),

              ],

            ),
            const SizedBox(height: 20),
            InitialParamListWidget(directoryPath: initialParamPath,recolState: updateState),
           // FinalParamListWidget(directoryPath: finalParamPath,recolState: updateState),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                await _productionFunctionKit.runCreatePreUploadLaserBoresightFile(await _productionFunctionKit.searchUserFolders(_controller.text.trim()),updateState);
                // setState(() {}); // Update UI with the new status message
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3F941B),
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
           FinalParamListWidget(directoryPath: finalParamPath,recolState: updateState),
           const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                await _productionFunctionKit.uploadAtcToUnit(_controller.text.trim(), updateState);
              },

              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F6E77),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              child: const Text(
                'Upload ATC to Unit',
                style: TextStyle(
                  color: Color(0xFFFFFFFF),
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
            /// Rec
            // ElevatedButton(
            //   onPressed: () async {
            //     await _productionFunctionKit.sendRecCommand(_controller.text,updateState);
            //   },
            //
            //   style: ElevatedButton.styleFrom(
            //     backgroundColor: const Color(0xFF532F98),
            //     shape: RoundedRectangleBorder(
            //       borderRadius: BorderRadius.circular(3),
            //     ),
            //   ),
            //   child: const Text(
            //     'Upload GNSS code',
            //     style: TextStyle(
            //       color: Color(0xFFFFFFFF),
            //     ),
            //   ),
            // ),
            //const SizedBox(height: 20),
            /// OPERATION TEXT
            UnitResponse(),
            const SizedBox(height: 20),
            if (output["IMU SN: "] != null && RegExp(r'\d').hasMatch(output["IMU SN: "]!))
              ElevatedButton(
                onPressed: () async {
                  await _readMeClassKit.createFoldersAndFile(updateState);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3F941B),
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
