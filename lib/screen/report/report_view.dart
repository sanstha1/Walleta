import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:walleta/screen/chart/viewmodel/get_transaction_viewmodel.dart';
import 'dart:io';

import 'package:walleta/services/currency_service.dart';
import 'package:walleta/theme/app_colors.dart';

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
    switch (category.toLowerCase().trim()) {
      case 'education':
        return const Color(0xFF43A047);
      case 'food':
        return const Color(0xFF1E88E5);
      case 'work':
        return const Color(0xFF5E35B1);
      case 'shopping':
        return const Color(0xFFE91E63);
      case 'health':
        return const Color(0xFFF44336);
      case 'transport':
        return Colors.orangeAccent;
      default:
        return const Color(0xFFFB8C00);
    }
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

  Future<int> _getAndroidSdkInt() async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      final android = await deviceInfo.androidInfo;
      return android.version.sdkInt;
    } catch (_) {
      return 30;
    }
  }

  Future<bool> _requestStoragePermission() async {
    final sdk = await _getAndroidSdkInt();

    if (sdk >= 30) {
      final status = await Permission.manageExternalStorage.request();
      if (!status.isGranted) {
        if (!mounted) return false;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Please allow "All files access" in Settings.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 5),
          ),
        );
        await openAppSettings();
        return false;
      }
      return true;
    } else if (sdk >= 29) {
      return true;
    } else {
      final status = await Permission.storage.request();
      if (!status.isGranted) {
        if (!mounted) return false;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Storage permission denied.'),
            backgroundColor: Colors.red,
          ),
        );
        return false;
      }
      return true;
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
      if (Platform.isAndroid) {
        final granted = await _requestStoragePermission();
        if (!granted) return;
      }

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

      final downloadsDir = Directory('/storage/emulated/0/Download');
      if (!await downloadsDir.exists()) {
        await downloadsDir.create(recursive: true);
      }

      final filename =
          'report-${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.csv';
      final file = File('${downloadsDir.path}/$filename');
      await file.writeAsString(buffer.toString());

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Saved to Downloads/$filename'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 5),
        ),
      );
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
    final colors = AppColors.of(context);
    final currency = context.watch<CurrencyProvider>().symbol;

    return Scaffold(
      backgroundColor: colors.backgroundColor,
      body: SafeArea(
        child: Consumer<GetTransactionViewModel>(
          builder: (context, viewModel, child) {
            final filteredList = viewModel.transactions.where((t) {
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
              return (selectedFilter == "Income"
                  ? (t.isIncome ?? false)
                  : !(t.isIncome ?? false));
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
                          // ignore: deprecated_member_use
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
                        ),
                        _buildCategoryChart(
                          categoryData,
                          totalInTab,
                          colors,
                          currency,
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
                'This Month',
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
                'Balance',
                style: TextStyle(color: colors.disabledText, fontSize: 12),
              ),
              const SizedBox(height: 4),
              Text(
                '${balance >= 0 ? '+' : '-'}$currency${balance.abs().toStringAsFixed(2)}',
                style: const TextStyle(
                  color: _accentTeal,
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
  ) {
    if (list.isEmpty) {
      return Center(
        child: Text(
          "No records found",
          style: TextStyle(color: colors.disabledText),
        ),
      );
    }
    return ListView.builder(
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
              _getCategoryEmoji(
                t.category ?? "General",
                _getCategoryColor(t.category ?? "General"),
              ),
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
    );
  }

  Widget _buildCategoryChart(
    Map<String, double> data,
    double total,
    AppColors colors,
    String currency,
  ) {
    if (data.isEmpty) {
      return Center(
        child: Text(
          "No data to visualize",
          style: TextStyle(color: colors.disabledText),
        ),
      );
    }
    return Column(
      children: [
        const SizedBox(height: 20),
        SizedBox(
          height: 180,
          child: PieChart(
            PieChartData(
              sectionsSpace: 4,
              centerSpaceRadius: 40,
              sections: data.entries
                  .map(
                    (e) => PieChartSectionData(
                      color: _getCategoryColor(e.key),
                      value: e.value,
                      radius: 20,
                      showTitle: false,
                    ),
                  )
                  .toList(),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Expanded(
          child: ListView(
            children: data.entries
                .map(
                  (e) => _ReportCategoryRow(
                    label: e.key,
                    amount: "$currency${e.value.toStringAsFixed(2)}",
                    percent: "${(e.value / total * 100).toStringAsFixed(1)}%",
                    color: _getCategoryColor(e.key),
                    textColor: colors.primaryText,
                    subColor: colors.disabledText,
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }

  Widget _getCategoryEmoji(String name, Color color) {
    String emoji = "💰";
    if (name.toLowerCase().contains('food')) {
      emoji = "🍕";
    } else if (name.toLowerCase().contains('transport')) {
      emoji = "🚗";
    } else if (name.toLowerCase().contains('shopping')) {
      emoji = "🛍️";
    }
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        // ignore: deprecated_member_use
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      child: Text(emoji, style: const TextStyle(fontSize: 20)),
    );
  }

  Widget _buildTypeFilters(AppColors colors) {
    return Row(
      children: ["All", "Expense", "Income"].map((type) {
        final isSelected = selectedFilter == type;
        return GestureDetector(
          onTap: () => setState(() => selectedFilter = type),
          child: Container(
            margin: const EdgeInsets.only(right: 10),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
            decoration: BoxDecoration(
              color: isSelected ? _accentTeal : colors.containerBG,
              borderRadius: BorderRadius.circular(30),
              boxShadow: isSelected ? [] : AppColors.softShadow,
            ),
            child: Text(
              type,
              style: TextStyle(
                color: isSelected ? Colors.white : colors.disabledText,
                fontSize: 12,
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
