import 'package:flutter/foundation.dart';
import '../models/checklist_item_model.dart';

class ChecklistController extends ChangeNotifier {
  List<ChecklistItemModel> _items = [];
  bool _isCompleted = false;

  List<ChecklistItemModel> get items => _items;
  bool get isCompleted => _isCompleted;
  int get completedCount => _items.where((item) => item.isCompleted).length;
  int get totalCount => _items.length;
  double get progress => totalCount == 0 ? 0 : completedCount / totalCount;

  void loadChecklist() {
    _items = [
      ChecklistItemModel(
        id: '1',
        title: 'Exterior Condition',
        description: 'Check for visible damage, tire condition',
      ),
      ChecklistItemModel(
        id: '2',
        title: 'Lights & Indicators',
        description: 'Headlights, tail lights, indicators working',
      ),
      ChecklistItemModel(
        id: '3',
        title: 'Mirrors & Wipers',
        description: 'All mirrors clean and adjusted, wipers functional',
      ),
      ChecklistItemModel(
        id: '4',
        title: 'Fuel / Charge Level',
        description: 'Sufficient fuel or battery for assigned route',
      ),
      ChecklistItemModel(
        id: '5',
        title: 'Seatbelt & Cabin',
        description: 'Seatbelt functional, cabin clean and secure',
      ),
      ChecklistItemModel(
        id: '6',
        title: 'Dashboard Warnings',
        description: 'No critical warning lights on dashboard',
      ),
    ];
    _isCompleted = false;
    notifyListeners();
  }

  void toggleItem(String id) {
    _items = _items.map((item) {
      if (item.id == id) {
        return item.copyWith(isCompleted: !item.isCompleted);
      }
      return item;
    }).toList();

    _isCompleted = _items.every((item) => item.isCompleted);
    notifyListeners();
  }

  void reset() {
    _items = [];
    _isCompleted = false;
    notifyListeners();
  }
}
