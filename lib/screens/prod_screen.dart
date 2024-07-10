import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:process_run/shell.dart';

import '../constant.dart';

class FolderOpener extends StatefulWidget {
  @override
  _FolderOpenerState createState() => _FolderOpenerState();
}

class _FolderOpenerState extends State<FolderOpener> {
  TextEditingController _controller = TextEditingController();
  String _statusMessage = '';

  Future<String?> _searchFolder(Directory dir, String folderName) async {
    try {
      await for (var entity in dir.list(recursive: true, followLinks: false)) {
        if (entity is Directory &&
            p.basename(entity.path).toLowerCase() == folderName.toLowerCase()) {
          return entity.path;
        }
      }
    } on FileSystemException catch (e) {
      print("Error during directory search: ${e.message}");
    } catch (e) {
      print("An error occurred: $e");
    }
    return null;
  }

  Future<String?> _searchUserFolders(String folderName) async {
    List<Directory> searchDirs = [
      Directory('C:\\Users\\${Platform.environment['USERNAME']}\\Desktop'),
      Directory('C:\\Users\\${Platform.environment['USERNAME']}\\Documents'),
      Directory('C:\\Users\\${Platform.environment['USERNAME']}\\Downloads'),
    ];

    for (Directory dir in searchDirs) {
      String? folderPath = await _searchFolder(dir, folderName);
      if (folderPath != null) {
        return folderPath;
      }
    }
    return null;
  }

  void _openFolder() async {
    String folderName = _controller.text.trim();
    if (folderName.isEmpty) {
      setState(() {
        _statusMessage = 'Please enter a folder name.';
      });
      return;
    }

    setState(() {
      _statusMessage = 'Searching for the folder...';
    });

    String? folderPath = await _searchUserFolders(folderName);
    if (folderPath == null) {
      folderPath = await _searchFolder(Directory('C:\\'), folderName);
    }

    if (folderPath != null) {
      var shell = Shell();
      try {
        await shell.run('explorer "${p.normalize(folderPath)}"');
        setState(() {
          _statusMessage = 'Folder opened successfully.';
        });
      } catch (e) {
        setState(() {
          _statusMessage = 'Error opening the folder: $e';
        });
      }
    } else {
      setState(() {
        _statusMessage = 'Folder not found.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          TextField(
            style: TextStyle(
              color: textColorGray,
            ),
            textCapitalization: TextCapitalization.characters,
            controller: _controller,
            decoration: InputDecoration(
              hintText: 'Enter Unit Serial Number',
              hintStyle: TextStyle(color: Colors.grey),
            ),
          ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: _openFolder,
            child: Text('Search Unit Folder'),
          ),
          SizedBox(height: 20),
          Text(_statusMessage),
        ],
      ),
    );
  }
}
