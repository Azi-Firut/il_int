import 'package:flutter/material.dart';
import '../models/atc_gen_class.dart';
import '../models/folder_operations_class.dart';

class ProdScreen extends StatefulWidget {
  @override
  _ProdScreenState createState() => _ProdScreenState();
}

class _ProdScreenState extends State<ProdScreen> {
  final FolderOpener _folderOpener = FolderOpener();
  final AtcGenerator _genAtc = AtcGenerator();
  final TextEditingController _controller = TextEditingController();


  void updateState() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
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
              await _folderOpener.openFolder(_controller.text.trim());
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

               _genAtc.parseFolder(_folderOpener.searchUserFolders(_controller.text.trim()));
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
              'Initial Parameters',
              style: TextStyle(
                color: Color(0xFFFFFFFF),
              ),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () async {
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
              'Final Parameters',
              style: TextStyle(
                color: Color(0xFFFFFFFF),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            _folderOpener.statusMessage,
            style: const TextStyle(
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}
