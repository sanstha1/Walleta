import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:walleta/screen/home/viewmodel/home_viewmodel.dart';
import 'package:walleta/services/currency_service.dart';
import 'package:walleta/services/transaction_service.dart';
import 'package:walleta/theme/app_colors.dart';

class MonthlyView extends StatelessWidget {
  const MonthlyView({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final currency = context.watch<CurrencyProvider>().symbol;
    final homeViewModel = Provider.of<HomeViewModel>(context);
    Provider.of<TransactionService>(context);

    final monthlyExpense = homeViewModel.getMonthlyExpense(context);
    final monthlyIncome = homeViewModel.getMonthlyIncome(context);
    final monthlyTransactions = homeViewModel.getMonthlyTransactions(context);
    final monthlyChartData = homeViewModel.getMonthlyChartData(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.containerBG,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: Icon(
                    Icons.arrow_back_ios,
                    color: colors.primaryText,
                    size: 20,
                  ),
                  onPressed: () => homeViewModel.changeMonth(-1),
                ),
                Column(
                  children: [
                    Text(
                      '${homeViewModel.getMonthName()} ${homeViewModel.selectedDate.year}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: colors.primaryText,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Total: $currency${(monthlyIncome - monthlyExpense).toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 14,
                        color: colors.disabledText,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: Icon(
                    Icons.arrow_forward_ios,
                    color: colors.primaryText,
                    size: 20,
                  ),
                  onPressed:
                      homeViewModel.selectedDate.month < DateTime.now().month
                      ? () => homeViewModel.changeMonth(1)
                      : null,
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

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
                        "-$currency${monthlyExpense.toStringAsFixed(2)}",
                        style: const TextStyle(
                          fontSize: 20,
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
                        "+$currency${monthlyIncome.toStringAsFixed(2)}",
                        style: const TextStyle(
                          fontSize: 20,
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

          const SizedBox(height: 20),

          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: colors.containerBG,
              borderRadius: BorderRadius.circular(16),
            ),
            child: _buildMonthlyChart(
              monthlyChartData,
              monthlyIncome,
              monthlyExpense,
              colors,
              currency,
            ),
          ),

          const SizedBox(height: 24),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'This Month',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: colors.primaryText,
                ),
              ),
              if (monthlyTransactions.isNotEmpty)
                Text(
                  "${monthlyTransactions.length} transactions",
                  style: TextStyle(fontSize: 14, color: colors.disabledText),
                ),
            ],
          ),
          const SizedBox(height: 16),

          Consumer<TransactionService>(
            builder: (context, service, child) {
              if (service.isLoading) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: CircularProgressIndicator(color: colors.primary),
                  ),
                );
              }
              if (monthlyTransactions.isEmpty) {
                return Container(
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
                        "No transactions this month",
                        style: TextStyle(
                          fontSize: 16,
                          color: colors.disabledText,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return Column(
                children: monthlyTransactions.take(10).map((tx) {
                  final isIncome = tx.isIncome ?? false;
                  final iconColor = isIncome ? Colors.green : Colors.red;
                  final date = tx.createdAt != null
                      ? DateFormat('MMM d').format(tx.createdAt!)
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
                                '${tx.category ?? 'No Category'} • $date',
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
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyChart(
    Map<String, double> chartData,
    double totalIncome,
    double totalExpense,
    AppColors colors,
    String currency,
  ) {
    if (chartData.isEmpty) {
      return Center(
        child: Text(
          'No data for this month',
          style: TextStyle(color: colors.disabledText),
        ),
      );
    }

    final maxValue = chartData.values.isNotEmpty
        ? chartData.values.reduce((a, b) => a > b ? a : b)
        : 100;
    final weeks = chartData.keys.toList();
    final weekCount = weeks.length;
    final incomePerWeek = weekCount > 0 ? totalIncome / weekCount : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Monthly Spending by Week",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: colors.primaryText,
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
          height: 180,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: chartData.entries.map((entry) {
              final combinedMax = maxValue > incomePerWeek
                  ? maxValue
                  : incomePerWeek;
              final expenseHeight = combinedMax > 0
                  ? (entry.value / combinedMax) * 120
                  : 0.0;
              final incomeHeight = combinedMax > 0
                  ? (incomePerWeek / combinedMax) * 120
                  : 0.0;

              return Column(
                mainAxisAlignment: MainAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            "$currency${entry.value.toStringAsFixed(0)}",
                            style: TextStyle(
                              fontSize: 8,
                              color: colors.disabledText,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            width: 14,
                            height: expenseHeight.clamp(4.0, 120.0),
                            decoration: BoxDecoration(
                              color: Colors.red,
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
                            "$currency${incomePerWeek.toStringAsFixed(0)}",
                            style: TextStyle(
                              fontSize: 8,
                              color: colors.disabledText,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            width: 14,
                            height: incomeHeight.clamp(4.0, 120.0),
                            decoration: BoxDecoration(
                              color: Colors.green,
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
}
