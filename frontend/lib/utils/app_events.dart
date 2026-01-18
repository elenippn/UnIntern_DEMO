import 'package:flutter/foundation.dart';

class AppEvents extends ChangeNotifier {
  int applicationsRevision = 0;

  void applicationsChanged() {
    applicationsRevision++;
    notifyListeners();
  }
}
