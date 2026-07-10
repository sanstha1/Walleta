import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:walleta/screen/category/view/add_new_categories.dart';
import 'package:walleta/screen/chart/viewmodel/add_transaction_viewmodel.dart';
import 'package:walleta/screen/profile/budget/viewmodel/budget_viewmodel.dart';
import 'package:walleta/services/budget_service.dart';
import 'package:walleta/services/currency_service.dart';
import 'package:walleta/theme/app_colors.dart';
import 'package:walleta/theme/app_theme_manager.dart';

const Color _accentTeal = Color(0xFF006A60);
const Color _expenseDeep = Color(0xFFBA1A1A);

class BudgetManagementScreen extends StatefulWidget {
  final String email;
  const BudgetManagementScreen({super.key, required this.email});

  @override
  State<BudgetManagementScreen> createState() => _BudgetManagementScreenState();
}

class _BudgetManagementScreenState extends State<BudgetManagementScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BudgetService>().fetchBudgets(widget.email);
    });
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        padding: EdgeInsets.zero,
        backgroundColor: Colors.transparent,
        elevation: 0,
        duration: const Duration(seconds: 3),
        content: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: _accentTeal,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: _accentTeal.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: Colors.white,
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        padding: EdgeInsets.zero,
        backgroundColor: Colors.transparent,
        elevation: 0,
        duration: const Duration(seconds: 4),
        content: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: _expenseDeep,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: _expenseDeep.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close_rounded,
                  color: Colors.white,
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currency = context.watch<CurrencyProvider>().symbol;
    final themeManager = context.watch<AppThemeManager>();
    final colors = themeManager.colors;

    return Scaffold(
      backgroundColor: colors.backgroundColor,
      appBar: AppBar(
        backgroundColor: colors.backgroundColor,
        elevation: 0,
        centerTitle: false,
        title: Text(
          'Budget Limits',
          style: TextStyle(
            fontFamily: 'monospace',
            fontWeight: FontWeight.w800,
            fontSize: 22,
            color: colors.primaryText,
          ),
        ),
        iconTheme: IconThemeData(color: colors.primaryText),
      ),
      body: Consumer<BudgetService>(
        builder: (context, budgetService, _) {
          if (budgetService.isLoading) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: _accentTeal),
                  const SizedBox(height: 16),
                  Text(
                    'Loading budgets...',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      color: colors.disabledText,
                    ),
                  ),
                ],
              ),
            );
          }

          if (budgetService.error != null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: _expenseDeep.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.wifi_off_rounded,
                        size: 48,
                        color: _expenseDeep,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Something went wrong',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: colors.primaryText,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      budgetService.error!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        color: colors.disabledText,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () => budgetService.fetchBudgets(widget.email),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _accentTeal,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text(
                        'Try Again',
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SectionHeader(
                  title: 'Overall Budget',
                  icon: Icons.account_balance_wallet_rounded,
                  colors: colors,
                ),
                const SizedBox(height: 12),
                if (budgetService.overallBudget != null &&
                    budgetService.overallBudget!.id != null)
                  _buildBudgetCard(
                    budget: budgetService.overallBudget!,
                    currency: currency,
                    colors: colors,
                    onEdit: () => _showEditBudgetDialog(
                      context: context,
                      budget: budgetService.overallBudget!,
                      currency: currency,
                      colors: colors,
                    ),
                    onDelete: () => _showDeleteConfirmation(
                      context: context,
                      budget: budgetService.overallBudget!,
                      colors: colors,
                    ),
                  )
                else
                  _AddBudgetPlaceholder(
                    label: 'Set Overall Budget',
                    colors: colors,
                    onTap: () => _showCreateBudgetDialog(
                      context: context,
                      email: widget.email,
                      currency: currency,
                      colors: colors,
                    ),
                  ),
                const SizedBox(height: 32),
                _SectionHeader(
                  title: 'Category Budgets',
                  icon: Icons.grid_view_rounded,
                  colors: colors,
                ),
                const SizedBox(height: 12),
                if (budgetService.categoryBudgets.isEmpty)
                  _AddBudgetPlaceholder(
                    label: 'Add Category Budget',
                    colors: colors,
                    onTap: () => _showCreateCategoryBudgetDialog(
                      context: context,
                      email: widget.email,
                      currency: currency,
                      colors: colors,
                    ),
                  )
                else ...[
                  ...budgetService.categoryBudgets.values.map(
                    (budget) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildBudgetCard(
                        budget: budget,
                        currency: currency,
                        colors: colors,
                        onEdit: () => _showEditBudgetDialog(
                          context: context,
                          budget: budget,
                          currency: currency,
                          colors: colors,
                        ),
                        onDelete: () => _showDeleteConfirmation(
                          context: context,
                          budget: budget,
                          colors: colors,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _showCreateCategoryBudgetDialog(
                        context: context,
                        email: widget.email,
                        currency: currency,
                        colors: colors,
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _accentTeal,
                        side: const BorderSide(color: _accentTeal),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      icon: const Icon(Icons.add_rounded),
                      label: const Text(
                        'Add Category Budget',
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildBudgetCard({
    required BudgetModel budget,
    required String currency,
    required AppColors colors,
    required VoidCallback onEdit,
    required VoidCallback onDelete,
  }) {
    final percent = (budget.percentageUsed / 100).clamp(0.0, 1.0);
    final Color progressColor = budget.isExceeded
        ? _expenseDeep
        : budget.isNearLimit
        ? Colors.orange
        : _accentTeal;

    return Container(
      decoration: BoxDecoration(
        color: colors.containerBG,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: budget.isExceeded
              ? _expenseDeep.withOpacity(0.4)
              : budget.isNearLimit
              ? Colors.orange.withOpacity(0.4)
              : colors.disabledText.withOpacity(0.1),
          width: budget.isExceeded || budget.isNearLimit ? 1.5 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: progressColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    budget.category == null
                        ? Icons.account_balance_wallet_rounded
                        : Icons.label_rounded,
                    color: progressColor,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        budget.budgetType,
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: colors.primaryText,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: _accentTeal.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          budget.periodLabel,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 11,
                            color: _accentTeal,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton(
                  icon: Icon(
                    Icons.more_vert_rounded,
                    color: colors.disabledText,
                  ),
                  color: colors.containerBG,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      onTap: onEdit,
                      child: Row(
                        children: [
                          const Icon(
                            Icons.edit_rounded,
                            size: 18,
                            color: _accentTeal,
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            'Edit',
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      onTap: onDelete,
                      child: const Row(
                        children: [
                          Icon(
                            Icons.delete_outline_rounded,
                            size: 18,
                            color: _expenseDeep,
                          ),
                          SizedBox(width: 10),
                          Text(
                            'Delete',
                            style: TextStyle(
                              fontFamily: 'monospace',
                              color: _expenseDeep,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${budget.percentageUsed.toStringAsFixed(1)}% used',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: progressColor,
                  ),
                ),
                Text(
                  '$currency${(budget.spent ?? 0).toStringAsFixed(2)} / $currency${(budget.limitAmount ?? 0).toStringAsFixed(2)}',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: colors.disabledText,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: percent,
                minHeight: 10,
                backgroundColor: colors.disabledText.withOpacity(0.1),
                valueColor: AlwaysStoppedAnimation(progressColor),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                if (!budget.isExceeded) ...[
                  const Icon(
                    Icons.savings_rounded,
                    size: 16,
                    color: _accentTeal,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '$currency${budget.remaining.toStringAsFixed(2)} remaining',
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: _accentTeal,
                    ),
                  ),
                ] else ...[
                  const Icon(
                    Icons.warning_rounded,
                    size: 16,
                    color: _expenseDeep,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '$currency${(-(budget.remaining)).toStringAsFixed(2)} over budget',
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: _expenseDeep,
                    ),
                  ),
                ],
                const Spacer(),
                if (budget.alertsEnabled == true)
                  Row(
                    children: [
                      Icon(
                        Icons.notifications_active_rounded,
                        size: 14,
                        color: colors.disabledText,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Alerts on',
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 11,
                          color: colors.disabledText,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            if (budget.isNearLimit || budget.isExceeded) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: budget.isExceeded
                      ? _expenseDeep.withOpacity(0.1)
                      : Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: budget.isExceeded
                        ? _expenseDeep.withOpacity(0.3)
                        : Colors.orange.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      budget.isExceeded
                          ? Icons.error_outline_rounded
                          : Icons.warning_amber_rounded,
                      size: 16,
                      color: budget.isExceeded ? _expenseDeep : Colors.orange,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        budget.isExceeded
                            ? 'Budget exceeded! Consider reviewing your expenses.'
                            : 'Alert threshold (${budget.alertThreshold}%) reached',
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: budget.isExceeded
                              ? _expenseDeep
                              : Colors.orange,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showCreateBudgetDialog({
    required BuildContext context,
    required String email,
    required String currency,
    required AppColors colors,
  }) {
    _showBudgetFormDialog(
      context: context,
      title: 'Set Overall Budget',
      email: email,
      isNew: true,
      currency: currency,
      colors: colors,
    );
  }

  void _showCreateCategoryBudgetDialog({
    required BuildContext context,
    required String email,
    required String currency,
    required AppColors colors,
  }) {
    _showBudgetFormDialog(
      context: context,
      title: 'Add Category Budget',
      email: email,
      isNew: true,
      isCategory: true,
      currency: currency,
      colors: colors,
    );
  }

  void _showEditBudgetDialog({
    required BuildContext context,
    required BudgetModel budget,
    required String currency,
    required AppColors colors,
  }) {
    final limitController = TextEditingController(
      text: budget.limitAmount?.toString() ?? '',
    );
    final alertThresholdController = TextEditingController(
      text: budget.alertThreshold?.toString() ?? '80',
    );
    bool alertsEnabled = budget.alertsEnabled ?? false;
    String selectedPeriod = budget.period ?? 'monthly';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: colors.backgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _accentTeal.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.edit_rounded,
                  color: _accentTeal,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Edit ${budget.budgetType} Budget',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: colors.primaryText,
                  ),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: selectedPeriod,
                  dropdownColor: colors.containerBG,
                  decoration: InputDecoration(
                    labelText: 'Budget Period',
                    labelStyle: TextStyle(
                      fontFamily: 'monospace',
                      color: colors.disabledText,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: colors.disabledText.withOpacity(0.2),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: _accentTeal),
                    ),
                    filled: true,
                    fillColor: colors.disabledText.withOpacity(0.05),
                  ),
                  style: TextStyle(
                    fontFamily: 'monospace',
                    color: colors.primaryText,
                    fontWeight: FontWeight.w600,
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'daily',
                      child: Text(
                        'Daily',
                        style: TextStyle(fontFamily: 'monospace'),
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'weekly',
                      child: Text(
                        'Weekly',
                        style: TextStyle(fontFamily: 'monospace'),
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'monthly',
                      child: Text(
                        'Monthly',
                        style: TextStyle(fontFamily: 'monospace'),
                      ),
                    ),
                  ],
                  onChanged: (v) {
                    if (v != null) setState(() => selectedPeriod = v);
                  },
                ),
                const SizedBox(height: 12),
                _StyledTextField(
                  controller: limitController,
                  label: 'Budget Limit ($currency)',
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  colors: colors,
                ),
                const SizedBox(height: 12),
                _StyledTextField(
                  controller: alertThresholdController,
                  label: 'Alert Threshold (%)',
                  keyboardType: TextInputType.number,
                  colors: colors,
                ),
                const SizedBox(height: 12),
                _AlertsToggle(
                  value: alertsEnabled,
                  colors: colors,
                  onChanged: (v) => setState(() => alertsEnabled = v ?? false),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: TextStyle(
                  fontFamily: 'monospace',
                  color: colors.disabledText,
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _accentTeal,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () async {
                final limit = double.tryParse(limitController.text);
                final threshold = int.tryParse(alertThresholdController.text);
                if (!_validateInputs(limit, threshold, colors)) return;
                try {
                  await context.read<BudgetService>().updateBudget(
                    budgetId: budget.id!,
                    limitAmount: limit,
                    alertThreshold: threshold,
                    alertsEnabled: alertsEnabled,
                    period: selectedPeriod,
                  );
                  if (mounted) {
                    Navigator.pop(context);
                    _showSuccess('Budget updated successfully');
                  }
                } catch (e) {
                  if (mounted)
                    _handleBudgetError(
                      context,
                      e.toString(),
                      null,
                      selectedPeriod,
                      colors,
                    );
                }
              },
              child: const Text(
                'Update',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showBudgetFormDialog({
    required BuildContext context,
    required String title,
    required String email,
    required bool isNew,
    required String currency,
    required AppColors colors,
    bool isCategory = false,
  }) {
    final limitController = TextEditingController();
    final alertThresholdController = TextEditingController(text: '80');
    String selectedCategory = '';
    String selectedPeriod = 'monthly';
    bool alertsEnabled = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: colors.backgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _accentTeal.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.add_chart_rounded,
                  color: _accentTeal,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: colors.primaryText,
                  ),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: selectedPeriod,
                  dropdownColor: colors.containerBG,
                  decoration: InputDecoration(
                    labelText: 'Budget Period',
                    labelStyle: TextStyle(
                      fontFamily: 'monospace',
                      color: colors.disabledText,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: colors.disabledText.withOpacity(0.2),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: _accentTeal),
                    ),
                    filled: true,
                    fillColor: colors.disabledText.withOpacity(0.05),
                  ),
                  style: TextStyle(
                    fontFamily: 'monospace',
                    color: colors.primaryText,
                    fontWeight: FontWeight.w600,
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'daily',
                      child: Text(
                        'Daily',
                        style: TextStyle(fontFamily: 'monospace'),
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'weekly',
                      child: Text(
                        'Weekly',
                        style: TextStyle(fontFamily: 'monospace'),
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'monthly',
                      child: Text(
                        'Monthly',
                        style: TextStyle(fontFamily: 'monospace'),
                      ),
                    ),
                  ],
                  onChanged: (v) {
                    if (v != null) setState(() => selectedPeriod = v);
                  },
                ),
                const SizedBox(height: 12),
                if (isCategory)
                  ChangeNotifierProvider(
                    create: (_) => AddTransactionViewModel()..fetchCategories(),
                    child: Consumer<AddTransactionViewModel>(
                      builder: (context, catVm, _) {
                        if (catVm.isBusy) {
                          return const SizedBox(
                            height: 50,
                            child: Center(
                              child: CircularProgressIndicator(
                                color: _accentTeal,
                              ),
                            ),
                          );
                        }
                        return SizedBox(
                          height: 50,
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                GestureDetector(
                                  onTap: () async {
                                    final result =
                                        await showModalBottomSheet<bool>(
                                          context: context,
                                          builder: (context) =>
                                              const AddNewCategories(),
                                        );
                                    if (result == true) {
                                      await catVm.fetchCategories();
                                    }
                                  },
                                  child: Container(
                                    margin: const EdgeInsets.only(right: 8),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: _accentTeal.withOpacity(0.5),
                                      ),
                                    ),
                                    child: const Row(
                                      children: [
                                        Icon(
                                          Icons.add_rounded,
                                          size: 16,
                                          color: _accentTeal,
                                        ),
                                        SizedBox(width: 4),
                                        Text(
                                          'Add',
                                          style: TextStyle(
                                            fontFamily: 'monospace',
                                            color: _accentTeal,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                ...catVm.categories.map((cat) {
                                  final isSel = selectedCategory == cat.title;
                                  return GestureDetector(
                                    onTap: () => setState(
                                      () => selectedCategory = cat.title,
                                    ),
                                    child: AnimatedContainer(
                                      duration: const Duration(
                                        milliseconds: 200,
                                      ),
                                      margin: const EdgeInsets.only(right: 8),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isSel
                                            ? _accentTeal
                                            : colors.disabledText.withOpacity(
                                                0.1,
                                              ),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        children: [
                                          Text(
                                            cat.emoji,
                                            style: const TextStyle(
                                              fontSize: 16,
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            cat.title,
                                            style: TextStyle(
                                              fontFamily: 'monospace',
                                              color: isSel
                                                  ? Colors.white
                                                  : colors.primaryText,
                                              fontWeight: FontWeight.w700,
                                              fontSize: 13,
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
                        );
                      },
                    ),
                  ),
                if (isCategory) const SizedBox(height: 12),
                _StyledTextField(
                  controller: limitController,
                  label: 'Budget Limit ($currency)',
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  colors: colors,
                ),
                const SizedBox(height: 12),
                _StyledTextField(
                  controller: alertThresholdController,
                  label: 'Alert Threshold (%)',
                  keyboardType: TextInputType.number,
                  colors: colors,
                ),
                const SizedBox(height: 12),
                _AlertsToggle(
                  value: alertsEnabled,
                  colors: colors,
                  onChanged: (v) => setState(() => alertsEnabled = v ?? false),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: TextStyle(
                  fontFamily: 'monospace',
                  color: colors.disabledText,
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _accentTeal,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () async {
                final limit = double.tryParse(limitController.text);
                final threshold = int.tryParse(alertThresholdController.text);
                if (!_validateInputs(limit, threshold, colors)) return;
                if (isCategory && selectedCategory.isEmpty) {
                  _showValidationDialog(
                    context,
                    'Category Required',
                    'Please select a category for this budget.',
                    colors,
                  );
                  return;
                }
                try {
                  await context.read<BudgetService>().createBudget(
                    email: email,
                    limitAmount: limit!,
                    period: selectedPeriod,
                    category: isCategory ? selectedCategory : null,
                    alertThreshold: threshold!,
                    alertsEnabled: alertsEnabled,
                  );
                  if (mounted) {
                    // ignore: use_build_context_synchronously
                    Navigator.pop(context);
                    _showSuccess('Budget created successfully 🎉');
                  }
                } catch (e) {
                  if (mounted) {
                    _handleBudgetError(
                      // ignore: use_build_context_synchronously
                      context,
                      e.toString(),
                      isCategory ? selectedCategory : null,
                      selectedPeriod,
                      colors,
                    );
                  }
                }
              },
              child: const Text(
                'Create',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation({
    required BuildContext context,
    required BudgetModel budget,
    required AppColors colors,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colors.backgroundColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _expenseDeep.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.delete_outline_rounded,
                color: _expenseDeep,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Delete Budget',
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to delete the ${budget.budgetType} budget? This cannot be undone.',
          style: TextStyle(
            fontFamily: 'monospace',
            color: colors.disabledText,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(
                fontFamily: 'monospace',
                color: colors.disabledText,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _expenseDeep,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () async {
              try {
                await context.read<BudgetService>().deleteBudget(
                  budget.id!,
                  widget.email,
                );
                if (mounted) {
                  // ignore: use_build_context_synchronously
                  Navigator.pop(context);
                  _showSuccess('Budget deleted');
                }
              } catch (e) {
                if (mounted) {
                  // ignore: use_build_context_synchronously
                  Navigator.pop(context);
                  _showError('Delete failed: ${e.toString()}');
                }
              }
            },
            child: const Text(
              'Delete',
              style: TextStyle(
                fontFamily: 'monospace',
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _validateInputs(double? limit, int? threshold, AppColors colors) {
    if (limit == null || limit <= 0) {
      _showValidationDialog(
        context,
        'Invalid Amount',
        'Please enter a valid budget limit greater than 0.',
        colors,
      );
      return false;
    }
    if (threshold == null || threshold < 1 || threshold > 100) {
      _showValidationDialog(
        context,
        'Invalid Threshold',
        'Alert threshold must be between 1 and 100.',
        colors,
      );
      return false;
    }
    return true;
  }

  void _showValidationDialog(
    BuildContext context,
    String title,
    String message,
    AppColors colors,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colors.backgroundColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              color: Colors.orange,
              size: 24,
            ),
            const SizedBox(width: 10),
            Text(
              title,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: TextStyle(
            fontFamily: 'monospace',
            color: colors.disabledText,
            height: 1.5,
          ),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'OK',
              style: TextStyle(
                fontFamily: 'monospace',
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleBudgetError(
    BuildContext context,
    String error,
    String? category,
    String period,
    AppColors colors,
  ) {
    if (error.contains('already exists') || error.contains('DUPLICATE')) {
      final periodLabel = period == 'daily'
          ? 'Daily'
          : period == 'weekly'
          ? 'Weekly'
          : 'Monthly';
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: colors.backgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.copy_rounded,
                  color: Colors.orange,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Already Exists',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'A $periodLabel budget for "${category ?? 'overall'}" already exists for this period.',
                style: TextStyle(
                  fontFamily: 'monospace',
                  color: colors.disabledText,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _accentTeal.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _accentTeal.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.lightbulb_outline_rounded,
                      size: 16,
                      color: _accentTeal,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Try editing the existing budget instead.',
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                          color: _accentTeal,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: TextStyle(
                  fontFamily: 'monospace',
                  color: colors.disabledText,
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                Navigator.pop(context);
                context.read<BudgetService>().fetchBudgets(widget.email);
              },
              child: const Text(
                'View Existing',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      );
      return;
    }
    _showError(error.replaceAll('Exception: ', ''));
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final AppColors colors;
  const _SectionHeader({
    required this.title,
    required this.icon,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: _accentTeal),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: colors.primaryText,
          ),
        ),
      ],
    );
  }
}

class _AddBudgetPlaceholder extends StatelessWidget {
  final String label;
  final AppColors colors;
  final VoidCallback onTap;
  const _AddBudgetPlaceholder({
    required this.label,
    required this.colors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 28),
        decoration: BoxDecoration(
          color: colors.containerBG,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _accentTeal.withOpacity(0.3), width: 1.5),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _accentTeal.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.add_rounded,
                size: 28,
                color: _accentTeal,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'monospace',
                color: _accentTeal,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StyledTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final TextInputType keyboardType;
  final AppColors colors;
  const _StyledTextField({
    required this.controller,
    required this.label,
    required this.keyboardType,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: TextStyle(
        fontFamily: 'monospace',
        color: colors.primaryText,
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          fontFamily: 'monospace',
          color: colors.disabledText,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colors.disabledText.withOpacity(0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _accentTeal, width: 2),
        ),
        filled: true,
        fillColor: colors.disabledText.withOpacity(0.05),
      ),
    );
  }
}

class _AlertsToggle extends StatelessWidget {
  final bool value;
  final AppColors colors;
  final ValueChanged<bool?> onChanged;
  const _AlertsToggle({
    required this.value,
    required this.colors,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: colors.disabledText.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.disabledText.withOpacity(0.2)),
      ),
      child: CheckboxListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(
          'Enable Alerts',
          style: TextStyle(
            fontFamily: 'monospace',
            fontWeight: FontWeight.w700,
            fontSize: 14,
            color: colors.primaryText,
          ),
        ),
        subtitle: Text(
          'Get notified when nearing budget limits',
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 11,
            color: colors.disabledText,
          ),
        ),
        value: value,
        activeColor: _accentTeal,
        onChanged: onChanged,
      ),
    );
  }
}
