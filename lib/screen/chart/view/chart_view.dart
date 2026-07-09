// ignore_for_file: deprecated_member_use, use_build_context_synchronously

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:walleta/screen/category/view/add_new_categories.dart';
import 'package:walleta/screen/chart/viewmodel/add_transaction_viewmodel.dart';
import 'package:walleta/theme/app_colors.dart';
import 'package:walleta/screen/text_transaction/viewmodel/get_transaction_view_model.dart';
import 'package:walleta/theme/app_theme_manager.dart';
import 'package:walleta/services/currency_service.dart';
import 'dart:math' as math;

const Color _accentTeal = Color(0xFF006A60);
const Color _expenseDeep = Color(0xFFBA1A1A);
const Color _incomeDeep = Color(0xFF10B981);

enum DateFilter { week, month, threeMonths, year }

@RoutePage()
class TransactionPage extends StatefulWidget {
  const TransactionPage({super.key});

  @override
  State<TransactionPage> createState() => _TransactionPageState();

  static void showAddTransactionModal(
    BuildContext context,
    AddTransactionViewModel addViewModel,
    GetTransactionViewModel getViewModel,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: getViewModel),
          ChangeNotifierProvider.value(value: addViewModel),
        ],
        child: Consumer2<GetTransactionViewModel, AddTransactionViewModel>(
          builder: (context, getViewModel, addViewModel, child) {
            return _AddTransactionSheet(
              addViewModel: addViewModel,
              getViewModel: getViewModel,
            );
          },
        ),
      ),
    );
  }
}

class _TransactionPageState extends State<TransactionPage> {
  DateFilter _selectedFilter = DateFilter.week;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => GetTransactionViewModel()..initialize(),
        ),
        ChangeNotifierProvider(
          create: (_) => AddTransactionViewModel()..fetchCategories(),
        ),
      ],
      child:
          Consumer3<
            GetTransactionViewModel,
            AddTransactionViewModel,
            AppThemeManager
          >(
            builder:
                (context, getViewModel, addViewModel, themeManager, child) {
                  final colors = themeManager.colors;
                  final isDark = themeManager.isDark;

                  return Scaffold(
                    backgroundColor: colors.backgroundColor,
                    appBar: AppBar(
                      backgroundColor: colors.backgroundColor,
                      elevation: 0,
                      title: Text(
                        'Chart',
                        style: TextStyle(
                          color: colors.primaryText,
                          fontWeight: FontWeight.w800,
                          fontSize: 22,
                          fontFamily: 'monospace',
                        ),
                      ),
                      centerTitle: false,
                      iconTheme: IconThemeData(color: colors.primaryText),
                      actions: [
                        Padding(
                          padding: const EdgeInsets.only(right: 16),
                          child: Icon(
                            Icons.notifications_none_rounded,
                            color: colors.primaryText,
                            size: 24,
                          ),
                        ),
                      ],
                    ),
                    body: getViewModel.isBusy
                        ? Center(
                            child: CircularProgressIndicator(
                              color: _accentTeal,
                            ),
                          )
                        : _buildContent(context, getViewModel, colors, isDark),
                    floatingActionButton: FloatingActionButton.extended(
                      elevation: 4,
                      backgroundColor: _accentTeal,
                      onPressed: () => TransactionPage.showAddTransactionModal(
                        context,
                        addViewModel,
                        getViewModel,
                      ),
                      label: const Text(
                        "Add",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      icon: const Icon(
                        Icons.add_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  );
                },
          ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    GetTransactionViewModel viewModel,
    AppColors colors,
    bool isDark,
  ) {
    return RefreshIndicator(
      onRefresh: () => viewModel.getSyncedTransactions(),
      color: _accentTeal,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSummaryCards(viewModel, colors),
                  const SizedBox(height: 20),
                  _buildDateFilterBar(colors),
                  const SizedBox(height: 12),
                  _buildTrendLineChart(viewModel, colors, isDark),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
          _buildGroupedTransactionList(context, viewModel, colors),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  Widget _buildDateFilterBar(AppColors colors) {
    const filters = [
      (DateFilter.week, '7D'),
      (DateFilter.month, '1M'),
      (DateFilter.threeMonths, '3M'),
      (DateFilter.year, '1Y'),
    ];

    return Row(
      children: filters.map((entry) {
        final isSelected = _selectedFilter == entry.$1;
        return GestureDetector(
          onTap: () => setState(() => _selectedFilter = entry.$1),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? _accentTeal : colors.containerBG,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              entry.$2,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: isSelected ? Colors.white : colors.disabledText,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  List<Map<String, dynamic>> _getFilteredChartData(
    GetTransactionViewModel viewModel,
  ) {
    final now = DateTime.now();
    DateTime start;
    int buckets;
    String Function(DateTime) labelFn;

    switch (_selectedFilter) {
      case DateFilter.week:
        start = now.subtract(const Duration(days: 6));
        buckets = 7;
        labelFn = (d) =>
            ['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su'][d.weekday - 1];
        break;
      case DateFilter.month:
        start = now.subtract(const Duration(days: 29));
        buckets = 30;
        labelFn = (d) => '${d.day}';
        break;
      case DateFilter.threeMonths:
        start = now.subtract(const Duration(days: 89));
        buckets = 12;
        labelFn = (d) => '${d.day}/${d.month}';
        break;
      case DateFilter.year:
        start = DateTime(now.year, now.month - 11, 1);
        buckets = 12;
        labelFn = (d) => [
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
        ][d.month - 1];
        break;
    }

    final result = List.generate(buckets, (i) {
      DateTime date;
      if (_selectedFilter == DateFilter.year) {
        date = DateTime(start.year, start.month + i, 1);
      } else if (_selectedFilter == DateFilter.threeMonths) {
        date = start.add(Duration(days: i * 7));
      } else {
        date = start.add(Duration(days: i));
      }
      return {
        'date': date,
        'label': labelFn(date),
        'expense': 0.0,
        'income': 0.0,
      };
    });

    for (final tx in viewModel.transactions) {
      final txDate = tx.createdAt ?? DateTime.now();
      if (txDate.isBefore(start)) continue;

      for (int i = 0; i < result.length; i++) {
        final bucketDate = result[i]['date'] as DateTime;
        DateTime bucketEnd;
        if (i + 1 < result.length) {
          bucketEnd = result[i + 1]['date'] as DateTime;
        } else {
          bucketEnd = now.add(const Duration(days: 1));
        }

        if ((txDate.isAfter(bucketDate) ||
                txDate.isAtSameMomentAs(bucketDate)) &&
            txDate.isBefore(bucketEnd)) {
          if (tx.isIncome == true) {
            result[i]['income'] =
                (result[i]['income'] as double) + (tx.amount ?? 0.0);
          } else {
            result[i]['expense'] =
                (result[i]['expense'] as double) + (tx.amount ?? 0.0);
          }
          break;
        }
      }
    }

    return result;
  }

  Widget _buildTrendLineChart(
    GetTransactionViewModel viewModel,
    AppColors colors,
    bool isDark,
  ) {
    final data = _getFilteredChartData(viewModel);
    final allValues = data
        .expand((d) => [d['expense'] as double, d['income'] as double])
        .toList();
    final maxVal = allValues.isEmpty ? 1.0 : allValues.reduce(math.max);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.containerBG,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _legendDot(_expenseDeep, 'Expense', colors),
              const SizedBox(width: 16),
              _legendDot(_accentTeal, 'Income', colors),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 160,
            child: CustomPaint(
              painter: _TrendLinePainter(
                data: data,
                maxVal: maxVal == 0 ? 1 : maxVal,
                isDark: isDark,
              ),
              child: Container(),
            ),
          ),
          const SizedBox(height: 8),
          _buildChartLabels(data, colors),
        ],
      ),
    );
  }

  Widget _legendDot(Color color, String label, AppColors colors) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: colors.primaryText,
          ),
        ),
      ],
    );
  }

  Widget _buildChartLabels(List<Map<String, dynamic>> data, AppColors colors) {
    final step = (data.length / 5).ceil();
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(data.length, (i) {
        if (i % step != 0 && i != data.length - 1) {
          return const SizedBox.shrink();
        }
        return Text(
          data[i]['label'] as String,
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 10,
            color: colors.disabledText,
            fontWeight: FontWeight.w600,
          ),
        );
      }),
    );
  }

  Widget _buildSummaryCards(
    GetTransactionViewModel viewModel,
    AppColors colors,
  ) {
    final currency = context.read<CurrencyProvider>().symbol;
    return Row(
      children: [
        Expanded(
          child: _SummaryCard(
            label: 'Expense',
            sign: '-',
            amount: '$currency${viewModel.totalExpense.toStringAsFixed(2)}',
            color: _expenseDeep,
            icon: Icons.arrow_downward_rounded,
            colors: colors,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _SummaryCard(
            label: 'Income',
            sign: '+',
            amount: '$currency${viewModel.totalIncome.toStringAsFixed(2)}',
            color: _incomeDeep,
            icon: Icons.arrow_upward_rounded,
            colors: colors,
          ),
        ),
      ],
    );
  }

  Widget _buildGroupedTransactionList(
    BuildContext context,
    GetTransactionViewModel viewModel,
    AppColors colors,
  ) {
    final transactions = viewModel.transactions;

    final currency = context.watch<CurrencyProvider>().symbol;
    if (transactions.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long_rounded,
              size: 80,
              color: colors.disabledText.withOpacity(0.2),
            ),
            const SizedBox(height: 16),
            Text(
              "No transactions found",
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 16,
                color: colors.disabledText,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    final Map<String, List<dynamic>> grouped = {};
    for (final tx in transactions) {
      final date = tx.createdAt ?? DateTime.now();
      final key = _formatDateKey(date);
      grouped.putIfAbsent(key, () => []).add(tx);
    }

    final sortedKeys = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    final widgets = <Widget>[];

    for (final dateKey in sortedKeys) {
      final dayTransactions = grouped[dateKey]!;
      final dayExpense = dayTransactions
          .where((t) => t.isIncome != true)
          .fold(0.0, (sum, t) => sum + (t.amount ?? 0.0));
      final dayIncome = dayTransactions
          .where((t) => t.isIncome == true)
          .fold(0.0, (sum, t) => sum + (t.amount ?? 0.0));

      widgets.add(
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                dateKey,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: colors.primaryText,
                ),
              ),
              Row(
                children: [
                  if (dayExpense > 0)
                    Text(
                      '-$currency${dayExpense.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _expenseDeep,
                      ),
                    ),
                  if (dayExpense > 0 && dayIncome > 0) const SizedBox(width: 8),
                  if (dayIncome > 0)
                    Text(
                      '+$currency${dayIncome.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _incomeDeep,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      );

      for (int index = 0; index < dayTransactions.length; index++) {
        final transaction = dayTransactions[index];
        final isIncome = transaction.isIncome == true;

        widgets.add(
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Dismissible(
              key: Key(transaction.id?.toString() ?? '${dateKey}_$index'),
              direction: DismissDirection.horizontal,
              confirmDismiss: (direction) async {
                if (direction == DismissDirection.endToStart) {
                  return await _showDeleteConfirmation(context, colors);
                } else {
                  _handleEditTransaction(context, transaction);
                  return false;
                }
              },
              onDismissed: (direction) async {
                if (direction == DismissDirection.endToStart) {
                  final result = await viewModel.deleteTransaction(
                    transaction.id!,
                  );
                  if (result.success) {
                    await viewModel.getSyncedTransactions();
                  } else {
                    // ignore: duplicate_ignore
                    // ignore: use_build_context_synchronously
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Delete failed: ${result.message}'),
                        backgroundColor: _expenseDeep,
                      ),
                    );
                  }
                }
              },
              background: _buildSwipeBackground(
                alignment: Alignment.centerLeft,
                color: _accentTeal,
                icon: Icons.edit_rounded,
                label: "Edit",
              ),
              secondaryBackground: _buildSwipeBackground(
                alignment: Alignment.centerRight,
                color: _expenseDeep,
                icon: Icons.delete_outline_rounded,
                label: "Delete",
              ),
              child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colors.containerBG,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: (isIncome ? _incomeDeep : _expenseDeep)
                            // ignore: duplicate_ignore
                            // ignore: deprecated_member_use
                            .withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        transaction.emoji ?? (isIncome ? "💰" : "💸"),
                        style: const TextStyle(fontSize: 26),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            transaction.title ?? "Untitled",
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: colors.primaryText,
                            ),
                          ),
                          Text(
                            transaction.category ?? "Uncategorized",
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 13,
                              color: colors.disabledText,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "${isIncome ? '+' : '-'}$currency${transaction.amount?.toStringAsFixed(2) ?? '0.00'}",
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        color: isIncome ? _incomeDeep : _expenseDeep,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }
    }

    return SliverToBoxAdapter(child: Column(children: widgets));
  }

  String _formatDateKey(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final txDay = DateTime(date.year, date.month, date.day);

    if (txDay == today) return 'Today';
    if (txDay == yesterday) return 'Yesterday';

    const months = [
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
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  Widget _buildSwipeBackground({
    required Alignment alignment,
    required Color color,
    required IconData icon,
    required String label,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      alignment: alignment,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (alignment == Alignment.centerLeft)
            Icon(icon, color: Colors.white),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'monospace',
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 8),
          if (alignment == Alignment.centerRight)
            Icon(icon, color: Colors.white),
        ],
      ),
    );
  }

  Future<bool?> _showDeleteConfirmation(
    BuildContext context,
    AppColors colors,
  ) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colors.backgroundColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          "Delete Transaction?",
          style: TextStyle(
            fontFamily: 'monospace',
            color: colors.primaryText,
            fontWeight: FontWeight.w800,
          ),
        ),
        content: Text(
          "This action cannot be undone.",
          style: TextStyle(fontFamily: 'monospace', color: colors.disabledText),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              "Cancel",
              style: TextStyle(
                fontFamily: 'monospace',
                color: colors.disabledText,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: _expenseDeep,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              "Delete",
              style: TextStyle(fontFamily: 'monospace', color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _handleEditTransaction(BuildContext context, dynamic transaction) {
    final addViewModel = Provider.of<AddTransactionViewModel>(
      context,
      listen: false,
    );
    final getViewModel = Provider.of<GetTransactionViewModel>(
      context,
      listen: false,
    );

    addViewModel.isEditing = true;
    addViewModel.editingId = transaction.id;
    addViewModel.transactionTitle.text = transaction.title ?? "";
    addViewModel.transactionAmount.text = transaction.amount?.toString() ?? "";
    addViewModel.onSignChange(transaction.isIncome ?? false);
    addViewModel.selectCategory(transaction.category ?? "");

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: getViewModel),
          ChangeNotifierProvider.value(value: addViewModel),
        ],
        child: _AddTransactionSheet(
          addViewModel: addViewModel,
          getViewModel: getViewModel,
        ),
      ),
    ).then((_) {
      addViewModel.isEditing = false;
      addViewModel.editingId = null;
      addViewModel.transactionTitle.clear();
      addViewModel.transactionAmount.clear();
    });
  }
}

class _TrendLinePainter extends CustomPainter {
  final List<Map<String, dynamic>> data;
  final double maxVal;
  final bool isDark;

  _TrendLinePainter({
    required this.data,
    required this.maxVal,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final expensePaint = Paint()
      ..color = _expenseDeep
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final incomePaint = Paint()
      ..color = _accentTeal
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final expenseFill = Paint()
      ..color = _expenseDeep.withOpacity(0.08)
      ..style = PaintingStyle.fill;

    final incomeFill = Paint()
      ..color = _accentTeal.withOpacity(0.08)
      ..style = PaintingStyle.fill;

    final expensePath = Path();
    final incomePath = Path();
    final expenseFillPath = Path();
    final incomeFillPath = Path();

    final xStep = size.width / (data.length - 1);

    final expensePoints = <Offset>[];
    final incomePoints = <Offset>[];

    for (int i = 0; i < data.length; i++) {
      final x = i * xStep;
      final expenseY =
          size.height - ((data[i]['expense'] as double) / maxVal * size.height);
      final incomeY =
          size.height - ((data[i]['income'] as double) / maxVal * size.height);
      expensePoints.add(Offset(x, expenseY));
      incomePoints.add(Offset(x, incomeY));
    }

    _drawSmoothPath(expensePath, expensePoints);
    _drawSmoothPath(incomePath, incomePoints);

    expenseFillPath.addPath(expensePath, Offset.zero);
    expenseFillPath.lineTo(expensePoints.last.dx, size.height);
    expenseFillPath.lineTo(0, size.height);
    expenseFillPath.close();

    incomeFillPath.addPath(incomePath, Offset.zero);
    incomeFillPath.lineTo(incomePoints.last.dx, size.height);
    incomeFillPath.lineTo(0, size.height);
    incomeFillPath.close();

    canvas.drawPath(expenseFillPath, expenseFill);
    canvas.drawPath(incomeFillPath, incomeFill);
    canvas.drawPath(expensePath, expensePaint);
    canvas.drawPath(incomePath, incomePaint);

    final dotPaint = Paint()..style = PaintingStyle.fill;

    for (int i = 0; i < expensePoints.length; i++) {
      if ((data[i]['expense'] as double) > 0) {
        dotPaint.color = _expenseDeep;
        canvas.drawCircle(expensePoints[i], 4, dotPaint);
      }
    }

    for (int i = 0; i < incomePoints.length; i++) {
      if ((data[i]['income'] as double) > 0) {
        dotPaint.color = _accentTeal;
        canvas.drawCircle(incomePoints[i], 4, dotPaint);
      }
    }
  }

  void _drawSmoothPath(Path path, List<Offset> points) {
    if (points.isEmpty) return;
    path.moveTo(points[0].dx, points[0].dy);

    for (int i = 0; i < points.length - 1; i++) {
      final cp1 = Offset((points[i].dx + points[i + 1].dx) / 2, points[i].dy);
      final cp2 = Offset(
        (points[i].dx + points[i + 1].dx) / 2,
        points[i + 1].dy,
      );
      path.cubicTo(
        cp1.dx,
        cp1.dy,
        cp2.dx,
        cp2.dy,
        points[i + 1].dx,
        points[i + 1].dy,
      );
    }
  }

  @override
  bool shouldRepaint(_TrendLinePainter oldDelegate) =>
      oldDelegate.data != data || oldDelegate.maxVal != maxVal;
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String sign;
  final String amount;
  final Color color;
  final IconData icon;
  final AppColors colors;

  const _SummaryCard({
    required this.label,
    required this.sign,
    required this.amount,
    required this.color,
    required this.icon,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.containerBG,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: colors.disabledText),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: colors.disabledText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            sign,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          FittedBox(
            child: Text(
              amount,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: color,
                letterSpacing: -0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddTransactionSheet extends StatelessWidget {
  final AddTransactionViewModel addViewModel;
  final GetTransactionViewModel getViewModel;

  const _AddTransactionSheet({
    required this.addViewModel,
    required this.getViewModel,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.watch<AppThemeManager>().colors;
    final currency = context.watch<CurrencyProvider>().symbol;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Container(
        decoration: BoxDecoration(
          color: colors.backgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 48,
                      height: 5,
                      decoration: BoxDecoration(
                        color: colors.disabledText.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        addViewModel.isEditing
                            ? 'Edit Transaction'
                            : 'New Transaction',
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: colors.primaryText,
                        ),
                      ),
                      CircleAvatar(
                        backgroundColor: colors.containerBG,
                        child: IconButton(
                          icon: Icon(
                            Icons.close_rounded,
                            color: colors.primaryText,
                            size: 20,
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _InputCard(
                    colors: colors,
                    label: 'DESCRIPTION',
                    child: TextField(
                      controller: addViewModel.transactionTitle,
                      focusNode: addViewModel.titleFocusNode,
                      textCapitalization: TextCapitalization.sentences,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        color: colors.primaryText,
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Dinner, Rent...',
                        hintStyle: TextStyle(
                          fontFamily: 'monospace',
                          color: colors.disabledText.withOpacity(0.4),
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _InputCard(
                    colors: colors,
                    label: 'AMOUNT',
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: colors.backgroundColor,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            children: [
                              _ToggleButton(
                                label: 'Exp',
                                isSelected: !addViewModel.isIncome,
                                colors: colors,
                                onTap: () => addViewModel.onSignChange(false),
                              ),
                              _ToggleButton(
                                label: 'Inc',
                                isSelected: addViewModel.isIncome,
                                colors: colors,
                                onTap: () => addViewModel.onSignChange(true),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextField(
                            controller: addViewModel.transactionAmount,
                            focusNode: addViewModel.amountFocusNode,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            textAlign: TextAlign.end,
                            style: TextStyle(
                              fontFamily: 'monospace',
                              color: addViewModel.isIncome
                                  ? _incomeDeep
                                  : _expenseDeep,
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                            ),
                            decoration: InputDecoration(
                              hintText: '0.00',
                              hintStyle: TextStyle(
                                fontFamily: 'monospace',
                                color: colors.disabledText.withOpacity(0.2),
                              ),
                              border: InputBorder.none,
                              prefixText: '$currency ',
                              prefixStyle: const TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'CATEGORY',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                      color: colors.disabledText,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 12),
                  addViewModel.isBusy
                      ? Center(
                          child: CircularProgressIndicator(color: _accentTeal),
                        )
                      : SizedBox(
                          height: 50,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: addViewModel.categories.length + 1,
                            itemBuilder: (context, index) {
                              if (index == 0) {
                                return _buildAddButton(context, colors);
                              }
                              final category =
                                  addViewModel.categories[index - 1];
                              final isSelected =
                                  addViewModel.selectedCategory ==
                                  category.title;
                              return _buildCategoryChip(
                                context,
                                category,
                                isSelected,
                                colors,
                              );
                            },
                          ),
                        ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: ElevatedButton(
                      onPressed:
                          addViewModel.canAddTransaction && !addViewModel.isBusy
                          ? () async {
                              if (addViewModel.isEditing) {
                                await addViewModel.updateTransaction();
                              } else {
                                await addViewModel.onSaveTransactionPressed();
                              }
                              Navigator.pop(context);
                              await getViewModel.getSyncedTransactions();
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: addViewModel.isEditing
                            ? _accentTeal
                            : colors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: Text(
                        addViewModel.isEditing
                            ? 'Update Changes'
                            : 'Confirm Transaction',
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAddButton(BuildContext context, AppColors colors) {
    return GestureDetector(
      onTap: () async {
        final result = await showModalBottomSheet<bool>(
          context: context,
          builder: (context) => const AddNewCategories(),
        );
        if (result == true) await addViewModel.fetchCategories();
      },
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: colors.containerBG,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _accentTeal.withOpacity(0.5)),
        ),
        child: Row(
          children: [
            Icon(Icons.add_rounded, color: _accentTeal, size: 20),
            const SizedBox(width: 4),
            Text(
              "Add",
              style: TextStyle(
                fontFamily: 'monospace',
                color: _accentTeal,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChip(
    BuildContext context,
    dynamic category,
    bool isSelected,
    AppColors colors,
  ) {
    return GestureDetector(
      onTap: () => addViewModel.selectCategory(category.title ?? ''),
      onLongPress: () async {
        bool? confirm = await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: colors.backgroundColor,
            title: Text(
              "Delete ${category.title}?",
              style: TextStyle(
                fontFamily: 'monospace',
                color: colors.primaryText,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text(
                  "No",
                  style: TextStyle(fontFamily: 'monospace'),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  "Yes",
                  style: TextStyle(
                    fontFamily: 'monospace',
                    color: _expenseDeep,
                  ),
                ),
              ),
            ],
          ),
        );
        if (confirm == true) {
          await addViewModel.deleteCategory(category.id.toString());
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? _accentTeal : colors.containerBG,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Text(category.emoji ?? '📁', style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 8),
            Text(
              category.title ?? '',
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 14,
                color: isSelected ? Colors.white : colors.primaryText,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InputCard extends StatelessWidget {
  final AppColors colors;
  final String label;
  final Widget child;

  const _InputCard({
    required this.colors,
    required this.label,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: colors.containerBG,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 11,
              color: colors.disabledText,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 6),
          child,
        ],
      ),
    );
  }
}

class _ToggleButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final AppColors colors;
  final VoidCallback onTap;

  const _ToggleButton({
    required this.label,
    required this.isSelected,
    required this.colors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? _accentTeal : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'monospace',
            color: isSelected ? Colors.white : colors.disabledText,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}
