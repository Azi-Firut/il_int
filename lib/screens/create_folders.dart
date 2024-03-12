import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Folder Creator',
      home: FolderCreator(),
    );
  }
}

class FolderCreator extends StatefulWidget {
  @override
  _FolderCreatorState createState() => _FolderCreatorState();
}

class _FolderCreatorState extends State<FolderCreator> {
  static const List<String> brands = []; //=============
  final TextEditingController _folderNameController = TextEditingController();
  final TextEditingController _fileNameController = TextEditingController();
  final TextEditingController _pathController = TextEditingController();
  String _folderName = '';
  String _fileName = '';
  String _path = '';
  String _fileContent = '';
  String _brand = '';

  void writeFile() async {
    await File("Readme_$_brand-$_fileName.txt").writeAsString(_fileContent);
    // Save file.
  }

  Future<void> _createFolder() async {
    final Directory documentsDir = await getApplicationDocumentsDirectory();
    final String folderPath =
        '${documentsDir.path}/$_folderName'; //================== Create folder to this path
    final Directory newFolder = Directory(folderPath);
    if (!newFolder.existsSync()) {
      newFolder.createSync(recursive: true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Folder created at: $folderPath'),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Folder already exists.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Create Folder'),
      ),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _folderNameController,
              decoration: InputDecoration(labelText: 'Folder Name'),
              onChanged: (value) {
                setState(() {
                  _folderName = value;
                });
              },
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _folderName.isEmpty ? null : _createFolder,
              child: Text('Create Folder'),
            ),
          ],
        ),
      ),
    );
  }
}
