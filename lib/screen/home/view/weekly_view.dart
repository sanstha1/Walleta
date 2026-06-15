import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:walleta/services/currency_service.dart';
import 'package:walleta/services/transaction_service.dart';
import 'package:walleta/theme/app_colors.dart';

class WeeklyView extends StatelessWidget {
  const WeeklyView({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final currency = context.watch<CurrencyProvider>().symbol;
    final transactionService = Provider.of<TransactionService>(context);

    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 6));

    final weeklyTransactions = transactionService.getTransactionsForDateRange(
      DateTime(weekStart.year, weekStart.month, weekStart.day),
      DateTime(weekEnd.year, weekEnd.month, weekEnd.day, 23, 59, 59),
    );

    final weeklyExpense = weeklyTransactions
        .where((tx) => !(tx.isIncome ?? false))
        .fold(0.0, (sum, tx) => sum + (tx.amount ?? 0));

    final weeklyIncome = weeklyTransactions
        .where((tx) => tx.isIncome ?? false)
        .fold(0.0, (sum, tx) => sum + (tx.amount ?? 0));

    final weeklyChartData = _generateWeeklyChartData(transactionService);
    final balance = weeklyIncome - weeklyExpense;
    final isPositive = balance >= 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  "Expense",
                  weeklyExpense,
                  Colors.red,
                  colors,
                  currency,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryCard(
                  "Income",
                  weeklyIncome,
                  Colors.green,
                  colors,
                  currency,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: colors.containerBG,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Total Balance this Week",
                  style: TextStyle(fontSize: 14, color: colors.disabledText),
                ),
                const SizedBox(height: 8),
                Text(
                  "$currency${balance.toStringAsFixed(2)}",
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    color: isPositive ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: colors.containerBG,
              borderRadius: BorderRadius.circular(16),
            ),
            child: _buildWeeklyChart(weeklyChartData, colors, currency),
          ),

          const SizedBox(height: 24),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Recent Activity",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: colors.primaryText,
                ),
              ),
              Text(
                "${weeklyTransactions.length} items",
                style: TextStyle(fontSize: 14, color: colors.disabledText),
              ),
            ],
          ),

          const SizedBox(height: 16),

          if (transactionService.isLoading)
            const Center(child: CircularProgressIndicator())
          else if (weeklyTransactions.isEmpty)
            _buildEmptyState(colors)
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: weeklyTransactions.length > 10
                  ? 10
                  : weeklyTransactions.length,
              itemBuilder: (context, index) => _buildTransactionItem(
                weeklyTransactions[index],
                colors,
                currency,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
    String title,
    double amount,
    Color amountColor,
    AppColors colors,
    String currency,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.containerBG,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(fontSize: 12, color: colors.disabledText),
          ),
          const SizedBox(height: 4),
          FittedBox(
            child: Text(
              "$currency${amount.toStringAsFixed(2)}",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: amountColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyChart(
    Map<String, Map<String, double>> chartData,
    AppColors colors,
    String currency,
  ) {
    final allValues = chartData.values.expand((m) => m.values);
    final maxVal = allValues.isEmpty
        ? 100.0
        : allValues.reduce((a, b) => a > b ? a : b);
    final displayMax = maxVal == 0 ? 100.0 : maxVal;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Spending Trend",
          style: TextStyle(
            color: colors.primaryText,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 4),
            Text(
              "Expense",
              style: TextStyle(fontSize: 11, color: colors.disabledText),
            ),
            const SizedBox(width: 12),
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 4),
            Text(
              "Income",
              style: TextStyle(fontSize: 11, color: colors.disabledText),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 150,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: chartData.entries.map((entry) {
              final expense = entry.value['expense'] ?? 0;
              final income = entry.value['income'] ?? 0;
              final expenseHeight = (expense / displayMax * 100).clamp(
                expense > 0 ? 4.0 : 0.0,
                100.0,
              );
              final incomeHeight = (income / displayMax * 100).clamp(
                income > 0 ? 4.0 : 0.0,
                100.0,
              );

              return Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            "$currency${expense.toInt()}",
                            style: TextStyle(
                              fontSize: 8,
                              color: colors.disabledText,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            width: 12,
                            height: expenseHeight,
                            decoration: BoxDecoration(
                              color: expense > 0
                                  ? Colors.red
                                  // ignore: deprecated_member_use
                                  : colors.disabledText.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 3),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            "$currency${income.toInt()}",
                            style: TextStyle(
                              fontSize: 8,
                              color: colors.disabledText,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            width: 12,
                            height: incomeHeight,
                            decoration: BoxDecoration(
                              color: income > 0
                                  ? Colors.green
                                  // ignore: deprecated_member_use
                                  : colors.disabledText.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    entry.key,
                    style: TextStyle(fontSize: 12, color: colors.disabledText),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionItem(dynamic tx, AppColors colors, String currency) {
    final isIncome = tx.isIncome ?? false;
    final color = isIncome ? Colors.green : Colors.red;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.containerBG,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          CircleAvatar(
            // ignore: deprecated_member_use
            backgroundColor: color.withOpacity(0.1),
            child: Icon(
              isIncome ? Icons.south_west : Icons.north_east,
              color: color,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tx.title ?? 'Unknown',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: colors.primaryText,
                  ),
                ),
                Text(
                  tx.category ?? 'General',
                  style: TextStyle(fontSize: 12, color: colors.disabledText),
                ),
              ],
            ),
          ),
          Text(
            "${isIncome ? '+' : '-'}$currency${tx.amount?.toStringAsFixed(2)}",
            style: TextStyle(fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(AppColors colors) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Text(
          "No transactions recorded this week.",
          style: TextStyle(color: colors.disabledText),
        ),
      ),
    );
  }

  Map<String, Map<String, double>> _generateWeeklyChartData(
    TransactionService service,
  ) {
    final now = DateTime.now();
    final chartData = <String, Map<String, double>>{};

    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dayTransactions = service.getTransactionsForDay(
        DateTime(date.year, date.month, date.day),
      );

      chartData[DateFormat('EEE').format(date)] = {
        'expense': dayTransactions
            .where((tx) => !(tx.isIncome ?? false))
            .fold(0.0, (sum, tx) => sum + (tx.amount ?? 0)),
        'income': dayTransactions
            .where((tx) => tx.isIncome ?? false)
            .fold(0.0, (sum, tx) => sum + (tx.amount ?? 0)),
      };
    }

    return chartData;
  }
}
