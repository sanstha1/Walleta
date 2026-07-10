import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:walleta/theme/app_theme_manager.dart';

const Color _accentTeal = Color(0xFF006A60);
const Color _expenseDeep = Color(0xFFBA1A1A);

class BudgetCheckDialog extends StatelessWidget {
  final String email;
  final String category;
  final double amount;
  final VoidCallback onProceed;
  final VoidCallback onCancel;

  const BudgetCheckDialog({
    super.key,
    required this.email,
    required this.category,
    required this.amount,
    required this.onProceed,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.watch<AppThemeManager>().colors;
    return FutureBuilder(
      future: context.read<BudgetService>().checkBudgetLimit(
        email: email,
        category: category,
        amount: amount,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return AlertDialog(
            backgroundColor: colors.backgroundColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Text(
              'Checking Budget...',
              style: TextStyle(
                fontFamily: 'monospace',
                color: colors.primaryText,
                fontWeight: FontWeight.w800,
              ),
            ),
            content: Center(
              child: CircularProgressIndicator(color: _accentTeal),
            ),
          );
        }

        if (snapshot.hasError) {
          return AlertDialog(
            backgroundColor: colors.backgroundColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Text(
              'Error',
              style: TextStyle(
                fontFamily: 'monospace',
                color: colors.primaryText,
                fontWeight: FontWeight.w800,
              ),
            ),
            content: Text(
              'Error checking budget: ${snapshot.error}',
              style: TextStyle(
                fontFamily: 'monospace',
                color: colors.disabledText,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  onCancel();
                },
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    color: colors.disabledText,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  onProceed();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _expenseDeep,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Proceed Anyway',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          );
        }

        final result = snapshot.data ?? {};
        final canProceed = result['canProceed'] as bool? ?? true;
        final issues =
            (result['issues'] as List<dynamic>?)
                ?.cast<Map<String, dynamic>>() ??
            [];

        if (canProceed) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.pop(context);
            onProceed();
          });
          return const SizedBox.shrink();
        }

        return AlertDialog(
          backgroundColor: colors.backgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            '⚠️ Budget Alert',
            style: TextStyle(
              fontFamily: 'monospace',
              color: colors.primaryText,
              fontWeight: FontWeight.w800,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'This transaction will exceed your budget(s):',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.w600,
                    color: colors.primaryText,
                  ),
                ),
                const SizedBox(height: 12),
                ...issues.map((issue) {
                  final type = issue['type'] as String?;
                  final current = issue['current'] as num?;
                  final limit = issue['limit'] as num?;
                  final projected = issue['projected'] as num?;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _expenseDeep.withOpacity(0.1),
                        border: Border.all(
                          color: _expenseDeep.withOpacity(0.5),
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            type == 'overall_exceeded'
                                ? '💰 Overall Budget'
                                : '📁 ${issue['category']} Budget',
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.w700,
                              color: _expenseDeep,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Current: ${current?.toStringAsFixed(2) ?? '0'}\n'
                            'Will be: ${projected?.toStringAsFixed(2) ?? '0'}\n'
                            'Limit: ${limit?.toStringAsFixed(2) ?? '0'}',
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 12,
                              color: colors.primaryText,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                onCancel();
              },
              child: Text(
                'Cancel',
                style: TextStyle(
                  fontFamily: 'monospace',
                  color: colors.disabledText,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                onProceed();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _expenseDeep,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Proceed Anyway',
                style: TextStyle(
                  fontFamily: 'monospace',
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

Future<bool?> showBudgetCheckDialog({
  required BuildContext context,
  required String email,
  required String category,
  required double amount,
}) {
  return showDialog<bool?>(
    context: context,
    builder: (context) => BudgetCheckDialog(
      email: email,
      category: category,
      amount: amount,
      onProceed: () {},
      onCancel: () {},
    ),
  );
}
