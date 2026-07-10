import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:walleta/screen/profile/budget/viewmodel/budget_viewmodel.dart';
import 'package:walleta/services/currency_service.dart';

const Color _expenseDeep = Color(0xFFBA1A1A);

class BudgetAlertBanner extends StatelessWidget {
  final BudgetModel budget;

  const BudgetAlertBanner({super.key, required this.budget});

  static void show(BuildContext context, BudgetModel budget) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 6),
        backgroundColor: Colors.transparent,
        elevation: 0,
        content: BudgetAlertBanner(budget: budget),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currency = context.watch<CurrencyProvider>().symbol;
    final isExceeded = budget.isExceeded;
    final color = isExceeded ? _expenseDeep : Colors.orange.shade700;
    final icon = isExceeded
        ? Icons.money_off_rounded
        : Icons.warning_amber_rounded;
    final title = isExceeded
        ? '🚨 Budget Exceeded!'
        : '⚠️ Budget Alert (${budget.alertThreshold}% reached)';

    final spentText = '$currency${(budget.spent ?? 0).toStringAsFixed(2)}';
    final limitText =
        '$currency${(budget.limitAmount ?? 0).toStringAsFixed(2)}';
    final budgetName = budget.budgetType;
    final periodLabel = budget.periodLabel;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$budgetName ($periodLabel): $spentText / $limitText',
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
