import 'dart:io';
import 'package:cross_file/cross_file.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:file_selector/file_selector.dart' as file_selector;

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: FilePickerPage(),
    );
  }
}

class FilePickerPage extends StatefulWidget {
  @override
  _FilePickerPageState createState() => _FilePickerPageState();
}

class _FilePickerPageState extends State<FilePickerPage> {
  String? _selectedFilePath;

  Future<void> _pickFile() async {
    final XFile? file = await file_selector.openFile();
    if (file != null) {
      setState(() {
        _selectedFilePath = file.path;
      });
    }
  }

  Future<void> _saveFileAsTxt() async {
    if (_selectedFilePath != null) {
      try {
        final sourceFile = File(_selectedFilePath!);
        final contentBytes = await sourceFile.readAsBytes();
        final destinationFile = File('${sourceFile.path}.txt');
        await destinationFile.writeAsBytes(contentBytes);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('File saved as TXT at ${destinationFile.path}'),
          ),
        );
      } catch (e) {
        print('Error saving file as TXT: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('File Picker'),
      ),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton(
              onPressed: _pickFile,
              child: Text('Pick File'),
            ),
            SizedBox(height: 20),
            if (_selectedFilePath != null) ...[
              Text(
                'Selected File Path:',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 10),
              Text(_selectedFilePath!),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveFileAsTxt,
                child: Text('Save File as TXT'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
