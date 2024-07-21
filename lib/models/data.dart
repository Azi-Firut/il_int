import 'package:flutter/cupertino.dart';

class Data with ChangeNotifier {
  ////////////////////////////////////////////////////////////

  String _textWidget3 = 'TEXT W3';
  String get getTextToWidget3 => _textWidget3; // возврат данных через гетер
  void changeString(String newString) {
    _textWidget3 = newString;
    notifyListeners();
  }

//////////////////////////////////////////////////////////////
  int _screenNumber = 0;
  int get getScreenNumber => _screenNumber; // возврат данных через гетер
  void changeScreenNumber(int screenNum) {
    // проброс данных через функцию
    _screenNumber = screenNum;
    notifyListeners();
  }
/// Atc address
  String _unitAddressForAtc = '';
  String get getUnitAddressForAtc => _unitAddressForAtc; // возврат данных через гетер
  void unitAddressForAtc(String address) {
    _unitAddressForAtc = address;
    notifyListeners();
  }
//////////////////////////////////////////////////////////////
}
