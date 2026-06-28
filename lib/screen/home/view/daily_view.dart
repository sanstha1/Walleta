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
                  child: _buildSummaryCard(
                    "Expense",
                    "$currency${dailyExpense.toStringAsFixed(2)}",
                    _expenseDeep,
                    colors,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSummaryCard(
                    "Income",
                    "$currency${dailyIncome.toStringAsFixed(2)}",
                    _incomeDeep,
                    colors,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            Text(
              DateFormat('EEEE, MMMM d').format(DateTime.now()),
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: colors.primaryText,
              ),
            ),

            const SizedBox(height: 16),

            if (transactionService.isLoading)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: CircularProgressIndicator(color: _accentTeal),
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
                        fontFamily: 'monospace',
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
                  final iconColor = isIncome ? colors.success : colors.error;
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
                                '${tx.category ?? 'No Category'} • $time',
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
              ),

            if (!transactionService.isLoading)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Center(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      transactionService.fetchTransactions();
                      // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
                      homeViewModel.notifyListeners();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _accentTeal,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 14,
                      ),
                    ),
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text(
                      'Refresh',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 16),

            Stack(
              children: [
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: colors.containerBG,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Today's Balance",
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: colors.primaryText,
                        ),
                      ),
                      Text(
                        "${isPositive ? '+' : ''}$currency${balance.toStringAsFixed(2)}",
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: isPositive ? colors.success : colors.error,
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned.fill(
                  child: CustomPaint(
                    painter: _DashedRRectPainter(
                      color: isPositive ? colors.success : colors.error,
                      radius: 16,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
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
                        fontSize: 24,
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
}

class _DashedRRectPainter extends CustomPainter {
  final Color color;
  final double radius;

  _DashedRRectPainter({required this.color, required this.radius});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0.75, 0.75, size.width - 1.5, size.height - 1.5),
      Radius.circular(radius),
    );

    final path = Path()..addRRect(rrect);
    final dashPath = Path();
    const dashWidth = 6.0;
    const dashSpace = 4.0;

    for (final metric in path.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        final next = distance + dashWidth;
        dashPath.addPath(
          metric.extractPath(distance, next.clamp(0, metric.length)),
          Offset.zero,
        );
        distance = next + dashSpace;
      }
    }

    canvas.drawPath(dashPath, paint);
  }

  @override
  bool shouldRepaint(covariant _DashedRRectPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.radius != radius;
}
