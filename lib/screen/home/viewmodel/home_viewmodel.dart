import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:walleta/screen/text_transaction/viewmodel/get_transaction_view_model.dart';
import 'package:walleta/services/transaction_service.dart';

class HomeViewModel extends ChangeNotifier {
  DateTime _selectedDate = DateTime.now();
  DateTime get selectedDate => _selectedDate;

  // For daily view
  DateTime get today => DateTime.now();

  // For weekly view
  DateTime get weekStart {
    final now = DateTime.now();
    // Start from Monday
    return DateTime(now.year, now.month, now.day - (now.weekday - 1));
  }

  DateTime get weekEnd => weekStart.add(const Duration(days: 6));

  // For monthly view
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

  // Daily calculations
  double getDailyExpense(BuildContext context) {
    final service = Provider.of<TransactionService>(context, listen: false);
    return service.getTotalExpenseForDateRange(today, today);
  }

  double getDailyIncome(BuildContext context) {
    final service = Provider.of<TransactionService>(context, listen: false);
    return service.getTotalIncomeForDateRange(today, today);
  }

  List<TransactionModel> getDailyTransactions(BuildContext context) {
    final service = Provider.of<TransactionService>(context, listen: false);
    return service.getTransactionsForDay(today);
  }

  // Weekly calculations
  double getWeeklyExpense(BuildContext context) {
    final service = Provider.of<TransactionService>(context, listen: false);
    return service.getTotalExpenseForDateRange(weekStart, weekEnd);
  }

  double getWeeklyIncome(BuildContext context) {
    final service = Provider.of<TransactionService>(context, listen: false);
    return service.getTotalIncomeForDateRange(weekStart, weekEnd);
  }

  List<TransactionModel> getWeeklyTransactions(BuildContext context) {
    final service = Provider.of<TransactionService>(context, listen: false);
    return service.getTransactionsForDateRange(weekStart, weekEnd);
  }

  Map<String, double> getWeeklyChartData(BuildContext context) {
    final service = Provider.of<TransactionService>(context, listen: false);
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final data = <String, double>{};

    for (int i = 0; i < 7; i++) {
      final day = weekStart.add(Duration(days: i));
      double dayExpense = service
          .getTransactionsForDay(day)
          .where((tx) => tx.isIncome == false)
          .fold(0.0, (sum, tx) => sum + (tx.amount ?? 0));

      data[days[i]] = dayExpense;
    }

    return data;
  }

  // Monthly calculations
  double getMonthlyExpense(BuildContext context) {
    final service = Provider.of<TransactionService>(context, listen: false);
    return service.getTotalExpenseForDateRange(monthStart, monthEnd);
  }

  double getMonthlyIncome(BuildContext context) {
    final service = Provider.of<TransactionService>(context, listen: false);
    return service.getTotalIncomeForDateRange(monthStart, monthEnd);
  }

  List<TransactionModel> getMonthlyTransactions(BuildContext context) {
    final service = Provider.of<TransactionService>(context, listen: false);
    return service.getTransactionsForDateRange(monthStart, monthEnd);
  }

  Map<String, double> getMonthlyChartData(BuildContext context) {
    final service = Provider.of<TransactionService>(context, listen: false);
    final weeks = <String, double>{};

    // Group by week
    DateTime currentWeekStart = monthStart;
    int weekNumber = 1;

    while (currentWeekStart.month == monthStart.month) {
      DateTime weekEndDate = currentWeekStart.add(const Duration(days: 6));
      if (weekEndDate.month != monthStart.month) {
        weekEndDate = monthEnd;
      }

      double weekExpense = service.getTotalExpenseForDateRange(
        currentWeekStart,
        weekEndDate,
      );
      weeks['Week $weekNumber'] = weekExpense;

      currentWeekStart = currentWeekStart.add(const Duration(days: 7));
      weekNumber++;
    }

    return weeks;
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
