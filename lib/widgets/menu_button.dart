import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../constant.dart';
import '../models/data.dart';

class CustomTextButton extends StatelessWidget {
  final IconData icon;
  final String text;
  final onPress;

  const CustomTextButton({
    Key? key,
    required this.icon,
    required this.text,
    required this.onPress,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextButton(
      style: ButtonStyle(
        maximumSize: MaterialStateProperty.all(const Size(150, 60)),
        minimumSize: MaterialStateProperty.all(const Size(150, 54)),
        overlayColor: MaterialStateProperty.all<Color>(Color(0x1800A4FC)),
        backgroundColor: MaterialStateProperty.all<Color>(Colors.transparent),
        foregroundColor: MaterialStateProperty.all<Color>(Colors.black),
        padding: MaterialStateProperty.all<EdgeInsetsGeometry>(
          const EdgeInsets.only(top: 3, bottom: 3),
        ),
        shape: MaterialStateProperty.all<OutlinedBorder>(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(0),
          ),
        ),
      ),
      onPressed: () {
        context.read<Data>().changeScreenNumber(onPress);
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        //  mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(width: 14),
          Icon(icon, color: Colors.white),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              fontWeight: FontWeight.normal,
              color: textColorGray,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
