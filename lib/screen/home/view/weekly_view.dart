import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:walleta/services/currency_service.dart';
import 'package:walleta/services/transaction_service.dart';
import 'package:walleta/theme/app_colors.dart';

const Color _accentTeal = Color(0xFF006A60);
const Color _expenseDeep = Color(0xFFBA1A1A);
const Color _incomeDeep = Color(0xFF10B981);

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
                  "$currency${weeklyExpense.toStringAsFixed(2)}",
                  _expenseDeep,
                  colors,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryCard(
                  "Income",
                  "$currency${weeklyIncome.toStringAsFixed(2)}",
                  _incomeDeep,
                  colors,
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
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 13,
                    color: colors.disabledText,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "$currency${balance.toStringAsFixed(2)}",
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    color: isPositive ? _incomeDeep : _expenseDeep,
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
                  fontFamily: 'monospace',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: colors.primaryText,
                ),
              ),
              Text(
                "${weeklyTransactions.length} items",
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 13,
                  color: colors.disabledText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (transactionService.isLoading)
            Center(child: CircularProgressIndicator(color: _accentTeal))
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
    String label,
    String amount,
    Color accentColor,
    AppColors colors,
  ) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        color: colors.containerBG,
        child: IntrinsicHeight(
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
                          fontSize: 12,
                          color: colors.disabledText,
                        ),
                      ),
                      const SizedBox(height: 6),
                      FittedBox(
                        child: Text(
                          amount,
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: accentColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWeeklyChart(
    Map<String, Map<String, double>> chartData,
    AppColors colors,
    String currency,
  ) {
    final maxVal = chartData.values
        .expand((m) => [m['expense'] ?? 0, m['income'] ?? 0])
        .fold(0.0, (a, b) => a > b ? a : b);
    final displayMax = maxVal == 0 ? 100.0 : maxVal;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Spending Trend",
          style: TextStyle(
            fontFamily: 'monospace',
            color: colors.primaryText,
            fontWeight: FontWeight.bold,
            fontSize: 15,
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
          height: 165,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: chartData.entries.map((entry) {
              final expense = entry.value['expense'] ?? 0;
              final income = entry.value['income'] ?? 0;
              final hasData = expense > 0 || income > 0;
              final isExpenseDominant = expense >= income;
              final value = isExpenseDominant ? expense : income;
              final barColor = isExpenseDominant ? _expenseDeep : _accentTeal;
              final barHeight = hasData
                  ? (value / displayMax * 95).clamp(6.0, 95.0)
                  : 6.0;

              return Column(
                mainAxisAlignment: MainAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    height: 12,
                    child: hasData
                        ? Text(
                            "$currency${value.toInt()}",
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 9,
                              color: colors.disabledText,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: 18,
                    height: barHeight,
                    decoration: BoxDecoration(
                      color: hasData
                          ? barColor.withOpacity(0.8)
                          : colors.disabledText.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
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

  Widget _buildTransactionItem(dynamic tx, AppColors colors, String currency) {
    final isIncome = tx.isIncome ?? false;
    final color = isIncome ? colors.success : colors.error;
    final amountColor = isIncome ? _incomeDeep : _expenseDeep;

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
            backgroundColor: color.withOpacity(0.12),
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
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.w600,
                    color: colors.primaryText,
                  ),
                ),
                Text(
                  tx.category ?? 'General',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    color: colors.disabledText,
                  ),
                ),
              ],
            ),
          ),
          Text(
            "${isIncome ? '+' : '-'}$currency${tx.amount?.toStringAsFixed(2)}",
            style: TextStyle(
              fontFamily: 'monospace',
              fontWeight: FontWeight.w700,
              color: amountColor,
            ),
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
          style: TextStyle(fontFamily: 'monospace', color: colors.disabledText),
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
