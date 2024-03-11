import 'package:flutter/material.dart';
import 'package:il_int/screens/merge_basefile.dart';

void main() {
  runApp(const Ilint());
}

class Ilint extends StatelessWidget {
  const Ilint({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'il_int',
      // theme: ThemeData(
      //   primarySwatch: Colors.blue,
      // ),
      home: MergeBasefile(),
    );
  }
}
