import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:walleta/theme/app_colors.dart';
import 'package:walleta/theme/app_theme_manager.dart';

const Color _accentTeal = Color(0xFF006A60);
const Color _expenseDeep = Color(0xFFBA1A1A);

class BudgetSummaryWidget extends StatelessWidget {
  final String email;

  const BudgetSummaryWidget({Key? key, required this.email}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colors = context.watch<AppThemeManager>().colors;
    return Consumer<BudgetService>(
      builder: (context, budgetService, _) {
        if (budgetService.isLoading) {
          return Center(child: CircularProgressIndicator(color: _accentTeal));
        }

        if (budgetService.budgets.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                'Budget Status',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: colors.primaryText,
                ),
              ),
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  ...budgetService.budgets.map((budget) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: _buildBudgetChip(budget, colors),
                    );
                  }).toList(),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
        );
      },
    );
  }

  // ignore: strict_top_level_inference
  Widget _buildBudgetChip(budget, AppColors colors) {
    final statusColor = budget.isExceeded
        ? _expenseDeep
        : budget.isNearLimit
        ? Colors.orange
        : _accentTeal;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        border: Border.all(color: statusColor),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            budget.budgetType,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: statusColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${budget.percentageUsed.toStringAsFixed(0)}% • ${(budget.spent ?? 0).toStringAsFixed(0)}/${(budget.limitAmount ?? 0).toStringAsFixed(0)}',
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 11,
              color: colors.primaryText,
            ),
          ),
        ],
      ),
    );
  }
}
