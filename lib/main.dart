import 'dart:async';

import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:il_int/screens/screen_switcher.dart';
import 'package:il_int/widgets/menu_button.dart';
import 'package:provider/provider.dart';

import 'models/data.dart';

void main() {
  appWindow.size = const Size(600, 800);
  runApp(IlintGui());
  appWindow.hide();
  doWhenWindowReady(() {
    final win = appWindow;
    const initialSize = Size(600, 800);
    win.minSize = initialSize;
    win.size = initialSize;
    win.alignment = Alignment.topRight;
    win.title = "iL internal";
    win.show();
  });
}

const borderColor = Color(0x1800A4FC);

class IlintGui extends StatelessWidget {
  IlintGui({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<Data>(
      create: (context) => Data(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: WindowBorder(
            color: borderColor,
            width: 0,
            child: const Row(
              children: [LeftSide(), RightSide()],
            ),
          ),
        ),
      ),
    );
  }
}

const sidebarColor = Color(0xFF282A2C);

class LeftSide extends StatefulWidget {
  const LeftSide({Key? key}) : super(key: key);

  @override
  _LeftSideState createState() => _LeftSideState();
}

class _LeftSideState extends State<LeftSide> {
  bool showButtons = true;

  @override
  void initState() {
    super.initState();
    _checkPermission();
  }

  Future<void> _checkPermission() async {
    try {
      final response = await http.get(Uri.parse(
          'https://raw.githubusercontent.com/Azi-Firut/il_int/master/perm'));
      if (response.statusCode == 200) {
        final body = response.body.trim();
        if (body == 'no') {
          setState(() {
            showButtons = false;
          });
        }
        if (body == 'yes') {
          setState(() {
            showButtons = true;
          });
        }
        ;
      }
    } catch (e) {
      // Если возникла ошибка (например, нет доступа к URL), ничего не делаем и оставляем showButtons = true
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      child: Container(
        color: sidebarColor,
        child: Column(
          children: [
            Container(
              color: const Color(0xFF1F1F1F),
              height: 31,
              child: const Center(
                child: Text(
                  "Inertial Labs internal",
                  style: TextStyle(
                    color: Color(0xFF777777),
                  ),
                ),
              ),
            ),
            if (showButtons) ...[
              const CustomTextButton(
                icon: Icons.wifi_find_rounded,
                text: "Scan wi-fi",
                onPress: 1,
              ),
              Container(
                height: 1,
                width: double.infinity,
                color: const Color(0x1800A4FC),
              ),
              const CustomTextButton(
                icon: Icons.call_merge_rounded,
                text: "Merge file",
                onPress: 2,
              ),
              Container(
                height: 1,
                width: double.infinity,
                color: const Color(0x1500A4FC),
              ),
              const CustomTextButton(
                icon: Icons.bug_report_outlined,
                text: "Device fix",
                onPress: 3,
              ),
              Container(
                height: 1,
                width: double.infinity,
                color: const Color(0x1500A4FC),
              ),
              const CustomTextButton(
                icon: Icons.developer_board,
                text: "Production",
                onPress: 4,
              ),
              Container(
                height: 1,
                width: double.infinity,
                color: const Color(0x1500A4FC),
              ),
              const CustomTextButton(
                icon: Icons.handyman_rounded,
                text: "Engineering",
                onPress: 5,
              ),
              Container(
                height: 1,
                width: double.infinity,
                color: const Color(0x1500A4FC),
              ),
              const CustomTextButton(
                icon: Icons.tips_and_updates_outlined,
                text: "Test",
                onPress: 99,
              ),
              // Container(
              //   height: 1,
              //   width: double.infinity,
              //   color: const Color(0x1500A4FC),
              // ),
              // const CustomTextButton(
              //   icon: Icons.account_tree_rounded,
              //   text: "Test open folder",
              //   onPress: 5,
              // ),
              Container(
                height: 1,
                width: double.infinity,
                color: const Color(0x1500A4FC),
              ),
            ],
            WindowTitleBarBox(child: MoveWindow()),
            Expanded(child: Container())
          ],
        ),
      ),
    );
  }
}

const backgroundStartColor = Color(0xFF1F1F1F);
const backgroundStartColor2 = Color(0xFF232323);
const backgroundEndColor = Color(0xFF282A2C);

class RightSide extends StatefulWidget {
  const RightSide({Key? key}) : super(key: key);

  @override
  _RightSideState createState() => _RightSideState();
}

class _RightSideState extends State<RightSide> {
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              backgroundStartColor,
              backgroundStartColor2,
              backgroundEndColor,
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: Column(
          children: [
            WindowTitleBarBox(
              child: Row(
                children: [
                  Expanded(child: MoveWindow()),
                  WindowButtons(),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    ScreenSwitcher(page: context.watch<Data>().getScreenNumber),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

final buttonColors = WindowButtonColors(
  iconNormal: const Color(0xFF777777),
  mouseOver: const Color(0xFF252525),
  mouseDown: const Color(0xFF4F3405),
  iconMouseOver: const Color(0xFFFFFEFE),
  iconMouseDown: const Color(0xFF777777),
);

final closeButtonColors = WindowButtonColors(
  mouseOver: const Color(0xFF252525),
  mouseDown: const Color(0xFFB71C1C),
  iconNormal: const Color(0xFF777777),
  iconMouseOver: Colors.white,
);

class WindowButtons extends StatefulWidget {
  const WindowButtons({super.key});

  @override
  State<WindowButtons> createState() => _WindowButtonsState();
}

class _WindowButtonsState extends State<WindowButtons> {
  void maximizeOrRestore() {
    setState(() {
      appWindow.maximizeOrRestore();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        MinimizeWindowButton(colors: buttonColors),
        appWindow.isMaximized
            ? RestoreWindowButton(
                colors: buttonColors,
                onPressed: maximizeOrRestore,
              )
            : MaximizeWindowButton(
                colors: buttonColors,
                onPressed: maximizeOrRestore,
              ),
        CloseWindowButton(colors: closeButtonColors),
      ],
    );
  }
}
