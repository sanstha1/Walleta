import 'dart:io';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:walleta/screen/chart/viewmodel/get_transaction_viewmodel.dart';
import 'package:walleta/services/currency_service.dart';
import 'package:walleta/theme/app_colors.dart';
import 'package:walleta/theme/app_theme_manager.dart';

const Color _accentTeal = Color(0xFF006A60);

class TransactionReportView extends StatefulWidget {
  const TransactionReportView({super.key});

  @override
  State<TransactionReportView> createState() => _TransactionReportViewState();
}

class _TransactionReportViewState extends State<TransactionReportView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String selectedFilter = "All";
  DateTime startDate = DateTime.now().subtract(const Duration(days: 7));
  DateTime endDate = DateTime.now();
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<GetTransactionViewModel>(
        context,
        listen: false,
      ).getSyncedTransactions();
    });
  }

  Color _getCategoryColor(String category) {
    final lowerCat = category.toLowerCase().trim();

    if (lowerCat.contains('food') ||
        lowerCat.contains('grocery') ||
        lowerCat.contains('restaurant')) {
      return const Color(0xFF1E88E5);
    }
    if (lowerCat.contains('transport') ||
        lowerCat.contains('travel') ||
        lowerCat.contains('fuel')) {
      return const Color(0xFFFF9800);
    }
    if (lowerCat.contains('shopping') || lowerCat.contains('clothing')) {
      return const Color(0xFFE91E63);
    }
    if (lowerCat.contains('health') || lowerCat.contains('medical')) {
      return const Color(0xFFF44336);
    }
    if (lowerCat.contains('education') || lowerCat.contains('school')) {
      return const Color(0xFF43A047);
    }
    if (lowerCat.contains('work') ||
        lowerCat.contains('salary') ||
        lowerCat.contains('income')) {
      return const Color(0xFF5E35B1);
    }
    if (lowerCat.contains('entertainment') ||
        lowerCat.contains('movie') ||
        lowerCat.contains('game')) {
      return const Color(0xFF00BCD4);
    }
    if (lowerCat.contains('bill') ||
        lowerCat.contains('utility') ||
        lowerCat.contains('rent')) {
      return const Color(0xFF795548);
    }

    final List<Color> vibrantColors = const [
      Color(0xFFE53935),
      Color(0xFFD81B60),
      Color(0xFF8E24AA),
      Color(0xFF5E35B1),
      Color(0xFF3949AB),
      Color(0xFF1E88E5),
      Color(0xFF039BE5),
      Color(0xFF00ACC1),
      Color(0xFF00897B),
      Color(0xFF43A047),
      Color(0xFF7CB342),
      Color(0xFFC0CA33),
      Color(0xFFFDD835),
      Color(0xFFFFB300),
      Color(0xFFFF9800),
      Color(0xFFFB8C00),
      Color(0xFF8D6E63),
      Color(0xFF78909C),
    ];

    int index = lowerCat.hashCode.abs() % vibrantColors.length;
    return vibrantColors[index];
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate ? startDate : endDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        if (isStartDate) {
          startDate = picked;
        } else {
          endDate = picked;
        }
      });
    }
  }

  Future<void> _exportFilteredToCsv(List<dynamic> filteredList) async {
    if (filteredList.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No transactions to export.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isExporting = true);
    try {
      final buffer = StringBuffer();
      buffer.writeln('Date,Title,Category,Amount,Type');
      for (final t in filteredList) {
        final date = DateFormat(
          'yyyy-MM-dd HH:mm',
        ).format(t.createdAt ?? DateTime.now());
        final title = (t.title ?? 'Untitled').replaceAll(',', ' ');
        final category = (t.category ?? 'Other').replaceAll(',', ' ');
        final amount = (t.amount ?? 0.0).toStringAsFixed(2);
        final type = (t.isIncome ?? false) ? 'Income' : 'Expense';
        buffer.writeln('$date,$title,$category,$amount,$type');
      }

      final filename =
          'report-${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.csv';
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/$filename');
      await file.writeAsString(buffer.toString());

      final result = await SharePlus.instance.share(
        ShareParams(files: [XFile(file.path)], text: 'Your transaction report'),
      );

      if (!mounted) return;

      if (result.status == ShareResultStatus.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Saved $filename'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Export failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeManager = context.watch<AppThemeManager>();
    final colors = themeManager.colors;
    final currency = context.watch<CurrencyProvider>().symbol;

    return Scaffold(
      backgroundColor: colors.backgroundColor,
      body: SafeArea(
        child: Consumer<GetTransactionViewModel>(
          builder: (context, viewModel, child) {
            final filteredList = viewModel.transactions.where((t) {
              if (t.createdAt == null) return false;
              final tDate = DateTime(
                t.createdAt!.year,
                t.createdAt!.month,
                t.createdAt!.day,
              );
              final sDate = DateTime(
                startDate.year,
                startDate.month,
                startDate.day,
              );
              final eDate = DateTime(endDate.year, endDate.month, endDate.day);

              final matchesDate =
                  tDate.isAtSameMomentAs(sDate) ||
                  tDate.isAtSameMomentAs(eDate) ||
                  (tDate.isAfter(sDate) && tDate.isBefore(eDate));

              if (!matchesDate) return false;
              if (selectedFilter == "All") return true;
              if (selectedFilter == "Income") return (t.isIncome ?? false);
              return !(t.isIncome ?? false);
            }).toList();

            Map<String, double> categoryData = {};
            double totalInTab = 0;
            double incomeInTab = 0;
            double expenseInTab = 0;

            for (var t in filteredList) {
              double amount = t.amount ?? 0.0;
              totalInTab += amount;
              if (t.isIncome ?? false) {
                incomeInTab += amount;
              } else {
                expenseInTab += amount;
              }
              String cat = (t.category ?? 'Other').trim();
              categoryData[cat] = (categoryData[cat] ?? 0.0) + amount;
            }
            final balance = incomeInTab - expenseInTab;

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Report',
                        style: TextStyle(
                          color: colors.primaryText,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      GestureDetector(
                        onTap: _isExporting
                            ? null
                            : () => _exportFilteredToCsv(filteredList),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: colors.containerBG,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: AppColors.softShadow,
                          ),
                          child: _isExporting
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: _accentTeal,
                                  ),
                                )
                              : const Icon(
                                  Icons.download_rounded,
                                  color: _accentTeal,
                                  size: 18,
                                ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildTypeFilters(colors),
                  const SizedBox(height: 20),
                  Text(
                    'Custom Range',
                    style: TextStyle(
                      color: colors.disabledText,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildDatePickerRow(colors),
                  const SizedBox(height: 20),
                  Container(
                    height: 45,
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: colors.disabled.withOpacity(0.4),
                        ),
                      ),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      indicatorColor: _accentTeal,
                      labelColor: _accentTeal,
                      unselectedLabelColor: colors.disabledText,
                      dividerColor: Colors.transparent,
                      labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                      tabs: const [
                        Tab(text: 'Transactions'),
                        Tab(text: 'Visuals'),
                      ],
                    ),
                  ),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildSpendingList(
                          filteredList,
                          colors,
                          currency,
                          balance,
                          viewModel,
                        ),
                        _buildCategoryChart(
                          categoryData,
                          totalInTab,
                          colors,
                          currency,
                          viewModel,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSummaryCard(
    int count,
    double balance,
    AppColors colors,
    String currency,
  ) {
    return Container(
      margin: const EdgeInsets.only(top: 15, bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.containerBG,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppColors.softShadow,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Selected Period',
                style: TextStyle(color: colors.disabledText, fontSize: 12),
              ),
              const SizedBox(height: 4),
              Text(
                '$count Transactions',
                style: TextStyle(
                  color: colors.primaryText,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Net Balance',
                style: TextStyle(color: colors.disabledText, fontSize: 12),
              ),
              const SizedBox(height: 4),
              Text(
                '${balance >= 0 ? '+' : '-'}$currency${balance.abs().toStringAsFixed(2)}',
                style: TextStyle(
                  color: balance >= 0 ? colors.success : colors.error,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSpendingList(
    List<dynamic> list,
    AppColors colors,
    String currency,
    double balance,
    GetTransactionViewModel viewModel,
  ) {
    if (list.isEmpty) {
      String emptyMessage = "No records found for this period.";
      if (selectedFilter == "Income") {
        emptyMessage = "No income records found.";
      } else if (selectedFilter == "Expense") {
        emptyMessage = "No expense records found.";
      }
      return RefreshIndicator(
        onRefresh: () => viewModel.getSyncedTransactions(),
        color: _accentTeal,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(
              height: 300,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Text(
                    emptyMessage,
                    style: TextStyle(color: colors.disabledText, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: () => viewModel.getSyncedTransactions(),
      color: _accentTeal,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        itemCount: list.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return _buildSummaryCard(list.length, balance, colors, currency);
          }
          final t = list[index - 1];
          final isIncome = t.isIncome ?? false;
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.containerBG,
              borderRadius: BorderRadius.circular(16),
              boxShadow: AppColors.softShadow,
            ),
            child: Row(
              children: [
                _getCategoryEmoji(t.emoji, t.category ?? "General"),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t.title ?? "Untitled",
                        style: TextStyle(
                          color: colors.primaryText,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${DateFormat('MMM dd, hh:mm a').format(t.createdAt ?? DateTime.now())}  ·  ${(t.category ?? 'GENERAL').toUpperCase()}',
                        style: TextStyle(
                          color: colors.disabledText,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  "${isIncome ? '+' : '-'}$currency${(t.amount ?? 0.0).toStringAsFixed(2)}",
                  style: TextStyle(
                    color: isIncome ? colors.success : colors.error,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCategoryChart(
    Map<String, double> data,
    double total,
    AppColors colors,
    String currency,
    GetTransactionViewModel viewModel,
  ) {
    if (data.isEmpty) {
      String emptyMessage = "No data to visualize.";
      if (selectedFilter == "Income") {
        emptyMessage = "No income records found for this period.";
      } else if (selectedFilter == "Expense") {
        emptyMessage = "No expense records found for this period.";
      }
      return RefreshIndicator(
        onRefresh: () => viewModel.getSyncedTransactions(),
        color: _accentTeal,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(
              height: 300,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Text(
                    emptyMessage,
                    style: TextStyle(color: colors.disabledText, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    String chartTitle = "Transaction Breakdown";
    Color titleColor = _accentTeal;
    if (selectedFilter == "Expense") {
      chartTitle = "Expense Breakdown";
      titleColor = colors.error;
    } else if (selectedFilter == "Income") {
      chartTitle = "Income Breakdown";
      titleColor = colors.success;
    }

    final entries = data.entries.toList();

    return RefreshIndicator(
      onRefresh: () => viewModel.getSyncedTransactions(),
      color: _accentTeal,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Column(
              children: [
                const SizedBox(height: 20),
                Text(
                  chartTitle,
                  style: TextStyle(
                    color: titleColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Total: $currency${total.toStringAsFixed(2)}",
                  style: TextStyle(
                    color: colors.disabledText,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 200,
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 4,
                      centerSpaceRadius: 45,
                      sections: entries
                          .map(
                            (e) => PieChartSectionData(
                              color: _getCategoryColor(e.key),
                              value: e.value,
                              radius: 25,
                              showTitle: true,
                              title:
                                  "${(e.value / total * 100).toStringAsFixed(0)}%",
                              titleStyle: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final e = entries[index];
              return _ReportCategoryRow(
                label: e.key,
                amount: "$currency${e.value.toStringAsFixed(2)}",
                percent: "${(e.value / total * 100).toStringAsFixed(1)}%",
                color: _getCategoryColor(e.key),
                textColor: colors.primaryText,
                subColor: colors.disabledText,
              );
            }, childCount: entries.length),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  Widget _getCategoryEmoji(String? emoji, String category) {
    final color = _getCategoryColor(category);
    String displayEmoji = "💰";

    if (emoji != null && emoji.isNotEmpty && emoji != "null") {
      displayEmoji = emoji;
    } else {
      final lowerCat = category.toLowerCase();
      if (lowerCat.contains('food') ||
          lowerCat.contains('grocery') ||
          lowerCat.contains('restaurant')) {
        displayEmoji = "🍕";
      } else if (lowerCat.contains('transport') ||
          lowerCat.contains('travel') ||
          lowerCat.contains('fuel')) {
        displayEmoji = "🚗";
      } else if (lowerCat.contains('shopping') ||
          lowerCat.contains('clothing')) {
        displayEmoji = "🛍️";
      } else if (lowerCat.contains('health') || lowerCat.contains('medical')) {
        displayEmoji = "🏥";
      } else if (lowerCat.contains('education') ||
          lowerCat.contains('school')) {
        displayEmoji = "📚";
      } else if (lowerCat.contains('work') ||
          lowerCat.contains('salary') ||
          lowerCat.contains('income')) {
        displayEmoji = "💼";
      } else if (lowerCat.contains('entertainment') ||
          lowerCat.contains('movie') ||
          lowerCat.contains('game')) {
        displayEmoji = "🎬";
      } else if (lowerCat.contains('bill') ||
          lowerCat.contains('utility') ||
          lowerCat.contains('rent')) {
        displayEmoji = "🧾";
      }
    }

    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      child: Text(displayEmoji, style: const TextStyle(fontSize: 20)),
    );
  }

  Widget _buildTypeFilters(AppColors colors) {
    return Row(
      children: ["All", "Expense", "Income"].map((type) {
        final isSelected = selectedFilter == type;
        return GestureDetector(
          onTap: () => setState(() => selectedFilter = type),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.only(right: 10),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
            decoration: BoxDecoration(
              color: isSelected ? _accentTeal : colors.containerBG,
              borderRadius: BorderRadius.circular(30),
              border: isSelected
                  ? null
                  : Border.all(color: colors.disabled.withOpacity(0.2)),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: _accentTeal.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : AppColors.softShadow,
            ),
            child: Text(
              type,
              style: TextStyle(
                color: isSelected ? Colors.white : colors.disabledText,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDatePickerRow(AppColors colors) {
    final df = DateFormat('dd MMM, yyyy');
    return Row(
      children: [
        _buildDateBox(
          "FROM",
          df.format(startDate),
          colors,
          () => _selectDate(context, true),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Icon(Icons.arrow_forward, size: 14, color: _accentTeal),
        ),
        _buildDateBox(
          "TO",
          df.format(endDate),
          colors,
          () => _selectDate(context, false),
        ),
      ],
    );
  }

  Widget _buildDateBox(
    String label,
    String date,
    AppColors colors,
    VoidCallback onTap,
  ) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colors.containerBG,
            borderRadius: BorderRadius.circular(14),
            boxShadow: AppColors.softShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: _accentTeal,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                date,
                style: TextStyle(
                  color: colors.primaryText,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReportCategoryRow extends StatelessWidget {
  final String label, amount, percent;
  final Color color, textColor, subColor;

  const _ReportCategoryRow({
    required this.label,
    required this.amount,
    required this.percent,
    required this.color,
    required this.textColor,
    required this.subColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Text(label, style: TextStyle(color: subColor, fontSize: 13)),
          const Spacer(),
          Text(
            amount,
            style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 10),
          Text(
            percent,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
