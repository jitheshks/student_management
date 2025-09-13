import 'package:flutter/material.dart';

mixin BaseController<T> on ChangeNotifier {
  bool isLoading = false;
  String? errorMessage;
  List<T> items = [];
  List<T> filteredItems = [];
  final Set<String> selectedItems = {};

  List<T> get users => filteredItems;
  Set<String> get selectedUsers => selectedItems;

  void toggleUserSelection(String id) {
    if (selectedItems.contains(id)) {
      selectedItems.remove(id);
    } else {
      selectedItems.add(id);
    }
    notifyListeners();
  }

  void clearSelectedUsers() {
    selectedItems.clear();
    notifyListeners();
  }

  void applySortAndFilter();
  Future<void> fetchUsers();
  Future<void> deleteUser(String id, String authId);
}
