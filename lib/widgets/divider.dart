import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../constant.dart';
import '../models/data.dart';

class DividerString extends StatelessWidget {
  final String text;

  const DividerString({
    Key? key,
    required this.text,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return  Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(crossAxisAlignment:CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(child: Container(height: 1,color: Colors.white12,)),
          Text("   $text   ",style: TextStyle(
            fontWeight: FontWeight.normal,
            color: Colors.white30,
            fontSize: 14,
            ),
          ),
          Expanded(child: Container(height: 1,color: Colors.white12,))
        ],
      ),
    );
  }
}
