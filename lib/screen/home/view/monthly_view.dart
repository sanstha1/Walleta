import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:walleta/screen/home/viewmodel/home_viewmodel.dart';
import 'package:walleta/services/currency_service.dart';
import 'package:walleta/services/transaction_service.dart';
import 'package:walleta/theme/app_colors.dart';

const Color _accentTeal = Color(0xFF006A60);
const Color _expenseDeep = Color(0xFFBA1A1A);
const Color _incomeDeep = Color(0xFF10B981);

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
                    color: colors.disabledText,
                    size: 18,
                  ),
                  onPressed: () => homeViewModel.changeMonth(-1),
                ),
                Column(
                  children: [
                    Text(
                      '${homeViewModel.getMonthName()} ${homeViewModel.selectedDate.year}',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: colors.primaryText,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Total: $currency${(monthlyIncome - monthlyExpense).toStringAsFixed(2)}',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 13,
                        color: colors.disabledText,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: Icon(
                    Icons.arrow_forward_ios,
                    color: colors.disabledText,
                    size: 18,
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
                child: _buildSummaryCard(
                  "Expense",
                  "$currency${monthlyExpense.toStringAsFixed(2)}",
                  _expenseDeep,
                  colors,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryCard(
                  "Income",
                  "$currency${monthlyIncome.toStringAsFixed(2)}",
                  _incomeDeep,
                  colors,
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
                  fontFamily: 'monospace',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: colors.primaryText,
                ),
              ),
              if (monthlyTransactions.isNotEmpty)
                Text(
                  "${monthlyTransactions.length} transactions",
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 13,
                    color: colors.disabledText,
                  ),
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
                    child: CircularProgressIndicator(color: _accentTeal),
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
                          fontFamily: 'monospace',
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
                  final iconColor = isIncome ? colors.success : colors.error;
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
                            color: iconColor.withOpacity(0.12),
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
                                  fontFamily: 'monospace',
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: colors.primaryText,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${tx.category ?? 'No Category'} • $date',
                                style: TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 13,
                                  color: colors.disabledText,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          "${isIncome ? '+' : '-'}$currency${tx.amount?.toStringAsFixed(2) ?? '0.00'}",
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: isIncome ? _incomeDeep : _expenseDeep,
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

  Widget _buildSummaryCard(
    String label,
    String amount,
    Color accentColor,
    AppColors colors,
  ) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        color: colors.containerBG,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 4, color: accentColor),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 13,
                        color: colors.disabledText,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      amount,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: accentColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
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
          style: TextStyle(fontFamily: 'monospace', color: colors.disabledText),
        ),
      );
    }

    final weeks = chartData.keys.toList();
    final weekCount = weeks.length;
    final incomePerWeek = weekCount > 0 ? totalIncome / weekCount : 0.0;
    final maxValue = chartData.values.reduce((a, b) => a > b ? a : b);
    final combinedMax = maxValue > incomePerWeek ? maxValue : incomePerWeek;
    final displayMax = combinedMax == 0 ? 100.0 : combinedMax;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Monthly Spending by Week",
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: colors.primaryText,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: const BoxDecoration(
                color: _expenseDeep,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              "Expense",
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 11,
                color: colors.disabledText,
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 10,
              height: 10,
              decoration: const BoxDecoration(
                color: _accentTeal,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              "Income",
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 11,
                color: colors.disabledText,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: 170,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: chartData.entries.map((entry) {
              final expenseValue = entry.value;
              final isExpenseDominant = expenseValue >= incomePerWeek;
              final value = isExpenseDominant ? expenseValue : incomePerWeek;
              final barColor = isExpenseDominant ? _expenseDeep : _accentTeal;
              final barHeight = displayMax > 0
                  ? (value / displayMax * 110).clamp(10.0, 110.0)
                  : 10.0;

              return Column(
                mainAxisAlignment: MainAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "$currency${value.toStringAsFixed(0)}",
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 9,
                      color: colors.disabledText,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: 14,
                    height: barHeight,
                    decoration: BoxDecoration(
                      color: barColor,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(7),
                      ),
                    ),
                  ),
                  Container(
                    width: 14,
                    height: 5,
                    decoration: const BoxDecoration(
                      color: _expenseDeep,
                      borderRadius: BorderRadius.vertical(
                        bottom: Radius.circular(7),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    entry.key,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                      color: colors.disabledText,
                    ),
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
