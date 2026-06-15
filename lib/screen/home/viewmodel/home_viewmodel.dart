import 'package:flutter/material.dart';

class HomeViewModel extends ChangeNotifier {
  DateTime _selectedDate = DateTime.now();
  DateTime get selectedDate => _selectedDate;

  DateTime get today => DateTime.now();

  DateTime get weekStart {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day - (now.weekday - 1));
  }

  DateTime get weekEnd => weekStart.add(const Duration(days: 6));

  DateTime get monthStart =>
      DateTime(_selectedDate.year, _selectedDate.month, 1);
  DateTime get monthEnd =>
      DateTime(_selectedDate.year, _selectedDate.month + 1, 0);

  void changeMonth(int delta) {
    _selectedDate = DateTime(
      _selectedDate.year,
      _selectedDate.month + delta,
      1,
    );
    notifyListeners();
  }

  String getMonthName() {
    return [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ][_selectedDate.month - 1];
  }

  String getFormattedWeekRange() {
    final monthNames = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${weekStart.day} ${monthNames[weekStart.month - 1]} - ${weekEnd.day} ${monthNames[weekEnd.month - 1]}, ${weekStart.year}';
  }
}
