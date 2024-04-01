import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cross_file/cross_file.dart';
import 'dart:io';
import 'package:dcat/dcat.dart';
import '../constant.dart';

class MergeBaseFiles extends StatefulWidget {
  const MergeBaseFiles({Key? key}) : super(key: key);

  @override
  _MergeBaseFilesState createState() => _MergeBaseFilesState();
}

class _MergeBaseFilesState extends State<MergeBaseFiles> {
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
        height: MediaQuery.of(context).size.height - 32,
        //  width: windowW,
        color: _dragging ? Color(0xF00A4FC) : Colors.transparent,
        child: Stack(
          children: [
            if (listX.isEmpty)
              Center(
                child: Text(
                  dragAndDropMessage,
                  style: const TextStyle(
                    color: Color(0xFF777777),
                  ),
                ),
              ),
            if (listX.length == 1)
              Center(
                child: Text(
                  textAlign: TextAlign.center,
                  "${listX[0].path}\nAnd the second file please",
                  style: const TextStyle(
                    color: Color(0xFF777777),
                  ),
                ),
              ),
            if (listX.length == 2)
              Center(
                child: Text(
                  "${listX.map((e) => e.path).join("\n")}\n\nThese two files are merged\nAll the best to you!",
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF777777),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
