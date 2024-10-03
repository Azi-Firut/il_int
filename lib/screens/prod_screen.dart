import 'package:flutter/material.dart';
import 'package:il_int/models/device_fix_class.dart';
import 'package:il_int/models/final_calibration_class.dart';
import '../constant.dart';
import '../models/init_calibration_class.dart';
import '../models/production_class.dart';


class ProdScreen extends StatefulWidget {
  @override
  _ProdScreenState createState() => _ProdScreenState();
}

class _ProdScreenState extends State<ProdScreen> {
  final Production _productionFunctionKit = Production();
  final TextEditingController _controller = TextEditingController();
  final DeviceFix _deviceFixFunctionKit = DeviceFix();

///
  void updateState() {
    setState(() {});
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
              onPressed: () async {

                _productionFunctionKit.parseFolder(_productionFunctionKit.searchUserFolders(_controller.text.trim()),updateState);
                // await _folderOpener.openFolder(_controller.text.trim());
                // setState(() {}); // Update UI with the new status message
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF02567E),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              child: const Text(
                'Create ATC',
                style: TextStyle(
                  color: Color(0xFFFFFFFF),
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                _productionFunctionKit.formatUsb(updateState);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFC22B00),
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
            const SizedBox(height: 20),
            InitialParamListWidget(directoryPath: initialParamPath,updateState: updateState),
            // ElevatedButton(
            //   onPressed: () async {
            //     // await _folderOpener.openFolder(_controller.text.trim());
            //     // setState(() {}); // Update UI with the new status message
            //   },
            //   style: ElevatedButton.styleFrom(
            //     backgroundColor: const Color(0xFF02567E),
            //     shape: RoundedRectangleBorder(
            //       borderRadius: BorderRadius.circular(3),
            //     ),
            //   ),
            //   child: const Text(
            //     'Initial Parameters',
            //     style: TextStyle(
            //       color: Color(0xFFFFFFFF),
            //     ),
            //   ),
            // ),
            //const SizedBox(height: 20),
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
            FinalParamListWidget(directoryPath: finalParamPath, updateState: updateState),
            // ElevatedButton(
            //   onPressed: () async {
            //     // await _folderOpener.openFolder(_controller.text.trim());
            //     // setState(() {}); // Update UI with the new status message
            //   },
            //   style: ElevatedButton.styleFrom(
            //     backgroundColor: const Color(0xFF02567E),
            //     shape: RoundedRectangleBorder(
            //       borderRadius: BorderRadius.circular(3),
            //     ),
            //   ),
            //   child: const Text(
            //     'Final Parameters',
            //     style: TextStyle(
            //       color: Color(0xFFFFFFFF),
            //     ),
            //   ),
            // ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                await _productionFunctionKit.runGetUnitImu(updateState);
                updateState();
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
            ///

            ///
            const SizedBox(height: 20),
            SelectableText(
              _productionFunctionKit.statusOutput,
              style: const TextStyle(
                color: Colors.grey,
              ),
            ),
            Text(
              _deviceFixFunctionKit.statusOutput,
              style: const TextStyle(
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
