import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:il_int/screens/merge_screen.dart';

import 'wifi_screen.dart';
import 'intro_screen.dart';

class ScreenSwitcher extends StatefulWidget {
  final int page;

  const ScreenSwitcher({Key? key, required this.page}) : super(key: key);

  @override
  _ScreenSwitcherState createState() => _ScreenSwitcherState();
}

class _ScreenSwitcherState extends State<ScreenSwitcher> {
  Widget screenSwitcher() {
    print("ScreenSwitcher number of page = ${widget.page}");
    if (widget.page == 0) {
      return Intro();
    } else if (widget.page == 1) {
      return WiFiadd();
    } else if (widget.page == 2) {
      return MergeBaseFiles();
    } else if (widget.page == 3) {
      return MergeBaseFiles();
    } else {
      // Return some default widget if page number is not recognized
      return Container();
    }
  }

  @override
  Widget build(BuildContext context) {
    return screenSwitcher();
  }
}