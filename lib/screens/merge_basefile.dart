import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cross_file/cross_file.dart';
import 'dart:io';
import 'package:dcat/dcat.dart';
import 'package:desktop_window/desktop_window.dart';
import 'package:il_int/screens/create_folders.dart';
import 'package:il_int/screens/unit_check.dart';
import '../constant.dart';

class MergeBasefile extends StatefulWidget {
  MergeBasefile({Key? key}) : super(key: key);
  @override
  _MergeBasefileState createState() => _MergeBasefileState();
}

class _MergeBasefileState extends State<MergeBasefile> {
  @override
  void initState() {
    DesktopWindow.setWindowSize(const Size(400, 300));
    DesktopWindow.setMinWindowSize(const Size(400, 300));
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          actions: [
            GestureDetector(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (context) => UnitPreShipmentCheck()),
                );
              }, // --------------- Unit check
              child: const Padding(
                padding: EdgeInsets.only(right: 14.0),
                child: Icon(
                  Icons.price_check_outlined,
                  color: Colors.white,
                  size: 40,
                ),
              ),
            ),
            GestureDetector(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => MyApp()),
                );
              }, // --------------- Unit check
              child: const Padding(
                padding: EdgeInsets.only(right: 14.0),
                child: Icon(
                  Icons.folder_open_rounded,
                  color: Colors.white,
                  size: 40,
                ),
              ),
            ),
          ],
          shadowColor: Colors.black,
          elevation: 6,
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topRight, // Start direction
                end: Alignment.bottomRight, // End direction
                colors: [
                  Colors.orange, // Start Color
                  Colors.red, // End Color
                ], // Customize your colors here
              ),
            ),
          ),
          centerTitle: true,
          title: const Text(
            'Merge base station files',
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
        ),
        body: Wrap(
          direction: Axis.vertical,
          runSpacing: 8,
          spacing: 8,
          children: const [
            ExampleDragTarget1(),
          ],
        ),
      ),
    );
  }
}

class ExampleDragTarget1 extends StatefulWidget {
  const ExampleDragTarget1({Key? key}) : super(key: key);

  @override
  _ExampleDragTargetState createState() => _ExampleDragTargetState();
}

class _ExampleDragTargetState extends State<ExampleDragTarget1> {
  bool _dragging = false;
  Offset? offset;
  late XFile firstDrag;
  late XFile secondDrag;
  final List<XFile> listX = [];

  Future<void> merge() async {
    if (listX.length == 2) {
      var slot0 = listX[0].name.split("-");
      slot0.removeLast();
      var slot0Val = int.parse(slot0[slot0.length - 1]);
      //
      var slot1 = listX[1].name.split("-");
      slot1.removeLast();
      var slot1Val = int.parse(slot1[slot1.length - 1]);
      //
      if (slot0Val < slot1Val) {
        firstDrag = listX[0];
        secondDrag = listX[1];
      } else {
        firstDrag = listX[1];
        secondDrag = listX[0];
      }
      //
      print('--------  ${slot0Val}');
      print('--------  ${slot0Val.runtimeType}');
    }

    /// Path splitter
    String outputPath = listX[0].path;
    List<String> putiy = outputPath.split("\\");
    putiy.removeLast();
    putiy.add('basefile');
    var directoryPath = putiy.join("/");

    /// Log
    // print('--------  ${slot0.runtimeType}');
    print('Output directory --------  ${directoryPath}');

    /// Merger
    final result = await cat(
        [firstDrag.path, secondDrag.path], File(directoryPath).openWrite());
    if (result.isFailure) {
      for (final error in result.errors) {
        print('Error: ${error.message}');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    var windowW = MediaQuery.of(context).size.width;
    var windowH = MediaQuery.of(context).size.height;
    return DropTarget(
      onDragDone: (detail) async {
        setState(() {
          listX.addAll(detail.files);
          if (listX.length > 2) {
            listX.clear();
          }
          if (listX.length == 2) {
            merge();
          }
        });

        debugPrint('onDragDone:');
        for (final file in detail.files) {
          debugPrint('${file.name}\n'
              '${file.path}\n'
              '${file.readAsBytes().toString()}\n'
              '${detail.files}\n');
        }
      },
      onDragUpdated: (details) {
        setState(() {
          offset = details.localPosition;
        });
      },
      onDragEntered: (detail) {
        setState(() {
          _dragging = true;
          offset = detail.localPosition;
          if (offset != null && listX.length == 0) {
            dragAndDropMessage = "Drop it";
          } else {
            dragAndDropMessage = "Select two files and drop here";
          }
        });
      },
      onDragExited: (detail) {
        setState(() {
          _dragging = false;
          offset = null;
        });
      },
      child: Container(
        height: windowH,
        width: windowW,
        color: _dragging ? Colors.orange.withOpacity(0.4) : Colors.white,
        child: Stack(
          children: [
            if (listX.isEmpty) Center(child: Text(dragAndDropMessage)),
            if (listX.length == 1)
              Center(
                  child: Text(
                      textAlign: TextAlign.center,
                      "${listX[0].path}\nAnd the second file please")),
            if (listX.length == 2)
              Center(
                  child: Text(
                "${listX.map((e) => e.path).join("\n")}\n\nThese two files are merged\nAll the best to you!",
                textAlign: TextAlign.center,
              )),
          ],
        ),
      ),
    );
  }
}
