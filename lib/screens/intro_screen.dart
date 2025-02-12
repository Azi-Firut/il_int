import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import '../constant.dart';
import '../models/data.dart';

class Intro extends StatelessWidget {
  const Intro({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      child: Padding(
        padding: EdgeInsets.all(14),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.only(right: 12.0),
                  child: Icon(
                    Icons.wifi_find_rounded,
                    color: textColorGray,
                    size: 18,
                  ),
                ),
                Flexible(
                  fit: FlexFit.loose,
                  child: Text(
                    "If the unit is turned on, it is added to the list of trusted Wi-Fi networks and the password is automatically entered (the scan lasts 10 seconds).",
                    style: TextStyle(
                      color: textColorGray,
                    ),
                  ),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.only(right: 12.0),
                  child: Icon(
                    Icons.call_merge_rounded,
                    color: textColorGray,
                    size: 18,
                  ),
                ),
                Flexible(
                  fit: FlexFit.loose,
                  child: Text(
                    "Combines two base files into one (supported format is - *.bin).",
                    style: TextStyle(
                      color: textColorGray,
                    ),
                  ),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.only(right: 12.0),
                  child: Icon(
                    Icons.bug_report_outlined,
                    color: textColorGray,
                    size: 18,
                  ),
                ),
                Flexible(
                  fit: FlexFit.loose,
                  child: Text(
                    "Tools for changing the brand and restoring a deleted calibration file (use if the device writes data to folders with an incorrect name).",
                    style: TextStyle(
                      color: textColorGray,
                    ),
                  ),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.only(right: 12.0),
                  child: Icon(
                    Icons.developer_board,
                    color: textColorGray,
                    size: 18,
                  ),
                ),
                Flexible(
                  fit: FlexFit.loose,
                  child: Text(
                    "Tools for production department (chain of procedure before unit will be shipped).",
                    style: TextStyle(
                      color: textColorGray,
                    ),
                  ),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.only(right: 12.0),
                  child: Icon(
                    Icons.handyman_rounded,
                    color: textColorGray,
                    size: 18,
                  ),
                ),
                Flexible(
                  fit: FlexFit.loose,
                  child: Text(
                    "Programmatic installation of unit components.",
                    style: TextStyle(
                      color: textColorGray,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
