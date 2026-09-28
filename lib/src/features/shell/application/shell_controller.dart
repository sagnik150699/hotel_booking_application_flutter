import 'package:flutter/foundation.dart';

/// Top-level destinations in the app shell.
enum ShellTab {
  explore('Explore'),
  saved('Saved'),
  trips('Trips');

  const ShellTab(this.label);

  final String label;
}

/// Which tab the shell is showing. Kept outside the shell widget so deep
/// flows (e.g. the booking confirmation screen) can jump straight to Trips.
class ShellController extends ChangeNotifier {
  ShellTab _tab = ShellTab.explore;

  ShellTab get tab => _tab;

  int get index => _tab.index;

  void select(ShellTab tab) {
    if (tab == _tab) {
      return;
    }
    _tab = tab;
    notifyListeners();
  }

  void selectIndex(int index) => select(ShellTab.values[index]);
}
