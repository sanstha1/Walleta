// ignore_for_file: invalid_use_of_visible_for_testing_member

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:walleta/screen/home/viewmodel/home_viewmodel.dart';
import 'package:walleta/services/currency_service.dart';
import 'package:walleta/services/transaction_service.dart';
import 'package:walleta/theme/app_colors.dart';

class DailyView extends StatelessWidget {
  const DailyView({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final currency = context.watch<CurrencyProvider>().symbol;
    final homeViewModel = Provider.of<HomeViewModel>(context);
    final transactionService = Provider.of<TransactionService>(context);

    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);
    final todayEnd = todayStart.add(const Duration(days: 1));

    final dailyTransactions = transactionService.transactions.where((tx) {
      if (tx.createdAt == null) return false;
      return tx.createdAt!.isAfter(todayStart) &&
          tx.createdAt!.isBefore(todayEnd);
    }).toList();

    final dailyExpense = dailyTransactions
        .where((tx) => tx.isIncome == false || tx.isIncome == null)
        .fold(0.0, (sum, tx) => sum + (tx.amount ?? 0));

    final dailyIncome = dailyTransactions
        .where((tx) => tx.isIncome == true)
        .fold(0.0, (sum, tx) => sum + (tx.amount ?? 0));

    final balance = dailyIncome - dailyExpense;
    final isPositive = balance >= 0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colors.containerBG,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Expense",
                          style: TextStyle(
                            fontSize: 14,
                            color: colors.disabledText,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "-$currency${dailyExpense.toStringAsFixed(2)}",
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colors.containerBG,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Income",
                          style: TextStyle(
                            fontSize: 14,
                            color: colors.disabledText,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "+$currency${dailyIncome.toStringAsFixed(2)}",
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            Text(
              DateFormat('EEEE, MMMM d').format(DateTime.now()),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: colors.primaryText,
              ),
            ),

            const SizedBox(height: 16),

            if (transactionService.isLoading)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: CircularProgressIndicator(color: colors.primary),
                ),
              )
            else if (dailyTransactions.isEmpty)
              Container(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    Icon(
                      Icons.receipt_long,
                      size: 60,
                      color: colors.disabledText,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "No transactions today",
                      style: TextStyle(
                        fontSize: 16,
                        color: colors.disabledText,
                      ),
                    ),
                  ],
                ),
              )
            else
              Column(
                children: dailyTransactions.map((tx) {
                  final isIncome = tx.isIncome ?? false;
                  final iconColor = isIncome ? Colors.green : Colors.red;
                  final time = tx.createdAt != null
                      ? DateFormat('h:mm a').format(tx.createdAt!)
                      : '';

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colors.containerBG,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            // ignore: deprecated_member_use
                            color: iconColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            isIncome
                                ? Icons.arrow_downward
                                : Icons.arrow_upward,
                            color: iconColor,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                tx.title ?? 'No Title',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: colors.primaryText,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${tx.category ?? 'No Category'} • $time',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: colors.disabledText,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          "${isIncome ? '+' : '-'}$currency${tx.amount?.toStringAsFixed(2) ?? '0.00'}",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: iconColor,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),

            if (!transactionService.isLoading)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Center(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      transactionService.fetchTransactions();
                      // ignore: invalid_use_of_protected_member
                      homeViewModel.notifyListeners();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Refresh'),
                  ),
                ),
              ),

            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colors.containerBG,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isPositive ? Colors.green : Colors.red,
                  width: 2,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Today's Balance",
                    style: TextStyle(fontSize: 16, color: colors.primaryText),
                  ),
                  Text(
                    "${isPositive ? '+' : ''}$currency${balance.toStringAsFixed(2)}",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: isPositive ? Colors.green : Colors.red,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
