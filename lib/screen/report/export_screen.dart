import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:intl/intl.dart';
import 'package:walleta/config/api_config.dart';
import 'package:walleta/services/token_service.dart';
import 'package:walleta/theme/app_colors.dart';

const Color _accentTeal = Color(0xFF006A60);

class ExportScreen extends StatefulWidget {
  final String userEmail;
  const ExportScreen({super.key, required this.userEmail});

  @override
  State<ExportScreen> createState() => _ExportScreenState();
}

enum _ExportStatus { idle, loading, success, error }

class _ExportScreenState extends State<ExportScreen>
    with TickerProviderStateMixin {
  _ExportStatus _status = _ExportStatus.idle;
  String? _errorMessage;
  String? _savedFilename;
  DateTime? _fromDate;
  DateTime? _toDate;

  final Map<String, bool> _selectedFields = {
    'Date': true,
    'Title': true,
    'Category': true,
    'Amount': true,
    'Type': true,
  };

  late final AnimationController _successController;
  late final Animation<double> _successScale;
  late final Animation<double> _successFade;

  @override
  void initState() {
    super.initState();
    _successController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _successScale = CurvedAnimation(
      parent: _successController,
      curve: Curves.elasticOut,
    );
    _successFade = CurvedAnimation(
      parent: _successController,
      curve: Curves.easeIn,
    );
  }

  @override
  void dispose() {
    _successController.dispose();
    super.dispose();
  }

  void _toggleField(String field) {
    setState(() => _selectedFields[field] = !(_selectedFields[field] ?? true));
  }

  Future<String?> _getToken() async {
    final jwt = await TokenService.getToken();
    if (jwt != null && jwt.isNotEmpty) return jwt;
    return null;
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
        if (mounted) await openAppSettings();
        return false;
      }
      return true;
    } else if (sdk >= 29) {
      return true;
    } else {
      final status = await Permission.storage.request();
      return status.isGranted;
    }
  }

  Future<void> _saveToDownloads(List<int> bytes, String filename) async {
    if (Platform.isAndroid) {
      final granted = await _requestStoragePermission();
      if (!granted) {
        setState(() {
          _status = _ExportStatus.error;
          _errorMessage = 'Storage permission denied.';
        });
        return;
      }
    }

    final downloadsDir = Directory('/storage/emulated/0/Download');
    if (!await downloadsDir.exists()) {
      await downloadsDir.create(recursive: true);
    }

    final file = File('${downloadsDir.path}/$filename');
    await file.writeAsBytes(bytes);

    if (!mounted) return;
    setState(() {
      _status = _ExportStatus.success;
      _savedFilename = filename;
    });
    _successController.forward(from: 0);
  }

  Future<void> _exportTransactions() async {
    setState(() {
      _status = _ExportStatus.loading;
      _errorMessage = null;
      _savedFilename = null;
    });
    _successController.reset();

    try {
      final token = await _getToken();
      if (token == null) {
        setState(() {
          _status = _ExportStatus.error;
          _errorMessage = 'Not authenticated. Please log in again.';
        });
        return;
      }

      String url =
          '${ApiConfig.baseUrl}/api/export/transactions?email=${Uri.encodeComponent(widget.userEmail)}';
      if (_fromDate != null) url += '&from=${_fromDate!.toIso8601String()}';
      if (_toDate != null) url += '&to=${_toDate!.toIso8601String()}';

      final response = await http
          .get(
            Uri.parse(url),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'text/csv',
            },
          )
          .timeout(const Duration(seconds: 30));

      if (!mounted) return;

      if (response.statusCode == 200) {
        final lines = const LineSplitter().convert(response.body);
        final buffer = StringBuffer();

        final activeFields = _selectedFields.entries
            .where((e) => e.value)
            .map((e) => e.key)
            .toList();

        buffer.writeln(activeFields.join(','));

        if (lines.length > 1) {
          final headers = lines[0]
              .split(',')
              .map((h) => h.trim().toLowerCase())
              .toList();
          final dateIdx = headers.indexWhere(
            (h) => h.contains('date') || h.contains('created'),
          );
          final titleIdx = headers.indexWhere(
            (h) => h.contains('title') || h.contains('name'),
          );
          final categoryIdx = headers.indexWhere((h) => h.contains('category'));
          final amountIdx = headers.indexWhere((h) => h.contains('amount'));
          final isIncomeIdx = headers.indexWhere((h) => h.contains('income'));

          for (int i = 1; i < lines.length; i++) {
            final line = lines[i].trim();
            if (line.isEmpty) continue;
            final cols = line.split(',');

            String date = '';
            if (dateIdx >= 0 && dateIdx < cols.length) {
              final raw = cols[dateIdx].trim();
              try {
                final parsed = DateTime.parse(raw);
                date = DateFormat('yyyy-MM-dd').format(parsed);
              } catch (_) {
                date = raw;
              }
            }

            final title = titleIdx >= 0 && titleIdx < cols.length
                ? cols[titleIdx].trim().replaceAll(',', ' ')
                : '';
            final category = categoryIdx >= 0 && categoryIdx < cols.length
                ? cols[categoryIdx].trim().replaceAll(',', ' ')
                : '';
            final amount = amountIdx >= 0 && amountIdx < cols.length
                ? cols[amountIdx].trim()
                : '';
            final type = isIncomeIdx >= 0 && isIncomeIdx < cols.length
                ? (cols[isIncomeIdx].trim().toLowerCase() == 'true'
                      ? 'Income'
                      : 'Expense')
                : '';

            final rowValues = <String>[];
            if (_selectedFields['Date'] == true) rowValues.add(date);
            if (_selectedFields['Title'] == true) rowValues.add(title);
            if (_selectedFields['Category'] == true) rowValues.add(category);
            if (_selectedFields['Amount'] == true) rowValues.add(amount);
            if (_selectedFields['Type'] == true) rowValues.add(type);

            buffer.writeln(rowValues.join(','));
          }
        }

        final filename =
            'transactions_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.csv';
        await _saveToDownloads(utf8.encode(buffer.toString()), filename);
      } else {
        setState(() {
          _status = _ExportStatus.error;
          _errorMessage =
              'Export failed (${response.statusCode}). Please try again.';
        });
      }
    } catch (e) {
      setState(() {
        _status = _ExportStatus.error;
        _errorMessage = 'Something went wrong. Check your connection.';
      });
    }
  }

  Future<void> _pickFromDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _fromDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _fromDate = picked);
  }

  Future<void> _pickToDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _toDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _toDate = picked);
  }

  void _resetToIdle() {
    setState(() {
      _status = _ExportStatus.idle;
      _errorMessage = null;
      _savedFilename = null;
    });
    _successController.reset();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Scaffold(
      backgroundColor: colors.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Export',
          style: TextStyle(
            color: colors.primaryText,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: colors.primaryText,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        transitionBuilder: (child, anim) =>
            FadeTransition(opacity: anim, child: child),
        child: _status == _ExportStatus.success
            ? _SuccessView(
                key: const ValueKey('success'),
                filename: _savedFilename ?? '',
                colors: colors,
                scaleAnim: _successScale,
                fadeAnim: _successFade,
                onExportAgain: _resetToIdle,
              )
            : _MainView(
                key: const ValueKey('main'),
                colors: colors,
                status: _status,
                errorMessage: _errorMessage,
                fromDate: _fromDate,
                toDate: _toDate,
                selectedFields: _selectedFields,
                onPickFrom: _pickFromDate,
                onPickTo: _pickToDate,
                onClearDates: () => setState(() {
                  _fromDate = null;
                  _toDate = null;
                }),
                onToggleField: _toggleField,
                onExport: _exportTransactions,
              ),
      ),
    );
  }
}

class _MainView extends StatelessWidget {
  final AppColors colors;
  final _ExportStatus status;
  final String? errorMessage;
  final DateTime? fromDate, toDate;
  final Map<String, bool> selectedFields;
  final VoidCallback onPickFrom, onPickTo, onClearDates, onExport;
  final void Function(String) onToggleField;

  const _MainView({
    super.key,
    required this.colors,
    required this.status,
    required this.errorMessage,
    required this.fromDate,
    required this.toDate,
    required this.selectedFields,
    required this.onPickFrom,
    required this.onPickTo,
    required this.onClearDates,
    required this.onToggleField,
    required this.onExport,
  });

  @override
  Widget build(BuildContext context) {
    final isLoading = status == _ExportStatus.loading;
    final isError = status == _ExportStatus.error;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Download Your Data',
            style: TextStyle(
              color: colors.primaryText,
              fontSize: 26,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Export your transactions as a CSV file for backup or analysis.',
            style: TextStyle(
              color: colors.disabledText,
              fontSize: 14,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),

          _SectionCard(
            colors: colors,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.date_range_rounded,
                      color: _accentTeal,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Date Range',
                      style: TextStyle(
                        color: colors.primaryText,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '· optional',
                      style: TextStyle(
                        color: colors.disabledText,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _DateChip(
                        colors: colors,
                        label: 'From',
                        value: fromDate == null
                            ? 'All time'
                            : DateFormat('MMM d, y').format(fromDate!),
                        isSet: fromDate != null,
                        onTap: onPickFrom,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Icon(
                        Icons.arrow_forward_rounded,
                        color: colors.disabledText,
                        size: 16,
                      ),
                    ),
                    Expanded(
                      child: _DateChip(
                        colors: colors,
                        label: 'To',
                        value: toDate == null
                            ? 'Today'
                            : DateFormat('MMM d, y').format(toDate!),
                        isSet: toDate != null,
                        onTap: onPickTo,
                      ),
                    ),
                  ],
                ),
                if (fromDate != null || toDate != null) ...[
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: onClearDates,
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.close_rounded, color: _accentTeal, size: 14),
                        SizedBox(width: 4),
                        Text(
                          'Clear dates',
                          style: TextStyle(color: _accentTeal, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          _SectionCard(
            colors: colors,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.table_chart_rounded,
                      color: _accentTeal,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Columns to Export',
                      style: TextStyle(
                        color: colors.primaryText,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Tap to toggle columns on or off',
                  style: TextStyle(color: colors.disabledText, fontSize: 11.5),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: selectedFields.entries.map((entry) {
                    final isOn = entry.value;
                    return GestureDetector(
                      onTap: () => onToggleField(entry.key),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: isOn
                              ? _accentTeal
                              // ignore: deprecated_member_use
                              : colors.disabled.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isOn ? _accentTeal : Colors.transparent,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isOn
                                  ? Icons.check_circle_rounded
                                  : Icons.radio_button_unchecked_rounded,
                              color: isOn ? Colors.white : colors.disabledText,
                              size: 14,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              entry.key,
                              style: TextStyle(
                                color: isOn
                                    ? Colors.white
                                    : colors.disabledText,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          SizedBox(
            width: double.infinity,
            height: 56,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: _accentTeal,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  onTap: isLoading ? null : onExport,
                  borderRadius: BorderRadius.circular(16),
                  child: Center(
                    child: isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.download_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                              SizedBox(width: 10),
                              Text(
                                'Export as CSV',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ),
          ),

          if (isError && errorMessage != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                // ignore: deprecated_member_use
                color: colors.error.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                // ignore: deprecated_member_use
                border: Border.all(color: colors.error.withOpacity(0.25)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.error_outline_rounded,
                    color: colors.error,
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      errorMessage!,
                      style: TextStyle(color: colors.error, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ],

          if (status == _ExportStatus.idle) ...[
            const SizedBox(height: 28),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                // ignore: deprecated_member_use
                color: _accentTeal.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                // ignore: deprecated_member_use
                border: Border.all(color: _accentTeal.withOpacity(0.25)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    color: _accentTeal,
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'The file will be saved directly to your Downloads folder.',
                      style: TextStyle(
                        color: colors.primaryText,
                        fontSize: 12.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SuccessView extends StatelessWidget {
  final String filename;
  final AppColors colors;
  final Animation<double> scaleAnim, fadeAnim;
  final VoidCallback onExportAgain;

  const _SuccessView({
    super.key,
    required this.filename,
    required this.colors,
    required this.scaleAnim,
    required this.fadeAnim,
    required this.onExportAgain,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: FadeTransition(
          opacity: fadeAnim,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ScaleTransition(
                scale: scaleAnim,
                child: Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _accentTeal,
                    boxShadow: [
                      BoxShadow(
                        // ignore: deprecated_member_use
                        color: _accentTeal.withOpacity(0.35),
                        blurRadius: 28,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 48,
                  ),
                ),
              ),
              const SizedBox(height: 28),
              Text(
                'Export Complete',
                style: TextStyle(
                  color: colors.primaryText,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Your file has been saved to Downloads.',
                style: TextStyle(
                  color: colors.disabledText,
                  fontSize: 14,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: colors.containerBG,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: AppColors.softShadow,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.insert_drive_file_rounded,
                      color: _accentTeal,
                      size: 18,
                    ),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        filename,
                        style: TextStyle(
                          color: colors.primaryText,
                          fontSize: 13,
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.folder_rounded,
                    color: colors.disabledText,
                    size: 14,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Downloads',
                    style: TextStyle(color: colors.disabledText, fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton.icon(
                  onPressed: onExportAgain,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('Export Again'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _accentTeal,
                    side: const BorderSide(color: _accentTeal, width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final AppColors colors;
  final Widget child;

  const _SectionCard({required this.colors, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.containerBG,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppColors.softShadow,
      ),
      child: child,
    );
  }
}

class _DateChip extends StatelessWidget {
  final bool isSet;
  final AppColors colors;
  final String label, value;
  final VoidCallback onTap;

  const _DateChip({
    required this.colors,
    required this.isSet,
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSet
              // ignore: deprecated_member_use
              ? _accentTeal.withOpacity(0.10)
              // ignore: deprecated_member_use
              : colors.disabled.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            // ignore: deprecated_member_use
            color: isSet ? _accentTeal.withOpacity(0.4) : Colors.transparent,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label.toUpperCase(),
              style: const TextStyle(
                color: _accentTeal,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              value,
              style: TextStyle(
                color: colors.primaryText,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
