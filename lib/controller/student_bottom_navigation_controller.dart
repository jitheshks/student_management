// lib/controller/bottom_navigation_controler.dart
import 'package:flutter/foundation.dart';

class StudentBottomNavController extends ChangeNotifier {
int _currentIndex = 0;
int get currentIndex => _currentIndex;

void setIndex(int index) {
if (index == _currentIndex) return;
_currentIndex = index;
notifyListeners();
}

// Optional: programmatic tab switching helpers
void toProfile() => setIndex(0);
void toLibrary() => setIndex(1);
void toFees() => setIndex(2);
}