import 'package:flutter/material.dart';
import 'package:il_int/screens/prod_screen.dart';
import '../constant.dart';
import 'package:il_int/models/data.dart';
import 'package:provider/provider.dart';


pushUnitResponse(int step,String text,updateState){
  unitResponse['step']= step;
  print('pushUnitResponse ${unitResponse['step']}');
  unitResponse['text']= text;
  print('pushUnitResponse ${unitResponse['text']}');
updateState();
}

class UnitResponse extends StatefulWidget {
  const UnitResponse({super.key});

  @override
  _UnitResponseState createState() => _UnitResponseState();
}

class _UnitResponseState extends State<UnitResponse> {
  void updateState() {
    setState(() {});
  }

  Widget step (){
    Widget icoReturn;
    if (unitResponse['step']==0){
      icoReturn = const Icon(
        Icons.access_time,
        color: Color(0xFF868585),
        size: 22,
      );
      //updateState();
    } else if (unitResponse['step']==1){
      icoReturn = const Icon(
        Icons.blur_circular_outlined,
        color: Color(0xFF80E053),
        size: 22,
      );
      //updateState();
    } else if (unitResponse['step']==2){
      icoReturn = const Icon(
        Icons.error_outline_outlined,
        color: Color(0xFFD90B25),
        size: 22,
      );
      //updateState();
    } else if (unitResponse['step']==3){
      icoReturn = const Icon(
        Icons.error_outline_outlined,
        color: Color(0xFF0BA2D9),
        size: 22,
      );
      //updateState();
    }else {
      icoReturn = const SizedBox.shrink();
    }
  // updateState();
    return icoReturn;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Row( crossAxisAlignment: CrossAxisAlignment.start,
       children: [
               Padding(
           padding: const EdgeInsets.only(right: 12.0,left: 12,top: 0),
           child: step(),
         ),
         unitResponse['text'] != null && unitResponse['text']!.isNotEmpty
             ? Flexible(
               child: SelectableText(
                          unitResponse['text']!,
                          style: const TextStyle(
               color: Colors.grey,
                          ),
                          maxLines: null,
                        ),
             )
             : const SizedBox.shrink(),
        ],
      ),
    );
  }
}
